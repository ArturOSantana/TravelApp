import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations extends ChangeNotifier {
  static const String PORTUGUESE = 'pt_BR';
  static const String ENGLISH = 'en';

  static const Map<String, IconData> languageIcons = {
    PORTUGUESE: Icons.language,  // or use Icons.flag
    ENGLISH: Icons.language,
  };

  static const Map<String, String> languageFlags = {
    PORTUGUESE: '🇧🇷',
    ENGLISH: '🇺🇸',
  };

  String _locale = PORTUGUESE;

  String get locale => _locale;

  bool get isPortuguese => _locale == PORTUGUESE;
  bool get isEnglish => _locale == ENGLISH;

  static final Map<String, Map<String, String>> _translations = {
    PORTUGUESE: {
      'hello': 'Olá',
      'welcome': 'Bem-vindo',
      'logout': 'Sair',
      'back': 'Voltar',
      'save': 'Salvar',
      'cancel': 'Cancelar',
      'delete': 'Deletar',
      'edit': 'Editar',
      'add': 'Adicionar',
      'create': 'Criar',
      'search': 'Pesquisar',
      'settings': 'Configurações',
      'language': 'Idioma',
      'portuguese': 'Português (BR)',
      'english': 'English',
      'my_trips': 'Minhas Viagens',
      'dashboard': 'Dashboard',
      'journal': 'Diário',
      'community': 'Comunidade',
      'profile': 'Perfil',
      'expenses': 'Despesas',
      'activities': 'Atividades',
      'packing_list': 'Lista de Malas',
      'safety_check_in': 'Check-in de Segurança',
      'recommendations': 'Recomendações',
      'notifications': 'Notificações',
    },
    ENGLISH: {
      'hello': 'Hello',
      'welcome': 'Welcome',
      'logout': 'Logout',
      'back': 'Back',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'create': 'Create',
      'search': 'Search',
      'settings': 'Settings',
      'language': 'Language',
      'portuguese': 'Português (BR)',
      'english': 'English',
      'my_trips': 'My Trips',
      'dashboard': 'Dashboard',
      'journal': 'Journal',
      'community': 'Community',
      'profile': 'Profile',
      'expenses': 'Expenses',
      'activities': 'Activities',
      'packing_list': 'Packing List',
      'safety_check_in': 'Safety Check-in',
      'recommendations': 'Recommendations',
      'notifications': 'Notifications',
    },
  };

  AppLocalizations() {
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString('app_language') ?? PORTUGUESE;
    notifyListeners();
  }

  Future<void> changeLanguage(String newLocale) async {
    if (_locale != newLocale) {
      _locale = newLocale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', newLocale);
      notifyListeners();
    }
  }

  String translate(String key) {
    return _translations[_locale]?[key] ?? key;
  }

  // Helper method to use in the app
  String t(String key) => translate(key);
}

// Global instance for easy access
final appLocalizations = AppLocalizations();
