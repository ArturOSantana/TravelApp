import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'http_client_service.dart';
import 'permission_service.dart';
import '../core/exceptions/app_exceptions.dart';

class LocationService {
  static const String _nominatimBase = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'TravelPlannerApp/1.0';
  static const int _minQueryLength = 3;

  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      throw ValidationException.emptyField('query');
    }

    if (query.trim().length < _minQueryLength) {
      throw ValidationException.invalidValue(
        'query',
        'A busca deve ter pelo menos $_minQueryLength caracteres',
      );
    }

    try {
      final response = await HttpClientService.get(
        Uri.parse(
          '$_nominatimBase/search?q=${Uri.encodeComponent(query.trim())}&format=json&limit=10&accept-language=pt-BR',
        ),
        headers: {'User-Agent': _userAgent},
        timeout: const Duration(seconds: 8),
        cacheDuration: const Duration(hours: 24),
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

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
      } else if (response.statusCode == 429) {
        throw NetworkException(
          'Muitas requisições. Aguarde um momento',
          statusCode: 429,
          code: 'rate-limit',
        );
      } else {
        throw NetworkException.serverError(response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro ao buscar lugares',
        code: 'search-failed',
        originalError: e,
      );
    }
  }

  static Future<Map<String, dynamic>> getAddressFromCoordinates(
    double lat,
    double lon,
  ) async {
    // Validar coordenadas
    if (lat < -90 || lat > 90) {
      throw ValidationException.invalidValue(
          'latitude', 'Latitude deve estar entre -90 e 90');
    }
    if (lon < -180 || lon > 180) {
      throw ValidationException.invalidValue(
          'longitude', 'Longitude deve estar entre -180 e 180');
    }

    try {
      final response = await HttpClientService.get(
        Uri.parse(
          '$_nominatimBase/reverse?lat=$lat&lon=$lon&format=json&accept-language=pt-BR',
        ),
        headers: {'User-Agent': _userAgent},
        timeout: const Duration(seconds: 8),
        cacheDuration: const Duration(hours: 12),
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['error'] != null) {
          throw NetworkException(
            'Endereço não encontrado para estas coordenadas',
            code: 'address-not-found',
          );
        }

        return {
          'display_name': data['display_name'] as String,
          'address': data['address'] as Map<String, dynamic>?,
          'lat': lat,
          'lon': lon,
        };
      } else if (response.statusCode == 429) {
        throw NetworkException(
          'Muitas requisições. Aguarde um momento',
          statusCode: 429,
          code: 'rate-limit',
        );
      } else {
        throw NetworkException.serverError(response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro ao buscar endereço',
        code: 'reverse-geocoding-failed',
        originalError: e,
      );
    }
  }

  static Future<Position> getCurrentLocation({BuildContext? context}) async {
    try {
      // Verificar e solicitar permissão
      if (context != null) {
        final hasPermission = await PermissionService.hasLocationPermission();
        if (!hasPermission) {
          final granted =
              await PermissionService.requestLocationPermission(context);
          if (!granted) {
            throw PermissionException.locationDenied();
          }
        }
      } else {
        final hasPermission = await PermissionService.hasLocationPermission();
        if (!hasPermission) {
          throw PermissionException.locationDenied();
        }
      }

      // Verificar se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw GenericException(
          'Serviço de localização desabilitado. Ative o GPS nas configurações',
          code: 'location-service-disabled',
        );
      }

      // Obtém posição atual
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw GenericException(
        'Erro ao obter localização',
        code: 'get-location-failed',
        originalError: e,
      );
    }
  }

  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Atualiza a cada 10 metros
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  static Future<List<Map<String, dynamic>>> searchNearby(
    double lat,
    double lon,
    String category,
  ) async {
    // Validar coordenadas
    if (lat < -90 || lat > 90) {
      throw ValidationException.invalidValue('latitude', 'Latitude inválida');
    }
    if (lon < -180 || lon > 180) {
      throw ValidationException.invalidValue('longitude', 'Longitude inválida');
    }
    if (category.trim().isEmpty) {
      throw ValidationException.emptyField('category');
    }

    try {
      final response = await HttpClientService.get(
        Uri.parse(
          '$_nominatimBase/search?'
          'q=${Uri.encodeComponent(category.trim())}&'
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

      if (response == null) {
        throw NetworkException.timeout();
      }

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
      } else if (response.statusCode == 429) {
        throw NetworkException(
          'Muitas requisições. Aguarde um momento',
          statusCode: 429,
          code: 'rate-limit',
        );
      } else {
        throw NetworkException.serverError(response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro ao buscar lugares próximos',
        code: 'search-nearby-failed',
        originalError: e,
      );
    }
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  static Future<Map<String, dynamic>> getPlaceDetails(
    double lat,
    double lon,
  ) async {
    // Validar coordenadas
    if (lat < -90 || lat > 90) {
      throw ValidationException.invalidValue('latitude', 'Latitude inválida');
    }
    if (lon < -180 || lon > 180) {
      throw ValidationException.invalidValue('longitude', 'Longitude inválida');
    }

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

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['error'] != null) {
          throw NetworkException(
            'Detalhes não encontrados para estas coordenadas',
            code: 'details-not-found',
          );
        }

        return {
          'display_name': data['display_name'] as String,
          'address': data['address'] as Map<String, dynamic>?,
          'lat': lat,
          'lon': lon,
          'type': data['type'] as String?,
          'category': data['category'] as String?,
          'extratags': data['extratags'] as Map<String, dynamic>?,
        };
      } else if (response.statusCode == 429) {
        throw NetworkException(
          'Muitas requisições. Aguarde um momento',
          statusCode: 429,
          code: 'rate-limit',
        );
      } else {
        throw NetworkException.serverError(response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro ao buscar detalhes do lugar',
        code: 'get-details-failed',
        originalError: e,
      );
    }
  }
}
