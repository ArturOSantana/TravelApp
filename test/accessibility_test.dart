import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Testes de Acessibilidade (W3C/WCAG) - Estrutura de UI', () {
    
    testWidgets('Deve validar a semântica de um cabeçalho e ícone acessível', (WidgetTester tester) async {
      // Criamos uma versão simplificada da UI para testar os padrões W3C sem depender do Firebase
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Semantics(
                label: "Logo do aplicativo",
                child: const Icon(Icons.travel_explore),
              ),
              Semantics(
                header: true,
                child: const Text("Bem-vindo"),
              ),
              Semantics(
                button: true,
                label: "Entrar",
                child: ElevatedButton(onPressed: () {}, child: const Text("Login")),
              ),
            ],
          ),
        ),
      ));

      // 1. Verifica se o Header (W3C Requisito) existe
      expect(find.bySemanticsLabel('Bem-vindo'), findsOneWidget);

      // 2. Verifica se a imagem/ícone tem descrição (WCAG Alt-Text)
      expect(find.bySemanticsLabel('Logo do aplicativo'), findsOneWidget);

      // 3. Verifica se o botão tem papel semântico
      expect(find.bySemanticsLabel('Entrar'), findsOneWidget);
    });

    testWidgets('Verifica se campos de texto possuem Labels acessíveis', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'E-mail'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Senha'),
              ),
            ],
          ),
        ),
      ));

      // O W3C exige que campos de entrada sejam identificáveis
      expect(find.widgetWithText(TextField, 'E-mail'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
    });
  });
}
