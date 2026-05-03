import 'dart:math';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/trip.dart';

class AnalyticsService {

  static double calculateEfficiencyIndex({
    required double totalSpent,
    required double totalBudget,
    required int daysElapsed,
    required int totalDays,
  }) {
    if (totalDays == 0 || totalBudget == 0) return 0;
    double timeElapsed = daysElapsed / totalDays;
    double budgetUsed = totalSpent / totalBudget;
    return budgetUsed / timeElapsed;
  }

  static double calculateBurnRate({
    required double totalSpent,
    required int daysElapsed,
  }) {
    return daysElapsed > 0 ? totalSpent / daysElapsed : 0;
  }

  /// Projeta gastos futur
  static double projectFutureSpending({
    required double burnRate,
    required int daysRemaining,
  }) {
    return burnRate * daysRemaining;
  }

  static int daysUntilBudgetEnds({
    required double budgetRemaining,
    required double burnRate,
  }) {
    if (burnRate == 0) return 999999;
    return (budgetRemaining / burnRate).ceil();
  }

  static double calculateMedian(List<double> values) {
    if (values.isEmpty) return 0;
    List<double> sorted = List.from(values)..sort();
    int middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    }
    return sorted[middle];
  }

  static double calculateMean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calcula padrão
  static double calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0;
    double mean = calculateMean(values);
    double variance = values.fold(
          0.0,
          (sum, value) => sum + pow(value - mean, 2),
        ) /
        values.length;
    return sqrt(variance);
  }

  static List<Expense> findOutliers(List<Expense> expenses) {
    if (expenses.length < 3) return [];

    List<double> values = expenses.map((e) => e.value).toList();
    double mean = calculateMean(values);
    double stdDev = calculateStdDev(values);

    return expenses.where((e) => (e.value - mean).abs() > 2 * stdDev).toList();
  }

  /// Calcula quartis (Q1, Q2/Mediana, Q3)
  static Map<String, double> calculateQuartiles(List<double> values) {
    if (values.isEmpty) {
      return {'Q1': 0, 'Q2': 0, 'Q3': 0};
    }

    List<double> sorted = List.from(values)..sort();
    int n = sorted.length;

    double q2 = calculateMedian(sorted);
    double q1 = calculateMedian(sorted.sublist(0, n ~/ 2));
    double q3 = calculateMedian(sorted.sublist((n + 1) ~/ 2));

    return {'Q1': q1, 'Q2': q2, 'Q3': q3};
  }

  static Map<String, double> groupByCategory(List<Expense> expenses) {
    Map<String, double> categories = {};
    for (var expense in expenses) {
      categories[expense.category] =
          (categories[expense.category] ?? 0) + expense.value;
    }
    return categories;
  }

  static Map<String, double> groupByWeekday(List<Expense> expenses) {
    Map<String, double> weekdays = {
      'Segunda': 0,
      'Terça': 0,
      'Quarta': 0,
      'Quinta': 0,
      'Sexta': 0,
      'Sábado': 0,
      'Domingo': 0,
    };

    List<String> weekdayNames = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo'
    ];

    for (var expense in expenses) {
      int weekday = expense.date.weekday - 1; // 0 = Monday
      String weekdayName = weekdayNames[weekday];
      weekdays[weekdayName] = (weekdays[weekdayName] ?? 0) + expense.value;
    }

    return weekdays;
  }

  static Map<DateTime, double> groupByDay(List<Expense> expenses) {
    Map<DateTime, double> dailySpending = {};

    for (var expense in expenses) {
      DateTime day = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      dailySpending[day] = (dailySpending[day] ?? 0) + expense.value;
    }

    return dailySpending;
  }

  static List<double> calculateMovingAverage(
    List<double> values,
    int windowSize,
  ) {
    if (values.length < windowSize) return values;

    List<double> movingAvg = [];
    for (int i = 0; i <= values.length - windowSize; i++) {
      double sum = 0;
      for (int j = 0; j < windowSize; j++) {
        sum += values[i + j];
      }
      movingAvg.add(sum / windowSize);
    }
    return movingAvg;
  }

  static double calculateParetoRatio(Map<DateTime, double> dailySpending) {
    if (dailySpending.isEmpty) return 0;

    List<double> sortedSpending = dailySpending.values.toList()
      ..sort((a, b) => b.compareTo(a));

    double totalSpending = sortedSpending.reduce((a, b) => a + b);
    int top20Count = (sortedSpending.length * 0.2).ceil();

    double top20Spending =
        sortedSpending.take(top20Count).fold(0.0, (sum, value) => sum + value);

    return top20Spending / totalSpending;
  }

  static double calculateCostPerPersonPerDay({
    required double totalSpent,
    required int numberOfPeople,
    required int daysElapsed,
  }) {
    if (numberOfPeople == 0 || daysElapsed == 0) return 0;
    return totalSpent / (numberOfPeople * daysElapsed);
  }

  static double calculateCostBenefit({
    required double rating,
    required double totalSpent,
  }) {
    if (totalSpent == 0) return 0;
    return rating / (totalSpent / 1000);
  }

  static List<String> generateRecommendations({
    required double efficiencyIndex,
    required double burnRate,
    required double budgetRemaining,
    required int daysRemaining,
    required Map<String, double> categorySpending,
    required Map<String, double> plannedBudget,
  }) {
    List<String> recommendations = [];

//betinha
    if (efficiencyIndex > 1.2) {
      recommendations.add(
        'Atenção! Você está gastando ${((efficiencyIndex - 1) * 100).toStringAsFixed(0)}% mais rápido que o planejado',
      );
    } else if (efficiencyIndex < 0.8) {
      recommendations.add(
        'Parabéns! Você está economizando ${((1 - efficiencyIndex) * 100).toStringAsFixed(0)}% do orçamento',
      );
    }

    int daysUntilEnd = daysUntilBudgetEnds(
      budgetRemaining: budgetRemaining,
      burnRate: burnRate,
    );

    if (daysUntilEnd < daysRemaining) {
      recommendations.add(
        '🚨 No ritmo atual, seu orçamento acaba ${daysRemaining - daysUntilEnd} dias antes do fim da viagem',
      );
    }

    // Categoria 
    if (plannedBudget.isNotEmpty) {
      var overBudgetCategories = categorySpending.entries
          .where((e) =>
              (plannedBudget[e.key] ?? 0) > 0 &&
              e.value > (plannedBudget[e.key] ?? 0))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (overBudgetCategories.isNotEmpty) {
        var worst = overBudgetCategories.first;
        double overage = worst.value - (plannedBudget[worst.key] ?? 0);
        recommendations.add(
          '💡 Reduza gastos em ${worst.key} (R\$ ${overage.toStringAsFixed(2)} acima do planejado)',
        );
      }
    }

    
    if (plannedBudget.isNotEmpty) {
      var underBudgetCategories = categorySpending.entries
          .where((e) =>
              (plannedBudget[e.key] ?? 0) > 0 &&
              e.value < (plannedBudget[e.key] ?? 0))
          .toList()
        ..sort((a, b) => ((plannedBudget[b.key] ?? 0) - b.value)
            .compareTo((plannedBudget[a.key] ?? 0) - a.value));

      if (underBudgetCategories.isNotEmpty) {
        var best = underBudgetCategories.first;
        recommendations.add(
          '🎯 Continue economizando em ${best.key}!',
        );
      }
    }

    return recommendations;
  }

  static TripStatistics calculateTripStatistics({
    required Trip trip,
    required List<Expense> expenses,
  }) {
    if (expenses.isEmpty) {
      return TripStatistics(
        totalSpent: 0,
        averagePerDay: 0,
        averagePerExpense: 0,
        median: 0,
        stdDev: 0,
        minExpense: 0,
        maxExpense: 0,
        categoryBreakdown: {},
        weekdayBreakdown: {},
        efficiencyIndex: 0,
        burnRate: 0,
        projectedTotal: 0,
        budgetRemaining: trip.budget,
        daysUntilBudgetEnds: 999999,
        outliers: [],
        recommendations: [],
      );
    }

    double totalSpent = expenses.fold(0.0, (sum, e) => sum + e.value);
    List<double> values = expenses.map((e) => e.value).toList();

    int daysElapsed = trip.startDate != null
        ? DateTime.now().difference(trip.startDate!).inDays + 1
        : 1;
    int totalDays = trip.startDate != null && trip.endDate != null
        ? trip.endDate!.difference(trip.startDate!).inDays + 1
        : daysElapsed;

    double burnRate = calculateBurnRate(
      totalSpent: totalSpent,
      daysElapsed: daysElapsed,
    );

    double efficiencyIndex = calculateEfficiencyIndex(
      totalSpent: totalSpent,
      totalBudget: trip.budget,
      daysElapsed: daysElapsed,
      totalDays: totalDays,
    );

    Map<String, double> categorySpending = groupByCategory(expenses);

    return TripStatistics(
      totalSpent: totalSpent,
      averagePerDay: totalSpent / daysElapsed,
      averagePerExpense: totalSpent / expenses.length,
      median: calculateMedian(values),
      stdDev: calculateStdDev(values),
      minExpense: values.reduce(min),
      maxExpense: values.reduce(max),
      categoryBreakdown: categorySpending,
      weekdayBreakdown: groupByWeekday(expenses),
      efficiencyIndex: efficiencyIndex,
      burnRate: burnRate,
      projectedTotal: totalSpent +
          projectFutureSpending(
            burnRate: burnRate,
            daysRemaining: totalDays - daysElapsed,
          ),
      budgetRemaining: trip.budget - totalSpent,
      daysUntilBudgetEnds: daysUntilBudgetEnds(
        budgetRemaining: trip.budget - totalSpent,
        burnRate: burnRate,
      ),
      outliers: findOutliers(expenses),
      recommendations: generateRecommendations(
        efficiencyIndex: efficiencyIndex,
        burnRate: burnRate,
        budgetRemaining: trip.budget - totalSpent,
        daysRemaining: totalDays - daysElapsed,
        categorySpending: categorySpending,
        plannedBudget: {},
      ),
    );
  }
}

