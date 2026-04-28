import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoAlbum {
  final String id;
  final String tripId;
  final String folderName;
  final List<PhotoItem> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  PhotoAlbum({
    required this.id,
    required this.tripId,
    required this.folderName,
    required this.photos,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PhotoAlbum.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhotoAlbum(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      folderName: data['folderName'] ?? 'Sem Nome',
      photos:
          (data['photos'] as List<dynamic>?)
              ?.map((p) => PhotoItem.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'folderName': folderName,
      'photos': photos.map((p) => p.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PhotoAlbum copyWith({
    String? id,
    String? tripId,
    String? folderName,
    List<PhotoItem>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PhotoAlbum(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      folderName: folderName ?? this.folderName,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PhotoItem {
  final String id;
  final String url;
  final String thumbnailUrl;
  final String? caption;
  final String? location;
  final DateTime takenAt;
  final bool isPublic;

  PhotoItem({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    this.caption,
    this.location,
    required this.takenAt,
    this.isPublic = false,
  });

  factory PhotoItem.fromMap(Map<String, dynamic> map) {
    return PhotoItem(
      id: map['id'] ?? '',
      url: map['url'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? map['url'] ?? '',
      caption: map['caption'],
      location: map['location'],
      takenAt: (map['takenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublic: map['isPublic'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'location': location,
      'takenAt': Timestamp.fromDate(takenAt),
      'isPublic': isPublic,
    };
  }

  PhotoItem copyWith({
    String? id,
    String? url,
    String? thumbnailUrl,
    String? caption,
    String? location,
    DateTime? takenAt,
    bool? isPublic,
  }) {
    return PhotoItem(
      id: id ?? this.id,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      location: location ?? this.location,
      takenAt: takenAt ?? this.takenAt,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

// Pastas pré-definidas
class PhotoFolders {
  static const String highlights = 'Destaques';
  static const String landscapes = 'Paisagens';
  static const String food = 'Gastronomia';
  static const String people = 'Pessoas';
  static const String activities = 'Atividades';
  static const String accommodation = 'Hospedagem';
  static const String transport = 'Transporte';
  static const String other = 'Outras';

  static List<String> get all => [
    highlights,
    landscapes,
    food,
    people,
    activities,
    accommodation,
    transport,
    other,
  ];

  static String getIcon(String folder) {
    switch (folder) {
      case highlights:
        return '⭐';
      case landscapes:
        return '🏞️';
      case food:
        return '🍽️';
      case people:
        return '👥';
      case activities:
        return '🎯';
      case accommodation:
        return '🏨';
      case transport:
        return '🚗';
      case other:
        return '📸';
      default:
        return '📁';
    }
  }
}

