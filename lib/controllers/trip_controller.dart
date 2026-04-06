import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';
import '../models/activity.dart';
import '../models/expense.dart';
import '../models/service_model.dart';
import '../models/journal_entry.dart';

class TripController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- TRIPS ---
  Stream<List<Trip>> getTrips() {
    String uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('trips')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final trips = snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
          // Ordenação feita em Dart para evitar erro de índice composto no Firestore
          trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return trips;
        });
  }

  Future<void> addTrip(Trip trip) async {
    await _db.collection('trips').add(trip.toMap());
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
          // Ordena decrescente (mais recente primeiro)
          entries.sort((a, b) => b.date.compareTo(a.date));
          return entries;
        });
  }

  Future<void> addJournalEntry(JournalEntry entry) async {
    await _db.collection('journal').add(entry.toMap());
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

  Future<void> saveService(ServiceModel service) async {
    await _db.collection('services').add(service.toMap());
  }
}
