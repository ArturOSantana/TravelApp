import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system; // Padrão: seguir sistema

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  ThemeController() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        switch (savedTheme) {
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'system':
          default:
            _themeMode = ThemeMode.system;
            break;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar tema: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String modeString;
      switch (mode) {
        case ThemeMode.dark:
          modeString = 'dark';
          break;
        case ThemeMode.light:
          modeString = 'light';
          break;
        case ThemeMode.system:
        default:
          modeString = 'system';
          break;
      }
      await prefs.setString(_themeKey, modeString);
    } catch (e) {
      debugPrint('Erro ao salvar tema: $e');
    }
  }

  String getThemeModeName() {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.system:
      default:
        return 'Automático (Sistema)';
    }
  }
}
