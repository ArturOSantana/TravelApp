import 'dart:convert';
import 'package:http/http.dart' as http;


class RestCountriesService {
  static const String _baseUrl = 'https://restcountries.com/v3.1';

 
  static Future<Map<String, dynamic>?> getCountryInfo(
      String countryName) async {
    try {
      final url = Uri.parse('$_baseUrl/name/$countryName');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) return null;

        final country = data[0];
        final currencies = country['currencies'] as Map<String, dynamic>?;
        final languages = country['languages'] as Map<String, dynamic>?;
        final timezones = country['timezones'] as List<dynamic>?;

        String? currencyCode;
        String? currencyName;
        String? currencySymbol;
        if (currencies != null && currencies.isNotEmpty) {
          final firstCurrency = currencies.values.first;
          currencyCode = currencies.keys.first;
          currencyName = firstCurrency['name'];
          currencySymbol = firstCurrency['symbol'];
        }

        String? language;
        if (languages != null && languages.isNotEmpty) {
          language = languages.values.first;
        }

        return {
          'name': country['name']['common'] ?? '',
          'officialName': country['name']['official'] ?? '',
          'capital': (country['capital'] as List?)?.first ?? '',
          'region': country['region'] ?? '',
          'subregion': country['subregion'] ?? '',
          'population': country['population'] ?? 0,
          'area': country['area'] ?? 0,
          'flag': country['flags']['png'] ?? '',
          'flagEmoji': country['flag'] ?? '',
          'currencyCode': currencyCode ?? '',
          'currencyName': currencyName ?? '',
          'currencySymbol': currencySymbol ?? '',
          'language': language ?? '',
          'timezone': timezones?.first ?? '',
          'timezones': timezones ?? [],
          'continent': country['continents']?.first ?? '',
          'callingCode': country['idd']?['root'] ?? '',
          'tld': (country['tld'] as List?)?.first ?? '',
          'independent': country['independent'] ?? false,
          'landlocked': country['landlocked'] ?? false,
          'borders': country['borders'] ?? [],
          'maps': country['maps']?['googleMaps'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Erro ao buscar informações do país: $e');
      return null;
    }
  }


  static Future<Map<String, dynamic>?> getCountryByCapital(
      String capital) async {
    try {
      final url = Uri.parse('$_baseUrl/capital/$capital');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) return null;
        return _parseCountryData(data[0]);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar país pela capital: $e');
      return null;
    }
  }

  
  static Future<List<Map<String, dynamic>>> getCountriesByRegion(
      String region) async {
    try {
      final url = Uri.parse('$_baseUrl/region/$region');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((country) => _parseCountryData(country)).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar países por região: $e');
      return [];
    }
  }


  static Future<List<Map<String, dynamic>>> getBorderingCountries(
      String countryCode) async {
    try {
      final url = Uri.parse('$_baseUrl/alpha/$countryCode');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) return [];

        final borders = data[0]['borders'] as List<dynamic>?;
        if (borders == null || borders.isEmpty) return [];

        final borderCountries = <Map<String, dynamic>>[];
        for (final borderCode in borders) {
          final borderUrl = Uri.parse('$_baseUrl/alpha/$borderCode');
          final borderResponse = await http.get(borderUrl);

          if (borderResponse.statusCode == 200) {
            final borderData = json.decode(borderResponse.body);
            if (borderData.isNotEmpty) {
              borderCountries.add(_parseCountryData(borderData[0]));
            }
          }
        }
        return borderCountries;
      }
      return [];
    } catch (e) {
      print('Erro ao buscar países vizinhos: $e');
      return [];
    }
  }

  
  static String extractCountryFromAddress(String address) {
    final parts = address.split(',');
    if (parts.length >= 2) {
      return parts.last.trim();
    }
    return address.trim();
  }

 
  static String extractCityFromAddress(String address) {
    final parts = address.split(',');
    return parts.first.trim();
  }

  static Map<String, dynamic> _parseCountryData(Map<String, dynamic> country) {
    final currencies = country['currencies'] as Map<String, dynamic>?;
    final languages = country['languages'] as Map<String, dynamic>?;

    String? currencyCode;
    String? currencySymbol;
    if (currencies != null && currencies.isNotEmpty) {
      currencyCode = currencies.keys.first;
      currencySymbol = currencies.values.first['symbol'];
    }

    String? language;
    if (languages != null && languages.isNotEmpty) {
      language = languages.values.first;
    }

    return {
      'name': country['name']['common'] ?? '',
      'capital': (country['capital'] as List?)?.first ?? '',
      'flag': country['flags']['png'] ?? '',
      'flagEmoji': country['flag'] ?? '',
      'currencyCode': currencyCode ?? '',
      'currencySymbol': currencySymbol ?? '',
      'language': language ?? '',
      'timezone': (country['timezones'] as List?)?.first ?? '',
      'population': country['population'] ?? 0,
    };
  }


  static List<String> getTravelTips(Map<String, dynamic> countryInfo) {
    final tips = <String>[];

    if (countryInfo['currencyCode'] != null &&
        countryInfo['currencyCode'].isNotEmpty) {
      tips.add(
          '💰 Moeda local: ${countryInfo['currencyName']} (${countryInfo['currencySymbol']})');
    }

    if (countryInfo['language'] != null && countryInfo['language'].isNotEmpty) {
      tips.add('🗣️ Idioma: ${countryInfo['language']}');
    }

  
    if (countryInfo['timezone'] != null && countryInfo['timezone'].isNotEmpty) {
      tips.add('🕐 Fuso horário: ${countryInfo['timezone']}');
    }

    final population = countryInfo['population'] as int?;
    if (population != null && population > 0) {
      final popStr = population > 1000000
          ? '${(population / 1000000).toStringAsFixed(1)}M'
          : '${(population / 1000).toStringAsFixed(0)}K';
      tips.add('👥 População: $popStr habitantes');
    }

    // Região
    if (countryInfo['region'] != null) {
      tips.add('🌍 Região: ${countryInfo['region']}');
    }

    return tips;
  }

  static List<Map<String, String>> getAvailableRegions() {
    return [
      {'id': 'africa', 'name': 'África', 'icon': '🌍'},
      {'id': 'americas', 'name': 'Américas', 'icon': '🌎'},
      {'id': 'asia', 'name': 'Ásia', 'icon': '🌏'},
      {'id': 'europe', 'name': 'Europa', 'icon': '🇪🇺'},
      {'id': 'oceania', 'name': 'Oceania', 'icon': '🏝️'},
    ];
  }
}

