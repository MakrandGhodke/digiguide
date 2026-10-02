import 'package:flutter/material.dart';

class AppTheme {
  static const Color coral50 = Color(0xFFFFF1F2);
  static const Color coral100 = Color(0xFFFFE4E6);
  static const Color coral500 = Color(0xFFFE6B57); // Approximate Coral-500
  static const Color coral600 = Color(0xFFE54D3B);

  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate50 = Color(0xFFF8FAFC);

  static const Color gray50 = Color(0xFFF9FAFB);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: coral500,
      colorScheme: ColorScheme.light(
        primary: coral500,
        secondary: coral600,
        surface: Colors.white,
        onSurface: slate900,
        surfaceContainerHighest: gray50,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: slate900,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: slate900,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(color: slate900, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: slate600, fontSize: 16),
        bodyMedium: TextStyle(color: slate600, fontSize: 14),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: slate900,
      primaryColor: coral500,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: coral500,
        secondary: coral600,
        surface: slate800,
        onSurface: slate50,
        background: slate900,
        onBackground: slate50,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: slate900,
        elevation: 0,
        iconTheme: IconThemeData(color: slate50),
        titleTextStyle: TextStyle(
          color: slate50,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        color: slate800,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: slate50,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: slate50,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(color: slate50, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: slate300, fontSize: 16),
        bodyMedium: TextStyle(color: slate300, fontSize: 14),
      ),
    );
  }
}
