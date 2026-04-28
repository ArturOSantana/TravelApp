import 'package:cloud_firestore/cloud_firestore.dart';

class SafetyCheckIn {
  final String id;
  final String tripId;
  final String userId;
  final DateTime timestamp;
  final String locationName;
  final bool isPanic;
  final double? latitude;
  final double? longitude;
  final String? userName;
  final bool isAcknowledged;
  final List<String> acknowledgedBy;

  SafetyCheckIn({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.timestamp,
    required this.locationName,
    this.isPanic = false,
    this.latitude,
    this.longitude,
    this.userName,
    this.isAcknowledged = false,
    this.acknowledgedBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'userId': userId,
      'timestamp': timestamp,
      'locationName': locationName,
      'isPanic': isPanic,
      'latitude': latitude,
      'longitude': longitude,
      'userName': userName,
      'isAcknowledged': isAcknowledged,
      'acknowledgedBy': acknowledgedBy,
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
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      userName: data['userName'],
      isAcknowledged: data['isAcknowledged'] ?? false,
      acknowledgedBy: List<String>.from(data['acknowledgedBy'] ?? []),
    );
  }

  SafetyCheckIn copyWith({
    String? id,
    String? tripId,
    String? userId,
    DateTime? timestamp,
    String? locationName,
    bool? isPanic,
    double? latitude,
    double? longitude,
    String? userName,
    bool? isAcknowledged,
    List<String>? acknowledgedBy,
  }) {
    return SafetyCheckIn(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      locationName: locationName ?? this.locationName,
      isPanic: isPanic ?? this.isPanic,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      userName: userName ?? this.userName,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
    );
  }
}
