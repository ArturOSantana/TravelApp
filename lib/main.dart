import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/journal_page.dart';
import 'screens/community_page.dart';
import 'screens/onboarding_page.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'services/cache_service.dart';
import 'services/memory_manager_service.dart';
import 'services/permission_service.dart';
import 'theme/app_theme.dart';
import 'controllers/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa a formatação de datas para Português (Brasil)
  await initializeDateFormatting('pt_BR', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa o gerenciador de memória
  // Detecta automaticamente dispositivos antigos e ajusta configurações
  await MemoryManagerService().initialize();

  if (!kIsWeb) {
    // Configura o Firestore com cache otimizado para o dispositivo
    final gerenciadorMemoria = MemoryManagerService();
    final configuracoes = gerenciadorMemoria.getOptimizedSettings();

    // Firebase exige cache entre 1MB e 100MB
    // Dispositivos antigos recebem valores menores automaticamente
    final tamanhoCache = configuracoes['cacheSize'] as int;
    final tamanhoCacheValido = tamanhoCache.clamp(1048576, 104857600);

    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: tamanhoCacheValido,
    );
  }

  await CacheService.initialize();

  if (!kIsWeb) {
    await NotificationService.init();
    await PushNotificationService.initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Travel App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            home: const AppInitializer(),
            onGenerateRoute: (settings) {
              final Uri uri = Uri.parse(settings.name ?? '/');

              if (uri.pathSegments.length == 2 &&
                  uri.pathSegments.first == 'journal') {
                final String tripId = uri.pathSegments[1];
                return MaterialPageRoute(
                  builder: (context) => JournalPage(tripId: tripId),
                  settings: settings,
                );
              }

              switch (uri.path) {
                case '/':
                  return MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                    settings: settings,
                  );
                case '/onboarding':
                  return MaterialPageRoute(
                    builder: (context) => const OnboardingPage(),
                    settings: settings,
                  );
                case '/register':
                  return MaterialPageRoute(
                    builder: (context) => const RegisterPage(),
                    settings: settings,
                  );
                case '/home':
                  return MaterialPageRoute(
                    builder: (context) => const DashboardPage(),
                    settings: settings,
                  );
                case '/community':
                  return MaterialPageRoute(
                    builder: (context) => const CommunityPage(),
                    settings: settings,
                  );
                default:
                  return MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                    settings: settings,
                  );
              }
            },
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _permissionRequested = false;

  Future<void> _requestLocationPermission() async {
    if (!_permissionRequested && mounted) {
      _permissionRequested = true;
      // Aguarda um frame para garantir que o contexto está disponível
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await PermissionService.requestLocationPermission(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Se ainda está carregando o estado do Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final bool onboardingConcluido = CacheService.isOnboardingCompleted();

        // Fluxo de navegação inicial do app
        if (!onboardingConcluido) {
          return const OnboardingPage();
        }

        if (snapshot.hasData && snapshot.data != null) {
          _requestLocationPermission();
          return const DashboardPage();
        }

        return const LoginPage();
      },
    );
  }
}
