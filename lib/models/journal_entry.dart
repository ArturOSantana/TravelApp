import 'package:cloud_firestore/cloud_firestore.dart';

enum MoodIcon {
  veryHappy('sentiment_very_satisfied', 'Muito Feliz', 5),
  happy('sentiment_satisfied', 'Feliz', 4),
  neutral('sentiment_neutral', 'Neutro', 3),
  sad('sentiment_dissatisfied', 'Triste', 2),
  verySad('sentiment_very_dissatisfied', 'Muito Triste', 1);

  final String iconName;
  final String label;
  final int value;

  const MoodIcon(this.iconName, this.label, this.value);

  static MoodIcon fromValue(int value) {
    return MoodIcon.values.firstWhere(
      (mood) => mood.value == value,
      orElse: () => MoodIcon.neutral,
    );
  }

  static MoodIcon fromString(String iconName) {
    return MoodIcon.values.firstWhere(
      (mood) => mood.iconName == iconName,
      orElse: () => MoodIcon.neutral,
    );
  }
}

enum ReactionType {
  like('favorite', 'Curtir'),
  love('favorite_border', 'Amei'),
  wow('star', 'Uau'),
  celebrate('celebration', 'Celebrar'),
  support('thumb_up', 'Apoiar'),
  thanks('volunteer_activism', 'Obrigado');

  final String iconName;
  final String label;

  const ReactionType(this.iconName, this.label);

  static ReactionType fromIcon(String iconName) {
    return ReactionType.values.firstWhere(
      (reaction) => reaction.iconName == iconName,
      orElse: () => ReactionType.like,
    );
  }
}

class JournalEntry {
  final String id;
  final String tripId;
  final String userId;
  final String userName;
  final DateTime date;
  final String content;
  final MoodIcon mood;
  final List<String> photos;
  final String? locationName;
  final DateTime createdAt;
  final Map<String, List<String>> reactions; // {emoji: [userId1, userId2, ...]}
  final bool isPublic;
  final String? shareToken;

  JournalEntry({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.userName,
    required this.date,
    required this.content,
    required this.mood,
    this.photos = const [],
    this.locationName,
    required this.createdAt,
    this.reactions = const {},
    this.isPublic = false,
    this.shareToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'userId': userId,
      'userName': userName,
      'date': date,
      'content': content,
      'mood': mood.iconName,
      'moodValue': mood.value,
      'photos': photos,
      'locationName': locationName,
      'createdAt': FieldValue.serverTimestamp(),
      'reactions': reactions,
      'isPublic': isPublic,
      'shareToken': shareToken,
    };
  }

  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;

    // Compatibilidade com versão antiga (moodScore)
    MoodIcon mood;
    if (data.containsKey('mood')) {
      mood = MoodIcon.fromString(data['mood']);
    } else if (data.containsKey('moodValue')) {
      mood = MoodIcon.fromValue(data['moodValue']);
    } else {
      // Converter moodScore antigo para novo sistema
      final double moodScore = (data['moodScore'] ?? 3).toDouble();
      mood = MoodIcon.fromValue(moodScore.round());
    }

    return JournalEntry(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Viajante',
      date: (data['date'] as Timestamp).toDate(),
      content: data['content'] ?? '',
      mood: mood,
      photos: List<String>.from(data['photos'] ?? []),
      locationName: data['locationName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: Map<String, List<String>>.from(
        (data['reactions'] as Map?)?.map(
              (key, value) =>
                  MapEntry(key.toString(), List<String>.from(value)),
            ) ??
            {},
      ),
      isPublic: data['isPublic'] ?? false,
      shareToken: data['shareToken'],
    );
  }

  JournalEntry copyWith({
    String? id,
    String? tripId,
    String? userId,
    String? userName,
    DateTime? date,
    String? content,
    MoodIcon? mood,
    List<String>? photos,
    String? locationName,
    DateTime? createdAt,
    Map<String, List<String>>? reactions,
    bool? isPublic,
    String? shareToken,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      photos: photos ?? this.photos,
      locationName: locationName ?? this.locationName,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
      isPublic: isPublic ?? this.isPublic,
      shareToken: shareToken ?? this.shareToken,
    );
  }

  int getTotalReactions() {
    return reactions.values.fold(0, (sum, users) => sum + users.length);
  }

  Map<String, int> getReactionCounts() {
    return reactions.map((emoji, users) => MapEntry(emoji, users.length));
  }

  bool hasUserReacted(String userId) {
    return reactions.values.any((users) => users.contains(userId));
  }

  String? getUserReaction(String userId) {
    for (var entry in reactions.entries) {
      if (entry.value.contains(userId)) {
        return entry.key;
      }
    }
    return null;
  }
}
