import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

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
      'subscriptionStartDate': subscriptionStartDate,
      'subscriptionEndDate': subscriptionEndDate,
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
}

// Made with Bob
