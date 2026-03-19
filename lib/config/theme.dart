import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiprayTheme {
  static const _gold = Color(0xFFD4A647);
  static const _goldLight = Color(0xFFE8C97A);
  static const _goldDark = Color(0xFFB8862E);
  static const _bgDark = Color(0xFF0D0D0D);
  static const _surfaceDark = Color(0xFF1A1A1A);
  static const _cardDark = Color(0xFF242424);
  static const _textPrimary = Color(0xFFF5F0E8);
  static const _textSecondary = Color(0xFFA09880);
  static const _activeLineGreen = Color(0xFF1A3D2E);
  static const _nextLineBlue = Color(0xFF1A2640);
  static const _error = Color(0xFFCF6679);

  static const gold = _gold;
  static const activeLineColor = _activeLineGreen;
  static const nextLineColor = _nextLineBlue;
  static const cardColor = _cardDark;
  static const bgDark = _bgDark;
  static const surfaceDark = _surfaceDark;
  static const textPrimary = _textPrimary;
  static const textSecondary = _textSecondary;

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.notoSansThaiTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _gold,
        onPrimary: _bgDark,
        secondary: _goldLight,
        onSecondary: _bgDark,
        tertiary: _goldDark,
        surface: _surfaceDark,
        onSurface: _textPrimary,
        error: _error,
      ),
      scaffoldBackgroundColor: _bgDark,
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: _gold,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: _textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: _textPrimary,
          height: 1.8,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: _textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _bgDark,
        foregroundColor: _gold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: _gold,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: _bgDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _gold,
          side: const BorderSide(color: _gold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _gold,
        foregroundColor: _bgDark,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _surfaceDark,
        selectedItemColor: _gold,
        unselectedItemColor: _textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      dividerTheme: DividerThemeData(
        color: _textSecondary.withValues(alpha: 0.2),
      ),
      iconTheme: const IconThemeData(color: _gold),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _gold;
          return _textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _gold.withValues(alpha: 0.3);
          }
          return _textSecondary.withValues(alpha: 0.2);
        }),
      ),
    );
  }
}
