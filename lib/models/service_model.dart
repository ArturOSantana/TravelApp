import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String ownerId;
  final String name;
  final String category;
  final String location;
  final double rating;
  final String comment;
  final double averageCost;
  final int usageFrequency;
  final List<String> tags;
  final List<String> photos;
  final DateTime lastUsed;
  final bool isPublic;
  final String? userName;
  final List<String> likes; // Lista de UIDs que curtiram
  final int savesCount;     // Quantas vezes foi importado/salvo

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
    this.likes = const [],
    this.savesCount = 0,
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
      'likes': likes,
      'savesCount': savesCount,
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
      likes: List<String>.from(data['likes'] ?? []),
      savesCount: data['savesCount'] ?? 0,
    );
  }
}
