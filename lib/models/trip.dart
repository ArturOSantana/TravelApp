import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/validators/model_validators.dart';

enum TripStatus { planned, active, completed, cancelled }

extension TripStatusExtension on TripStatus {
  String get value {
    switch (this) {
      case TripStatus.planned:
        return 'planned';
      case TripStatus.active:
        return 'active';
      case TripStatus.completed:
        return 'completed';
      case TripStatus.cancelled:
        return 'cancelled';
    }
  }

  static TripStatus fromString(String value) {
    switch (value) {
      case 'active':
        return TripStatus.active;
      case 'completed':
        return TripStatus.completed;
      case 'cancelled':
        return TripStatus.cancelled;
      default:
        return TripStatus.planned;
    }
  }
}

class Trip {
  final String id;
  final String ownerId;
  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final double budget;
  final String baseCurrency;
  final String objective;
  final bool isGroup;
  final List<String> members;
  final bool isNomad;
  final DateTime createdAt;
  final TripStatus status;
  final String? photoUrl;

  Trip({
    required this.id,
    required this.ownerId,
    required this.destination,
    this.startDate,
    this.endDate,
    required this.budget,
    this.baseCurrency = 'BRL',
    required this.objective,
    this.isGroup = false,
    this.members = const [],
    this.isNomad = false,
    required this.createdAt,
    this.status = TripStatus.planned,
    this.photoUrl,
  }) {
    _validate();
  }

  void _validate() {
    // Validação mais tolerante para dados legados
    if (destination.trim().isEmpty) {
      debugPrint('⚠️ [Trip] Viagem com destino vazio detectada (ID: $id)');
    }
    if (budget < 0) {
      debugPrint('⚠️ [Trip] Viagem com orçamento negativo detectada (ID: $id)');
    }
    // Não valida dateRange para permitir viagens nômades e dados antigos
  }

  bool isAdmin(String uid) {
    if (uid.isEmpty) return false;
    return uid == ownerId;
  }

  bool isMember(String uid) {
    return uid == ownerId || members.contains(uid);
  }

  Trip copyWith({
    String? id,
    String? ownerId,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    String? baseCurrency,
    String? objective,
    bool? isGroup,
    List<String>? members,
    bool? isNomad,
    DateTime? createdAt,
    TripStatus? status,
    String? photoUrl,
  }) {
    return Trip(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      objective: objective ?? this.objective,
      isGroup: isGroup ?? this.isGroup,
      members: members ?? this.members,
      isNomad: isNomad ?? this.isNomad,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'destination': destination,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'budget': budget,
      'baseCurrency': baseCurrency,
      'objective': objective,
      'isGroup': isGroup,
      'members': members,
      'isNomad': isNomad,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.value,
      'photoUrl': photoUrl,
    };
  }

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Trip(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      destination: data['destination'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      budget: (data['budget'] ?? 0).toDouble(),
      baseCurrency: data['baseCurrency'] ?? 'BRL',
      objective: data['objective'] ?? 'Geral',
      isGroup: data['isGroup'] ?? false,
      members: List<String>.from(data['members'] ?? []),
      isNomad: data['isNomad'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: TripStatusExtension.fromString(data['status'] ?? 'planned'),
      photoUrl: data['photoUrl'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        destination,
        startDate,
        endDate,
        budget,
        baseCurrency,
        objective,
        isGroup,
        members,
        isNomad,
        createdAt,
        status,
        photoUrl,
      ];

  @override
  String toString() =>
      'Trip(id: $id, destination: $destination, status: ${status.value})';
}
