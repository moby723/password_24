import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otp/otp.dart';
import '../utils/colors.dart';
import '../utils/device_check.dart';
import 'qr_scan_screen.dart';
import 'home_screen.dart';

class OtpListScreen extends StatefulWidget {
  const OtpListScreen({super.key});

  @override
  State<OtpListScreen> createState() => _OtpListScreenState();
}

class _OtpListScreenState extends State<OtpListScreen> {
  List _otpList = [];
  Timer? _timer;
  double _progress = 0.0;
  bool _isSwipeRightToLeft = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadOtpList();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSwipeRightToLeft = prefs.getBool('swipe_direction') ?? true;
    });
  }

  Future<void> _loadOtpList() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('saved_otps');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      setState(() {
        _otpList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> _saveOtpList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_otps', jsonEncode(_otpList));
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final time = DateTime.now().millisecondsSinceEpoch;
      final int remaining = 30 - ((time / 1000).floor() % 30);
      setState(() {
        _progress = remaining / 30.0;
      });
    });
  }

  String _generateOtp(String secret) {
    try {
      return OTP.generateTOTPCodeString(
        secret,
        DateTime.now().millisecondsSinceEpoch,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
    } catch (e) {
      return "ERROR";
    }
  }

  void _showEditDialog(int index) {
    final item = _otpList[index];
    final siteController = TextEditingController(text: item["site"]);
    final idController = TextEditingController(text: item["id"]);
    final secretController = TextEditingController(text: item["secret"]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('OTP 정보 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: siteController, decoration: const InputDecoration(labelText: '사이트 이름')),
              TextField(controller: idController, decoration: const InputDecoration(labelText: '아이디 또는 이메일')),
              TextField(controller: secretController, decoration: const InputDecoration(labelText: '시크릿 키')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            ElevatedButton(
              onPressed: () {
                if (siteController.text.isNotEmpty && secretController.text.isNotEmpty) {
                  setState(() {
                    _otpList[index] = {
                      "site": siteController.text,
                      "id": idController.text,
                      "secret": secretController.text.replaceAll(' ', '').toUpperCase(),
                    };
                  });
                  _saveOtpList();
                  Navigator.pop(context);
                }
              },
              child: const Text('수정'),
            ),
          ],
        );
      },
    );
  }

  void _showManualAddDialog() {
    final siteController = TextEditingController();
    final idController = TextEditingController();
    final secretController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('OTP 직접 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: siteController, decoration: const InputDecoration(labelText: '사이트 이름')),
              TextField(controller: idController, decoration: const InputDecoration(labelText: '아이디 또는 이메일')),
              TextField(controller: secretController, decoration: const InputDecoration(labelText: '시크릿 키 (영문/숫자)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            ElevatedButton(
              onPressed: () {
                if (siteController.text.isNotEmpty && secretController.text.isNotEmpty) {
                  setState(() {
                    _otpList.add({
                      "site": siteController.text,
                      "id": idController.text,
                      "secret": secretController.text.replaceAll(' ', '').toUpperCase(),
                    });
                  });
                  _saveOtpList();
                  Navigator.pop(context);
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  void _showAddOptions() {
    if (DeviceCheck.isDesktopOrWeb) {
      _showManualAddDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code_scanner, color: PRIMARY_COLOR),
                title: const Text('QR 코드로 스캔'),
                onTap: () async {
                  Navigator.pop(context);
                  HomeScreen.isLockScreenVisible = true;

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QrScanScreen()),
                  );

                  HomeScreen.isLockScreenVisible = false;

                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      _otpList.add(result);
                    });
                    _saveOtpList();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.keyboard, color: PRIMARY_COLOR),
                title: const Text('시크릿 키 직접 입력'),
                onTap: () {
                  Navigator.pop(context);
                  _showManualAddDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP 관리')),
      body: _otpList.isEmpty
          ? const Center(child: Text('저장된 OTP가 없습니다.', textAlign: TextAlign.center))
          : ListView.builder(
        itemCount: _otpList.length,
        itemBuilder: (context, index) {
          final item = _otpList[index];
          final otpCode = _generateOtp(item["secret"]!);

          return Dismissible(
            key: Key('otp_${item["secret"]}_$index'),
            direction: _isSwipeRightToLeft
                ? DismissDirection.endToStart
                : DismissDirection.startToEnd,
            background: Container(
              color: ERROR_COLOR,
              alignment: _isSwipeRightToLeft
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              setState(() {
                _otpList.removeAt(index);
              });
              _saveOtpList();
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(
                  item["site"]!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item["id"]!),
                    const SizedBox(height: 4),
                    Text(
                      otpCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: PRIMARY_COLOR,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: 20, color: DARK_GREY_COLOR),
                      onPressed: () => _showEditDialog(index),
                    ),
                    const SizedBox(width: 8),
                    CircularProgressIndicator(
                      value: _progress,
                      backgroundColor: LIGHT_GREY_COLOR,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _progress < 0.2 ? ERROR_COLOR : PRIMARY_COLOR,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  if (otpCode != "ERROR") {
                    Clipboard.setData(ClipboardData(text: otpCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('OTP 코드가 복사되었습니다.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        child: const Icon(Icons.add),
      ),
    );
  }
}