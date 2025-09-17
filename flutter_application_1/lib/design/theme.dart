// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration long = Duration(milliseconds: 700);

  static const Curve ease = Curves.easeOut;
  static const Curve pop = Curves.easeOutBack;
}

class AppTheme {
  // สีหลักของแอป
  static const Color deepPurple = Color(0xFF5B2EFF);
  static const Color purple = Color(0xFF8C6CFF);
  static const Color lavender = Color(0xFFEDE9FF);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: false,
    colorScheme: ColorScheme.fromSeed(
      seedColor: deepPurple,
      primary: deepPurple,
      secondary: purple,
      background: const Color(0xFFF7F5FF),
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F5FF),
    primaryColor: deepPurple,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: deepPurple,
      foregroundColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: lavender, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: deepPurple, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(vertical: 14),
        ),
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          return deepPurple;
        }),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.all(deepPurple),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
