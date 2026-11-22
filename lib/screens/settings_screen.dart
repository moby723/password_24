import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSwipeRightToLeft = true;
  bool _useBiometrics = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSwipeRightToLeft = prefs.getBool('swipe_direction') ?? true;
      _useBiometrics = prefs.getBool('use_biometrics') ?? true;
    });
  }

  void _showChangePinDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPin = prefs.getString('master_pin') ?? "1234";
    final pinController = TextEditingController();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Builder(
              builder: (snackContext) {
                return Center(
                  child: SingleChildScrollView(
                    child: AlertDialog(
                      title: const Text('새로운 PIN 설정'),
                      content: TextField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: '숫자 4자리 입력'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('취소'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final newPin = pinController.text;

                            ScaffoldMessenger.of(snackContext).clearSnackBars();

                            if (newPin.length != 4) {
                              ScaffoldMessenger.of(snackContext).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN 번호는 4자리여야 합니다.'),
                                  backgroundColor: WARNING_COLOR,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            if (newPin == currentPin) {
                              ScaffoldMessenger.of(snackContext).showSnackBar(
                                const SnackBar(
                                  content: Text('기존과 동일한 PIN 번호입니다.'),
                                  backgroundColor: WARNING_COLOR,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            await prefs.setString('master_pin', newPin);
                            if (!mounted) return;
                            Navigator.pop(context);

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('PIN 번호가 성공적으로 변경되었습니다.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text('변경'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('PIN 번호 변경'),
            subtitle: const Text('앱 잠금 해제에 사용할 4자리 숫자 변경'),
            onTap: _showChangePinDialog,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('지문 인증 사용'),
            subtitle: const Text('앱 잠금 해제 시 지문 인증 활성화'),
            value: _useBiometrics,
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('use_biometrics', value);
              setState(() {
                _useBiometrics = value;
              });
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.swipe),
            title: const Text('스와이프 삭제 방향'),
            subtitle: Text(
              _isSwipeRightToLeft ? '오른쪽에서 왼쪽으로 밀기' : '왼쪽에서 오른쪽으로 밀기',
            ),
            value: _isSwipeRightToLeft,
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('swipe_direction', value);
              setState(() {
                _isSwipeRightToLeft = value;
              });
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('앱 정보'),
            subtitle: Text('v1.0.0'),
          ),
        ],
      ),
    );
  }
}