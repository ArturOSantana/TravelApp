import 'package:flutter/material.dart';
import 'screens/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xfff2f1e2),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xfff1eec0),
        ),
        scaffoldBackgroundColor: const Color(0xfff2f1e2),
        textTheme: const TextTheme(
          bodyLarge : TextStyle (color : Colors.deepPurple),
        ),


      ),
      home: const LoginPage(),
    );
  }
}