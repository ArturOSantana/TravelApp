import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'http_client_service.dart';
import 'permission_service.dart';

/// - Nominatim (OpenStreetMap) para geocoding
/// - Geolocator para localização em tempo real
class LocationService {
  static const String _nominatimBase = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'TravelPlannerApp/1.0';

  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.length < 3) return [];

    try {
      final response = await HttpClientService.get(
        Uri.parse(
          '$_nominatimBase/search?q=$query&format=json&limit=10&accept-language=pt-BR',
        ),
        headers: {'User-Agent': _userAgent},
        timeout: const Duration(seconds: 8),
        cacheDuration: const Duration(hours: 24),
      );

      if (response == null) return [];

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'display_name': item['display_name'] as String,
                'lat': double.tryParse(item['lat'].toString()) ?? 0.0,
                'lon': double.tryParse(item['lon'].toString()) ?? 0.0,
                'type': item['type'] as String? ?? 'place',
                'importance': item['importance'] as double? ?? 0.0,
                'icon': item['icon'] as String?,
              },
            )
            .toList();
      }
    } catch (e) {
      print('Erro ao buscar lugares: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getAddressFromCoordinates(
    double lat,
    double lon,
  ) async {
    try {
      final response = await HttpClientService.get(
        Uri.parse(
          '$_nominatimBase/reverse?lat=$lat&lon=$lon&format=json&accept-language=pt-BR',
        ),
        headers: {'User-Agent': _userAgent},
        timeout: const Duration(seconds: 8),
        cacheDuration: const Duration(hours: 12),
      );

      if (response == null) return null;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'display_name': data['display_name'] as String,
          'address': data['address'] as Map<String, dynamic>?,
          'lat': lat,
          'lon': lon,
        };
      }
    } catch (e) {
      print('Erro ao buscar endereço: $e');
    }
    return null;
  }

  /// Obtém localização atual do dispositivo em tempo real
  /// Requer BuildContext para mostrar diálogos de permissão
  static Future<Position?> getCurrentLocation({BuildContext? context}) async {
    try {
      // Se o contexto foi fornecido, verifica permissão com UI
      if (context != null) {
        final hasPermission = await PermissionService.hasLocationPermission();
        if (!hasPermission) {
          final granted =
              await PermissionService.requestLocationPermission(context);
          if (!granted) {
            return null;
          }
        }
      } else {
        // Fallback: verifica permissão sem UI
        final hasPermission = await PermissionService.hasLocationPermission();
        if (!hasPermission) {
          print('Permissão de localização não concedida');
          return null;
        }
      }

      // Verifica se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Serviço de localização desabilitado');
        return null;
      }

      // Obtém posição atual
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      print('Erro ao obter localização: $e');
      return null;
    }
  }

  /// Stream de localização em tempo real
  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Atualiza a cada 10 metros
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Calcula distância entre dois pontos em metros
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Busca lugares próximos a uma coordenada
  static Future<List<Map<String, dynamic>>> searchNearby(
    double lat,
    double lon,
    String category, // ex: 'restaurant', 'hotel', 'tourism'
  ) async {
    try {
      // Nominatim não tem busca por categoria diretamente, mas podemos buscar por tipo
      final response = await HttpClientService.get(
        Uri.parse(
          '$_nominatimBase/search?'
          'q=$category&'
          'format=json&'
          'limit=20&'
          'viewbox=${lon - 0.1},${lat - 0.1},${lon + 0.1},${lat + 0.1}&'
          'bounded=1&'
          'accept-language=pt-BR',
        ),
        headers: {'User-Agent': _userAgent},
        timeout: const Duration(seconds: 10),
        cacheDuration: const Duration(hours: 6),
      );

      if (response == null) return [];

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final itemLat = double.tryParse(item['lat'].toString()) ?? 0.0;
          final itemLon = double.tryParse(item['lon'].toString()) ?? 0.0;
          final distance = calculateDistance(lat, lon, itemLat, itemLon);

          return {
            'display_name': item['display_name'] as String,
            'lat': itemLat,
            'lon': itemLon,
            'type': item['type'] as String? ?? 'place',
            'distance': distance,
            'distance_text': _formatDistance(distance),
          };
        }).toList()
          ..sort(
            (a, b) =>
                (a['distance'] as double).compareTo(b['distance'] as double),
          );
      }
    } catch (e) {
      print('Erro ao buscar lugares próximos: $e');
    }
    return [];
  }

  /// Formata distância para exibição
  static String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Obtém detalhes de um lugar específico
  static Future<Map<String, dynamic>?> getPlaceDetails(
    double lat,
    double lon,
  ) async {
    try {
      final response = await HttpClientService.get(
        Uri.parse(
          '$_nominatimBase/reverse?'
          'lat=$lat&'
          'lon=$lon&'
          'format=json&'
          'addressdetails=1&'
          'extratags=1&'
          'accept-language=pt-BR',
        ),
        headers: {'User-Agent': _userAgent},
        timeout: const Duration(seconds: 8),
        cacheDuration: const Duration(hours: 12),
      );

      if (response == null) return null;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'display_name': data['display_name'] as String,
          'address': data['address'] as Map<String, dynamic>?,
          'lat': lat,
          'lon': lon,
          'type': data['type'] as String?,
          'category': data['category'] as String?,
          'extratags': data['extratags'] as Map<String, dynamic>?,
        };
      }
    } catch (e) {
      print('Erro ao buscar detalhes do lugar: $e');
    }
    return null;
  }
}
