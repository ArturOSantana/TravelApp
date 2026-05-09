import 'service_model.dart';
import 'destination_rating.dart';

abstract class CommunityItem {
  String get id;
  String get ownerId;
  String? get userName;
  DateTime get createdAt;
  bool get isPublic;
  String get type; 

  String get title;
  String get subtitle;
  String get description;
  List<String> get photos;
  List<String> get likes;

  int compareTo(CommunityItem other) {
    return other.createdAt.compareTo(createdAt); // Mais recente primeiro
  }
}

class CommunityService extends CommunityItem {
  final ServiceModel service;

  CommunityService(this.service);

  @override
  String get id => service.id;

  @override
  String get ownerId => service.ownerId;

  @override
  String? get userName => service.userName;

  @override
  DateTime get createdAt => service.lastUsed;

  @override
  bool get isPublic => service.isPublic;

  @override
  String get type => 'service';

  @override
  String get title => service.name;

  @override
  String get subtitle => '${service.category} • ${service.location}';

  @override
  String get description => service.comment;

  @override
  List<String> get photos => service.photos;

  @override
  List<String> get likes => service.likes;
}

class CommunityDestinationRating extends CommunityItem {
  final DestinationRating rating;

  CommunityDestinationRating(this.rating);

  @override
  String get id => rating.id;

  @override
  String get ownerId => rating.userId;

  @override
  String? get userName => rating.userName;

  @override
  DateTime get createdAt => rating.createdAt;

  @override
  bool get isPublic => rating.isPublic;

  @override
  String get type => 'destination_rating';

  @override
  String get title => rating.destinationName;

  @override
  String get subtitle =>
      'Avaliação de Viagem • ${_formatRating(rating.overallRating)}';

  @override
  String get description => rating.review ?? 'Sem comentário';

  @override
  List<String> get photos => rating.photos;

  @override
  List<String> get likes =>
      []; 

  String _formatRating(double rating) {
    return ' ${rating.toStringAsFixed(1)}/5.0';
  }
}

