import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
  //essa classe é responsável por gerenciar a localização do aplicativo,o usuário escolhe entre diferentes idiomas e armazenando essa preferência usando SharedPreferences. Ela também fornece um método de tradução para obter as strings traduzidas com base na chave fornecida.
  //fiz um por um, se quiser adicionar mais é só seguir o padrão (linguagems orientais requerem extensoes,tipo japonês)
class AppLocalizations extends ChangeNotifier {
  static const String PORTUGUESE = 'pt_BR';
  static const String ENGLISH = 'en';
  static const String ITALIAN = 'it';
  static const String SPANISH = 'es';
  static const String FRENCH = 'fr';
  static const String RUSSIAN = 'ru';


//se nao funcionar eu me mato 21/4/26
  static const Map<String, IconData> languageIcons = {
    PORTUGUESE: Icons.language,  // or use Icons.flag
    ENGLISH: Icons.language,
    ITALIAN: Icons.language,
    SPANISH: Icons.language,
    FRENCH: Icons.language,
    RUSSIAN: Icons.language,

  };

  static const Map<String, String> languageFlags = {
    PORTUGUESE: '🇧🇷',
    ENGLISH: '🇺🇸',
    ITALIAN: '🇮🇹',
    SPANISH: '🇪🇸',
    FRENCH: '🇫🇷',
    RUSSIAN: '🇷🇺',
  };

  String _locale = PORTUGUESE;

  String get locale => _locale;

