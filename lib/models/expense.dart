import 'package:cloud_firestore/cloud_firestore.dart';

enum SplitType { equal, exact, percentage, shares }

class Expense {
  final String id;
  final String tripId;
  final String title;
  final double value; // Total converted to trip's base currency
  final double originalValue; // Value in spent currency
  final String currency; // Currency of the expense (USD, BRL, etc.)
  final String category;
  final String payerId; // User who paid
  final Map<String, double> splits; // userId: amount/percentage/share
  final SplitType splitType;
  final DateTime date;

  Expense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.value,
    this.originalValue = 0.0,
    this.currency = 'BRL',
    required this.category,
    required this.payerId,
    this.splits = const {},
    this.splitType = SplitType.equal,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'title': title,
      'value': value,
      'originalValue': originalValue,
      'currency': currency,
      'category': category,
      'payerId': payerId,
      'splits': splits,
      'splitType': splitType.name,
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
      originalValue: (data['originalValue'] ?? (data['value'] ?? 0)).toDouble(),
      currency: data['currency'] ?? 'BRL',
      category: data['category'] ?? 'general',
      payerId: data['payerId'] ?? '',
      splits: Map<String, double>.from(data['splits'] ?? {}),
      splitType: SplitType.values.firstWhere(
        (e) => e.name == (data['splitType'] ?? 'equal'),
        orElse: () => SplitType.equal,
      ),
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}
