import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';
import '../models/activity.dart';
import '../models/expense.dart';
import '../models/service_model.dart';
import '../models/journal_entry.dart';
import '../models/safety_checkin.dart';
import '../models/user_model.dart';

class TripController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Trip>> getTrips({String? status}) {
    String uid = _auth.currentUser?.uid ?? '';
    var query = _db.collection('trips').where('members', arrayContains: uid);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      final trips = snapshot.docs
          .map((doc) => Trip.fromFirestore(doc))
          .toList();
      trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return trips;
    });
  }

  Future<void> addTrip(Trip trip) async {
    await _db.collection('trips').add(trip.toMap());
  }

  Future<void> deleteTrip(String tripId) async {
    await _db.collection('trips').doc(tripId).delete();
  }

  Future<void> updateTripStatus(String tripId, String newStatus) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) throw Exception('Usuário não autenticado.');

    final doc = await _db.collection('trips').doc(tripId).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Viagem não encontrada.');
    }

    final trip = Trip.fromFirestore(doc);
    if (!trip.isAdmin(uid)) {
      throw Exception(
        'Somente o administrador pode alterar o status da viagem.',
      );
    }

    await _db.collection('trips').doc(tripId).update({'status': newStatus});
  }

  Future<void> joinTrip(String tripId) async {
    final user = _auth.currentUser;
    final uid = user?.uid ?? '';
    if (uid.isEmpty) throw Exception("Usuário não autenticado");

    final userRef = _db.collection('users').doc(uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      final displayName = user?.displayName?.trim() ?? '';
      final email = user?.email?.trim() ?? '';
      await userRef.set({
        'uid': uid,
        'name': displayName,
        'userName': displayName,
        'email': email,
        'phone': '',
        'emergencyContact': '',
        'emergencyPhone': '',
        'bio': '',
        'photoUrl': null,
        'isPremium': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = userDoc.data() ?? {};
      final storedName = (data['name'] ?? data['userName'] ?? '')
          .toString()
          .trim();
      final displayName = user?.displayName?.trim() ?? '';
      final email = user?.email?.trim() ?? '';

      if (storedName.isEmpty ||
          ((data['email'] ?? '').toString().trim().isEmpty &&
              email.isNotEmpty)) {
        await userRef.set({
          'uid': uid,
          'name': storedName.isNotEmpty ? storedName : displayName,
          'userName': storedName.isNotEmpty ? storedName : displayName,
          'email': (data['email'] ?? email).toString().trim(),
        }, SetOptions(merge: true));
      }
    }

    await _db.collection('trips').doc(tripId).update({
      'members': FieldValue.arrayUnion([uid]),
      'isGroup': true,
    });
  }

  Future<void> removeMember(String tripId, String memberId) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) throw Exception('Usuário não autenticado.');

    final tripDoc = await _db.collection('trips').doc(tripId).get();
    if (!tripDoc.exists || tripDoc.data() == null) {
      throw Exception('Viagem não encontrada.');
    }

    final trip = Trip.fromFirestore(tripDoc);
    if (!trip.isAdmin(uid)) {
      throw Exception('Somente o administrador pode remover membros.');
    }

    if (memberId == trip.ownerId) {
      throw Exception('O administrador da viagem não pode ser removido.');
    }

    await _db.collection('trips').doc(tripId).update({
      'members': FieldValue.arrayRemove([memberId]),
    });
  }

  Future<List<UserModel>> getTripMembers(List<String> memberIds) async {
    final List<UserModel> users = [];
    final currentUser = _auth.currentUser;
    final currentUid = currentUser?.uid;
    final uniqueIds = memberIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final Map<String, Map<String, dynamic>> userDataByUid = {};

    for (final uid in uniqueIds) {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        userDataByUid[uid] = doc.data()!;
      }
    }

    final unresolvedIds = uniqueIds
        .where((uid) => !userDataByUid.containsKey(uid))
        .toList();

    for (int i = 0; i < unresolvedIds.length; i += 10) {
      final chunk = unresolvedIds.skip(i).take(10).toList();
      if (chunk.isEmpty) continue;

      final snapshot = await _db
          .collection('users')
          .where('uid', whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final uid = (data['uid'] ?? doc.id).toString().trim();
        if (uid.isNotEmpty) {
          userDataByUid[uid] = data;
        }
      }
    }

    for (final uid in uniqueIds) {
      final data = userDataByUid[uid];

      String resolvedName = '';
      String email = '';

      if (data != null) {
        resolvedName = (data['name'] ?? '').toString().trim();
        if (resolvedName.isEmpty) {
          resolvedName = (data['userName'] ?? '').toString().trim();
        }
        email = (data['email'] ?? '').toString().trim();
      }

      if (resolvedName.isEmpty && uid == currentUid) {
        final displayName = currentUser?.displayName?.trim() ?? '';
        if (displayName.isNotEmpty) {
          resolvedName = displayName;
        }
        if (email.isEmpty) {
          email = currentUser?.email?.trim() ?? '';
        }
      }

      if (resolvedName.isEmpty && email.isNotEmpty && email.contains('@')) {
        resolvedName = email.split('@').first;
      }

      if (resolvedName.isEmpty) {
        resolvedName = 'Usuário';
      }

      users.add(
        UserModel(
          uid: uid,
          name: uid == currentUid ? 'Eu' : resolvedName,
          email: email,
          phone: (data?['phone'] ?? '').toString(),
          emergencyContact: (data?['emergencyContact'] ?? '').toString(),
          emergencyPhone: (data?['emergencyPhone'] ?? '').toString(),
          bio: (data?['bio'] ?? '').toString(),
          photoUrl: data?['photoUrl'],
          isPremium: data?['isPremium'] ?? false,
        ),
      );
    }

    return users;
  }

  // --- SERVICES / COMUNIDADE ---
  Stream<List<ServiceModel>> getPersonalServices() {
    String uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('services')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ServiceModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<ServiceModel>> getCommunityServices() {
    return _db
        .collection('services')
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ServiceModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<ServiceModel>> getSavedServices() {
    String uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('services')
        .where('savedBy', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ServiceModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<String> _resolveCurrentUserName() async {
    final user = _auth.currentUser;
    final uid = user?.uid ?? '';
    String name = user?.displayName?.trim() ?? '';

    if (name.isNotEmpty) return name;

    if (uid.isNotEmpty) {
      final userDoc = await _db.collection('users').doc(uid).get();
      final data = userDoc.data();
      name = (data?['name'] ?? data?['userName'] ?? '').toString().trim();
    }

    if (name.isNotEmpty) return name;

    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Viajante';
  }

  Future<void> saveService(ServiceModel service) async {
    final normalizedService = service.copyWith(
      userName: (service.userName ?? '').trim().isNotEmpty
          ? service.userName!.trim()
          : await _resolveCurrentUserName(),
      updatedAt: DateTime.now(),
    );

    await _db.collection('services').add(normalizedService.toMap());
  }

  Future<void> updateService(ServiceModel service) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (service.id.isEmpty) throw Exception('Post inválido para edição.');
    if (uid.isEmpty) throw Exception('Usuário não autenticado.');
    if (service.ownerId != uid) {
      throw Exception('Somente o autor pode editar este post.');
    }

    final normalizedService = service.copyWith(
      userName: await _resolveCurrentUserName(),
      updatedAt: DateTime.now(),
    );

    await _db
        .collection('services')
        .doc(service.id)
        .update(normalizedService.toMap());
  }

  Future<void> deleteService(String serviceId, String ownerId) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) throw Exception('Usuário não autenticado.');
    if (uid != ownerId) {
      throw Exception('Somente o autor pode apagar este post.');
    }

    await _db.collection('services').doc(serviceId).delete();
  }

  Future<void> addServiceComment(
    String serviceId,
    List<PostComment> currentComments,
    String text,
  ) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) throw Exception('Usuário não autenticado.');

    final cleanedText = text.trim();
    if (cleanedText.isEmpty) {
      throw Exception('Digite um comentário.');
    }

    final comment = PostComment(
      id: _db.collection('services').doc().id,
      userId: uid,
      userName: await _resolveCurrentUserName(),
      text: cleanedText,
      createdAt: DateTime.now(),
    );

    final updatedComments = [...currentComments, comment];

    await _db.collection('services').doc(serviceId).update({
      'comments': updatedComments.map((item) => item.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> hideServiceComment({
    required String serviceId,
    required String ownerId,
    required String commentId,
    required List<PostComment> currentComments,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) throw Exception('Usuário não autenticado.');
    if (uid != ownerId) {
      throw Exception('Somente o autor do post pode ocultar comentários.');
    }

    final updatedComments = currentComments
        .map(
          (comment) => comment.id == commentId
              ? comment.copyWith(isHidden: true, hiddenBy: uid)
              : comment,
        )
        .toList();

    await _db.collection('services').doc(serviceId).update({
      'comments': updatedComments.map((item) => item.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> importService(ServiceModel service) async {
    final uid = _auth.currentUser?.uid ?? '';
    final userName = await _resolveCurrentUserName();

    if (service.id.isNotEmpty) {
      await _db.collection('services').doc(service.id).update({
        'savesCount': FieldValue.increment(1),
      });
    }

    final imported = ServiceModel(
      id: '',
      ownerId: uid,
      userName: userName,
      name: service.name,
      category: service.category,
      location: service.location,
      rating: service.rating,
      comment: service.comment,
      averageCost: service.averageCost,
      lastUsed: DateTime.now(),
      isPublic: false,
      photos: service.photos,
      tags: service.tags,
      comments: service.comments,
      commentsEnabled: service.commentsEnabled,
      updatedAt: DateTime.now(),
    );

    await saveService(imported);
  }

  Future<void> toggleSaveService(String serviceId, List<String> currentSavedBy) async {
    String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

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
    String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    DocumentReference docRef = _db.collection('services').doc(serviceId);

    if (currentLikes.contains(uid)) {
      await docRef.update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await docRef.update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  // --- ACTIVITIES ---
  Stream<List<Activity>> getActivities(String tripId) {
    return _db
        .collection('activities')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) {
          final activities = snapshot.docs
              .map((doc) => Activity.fromFirestore(doc))
              .toList();
          activities.sort((a, b) {
            int timeCompare = a.time.compareTo(b.time);
            if (timeCompare != 0) return timeCompare;
            return a.index.compareTo(b.index);
          });
          return activities;
        });
  }

  Stream<List<String>> watchTripCategories(String tripId) {
    return _db
        .collection('activities')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) {
      final activityCategories = snapshot.docs
          .map((doc) => _capitalize(doc.data()['category'] ?? 'Geral'))
          .toSet();
      
      return ['Todos', ...activityCategories.toList()..sort()];
    });
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Future<void> addActivity(Activity activity) async {
    await _db.collection('activities').add(activity.toMap());
  }

  Future<void> updateActivity(Activity activity) async {
    if (activity.id.isEmpty) return;
    await _db.collection('activities').doc(activity.id).update(activity.toMap());
  }

  Future<void> reorderActivities(List<Activity> activities) async {
    final batch = _db.batch();
    for (int i = 0; i < activities.length; i++) {
      final ref = _db.collection('activities').doc(activities[i].id);
      batch.update(ref, {'index': i});
    }
    await batch.commit();
  }

  Future<void> deleteActivity(String activityId) async {
    await _db.collection('activities').doc(activityId).delete();
  }

  Future<void> voteActivity(String activityId, String userId, int vote) async {
    await _db.collection('activities').doc(activityId).update({
      'votes.$userId': vote,
    });
  }

  Future<void> addOpinion(String activityId, String text) async {
    String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    String name = _auth.currentUser?.displayName ?? 'Viajante';

    await _db.collection('activities').doc(activityId).update({
      'opinions': FieldValue.arrayUnion([
        {
          'userId': uid,
          'userName': name,
          'text': text.trim(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      ]),
    });
  }

  // --- EXPENSES ---
  Stream<List<Expense>> getExpenses(String tripId) {
    return _db
        .collection('expenses')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) {
          final expenses = snapshot.docs
              .map((doc) => Expense.fromFirestore(doc))
              .toList();
          expenses.sort((a, b) => b.date.compareTo(a.date));
          return expenses;
        });
  }

  Future<void> addExpense(Expense expense) async {
    await _db.collection('expenses').add(expense.toMap());
  }

  Future<void> deleteExpense(String expenseId) async {
    await _db.collection('expenses').doc(expenseId).delete();
  }

  Future<void> settleDebt(
    String tripId,
    String fromUserId,
    String toUserId,
    double amount,
  ) async {
    final payment = Expense(
      id: '',
      tripId: tripId,
      title: 'Pagamento de Dívida',
      value: amount,
      category: 'payment',
      payerId: fromUserId,
      date: DateTime.now(),
      splits: {toUserId: amount},
    );
    await addExpense(payment);
  }

  // --- JOURNAL ---
  Stream<List<JournalEntry>> getJournalEntries(String tripId) {
    return _db
        .collection('journal')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) {
          final entries = snapshot.docs
              .map((doc) => JournalEntry.fromFirestore(doc))
              .toList();
          entries.sort((a, b) => b.date.compareTo(a.date));
          return entries;
        });
  }

  Future<void> addJournalEntry(JournalEntry entry) async {
    await _db.collection('journal').add(entry.toMap());
  }

  // --- SAFETY ---
  Stream<List<SafetyCheckIn>> getSafetyHistory(String tripId) {
    return _db
        .collection('safety')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => SafetyCheckIn.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  Future<void> performSafetyCheckIn(
    String tripId,
    String location,
    bool isPanic,
  ) async {
    String uid = _auth.currentUser?.uid ?? '';
    final checkIn = SafetyCheckIn(
      id: '',
      tripId: tripId,
      userId: uid,
      timestamp: DateTime.now(),
      locationName: location,
      isPanic: isPanic,
    );
    await _db.collection('safety').add(checkIn.toMap());
  }
}
