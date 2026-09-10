import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primaryLight = Color(0xFF5D4037);
  static const Color primaryDark = Color(0xFFCCA47C);

  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF141312);

  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E1C1A);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF25221F);

  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textPrimaryDark = Color(0xFFEDE8E3);

  static const Color textSecondaryLight = Color(0xFF795548);
  static const Color textSecondaryDark = Color(0xFFB5A99F);

  static const Color borderLight = Color(0x2E5D4037);
  static const Color borderDark = Color(0x3DCCA47C);

  /// Light ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Almarai',
      primaryColor: primaryLight,
      scaffoldBackgroundColor: backgroundLight,
      cardColor: cardLight,
      canvasColor: backgroundLight,
      colorScheme: ColorScheme.light(
        primary: primaryLight,
        secondary: const Color(0xFF8D6E63),
        surface: cardLight,
        error: Colors.red.shade700,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: primaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryLight),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0.5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderLight, width: 0.8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 0.8,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: backgroundLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      iconTheme: const IconThemeData(
        color: primaryLight,
      ),
    );
  }

  /// Dark ThemeData
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Almarai',
      primaryColor: primaryDark,
      scaffoldBackgroundColor: backgroundDark,
      cardColor: cardDark,
      canvasColor: backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: primaryDark,
        secondary: const Color(0xFFA1887F),
        surface: cardDark,
        error: Colors.red.shade400,
        onPrimary: const Color(0xFF141312),
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: primaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryDark),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0.5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderDark, width: 0.8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 0.8,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      iconTheme: const IconThemeData(
        color: primaryDark,
      ),
    );
  }
}
