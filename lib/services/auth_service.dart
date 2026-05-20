import 'package:firebase_auth/firebase_auth.dart';
import '../core/exceptions/app_exceptions.dart';

/// Serviço de autenticação com Firebase
///
/// Gerencia login, registro, recuperação de senha e outras
/// operações relacionadas à autenticação de usuários.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Retorna o usuário atualmente autenticado
  User? get currentUser => _auth.currentUser;

  /// Stream de mudanças no estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Realiza login com email e senha
  ///
  /// Throws [AuthException] em caso de erro
  Future<User> login(String email, String password) async {
    try {
      // Validação básica
      if (email.trim().isEmpty || password.isEmpty) {
        throw AuthException.invalidCredentials();
      }

      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user == null) {
        throw AuthException('Falha ao fazer login', code: 'login-failed');
      }

      return result.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Erro inesperado ao fazer login',
        code: 'unknown-error',
        originalError: e,
      );
    }
  }

  /// Registra novo usuário com email e senha
  ///
  /// Throws [AuthException] em caso de erro
  Future<User> register(String email, String password) async {
    try {
      // Validação básica
      if (email.trim().isEmpty) {
        throw AuthException.invalidEmail();
      }
      if (password.length < 6) {
        throw AuthException.weakPassword();
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user == null) {
        throw AuthException('Falha ao criar conta', code: 'register-failed');
      }

      // Enviar email de verificação
      await result.user!.sendEmailVerification();

      return result.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Erro inesperado ao criar conta',
        code: 'unknown-error',
        originalError: e,
      );
    }
  }

  /// Envia email de recuperação de senha
  ///
  /// Throws [AuthException] em caso de erro
  Future<void> resetPassword(String email) async {
    try {
      if (email.trim().isEmpty) {
        throw AuthException.invalidEmail();
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Erro ao enviar email de recuperação',
        code: 'reset-failed',
        originalError: e,
      );
    }
  }

  /// Faz logout do usuário atual
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException(
        'Erro ao fazer logout',
        code: 'logout-failed',
        originalError: e,
      );
    }
  }

  /// Reenvia email de verificação
  Future<void> resendVerificationEmail() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw AuthException('Usuário não autenticado',
            code: 'not-authenticated');
      }

      if (user.emailVerified) {
        throw AuthException('Email já verificado', code: 'already-verified');
      }

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Erro ao reenviar email de verificação',
        code: 'resend-failed',
        originalError: e,
      );
    }
  }

  /// Atualiza o nome de exibição do usuário
  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw AuthException('Usuário não autenticado',
            code: 'not-authenticated');
      }

      await user.updateDisplayName(displayName.trim());
      await user.reload();
    } catch (e) {
      throw AuthException(
        'Erro ao atualizar nome',
        code: 'update-failed',
        originalError: e,
      );
    }
  }

  /// Atualiza a senha do usuário
  ///
  /// Requer reautenticação recente
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw AuthException('Usuário não autenticado',
            code: 'not-authenticated');
      }

      if (newPassword.length < 6) {
        throw AuthException.weakPassword();
      }

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'Por segurança, faça login novamente antes de alterar a senha',
          code: 'requires-recent-login',
        );
      }
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Erro ao atualizar senha',
        code: 'update-password-failed',
        originalError: e,
      );
    }
  }

  /// Reautentica o usuário com credenciais atuais
  Future<void> reauthenticate(String email, String password) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw AuthException('Usuário não autenticado',
            code: 'not-authenticated');
      }

      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Erro ao reautenticar',
        code: 'reauthenticate-failed',
        originalError: e,
      );
    }
  }

  /// Deleta a conta do usuário
  ///
  /// Requer reautenticação recente
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw AuthException('Usuário não autenticado',
            code: 'not-authenticated');
      }

      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'Por segurança, faça login novamente antes de deletar a conta',
          code: 'requires-recent-login',
        );
      }
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Erro ao deletar conta',
        code: 'delete-account-failed',
        originalError: e,
      );
    }
  }

  /// Converte exceções do Firebase em exceções customizadas
  AuthException _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException.userNotFound();
      case 'wrong-password':
        return AuthException.invalidCredentials();
      case 'invalid-email':
        return AuthException.invalidEmail();
      case 'email-already-in-use':
        return AuthException.emailAlreadyInUse();
      case 'weak-password':
        return AuthException.weakPassword();
      case 'user-disabled':
        return AuthException.userDisabled();
      case 'too-many-requests':
        return AuthException.tooManyRequests();
      case 'network-request-failed':
        return AuthException.networkError();
      case 'invalid-credential':
        return AuthException.invalidCredentials();
      default:
        return AuthException(
          e.message ?? 'Erro de autenticação',
          code: e.code,
          originalError: e,
        );
    }
  }
}
