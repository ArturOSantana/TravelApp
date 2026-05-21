import 'dart:convert';
import '../core/exceptions/app_exceptions.dart';
import 'http_client_service.dart';


class RestCountriesService {
  static const String _baseUrl = 'https://restcountries.com/v3.1';

  // Constantes de validação
  static const int _minCountryNameLength = 2;
  static const int _minCapitalNameLength = 2;
  static const List<String> _validRegions = [
    'africa',
    'americas',
    'asia',
    'europe',
    'oceania',
  ];

  /// Busca informações detalhadas de um país por nome
  ///
  /// Parâmetros:
  /// - [countryName]: Nome do país (mínimo 2 caracteres)
  ///
  /// Retorna: Mapa com informações do país
  ///
  /// Lança:
  /// - [ValidationException]: Se nome do país for inválido
  /// - [NetworkException]: Se houver erro na requisição
  static Future<Map<String, dynamic>> getCountryInfo(String countryName) async {
    _validateCountryName(countryName);

    try {
      final url = Uri.parse('$_baseUrl/name/$countryName');
      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 8),
        cacheDuration: const Duration(days: 7),
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isEmpty) {
          throw NetworkException(
            'País não encontrado: $countryName',
            statusCode: 404,
            code: 'country_not_found',
          );
        }

