import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/journal_page.dart';
import 'screens/community_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Crucial para Web: Remove o '#' da URL
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Inicializa o Firebase com as opções geradas pelo FlutterFire CLI
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Notificações apenas para Mobile (não inicializa na Web para evitar erros)
  if (!kIsWeb) {
    await NotificationService.init();
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
      ),
      // Sistema de rotas compatível com Web
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final Uri uri = Uri.parse(settings.name ?? '/');
        
        // Trata /journal/ID
        if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'journal') {
          final String tripId = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (context) => JournalPage(tripId: tripId),
            settings: settings,
          );
        }

        // Rotas fixas
        switch (uri.path) {
          case '/':
            return MaterialPageRoute(builder: (context) => const LoginPage(), settings: settings);
          case '/register':
            return MaterialPageRoute(builder: (context) => const RegisterPage(), settings: settings);
          case '/home':
            return MaterialPageRoute(builder: (context) => const DashboardPage(), settings: settings);
          case '/community':
            return MaterialPageRoute(builder: (context) => const CommunityPage(), settings: settings);
          default:
            return MaterialPageRoute(builder: (context) => const LoginPage(), settings: settings);
        }
      },
    );
  }
}
