import 'package:flutter/material.dart';

class AppTheme {
  // STUDENT (Blue)
  static const Color studentPrimary = Color(0xFF1E88E5);
  static const Color studentAccent = Color(0xFF64B5F6);
  static const Color studentBackground = Color(0xFFF5F9FF);

  // COMPANY (Teal)
  static const Color companyPrimary = Color(0xFF26A69A);
  static const Color companyAccent = Color(0xFF80CBC4);
  static const Color companyBackground = Color(0xFFF3FBF9);

  static ThemeData studentTheme = ThemeData(
    primaryColor: studentPrimary,
    scaffoldBackgroundColor: studentBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: studentPrimary,
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: studentPrimary,
    ),
  );

  static ThemeData companyTheme = ThemeData(
    primaryColor: companyPrimary,
    scaffoldBackgroundColor: companyBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: companyPrimary,
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: companyPrimary,
    ),
  );
}
