import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'otp_list_screen.dart';
import 'password_list_screen.dart';
import 'settings_screen.dart';
import 'lock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static bool isLockScreenVisible = false;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const OtpListScreen(),
    const PasswordListScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!HomeScreen.isLockScreenVisible) {
        HomeScreen.isLockScreenVisible = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LockScreen(isFromBackground: true),
              ),
            ).then((_) {
              Future.delayed(const Duration(milliseconds: 500), () {
                HomeScreen.isLockScreenVisible = false;
              });
            });
          }
        });
      }
    }
  }

  Widget _buildTabItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? PRIMARY_COLOR : DARK_GREY_COLOR,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? PRIMARY_COLOR : DARK_GREY_COLOR,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        height: 65,
        child: Row(
          children: [
            _buildTabItem(Icons.security, 'OTP', 0),
            _buildTabItem(Icons.vpn_key, '비밀번호', 1),
            _buildTabItem(Icons.settings, '설정', 2),
          ],
        ),
      ),
    );
  }
}