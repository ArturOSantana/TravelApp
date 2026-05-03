import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HeatmapWidget extends StatelessWidget {
  final Map<DateTime, double> data;
  final String title;

  const HeatmapWidget({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Sem dados para exibir'));
    }

    final weeks = _groupByWeeks(data);
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildWeekdayLabels(),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: weeks.map((week) {
                return _buildWeekColumn(context, week, maxValue);
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(context, maxValue),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    final weekdays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    return Row(
      children: [
        const SizedBox(width: 40),
        ...weekdays.map((day) => Container(
              width: 32,
              margin: const EdgeInsets.only(right: 4),
              child: Text(
                day,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )),
      ],
    );
  }

  Widget _buildWeekColumn(BuildContext context,
      List<MapEntry<DateTime, double>?> week, double maxValue) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 20,
          margin: const EdgeInsets.only(right: 4, bottom: 4),
          child: Text(
            DateFormat('dd/MM').format(week.first?.key ?? DateTime.now()),
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
        ...week.map((entry) {
          return _buildDayCell(context, entry, maxValue);
        }),
      ],
    );
  }

  Widget _buildDayCell(BuildContext context, MapEntry<DateTime, double>? entry,
      double maxValue) {
    if (entry == null) {
      return Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 4, bottom: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final intensity = entry.value / maxValue;
    final color = _getHeatColor(intensity);

    return Tooltip(
      message:
          '${DateFormat('dd/MM').format(entry.key)}\nR\$ ${entry.value.toStringAsFixed(2)}',
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 4, bottom: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
    );
  }

  Color _getHeatColor(double intensity) {
    if (intensity < 0.2) return Colors.green.shade100;
    if (intensity < 0.4) return Colors.green.shade300;
    if (intensity < 0.6) return Colors.yellow.shade300;
    if (intensity < 0.8) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  Widget _buildLegend(BuildContext context, double maxValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Menos', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          final intensity = (index + 1) / 5;
          return Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: _getHeatColor(intensity),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
        const SizedBox(width: 8),
        const Text('Mais', style: TextStyle(fontSize: 12)),
      ],
    );
  }

  List<List<MapEntry<DateTime, double>?>> _groupByWeeks(
      Map<DateTime, double> data) {
    if (data.isEmpty) return [];

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final firstDate = sortedEntries.first.key;
    final lastDate = sortedEntries.last.key;

    final startDate = firstDate.subtract(Duration(days: firstDate.weekday % 7));

    final weeks = <List<MapEntry<DateTime, double>?>>[];
    var currentDate = startDate;

    while (currentDate.isBefore(lastDate) ||
        currentDate.isAtSameMomentAs(lastDate)) {
      final week = <MapEntry<DateTime, double>?>[];

      for (int i = 0; i < 7; i++) {
        final date = currentDate.add(Duration(days: i));
        final entry = sortedEntries.firstWhere(
          (e) =>
              e.key.year == date.year &&
              e.key.month == date.month &&
              e.key.day == date.day,
          orElse: () => MapEntry(date, 0),
        );

        if (entry.value > 0 ||
            (date.isAfter(firstDate) && date.isBefore(lastDate))) {
          week.add(entry);
        } else {
          week.add(null);
        }
      }

      weeks.add(week);
      currentDate = currentDate.add(const Duration(days: 7));
    }

    return weeks;
  }
}

