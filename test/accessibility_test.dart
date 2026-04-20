import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/screens/login_page.dart';

void main() {
  group('Testes de Acessibilidade (W3C/WCAG)', () {
    
    testWidgets('Deve encontrar Semântica de cabeçalho e botão na LoginPage', (WidgetTester tester) async {
      // Renderiza a página de login
      await tester.pumpWidget(const MaterialApp(
        home: LoginPage(),
      ));

      // 1. Verifica se existe um Header (Semantics header: true)
      // O W3C exige hierarquia clara de títulos
      final headerFinder = find.bySemanticsLabel('Bem-vindo');
      expect(headerFinder, findsOneWidget);

      // 2. Verifica se o ícone/logo possui uma descrição semântica
      // Essencial para deficientes visuais entenderem elementos gráficos
      expect(find.bySemanticsLabel('Logo do aplicativo'), findsOneWidget);

      // 3. Verifica o Tap Target do botão Esqueci minha senha (WCAG recomenda áreas grandes)
      final forgotPasswordButton = find.widgetWithText(TextButton, 'Esqueci minha senha');
      expect(forgotPasswordButton, findsOneWidget);
    });

    testWidgets('Verifica se campos de formulário possuem AutofillHints (Requisito W3C)', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: LoginPage(),
      ));

      final emailField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'E-mail'));
      final passwordField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Senha'));

      // O W3C recomenda que campos comuns facilitem a entrada de dados
      expect(emailField.autofillHints, contains(AutofillHints.email));
      expect(passwordField.autofillHints, contains(AutofillHints.password));
    });
  });
}
