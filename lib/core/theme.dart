import 'package:flutter/material.dart';

/// Yeadut design language: calm, trustworthy, modern-traditional.
/// Deep blue primary over warm parchment neutrals.
class YeadutTheme {
  static const Color deepBlue = Color(0xFF0C447C);
  static const Color midBlue = Color(0xFF185FA5);
  static const Color gold = Color(0xFFBA7517);
  static const Color parchment = Color(0xFFFAF7F0);
  static const Color nightBlue = Color(0xFF0A1828);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: deepBlue,
      brightness: Brightness.light,
      surface: parchment,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: parchment,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: midBlue,
      brightness: Brightness.dark,
      surface: nightBlue,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: nightBlue,
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
