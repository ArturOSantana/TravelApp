import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('Lógica de Geofencing', () {
    test('Deve calcular distância e identificar chegada (raio < 50m)', () {
      const double hotelLat = -23.5615;
      const double hotelLon = -46.6560;
      
      const double userLat = -23.5617;
      const double userLon = -46.6561;

      final double distance = Geolocator.distanceBetween(hotelLat, hotelLon, userLat, userLon);
      
      print('Distância calculada: ${distance.toStringAsFixed(2)}m');
      expect(distance < 50, true);
    });

    test('Deve identificar desvio de rota (raio > 300m)', () {
      const double hotelLat = -23.5615;
      const double hotelLon = -46.6560;
      
      const double userLat = -23.5650; // Afastou-se
      const double userLon = -46.6590;

      final double distance = Geolocator.distanceBetween(hotelLat, hotelLon, userLat, userLon);
      
      print('Distância de desvio: ${distance.toStringAsFixed(2)}m');
      expect(distance > 300, true);
    });
  });
}
