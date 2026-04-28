import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { like, comment, safetyAlert }

class AppNotification {
  final String id;
  final String receiverId;
  final String senderId;
  final String senderName;
  final String postId; // Pode ser tripId no caso de segurança
  final String postName; // Pode ser o nome da viagem ou localização
  final NotificationType type;
  final String? commentText; // Pode ser a mensagem de alerta
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
  });

  Map<String, dynamic> toMap() {
    return {
      'receiverId': receiverId,
      'senderId': senderId,
      'senderName': senderName,
      'postId': postId,
      'postName': postName,
      'type': type.index,
      'commentText': commentText,
      'createdAt': createdAt,
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
}
