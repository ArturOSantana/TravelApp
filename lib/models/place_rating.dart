import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceRating {
  final String id;
  final String userId;
  final String userName;
  final String placeId; // id do geo(api)
  final String placeName;
  final String placeAddress;
  final double? placeLat;
  final double? placeLon;
  final String placeCategory;

  // notas
  final double overallRating;
  final double? foodQuality;
  final double? serviceQuality;
  final double? valueForMoney;
  final double? cleanliness;
  final double? atmosphere;

  final String? review;
  final List<String> photos;
  final List<String> tags;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublic;
  final String? tripId;

  // Interações sociais
  final List<String> likes;
  final int helpfulCount;

  PlaceRating({
    required this.id,
    required this.userId,
    required this.userName,
    required this.placeId,
    required this.placeName,
    required this.placeAddress,
    this.placeLat,
    this.placeLon,
    required this.placeCategory,
    required this.overallRating,
    this.foodQuality,
    this.serviceQuality,
    this.valueForMoney,
    this.cleanliness,
    this.atmosphere,
    this.review,
    this.photos = const [],
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
    this.isPublic = true,
    this.tripId,
    this.likes = const [],
    this.helpfulCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'placeId': placeId,
      'placeName': placeName,
      'placeAddress': placeAddress,
      'placeLat': placeLat,
      'placeLon': placeLon,
      'placeCategory': placeCategory,
      'overallRating': overallRating,
      'foodQuality': foodQuality,
      'serviceQuality': serviceQuality,
      'valueForMoney': valueForMoney,
      'cleanliness': cleanliness,
      'atmosphere': atmosphere,
      'review': review,
      'photos': photos,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isPublic': isPublic,
      'tripId': tripId,
      'likes': likes,
      'helpfulCount': helpfulCount,
    };
  }

  factory PlaceRating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlaceRating(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Viajante',
      placeId: data['placeId'] ?? '',
      placeName: data['placeName'] ?? '',
      placeAddress: data['placeAddress'] ?? '',
      placeLat: data['placeLat']?.toDouble(),
      placeLon: data['placeLon']?.toDouble(),
      placeCategory: data['placeCategory'] ?? '',
      overallRating: (data['overallRating'] ?? 0).toDouble(),
      foodQuality: data['foodQuality']?.toDouble(),
      serviceQuality: data['serviceQuality']?.toDouble(),
      valueForMoney: data['valueForMoney']?.toDouble(),
      cleanliness: data['cleanliness']?.toDouble(),
      atmosphere: data['atmosphere']?.toDouble(),
      review: data['review'],
      photos: List<String>.from(data['photos'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isPublic: data['isPublic'] ?? true,
      tripId: data['tripId'],
      likes: List<String>.from(data['likes'] ?? []),
      helpfulCount: data['helpfulCount'] ?? 0,
    );
  }

  PlaceRating copyWith({
    String? id,
    String? userId,
    String? userName,
    String? placeId,
    String? placeName,
    String? placeAddress,
    double? placeLat,
    double? placeLon,
    String? placeCategory,
    double? overallRating,
    double? foodQuality,
    double? serviceQuality,
    double? valueForMoney,
    double? cleanliness,
    double? atmosphere,
    String? review,
    List<String>? photos,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    String? tripId,
    List<String>? likes,
    int? helpfulCount,
  }) {
    return PlaceRating(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      placeAddress: placeAddress ?? this.placeAddress,
      placeLat: placeLat ?? this.placeLat,
      placeLon: placeLon ?? this.placeLon,
      placeCategory: placeCategory ?? this.placeCategory,
      overallRating: overallRating ?? this.overallRating,
      foodQuality: foodQuality ?? this.foodQuality,
      serviceQuality: serviceQuality ?? this.serviceQuality,
      valueForMoney: valueForMoney ?? this.valueForMoney,
      cleanliness: cleanliness ?? this.cleanliness,
      atmosphere: atmosphere ?? this.atmosphere,
      review: review ?? this.review,
      photos: photos ?? this.photos,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      tripId: tripId ?? this.tripId,
      likes: likes ?? this.likes,
      helpfulCount: helpfulCount ?? this.helpfulCount,
    );
  }

  /// Retorna cor baseada na nota
  String getRatingColor() {
    if (overallRating >= 4.5) return '#4CAF50'; // Verde
    if (overallRating >= 4.0) return '#8BC34A'; // Verde claro
    if (overallRating >= 3.0) return '#FFC107'; // Amarelo
    if (overallRating >= 2.0) return '#FF9800'; // Laranja
    return '#F44336'; // Vermelho
  }

  /// Retorna descrição textual da nota
  String getRatingDescription() {
    if (overallRating >= 4.5) return 'Excelente';
    if (overallRating >= 4.0) return 'Muito Bom';
    if (overallRating >= 3.0) return 'Bom';
    if (overallRating >= 2.0) return 'Regular';
    return 'Ruim';
  }

  /// Retorna número de estrelas cheias (0-5)
  int getFullStars() {
    return overallRating.floor();
  }

  /// Retorna se tem meia estrela
  bool hasHalfStar() {
    return (overallRating - overallRating.floor()) >= 0.5;
  }
}

class PlaceStats {
  final String placeId;
  final String placeName;
  final double averageRating;
  final int totalRatings;
  final double? averageFoodQuality;
  final double? averageServiceQuality;
  final double? averageValueForMoney;
  final double? averageCleanliness;
  final double? averageAtmosphere;
  final Map<String, int> tagCounts;
  final List<String> topTags;
  final int totalHelpful;

  PlaceStats({
    required this.placeId,
    required this.placeName,
    required this.averageRating,
    required this.totalRatings,
    this.averageFoodQuality,
    this.averageServiceQuality,
    this.averageValueForMoney,
    this.averageCleanliness,
    this.averageAtmosphere,
    this.tagCounts = const {},
    this.topTags = const [],
    this.totalHelpful = 0,
  });

  factory PlaceStats.fromRatings(List<PlaceRating> ratings) {
    if (ratings.isEmpty) {
      return PlaceStats(
        placeId: '',
        placeName: '',
        averageRating: 0.0,
        totalRatings: 0,
      );
    }

    final placeId = ratings.first.placeId;
    final placeName = ratings.first.placeName;
    final avgRating =
        ratings.map((r) => r.overallRating).reduce((a, b) => a + b) /
            ratings.length;

    final foodRatings = ratings
        .where((r) => r.foodQuality != null)
        .map((r) => r.foodQuality!)
        .toList();
    final serviceRatings = ratings
        .where((r) => r.serviceQuality != null)
        .map((r) => r.serviceQuality!)
        .toList();
    final valueRatings = ratings
        .where((r) => r.valueForMoney != null)
        .map((r) => r.valueForMoney!)
        .toList();
    final cleanRatings = ratings
        .where((r) => r.cleanliness != null)
        .map((r) => r.cleanliness!)
        .toList();
    final atmosphereRatings = ratings
        .where((r) => r.atmosphere != null)
        .map((r) => r.atmosphere!)
        .toList();

    Map<String, int> tagCounts = {};
    int totalHelpful = 0;
    for (var rating in ratings) {
      for (var tag in rating.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
      totalHelpful += rating.helpfulCount;
    }

    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTags = sortedTags.take(5).map((e) => e.key).toList();

    return PlaceStats(
      placeId: placeId,
      placeName: placeName,
      averageRating: avgRating,
      totalRatings: ratings.length,
      averageFoodQuality: foodRatings.isNotEmpty
          ? foodRatings.reduce((a, b) => a + b) / foodRatings.length
          : null,
      averageServiceQuality: serviceRatings.isNotEmpty
          ? serviceRatings.reduce((a, b) => a + b) / serviceRatings.length
          : null,
      averageValueForMoney: valueRatings.isNotEmpty
          ? valueRatings.reduce((a, b) => a + b) / valueRatings.length
          : null,
      averageCleanliness: cleanRatings.isNotEmpty
          ? cleanRatings.reduce((a, b) => a + b) / cleanRatings.length
          : null,
      averageAtmosphere: atmosphereRatings.isNotEmpty
          ? atmosphereRatings.reduce((a, b) => a + b) / atmosphereRatings.length
          : null,
      tagCounts: tagCounts,
      topTags: topTags,
      totalHelpful: totalHelpful,
    );
  }
}

class PlaceTags {
  static const List<String> restaurants = [
    'Delicioso',
    'Bom custo-benefício',
    'Ambiente agradável',
    'Atendimento rápido',
    'Porções generosas',
    'Comida caseira',
    'Gourmet',
    'Romântico',
    'Família',
    'Vegano/Vegetariano',
  ];

  static const List<String> attractions = [
    'Imperdível',
    'Fotogênico',
    'Educativo',
    'Divertido',
    'Relaxante',
    'Aventura',
    'Histórico',
    'Cultural',
    'Para crianças',
    'Acessível',
  ];

  static const List<String> entertainment = [
    'Animado',
    'Boa música',
    'Drinks especiais',
    'Vista incrível',
    'Bom para grupos',
    'Romântico',
    'Moderno',
    'Tradicional',
    'Seguro',
    'Bem localizado',
  ];

  static List<String> getTagsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
      case 'restaurante':
        return restaurants;
      case 'attraction':
      case 'atração':
        return attractions;
      case 'entertainment':
      case 'entretenimento':
        return entertainment;
      default:
        return [...restaurants, ...attractions, ...entertainment];
    }
  }
}
