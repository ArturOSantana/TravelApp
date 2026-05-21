import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/validators/model_validators.dart';

enum NotificationType { like, comment, safetyAlert }

class AppNotification {
  final String id;
  final String receiverId;
  final String senderId;
  final String senderName;
  final String postId;
  final String postName;
  final NotificationType type;
  final String? commentText;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.receiverId,
    required this.senderId,
    required this.senderName,
    required this.postId,
    required this.postName,
    required this.type,
    this.commentText,
    required this.createdAt,
    this.isRead = false,
  }) {
    _validate();
  }

  void _validate() {
    ModelValidators.validateNonEmpty(receiverId, 'Receptor');
    ModelValidators.validateNonEmpty(senderId, 'Remetente');
  }

  AppNotification copyWith({
    String? id,
    String? receiverId,
    String? senderId,
    String? senderName,
    String? postId,
    String? postName,
    NotificationType? type,
    String? commentText,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      receiverId: receiverId ?? this.receiverId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      postId: postId ?? this.postId,
      postName: postName ?? this.postName,
      type: type ?? this.type,
      commentText: commentText ?? this.commentText,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'receiverId': receiverId,
      'senderId': senderId,
      'senderName': senderName,
      'postId': postId,
      'postName': postName,
      'type': type.index,
      'commentText': commentText,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return AppNotification(
      id: doc.id,
      receiverId: data['receiverId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      postId: data['postId'] ?? '',
      postName: data['postName'] ?? '',
      type: NotificationType.values[data['type'] ?? 0],
      commentText: data['commentText'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          receiverId == other.receiverId &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ receiverId.hashCode ^ type.hashCode;

  @override
  String toString() =>
      'AppNotification(id: $id, type: ${type.name}, isRead: $isRead)';
}

// Made with Bob
