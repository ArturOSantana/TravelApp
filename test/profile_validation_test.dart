import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validação de Perfil', () {
    String? validateFullName(String? value) {
      if (value == null || value.isEmpty) return "Campo obrigatório";
      final parts = value.trim().split(' ');
      if (parts.length < 2 || parts.any((p) => p.isEmpty)) {
        return "Informe seu nome completo";
      }
      return null;
    }

    String? validatePhone(String? value) {
      if (value == null || value.isEmpty) return "Campo obrigatório";
      final phone = value.replaceAll(RegExp(r'\D'), '');
      if (phone.length != 11) {
        return "Use o padrão 11999999999 (11 dígitos)";
      }
      return null;
    }

    test('Deve rejeitar nome sem sobrenome', () {
      expect(validateFullName('Artur'), 'Informe seu nome completo');
    });

    test('Deve aceitar nome completo', () {
      expect(validateFullName('Artur Santana'), null);
    });

    test('Deve rejeitar telefone com menos de 11 dígitos', () {
      expect(validatePhone('1199999999'), 'Use o padrão 11999999999 (11 dígitos)');
    });

    test('Deve aceitar telefone com 11 dígitos (limpo)', () {
      expect(validatePhone('11999999999'), null);
    });

    test('Deve aceitar telefone com máscara mas 11 dígitos reais', () {
      expect(validatePhone('(11) 99999-9999'), null);
    });

    test('Deve rejeitar telefone vazio', () {
      expect(validatePhone(''), 'Campo obrigatório');
    });
  });
}
