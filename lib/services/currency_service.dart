import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  // Usando AwesomeAPI (Gratuita e sem chave para testes)
  static const String _baseUrl = 'https://economia.awesomeapi.com.br/json/last/';

  static Future<double> getExchangeRate(String from, String to) async {
    if (from == to) return 1.0;
    
    try {
      final response = await http.get(Uri.parse('$_baseUrl$from-$to'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return double.parse(data['$from$to']['bid']);
      }
    } catch (e) {
      print('Erro ao buscar câmbio: $e');
    }
    return 1.0; // Fallback
  }
}
