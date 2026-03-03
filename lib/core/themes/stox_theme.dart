import 'package:flutter/material.dart';

class StoxTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: const Color(0xFF0A6ED1), // SAP Blue
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0A6ED1),
        secondary: Color(0xFF0854A0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A6ED1),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}
