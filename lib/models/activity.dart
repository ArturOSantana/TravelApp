import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/validators/model_validators.dart';

enum ActivityStatus { pending, completed, cancelled }

class Activity {
  final String id;
  final String tripId;
  final String title;
  final String? description;
  final DateTime time;
  final String location;
  final String category;
  final Map<String, int> votes;
  final List<Map<String, dynamic>> opinions;
  final bool isApproved;
  final double? latitude;
  final double? longitude;
  final int index;
  final ActivityStatus status;

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
  }) {
    _validate();
  }

  void _validate() {
    ModelValidators.validateNonEmpty(title, 'Título');
    ModelValidators.validateNonEmpty(location, 'Localização');
    ModelValidators.validateCoordinates(latitude, longitude);
  }

  bool get isCompleted => status == ActivityStatus.completed;
  bool get isPending => status == ActivityStatus.pending;
  bool get isCancelled => status == ActivityStatus.cancelled;

  int get voteScore => votes.values.fold(0, (sum, vote) => sum + vote);

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'title': title,
      'description': description,
      'time': Timestamp.fromDate(time),
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
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Activity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tripId == other.tripId &&
          title == other.title &&
          time == other.time;

  @override
  int get hashCode =>
      id.hashCode ^ tripId.hashCode ^ title.hashCode ^ time.hashCode;

  @override
  String toString() =>
      'Activity(id: $id, title: $title, status: ${status.name})';
}
