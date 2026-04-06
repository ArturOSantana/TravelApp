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

  // --- TRIPS ---
  Stream<List<Trip>> getTrips({String? status}) {
    String uid = _auth.currentUser?.uid ?? '';
    var query = _db.collection('trips').where('members', arrayContains: uid);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      final trips = snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
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
    await _db.collection('trips').doc(tripId).update({'status': newStatus});
  }

  Future<void> joinTrip(String tripId) async {
    String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) throw Exception("Usuário não autenticado");

    await _db.collection('trips').doc(tripId).update({
      'members': FieldValue.arrayUnion([uid]),
      'isGroup': true, 
    });
  }

  // Novo: Remover membro (Apenas ADM)
  Future<void> removeMember(String tripId, String memberId) async {
    await _db.collection('trips').doc(tripId).update({
      'members': FieldValue.arrayRemove([memberId])
    });
  }

  // --- USERS ---
  Future<List<UserModel>> getTripMembers(List<String> memberIds) async {
    List<UserModel> users = [];
    for (String id in memberIds) {
      var doc = await _db.collection('users').doc(id).get();
      if (doc.exists) {
        users.add(UserModel.fromMap(doc.data()!));
      }
    }
    return users;
  }

  // --- SERVICES ---
  Stream<List<ServiceModel>> getPersonalServices() {
    String uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('services')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList());
  }

  Stream<List<ServiceModel>> getCommunityServices() {
    return _db
        .collection('services')
        .where('isPublic', isEqualTo: true)
        .limit(20)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList());
  }

  Future<void> saveService(ServiceModel service) async {
    await _db.collection('services').add(service.toMap());
  }

  // Novo: Importar serviço para favoritos
  Future<void> importService(ServiceModel service) async {
    String uid = _auth.currentUser?.uid ?? '';
    String userName = _auth.currentUser?.displayName ?? 'Viajante';

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
      isPublic: false, // Salva como privado na biblioteca pessoal
      photos: service.photos,
      tags: service.tags,
    );
    
    await saveService(imported);
  }

  // --- ACTIVITIES ---
  Stream<List<Activity>> getActivities(String tripId) {
    return _db
        .collection('activities')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) {
          final activities = snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList();
          activities.sort((a, b) => a.time.compareTo(b.time));
          return activities;
        });
  }

  Future<void> addActivity(Activity activity) async {
    await _db.collection('activities').add(activity.toMap());
  }

  Future<void> voteActivity(String activityId, String userId, int vote) async {
    await _db.collection('activities').doc(activityId).update({
      'votes.$userId': vote,
    });
  }

  // --- EXPENSES ---
  Stream<List<Expense>> getExpenses(String tripId) {
    return _db
        .collection('expenses')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) {
          final expenses = snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
          expenses.sort((a, b) => b.date.compareTo(a.date));
          return expenses;
        });
  }

  Stream<List<Expense>> getAllUserExpenses() {
    String uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('expenses')
        .where('payerId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList());
  }

  Future<void> addExpense(Expense expense) async {
    await _db.collection('expenses').add(expense.toMap());
  }

  // --- JOURNAL ---
  Stream<List<JournalEntry>> getJournalEntries(String tripId) {
    return _db
        .collection('journal')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) {
          final entries = snapshot.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList();
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
          final list = snapshot.docs.map((doc) => SafetyCheckIn.fromFirestore(doc)).toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  Future<void> performSafetyCheckIn(String tripId, String location, bool isPanic) async {
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
