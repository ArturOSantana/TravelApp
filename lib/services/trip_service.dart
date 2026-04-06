import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> createTrip({
    required String destination,
    required String startDate,
    required String endDate,
  }) async {
    final user = auth.currentUser;

    await firestore.collection("trips").add({
      "destination": destination,
      "start_date": startDate,
      "end_date": endDate,
      "userId": user?.uid,
      "created_at": Timestamp.now(),
    });
  }
}
