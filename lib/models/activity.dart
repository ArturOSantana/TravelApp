import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String tripId;
  final String title;
  final String? description;
  final DateTime time;
  final String location;
  final String category;
  final Map<String, int> votes; // userId: vote (1 or -1)
  final List<Map<String, dynamic>> opinions; // [{ 'userId': '', 'userName': '', 'text': '' }]
  final bool isApproved;
  final double? latitude;
  final double? longitude;

  Activity({
    required this.id,
    required this.tripId,
    required this.title,
    this.description,
    required this.time,
    required this.location,
    this.category = 'general',
    this.votes = const {},
    this.opinions = const [],
    this.isApproved = true,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'title': title,
      'description': description,
      'time': time,
      'location': location,
      'category': category,
      'votes': votes,
      'opinions': opinions,
      'isApproved': isApproved,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Activity(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      time: (data['time'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      category: data['category'] ?? 'general',
      votes: Map<String, int>.from(data['votes'] ?? {}),
      opinions: List<Map<String, dynamic>>.from(data['opinions'] ?? []),
      isApproved: data['isApproved'] ?? true,
      latitude: data['latitude'],
      longitude: data['longitude'],
    );
  }
}
