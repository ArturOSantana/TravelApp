import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LineChartWidget extends StatelessWidget {
  final Map<DateTime, double> data;
  final String title;
  final Color lineColor;
  final bool showMovingAverage;
  final double? budgetLine;

  const LineChartWidget({
    super.key,
    required this.data,
    required this.title,
    this.lineColor = Colors.blue,
    this.showMovingAverage = false,
    this.budgetLine,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Sem dados para exibir'));
    }

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    final minValue = data.values.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    // Calcula média móvel de 3 dias se solicitado
    List<double>? movingAvg;
    if (showMovingAverage && sortedEntries.length >= 3) {
      movingAvg = [];
      for (int i = 0; i < sortedEntries.length - 2; i++) {
        double avg = (sortedEntries[i].value +
                sortedEntries[i + 1].value +
                sortedEntries[i + 2].value) /
            3;
        movingAvg.add(avg);
      }
    }

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
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                data: sortedEntries,
                maxValue: maxValue,
                minValue: minValue,
                lineColor: lineColor,
                movingAverage: movingAvg,
                budgetLine: budgetLine,
                theme: Theme.of(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildLegend(context, movingAvg != null),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, bool hasMovingAvg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(context, 'Gastos', lineColor),
        if (hasMovingAvg) ...[
          const SizedBox(width: 16),
          _buildLegendItem(context, 'Média Móvel', lineColor.withOpacity(0.5)),
        ],
        if (budgetLine != null) ...[
          const SizedBox(width: 16),
          _buildLegendItem(context, 'Orçamento', Colors.red),
        ],
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<MapEntry<DateTime, double>> data;
  final double maxValue;
  final double minValue;
  final Color lineColor;
  final List<double>? movingAverage;
  final double? budgetLine;
  final ThemeData theme;

  _LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.minValue,
    required this.lineColor,
    this.movingAverage,
    this.budgetLine,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = lineColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = theme.colorScheme.outline.withOpacity(0.2)
      ..strokeWidth = 1;

    // Desenha grid horizontal
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    if (data.isEmpty) return;

    final range = maxValue - minValue;
    final xStep = size.width / (data.length - 1);

    // Desenha linha de orçamento se fornecida
    if (budgetLine != null && range > 0) {
      final budgetY =
          size.height - ((budgetLine! - minValue) / range * size.height);
      final budgetPaint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(0, budgetY),
        Offset(size.width, budgetY),
        budgetPaint,
      );
    }

    // Desenha área preenchida
    final fillPath = Path();
    fillPath.moveTo(0, size.height);

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = range > 0
          ? size.height - ((data[i].value - minValue) / range * size.height)
          : size.height / 2;

      if (i == 0) {
        fillPath.lineTo(x, y);
      } else {
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Desenha linha principal
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = range > 0
          ? size.height - ((data[i].value - minValue) / range * size.height)
          : size.height / 2;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Desenha pontos
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = range > 0
          ? size.height - ((data[i].value - minValue) / range * size.height)
          : size.height / 2;

      // Verifica se x e y são válidos antes de desenhar
      if (!x.isNaN && !y.isNaN && x.isFinite && y.isFinite) {
        canvas.drawCircle(Offset(x, y), 4, pointPaint);
        canvas.drawCircle(
          Offset(x, y),
          4,
          Paint()
            ..color = theme.colorScheme.surface
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // Desenha média móvel se fornecida
    if (movingAverage != null && movingAverage!.isNotEmpty) {
      final avgPaint = Paint()
        ..color = lineColor.withOpacity(0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final avgPath = Path();
      for (int i = 0; i < movingAverage!.length; i++) {
        final x = (i + 1) * xStep;
        final y = range > 0
            ? size.height -
                ((movingAverage![i] - minValue) / range * size.height)
            : size.height / 2;

        if (i == 0) {
          avgPath.moveTo(x, y);
        } else {
          avgPath.lineTo(x, y);
        }
      }

      canvas.drawPath(avgPath, avgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
