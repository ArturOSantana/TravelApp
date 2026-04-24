import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class GoogleMapsService {
  // Getter para garantir que pegamos a chave atualizada do dotenv
  String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  Future<List<dynamic>> getAutocomplete(String input) async {
    if (_apiKey.isEmpty || _apiKey == 'SUA_CHAVE_AQUI') {
      debugPrint('ERRO: Google Maps API Key não configurada no .env');
      return [];
    }

    if (input.isEmpty) return [];

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&types=(cities)&key=$_apiKey&language=pt-BR');

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        return data['predictions'] ?? [];
      } else {
        debugPrint('Google Places API Error: ${data['status']} - ${data['error_message'] ?? 'Sem mensagem'}');
      }
    } catch (e) {
      debugPrint('Erro na requisição Autocomplete: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (_apiKey.isEmpty) return null;

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry,photos&key=$_apiKey&language=pt-BR');

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        debugPrint('Google Place Details Error: ${data['status']}');
      }
    } catch (e) {
      debugPrint('Erro ao buscar detalhes: $e');
    }
    return null;
  }

  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=$maxWidth&photo_reference=$photoReference&key=$_apiKey';
  }
}
