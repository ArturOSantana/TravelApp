import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String tripId;
  final String title;
  final double value;
  final String category; // food, transport, lodging, health, leisure, etc.
  final String payerId;
  final Map<String, double> splits; // userId: amount (Case 6)
  final DateTime date;

  Expense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.value,
    required this.category,
    required this.payerId,
    this.splits = const {},
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'title': title,
      'value': value,
      'category': category,
      'payerId': payerId,
      'splits': splits,
      'date': date,
    };
  }

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Expense(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      title: data['title'] ?? '',
      value: (data['value'] ?? 0).toDouble(),
      category: data['category'] ?? 'general',
      payerId: data['payerId'] ?? '',
      splits: Map<String, double>.from(data['splits'] ?? {}),
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}
