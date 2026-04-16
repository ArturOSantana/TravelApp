import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      // Sistema de rotas compatível com Web
      home: const AppInitializer(),
      onGenerateRoute: (settings) {
        final Uri uri = Uri.parse(settings.name ?? '/');

        // Trata /journal/ID
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
  }
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    final bool onboardingCompleted = CacheService.isOnboardingCompleted();

    if (onboardingCompleted) {
      return const LoginPage();
    } else {
      return const OnboardingPage();
    }
  }
}
