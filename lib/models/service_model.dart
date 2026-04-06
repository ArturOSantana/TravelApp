import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String ownerId;
  final String name;
  final String category; // Lodging, Restaurant, Transport, Tour, etc.
  final String location;
  final double rating;
  final String comment;
  final double averageCost;
  final int usageFrequency;
  final List<String> tags;
  final List<String> photos; // New: Photos for the recommendation
  final DateTime lastUsed;
  final bool isPublic; // New: To share with the community
  final String? userName; // Optional: To show who recommended it

  ServiceModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.location,
    required this.rating,
    required this.comment,
    required this.averageCost,
    this.usageFrequency = 1,
    this.tags = const [],
    this.photos = const [],
    required this.lastUsed,
    this.isPublic = false,
    this.userName,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'category': category,
      'location': location,
      'rating': rating,
      'comment': comment,
      'averageCost': averageCost,
      'usageFrequency': usageFrequency,
      'tags': tags,
      'photos': photos,
      'lastUsed': lastUsed,
      'isPublic': isPublic,
      'userName': userName,
    };
  }

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return ServiceModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      averageCost: (data['averageCost'] ?? 0).toDouble(),
      usageFrequency: data['usageFrequency'] ?? 1,
      tags: List<String>.from(data['tags'] ?? []),
      photos: List<String>.from(data['photos'] ?? []),
      lastUsed: (data['lastUsed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublic: data['isPublic'] ?? false,
      userName: data['userName'],
    );
  }
}
