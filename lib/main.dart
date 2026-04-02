import 'package:flutter/material.dart';
import 'screens/login_page.dart';

void main() {
  runApp(const MyApp());
}

//projeto refatorado para melhor organização do código,objetivo:
//Dashboard → bonito + cards
//Lista → cards com viagens
//Detalhes → visual (imagem, infos)
//Criar → formulário elegante
//data 30 do 3

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
     
  useMaterial3: true,

  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
  ),

  scaffoldBackgroundColor: Colors.grey[100],

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),
      home: const LoginPage(),
    );
  }
}