import 'package:flutter/material.dart';
import 'dart:math' as math;

class GaugeChartWidget extends StatelessWidget {
  final double value; 
  final String title;
  final String subtitle;
  final Color? color;

  const GaugeChartWidget({
    super.key,
    required this.value,
    required this.title,
    required this.subtitle,
    this.color,
  });

  Color _getColor() {
    if (color != null) return color!;

    if (value < 0.5) return Colors.green;
    if (value < 0.75) return Colors.orange;
    if (value < 0.9) return Colors.deepOrange;
    return Colors.red;
  }

  String _getStatus() {
    if (value < 0.5) return 'Excelente';
    if (value < 0.75) return 'Bom';
    if (value < 0.9) return 'Atenção';
    return 'Crítico';
  }

  @override
  Widget build(BuildContext context) {
    final gaugeColor = _getColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            width: 200,
            child: CustomPaint(
              painter: _GaugePainter(
                value: value.clamp(0.0, 1.0),
                color: gaugeColor,
                backgroundColor:
                    Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(value * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: gaugeColor,
                      ),
                    ),
                    Text(
                      _getStatus(),
                      style: TextStyle(
                        fontSize: 14,
                        color: gaugeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color backgroundColor;

  _GaugePainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75, 
      math.pi * 1.5, 
      false,
      backgroundPaint,
    );

    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.5),
          color,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * value,
      false,
      progressPaint,
    );

    _drawMarkers(canvas, center, radius);
  }

  void _drawMarkers(Canvas canvas, Offset center, double radius) {
    final markerPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i <= 10; i++) {
      final angle = math.pi * 0.75 + (math.pi * 1.5 * i / 10);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      canvas.drawCircle(
        Offset(x, y),
        i % 2 == 0 ? 4 : 2,
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

