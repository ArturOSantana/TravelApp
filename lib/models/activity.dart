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
  final List<Map<String, dynamic>>
  opinions; // [{ 'userId': '', 'userName': '', 'text': '' }]
  final bool isApproved;
  final double? latitude;
  final double? longitude;
  final double estimatedCost;
  final int durationMinutes;
  final String period;
  final bool isOutdoor;
  final int priority;
  final List<String> tags;
  final String source;
  final double score;

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
    this.estimatedCost = 0,
    this.durationMinutes = 90,
    this.period = 'flexivel',
    this.isOutdoor = false,
    this.priority = 0,
    this.tags = const [],
    this.source = 'manual',
    this.score = 0,
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
      'estimatedCost': estimatedCost,
      'durationMinutes': durationMinutes,
      'period': period,
      'isOutdoor': isOutdoor,
      'priority': priority,
      'tags': tags,
      'source': source,
      'score': score,
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
      estimatedCost: (data['estimatedCost'] ?? 0).toDouble(),
      durationMinutes: (data['durationMinutes'] ?? 90) as int,
      period: (data['period'] ?? 'flexivel').toString(),
      isOutdoor: data['isOutdoor'] ?? false,
      priority: (data['priority'] ?? 0) as int,
      tags: List<String>.from(data['tags'] ?? []),
      source: (data['source'] ?? 'manual').toString(),
      score: (data['score'] ?? 0).toDouble(),
    );
  }
}
