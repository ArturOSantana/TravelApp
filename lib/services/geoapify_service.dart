import 'dart:convert';
import 'dart:math';
import '../config/api_keys.dart';
import '../core/exceptions/app_exceptions.dart';
import 'http_client_service.dart';

/// Serviço de integração com Geoapify API
///
/// Responsabilidades:
/// - Cálculo de rotas e distâncias
/// - Otimização de rotas multi-ponto
/// - Busca de pontos de interesse
/// - Matriz de distâncias
///
/// API: https://www.geoapify.com/
class GeoapifyService {
  static const String _apiKey = ApiKeys.geoapify;
  static const String _baseUrl = 'https://api.geoapify.com/v1';
  static const String _placesUrl = 'https://api.geoapify.com/v2';

  // Constantes de validação
  static const double _minLatitude = -90.0;
  static const double _maxLatitude = 90.0;
  static const double _minLongitude = -180.0;
  static const double _maxLongitude = 180.0;
  static const int _maxWaypoints = 50;
  static const int _maxRadius = 50000; // 50km
  static const int _maxPlacesLimit = 500;

  /// Calcula rota entre dois pontos
  ///
  /// Parâmetros:
  /// - [startLat], [startLon]: Coordenadas de início
  /// - [endLat], [endLon]: Coordenadas de destino
  /// - [mode]: Modo de transporte (walk, drive, bicycle, transit)
  ///
  /// Retorna: Mapa com distância, duração e coordenadas da rota
  ///
  /// Lança:
  /// - [ValidationException]: Se coordenadas forem inválidas
  /// - [NetworkException]: Se houver erro na requisição
  static Future<Map<String, dynamic>> calculateRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    String mode = 'walk',
  }) async {
    // Validações
    _validateCoordinates(startLat, startLon, 'início');
    _validateCoordinates(endLat, endLon, 'destino');
    _validateTransportMode(mode);

    try {
      final url = Uri.parse(
        '$_baseUrl/routing?waypoints=$startLat,$startLon|$endLat,$endLon&mode=$mode&apiKey=$_apiKey',
      );

      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 10),
        cacheDuration: const Duration(hours: 2),
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List?;

        if (features == null || features.isEmpty) {
          throw NetworkException(
            'Nenhuma rota encontrada entre os pontos',
            code: 'no_route_found',
          );
        }

        final properties = features[0]['properties'] as Map<String, dynamic>;
        final geometry = features[0]['geometry'] as Map<String, dynamic>;

        final distance = (properties['distance'] as num?)?.toDouble() ?? 0.0;
        final duration = (properties['time'] as num?)?.toDouble() ?? 0.0;

        return {
          'distance': distance, // metros
          'duration': duration, // segundos
          'distanceKm': (distance / 1000).toStringAsFixed(2),
          'durationMin': (duration / 60).round(),
          'coordinates': geometry['coordinates'] ?? [],
          'mode': mode,
        };
      } else if (response.statusCode == 401) {
        throw NetworkException.unauthorized();
      } else if (response.statusCode == 429) {
        throw NetworkException.rateLimitExceeded();
      } else {
        throw NetworkException(
          'Erro ao calcular rota: ${response.statusCode}',
          statusCode: response.statusCode,
          code: 'route_calculation_failed',
        );
      }
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao calcular rota',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  /// Calcula rota com múltiplos pontos de parada
  ///
  /// Parâmetros:
  /// - [waypoints]: Lista de coordenadas (mínimo 2, máximo 50)
  /// - [mode]: Modo de transporte
  ///
  /// Retorna: Mapa com distância total e duração
  ///
  /// Lança:
  /// - [ValidationException]: Se waypoints forem inválidos
  /// - [NetworkException]: Se houver erro na requisição
  static Future<Map<String, dynamic>> calculateMultiPointRoute({
    required List<Map<String, double>> waypoints,
    String mode = 'walk',
  }) async {
    // Validações
    if (waypoints.length < 2) {
      throw ValidationException(
        'São necessários pelo menos 2 pontos para calcular rota',
      );
    }

    if (waypoints.length > _maxWaypoints) {
      throw ValidationException(
        'Máximo de $_maxWaypoints pontos permitidos',
      );
    }

    _validateTransportMode(mode);

    // Validar cada waypoint
    for (int i = 0; i < waypoints.length; i++) {
      final lat = waypoints[i]['lat'];
      final lon = waypoints[i]['lon'];

      if (lat == null || lon == null) {
        throw ValidationException(
          'Waypoint $i está com coordenadas inválidas',
        );
      }

      _validateCoordinates(lat, lon, 'waypoint $i');
    }

    try {
      final waypointsStr =
          waypoints.map((w) => '${w['lat']},${w['lon']}').join('|');

      final url = Uri.parse(
        '$_baseUrl/routing?waypoints=$waypointsStr&mode=$mode&apiKey=$_apiKey',
      );

      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 15),
        cacheDuration: const Duration(hours: 2),
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List?;

        if (features == null || features.isEmpty) {
          throw NetworkException(
            'Nenhuma rota encontrada',
            code: 'no_route_found',
          );
        }

        final properties = features[0]['properties'] as Map<String, dynamic>;
        final distance = (properties['distance'] as num?)?.toDouble() ?? 0.0;
        final duration = (properties['time'] as num?)?.toDouble() ?? 0.0;

        return {
          'distance': distance,
          'duration': duration,
          'distanceKm': (distance / 1000).toStringAsFixed(2),
          'durationMin': (duration / 60).round(),
          'waypoints': waypoints.length,
        };
      } else if (response.statusCode == 401) {
        throw NetworkException.unauthorized();
      } else if (response.statusCode == 429) {
        throw NetworkException.rateLimitExceeded();
      } else {
        throw NetworkException(
          'Erro ao calcular rota multi-ponto',
          statusCode: response.statusCode,
          code: 'multi_route_failed',
        );
      }
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao calcular rota multi-ponto',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  /// Calcula matriz de distâncias entre múltiplos pontos
  /// Útil para otimizar ordem de visitas
  ///
  /// Parâmetros:
  /// - [locations]: Lista de coordenadas (mínimo 2)
  /// - [mode]: Modo de transporte
  ///
  /// Retorna: Matriz de distâncias em km
  ///
  /// Lança:
  /// - [ValidationException]: Se locations forem inválidas
  /// - [NetworkException]: Se houver erro na requisição
  static Future<List<List<double>>> calculateDistanceMatrix({
    required List<Map<String, double>> locations,
    String mode = 'walk',
  }) async {
    if (locations.length < 2) {
      throw ValidationException(
        'São necessários pelo menos 2 locais para calcular matriz',
      );
    }

    if (locations.length > _maxWaypoints) {
      throw ValidationException(
        'Máximo de $_maxWaypoints locais permitidos',
      );
    }

    _validateTransportMode(mode);

    // Validar cada localização
    for (int i = 0; i < locations.length; i++) {
      final lat = locations[i]['lat'];
      final lon = locations[i]['lon'];

      if (lat == null || lon == null) {
        throw ValidationException(
          'Localização $i está com coordenadas inválidas',
        );
      }

      _validateCoordinates(lat, lon, 'localização $i');
    }

    try {
      final locationsStr =
          locations.map((l) => '${l['lat']},${l['lon']}').join('|');

      final url = Uri.parse(
        '$_baseUrl/routematrix?sources=$locationsStr&targets=$locationsStr&mode=$mode&apiKey=$_apiKey',
      );

      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 20),
        cacheDuration: const Duration(hours: 4),
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matrix = data['sources_to_targets'] as List?;

        if (matrix == null) {
          throw NetworkException(
            'Matriz de distâncias não retornada pela API',
            code: 'invalid_response',
          );
        }

        // Converter para matriz de distâncias em km
        return matrix.map<List<double>>((row) {
          return (row as List).map<double>((cell) {
            final distance = (cell['distance'] as num?)?.toDouble() ?? 0.0;
            return distance / 1000; // converter para km
          }).toList();
        }).toList();
      } else if (response.statusCode == 401) {
        throw NetworkException.unauthorized();
      } else if (response.statusCode == 429) {
        throw NetworkException.rateLimitExceeded();
      } else {
        throw NetworkException(
          'Erro ao calcular matriz de distâncias',
          statusCode: response.statusCode,
          code: 'matrix_calculation_failed',
        );
      }
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao calcular matriz de distâncias',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  /// Otimiza ordem de visita de atividades usando algoritmo do vizinho mais próximo
  ///
  /// Parâmetros:
  /// - [activities]: Lista de atividades com lat/lon
  /// - [mode]: Modo de transporte
  ///
  /// Retorna: Lista de atividades ordenada de forma otimizada
  ///
  /// Nota: Para 2 ou menos atividades, retorna a lista original
  static Future<List<Map<String, dynamic>>> optimizeRoute({
    required List<Map<String, dynamic>> activities,
    String mode = 'walk',
  }) async {
    if (activities.isEmpty) {
      throw ValidationException('Lista de atividades não pode estar vazia');
    }

    if (activities.length <= 2) {
      return activities;
    }

    try {
      final locations = <Map<String, double>>[];

      for (int i = 0; i < activities.length; i++) {
        final activity = activities[i];
        final lat = activity['lat'];
        final lon = activity['lon'];

        if (lat == null || lon == null) {
          throw ValidationException(
            'Atividade $i não possui coordenadas válidas',
          );
        }

        locations.add({
          'lat': (lat as num).toDouble(),
          'lon': (lon as num).toDouble(),
        });
      }

      final matrix = await calculateDistanceMatrix(
        locations: locations,
        mode: mode,
      );

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
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro ao otimizar rota',
        code: 'optimization_failed',
        originalError: e,
      );
    }
  }

  /// Calcula tempo total de viagem entre atividades ordenadas
  ///
  /// Parâmetros:
  /// - [activities]: Lista de atividades ordenadas
  /// - [mode]: Modo de transporte
  ///
  /// Retorna: Mapa com distância total, duração e segmentos
  static Future<Map<String, dynamic>> calculateTotalTravelTime({
    required List<Map<String, dynamic>> activities,
    String mode = 'walk',
  }) async {
    if (activities.isEmpty) {
      throw ValidationException('Lista de atividades não pode estar vazia');
    }

    if (activities.length < 2) {
      return {
        'totalDistance': '0.00',
        'totalDuration': 0,
        'segments': <Map<String, dynamic>>[],
      };
    }

    try {
      double totalDistance = 0;
      double totalDuration = 0;
      final segments = <Map<String, dynamic>>[];

      for (int i = 0; i < activities.length - 1; i++) {
        final current = activities[i];
        final next = activities[i + 1];

        final currentLat = current['lat'];
        final currentLon = current['lon'];
        final nextLat = next['lat'];
        final nextLon = next['lon'];

        if (currentLat == null ||
            currentLon == null ||
            nextLat == null ||
            nextLon == null) {
          throw ValidationException(
            'Atividade ${i + 1} ou ${i + 2} não possui coordenadas válidas',
          );
        }

        final route = await calculateRoute(
          startLat: (currentLat as num).toDouble(),
          startLon: (currentLon as num).toDouble(),
          endLat: (nextLat as num).toDouble(),
          endLon: (nextLon as num).toDouble(),
          mode: mode,
        );

        totalDistance += route['distance'] as double;
        totalDuration += route['duration'] as double;

        segments.add({
          'from': current['name'] ?? 'Ponto ${i + 1}',
          'to': next['name'] ?? 'Ponto ${i + 2}',
          'distance': route['distanceKm'],
          'duration': route['durationMin'],
        });
      }

      return {
        'totalDistance': (totalDistance / 1000).toStringAsFixed(2),
        'totalDuration': (totalDuration / 60).round(),
        'segments': segments,
      };
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro ao calcular tempo total de viagem',
        code: 'travel_time_calculation_failed',
        originalError: e,
      );
    }
  }

  /// Busca pontos turísticos e lugares próximos
  ///
  /// Parâmetros:
  /// - [lat], [lon]: Coordenadas do local de busca
  /// - [categories]: Categorias de lugares (tourism, entertainment, natural, etc)
  /// - [radius]: Raio de busca em metros (máximo: 50km)
  /// - [limit]: Número máximo de resultados (máximo: 500)
  ///
  /// Retorna: Lista de lugares encontrados
  ///
  /// Lança:
  /// - [ValidationException]: Se parâmetros forem inválidos
  /// - [NetworkException]: Se houver erro na requisição
  static Future<List<Map<String, dynamic>>> searchPlaces({
    required double lat,
    required double lon,
    String categories = 'tourism.attraction,tourism.sights',
    int radius = 5000,
    int limit = 50,
  }) async {
    // Validações
    _validateCoordinates(lat, lon, 'busca');

    if (radius <= 0 || radius > _maxRadius) {
      throw ValidationException(
        'Raio deve estar entre 1 e $_maxRadius metros',
      );
    }

    if (limit <= 0 || limit > _maxPlacesLimit) {
      throw ValidationException(
        'Limite deve estar entre 1 e $_maxPlacesLimit',
      );
    }

    if (categories.trim().isEmpty) {
      throw ValidationException('Categorias não podem estar vazias');
    }

    try {
      final url = Uri.parse(
        '$_placesUrl/places?categories=$categories&filter=circle:$lon,$lat,$radius&limit=$limit&apiKey=$_apiKey',
      );

      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 10),
        cacheDuration: const Duration(hours: 6),
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> features = data['features'] ?? [];

        return features.map((feature) {
          final props = feature['properties'] as Map<String, dynamic>? ?? {};
          final geometry = feature['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List? ?? [];

          // Coordenadas do lugar
          final placeLat =
              coords.length > 1 ? (coords[1] as num).toDouble() : lat;
          final placeLon =
              coords.length > 0 ? (coords[0] as num).toDouble() : lon;

          // Distância da API ou calcular manualmente
          var distance = (props['distance'] as num?)?.toDouble() ?? 0.0;

          // Se a distância for 0, calcular manualmente usando fórmula de Haversine
          if (distance == 0 && (placeLat != lat || placeLon != lon)) {
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
      } else if (response.statusCode == 401) {
        throw NetworkException.unauthorized();
      } else if (response.statusCode == 429) {
        throw NetworkException.rateLimitExceeded();
      } else {
        throw NetworkException(
          'Erro ao buscar lugares',
          statusCode: response.statusCode,
          code: 'places_search_failed',
        );
      }
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao buscar lugares',
        code: 'unexpected_error',
        originalError: e,
      );
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

  /// Retorna modos de transporte disponíveis
  static List<Map<String, String>> getTransportModes() {
    return [
      {'id': 'walk', 'name': 'A pé', 'icon': '🚶'},
      {'id': 'drive', 'name': 'Carro', 'icon': '🚗'},
      {'id': 'bicycle', 'name': 'Bicicleta', 'icon': '🚴'},
      {'id': 'transit', 'name': 'Transporte Público', 'icon': '🚌'},
    ];
  }

  // ========== MÉTODOS PRIVADOS DE VALIDAÇÃO ==========

  /// Valida coordenadas geográficas
  static void _validateCoordinates(double lat, double lon, String context) {
    if (lat < _minLatitude || lat > _maxLatitude) {
      throw ValidationException(
        'Latitude de $context inválida: $lat. Deve estar entre $_minLatitude e $_maxLatitude',
      );
    }

    if (lon < _minLongitude || lon > _maxLongitude) {
      throw ValidationException(
        'Longitude de $context inválida: $lon. Deve estar entre $_minLongitude e $_maxLongitude',
      );
    }
  }

  /// Valida modo de transporte
  static void _validateTransportMode(String mode) {
    const validModes = ['walk', 'drive', 'bicycle', 'transit'];

    if (!validModes.contains(mode)) {
      throw ValidationException(
        'Modo de transporte inválido: $mode. Modos válidos: ${validModes.join(", ")}',
      );
    }
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

// Made with Bob
