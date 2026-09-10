import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  static ThemeService get instance => _instance;

  ThemeService._internal();

  ThemeMode _themeMode = ThemeMode.system;
  File? _settingsFile;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  /// Returns whether the effective theme is dark right now.
  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    // For ThemeMode.system
    return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
  }

  /// Arabic display name for the current theme mode
  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'الوضع النهاري';
      case ThemeMode.dark:
        return 'الوضع الليلي';
      case ThemeMode.system:
        return 'تلقائي (حسب النظام)';
    }
  }

  /// Icon corresponding to current theme mode
  IconData get themeModeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  /// Initialize theme from local storage
  Future<void> init() async {
    try {
      final appDoc = await getApplicationDocumentsDirectory();
      _settingsFile = File('${appDoc.path}/alhuda_theme_mode.json');

      if (await _settingsFile!.exists()) {
        final content = await _settingsFile!.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        final modeString = data['themeMode'] as String?;

        if (modeString == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (modeString == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.system;
        }
      }
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
      _themeMode = ThemeMode.system;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Set and persist a specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _saveThemeMode();
  }

  /// Quick toggle between light and dark modes
  Future<void> toggleTheme() async {
    HapticFeedback.selectionClick();
    if (isDarkMode) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  Future<void> _saveThemeMode() async {
    try {
      if (_settingsFile == null) {
        final appDoc = await getApplicationDocumentsDirectory();
        _settingsFile = File('${appDoc.path}/alhuda_theme_mode.json');
      }

      String modeStr;
      switch (_themeMode) {
        case ThemeMode.dark:
          modeStr = 'dark';
          break;
        case ThemeMode.light:
          modeStr = 'light';
          break;
        case ThemeMode.system:
          modeStr = 'system';
          break;
      }

      final jsonStr = jsonEncode({'themeMode': modeStr});
      await _settingsFile!.writeAsString(jsonStr, flush: true);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }
}