  bool get isPortuguese => _locale == PORTUGUESE;
  bool get isEnglish => _locale == ENGLISH;
  bool get isItalian => _locale == ITALIAN;
  bool get isSpanish => _locale == SPANISH;
  bool get isFrench => _locale == FRENCH;
  bool get isRussian => _locale == RUSSIAN;


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
      'Name': 'Nome',
      'email': 'Email',
      'Phone': 'Telefone',
      'bio': 'Bio',
      'gender': 'Genero',
      'emergency_contact': 'Contato de Emergência',
      'travel_status': 'Status da Viagem',
      'travel_completed': 'Completa',
      'erase': 'Apagar',
      'sure': 'Tem certeza?',
      'exclude': 'Excluir',
      'this_action': 'Esta ação não pode ser desfeita.',
      'confirm': 'Confirmar',
      'planning': 'Planejamento',
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
      'nome': 'Name',
      'email': 'Email',
      'telefone': 'Phone',
      'bio': 'Bio',
      'gender': 'Gender',
      'emergency_contact': 'Contato de Emergência',
      'completo': 'Complete', 
      'erase': 'Erase',
      'sure': 'Are you sure?',
      'exclude': 'Exclude',
      'this_action': 'This action cannot be undone.',
      'confirm': 'Confirm',
      'planning': 'Planning',
      'profile': 'Profile',
      'expenses': 'Expenses',
      'activities': 'Activities',
      'packing_list': 'Packing List',
      'safety_check_in': 'Safety Check-in',
      'recommendations': 'Recommendations',
      'notifications': 'Notifications',
    },
    ITALIAN: {
      'hello': 'Ciao',
      'welcome': 'Benvenuto',
      'logout': 'Logout',
      'back': 'Indietro',
      'save': 'Salva',
      'cancel': 'Annulla',
      'delete': 'Elimina',
      'edit': 'Modifica',
      'add': 'Aggiungi',
      'create': 'Crea',
      'search': 'Cerca',
      'settings': 'Impostazioni',
      'language': 'Lingua',
      'portuguese': 'Português (BR)',
      'english': 'English',
      'my_trips': 'I miei viaggi',
      'dashboard': 'Dashboard',
      'journal': 'Diario',
      'community': 'Comunità',
      'name': 'Nome',
      'email': 'Email',
      'phone': 'Telefono',
      'bio': 'Bio',
      'gender': 'Genere',
      'emergency_contact': 'Contatto di emergenza',
      'travel_status': 'Stato del viaggio',
      'travel_completed': 'Completo',
      'erase': 'Cancellare',
      'sure': 'Sei sicuro?',
      'exclude': 'Escludere',
      'this_action': 'Questa azione non può essere annullata.',
      'confirm': 'Confermare',
      'planning': 'Planeggiamento',
      'profile': 'Profilo',
      'expenses': 'Spese',
      'activities': 'Attività',
      'packing_list': "Lista dei bagagli",
      "safety_check_in": "Check-in di sicurezza",
      "recommendations": "Raccomandazioni",
      "notifications": "Notifiche",
    },
    SPANISH: {
      'hello': 'Hola',
      'welcome': 'Bienvenido',
      'logout': 'Cerrar sesión',
      'back': 'Atrás',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'add': 'Agregar',
      'create': 'Crear',
      'search': 'Buscar',
      'settings': 'Configuraciones',
      'language': 'Idioma',
      'portuguese': 'Português (BR)',
      'english': 'English',
      'my_trips': 'Mis Viajes',
      'dashboard': 'Dashboard',
      'journal': 'Diario',
      'community': 'Comunidad',
      'name': 'Nombre',
      'email': 'Correo electrónico',
      'phone': 'Teléfono',
      'bio': 'Bio',
      'gender': 'Género',
      'emergency_contact': 'Contacto de emergencia',
      'travel_status': 'Estado del viaje',
      'travel_completed': 'Completo',
      'erase': 'Borrar',
      'sure': '¿Estás seguro?',
      'exclude': 'Excluir',
      'this_action': 'Esta acción no se puede deshacer.',
      'confirm': 'Confirmar',
      'planning': 'Planificación',
      'profile': 'Perfil',
      'expenses': 'Gastos',
      'activities': 'Actividades',
      "packing_list": "Lista de equipaje",
      "safety_check_in": "Check-in de seguridad",
      "recommendations": "Recomendaciones",
      "notifications": "Notificaciones",
    },
    FRENCH: {
      'hello': 'Bonjour',
      'welcome': 'Bienvenue',
      'logout': 'Déconnexion',
      'back': 'Retour',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'add': 'Ajouter',
      'create': 'Créer',
      'search': 'Rechercher',
      'settings': 'Paramètres',
      'language': 'Langue',
      'portuguese': 'Português (BR)',
      'english': 'English',
      'my_trips': 'Mes Voyages',
      'dashboard': 'Dashboard',
      'journal': 'Journal',
      'community': 'Communauté',
      'name': 'Nom',
      'email': 'Email',
      'phone': 'Téléphone',
      'bio': 'Bio',
      'gender': 'Genre',
      'emergency_contact': 'Contact d urgence',
      'travel_status': 'Statut du voyage',
      'travel_completed': 'Complet',
      'erase': 'Effacer',
      'sure': 'Êtes-vous sûr?',
      'exclude': 'Exclure',
      'this_action': "Cette action ne peut pas être annulée.",
      'confirm': 'Confirmer',
      'planning': 'Planification',
      'profile': 'Profil',
      'expenses': 'Dépenses',
      'activities': "Activités",
      "packing_list": "Liste de bagages",
      "safety_check_in": "Check-in de sécurité",
      "recommendations": "Recommandations",
      "notifications": "Notifications",
    },
    RUSSIAN: {
      'hello': 'Привет',
      'welcome': 'Добро пожаловать',
      'logout': 'Выйти',
      'back': 'Назад',
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'delete': 'Удалить',
      'edit': 'Редактировать',
      'add': 'Добавить',
      'create': 'Создать',
      'search': 'Поиск',
      'settings': 'Настройки',
      'language': 'Язык',
      'portuguese': 'Português (BR)',
      'english': 'English',
      'my_trips': 'Мои поездки',
      'dashboard': 'Панель управления',
      'journal': 'Журнал',
      'community': 'Сообщество',
      'name': 'Имя',
      'email': 'Электронная почта',
      'phone': 'Телефон',
      'bio': 'Биография',
      'gender': 'Пол',
      'emergency_contact': 'Контакт для экстренных случаев',
      'travel_status': 'Статус поездки',
      'travel_completed': 'Завершено',
      'erase': 'Стереть',
      'sure': 'Вы уверены?',
      'exclude': 'Исключить',
      'this_action': 'Это действие нельзя отменить.',
      'confirm': 'Подтвердить',
      'planning': 'Планирование',
      'profile': 'Профиль',
      'expenses': 'Расходы',
      "activities": "Деятельность",
      "packing_list": "Список упаковки",
      "safety_check_in": "Регистрация безопасности",
      "recommendations": "Рекомендации",
      "notifications": "Уведомления",
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
