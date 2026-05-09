import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../models/activity.dart';
import '../models/expense.dart';
import '../models/service_model.dart';
import '../models/journal_entry.dart';
import '../models/safety_checkin.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../models/place_rating.dart';
import '../models/destination_rating.dart';
import '../services/push_notification_service.dart';

class TripController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<AppNotification>> getNotifications() {
    String uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppNotification.fromFirestore(doc))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> _sendInternalNotification({
    required String receiverId,
    required String postId,
    required String postName,
    required NotificationType type,
    String? commentText,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.uid == receiverId) return;

    final notification = AppNotification(
      id: '',
      receiverId: receiverId,
      senderId: user.uid,
      senderName: user.displayName ?? 'Um viajante',
      postId: postId,
      postName: postName,
      type: type,
      commentText: commentText,
      createdAt: DateTime.now(),
    );

    await _db.collection('notifications').add(notification.toMap());

    if (type == NotificationType.like) {
      await PushNotificationService.notifyNewLike(
        postName,
        user.displayName ?? 'Alguém',
        receiverId,
      );
    } else if (type == NotificationType.comment) {
      await PushNotificationService.notifyNewComment(
        postName,
        user.displayName ?? 'Alguém',
        receiverId,
      );
    }
  }

  Stream<List<Trip>> getTrips({String? status}) {
    String uid = _auth.currentUser?.uid ?? '';
    var query = _db.collection('trips').where('members', arrayContains: uid);
    if (status != null) query = query.where('status', isEqualTo: status);
    return query.snapshots().map((snapshot) {
      final trips =
          snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
      trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return trips;
    });
  }

  Future<Trip> getTripById(String tripId) async {
    final doc = await _db.collection('trips').doc(tripId).get();
    return Trip.fromFirestore(doc);
  }

  Future<void> addTrip(Trip trip) async =>
      await _db.collection('trips').add(trip.toMap());
  Future<void> deleteTrip(String tripId) async =>
      await _db.collection('trips').doc(tripId).delete();

  Future<void> updateTripStatus(String tripId, String newStatus) async {
    await _db.collection('trips').doc(tripId).update({'status': newStatus});
  }

  /// Atualiza o orçamento e moeda base de uma viagem
  Future<void> updateTripBudget(
      String tripId, double newBudget, String newCurrency) async {
    await _db.collection('trips').doc(tripId).update({
      'budget': newBudget,
      'baseCurrency': newCurrency,
    });
  }

  Future<void> joinTrip(String tripId) async {
    final uid = _auth.currentUser?.uid ?? '';
    await _db.collection('trips').doc(tripId).update({
      'members': FieldValue.arrayUnion([uid]),
      'isGroup': true,
    });
  }

  Future<void> removeMember(String tripId, String memberId) async {
    final uid = _auth.currentUser?.uid ?? '';
    final doc = await _db.collection('trips').doc(tripId).get();
    final trip = Trip.fromFirestore(doc);
    if (uid != trip.ownerId)
      throw Exception('Somente o admin pode remover membros.');
    await _db.collection('trips').doc(tripId).update({
      'members': FieldValue.arrayRemove([memberId]),
    });
  }

  Future<List<UserModel>> getTripMembers(List<String> memberIds) async {
    final List<UserModel> users = [];
    for (final uid in memberIds) {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists)
        users.add(UserModel.fromMap(doc.data() as Map<String, dynamic>));
    }
    return users;
  }

  Stream<List<ServiceModel>> getCommunityServices() {
    return _db
        .collection('services')
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final services =
          snap.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList();
      services.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      return services;
    });
  }

  /// Busca avaliações de destino públicas para a comunidade
  Stream<List<DestinationRating>> getCommunityDestinationRatings() {
    return _db
        .collection('destination_ratings')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => DestinationRating.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<DestinationRating>> getPersonalDestinationRatings() {
    String uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('destination_ratings')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => DestinationRating.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<ServiceModel>> getPersonalServices() {
    String uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('services')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<ServiceModel>> getSavedServices() {
    String uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('services')
        .where('savedBy', arrayContains: uid)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList(),
        );
  }

  Future<void> saveService(ServiceModel service) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('[SAVE_SERVICE] Erro: Usuário não autenticado');
        throw Exception('Usuário não autenticado');
      }

      // Busca o nome do usuário do Firestore se displayName estiver vazio
      String userName = user.displayName ?? '';
      if (userName.isEmpty) {
        try {
          final userDoc = await _db.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            userName = userDoc.data()?['name'] ?? 'Viajante';
          } else {
            userName = 'Viajante';
          }
        } catch (e) {
          debugPrint('[SAVE_SERVICE] Erro ao buscar nome do usuário: $e');
          userName = 'Viajante';
        }
      }

      final payload = service.toMap();
      payload['ownerId'] = user.uid;
      payload['userName'] = userName;
      payload['createdAt'] = FieldValue.serverTimestamp();

      debugPrint('[SAVE_SERVICE] Salvando post na comunidade...');
      debugPrint('[SAVE_SERVICE] Autor: $userName (UID: ${user.uid})');
      final docRef = await _db.collection('services').add(payload);
      debugPrint('[SAVE_SERVICE] Post salvo com sucesso! ID: ${docRef.id}');
    } catch (e) {
      debugPrint('[SAVE_SERVICE] Erro ao salvar post: $e');
      rethrow;
    }
  }

  Future<void> updateService(ServiceModel service) async =>
      await _db.collection('services').doc(service.id).update(service.toMap());

  Future<void> deleteService(String serviceId, String ownerId) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty || uid != ownerId) {
      throw Exception('Somente o autor pode excluir esta postagem.');
    }

    await _db.collection('services').doc(serviceId).delete();
  }

  Future<void> deleteDestinationRating(
    String ratingId,
    String ownerId,
  ) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty || uid != ownerId) {
      throw Exception('Somente o autor pode excluir esta avaliação.');
    }

    await _db.collection('destination_ratings').doc(ratingId).delete();
  }

  Future<void> toggleSaveService(
    String serviceId,
    List<String> currentSavedBy,
  ) async {
    String uid = _auth.currentUser?.uid ?? '';
    DocumentReference docRef = _db.collection('services').doc(serviceId);
    if (currentSavedBy.contains(uid)) {
      await docRef.update({
        'savedBy': FieldValue.arrayRemove([uid]),
        'savesCount': FieldValue.increment(-1),
      });
    } else {
      await docRef.update({
        'savedBy': FieldValue.arrayUnion([uid]),
        'savesCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> toggleLikeService(
    String serviceId,
    List<String> currentLikes,
  ) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        debugPrint('[LIKE] Erro: Usuário não autenticado');
        return;
      }

      DocumentReference docRef = _db.collection('services').doc(serviceId);

      if (currentLikes.contains(uid)) {
        debugPrint('[LIKE] Removendo curtida do usuário $uid');
        await docRef.update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        debugPrint('[LIKE] Adicionando curtida do usuário $uid');
        await docRef.update({
          'likes': FieldValue.arrayUnion([uid]),
        });

        try {
          final doc = await docRef.get();
          if (doc.exists) {
            final service = ServiceModel.fromFirestore(doc);
            // Não envia notificação para si mesmo
            if (service.ownerId != uid) {
              await _sendInternalNotification(
                receiverId: service.ownerId,
                postId: serviceId,
                postName: service.name,
                type: NotificationType.like,
              );
            }
          }
        } catch (e) {
          debugPrint('[LIKE] Erro ao enviar notificação: $e');
          // Não falha a curtida se a notificação falhar
        }
      }
      debugPrint('[LIKE] Curtida atualizada com sucesso');
    } catch (e) {
      debugPrint('[LIKE] Erro ao alternar curtida: $e');
      rethrow;
    }
  }

  Future<void> addServiceComment(
    String serviceId,
    List<PostComment> currentComments,
    String text,
  ) async {
    if (text.trim().isEmpty) return;
    final user = _auth.currentUser;

    final comment = PostComment(
      id: _db.collection('services').doc().id,
      userId: user?.uid ?? '',
      userName: user?.displayName ?? 'Viajante',
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    await _db.collection('services').doc(serviceId).update({
      'comments': FieldValue.arrayUnion([comment.toMap()]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    final doc = await _db.collection('services').doc(serviceId).get();
    final service = ServiceModel.fromFirestore(doc);

    await _sendInternalNotification(
      receiverId: service.ownerId,
      postId: serviceId,
      postName: service.name,
      type: NotificationType.comment,
      commentText: text.trim(),
    );
  }

  // --- ATIVIDADES ---
  Stream<List<Activity>> getActivities(String tripId) {
    return _db
        .collection('activities')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) => Activity.fromFirestore(doc)).toList();
      list.sort((a, b) => a.time.compareTo(b.time));
      return list;
    });
  }

  Stream<List<String>> watchTripCategories(String tripId) {
    return _db
        .collection('activities')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snap) {
      final cats = snap.docs
          .map((doc) => doc.data()['category']?.toString() ?? 'Geral')
          .toSet()
          .toList();
      return ['Todos', ...cats];
    });
  }

  Future<void> addActivity(Activity activity) async =>
      await _db.collection('activities').add(activity.toMap());
  Future<void> updateActivity(Activity activity) async => await _db
      .collection('activities')
      .doc(activity.id)
      .update(activity.toMap());
  Future<void> deleteActivity(String activityId) async =>
      await _db.collection('activities').doc(activityId).delete();

  Future<void> reorderActivities(List<Activity> activities) async {
    final batch = _db.batch();
    for (int i = 0; i < activities.length; i++) {
      batch.update(_db.collection('activities').doc(activities[i].id), {
        'index': i,
      });
    }
    await batch.commit();
  }

  Future<void> voteActivity(String activityId, String userId, int vote) async {
    await _db.collection('activities').doc(activityId).update({
      'votes.$userId': vote,
    });
  }

  Future<void> addOpinion(String activityId, String text) async {
    final user = _auth.currentUser;
    await _db.collection('activities').doc(activityId).update({
      'opinions': FieldValue.arrayUnion([
        {
          'userId': user?.uid,
          'userName': user?.displayName ?? 'Viajante',
          'text': text.trim(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      ]),
    });
  }

  //dividas
  Stream<List<Expense>> getExpenses(String tripId) {
    return _db
        .collection('expenses')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) => Expense.fromFirestore(doc)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> addExpense(Expense expense) async =>
      await _db.collection('expenses').add(expense.toMap());

  Future<void> updateExpense(
          String expenseId, Map<String, dynamic> data) async =>
      await _db.collection('expenses').doc(expenseId).update(data);

  Future<void> deleteExpense(String expenseId) async =>
      await _db.collection('expenses').doc(expenseId).delete();

  //vampire diares
  Stream<List<JournalEntry>> getJournalEntries(String tripId) => _db
      .collection('journal')
      .where('tripId', isEqualTo: tripId)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList(),
      );
  Future<void> addJournalEntry(JournalEntry entry) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('[JOURNAL] Erro: Usuário não autenticado');
        throw Exception('Usuário não autenticado');
      }

      debugPrint('[JOURNAL] Salvando registro no journal...');
      final docRef = await _db.collection('journal').add(entry.toMap());
      debugPrint('[JOURNAL] Registro salvo com sucesso! ID: ${docRef.id}');
    } catch (e) {
      debugPrint('[JOURNAL] Erro ao salvar registro: $e');
      rethrow;
    }
  }

  Stream<List<SafetyCheckIn>> getSafetyHistory(String tripId) => _db
      .collection('safety')
      .where('tripId', isEqualTo: tripId)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((doc) => SafetyCheckIn.fromFirestore(doc)).toList(),
      );

  Future<void> performSafetyCheckIn(
    String tripId,
    String location,
    bool isPanic, {
    double? latitude,
    double? longitude,
  }) async {
    final user = _auth.currentUser;
    final now = DateTime.now();
    final checkIn = SafetyCheckIn(
      id: '',
      tripId: tripId,
      userId: user?.uid ?? '',
      timestamp: now,
      locationName: location,
      isPanic: isPanic,
      latitude: latitude,
      longitude: longitude,
      userName: user?.displayName ?? 'Viajante',
    );

    final checkInRef = await _db.collection('safety').add(checkIn.toMap());

    final tripDoc = await _db.collection('trips').doc(tripId).get();
    final trip = Trip.fromFirestore(tripDoc);

    if (isPanic) {
      final recipientIds =
          trip.members.where((memberId) => memberId != user?.uid);

      for (final memberId in recipientIds) {
        await _db.collection('notifications').add(
              AppNotification(
                id: '',
                receiverId: memberId,
                senderId: user?.uid ?? '',
                senderName: user?.displayName ?? 'Um viajante',
                postId: tripId,
                postName: trip.destination,
                type: NotificationType.safetyAlert,
                commentText:
                    "ALERTA SOS: Estou em $location e preciso de ajuda!",
                createdAt: now,
              ).toMap(),
            );
      }

      await _db.collection('trips').doc(tripId).set({
        'activeSafetyAlert': {
          'checkInId': checkInRef.id,
          'tripId': tripId,
          'userId': user?.uid ?? '',
          'userName': user?.displayName ?? 'Viajante',
          'tripDestination': trip.destination,
          'locationName': location,
          'latitude': latitude,
          'longitude': longitude,
          'createdAt': now,
          'isActive': true,
        },
      }, SetOptions(merge: true));

      debugPrint("Alerta de segurança registrado para $tripId");
      return;
    }

    await _db.collection('trips').doc(tripId).set({
      'activeSafetyAlert': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> watchActiveSafetyAlert(String tripId) {
    return _db.collection('trips').doc(tripId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;

      final alert = data['activeSafetyAlert'];
      if (alert is Map<String, dynamic> && alert['isActive'] == true) {
        return alert;
      }
      return null;
    });
  }

  Future<void> acknowledgeSafetyAlert(String checkInId, String userId) async {
    final doc = await _db.collection('safety').doc(checkInId).get();
    if (!doc.exists) return;

    final checkIn = SafetyCheckIn.fromFirestore(doc);
    final updatedAcknowledged = List<String>.from(checkIn.acknowledgedBy)
      ..add(userId);

    await _db.collection('safety').doc(checkInId).update({
      'acknowledgedBy': updatedAcknowledged,
      'isAcknowledged': true,
    });
  }

  // ==================== JOURNAL REACTIONS ====================

  /// Adiciona ou remove uma reação de um usuário em um registro de diário
  Future<void> addReactionToJournalEntry({
    required String tripId,
    required String entryId,
    required ReactionType reactionType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef =
        _db.collection('trips').doc(tripId).collection('journal').doc(entryId);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final entry = JournalEntry.fromFirestore(doc);
    final reactionKey = reactionType.toString().split('.').last;

    // Obtém a lista atual de usuários que reagiram com este tipo
    List<String> usersList = List<String>.from(
      entry.reactions[reactionKey] ?? [],
    );

    // Se o usuário já reagiu com este tipo, remove a reação
    final isRemoving = usersList.contains(user.uid);
    if (isRemoving) {
      usersList.remove(user.uid);
    } else {
      // Remove reação anterior do usuário (se houver)
      final updatedReactions = Map<String, List<String>>.from(entry.reactions);
      for (var key in updatedReactions.keys) {
        updatedReactions[key]!.remove(user.uid);
      }

      // Adiciona nova reação
      usersList.add(user.uid);

      // Envia notificação para o dono do journal entry (apenas ao adicionar reação)
      if (entry.userId != user.uid) {
        try {
          // Usa locationName ou um trecho do content como nome do post
          final postName = entry.locationName ??
              (entry.content.length > 30
                  ? '${entry.content.substring(0, 30)}...'
                  : entry.content);

          await _sendInternalNotification(
            receiverId: entry.userId,
            postId: entryId,
            postName: postName,
            type: NotificationType.like,
          );
        } catch (e) {
          debugPrint('[REACTION] Erro ao enviar notificação: $e');
          // Não falha a reação se a notificação falhar
        }
      }
    }

    // Atualiza no Firestore
    await docRef.update({'reactions.$reactionKey': usersList});

    debugPrint('Reação $reactionKey atualizada para o registro $entryId');
  }

  /// Gera um token único para compartilhamento público de um registro
  Future<String> generateShareToken(String tripId, String entryId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final token = '${entryId}_$timestamp';

    final docRef =
        _db.collection('trips').doc(tripId).collection('journal').doc(entryId);

    await docRef.update({'isPublic': true, 'shareToken': token});

    debugPrint('Token de compartilhamento gerado: $token');
    return token;
  }

  /// Obtém um registro de diário público pelo token de compartilhamento
  Future<JournalEntry?> getPublicJournalEntry(String shareToken) async {
    try {
      // Busca em todas as viagens (pode ser otimizado com índice no Firestore)
      final tripsSnapshot = await _db.collection('trips').get();

      for (var tripDoc in tripsSnapshot.docs) {
        final journalSnapshot = await _db
            .collection('trips')
            .doc(tripDoc.id)
            .collection('journal')
            .where('shareToken', isEqualTo: shareToken)
            .where('isPublic', isEqualTo: true)
            .limit(1)
            .get();

        if (journalSnapshot.docs.isNotEmpty) {
          return JournalEntry.fromFirestore(journalSnapshot.docs.first);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao buscar registro público: $e');
      return null;
    }
  }

  /// Stream para acompanhar reações em tempo real
  Stream<JournalEntry> watchJournalEntry(String tripId, String entryId) {
    return _db
        .collection('trips')
        .doc(tripId)
        .collection('journal')
        .doc(entryId)
        .snapshots()
        .map((doc) => JournalEntry.fromFirestore(doc));
  }

  // ==================== PLACE RATINGS ====================

  /// Busca todas as avaliações públicas de um lugar específico
  Stream<List<PlaceRating>> getPlaceRatings(String placeId) {
    return _db
        .collection('place_ratings')
        .where('placeId', isEqualTo: placeId)
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final ratings =
          snap.docs.map((doc) => PlaceRating.fromFirestore(doc)).toList();
      ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return ratings;
    });
  }

  /// Busca estatísticas agregadas de um lugar
  Future<PlaceStats?> getPlaceStats(String placeId) async {
    try {
      final snapshot = await _db
          .collection('place_ratings')
          .where('placeId', isEqualTo: placeId)
          .where('isPublic', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final ratings =
          snapshot.docs.map((doc) => PlaceRating.fromFirestore(doc)).toList();
      return PlaceStats.fromRatings(ratings);
    } catch (e) {
      debugPrint('Erro ao buscar estatísticas do lugar: $e');
      return null;
    }
  }

  /// Adiciona uma nova avaliação de lugar
  Future<void> addPlaceRating(PlaceRating rating) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('[PLACE_RATING] Erro: Usuário não autenticado');
        throw Exception('Usuário não autenticado');
      }

      debugPrint(
          '[PLACE_RATING] Salvando avaliação do lugar ${rating.placeName}...');
      final docRef = await _db.collection('place_ratings').add(rating.toMap());
      debugPrint(
          '[PLACE_RATING] Avaliação salva com sucesso! ID: ${docRef.id}');
    } catch (e) {
      debugPrint('[PLACE_RATING] Erro ao salvar avaliação: $e');
      rethrow;
    }
  }

  /// Atualiza uma avaliação existente
  Future<void> updatePlaceRating(PlaceRating rating) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.uid != rating.userId) {
        throw Exception('Sem permissão para editar esta avaliação');
      }

      await _db
          .collection('place_ratings')
          .doc(rating.id)
          .update(rating.toMap());
      debugPrint('[PLACE_RATING] Avaliação atualizada com sucesso!');
    } catch (e) {
      debugPrint('[PLACE_RATING] Erro ao atualizar avaliação: $e');
      rethrow;
    }
  }

  /// Deleta uma avaliação
  Future<void> deletePlaceRating(String ratingId, String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.uid != userId) {
        throw Exception('Sem permissão para deletar esta avaliação');
      }

      await _db.collection('place_ratings').doc(ratingId).delete();
      debugPrint('[PLACE_RATING] Avaliação deletada com sucesso!');
    } catch (e) {
      debugPrint('[PLACE_RATING] Erro ao deletar avaliação: $e');
      rethrow;
    }
  }

  /// Adiciona/remove curtida em uma avaliação de lugar
  Future<void> toggleLikePlaceRating(
      String ratingId, List<String> currentLikes) async {
    try {
      final uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        debugPrint('[LIKE_RATING] Erro: Usuário não autenticado');
        return;
      }

      DocumentReference docRef = _db.collection('place_ratings').doc(ratingId);

      if (currentLikes.contains(uid)) {
        debugPrint('[LIKE_RATING] Removendo curtida do usuário $uid');
        await docRef.update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        debugPrint('[LIKE_RATING] Adicionando curtida do usuário $uid');
        await docRef.update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
      debugPrint('[LIKE_RATING] Curtida atualizada com sucesso');
    } catch (e) {
      debugPrint('[LIKE_RATING] Erro ao alternar curtida: $e');
      rethrow;
    }
  }

  /// Marca uma avaliação como útil
  Future<void> markPlaceRatingAsHelpful(String ratingId) async {
    try {
      await _db.collection('place_ratings').doc(ratingId).update({
        'helpfulCount': FieldValue.increment(1),
      });
      debugPrint('[HELPFUL_RATING] Avaliação marcada como útil');
    } catch (e) {
      debugPrint('[HELPFUL_RATING] Erro ao marcar como útil: $e');
      rethrow;
    }
  }

  /// Busca avaliações do usuário atual
  Stream<List<PlaceRating>> getUserPlaceRatings() {
    final uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('place_ratings')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final ratings =
          snap.docs.map((doc) => PlaceRating.fromFirestore(doc)).toList();
      ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return ratings;
    });
  }

  /// Verifica se o usuário já avaliou um lugar específico
  Future<PlaceRating?> getUserRatingForPlace(String placeId) async {
    try {
      final uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return null;

      final snapshot = await _db
          .collection('place_ratings')
          .where('placeId', isEqualTo: placeId)
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return PlaceRating.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Erro ao buscar avaliação do usuário: $e');
      return null;
    }
  }

  /// Busca avaliações por categoria
  Stream<List<PlaceRating>> getPlaceRatingsByCategory(String category) {
    return _db
        .collection('place_ratings')
        .where('placeCategory', isEqualTo: category)
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final ratings =
          snap.docs.map((doc) => PlaceRating.fromFirestore(doc)).toList();
      ratings.sort((a, b) => b.overallRating.compareTo(a.overallRating));
      return ratings;
    });
  }

  /// Busca top avaliações (melhores notas)
  Future<List<PlaceRating>> getTopRatedPlaces({int limit = 10}) async {
    try {
      final snapshot = await _db
          .collection('place_ratings')
          .where('isPublic', isEqualTo: true)
          .orderBy('overallRating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PlaceRating.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Erro ao buscar top avaliações: $e');
      return [];
    }
  }

  // ==================== SAVED POSTS ====================

  /// Salva um post (serviço ou avaliação de destino) na lista do usuário
  Future<void> savePost(String postId, String postType) async {
    try {
      final uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        debugPrint('[SAVE_POST] Erro: Usuário não autenticado');
        throw Exception('Usuário não autenticado');
      }

      // Cria um identificador único combinando tipo e ID
      final savedPostId = '${postType}_$postId';

      await _db.collection('users').doc(uid).update({
        'savedPosts': FieldValue.arrayUnion([savedPostId]),
      });

      debugPrint('[SAVE_POST] Post $savedPostId salvo com sucesso');
    } catch (e) {
      debugPrint('[SAVE_POST] Erro ao salvar post: $e');
      rethrow;
    }
  }

  /// Remove um post da lista de salvos do usuário
  Future<void> unsavePost(String postId, String postType) async {
    try {
      final uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        debugPrint('[UNSAVE_POST] Erro: Usuário não autenticado');
        throw Exception('Usuário não autenticado');
      }

      final savedPostId = '${postType}_$postId';

      await _db.collection('users').doc(uid).update({
        'savedPosts': FieldValue.arrayRemove([savedPostId]),
      });

      debugPrint('[UNSAVE_POST] Post $savedPostId removido com sucesso');
    } catch (e) {
      debugPrint('[UNSAVE_POST] Erro ao remover post: $e');
      rethrow;
    }
  }

  /// Verifica se um post está salvo pelo usuário
  Future<bool> isPostSaved(String postId, String postType) async {
    try {
      final uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return false;

      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final savedPosts = List<String>.from(userData['savedPosts'] ?? []);
      final savedPostId = '${postType}_$postId';

      return savedPosts.contains(savedPostId);
    } catch (e) {
      debugPrint('[IS_POST_SAVED] Erro ao verificar post salvo: $e');
      return false;
    }
  }

  /// Busca todos os posts salvos do usuário (serviços e avaliações)
  Future<Map<String, List<dynamic>>> getSavedPosts() async {
    try {
      final uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        return {'services': [], 'ratings': []};
      }

      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        return {'services': [], 'ratings': []};
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final savedPosts = List<String>.from(userData['savedPosts'] ?? []);

      final List<ServiceModel> services = [];
      final List<DestinationRating> ratings = [];

      for (final savedPostId in savedPosts) {
        final parts = savedPostId.split('_');
        if (parts.length < 2) continue;

        final type = parts[0];
        final postId = parts.sublist(1).join('_');

        if (type == 'service') {
          try {
            final doc = await _db.collection('services').doc(postId).get();
            if (doc.exists) {
              services.add(ServiceModel.fromFirestore(doc));
            }
          } catch (e) {
            debugPrint('[GET_SAVED_POSTS] Erro ao buscar serviço $postId: $e');
          }
        } else if (type == 'rating') {
          try {
            final doc =
                await _db.collection('destination_ratings').doc(postId).get();
            if (doc.exists) {
              ratings.add(DestinationRating.fromFirestore(doc));
            }
          } catch (e) {
            debugPrint(
                '[GET_SAVED_POSTS] Erro ao buscar avaliação $postId: $e');
          }
        }
      }

      debugPrint(
          '[GET_SAVED_POSTS] ${services.length} serviços e ${ratings.length} avaliações salvos');
      return {'services': services, 'ratings': ratings};
    } catch (e) {
      debugPrint('[GET_SAVED_POSTS] Erro ao buscar posts salvos: $e');
      return {'services': [], 'ratings': []};
    }
  }

  /// Stream para acompanhar posts salvos em tempo real
  Stream<List<String>> watchSavedPosts() {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return Stream.value([]);
    }

    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return [];
      final userData = doc.data() as Map<String, dynamic>;
      return List<String>.from(userData['savedPosts'] ?? []);
    });
  }
}
