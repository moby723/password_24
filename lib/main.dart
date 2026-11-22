import 'package:flutter/material.dart';
import 'utils/colors.dart';
import 'screens/lock_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '비밀번호 24',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: PRIMARY_COLOR,
          primary: PRIMARY_COLOR,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: PRIMARY_COLOR,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: PRIMARY_COLOR,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const LockScreen(),
    );
  }
}