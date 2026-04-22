import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';
import '../models/activity.dart';
import '../models/expense.dart';
import '../models/service_model.dart';
import '../models/journal_entry.dart';
import '../models/safety_checkin.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../services/push_notification_service.dart';

class TripController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- NOTIFICAÇÕES (SINO) ---
  Stream<List<AppNotification>> getNotifications() {
    String uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
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
      await PushNotificationService.notifyNewLike(postName, user.displayName ?? 'Alguém');
    } else if (type == NotificationType.comment) {
      await PushNotificationService.notifyNewComment(postName, user.displayName ?? 'Alguém');
    }
  }

  // --- VIAGENS ---
  Stream<List<Trip>> getTrips({String? status}) {
    String uid = _auth.currentUser?.uid ?? '';
    var query = _db.collection('trips').where('members', arrayContains: uid);
    if (status != null) query = query.where('status', isEqualTo: status);
    return query.snapshots().map((snapshot) {
      final trips = snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
      trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return trips;
    });
  }

  Future<Trip> getTripById(String tripId) async {
    final doc = await _db.collection('trips').doc(tripId).get();
    return Trip.fromFirestore(doc);
  }

  Future<void> addTrip(Trip trip) async => await _db.collection('trips').add(trip.toMap());
  Future<void> deleteTrip(String tripId) async => await _db.collection('trips').doc(tripId).delete();

  Future<void> updateTripStatus(String tripId, String newStatus) async {
    await _db.collection('trips').doc(tripId).update({'status': newStatus});
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
    if (uid != trip.ownerId) throw Exception('Somente o admin pode remover membros.');
    await _db.collection('trips').doc(tripId).update({
      'members': FieldValue.arrayRemove([memberId]),
    });
  }

  Future<List<UserModel>> getTripMembers(List<String> memberIds) async {
    final List<UserModel> users = [];
    for (final uid in memberIds) {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) users.add(UserModel.fromMap(doc.data() as Map<String, dynamic>));
    }
    return users;
  }

  // --- COMUNIDADE / SERVIÇOS ---
  Stream<List<ServiceModel>> getCommunityServices() {
    return _db.collection('services').where('isPublic', isEqualTo: true).snapshots().map(
      (snap) => snap.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList(),
    );
  }

  Stream<List<ServiceModel>> getPersonalServices() {
    String uid = _auth.currentUser?.uid ?? '';
    return _db.collection('services').where('ownerId', isEqualTo: uid).snapshots().map(
      (snap) => snap.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList(),
    );
  }

  Stream<List<ServiceModel>> getSavedServices() {
    String uid = _auth.currentUser?.uid ?? '';
    return _db.collection('services').where('savedBy', arrayContains: uid).snapshots().map(
      (snap) => snap.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList(),
    );
  }

  Future<void> saveService(ServiceModel service) async {
    final user = _auth.currentUser;
    final payload = service.toMap();
    payload['ownerId'] = user?.uid;
    payload['userName'] = user?.displayName ?? 'Viajante';
    await _db.collection('services').add(payload);
  }

  Future<void> updateService(ServiceModel service) async => await _db.collection('services').doc(service.id).update(service.toMap());
  Future<void> deleteService(String serviceId, String ownerId) async => await _db.collection('services').doc(serviceId).delete();

  Future<void> toggleSaveService(String serviceId, List<String> currentSavedBy) async {
    String uid = _auth.currentUser?.uid ?? '';
    DocumentReference docRef = _db.collection('services').doc(serviceId);
    if (currentSavedBy.contains(uid)) {
      await docRef.update({'savedBy': FieldValue.arrayRemove([uid]), 'savesCount': FieldValue.increment(-1)});
    } else {
      await docRef.update({'savedBy': FieldValue.arrayUnion([uid]), 'savesCount': FieldValue.increment(1)});
    }
  }

  Future<void> toggleLikeService(String serviceId, List<String> currentLikes) async {
    String uid = _auth.currentUser?.uid ?? '';
    DocumentReference docRef = _db.collection('services').doc(serviceId);
    if (currentLikes.contains(uid)) {
      await docRef.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await docRef.update({'likes': FieldValue.arrayUnion([uid])});
      final doc = await docRef.get();
      final service = ServiceModel.fromFirestore(doc);
      await _sendInternalNotification(receiverId: service.ownerId, postId: serviceId, postName: service.name, type: NotificationType.like);
    }
  }

  Future<void> addServiceComment(String serviceId, List<PostComment> currentComments, String text) async {
    if (text.trim().isEmpty) return;
    final user = _auth.currentUser;
    
    final comment = PostComment(
      id: _db.collection('services').doc().id, 
      userId: user?.uid ?? '', 
      userName: user?.displayName ?? 'Viajante', 
      text: text.trim(), 
      createdAt: DateTime.now()
    );

    await _db.collection('services').doc(serviceId).update({
      'comments': FieldValue.arrayUnion([comment.toMap()]), 
      'updatedAt': Timestamp.fromDate(DateTime.now())
    });

    final doc = await _db.collection('services').doc(serviceId).get();
    final service = ServiceModel.fromFirestore(doc);
    
    await _sendInternalNotification(
      receiverId: service.ownerId, 
      postId: serviceId, 
      postName: service.name, 
      type: NotificationType.comment, 
      commentText: text.trim()
    );
  }

  // --- ATIVIDADES ---
  Stream<List<Activity>> getActivities(String tripId) {
    return _db.collection('activities').where('tripId', isEqualTo: tripId).snapshots().map((snap) {
      final list = snap.docs.map((doc) => Activity.fromFirestore(doc)).toList();
      list.sort((a, b) => a.time.compareTo(b.time));
      return list;
    });
  }

  Stream<List<String>> watchTripCategories(String tripId) {
    return _db.collection('activities').where('tripId', isEqualTo: tripId).snapshots().map((snap) {
      final cats = snap.docs.map((doc) => doc.data()['category']?.toString() ?? 'Geral').toSet().toList();
      return ['Todos', ...cats];
    });
  }

  Future<void> addActivity(Activity activity) async => await _db.collection('activities').add(activity.toMap());
  Future<void> updateActivity(Activity activity) async => await _db.collection('activities').doc(activity.id).update(activity.toMap());
  Future<void> deleteActivity(String activityId) async => await _db.collection('activities').doc(activityId).delete();

  Future<void> reorderActivities(List<Activity> activities) async {
    final batch = _db.batch();
    for (int i = 0; i < activities.length; i++) {
      batch.update(_db.collection('activities').doc(activities[i].id), {'index': i});
    }
    await batch.commit();
  }

  Future<void> voteActivity(String activityId, String userId, int vote) async {
    await _db.collection('activities').doc(activityId).update({'votes.$userId': vote});
  }

  Future<void> addOpinion(String activityId, String text) async {
    final user = _auth.currentUser;
    await _db.collection('activities').doc(activityId).update({
      'opinions': FieldValue.arrayUnion([{
        'userId': user?.uid,
        'userName': user?.displayName ?? 'Viajante',
        'text': text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      }])
    });
  }

  // --- DESPESAS ---
  Stream<List<Expense>> getExpenses(String tripId) {
    return _db.collection('expenses').where('tripId', isEqualTo: tripId).snapshots().map((snap) {
      final list = snap.docs.map((doc) => Expense.fromFirestore(doc)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> addExpense(Expense expense) async => await _db.collection('expenses').add(expense.toMap());
  Future<void> deleteExpense(String expenseId) async => await _db.collection('expenses').doc(expenseId).delete();

  // --- JOURNAL / SEGURANÇA ---
  Stream<List<JournalEntry>> getJournalEntries(String tripId) => _db.collection('journal').where('tripId', isEqualTo: tripId).snapshots().map((snap) => snap.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList());
  Future<void> addJournalEntry(JournalEntry entry) async => await _db.collection('journal').add(entry.toMap());
  
  Stream<List<SafetyCheckIn>> getSafetyHistory(String tripId) => _db.collection('safety').where('tripId', isEqualTo: tripId).snapshots().map((snap) => snap.docs.map((doc) => SafetyCheckIn.fromFirestore(doc)).toList());
  
  Future<void> performSafetyCheckIn(String tripId, String location, bool isPanic) async {
    final user = _auth.currentUser;
    final checkIn = SafetyCheckIn(
      id: '', 
      tripId: tripId, 
      userId: user?.uid ?? '', 
      timestamp: DateTime.now(), 
      locationName: location, 
      isPanic: isPanic
    );
    
    await _db.collection('safety').add(checkIn.toMap());

    if (isPanic) {
      // Notificar todos os membros da viagem
      final tripDoc = await _db.collection('trips').doc(tripId).get();
      final trip = Trip.fromFirestore(tripDoc);
      
      for (final memberId in trip.members) {
        if (memberId == user?.uid) continue;
        
        await _db.collection('notifications').add(AppNotification(
          id: '',
          receiverId: memberId,
          senderId: user?.uid ?? '',
          senderName: user?.displayName ?? 'Um viajante',
          postId: tripId,
          postName: trip.destination,
          type: NotificationType.safety_alert,
          commentText: "🆘 ALERTA SOS: Estou em $location e preciso de ajuda!",
          createdAt: DateTime.now(),
        ).toMap());
      }
    }
  }
}
