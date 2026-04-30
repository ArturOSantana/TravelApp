import 'dart:convert';
import 'dart:math';
import '../config/api_keys.dart';
import 'http_client_service.dart';

class GeoapifyService {
  static const String _apiKey = ApiKeys.geoapify;
  static const String _baseUrl = 'https://api.geoapify.com/v1';

  static Future<Map<String, dynamic>?> calculateRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    String mode = 'walk',
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/routing?waypoints=$startLat,$startLon|$endLat,$endLon&mode=$mode&apiKey=$_apiKey',
      );

      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 10),
        cacheDuration: const Duration(hours: 2),
      );

      if (response == null) return null;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] ?? [];

        if (features.isEmpty) return null;

        final properties = features[0]['properties'];
        final geometry = features[0]['geometry'];

        return {
          'distance': properties['distance'] ?? 0, // metros
          'duration': properties['time'] ?? 0, // segundos
          'distanceKm':
              ((properties['distance'] ?? 0) / 1000).toStringAsFixed(2),
          'durationMin': ((properties['time'] ?? 0) / 60).round(),
          'coordinates': geometry['coordinates'] ?? [],
          'mode': mode,
        };
      } else {
        print('Erro Geoapify Routing: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro ao calcular rota: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> calculateMultiPointRoute({
    required List<Map<String, double>> waypoints,
    String mode = 'walk',
  }) async {
    try {
      if (waypoints.length < 2) return null;

      final waypointsStr =
          waypoints.map((w) => '${w['lat']},${w['lon']}').join('|');

      final url = Uri.parse(
        '$_baseUrl/routing?waypoints=$waypointsStr&mode=$mode&apiKey=$_apiKey',
      );

      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 12),
        cacheDuration: const Duration(hours: 2),
      );

      if (response == null) return null;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] ?? [];

        if (features.isEmpty) return null;

        final properties = features[0]['properties'];

        return {
          'distance': properties['distance'] ?? 0,
          'duration': properties['time'] ?? 0,
          'distanceKm':
              ((properties['distance'] ?? 0) / 1000).toStringAsFixed(2),
          'durationMin': ((properties['time'] ?? 0) / 60).round(),
          'waypoints': waypoints.length,
        };
      }
      return null;
    } catch (e) {
      print('Erro ao calcular rota multi-ponto: $e');
      return null;
    }
  }

  /// Calcula matriz de distâncias entre múltiplos pontos
  /// Útil para otimizar ordem de visitas
  ///
  /// [locations] Lista de coordenadas
  /// [mode] Modo de transporte
  static Future<List<List<double>>?> calculateDistanceMatrix({
    required List<Map<String, double>> locations,
    String mode = 'walk',
  }) async {
    try {
      if (locations.length < 2) return null;

      final locationsStr =
          locations.map((l) => '${l['lat']},${l['lon']}').join('|');

      final url = Uri.parse(
        '$_baseUrl/routematrix?sources=$locationsStr&targets=$locationsStr&mode=$mode&apiKey=$_apiKey',
      );

      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 15),
        cacheDuration: const Duration(hours: 4),
      );

      if (response == null) return null;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matrix = data['sources_to_targets'] ?? [];

        // Converter para matriz de distâncias em km
        return matrix.map<List<double>>((row) {
          return (row as List).map<double>((cell) {
            final distance = cell['distance'] ?? 0;
            return distance / 1000; // converter para km
          }).toList();
        }).toList();
      }
      return null;
    } catch (e) {
      print('Erro ao calcular matriz de distâncias: $e');
      return null;
    }
  }

  /// [activities] Lista de atividades com lat/lon
  static Future<List<Map<String, dynamic>>> optimizeRoute({
    required List<Map<String, dynamic>> activities,
    String mode = 'walk',
  }) async {
    try {
      if (activities.length <= 2) return activities;

      final locations = activities
          .map((a) => {
                'lat': a['lat'] as double,
                'lon': a['lon'] as double,
              })
          .toList();

      final matrix = await calculateDistanceMatrix(
        locations: locations,
        mode: mode,
      );

      if (matrix == null) return activities;

      // Algoritmo do vizinho mais próximo
      final visited = <int>{};
      final optimized = <Map<String, dynamic>>[];
      int current = 0; // Começar do primeiro ponto

      visited.add(current);
      optimized.add(activities[current]);

      while (visited.length < activities.length) {
        double minDistance = double.infinity;
        int nearest = -1;

        // Encontrar ponto mais próximo não visitado
        for (int i = 0; i < activities.length; i++) {
          if (!visited.contains(i) && matrix[current][i] < minDistance) {
            minDistance = matrix[current][i];
            nearest = i;
          }
        }

        if (nearest != -1) {
          visited.add(nearest);
          optimized.add(activities[nearest]);
          current = nearest;
        } else {
          break;
        }
      }

      return optimized;
    } catch (e) {
      print('Erro ao otimizar rota: $e');
      return activities;
    }
  }

  /// [activities] Lista de atividades ordenadas
  /// [mode] Modo de transporte
  static Future<Map<String, dynamic>> calculateTotalTravelTime({
    required List<Map<String, dynamic>> activities,
    String mode = 'walk',
  }) async {
    try {
      if (activities.length < 2) {
        return {'totalDistance': 0.0, 'totalDuration': 0, 'segments': []};
      }

      double totalDistance = 0;
      double totalDuration = 0;
      final segments = <Map<String, dynamic>>[];

      for (int i = 0; i < activities.length - 1; i++) {
        final current = activities[i];
        final next = activities[i + 1];

        final route = await calculateRoute(
          startLat: current['lat'],
          startLon: current['lon'],
          endLat: next['lat'],
          endLon: next['lon'],
          mode: mode,
        );

        if (route != null) {
          totalDistance += (route['distance'] as num).toDouble();
          totalDuration += (route['duration'] as num).toDouble();

          segments.add({
            'from': current['name'] ?? 'Ponto ${i + 1}',
            'to': next['name'] ?? 'Ponto ${i + 2}',
            'distance': route['distanceKm'],
            'duration': route['durationMin'],
          });
        }
      }

      return {
        'totalDistance': (totalDistance / 1000).toStringAsFixed(2),
        'totalDuration': (totalDuration / 60).round(),
        'segments': segments,
      };
    } catch (e) {
      print('Erro ao calcular tempo total: $e');
      return {'totalDistance': 0.0, 'totalDuration': 0, 'segments': []};
    }
  }

  /// Busca pontos turísticos e lugares próximos
  ///
  /// [lat] Latitude do local
  /// [lon] Longitude do local
  /// [categories] Categorias de lugares (tourism, entertainment, natural, etc)
  /// [radius] Raio de busca em metros (padrão: 5000m = 5km)
  /// [limit] Número máximo de resultados (padrão: 50)
  static Future<List<Map<String, dynamic>>> searchPlaces({
    required double lat,
    required double lon,
    String categories = 'tourism.attraction,tourism.sights',
    int radius = 5000,
    int limit = 50,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v2/places?categories=$categories&filter=circle:$lon,$lat,$radius&limit=$limit&apiKey=$_apiKey',
      );

      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 10),
        cacheDuration: const Duration(hours: 6),
      );

      if (response == null) return [];

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> features = data['features'] ?? [];

        return features.map((feature) {
          final props = feature['properties'] ?? {};
          final geometry = feature['geometry'];
          final coords = geometry?['coordinates'] ?? [];

          // Coordenadas do lugar
          final placeLat = coords.length > 1 ? coords[1] : lat;
          final placeLon = coords.length > 0 ? coords[0] : lon;

          // Distância da API ou calcular manualmente
          var distance = props['distance']?.toDouble() ?? 0.0;

          // Se a distância for 0, calcular manualmente usando fórmula de Haversine
          if (distance == 0 && placeLat != lat && placeLon != lon) {
            distance = _calculateDistance(lat, lon, placeLat, placeLon);
          }

          return {
            'place_id': props['place_id'] ?? '',
            'name': props['name'] ?? props['address_line1'] ?? 'Sem nome',
            'categories': props['categories'] ?? [],
            'lat': placeLat,
            'lon': placeLon,
            'distance': distance.toInt(),
            'address': props['address_line2'] ?? '',
            'city': props['city'] ?? '',
            'country': props['country'] ?? '',
          };
        }).toList();
      } else {
        print('Erro Geoapify Places: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erro ao buscar lugares: $e');
      return [];
    }
  }

  /// Retorna categorias disponíveis para busca de lugares
  static List<Map<String, String>> getPlaceCategories() {
    return [
      {
        'id': 'tourism.attraction,tourism.sights',
        'name': 'Atrações Turísticas',
        'icon': '🎭'
      },
      {
        'id': 'entertainment.museum,entertainment.culture',
        'name': 'Museus e Cultura',
        'icon': '🏛️'
      },
      {
        'id': 'natural,leisure.park',
        'name': 'Natureza e Parques',
        'icon': '🌳'
      },
      {
        'id': 'heritage,tourism.sights',
        'name': 'Monumentos Históricos',
        'icon': '🏰'
      },
      {
        'id': 'religion.place_of_worship',
        'name': 'Locais Religiosos',
        'icon': '⛪'
      },
      {'id': 'building.historic', 'name': 'Arquitetura', 'icon': '🏗️'},
      {'id': 'entertainment', 'name': 'Entretenimento', 'icon': '🎪'},
      {'id': 'sport', 'name': 'Esportes', 'icon': '⚽'},
    ];
  }

  static List<Map<String, String>> getTransportModes() {
    return [
      {'id': 'walk', 'name': 'A pé', 'icon': '🚶'},
      {'id': 'drive', 'name': 'Carro', 'icon': '🚗'},
      {'id': 'bicycle', 'name': 'Bicicleta', 'icon': '🚴'},
      {'id': 'transit', 'name': 'Transporte Público', 'icon': '🚌'},
    ];
  }

  /// Calcula distância entre dois pontos usando fórmula de Haversine
  /// Retorna distância em metros
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // metros

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Converte graus para radianos
  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}