        return _parseDetailedCountryData(data[0]);
      } else if (response.statusCode == 404) {
        throw NetworkException(
          'País não encontrado: $countryName',
          statusCode: 404,
          code: 'country_not_found',
        );
      } else if (response.statusCode == 429) {
        throw NetworkException.rateLimitExceeded();
      } else {
        throw NetworkException(
          'Erro ao buscar informações do país: ${response.statusCode}',
          statusCode: response.statusCode,
          code: 'country_fetch_failed',
        );
      }
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao buscar informações do país',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  /// Busca país por nome da capital
  ///
  /// Parâmetros:
  /// - [capital]: Nome da capital (mínimo 2 caracteres)
  ///
  /// Retorna: Mapa com informações do país
  ///
  /// Lança:
  /// - [ValidationException]: Se nome da capital for inválido
  /// - [NetworkException]: Se houver erro na requisição
  static Future<Map<String, dynamic>> getCountryByCapital(
      String capital) async {
    _validateCapitalName(capital);

    try {
      final url = Uri.parse('$_baseUrl/capital/$capital');
      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 8),
        cacheDuration: const Duration(days: 7),
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isEmpty) {
          throw NetworkException(
            'Capital não encontrada: $capital',
            statusCode: 404,
            code: 'capital_not_found',
          );
        }

        return _parseCountryData(data[0]);
      } else if (response.statusCode == 404) {
        throw NetworkException(
          'Capital não encontrada: $capital',
          statusCode: 404,
          code: 'capital_not_found',
        );
      } else if (response.statusCode == 429) {
        throw NetworkException.rateLimitExceeded();
      } else {
        throw NetworkException(
          'Erro ao buscar país pela capital: ${response.statusCode}',
          statusCode: response.statusCode,
          code: 'capital_search_failed',
        );
      }
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao buscar país pela capital',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  /// Busca todos os países de uma região
  ///
  /// Parâmetros:
  /// - [region]: Nome da região (africa, americas, asia, europe, oceania)
  ///
  /// Retorna: Lista de países da região
  ///
  /// Lança:
  /// - [ValidationException]: Se região for inválida
  /// - [NetworkException]: Se houver erro na requisição
  static Future<List<Map<String, dynamic>>> getCountriesByRegion(
    String region,
  ) async {
    _validateRegion(region);

    try {
      final url = Uri.parse('$_baseUrl/region/$region');
      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 10),
        cacheDuration: const Duration(days: 7),
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isEmpty) {
          return [];
        }

        return data.map((country) => _parseCountryData(country)).toList();
      } else if (response.statusCode == 404) {
        throw NetworkException(
          'Região não encontrada: $region',
          statusCode: 404,
          code: 'region_not_found',
        );
      } else if (response.statusCode == 429) {
        throw NetworkException.rateLimitExceeded();
      } else {
        throw NetworkException(
          'Erro ao buscar países por região: ${response.statusCode}',
          statusCode: response.statusCode,
          code: 'region_search_failed',
        );
      }
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao buscar países por região',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  /// Busca países que fazem fronteira com um país específico
  ///
  /// Parâmetros:
  /// - [countryCode]: Código ISO do país (ex: BRA, USA, FRA)
  ///
  /// Retorna: Lista de países vizinhos
  ///
  /// Lança:
  /// - [ValidationException]: Se código do país for inválido
  /// - [NetworkException]: Se houver erro na requisição
  static Future<List<Map<String, dynamic>>> getBorderingCountries(
    String countryCode,
  ) async {
    _validateCountryCode(countryCode);

    try {
      final url = Uri.parse('$_baseUrl/alpha/$countryCode');
      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 8),
        cacheDuration: const Duration(days: 7),
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isEmpty) {
          throw NetworkException(
            'País não encontrado: $countryCode',
            statusCode: 404,
            code: 'country_not_found',
          );
        }

        final borders = data[0]['borders'] as List<dynamic>?;

        if (borders == null || borders.isEmpty) {
          return []; // País não tem fronteiras (ilha, por exemplo)
        }

        final borderCountries = <Map<String, dynamic>>[];

        for (final borderCode in borders) {
          try {
            final borderUrl = Uri.parse('$_baseUrl/alpha/$borderCode');
            final borderResponse = await HttpClientService.get(
              borderUrl,
              timeout: const Duration(seconds: 8),
              cacheDuration: const Duration(days: 7),
            );

            if (borderResponse != null && borderResponse.statusCode == 200) {
              final borderData = json.decode(borderResponse.body) as List;
              if (borderData.isNotEmpty) {
                borderCountries.add(_parseCountryData(borderData[0]));
              }
            }
          } catch (e) {
            // Continua mesmo se falhar para um país específico
            continue;
          }
        }

        return borderCountries;
      } else if (response.statusCode == 404) {
        throw NetworkException(
          'País não encontrado: $countryCode',
          statusCode: 404,
          code: 'country_not_found',
        );
      } else if (response.statusCode == 429) {
        throw NetworkException.rateLimitExceeded();
      } else {
        throw NetworkException(
          'Erro ao buscar países vizinhos: ${response.statusCode}',
          statusCode: response.statusCode,
          code: 'borders_fetch_failed',
        );
      }
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao buscar países vizinhos',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  /// Extrai nome do país de um endereço completo
  ///
  /// Parâmetros:
  /// - [address]: Endereço completo
  ///
  /// Retorna: Nome do país extraído
  static String extractCountryFromAddress(String address) {
    if (address.trim().isEmpty) {
      return '';
    }

    final parts = address.split(',');
    if (parts.length >= 2) {
      return parts.last.trim();
    }
    return address.trim();
  }

  /// Extrai nome da cidade de um endereço completo
  ///
  /// Parâmetros:
  /// - [address]: Endereço completo
  ///
  /// Retorna: Nome da cidade extraída
  static String extractCityFromAddress(String address) {
    if (address.trim().isEmpty) {
      return '';
    }

    final parts = address.split(',');
    return parts.first.trim();
  }

  /// Gera dicas de viagem baseadas nas informações do país
  ///
  /// Parâmetros:
  /// - [countryInfo]: Mapa com informações do país
  ///
  /// Retorna: Lista de dicas formatadas
  static List<String> getTravelTips(Map<String, dynamic> countryInfo) {
    final tips = <String>[];

    // Moeda
    final currencyCode = countryInfo['currencyCode'] as String?;
    final currencyName = countryInfo['currencyName'] as String?;
    final currencySymbol = countryInfo['currencySymbol'] as String?;

    if (currencyCode != null && currencyCode.isNotEmpty) {
      tips.add('💰 Moeda local: $currencyName ($currencySymbol)');
    }

    // Idioma
    final language = countryInfo['language'] as String?;
    if (language != null && language.isNotEmpty) {
      tips.add('🗣️ Idioma: $language');
    }

    // Fuso horário
    final timezone = countryInfo['timezone'] as String?;
    if (timezone != null && timezone.isNotEmpty) {
      tips.add('🕐 Fuso horário: $timezone');
    }

    // População
    final population = countryInfo['population'] as int?;
    if (population != null && population > 0) {
      final popStr = population > 1000000
          ? '${(population / 1000000).toStringAsFixed(1)}M'
          : '${(population / 1000).toStringAsFixed(0)}K';
      tips.add('👥 População: $popStr habitantes');
    }

    // Região
    final region = countryInfo['region'] as String?;
    if (region != null && region.isNotEmpty) {
      tips.add('🌍 Região: $region');
    }

    // Área
    final area = countryInfo['area'] as num?;
    if (area != null && area > 0) {
      tips.add('📏 Área: ${area.toStringAsFixed(0)} km²');
    }

    return tips;
  }

  /// Retorna lista de regiões disponíveis
  static List<Map<String, String>> getAvailableRegions() {
    return [
      {'id': 'africa', 'name': 'África', 'icon': '🌍'},
      {'id': 'americas', 'name': 'Américas', 'icon': '🌎'},
      {'id': 'asia', 'name': 'Ásia', 'icon': '🌏'},
      {'id': 'europe', 'name': 'Europa', 'icon': '🇪🇺'},
      {'id': 'oceania', 'name': 'Oceania', 'icon': '🏝️'},
    ];
  }

  static void _validateCountryName(String countryName) {
    if (countryName.trim().isEmpty) {
      throw ValidationException('Nome do país não pode estar vazio');
    }

    if (countryName.trim().length < _minCountryNameLength) {
      throw ValidationException(
        'Nome do país deve ter pelo menos $_minCountryNameLength caracteres',
      );
    }
  }

  /// Valida nome da capital
  static void _validateCapitalName(String capital) {
    if (capital.trim().isEmpty) {
      throw ValidationException('Nome da capital não pode estar vazio');
    }

    if (capital.trim().length < _minCapitalNameLength) {
      throw ValidationException(
        'Nome da capital deve ter pelo menos $_minCapitalNameLength caracteres',
      );
    }
  }

  /// Valida região
  static void _validateRegion(String region) {
    final regionLower = region.trim().toLowerCase();

    if (regionLower.isEmpty) {
      throw ValidationException('Região não pode estar vazia');
    }

    if (!_validRegions.contains(regionLower)) {
      throw ValidationException(
        'Região inválida: $region. Regiões válidas: ${_validRegions.join(", ")}',
      );
    }
  }

  /// Valida código do país
  static void _validateCountryCode(String countryCode) {
    if (countryCode.trim().isEmpty) {
      throw ValidationException('Código do país não pode estar vazio');
    }

    // Códigos ISO são geralmente 2 ou 3 caracteres
    if (countryCode.trim().length < 2 || countryCode.trim().length > 3) {
      throw ValidationException(
        'Código do país inválido: $countryCode. Deve ter 2 ou 3 caracteres',
      );
    }
  }

  /// Processa dados detalhados do país
  static Map<String, dynamic> _parseDetailedCountryData(
    Map<String, dynamic> country,
  ) {
    try {
      final currencies = country['currencies'] as Map<String, dynamic>?;
      final languages = country['languages'] as Map<String, dynamic>?;
      final timezones = country['timezones'] as List<dynamic>?;

      String? currencyCode;
      String? currencyName;
      String? currencySymbol;
      if (currencies != null && currencies.isNotEmpty) {
        final firstCurrency = currencies.values.first as Map<String, dynamic>;
        currencyCode = currencies.keys.first;
        currencyName = firstCurrency['name'] as String?;
        currencySymbol = firstCurrency['symbol'] as String?;
      }

      String? language;
      if (languages != null && languages.isNotEmpty) {
        language = languages.values.first as String;
      }

      return {
        'name': country['name']['common'] ?? '',
        'officialName': country['name']['official'] ?? '',
        'capital': (country['capital'] as List?)?.first ?? '',
        'region': country['region'] ?? '',
        'subregion': country['subregion'] ?? '',
        'population': (country['population'] as num?)?.toInt() ?? 0,
        'area': (country['area'] as num?)?.toDouble() ?? 0.0,
        'flag': country['flags']['png'] ?? '',
        'flagEmoji': country['flag'] ?? '',
        'currencyCode': currencyCode ?? '',
        'currencyName': currencyName ?? '',
        'currencySymbol': currencySymbol ?? '',
        'language': language ?? '',
        'timezone': timezones?.first ?? '',
        'timezones': timezones ?? [],
        'continent': (country['continents'] as List?)?.first ?? '',
        'callingCode': country['idd']?['root'] ?? '',
        'tld': (country['tld'] as List?)?.first ?? '',
        'independent': country['independent'] ?? false,
        'landlocked': country['landlocked'] ?? false,
        'borders': country['borders'] ?? [],
        'maps': country['maps']?['googleMaps'] ?? '',
      };
    } catch (e) {
      throw NetworkException(
        'Erro ao processar dados do país',
        code: 'parse_error',
        originalError: e,
      );
    }
  }

  /// Processa dados básicos do país
  static Map<String, dynamic> _parseCountryData(Map<String, dynamic> country) {
    try {
      final currencies = country['currencies'] as Map<String, dynamic>?;
      final languages = country['languages'] as Map<String, dynamic>?;

      String? currencyCode;
      String? currencySymbol;
      if (currencies != null && currencies.isNotEmpty) {
        currencyCode = currencies.keys.first;
        final currencyData = currencies.values.first as Map<String, dynamic>;
        currencySymbol = currencyData['symbol'] as String?;
      }

      String? language;
      if (languages != null && languages.isNotEmpty) {
        language = languages.values.first as String;
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
        'population': (country['population'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      throw NetworkException(
        'Erro ao processar dados do país',
        code: 'parse_error',
        originalError: e,
      );
    }
  }
}

// Made with Bob
