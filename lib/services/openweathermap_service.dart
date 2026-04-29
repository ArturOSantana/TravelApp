import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class OpenWeatherMapService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

 
  static Future<Map<String, dynamic>?> getCurrentWeather(String city) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?q=$city&appid=${ApiKeys.openWeatherMap}&units=metric&lang=pt_br',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return {
          'temp': data['main']['temp'].round(),
          'feels_like': data['main']['feels_like'].round(),
          'temp_min': data['main']['temp_min'].round(),
          'temp_max': data['main']['temp_max'].round(),
          'humidity': data['main']['humidity'],
          'pressure': data['main']['pressure'],
          'description': data['weather'][0]['description'],
          'icon': data['weather'][0]['icon'],
          'wind_speed': data['wind']['speed'],
          'wind_deg': data['wind']['deg'],
          'clouds': data['clouds']['all'],
          'sunrise': DateTime.fromMillisecondsSinceEpoch(
            data['sys']['sunrise'] * 1000,
          ),
          'sunset': DateTime.fromMillisecondsSinceEpoch(
            data['sys']['sunset'] * 1000,
          ),
          'city_name': data['name'],
          'country': data['sys']['country'],
        };
      } else {
        print('Erro OpenWeatherMap: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro ao buscar clima atual: $e');
      return null;
    }
  }

  
  static Future<List<Map<String, dynamic>>?> getForecast(String city) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?q=$city&appid=${ApiKeys.openWeatherMap}&units=metric&lang=pt_br',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['list'];

        return list.map((item) {
          return {
            'dt': DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
            'temp': item['main']['temp'].round(),
            'feels_like': item['main']['feels_like'].round(),
            'temp_min': item['main']['temp_min'].round(),
            'temp_max': item['main']['temp_max'].round(),
            'humidity': item['main']['humidity'],
            'description': item['weather'][0]['description'],
            'icon': item['weather'][0]['icon'],
            'wind_speed': item['wind']['speed'],
            'clouds': item['clouds']['all'],
            'pop': (item['pop'] * 100).round(), 
          };
        }).toList();
      } else {
        print('Erro OpenWeatherMap Forecast: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro ao buscar previsão: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentWeatherByCoords(
    double lat,
    double lon,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=${ApiKeys.openWeatherMap}&units=metric&lang=pt_br',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return {
          'temp': data['main']['temp'].round(),
          'feels_like': data['main']['feels_like'].round(),
          'temp_min': data['main']['temp_min'].round(),
          'temp_max': data['main']['temp_max'].round(),
          'humidity': data['main']['humidity'],
          'pressure': data['main']['pressure'],
          'description': data['weather'][0]['description'],
          'icon': data['weather'][0]['icon'],
          'wind_speed': data['wind']['speed'],
          'wind_deg': data['wind']['deg'],
          'clouds': data['clouds']['all'],
          'sunrise': DateTime.fromMillisecondsSinceEpoch(
            data['sys']['sunrise'] * 1000,
          ),
          'sunset': DateTime.fromMillisecondsSinceEpoch(
            data['sys']['sunset'] * 1000,
          ),
          'city_name': data['name'],
          'country': data['sys']['country'],
        };
      } else {
        print('Erro OpenWeatherMap Coords: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro ao buscar clima por coordenadas: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getForecastByCoords(
    double lat,
    double lon,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=${ApiKeys.openWeatherMap}&units=metric&lang=pt_br',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['list'];

        return list.map((item) {
          return {
            'dt': DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
            'temp': item['main']['temp'].round(),
            'feels_like': item['main']['feels_like'].round(),
            'temp_min': item['main']['temp_min'].round(),
            'temp_max': item['main']['temp_max'].round(),
            'humidity': item['main']['humidity'],
            'description': item['weather'][0]['description'],
            'icon': item['weather'][0]['icon'],
            'wind_speed': item['wind']['speed'],
            'clouds': item['clouds']['all'],
            'pop': (item['pop'] * 100).round(), // Probabilidade de chuva em %
          };
        }).toList();
      } else {
        print('Erro OpenWeatherMap Forecast Coords: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro ao buscar previsão por coordenadas: $e');
      return null;
    }
  }

  
  static String getIconUrl(String iconCode) {
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

  /// Retorna descrição da direção do vento
  static String getWindDirection(int degrees) {
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

  /// Agrupa previsões por dia (pega a média do dia)
  static List<Map<String, dynamic>> groupForecastByDay(
    List<Map<String, dynamic>> forecast,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in forecast) {
      final date = item['dt'] as DateTime;
      final dateKey = '${date.year}-${date.month}-${date.day}';

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
}


