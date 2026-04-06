import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String ownerId;
  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final double budget;
  final String objective;
  final bool isGroup;
  final List<String> members;
  final bool isNomad;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.ownerId,
    required this.destination,
    this.startDate,
    this.endDate,
    required this.budget,
    required this.objective,
    this.isGroup = false,
    this.members = const [],
    this.isNomad = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'destination': destination,
      'startDate': startDate,
      'endDate': endDate,
      'budget': budget,
      'objective': objective,
      'isGroup': isGroup,
      'members': members,
      'isNomad': isNomad,
      // Removi o FieldValue daqui para evitar conflito na serialização local
      'createdAt': createdAt,
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
      objective: data['objective'] ?? 'Geral',
      isGroup: data['isGroup'] ?? false,
      members: List<String>.from(data['members'] ?? []),
      isNomad: data['isNomad'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
