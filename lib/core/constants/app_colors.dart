import 'package:alhuda/core/theme/app_theme.dart';
import 'package:alhuda/core/theme/theme_service.dart';
import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand color constants
  static const Color primaryLight = AppTheme.primaryLight;
  static const Color primaryDark = AppTheme.primaryDark;

  // Dynamic colors adapting automatically to light / dark theme
  static Color get primary =>
      ThemeService.instance.isDarkMode ? primaryDark : primaryLight;

  static Color get background =>
      ThemeService.instance.isDarkMode ? AppTheme.backgroundDark : AppTheme.backgroundLight;

  static Color get card =>
      ThemeService.instance.isDarkMode ? AppTheme.cardDark : AppTheme.cardLight;

  static Color get surface =>
      ThemeService.instance.isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight;

  static Color get textPrimary =>
      ThemeService.instance.isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

  static Color get textSecondary =>
      ThemeService.instance.isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;

  static Color get border =>
      ThemeService.instance.isDarkMode ? AppTheme.borderDark : AppTheme.borderLight;

  static Color get black =>
      ThemeService.instance.isDarkMode ? AppTheme.textPrimaryDark : Colors.black;

  static Color get onPrimary =>
      ThemeService.instance.isDarkMode ? const Color(0xFF141312) : Colors.white;

  static Color get shadow =>
      ThemeService.instance.isDarkMode ? Colors.black.withAlpha(50) : Colors.black.withAlpha(8);
}