/// Classe para armazenar estatísticas de uma viagem
class TripStatistics {
  final double totalSpent;
  final double averagePerDay;
  final double averagePerExpense;
  final double median;
  final double stdDev;
  final double minExpense;
  final double maxExpense;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> weekdayBreakdown;
  final double efficiencyIndex;
  final double burnRate;
  final double projectedTotal;
  final double budgetRemaining;
  final int daysUntilBudgetEnds;
  final List<Expense> outliers;
  final List<String> recommendations;

  TripStatistics({
    required this.totalSpent,
    required this.averagePerDay,
    required this.averagePerExpense,
    required this.median,
    required this.stdDev,
    required this.minExpense,
    required this.maxExpense,
    required this.categoryBreakdown,
    required this.weekdayBreakdown,
    required this.efficiencyIndex,
    required this.burnRate,
    required this.projectedTotal,
    required this.budgetRemaining,
    required this.daysUntilBudgetEnds,
    required this.outliers,
    required this.recommendations,
  });

  String get efficiencyStatus {
    if (efficiencyIndex < 0.8) return 'Excelente';
    if (efficiencyIndex < 1.0) return 'Bom';
    if (efficiencyIndex < 1.2) return 'Atenção';
    return 'Crítico';
  }

  Color get efficiencyColor {
    if (efficiencyIndex < 0.8) return const Color(0xFF4CAF50); 
    if (efficiencyIndex < 1.0) return const Color(0xFF8BC34A); 
    if (efficiencyIndex < 1.2) return const Color(0xFFFFC107); 
    return const Color(0xFFF44336); 
  }
}

