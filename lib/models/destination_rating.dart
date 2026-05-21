import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/validators/model_validators.dart';

class DestinationRating {
  final String id;
  final String tripId;
  final String activityId;
  final String userId;
  final String userName;
  final String destinationName;
  final double overallRating;
  final double? valueForMoney;
  final double? accessibility;
  final double? crowdLevel;
  final double? safety;
  final String? review;
  final List<String> tags;
  final List<String> photos;
  final DateTime visitDate;
  final DateTime createdAt;
  final bool isPublic;

  DestinationRating({
    required this.id,
    required this.tripId,
    required this.activityId,
    required this.userId,
    required this.userName,
    required this.destinationName,
    required this.overallRating,
    this.valueForMoney,
    this.accessibility,
    this.crowdLevel,
    this.safety,
    this.review,
    this.tags = const [],
    this.photos = const [],
    required this.visitDate,
    required this.createdAt,
    this.isPublic = false,
  }) {
    _validate();
  }

  void _validate() {
    ModelValidators.validateNonEmpty(tripId, 'Trip ID');
    ModelValidators.validateNonEmpty(activityId, 'Activity ID');
    ModelValidators.validateNonEmpty(userId, 'User ID');
    ModelValidators.validateNonEmpty(destinationName, 'Nome do destino');
    ModelValidators.validateRating(overallRating, 'Avaliação geral');
    if (valueForMoney != null)
      ModelValidators.validateRating(valueForMoney!, 'Custo-benefício');
    if (accessibility != null)
      ModelValidators.validateRating(accessibility!, 'Acessibilidade');
    if (crowdLevel != null)
      ModelValidators.validateRating(crowdLevel!, 'Nível de lotação');
    if (safety != null) ModelValidators.validateRating(safety!, 'Segurança');
  }

  double get averageDetailedRating {
    List<double> ratings = [overallRating];
    if (valueForMoney != null) ratings.add(valueForMoney!);
    if (accessibility != null) ratings.add(accessibility!);
    if (safety != null) ratings.add(safety!);

    if (ratings.isEmpty) return 0.0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  String get ratingDescription {
    if (overallRating >= 4.5) return 'Excelente';
    if (overallRating >= 4.0) return 'Muito Bom';
    if (overallRating >= 3.0) return 'Bom';
    if (overallRating >= 2.0) return 'Regular';
    return 'Ruim';
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'activityId': activityId,
      'userId': userId,
      'userName': userName,
      'destinationName': destinationName,
      'overallRating': overallRating,
      'valueForMoney': valueForMoney,
      'accessibility': accessibility,
      'crowdLevel': crowdLevel,
      'safety': safety,
      'review': review,
      'tags': tags,
      'photos': photos,
      'visitDate': visitDate,
      'createdAt': createdAt,
      'isPublic': isPublic,
    };
  }

