import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/validators/model_validators.dart';

enum SplitType { equal, exact, percentage, shares }

class Expense {
  final String id;
  final String tripId;
  final String title;
  final double value;
  final double originalValue;
  final String currency;
  final String category;
  final String payerId;
  final Map<String, double> splits;
  final SplitType splitType;
  final DateTime date;
  final double exchangeRateUsed;
  final DateTime? conversionDate;

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
    this.exchangeRateUsed = 1.0,
    this.conversionDate,
  }) {
    _validate();
  }

  void _validate() {
    ModelValidators.validateNonEmpty(title, 'Título');
    ModelValidators.validatePositiveNumber(value, 'Valor');
    ModelValidators.validatePositiveNumber(exchangeRateUsed, 'Taxa de câmbio');
    if (splits.isNotEmpty) {
      ModelValidators.validateSplits(splits, splitType.name);
    }
  }

  Expense copyWith({
    String? id,
    String? tripId,
    String? title,
    double? value,
    double? originalValue,
    String? currency,
    String? category,
    String? payerId,
    Map<String, double>? splits,
    SplitType? splitType,
    DateTime? date,
    double? exchangeRateUsed,
    DateTime? conversionDate,
  }) {
    return Expense(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      value: value ?? this.value,
      originalValue: originalValue ?? this.originalValue,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      payerId: payerId ?? this.payerId,
      splits: splits ?? this.splits,
      splitType: splitType ?? this.splitType,
      date: date ?? this.date,
      exchangeRateUsed: exchangeRateUsed ?? this.exchangeRateUsed,
      conversionDate: conversionDate ?? this.conversionDate,
    );
  }

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
      'date': Timestamp.fromDate(date),
      'exchangeRateUsed': exchangeRateUsed,
      'conversionDate':
          conversionDate != null ? Timestamp.fromDate(conversionDate!) : null,
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
      exchangeRateUsed: (data['exchangeRateUsed'] ?? 1.0).toDouble(),
      conversionDate: data['conversionDate'] != null
          ? (data['conversionDate'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tripId == other.tripId &&
          title == other.title &&
          value == other.value;

  @override
  int get hashCode =>
      id.hashCode ^ tripId.hashCode ^ title.hashCode ^ value.hashCode;

  @override
  String toString() =>
      'Expense(id: $id, title: $title, value: $value $currency)';
}
