import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final String tripId;
  final String userId;
  final String userName;
  final DateTime date;
  final String content;
  final double moodScore;
  final List<String> photos;
  final String? locationName;
  final DateTime createdAt;

  JournalEntry({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.userName,
    required this.date,
    required this.content,
    required this.moodScore,
    this.photos = const [],
    this.locationName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'userId': userId,
      'userName': userName,
      'date': date,
      'content': content,
      'moodScore': moodScore,
      'photos': photos,
      'locationName': locationName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return JournalEntry(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Viajante',
      date: (data['date'] as Timestamp).toDate(),
      content: data['content'] ?? '',
      moodScore: (data['moodScore'] ?? 0).toDouble(),
      photos: List<String>.from(data['photos'] ?? []),
      locationName: data['locationName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
