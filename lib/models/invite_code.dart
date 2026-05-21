import 'package:cloud_firestore/cloud_firestore.dart';

class InviteCode {
  final String id;
  final String tripId;
  final String code; // Código curto de 6 caracteres
  final String createdBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int maxUses;
  final int usedCount;
  final bool isActive;

  InviteCode({
    required this.id,
    required this.tripId,
    required this.code,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.maxUses = 10,
    this.usedCount = 0,
    this.isActive = true,
  });

  factory InviteCode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InviteCode(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      code: data['code'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxUses: data['maxUses'] ?? 10,
      usedCount: data['usedCount'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'code': code,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'maxUses': maxUses,
      'usedCount': usedCount,
      'isActive': isActive,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isMaxUsesReached => usedCount >= maxUses;
  bool get isValid => isActive && !isExpired && !isMaxUsesReached;
}

// Made with Bob
