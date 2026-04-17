class ItineraryPreferences {
  final String pace;
  final String budgetStyle;
  final List<String> preferredCategories;
  final bool preferOutdoor;
  final bool avoidNightActivities;
  final bool prioritizeGroupConsensus;

  const ItineraryPreferences({
    this.pace = 'moderado',
    this.budgetStyle = 'equilibrado',
    this.preferredCategories = const [],
    this.preferOutdoor = false,
    this.avoidNightActivities = false,
    this.prioritizeGroupConsensus = true,
  });

  ItineraryPreferences copyWith({
    String? pace,
    String? budgetStyle,
    List<String>? preferredCategories,
    bool? preferOutdoor,
    bool? avoidNightActivities,
    bool? prioritizeGroupConsensus,
  }) {
    return ItineraryPreferences(
      pace: pace ?? this.pace,
      budgetStyle: budgetStyle ?? this.budgetStyle,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      preferOutdoor: preferOutdoor ?? this.preferOutdoor,
      avoidNightActivities: avoidNightActivities ?? this.avoidNightActivities,
      prioritizeGroupConsensus:
          prioritizeGroupConsensus ?? this.prioritizeGroupConsensus,
    );
  }
}

class SmartActivitySuggestion {
  final String activityId;
  final double score;
  final List<String> reasons;

  const SmartActivitySuggestion({
    required this.activityId,
    required this.score,
    required this.reasons,
  });
}

class ItineraryTimeBlock {
  final String label;
  final List<String> activityIds;

  const ItineraryTimeBlock({required this.label, required this.activityIds});
}

class ItineraryDayPlan {
  final DateTime date;
  final List<ItineraryTimeBlock> blocks;

  const ItineraryDayPlan({required this.date, required this.blocks});
}
