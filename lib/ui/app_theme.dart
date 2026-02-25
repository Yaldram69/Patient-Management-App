// lib/ui/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  /// Return a ThemeData tuned to the chosen accent color and brightness.
  static ThemeData themeData({required Color accentColor, required bool darkMode}) {
    final base = darkMode ? ThemeData.dark() : ThemeData.light();

    final colorScheme = base.colorScheme.copyWith(
      primary: accentColor,
      secondary: accentColor,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: accentColor,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: accentColor,
        elevation: 2,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: accentColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: darkMode ? Colors.white : Colors.black87,
        displayColor: darkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  /// Reusable input decoration builder used across screens.
  static InputDecoration inputDecoration({
    required String label,
    IconData? icon,
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      suffixIcon: suffix,
      filled: true,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  /// Reusable primary button style (if you need it outside ElevatedButton.icon)
  static ButtonStyle primaryButtonStyle(Color accent) {
    return ElevatedButton.styleFrom(
      backgroundColor: accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }
}
