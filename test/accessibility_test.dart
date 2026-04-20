import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Testes de Acessibilidade (W3C/WCAG) - Estrutura Semântica', () {
    
    testWidgets('Deve validar a semântica de cabeçalho e labels de formulário', (WidgetTester tester) async {
      // Removido o 'const' para permitir a construção do TextFormField
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Semantics(
                  header: true,
                  child: const Text("Título da Página"),
                ),
                TextFormField( // 'const' removido aqui
                  decoration: const InputDecoration(
                    labelText: "E-mail",
                    hintText: "Digite seu e-mail",
                  ),
                ),
                Semantics(
                  button: true,
                  label: "Enviar dados",
                  child: ElevatedButton(
                    onPressed: () {}, 
                    child: const Text("Cadastrar")
                  ),
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.bySemanticsLabel('Título da Página'), findsOneWidget);

      expect(find.bySemanticsLabel('Enviar dados'), findsOneWidget);

      expect(find.widgetWithText(TextFormField, 'E-mail'), findsOneWidget);
    });

    testWidgets('Deve validar área mínima de toque (WCAG Tap Target)', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () {},
              child: const Text("Link"),
            ),
          ),
        ),
      ));

      final buttonFinder = find.byType(TextButton);
      final RenderBox buttonBox = tester.renderObject(buttonFinder);

      expect(buttonBox.size.width, greaterThanOrEqualTo(48.0));
      expect(buttonBox.size.height, greaterThanOrEqualTo(48.0));
    });
  });
}
