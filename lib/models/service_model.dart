import 'package:cloud_firestore/cloud_firestore.dart';

class PostComment {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;
  final bool isHidden;
  final String? hiddenBy;

  const PostComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
    this.isHidden = false,
    this.hiddenBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'isHidden': isHidden,
      'hiddenBy': hiddenBy,
    };
  }

  factory PostComment.fromMap(Map<String, dynamic> data) {
    return PostComment(
      id: (data['id'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? 'Viajante').toString(),
      text: (data['text'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isHidden: data['isHidden'] ?? false,
      hiddenBy: data['hiddenBy']?.toString(),
    );
  }

  PostComment copyWith({
    String? id,
    String? userId,
    String? userName,
    String? text,
    DateTime? createdAt,
    bool? isHidden,
    String? hiddenBy,
  }) {
    return PostComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isHidden: isHidden ?? this.isHidden,
      hiddenBy: hiddenBy ?? this.hiddenBy,
    );
  }
}

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
  final List<String> likes;
  final List<String> savedBy; // Nova lista para IDs de usuários que salvaram o post
  final int savesCount;
  final List<PostComment> comments;
  final bool commentsEnabled;
  final DateTime? updatedAt;

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
    this.savedBy = const [],
    this.savesCount = 0,
    this.comments = const [],
    this.commentsEnabled = true,
    this.updatedAt,
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
      'savedBy': savedBy,
      'savesCount': savesCount,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'commentsEnabled': commentsEnabled,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
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
      savedBy: List<String>.from(data['savedBy'] ?? []),
      savesCount: data['savesCount'] ?? 0,
      comments: ((data['comments'] ?? []) as List)
          .map((item) => PostComment.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      commentsEnabled: data['commentsEnabled'] ?? true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  ServiceModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? category,
    String? location,
    double? rating,
    String? comment,
    double? averageCost,
    int? usageFrequency,
    List<String>? tags,
    List<String>? photos,
    DateTime? lastUsed,
    bool? isPublic,
    String? userName,
    List<String>? likes,
    List<String>? savedBy,
    int? savesCount,
    List<PostComment>? comments,
    bool? commentsEnabled,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      averageCost: averageCost ?? this.averageCost,
      usageFrequency: usageFrequency ?? this.usageFrequency,
      tags: tags ?? this.tags,
      photos: photos ?? this.photos,
      lastUsed: lastUsed ?? this.lastUsed,
      isPublic: isPublic ?? this.isPublic,
      userName: userName ?? this.userName,
      likes: likes ?? this.likes,
      savedBy: savedBy ?? this.savedBy,
      savesCount: savesCount ?? this.savesCount,
      comments: comments ?? this.comments,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
