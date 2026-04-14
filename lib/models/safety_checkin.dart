import 'package:cloud_firestore/cloud_firestore.dart';

class SafetyCheckIn {
  final String id;
  final String tripId;
  final String userId;
  final DateTime timestamp;
  final String locationName;
  final bool isPanic; 

  SafetyCheckIn({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.timestamp,
    required this.locationName,
    this.isPanic = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'userId': userId,
      'timestamp': timestamp,
      'locationName': locationName,
      'isPanic': isPanic,
    };
  }

  factory SafetyCheckIn.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return SafetyCheckIn(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      locationName: data['locationName'] ?? 'Localização não informada',
      isPanic: data['isPanic'] ?? false,
    );
  }
}