  factory DestinationRating.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return DestinationRating(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      activityId: data['activityId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Viajante',
      destinationName: data['destinationName'] ?? '',
      overallRating: (data['overallRating'] ?? 0).toDouble(),
      valueForMoney: data['valueForMoney']?.toDouble(),
      accessibility: data['accessibility']?.toDouble(),
      crowdLevel: data['crowdLevel']?.toDouble(),
      safety: data['safety']?.toDouble(),
      review: data['review'],
      tags: List<String>.from(data['tags'] ?? []),
      photos: List<String>.from(data['photos'] ?? []),
      visitDate: (data['visitDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublic: data['isPublic'] ?? false,
    );
  }

  DestinationRating copyWith({
    String? id,
    String? tripId,
    String? activityId,
    String? userId,
    String? userName,
    String? destinationName,
    double? overallRating,
    double? valueForMoney,
    double? accessibility,
    double? crowdLevel,
    double? safety,
    String? review,
    List<String>? tags,
    List<String>? photos,
    DateTime? visitDate,
    DateTime? createdAt,
    bool? isPublic,
  }) {
    return DestinationRating(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      activityId: activityId ?? this.activityId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      destinationName: destinationName ?? this.destinationName,
      overallRating: overallRating ?? this.overallRating,
      valueForMoney: valueForMoney ?? this.valueForMoney,
      accessibility: accessibility ?? this.accessibility,
      crowdLevel: crowdLevel ?? this.crowdLevel,
      safety: safety ?? this.safety,
      review: review ?? this.review,
      tags: tags ?? this.tags,
      photos: photos ?? this.photos,
      visitDate: visitDate ?? this.visitDate,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DestinationRating &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tripId == other.tripId &&
          activityId == other.activityId;

  @override
  int get hashCode => id.hashCode ^ tripId.hashCode ^ activityId.hashCode;

  @override
  String toString() =>
      'DestinationRating(id: $id, destination: $destinationName, rating: $overallRating)';
}

class DestinationStats {
  final String destinationName;
  final double averageRating;
  final int totalRatings;
  final double? averageValueForMoney;
  final double? averageAccessibility;
  final double? averageCrowdLevel;
  final double? averageSafety;
  final Map<String, int> tagCounts; // Contagem de cada tag
  final List<String> topTags; // Tags mais usadas

  DestinationStats({
    required this.destinationName,
    required this.averageRating,
    required this.totalRatings,
    this.averageValueForMoney,
    this.averageAccessibility,
    this.averageCrowdLevel,
    this.averageSafety,
    this.tagCounts = const {},
    this.topTags = const [],
  });

  factory DestinationStats.fromRatings(List<DestinationRating> ratings) {
    if (ratings.isEmpty) {
      return DestinationStats(
        destinationName: '',
        averageRating: 0.0,
        totalRatings: 0,
      );
    }

    final name = ratings.first.destinationName;
    final avgRating =
        ratings.map((r) => r.overallRating).reduce((a, b) => a + b) /
            ratings.length;

    // Calcular médias dos critérios detalhados
    final valueRatings = ratings
        .where((r) => r.valueForMoney != null)
        .map((r) => r.valueForMoney!)
        .toList();
    final accessRatings = ratings
        .where((r) => r.accessibility != null)
        .map((r) => r.accessibility!)
        .toList();
    final crowdRatings = ratings
        .where((r) => r.crowdLevel != null)
        .map((r) => r.crowdLevel!)
        .toList();
    final safetyRatings =
        ratings.where((r) => r.safety != null).map((r) => r.safety!).toList();

    // Contar tags
    Map<String, int> tagCounts = {};
    for (var rating in ratings) {
      for (var tag in rating.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    // Ordenar tags por frequência
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTags = sortedTags.take(5).map((e) => e.key).toList();

    return DestinationStats(
      destinationName: name,
      averageRating: avgRating,
      totalRatings: ratings.length,
      averageValueForMoney: valueRatings.isNotEmpty
          ? valueRatings.reduce((a, b) => a + b) / valueRatings.length
          : null,
      averageAccessibility: accessRatings.isNotEmpty
          ? accessRatings.reduce((a, b) => a + b) / accessRatings.length
          : null,
      averageCrowdLevel: crowdRatings.isNotEmpty
          ? crowdRatings.reduce((a, b) => a + b) / crowdRatings.length
          : null,
      averageSafety: safetyRatings.isNotEmpty
          ? safetyRatings.reduce((a, b) => a + b) / safetyRatings.length
          : null,
      tagCounts: tagCounts,
      topTags: topTags,
    );
  }
}

class RatingTags {
  static const List<String> all = [
    'Família',
    'Romântico',
    'Aventura',
    'Relaxante',
    'Cultural',
    'Gastronômico',
    'Natureza',
    'Urbano',
    'Histórico',
    'Moderno',
    'Econômico',
    'Luxuoso',
    'Acessível',
    'Fotogênico',
    'Imperdível',
  ];

  static List<String> getRecommendedTags(String category) {
    switch (category.toLowerCase()) {
      case 'turismo':
        return ['Cultural', 'Histórico', 'Fotogênico', 'Imperdível'];
      case 'gastronomia':
        return ['Gastronômico', 'Romântico', 'Família', 'Econômico'];
      case 'aventura':
        return ['Aventura', 'Natureza', 'Família'];
      case 'relaxamento':
        return ['Relaxante', 'Romântico', 'Luxuoso'];
      default:
        return ['Família', 'Romântico', 'Fotogênico'];
    }
  }
}
