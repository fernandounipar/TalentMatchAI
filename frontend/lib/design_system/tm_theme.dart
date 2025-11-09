import 'package:flutter/material.dart';
import 'tm_tokens.dart';

/// Configuração do ThemeData (Material 3) para TalentMatchIA
class TMTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: TMTokens.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: TMTokens.primary,
      secondary: TMTokens.secondary,
      surface: TMTokens.surface,
      background: TMTokens.bg,
      error: TMTokens.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: TMTokens.bg,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: TMTokens.text,
      ),
      cardTheme: CardThemeData(
        color: TMTokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TMTokens.r12),
          side: const BorderSide(color: TMTokens.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TMTokens.r8),
          borderSide: const BorderSide(color: TMTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TMTokens.r8),
          borderSide: const BorderSide(color: TMTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TMTokens.r8),
          borderSide: BorderSide(color: TMTokens.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w700),
        displayMedium: TextStyle(fontWeight: FontWeight.w700),
        displaySmall: TextStyle(fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: TMTokens.text),
        bodyMedium: TextStyle(color: TMTokens.text),
        bodySmall: TextStyle(color: TMTokens.textMuted),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TMTokens.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TMTokens.r8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TMTokens.text,
          side: const BorderSide(color: TMTokens.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TMTokens.r8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TMTokens.primary,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  static ThemeData dark() {
    // Mantém mesma paleta adaptando brilho e background.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: TMTokens.primary,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TMTokens.r12),
        ),
      ),
    );
  }
}

