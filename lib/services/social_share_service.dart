import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';

class SocialShareService {
  static Future<void> shareTripCard({
    required BuildContext context,
    required Trip trip,
    required int photosCount,
    required double totalSpent,
  }) async {
    try {
      final widget = _TripShareCard(
        trip: trip,
        photosCount: photosCount,
        totalSpent: totalSpent,
      );

      final image = await _widgetToImage(widget);

      final file = await _saveImage(image, trip.destination);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Minha viagem para ${trip.destination}! #TravelApp #Viagem',
      );
    } catch (e) {
      print('Erro ao compartilhar: $e');
      rethrow;
    }
  }

  /// Converte um Widget em imagem
  static Future<ui.Image> _widgetToImage(Widget widget) async {
    final repaintBoundary = RenderRepaintBoundary();

    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration.fromView(view),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: widget,
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 2.0);
    return image;
  }

  /// Salva a imagem em arquivo temporário
  static Future<File> _saveImage(ui.Image image, String tripName) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/trip_${tripName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    await file.writeAsBytes(buffer);
    return file;
  }
}

/// Widget do card de compartilhamento
class _TripShareCard extends StatelessWidget {
  final Trip trip;
  final int photosCount;
  final double totalSpent;

  const _TripShareCard({
    required this.trip,
    required this.photosCount,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    return Container(
      width: 1080,
      height: 1920,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade700,
            Colors.deepPurple.shade400,
            Colors.purple.shade300,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Padrão de fundo decorativo
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPatternPainter(),
            ),
          ),

          // Conteúdo principal
          Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Título do App
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Travel App',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 80),

                // Card principal
                Container(
                  padding: const EdgeInsets.all(50),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Ícone grande
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade400,
                              Colors.purple.shade300,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flight_takeoff,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Destino
                      const Text(
                        'Minha Viagem para',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        trip.destination,
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 50),

                      // Estatísticas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat(
                            icon: Icons.calendar_today,
                            label: 'Duração',
                            value: _getDuration(),
                          ),
                          Container(
                            width: 2,
                            height: 80,
                            color: Colors.grey.shade300,
                          ),
                          _buildStat(
                            icon: Icons.photo_camera,
                            label: 'Fotos',
                            value: '$photosCount',
                          ),
                          Container(
                            width: 2,
                            height: 80,
                            color: Colors.grey.shade300,
                          ),
                          _buildStat(
                            icon: Icons.attach_money,
                            label: 'Gasto',
                            value: currencyFormat.format(totalSpent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),

                // Call to action
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Organize suas viagens com',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Travel App',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Marca d'água
          Positioned(
            bottom: 40,
            right: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '#TravelApp',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 40,
          color: Colors.deepPurple.shade400,
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple.shade700,
          ),
        ),
      ],
    );
  }

  String _getDuration() {
    if (trip.startDate == null || trip.endDate == null) {
      return 'N/A';
    }
    final days = trip.endDate!.difference(trip.startDate!).inDays + 1;
    return '$days dias';
  }
}

/// Painter para padrão decorativo de fundo
class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Desenhar círculos decorativos
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.2, size.height * (0.2 + i * 0.15)),
        50 + i * 30,
        paint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * (0.3 + i * 0.15)),
        40 + i * 25,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
