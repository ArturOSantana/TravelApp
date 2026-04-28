import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityStatus { pending, completed, cancelled }

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
  final int index; // para  manual
  final ActivityStatus status; // Novo: status da atividade

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
    this.index = 0,
    this.status = ActivityStatus.pending,
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
      'index': index,
      'status': status.index,
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
      index: data['index'] ?? 0,
      status: ActivityStatus.values[data['status'] ?? 0],
    );
  }

  Activity copyWith({
    String? id,
    String? tripId,
    String? title,
    String? description,
    DateTime? time,
    String? location,
    String? category,
    Map<String, int>? votes,
    List<Map<String, dynamic>>? opinions,
    bool? isApproved,
    double? latitude,
    double? longitude,
    int? index,
    ActivityStatus? status,
  }) {
    return Activity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      location: location ?? this.location,
      category: category ?? this.category,
      votes: votes ?? this.votes,
      opinions: opinions ?? this.opinions,
      isApproved: isApproved ?? this.isApproved,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      index: index ?? this.index,
      status: status ?? this.status,
    );
  }
}
