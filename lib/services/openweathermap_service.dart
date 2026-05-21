import 'dart:convert';
import '../config/api_keys.dart';
import '../core/exceptions/app_exceptions.dart';
import 'http_client_service.dart';


class OpenWeatherMapService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Constantes de validação
  static const double _minLatitude = -90.0;
  static const double _maxLatitude = 90.0;
  static const double _minLongitude = -180.0;
  static const double _maxLongitude = 180.0;
  static const int _minCityNameLength = 2;

  static Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    _validateCityName(city);

    try {
      final url = Uri.parse(
        '$_baseUrl/weather?q=$city&appid=${ApiKeys.openWeatherMap}&units=metric&lang=pt_br',
      );

      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 8),
        cacheDuration: const Duration(minutes: 30),
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return _parseWeatherData(data);
      } else if (response.statusCode == 401) {
        throw NetworkException.apiKeyInvalid();
      } else if (response.statusCode == 404) {
        throw NetworkException(
          'Cidade não encontrada: $city',
          statusCode: 404,
          code: 'city_not_found',
        );
      } else if (response.statusCode == 429) {
        throw NetworkException.rateLimitExceeded();
      } else {
        throw NetworkException(
          'Erro ao buscar clima: ${response.statusCode}',
          statusCode: response.statusCode,
          code: 'weather_fetch_failed',
        );
      }
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao buscar clima',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getForecast(String city) async {
    _validateCityName(city);

    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?q=$city&appid=${ApiKeys.openWeatherMap}&units=metric&lang=pt_br',
      );

      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 8),
        cacheDuration: const Duration(hours: 1),
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> list = data['list'] ?? [];

        if (list.isEmpty) {
          throw NetworkException(
            'Nenhuma previsão disponível',
            code: 'no_forecast_data',
          );
        }

        return list.map((item) => _parseForecastItem(item)).toList();
      } else if (response.statusCode == 401) {
        throw NetworkException.apiKeyInvalid();
      } else if (response.statusCode == 404) {
        throw NetworkException(
          'Cidade não encontrada: $city',
          statusCode: 404,
          code: 'city_not_found',
        );
      } else if (response.statusCode == 429) {
        throw NetworkException.rateLimitExceeded();
      } else {
        throw NetworkException(
          'Erro ao buscar previsão: ${response.statusCode}',
          statusCode: response.statusCode,
          code: 'forecast_fetch_failed',
        );
      }
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao buscar previsão',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  static Future<Map<String, dynamic>> getCurrentWeatherByCoords(
    double lat,
    double lon,
  ) async {
    _validateCoordinates(lat, lon);

    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=${ApiKeys.openWeatherMap}&units=metric&lang=pt_br',
      );

      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 8),
        cacheDuration: const Duration(minutes: 30),
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return _parseWeatherData(data);
      } else if (response.statusCode == 401) {
        throw NetworkException.apiKeyInvalid();
      } else if (response.statusCode == 400) {
        throw ValidationException(
          'Coordenadas inválidas: lat=$lat, lon=$lon',
        );
      } else if (response.statusCode == 429) {
        throw NetworkException.rateLimitExceeded();
      } else {
        throw NetworkException(
          'Erro ao buscar clima por coordenadas: ${response.statusCode}',
          statusCode: response.statusCode,
          code: 'weather_coords_fetch_failed',
        );
      }
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao buscar clima por coordenadas',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getForecastByCoords(
    double lat,
    double lon,
  ) async {
    _validateCoordinates(lat, lon);

    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=${ApiKeys.openWeatherMap}&units=metric&lang=pt_br',
      );

      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 8),
        cacheDuration: const Duration(hours: 1),
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> list = data['list'] ?? [];

        if (list.isEmpty) {
          throw NetworkException(
            'Nenhuma previsão disponível',
            code: 'no_forecast_data',
          );
        }

        return list.map((item) => _parseForecastItem(item)).toList();
      } else if (response.statusCode == 401) {
        throw NetworkException.apiKeyInvalid();
      } else if (response.statusCode == 400) {
        throw ValidationException(
          'Coordenadas inválidas: lat=$lat, lon=$lon',
        );
      } else if (response.statusCode == 429) {
        throw NetworkException.rateLimitExceeded();
      } else {
        throw NetworkException(
          'Erro ao buscar previsão por coordenadas: ${response.statusCode}',
          statusCode: response.statusCode,
          code: 'forecast_coords_fetch_failed',
        );
      }
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao buscar previsão por coordenadas',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  static String getIconUrl(String iconCode) {
    if (iconCode.isEmpty) {
      return 'https://openweathermap.org/img/wn/01d@2x.png'; // fallback
    }
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  static String getWeatherEmoji(String iconCode) {
    switch (iconCode) {
      case '01d':
      case '01n':
        return '☀️'; // Céu limpo
      case '02d':
      case '02n':
        return '⛅'; // Poucas nuvens
      case '03d':
      case '03n':
        return '☁️'; // Nuvens dispersas
      case '04d':
      case '04n':
        return '☁️'; // Nublado
      case '09d':
      case '09n':
        return '🌧️'; // Chuva
      case '10d':
      case '10n':
        return '🌦️'; // Chuva leve
      case '11d':
      case '11n':
        return '⛈️'; // Trovoada
      case '13d':
      case '13n':
        return '❄️'; // Neve
      case '50d':
      case '50n':
        return '🌫️'; // Névoa
      default:
        return '🌤️';
    }
  }

  static String getWindDirection(int degrees) {
    if (degrees < 0 || degrees > 360) {
      return 'Desconhecido';
    }

    if (degrees >= 337.5 || degrees < 22.5) return 'Norte';
    if (degrees >= 22.5 && degrees < 67.5) return 'Nordeste';
    if (degrees >= 67.5 && degrees < 112.5) return 'Leste';
    if (degrees >= 112.5 && degrees < 157.5) return 'Sudeste';
    if (degrees >= 157.5 && degrees < 202.5) return 'Sul';
    if (degrees >= 202.5 && degrees < 247.5) return 'Sudoeste';
    if (degrees >= 247.5 && degrees < 292.5) return 'Oeste';
    if (degrees >= 292.5 && degrees < 337.5) return 'Noroeste';
    return 'Desconhecido';
  }

  static List<Map<String, dynamic>> groupForecastByDay(
    List<Map<String, dynamic>> forecast,
  ) {
    if (forecast.isEmpty) {
      return [];
    }

    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in forecast) {
      final date = item['dt'] as DateTime;
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(item);
    }

    return grouped.entries.map((entry) {
      final items = entry.value;
      final temps = items.map((i) => i['temp'] as int).toList();
      final descriptions =
          items.map((i) => i['description'] as String).toList();
      final icons = items.map((i) => i['icon'] as String).toList();

      return {
        'date': items.first['dt'],
        'temp_avg': (temps.reduce((a, b) => a + b) / temps.length).round(),
        'temp_min': temps.reduce((a, b) => a < b ? a : b),
        'temp_max': temps.reduce((a, b) => a > b ? a : b),
        'description': descriptions.first,
        'icon': icons.first,
      };
    }).toList();
  }

  static void _validateCityName(String city) {
    if (city.trim().isEmpty) {
      throw ValidationException('Nome da cidade não pode estar vazio');
    }

    if (city.trim().length < _minCityNameLength) {
      throw ValidationException(
        'Nome da cidade deve ter pelo menos $_minCityNameLength caracteres',
      );
    }
  }

  static void _validateCoordinates(double lat, double lon) {
    if (lat < _minLatitude || lat > _maxLatitude) {
      throw ValidationException(
        'Latitude inválida: $lat. Deve estar entre $_minLatitude e $_maxLatitude',
      );
    }

    if (lon < _minLongitude || lon > _maxLongitude) {
      throw ValidationException(
        'Longitude inválida: $lon. Deve estar entre $_minLongitude e $_maxLongitude',
      );
    }
  }

  static Map<String, dynamic> _parseWeatherData(Map<String, dynamic> data) {
    try {
      final main = data['main'] as Map<String, dynamic>;
      final weather = (data['weather'] as List).first as Map<String, dynamic>;
      final wind = data['wind'] as Map<String, dynamic>;
      final clouds = data['clouds'] as Map<String, dynamic>;
      final sys = data['sys'] as Map<String, dynamic>;

      return {
        'temp': (main['temp'] as num).round(),
        'feels_like': (main['feels_like'] as num).round(),
        'temp_min': (main['temp_min'] as num).round(),
        'temp_max': (main['temp_max'] as num).round(),
        'humidity': main['humidity'] as int,
        'pressure': main['pressure'] as int,
        'description': weather['description'] as String,
        'icon': weather['icon'] as String,
        'wind_speed': (wind['speed'] as num).toDouble(),
        'wind_deg': (wind['deg'] as num?)?.toInt() ?? 0,
        'clouds': clouds['all'] as int,
        'sunrise': DateTime.fromMillisecondsSinceEpoch(
          (sys['sunrise'] as int) * 1000,
        ),
        'sunset': DateTime.fromMillisecondsSinceEpoch(
          (sys['sunset'] as int) * 1000,
        ),
        'city_name': data['name'] as String,
        'country': sys['country'] as String,
      };
    } catch (e) {
      throw NetworkException(
        'Erro ao processar dados do clima',
        code: 'parse_error',
        originalError: e,
      );
    }
  }

  static Map<String, dynamic> _parseForecastItem(dynamic item) {
    try {
      final itemMap = item as Map<String, dynamic>;
      final main = itemMap['main'] as Map<String, dynamic>;
      final weather =
          (itemMap['weather'] as List).first as Map<String, dynamic>;
      final wind = itemMap['wind'] as Map<String, dynamic>;
      final clouds = itemMap['clouds'] as Map<String, dynamic>;

      return {
        'dt': DateTime.fromMillisecondsSinceEpoch(
          (itemMap['dt'] as int) * 1000,
        ),
        'temp': (main['temp'] as num).round(),
        'feels_like': (main['feels_like'] as num).round(),
        'temp_min': (main['temp_min'] as num).round(),
        'temp_max': (main['temp_max'] as num).round(),
        'humidity': main['humidity'] as int,
        'description': weather['description'] as String,
        'icon': weather['icon'] as String,
        'wind_speed': (wind['speed'] as num).toDouble(),
        'clouds': clouds['all'] as int,
        'pop': ((itemMap['pop'] as num) * 100)
            .round(), // Probabilidade de chuva em %
      };
    } catch (e) {
      throw NetworkException(
        'Erro ao processar item da previsão',
        code: 'parse_error',
        originalError: e,
      );
    }
  }
}

// Made with Bob
