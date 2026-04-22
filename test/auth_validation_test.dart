import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Testes de Validação de Auth (Cadastro e Login)', () {
    
    // Simulação das funções de validação da RegisterPage
    String? validateEmail(String? value) {
      if (value == null || value.isEmpty) return "Informe seu e-mail";
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) return "E-mail inválido";
      return null;
    }

    String? validatePassword(String? value) {
      if (value == null || value.length < 6) return "A senha deve ter pelo menos 6 caracteres";
      return null;
    }

    String? validateConfirmPassword(String? value, String originalPassword) {
      if (value == null || value.isEmpty) return "Confirme sua senha";
      if (value != originalPassword) return "As senhas não coincidem";
      return null;
    }

    String? validateName(String? value) {
      if (value == null || value.trim().isEmpty) return "Informe seu nome";
      if (value.trim().split(' ').length < 2) return "Informe nome e sobrenome";
      return null;
    }

    test('Deve rejeitar e-mail inválido (sem @)', () {
      expect(validateEmail('usuario.com'), 'E-mail inválido');
    });

    test('Deve aceitar e-mail válido', () {
      expect(validateEmail('teste@travel.com'), null);
    });

    test('Deve rejeitar senha com menos de 6 caracteres', () {
      expect(validatePassword('12345'), 'A senha deve ter pelo menos 6 caracteres');
    });

    test('Deve rejeitar se a confirmação de senha for diferente', () {
      expect(validateConfirmPassword('senha123', 'senha456'), 'As senhas não coincidem');
    });

    test('Deve aceitar se as senhas forem iguais', () {
      expect(validateConfirmPassword('minhasenha', 'minhasenha'), null);
    });

    test('Deve rejeitar nome apenas com primeiro nome', () {
      expect(validateName('Artur'), 'Informe nome e sobrenome');
    });

    test('Deve aceitar nome e sobrenome', () {
      expect(validateName('Artur Santana'), null);
    });
  });
}
