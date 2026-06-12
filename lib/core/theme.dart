import 'package:flutter/material.dart';

/// Yeadut design language: calm, trustworthy, modern-traditional.
/// Deep blue + gold over warm parchment neutrals; Heebo for UI text and
/// Frank Ruhl Libre for display/serif Hebrew moments (both bundled —
/// fully offline).
class YeadutTheme {
  static const Color deepBlue = Color(0xFF0C447C);
  static const Color midBlue = Color(0xFF185FA5);
  static const Color gold = Color(0xFFBA7517);
  static const Color goldBright = Color(0xFFF4C466);
  static const Color parchment = Color(0xFFFAF7F0);
  static const Color nightBlue = Color(0xFF0A1828);

  static const String uiFont = 'Heebo';
  static const String displayFont = 'FrankRuhlLibre';

  /// Serif display style for the Hebrew date and other "moments".
  static TextStyle display(BuildContext context,
      {double size = 24, FontWeight weight = FontWeight.w700}) {
    return TextStyle(
      fontFamily: displayFont,
      fontSize: size,
      fontWeight: weight,
      height: 1.25,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: deepBlue,
      brightness: Brightness.light,
      surface: parchment,
    ).copyWith(
      primary: deepBlue,
      tertiary: gold,
    );
    return _base(scheme).copyWith(scaffoldBackgroundColor: parchment);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: midBlue,
      brightness: Brightness.dark,
      surface: nightBlue,
    ).copyWith(tertiary: goldBright);
    return _base(scheme).copyWith(scaffoldBackgroundColor: nightBlue);
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: uiFont,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: uiFont,
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
              fontFamily: uiFont, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
              fontFamily: uiFont, fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        space: 24,
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
