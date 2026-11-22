import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordListScreen extends StatefulWidget {
  const PasswordListScreen({super.key});

  @override
  State<PasswordListScreen> createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  List _passwords = [];
  bool _isSwipeRightToLeft = true;
  void _showEditDialog(int index) {
    final item = _passwords[index];
    final siteController = TextEditingController(text: item["site"]);
    final idController = TextEditingController(text: item["id"]);
    final pwController = TextEditingController(text: item["pw"]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('비밀번호 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: siteController, decoration: const InputDecoration(labelText: '사이트 이름')),
              TextField(controller: idController, decoration: const InputDecoration(labelText: '아이디')),
              TextField(
                controller: pwController,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.auto_fix_high, color: Colors.blue),
                    tooltip: '비밀번호 자동 생성',
                    onPressed: () => _showPasswordGeneratorDialog(pwController),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            ElevatedButton(
              onPressed: () {
                if (siteController.text.isNotEmpty) {
                  setState(() {
                    _passwords[index] = {
                      "site": siteController.text,
                      "id": idController.text,
                      "pw": pwController.text,
                    };
                  });
                  _savePasswords();
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

  @override
  void initState() {
    super.initState();
    _loadPasswords();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSwipeRightToLeft = prefs.getBool('swipe_direction') ?? true;
    });
  }

  Future<void> _loadPasswords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('saved_passwords');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      setState(() {
        _passwords = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  Future<void> _savePasswords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_passwords', jsonEncode(_passwords));
  }

  void _showPasswordGeneratorDialog(TextEditingController pwController) {
    double length = 12;
    // 모든 옵션의 기본값을 꺼진 상태(false)로 변경
    bool useUpper = false;
    bool useNumber = false;
    bool useSpecial = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('비밀번호 자동 생성'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('길이: '),
                      Expanded(
                        child: Slider(
                          value: length,
                          min: 8,
                          max: 32,
                          divisions: 24,
                          label: length.toInt().toString(),
                          onChanged: (val) => setDialogState(() => length = val),
                        ),
                      ),
                      Text('${length.toInt()}자'),
                    ],
                  ),
                  CheckboxListTile(
                    title: const Text('대문자 포함 (A-Z)'),
                    value: useUpper,
                    onChanged: (val) => setDialogState(() => useUpper = val!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('숫자 포함 (0-9)'),
                    value: useNumber,
                    onChanged: (val) => setDialogState(() => useNumber = val!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('특수문자 포함 (!@#...)'),
                    value: useSpecial,
                    onChanged: (val) => setDialogState(() => useSpecial = val!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                ElevatedButton(
                  onPressed: () {
                    String chars = 'abcdefghijklmnopqrstuvwxyz';
                    if (useUpper) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
                    if (useNumber) chars += '0123456789';
                    if (useSpecial) chars += r'!@#$%^&*';

                    String generated = '';
                    final rnd = Random();
                    for (int i = 0; i < length.toInt(); i++) {
                      generated += chars[rnd.nextInt(chars.length)];
                    }

                    pwController.text = generated;
                    Navigator.pop(context);
                  },
                  child: const Text('적용하기'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddDialog() {
    final siteController = TextEditingController();
    final idController = TextEditingController();
    final pwController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('새 비밀번호 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: siteController, decoration: const InputDecoration(labelText: '사이트 이름 (예: Google)')),
              TextField(controller: idController, decoration: const InputDecoration(labelText: '아이디')),
              TextField(
                controller: pwController,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.auto_fix_high, color: Colors.blue),
                    tooltip: '비밀번호 자동 생성',
                    onPressed: () => _showPasswordGeneratorDialog(pwController),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            ElevatedButton(
              onPressed: () {
                if (siteController.text.isNotEmpty) {
                  setState(() {
                    _passwords.add({"site": siteController.text, "id": idController.text, "pw": pwController.text});
                  });
                  _savePasswords();
                  Navigator.pop(context);
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호')),
      body: _passwords.isEmpty
          ? const Center(child: Text('저장된 비밀번호가 없습니다.', textAlign: TextAlign.center))
          : ListView.builder(
        itemCount: _passwords.length,
        itemBuilder: (context, index) {
          final item = _passwords[index];
          return Dismissible(
            key: Key('pw_${item["site"]}_${item["pw"]}_$index'),
            direction: _isSwipeRightToLeft ? DismissDirection.endToStart : DismissDirection.startToEnd,
            background: Container(
              color: Colors.red,
              alignment: _isSwipeRightToLeft ? Alignment.centerRight : Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              setState(() { _passwords.removeAt(index); });
              _savePasswords();
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.lock, size: 40, color: Colors.grey),
                // 사이트와 아이디를 명확한 한글 라벨과 함께 표시하여 혼동 방지
                title: Text('사이트: ${item["site"]!}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('아이디: ${item["id"]!}'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: item["pw"]!));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('복사되었습니다.'), duration: Duration(seconds: 2)));
                },
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _showEditDialog(index),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, child: const Icon(Icons.add)),
    );
  }
}