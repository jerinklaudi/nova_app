import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF2196F3); // Blue
  static const Color secondary = Color(0xFF03DAC6); // Teal
  static const Color background = Colors.black;
  static const Color surface = Color(0xFF1E1E1E);

  // 🚨 THIS WAS MISSING
  static const Color danger = Color(0xFFCF6679); // Soft Red for alerts/reset

  // Accessibility Colors
  static const Color highContrastText = Colors.white;
  static const Color warning = Color(0xFFFFCF44); // Yellow for obstacles

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,

      // Card & Dialog Themes
      cardColor: surface,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
      ),

      // Text Theme (Optimized for Legibility)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: highContrastText),
        bodyLarge: TextStyle(fontSize: 18, color: highContrastText),
      ),
    );
  }
}
