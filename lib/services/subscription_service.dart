import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/exceptions/app_exceptions.dart';
import '../models/user_model.dart';

/// Serviço de gerenciamento de assinaturas e limites de recursos.
///
/// Controla o acesso a funcionalidades premium e limites do plano gratuito:
/// - Plano Free: máximo 3 viagens, 3 membros por viagem
/// - Plano Premium: recursos ilimitados, insights avançados, exportação de relatórios
class SubscriptionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Constantes de limites do plano Free
  static const int _maxTripsForFree = 3;
  static const int _maxMembersForFree = 3;

  /// Verifica se o usuário atual possui assinatura Premium.
  ///
  /// Retorna `false` se o usuário não estiver autenticado ou se houver erro.
  ///
  /// Throws:
  /// - [NetworkException] se houver erro de conexão com Firestore
  static Future<bool> _isPremiumUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final userData = UserModel.fromMap(doc.data()!);
      return userData.isPremium;
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Erro ao verificar status Premium',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao verificar Premium',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  /// Verifica se o usuário pode criar uma nova viagem.
  ///
  /// Usuários Premium têm viagens ilimitadas.
  /// Usuários Free estão limitados a 3 viagens.
  ///
  /// Returns: `true` se pode criar, `false` caso contrário
  ///
  /// Throws:
  /// - [AuthException] se o usuário não estiver autenticado
  /// - [NetworkException] se houver erro de conexão
  static Future<bool> canCreateTrip() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException(
        'Usuário não autenticado',
        code: 'user_not_authenticated',
      );
    }

    try {
      final isPremium = await _isPremiumUser();
      if (isPremium) return true;

      final tripsSnapshot = await _db
          .collection('trips')
          .where('members', arrayContains: user.uid)
          .get();

      return tripsSnapshot.docs.length < _maxTripsForFree;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Erro ao verificar limite de viagens',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao verificar limite de viagens',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  /// Verifica se o usuário pode adicionar um membro à viagem.
  ///
  /// Usuários Premium têm membros ilimitados.
  /// Usuários Free estão limitados a 3 membros por viagem.
  ///
  /// Parameters:
  /// - [tripId]: ID da viagem a verificar
  ///
  /// Returns: `true` se pode adicionar, `false` caso contrário
  ///
  /// Throws:
  /// - [ValidationException] se o tripId for inválido
  /// - [AuthException] se o usuário não estiver autenticado
  /// - [NetworkException] se houver erro de conexão
  /// - [SubscriptionException] se a viagem não existir
  static Future<bool> canAddMember(String tripId) async {
    _validateTripId(tripId);

    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException(
        'Usuário não autenticado',
        code: 'user_not_authenticated',
      );
    }

    try {
      final isPremium = await _isPremiumUser();
      if (isPremium) return true;

      final tripDoc = await _db.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) {
        throw SubscriptionException(
          'Viagem não encontrada',
          code: 'trip_not_found',
        );
      }

      final members = List<String>.from(tripDoc.data()?['members'] ?? []);
      return members.length < _maxMembersForFree;
    } on ValidationException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on SubscriptionException {
      rethrow;
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Erro ao verificar limite de membros',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao verificar limite de membros',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  /// Verifica se o usuário tem acesso a insights avançados (análises com IA).
  ///
  /// Funcionalidade exclusiva para usuários Premium.
  ///
  /// Returns: `true` se tem acesso, `false` caso contrário
  ///
  /// Throws:
  /// - [NetworkException] se houver erro de conexão
  static Future<bool> hasAdvancedInsights() async {
    try {
      return await _isPremiumUser();
    } on NetworkException {
      rethrow;
    }
  }

  /// Verifica se o usuário tem acesso a funcionalidades de IA.
  ///
  /// Funcionalidade exclusiva para usuários Premium.
  ///
  /// Returns: `true` se tem acesso, `false` caso contrário
  ///
  /// Throws:
  /// - [NetworkException] se houver erro de conexão
  static Future<bool> hasAIFeatures() async {
    try {
      return await _isPremiumUser();
    } on NetworkException {
      rethrow;
    }
  }

  /// Verifica se o usuário pode exportar relatórios.
  ///
  /// Funcionalidade exclusiva para usuários Premium.
  ///
  /// Returns: `true` se pode exportar, `false` caso contrário
  ///
  /// Throws:
  /// - [NetworkException] se houver erro de conexão
  static Future<bool> canExportReports() async {
    try {
      return await _isPremiumUser();
    } on NetworkException {
      rethrow;
    }
  }

  /// Atualiza o usuário atual para o plano Premium.
  ///
  /// Throws:
  /// - [AuthException] se o usuário não estiver autenticado
  /// - [NetworkException] se houver erro de conexão
  /// - [SubscriptionException] se já for Premium
  static Future<void> upgradeToPremium() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException(
        'Usuário não autenticado',
        code: 'user_not_authenticated',
      );
    }

    try {
      // Verifica se já é Premium
      final isPremium = await _isPremiumUser();
      if (isPremium) {
        throw SubscriptionException(
          'Usuário já possui assinatura Premium',
          code: 'already_premium',
        );
      }

      await _db.collection('users').doc(user.uid).update({
        'isPremium': true,
        'premiumSince': FieldValue.serverTimestamp(),
      });
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on SubscriptionException {
      rethrow;
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Erro ao atualizar para Premium',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao atualizar para Premium',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  /// Faz downgrade do usuário atual para o plano Free.
  ///
  /// Throws:
  /// - [AuthException] se o usuário não estiver autenticado
  /// - [NetworkException] se houver erro de conexão
  /// - [SubscriptionException] se já for Free
  static Future<void> downgradeToFree() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException(
        'Usuário não autenticado',
        code: 'user_not_authenticated',
      );
    }

    try {
      // Verifica se já é Free
      final isPremium = await _isPremiumUser();
      if (!isPremium) {
        throw SubscriptionException(
          'Usuário já está no plano Free',
          code: 'already_free',
        );
      }

      await _db.collection('users').doc(user.uid).update({
        'isPremium': false,
        'premiumSince': null,
      });
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on SubscriptionException {
      rethrow;
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Erro ao fazer downgrade para Free',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao fazer downgrade',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  /// Obtém informações detalhadas sobre os limites do usuário.
  ///
  /// Returns: Map com informações de uso e limites
  ///
  /// Throws:
  /// - [AuthException] se o usuário não estiver autenticado
  /// - [NetworkException] se houver erro de conexão
  static Future<Map<String, dynamic>> getUserLimits() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException(
        'Usuário não autenticado',
        code: 'user_not_authenticated',
      );
    }

    try {
      final isPremium = await _isPremiumUser();

      if (isPremium) {
        return {
          'isPremium': true,
          'maxTrips': -1, // Ilimitado
          'maxMembers': -1, // Ilimitado
          'currentTrips': 0,
          'hasAdvancedInsights': true,
          'canExportReports': true,
        };
      }

      final tripsSnapshot = await _db
          .collection('trips')
          .where('members', arrayContains: user.uid)
          .get();

      return {
        'isPremium': false,
        'maxTrips': _maxTripsForFree,
        'maxMembers': _maxMembersForFree,
        'currentTrips': tripsSnapshot.docs.length,
        'hasAdvancedInsights': false,
        'canExportReports': false,
      };
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on FirebaseException catch (e) {
      throw NetworkException(
        'Erro ao obter limites do usuário',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao obter limites',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  // ==================== VALIDAÇÕES ====================

  static void _validateTripId(String tripId) {
    if (tripId.trim().isEmpty) {
      throw ValidationException('ID da viagem não pode estar vazio');
    }
    if (tripId.trim().length < 10) {
      throw ValidationException('ID da viagem inválido');
    }
  }
}
