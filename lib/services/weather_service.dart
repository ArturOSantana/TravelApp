import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // wttr.in é uma API gratuita e simples que não exige chave para consultas básicas
  static Future<Map<String, dynamic>?> getWeather(String city) async {
    try {
      final response = await http.get(Uri.parse('https://wttr.in/$city?format=j1'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_condition'][0];
        return {
          'temp': current['temp_C'],
          'desc': current['lang_pt']?[0]?['value'] ?? current['weatherDesc'][0]['value'],
          'icon': _getWeatherIcon(current['weatherCode']),
        };
      }
    } catch (e) {
      print('Erro ao buscar clima: $e');
    }
    return null;
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
