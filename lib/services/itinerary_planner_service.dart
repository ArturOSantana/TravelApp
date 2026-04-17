import '../models/activity.dart';
import '../models/itinerary_preferences.dart';
import '../models/trip.dart';

class ItineraryPlannerResult {
  final Map<String, SmartActivitySuggestion> suggestionsByActivityId;
  final List<ItineraryDayPlan> dayPlans;
  final String? weatherHint;

  const ItineraryPlannerResult({
    required this.suggestionsByActivityId,
    required this.dayPlans,
    this.weatherHint,
  });
}

class ItineraryPlannerService {
  ItineraryPlannerResult buildSmartItinerary({
    required Trip trip,
    required List<Activity> activities,
    required ItineraryPreferences preferences,
    String? weatherDescription,
  }) {
    final sorted = List<Activity>.from(activities);
    final suggestions = <String, SmartActivitySuggestion>{};

    sorted.sort((a, b) {
      final scoreA = _scoreActivity(
        activity: a,
        trip: trip,
        preferences: preferences,
        weatherDescription: weatherDescription,
      );
      final scoreB = _scoreActivity(
        activity: b,
        trip: trip,
        preferences: preferences,
        weatherDescription: weatherDescription,
      );

      suggestions[a.id] = scoreA;
      suggestions[b.id] = scoreB;

      final compareScore = scoreB.score.compareTo(scoreA.score);
      if (compareScore != 0) return compareScore;
      return a.time.compareTo(b.time);
    });

    final dayPlans = _buildDayPlans(sorted);

    return ItineraryPlannerResult(
      suggestionsByActivityId: suggestions,
      dayPlans: dayPlans,
      weatherHint: _buildWeatherHint(weatherDescription),
    );
  }

  SmartActivitySuggestion _scoreActivity({
    required Activity activity,
    required Trip trip,
    required ItineraryPreferences preferences,
    String? weatherDescription,
  }) {
    var score = 0.0;
    final reasons = <String>[];

    final objective = trip.objective.toLowerCase().trim();
    final category = activity.category.toLowerCase().trim();
    final tags = activity.tags.map((tag) => tag.toLowerCase().trim()).toList();
    final budget = trip.budget;
    final weather = (weatherDescription ?? '').toLowerCase();

    if (preferences.preferredCategories.any(
      (item) => item.toLowerCase().trim() == category,
    )) {
      score += 3;
      reasons.add('Combina com as preferências escolhidas');
    }

    if (objective.isNotEmpty &&
        objective != 'geral' &&
        (category.contains(objective) ||
            tags.any((tag) => tag.contains(objective)) ||
            activity.title.toLowerCase().contains(objective))) {
      score += 3;
      reasons.add('Alinhada com o objetivo da viagem');
    }

    final upVotes = activity.votes.values.where((vote) => vote == 1).length;
    final downVotes = activity.votes.values.where((vote) => vote == -1).length;
    final voteBalance = upVotes - downVotes;

    if (preferences.prioritizeGroupConsensus && voteBalance > 0) {
      score += voteBalance * 1.5;
      reasons.add('Bem avaliada pelo grupo');
    } else if (voteBalance < 0) {
      score += voteBalance.toDouble();
      reasons.add('Tem baixa aceitação no grupo');
    }

    if (activity.priority > 0) {
      score += activity.priority * 2;
      reasons.add('Marcada como prioridade');
    }

    if (budget > 0) {
      final tripDays = _tripDays(trip);
      final dailyBudget = tripDays == 0 ? budget : budget / tripDays;

      if (activity.estimatedCost <= dailyBudget * 0.5) {
        score += 2;
        reasons.add('Cabe bem no orçamento');
      } else if (activity.estimatedCost > dailyBudget && dailyBudget > 0) {
        score -= 2;
        reasons.add('Pode pesar no orçamento');
      }
    }

    if (preferences.avoidNightActivities &&
        _resolvePeriod(activity) == 'noite') {
      score -= 2;
      reasons.add('Menos indicada para o perfil selecionado');
    }

    if (preferences.preferOutdoor && activity.isOutdoor) {
      score += 2;
      reasons.add('Combina com preferência por atividades ao ar livre');
    }

    if (weather.contains('chuva') || weather.contains('chuv')) {
      if (activity.isOutdoor) {
        score -= 2;
        reasons.add('Pode ser afetada por chuva');
      } else {
        score += 1.5;
        reasons.add('Boa opção para clima instável');
      }
    }

    if (activity.durationMinutes <= _durationLimit(preferences.pace)) {
      score += 1;
      reasons.add('Duração compatível com o ritmo da viagem');
    }

    if (reasons.isEmpty) {
      reasons.add('Atividade válida para compor o roteiro');
    }

    return SmartActivitySuggestion(
      activityId: activity.id,
      score: score,
      reasons: reasons.take(3).toList(),
    );
  }

  List<ItineraryDayPlan> _buildDayPlans(List<Activity> activities) {
    final grouped = <DateTime, Map<String, List<String>>>{};

    for (final activity in activities) {
      final day = DateTime(
        activity.time.year,
        activity.time.month,
        activity.time.day,
      );
      final period = _resolvePeriod(activity);

      grouped.putIfAbsent(day, () => {'manha': [], 'tarde': [], 'noite': []});

      grouped[day]![period]!.add(activity.id);
    }

    final days = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    return days.map((day) {
      final blocks = grouped[day]!;
      return ItineraryDayPlan(
        date: day,
        blocks: [
          ItineraryTimeBlock(
            label: 'Manhã',
            activityIds: blocks['manha'] ?? [],
          ),
          ItineraryTimeBlock(
            label: 'Tarde',
            activityIds: blocks['tarde'] ?? [],
          ),
          ItineraryTimeBlock(
            label: 'Noite',
            activityIds: blocks['noite'] ?? [],
          ),
        ],
      );
    }).toList();
  }

  String _resolvePeriod(Activity activity) {
    if (activity.period != 'flexivel') {
      switch (activity.period) {
        case 'morning':
          return 'manha';
        case 'afternoon':
          return 'tarde';
        case 'night':
          return 'noite';
      }
    }

    final hour = activity.time.hour;
    if (hour < 12) return 'manha';
    if (hour < 18) return 'tarde';
    return 'noite';
  }

  int _tripDays(Trip trip) {
    if (trip.startDate == null || trip.endDate == null) return 1;
    final difference = trip.endDate!.difference(trip.startDate!).inDays + 1;
    return difference <= 0 ? 1 : difference;
  }

  int _durationLimit(String pace) {
    switch (pace) {
      case 'leve':
        return 90;
      case 'intenso':
        return 240;
      default:
        return 150;
    }
  }

  String? _buildWeatherHint(String? weatherDescription) {
    if (weatherDescription == null || weatherDescription.trim().isEmpty) {
      return null;
    }

    final text = weatherDescription.toLowerCase();
    if (text.contains('chuva') || text.contains('chuv')) {
      return 'Clima chuvoso: priorize atividades indoor ou flexíveis.';
    }
    if (text.contains('sol') || text.contains('ensolar')) {
      return 'Clima favorável: atividades ao ar livre ganham destaque.';
    }
    return 'O clima foi considerado na organização do roteiro.';
  }
}


