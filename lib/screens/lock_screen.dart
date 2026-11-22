import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../utils/device_check.dart';
import 'home_screen.dart';

class LockScreen extends StatefulWidget {
  final bool isFromBackground;
  const LockScreen({super.key, this.isFromBackground = false});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

  String _correctPin = "1234";
  bool _isAuthenticating = false;
  bool _useBiometrics = true;

  int _failedAttempts = 0;
  DateTime? _lockUntil;
  Timer? _lockTimer;
  bool _isLocked = false;
  String _lockMessage = '';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _correctPin = prefs.getString('master_pin') ?? "1234";
      _failedAttempts = prefs.getInt('failed_attempts') ?? 0;
      _useBiometrics = prefs.getBool('use_biometrics') ?? true;
    });

    final lockStr = prefs.getString('lock_until');
    if (lockStr != null) {
      _lockUntil = DateTime.parse(lockStr);
      if (_lockUntil!.isAfter(DateTime.now())) {
        _startLockTimer();
      } else {
        await _clearLockTimer();
        _triggerInitialBiometrics();
      }
    } else {
      _triggerInitialBiometrics();
    }
  }

  void _triggerInitialBiometrics() {
    if (_useBiometrics && !DeviceCheck.isBiometricsUnsupported) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _checkBiometrics();
      });
    }
  }

  Future<void> _triggerLockout({bool fromBiometrics = false}) async {
    _lockTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();

    if (fromBiometrics) {
      _failedAttempts = ((_failedAttempts ~/ 5) + 1) * 5;
    }

    int tier = _failedAttempts ~/ 5;
    if (tier < 1) tier = 1;

    int lockMinutes = (10 * math.pow(6, tier - 1)).toInt();

    _lockUntil = DateTime.now().add(Duration(minutes: lockMinutes));
    await prefs.setString('lock_until', _lockUntil!.toIso8601String());
    await prefs.setInt('failed_attempts', _failedAttempts);
    _startLockTimer();

    String timeMsg = '';
    if (lockMinutes >= 1440) {
      timeMsg = '${lockMinutes ~/ 1440}일 ${(lockMinutes % 1440) ~/ 60}시간';
    } else if (lockMinutes >= 60) {
      timeMsg = '${lockMinutes ~/ 60}시간';
    } else {
      timeMsg = '${lockMinutes}분';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('연속 실패로 $timeMsg 기기가 잠깁니다.'),
          backgroundColor: ERROR_COLOR,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startLockTimer() {
    setState(() => _isLocked = true);
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isAfter(_lockUntil!)) {
        _clearLockTimer();
      } else {
        setState(() {
          final diff = _lockUntil!.difference(now);
          int d = diff.inDays;
          int h = diff.inHours % 24;
          int m = diff.inMinutes % 60;
          int s = diff.inSeconds % 60;

          String timeStr = '';
          if (d > 0) timeStr += '${d}일 ';
          if (h > 0 || d > 0) timeStr += '${h.toString().padLeft(2, '0')}:';
          timeStr += '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

          _lockMessage = '$timeStr 후 잠금 해제';
        });
      }
    });
  }

  Future<void> _clearLockTimer() async {
    _lockTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lock_until');
    if (mounted) {
      setState(() {
        _isLocked = false;
        _lockMessage = '';
      });
    }
  }

  Future<void> _resetAllOnSuccess() async {
    _lockTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('failed_attempts');
    await prefs.remove('lock_until');
    if (mounted) {
      setState(() {
        _failedAttempts = 0;
        _isLocked = false;
        _lockMessage = '';
      });
    }
  }

  Future<void> _unlockSuccess() async {
    await _resetAllOnSuccess();
    if (!mounted) return;

    if (widget.isFromBackground) {
      Navigator.pop(context);
    } else {
      HomeScreen.isLockScreenVisible = false;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _checkBiometrics() async {
    if (DeviceCheck.isBiometricsUnsupported) return;
    if (_isAuthenticating || _isLocked || !_useBiometrics) return;

    setState(() => _isAuthenticating = true);

    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (canAuthenticate) {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: '앱 잠금을 해제하려면 인증을 진행하세요.',
          biometricOnly: true,
        );
        if (didAuthenticate && mounted) {
          await _unlockSuccess();
        }
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('lockedout') ||
          errorStr.contains('permanentlylockedout') ||
          errorStr.contains('too many attempts')) {
        await _triggerLockout(fromBiometrics: true);
      }
    } finally {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isAuthenticating = false);
      });
    }
  }

  Future<void> _checkPin() async {
    if (_isLocked) return;

    if (_pinController.text == _correctPin) {
      await _unlockSuccess();
    } else {
      _failedAttempts++;

      if (_failedAttempts % 5 == 0) {
        await _triggerLockout();
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('failed_attempts', _failedAttempts);

        int remaining = 5 - (_failedAttempts % 5);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('비밀번호가 틀렸습니다. (남은 시도: $remaining회)'),
            backgroundColor: ERROR_COLOR,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 80,
                color: _isLocked ? ERROR_COLOR : DARK_GREY_COLOR,
              ),
              const SizedBox(height: 24),
              Text(
                _isLocked ? '잠금 상태' : 'PIN 번호를 입력하세요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isLocked ? ERROR_COLOR : Colors.black,
                ),
              ),
              if (_isLocked) ...[
                const SizedBox(height: 16),
                Text(
                  _lockMessage,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ERROR_COLOR,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: _pinController,
                enabled: !_isLocked,
                keyboardType: TextInputType.number,
                obscureText: true,
                textAlign: TextAlign.center,
                maxLength: 4,
                style: const TextStyle(fontSize: 24, letterSpacing: 10),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLocked ? null : _checkPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLocked ? DARK_GREY_COLOR : PRIMARY_COLOR,
                  ),
                  child: const Text(
                    '잠금 해제',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              if (!DeviceCheck.isBiometricsUnsupported && _useBiometrics) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: (_isAuthenticating || _isLocked) ? null : _checkBiometrics,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('지문 인증으로 해제'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}