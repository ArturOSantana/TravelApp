import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // wttr.in é uma API gratuita e simples que não exige chave para consultas básicas
  static Future<Map<String, dynamic>?> getWeather(String city) async {
    try {
      final response = await http.get(
        Uri.parse('https://wttr.in/$city?format=j1'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_condition'][0];
        return {
          'temp': current['temp_C'],
          'desc':
              current['lang_pt']?[0]?['value'] ??
              current['weatherDesc'][0]['value'],
          'icon': _getWeatherIcon(current['weatherCode']),
        };
      }
    } catch (e) {
      print('Erro ao buscar clima: $e');
    }
    return null;
  }

  /// Busca previsão do tempo para os próximos dias
  static Future<WeatherForecast?> getForecast(String city) async {
    try {
      final response = await http.get(
        Uri.parse('https://wttr.in/$city?format=j1'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_condition'][0];
        final weather = data['weather'] as List;

        // Analisa os próximos 3 dias
        int rainDays = 0;
        int coldDays = 0;
        int hotDays = 0;
        double maxTemp = 0;
        double minTemp = 100;

        for (var day in weather.take(3)) {
          final avgTemp = double.parse(day['avgtempC'].toString());
          final maxTempDay = double.parse(day['maxtempC'].toString());
          final minTempDay = double.parse(day['mintempC'].toString());
          final chanceOfRain = int.parse(
            day['hourly'][0]['chanceofrain'].toString(),
          );

          if (chanceOfRain > 40) rainDays++;
          if (avgTemp < 15) coldDays++;
          if (avgTemp > 28) hotDays++;
          if (maxTempDay > maxTemp) maxTemp = maxTempDay;
          if (minTempDay < minTemp) minTemp = minTempDay;
        }

        return WeatherForecast(
          currentTemp: double.parse(current['temp_C'].toString()),
          currentDesc:
              current['lang_pt']?[0]?['value'] ??
              current['weatherDesc'][0]['value'],
          currentIcon: _getWeatherIcon(current['weatherCode']),
          rainDays: rainDays,
          coldDays: coldDays,
          hotDays: hotDays,
          maxTemp: maxTemp,
          minTemp: minTemp,
        );
      }
    } catch (e) {
      print('Erro ao buscar previsão: $e');
    }
    return null;
  }

  /// Gera sugestões de itens para o checklist baseado no clima
  static List<PackingSuggestion> getPackingSuggestions(
    WeatherForecast forecast,
  ) {
    final suggestions = <PackingSuggestion>[];

    // Sugestões para chuva
    if (forecast.rainDays >= 2) {
      suggestions.add(
        PackingSuggestion(
          item: 'Capa de chuva ou guarda-chuva',
          category: 'Acessórios',
          reason:
              'Previsão de chuva em ${forecast.rainDays} dos próximos 3 dias',
          priority: true,
        ),
      );
      suggestions.add(
        PackingSuggestion(
          item: 'Calçado impermeável',
          category: 'Calçados',
          reason: 'Proteção contra chuva',
          priority: true,
        ),
      );
      suggestions.add(
        PackingSuggestion(
          item: 'Saco plástico para eletrônicos',
          category: 'Acessórios',
          reason: 'Proteger dispositivos da umidade',
          priority: false,
        ),
      );
    } else if (forecast.rainDays == 1) {
      suggestions.add(
        PackingSuggestion(
          item: 'Guarda-chuva compacto',
          category: 'Acessórios',
          reason: 'Possibilidade de chuva',
          priority: false,
        ),
      );
    }

    // Sugestões para frio
    if (forecast.coldDays >= 2 || forecast.minTemp < 15) {
      suggestions.add(
        PackingSuggestion(
          item: 'Casaco ou jaqueta',
          category: 'Roupas',
          reason:
              'Temperatura mínima de ${forecast.minTemp.toStringAsFixed(0)}°C',
          priority: true,
        ),
      );
      suggestions.add(
        PackingSuggestion(
          item: 'Calça comprida',
          category: 'Roupas',
          reason: 'Proteção contra o frio',
          priority: true,
        ),
      );
      suggestions.add(
        PackingSuggestion(
          item: 'Meias térmicas',
          category: 'Roupas',
          reason: 'Conforto em temperaturas baixas',
          priority: false,
        ),
      );
    }

    // Sugestões para calor
    if (forecast.hotDays >= 2 || forecast.maxTemp > 28) {
      suggestions.add(
        PackingSuggestion(
          item: 'Protetor solar',
          category: 'Higiene',
          reason:
              'Temperatura máxima de ${forecast.maxTemp.toStringAsFixed(0)}°C',
          priority: true,
        ),
      );
      suggestions.add(
        PackingSuggestion(
          item: 'Boné ou chapéu',
          category: 'Acessórios',
          reason: 'Proteção solar',
          priority: true,
        ),
      );
      suggestions.add(
        PackingSuggestion(
          item: 'Óculos de sol',
          category: 'Acessórios',
          reason: 'Proteção UV',
          priority: false,
        ),
      );
      suggestions.add(
        PackingSuggestion(
          item: 'Roupas leves e frescas',
          category: 'Roupas',
          reason: 'Conforto em altas temperaturas',
          priority: true,
        ),
      );
      suggestions.add(
        PackingSuggestion(
          item: 'Garrafa de água reutilizável',
          category: 'Acessórios',
          reason: 'Hidratação em clima quente',
          priority: false,
        ),
      );
    }

    return suggestions;
  }

  static String _getWeatherIcon(String code) {
    // Mapeamento simples de códigos wttr.in para emojis ou ícones
    int c = int.tryParse(code) ?? 113;
    if (c == 113) return '☀️'; // Ensolarado
    if (c <= 122) return '☁️'; // Nublado
    if (c <= 200) return '🌫️'; // Névoa
    if (c <= 300) return '🌧️'; // Chuva
    return '⛅';
  }
}

class WeatherForecast {
  final double currentTemp;
  final String currentDesc;
  final String currentIcon;
  final int rainDays;
  final int coldDays;
  final int hotDays;
  final double maxTemp;
  final double minTemp;

  WeatherForecast({
    required this.currentTemp,
    required this.currentDesc,
    required this.currentIcon,
    required this.rainDays,
    required this.coldDays,
    required this.hotDays,
    required this.maxTemp,
    required this.minTemp,
  });
}

class PackingSuggestion {
  final String item;
  final String category;
  final String reason;
  final bool priority;

  PackingSuggestion({
    required this.item,
    required this.category,
    required this.reason,
    required this.priority,
  });
}
