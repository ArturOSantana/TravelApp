import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/validators/model_validators.dart';

enum SubscriptionTier {
  free,
  premium,
  business,
}

class UserSubscription {
  final String userId;
  final SubscriptionTier tier;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final bool isActive;
  final String? paymentMethod;
  final double? monthlyPrice;

  UserSubscription({
    required this.userId,
    this.tier = SubscriptionTier.free,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.isActive = false,
    this.paymentMethod,
    this.monthlyPrice,
  }) {
    _validate();
  }

  void _validate() {
    ModelValidators.validateNonEmpty(userId, 'User ID');
    if (monthlyPrice != null) {
      ModelValidators.validatePositiveNumber(monthlyPrice!, 'Preço mensal');
    }
    if (subscriptionStartDate != null && subscriptionEndDate != null) {
      ModelValidators.validateDateRange(
          subscriptionStartDate, subscriptionEndDate);
    }
  }

  bool get isPremium => tier == SubscriptionTier.premium && isActive;
  bool get isBusiness => tier == SubscriptionTier.business && isActive;
  bool get isFree => tier == SubscriptionTier.free || !isActive;

  // Limites por plano
  int get maxTrips {
    switch (tier) {
      case SubscriptionTier.free:
        return 3;
      case SubscriptionTier.premium:
        return 999; // Ilimitado
      case SubscriptionTier.business:
        return 999; // Ilimitado
    }
  }

  int get maxMembersPerTrip {
    switch (tier) {
      case SubscriptionTier.free:
        return 5;
      case SubscriptionTier.premium:
        return 20;
      case SubscriptionTier.business:
        return 999; // Ilimitado
    }
  }

  bool get hasAdvancedInsights {
    return tier != SubscriptionTier.free;
  }

  bool get hasAIFeatures {
    return tier != SubscriptionTier.free;
  }

  bool get hasExportReports {
    return tier != SubscriptionTier.free;
  }

  bool get hasCloudBackup {
    return tier != SubscriptionTier.free;
  }

  bool get hasNoAds {
    return tier != SubscriptionTier.free;
  }

  bool get hasPrioritySupport {
    return tier == SubscriptionTier.business;
  }

  bool get hasBusinessFeatures {
    return tier == SubscriptionTier.business;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tier': tier.name,
      'subscriptionStartDate': subscriptionStartDate != null
          ? Timestamp.fromDate(subscriptionStartDate!)
          : null,
      'subscriptionEndDate': subscriptionEndDate != null
          ? Timestamp.fromDate(subscriptionEndDate!)
          : null,
      'isActive': isActive,
      'paymentMethod': paymentMethod,
      'monthlyPrice': monthlyPrice,
    };
  }

  factory UserSubscription.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return UserSubscription(
      userId: doc.id,
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.name == (data['tier'] ?? 'free'),
        orElse: () => SubscriptionTier.free,
      ),
      subscriptionStartDate:
          (data['subscriptionStartDate'] as Timestamp?)?.toDate(),
      subscriptionEndDate:
          (data['subscriptionEndDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? false,
      paymentMethod: data['paymentMethod'],
      monthlyPrice: data['monthlyPrice']?.toDouble(),
    );
  }

  UserSubscription copyWith({
    String? userId,
    SubscriptionTier? tier,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    bool? isActive,
    String? paymentMethod,
    double? monthlyPrice,
  }) {
    return UserSubscription(
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      subscriptionStartDate:
          subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      isActive: isActive ?? this.isActive,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSubscription &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          tier == other.tier &&
          isActive == other.isActive;

  @override
  int get hashCode => userId.hashCode ^ tier.hashCode ^ isActive.hashCode;

  @override
  String toString() =>
      'UserSubscription(userId: $userId, tier: ${tier.name}, isActive: $isActive)';
}
