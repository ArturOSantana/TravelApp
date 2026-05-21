import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/exceptions/app_exceptions.dart';
import 'subscription_service.dart';

class TripService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  TripService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => auth.currentUser?.uid;

  Future<String> createTrip({
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required double budget,
    String? description,
    List<String>? members,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw AuthException('Usuário não autenticado', code: 'not-authenticated');
    }

    _validateTripData(
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      budget: budget,
    );

    final canCreate = await SubscriptionService.canCreateTrip();
    if (!canCreate) {
      throw SubscriptionException.limitReached('viagens');
    }

    try {
      final tripData = {
        'destination': destination.trim(),
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'budget': budget,
        'description': description?.trim(),
        'members': [userId, ...(members ?? [])],
        'createdBy': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'planned',
        'isGroup': members != null && members.isNotEmpty,
      };

      final docRef = await firestore.collection('trips').add(tripData);

      return docRef.id;
    } catch (e) {
      if (e is AppException) rethrow;
      throw GenericException(
        'Erro ao criar viagem',
        code: 'create-trip-failed',
        originalError: e,
      );
    }
  }

  /// Atualiza uma viagem existente
  ///
  /// Throws [ValidationException] se os dados forem inválidos
  /// Throws [AuthException] se o usuário não tiver permissão
  Future<void> updateTrip({
    required String tripId,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    String? description,
    String? status,
  }) async {
    // Validar autenticação
    final userId = _currentUserId;
    if (userId == null) {
      throw AuthException('Usuário não autenticado', code: 'not-authenticated');
    }

    // Verificar se a viagem existe e se o usuário tem permissão
    final tripDoc = await firestore.collection('trips').doc(tripId).get();
    if (!tripDoc.exists) {
      throw ValidationException('Viagem não encontrada',
          code: 'trip-not-found');
    }

    final tripData = tripDoc.data()!;
    final members = List<String>.from(tripData['members'] ?? []);
    if (!members.contains(userId)) {
      throw AuthException(
        'Você não tem permissão para editar esta viagem',
        code: 'permission-denied',
      );
    }

    // Validar novos dados se fornecidos
    if (destination != null ||
        startDate != null ||
        endDate != null ||
        budget != null) {
      _validateTripData(
        destination: destination ?? tripData['destination'],
        startDate: startDate ?? (tripData['startDate'] as Timestamp).toDate(),
        endDate: endDate ?? (tripData['endDate'] as Timestamp).toDate(),
        budget: budget ?? tripData['budget'],
      );
    }

    try {
      // Preparar dados para atualização
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (destination != null) updateData['destination'] = destination.trim();
      if (startDate != null)
        updateData['startDate'] = Timestamp.fromDate(startDate);
      if (endDate != null) updateData['endDate'] = Timestamp.fromDate(endDate);
      if (budget != null) updateData['budget'] = budget;
      if (description != null) updateData['description'] = description.trim();
      if (status != null) {
        if (!['planned', 'active', 'completed', 'cancelled'].contains(status)) {
          throw ValidationException.invalidValue('status', 'Status inválido');
        }
        updateData['status'] = status;
      }

      // Atualizar viagem
      await firestore.collection('trips').doc(tripId).update(updateData);
    } catch (e) {
      if (e is AppException) rethrow;
      throw GenericException(
        'Erro ao atualizar viagem',
        code: 'update-trip-failed',
        originalError: e,
      );
    }
  }

  /// Deleta uma viagem
  ///
  /// Throws [AuthException] se o usuário não tiver permissão
  Future<void> deleteTrip(String tripId) async {
    // Validar autenticação
    final userId = _currentUserId;
    if (userId == null) {
      throw AuthException('Usuário não autenticado', code: 'not-authenticated');
    }

    // Verificar permissão (apenas criador pode deletar)
    final tripDoc = await firestore.collection('trips').doc(tripId).get();
    if (!tripDoc.exists) {
      throw ValidationException('Viagem não encontrada',
          code: 'trip-not-found');
    }

    final tripData = tripDoc.data()!;
    if (tripData['createdBy'] != userId) {
      throw AuthException(
        'Apenas o criador pode deletar a viagem',
        code: 'permission-denied',
      );
    }

    try {
      await firestore.collection('trips').doc(tripId).delete();
    } catch (e) {
      throw GenericException(
        'Erro ao deletar viagem',
        code: 'delete-trip-failed',
        originalError: e,
      );
    }
  }

  /// Adiciona um membro à viagem
  ///
  /// Throws [SubscriptionException] se o limite de membros for atingido
  Future<void> addMember(String tripId, String memberEmail) async {
    // Validar autenticação
    final userId = _currentUserId;
    if (userId == null) {
      throw AuthException('Usuário não autenticado', code: 'not-authenticated');
    }

    // Verificar limite de membros
    final canAdd = await SubscriptionService.canAddMember(tripId);
    if (!canAdd) {
      throw SubscriptionException.limitReached('membros');
    }

    try {
      // Buscar usuário pelo email
      // Nota: Isso requer uma collection de usuários com email indexado
      final userQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: memberEmail.trim().toLowerCase())
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw ValidationException('Usuário não encontrado',
            code: 'user-not-found');
      }

      final memberId = userQuery.docs.first.id;

      // Adicionar membro
      await firestore.collection('trips').doc(tripId).update({
        'members': FieldValue.arrayUnion([memberId]),
        'isGroup': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is AppException) rethrow;
      throw GenericException(
        'Erro ao adicionar membro',
        code: 'add-member-failed',
        originalError: e,
      );
    }
  }

  /// Remove um membro da viagem
  Future<void> removeMember(String tripId, String memberId) async {
    // Validar autenticação
    final userId = _currentUserId;
    if (userId == null) {
      throw AuthException('Usuário não autenticado', code: 'not-authenticated');
    }

    try {
      final tripDoc = await firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) {
        throw ValidationException('Viagem não encontrada',
            code: 'trip-not-found');
      }

      final tripData = tripDoc.data()!;

      // Não permitir remover o criador
      if (tripData['createdBy'] == memberId) {
        throw ValidationException(
          'Não é possível remover o criador da viagem',
          code: 'cannot-remove-creator',
        );
      }

      // Remover membro
      await firestore.collection('trips').doc(tripId).update({
        'members': FieldValue.arrayRemove([memberId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is AppException) rethrow;
      throw GenericException(
        'Erro ao remover membro',
        code: 'remove-member-failed',
        originalError: e,
      );
    }
  }

  /// Valida os dados de uma viagem
  void _validateTripData({
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required double budget,
  }) {
    // Validar destino
    if (destination.trim().isEmpty) {
      throw ValidationException.emptyField('destination');
    }
    if (destination.trim().length < 3) {
      throw ValidationException.invalidValue(
        'destination',
        'O destino deve ter pelo menos 3 caracteres',
      );
    }

    // Validar datas
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (startDate.isBefore(today)) {
      throw ValidationException.invalidValue(
        'startDate',
        'A data de início não pode ser no passado',
      );
    }

    if (endDate.isBefore(startDate)) {
      throw ValidationException.dateRangeInvalid();
    }

    if (endDate.isAfter(startDate.add(const Duration(days: 365)))) {
      throw ValidationException.invalidValue(
        'endDate',
        'A viagem não pode durar mais de 1 ano',
      );
    }

    // Validar orçamento
    if (budget < 0) {
      throw ValidationException.invalidValue(
        'budget',
        'O orçamento não pode ser negativo',
      );
    }
    if (budget > 1000000000) {
      throw ValidationException.invalidValue(
        'budget',
        'Orçamento muito alto',
      );
    }
  }
}
