import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/exceptions/app_exceptions.dart';
import 'http_client_service.dart';

/// Serviço de integração com ExchangeRate API
///
/// Responsabilidades:
/// - Conversão de moedas
/// - Obtenção de taxas de câmbio
/// - Cache de taxas para reduzir requisições
/// - Cálculo de orçamentos multi-moeda
///
/// API: https://www.exchangerate-api.com/
class ExchangeRateService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _cacheKey = 'exchange_rates_cache';
  static const String _cacheTimeKey = 'exchange_rates_cache_time';
  static const int _cacheDurationHours = 24; // Cache por 24 horas

  // Constantes de validação
  static const int _currencyCodeLength = 3;
  static const double _minAmount = 0.0;
  static const double _maxAmount = 999999999.99;

  /// Converte valor entre duas moedas
  ///
  /// Parâmetros:
  /// - [amount]: Valor a ser convertido (deve ser positivo)
  /// - [from]: Código da moeda de origem (3 letras, ex: BRL)
  /// - [to]: Código da moeda de destino (3 letras, ex: USD)
  ///
  /// Retorna: Valor convertido
  ///
  /// Lança:
  /// - [ValidationException]: Se parâmetros forem inválidos
  /// - [NetworkException]: Se houver erro na requisição
  static Future<double> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    _validateAmount(amount);
    _validateCurrencyCode(from, 'origem');
    _validateCurrencyCode(to, 'destino');

    try {
      final rate = await getExchangeRate(from: from, to: to);
      return amount * rate;
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro ao converter moeda',
        code: 'conversion_error',
        originalError: e,
      );
    }
  }

  /// Obtém taxa de câmbio entre duas moedas
  ///
  /// Parâmetros:
  /// - [from]: Código da moeda de origem (3 letras)
  /// - [to]: Código da moeda de destino (3 letras)
  ///
  /// Retorna: Taxa de câmbio
  ///
  /// Lança:
  /// - [ValidationException]: Se códigos de moeda forem inválidos
  /// - [NetworkException]: Se houver erro na requisição
  static Future<double> getExchangeRate({
    required String from,
    required String to,
  }) async {
    _validateCurrencyCode(from, 'origem');
    _validateCurrencyCode(to, 'destino');

    try {
      final rates = await _getRates(from);

      if (!rates.containsKey(to)) {
        throw NetworkException(
          'Moeda de destino não encontrada: $to',
          code: 'currency_not_found',
        );
      }

      return (rates[to] as num).toDouble();
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro ao obter taxa de câmbio',
        code: 'rate_fetch_error',
        originalError: e,
      );
    }
  }

  /// Converte múltiplos valores para uma moeda alvo
  ///
  /// Parâmetros:
  /// - [amounts]: Lista de mapas com 'amount', 'currency' e 'description'
  /// - [targetCurrency]: Código da moeda de destino
  ///
  /// Retorna: Lista de conversões realizadas
  ///
  /// Lança:
  /// - [ValidationException]: Se parâmetros forem inválidos
  /// - [NetworkException]: Se houver erro nas conversões
  static Future<List<Map<String, dynamic>>> convertMultiple({
    required List<Map<String, dynamic>> amounts,
    required String targetCurrency,
  }) async {
    if (amounts.isEmpty) {
      throw ValidationException('Lista de valores não pode estar vazia');
    }

    _validateCurrencyCode(targetCurrency, 'destino');

    final results = <Map<String, dynamic>>[];
    final errors = <String>[];

    for (int i = 0; i < amounts.length; i++) {
      try {
        final item = amounts[i];
        final amount = item['amount'];
        final from = item['currency'];

        if (amount == null || from == null) {
          errors.add('Item $i: campos obrigatórios ausentes');
          continue;
        }

        final amountDouble = (amount as num).toDouble();
        final fromStr = from as String;

        final converted = await convert(
          amount: amountDouble,
          from: fromStr,
          to: targetCurrency,
        );

        results.add({
          'original': amountDouble,
          'originalCurrency': fromStr,
          'converted': converted,
          'targetCurrency': targetCurrency,
          'description': item['description'] ?? '',
        });
      } catch (e) {
        errors.add('Item $i: ${e.toString()}');
      }
    }

    if (results.isEmpty && errors.isNotEmpty) {
      throw NetworkException(
        'Falha ao converter todos os valores: ${errors.join("; ")}',
        code: 'all_conversions_failed',
      );
    }

    return results;
  }

  /// Obtém múltiplas taxas de câmbio de uma vez
  ///
  /// Parâmetros:
  /// - [baseCurrency]: Moeda base
  /// - [targetCurrencies]: Lista de moedas de destino
  ///
  /// Retorna: Mapa com taxas de câmbio
  ///
  /// Lança:
  /// - [ValidationException]: Se parâmetros forem inválidos
  /// - [NetworkException]: Se houver erro na requisição
  static Future<Map<String, double>> getMultipleRates({
    required String baseCurrency,
    required List<String> targetCurrencies,
  }) async {
    _validateCurrencyCode(baseCurrency, 'base');

    if (targetCurrencies.isEmpty) {
      throw ValidationException(
          'Lista de moedas de destino não pode estar vazia');
    }

    for (final currency in targetCurrencies) {
      _validateCurrencyCode(currency, 'destino');
    }

    try {
      final allRates = await _getRates(baseCurrency);
      final rates = <String, double>{};

      for (final currency in targetCurrencies) {
        if (allRates.containsKey(currency)) {
          rates[currency] = (allRates[currency] as num).toDouble();
        }
      }

      return rates;
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro ao obter múltiplas taxas',
        code: 'multiple_rates_error',
        originalError: e,
      );
    }
  }

  /// Formata valor monetário com símbolo da moeda
  ///
  /// Parâmetros:
  /// - [amount]: Valor a ser formatado
  /// - [currency]: Código da moeda
  ///
  /// Retorna: String formatada (ex: "R$ 100.00")
  static String formatCurrency(double amount, String currency) {
    final symbol = getCurrencySymbol(currency);
    return '$symbol ${amount.toStringAsFixed(2)}';
  }

  /// Retorna símbolo da moeda
  ///
  /// Parâmetros:
  /// - [currencyCode]: Código da moeda (3 letras)
  ///
  /// Retorna: Símbolo da moeda ou o próprio código se não encontrado
  static String getCurrencySymbol(String currencyCode) {
    final symbols = {
      'BRL': 'R\$',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'ARS': '\$',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'CHF': 'Fr',
      'CNY': '¥',
      'MXN': '\$',
      'INR': '₹',
      'KRW': '₩',
      'RUB': '₽',
      'ZAR': 'R',
      'TRY': '₺',
      'SEK': 'kr',
      'NOK': 'kr',
      'DKK': 'kr',
      'PLN': 'zł',
    };
    return symbols[currencyCode.toUpperCase()] ?? currencyCode;
  }

  /// Calcula orçamento total convertendo múltiplas despesas para uma moeda
  ///
  /// Parâmetros:
  /// - [expenses]: Lista de despesas com amount, currency e description
  /// - [targetCurrency]: Moeda de destino
  ///
  /// Retorna: Mapa com total, breakdown e formatação
  ///
  /// Lança:
  /// - [ValidationException]: Se parâmetros forem inválidos
  /// - [NetworkException]: Se houver erro nas conversões
  static Future<Map<String, dynamic>> calculateTotalBudget({
    required List<Map<String, dynamic>> expenses,
    required String targetCurrency,
  }) async {
    if (expenses.isEmpty) {
      return {
        'total': 0.0,
        'currency': targetCurrency,
        'breakdown': <Map<String, dynamic>>[],
        'formattedTotal': formatCurrency(0.0, targetCurrency),
      };
    }

    _validateCurrencyCode(targetCurrency, 'destino');

    double total = 0;
    final breakdown = <Map<String, dynamic>>[];
    final errors = <String>[];

    for (int i = 0; i < expenses.length; i++) {
      try {
        final expense = expenses[i];
        final amount = expense['amount'];
        final currency = expense['currency'];

        if (amount == null || currency == null) {
          errors.add('Despesa $i: campos obrigatórios ausentes');
          continue;
        }

        final amountDouble = (amount as num).toDouble();
        final currencyStr = currency as String;

        if (currencyStr.toUpperCase() == targetCurrency.toUpperCase()) {
          total += amountDouble;
          breakdown.add({
            'description': expense['description'] ?? 'Sem descrição',
            'amount': amountDouble,
            'currency': currencyStr,
            'converted': amountDouble,
          });
        } else {
          final converted = await convert(
            amount: amountDouble,
            from: currencyStr,
            to: targetCurrency,
          );

          total += converted;
          breakdown.add({
            'description': expense['description'] ?? 'Sem descrição',
            'amount': amountDouble,
            'currency': currencyStr,
            'converted': converted,
          });
        }
      } catch (e) {
        errors.add('Despesa $i: ${e.toString()}');
      }
    }

    return {
      'total': total,
      'currency': targetCurrency,
      'breakdown': breakdown,
      'formattedTotal': formatCurrency(total, targetCurrency),
      'errors': errors,
    };
  }

  /// Retorna lista de moedas populares
  static List<Map<String, String>> getPopularCurrencies() {
    return [
      {
        'code': 'BRL',
        'name': 'Real Brasileiro',
        'symbol': 'R\$',
        'flag': '🇧🇷'
      },
      {
        'code': 'USD',
        'name': 'Dólar Americano',
        'symbol': '\$',
        'flag': '🇺🇸'
      },
      {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
      {'code': 'GBP', 'name': 'Libra Esterlina', 'symbol': '£', 'flag': '🇬🇧'},
      {'code': 'JPY', 'name': 'Iene Japonês', 'symbol': '¥', 'flag': '🇯🇵'},
      {'code': 'ARS', 'name': 'Peso Argentino', 'symbol': '\$', 'flag': '🇦🇷'},
      {
        'code': 'CAD',
        'name': 'Dólar Canadense',
        'symbol': 'C\$',
        'flag': '🇨🇦'
      },
      {
        'code': 'AUD',
        'name': 'Dólar Australiano',
        'symbol': 'A\$',
        'flag': '🇦🇺'
      },
      {'code': 'CHF', 'name': 'Franco Suíço', 'symbol': 'Fr', 'flag': '🇨🇭'},
      {'code': 'CNY', 'name': 'Yuan Chinês', 'symbol': '¥', 'flag': '🇨🇳'},
      {'code': 'MXN', 'name': 'Peso Mexicano', 'symbol': '\$', 'flag': '🇲🇽'},
    ];
  }

  /// Limpa cache de taxas de câmbio
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cacheKey) || key.startsWith(_cacheTimeKey)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      throw CacheException(
        'Erro ao limpar cache de taxas',
        originalError: e,
      );
    }
  }

  // ========== MÉTODOS PRIVADOS ==========

  /// Valida valor monetário
  static void _validateAmount(double amount) {
    if (amount < _minAmount) {
      throw ValidationException(
        'Valor não pode ser negativo: $amount',
      );
    }

    if (amount > _maxAmount) {
      throw ValidationException(
        'Valor muito grande: $amount. Máximo: $_maxAmount',
      );
    }
  }

  /// Valida código da moeda
  static void _validateCurrencyCode(String code, String context) {
    if (code.trim().isEmpty) {
      throw ValidationException(
          'Código de moeda de $context não pode estar vazio');
    }

    if (code.trim().length != _currencyCodeLength) {
      throw ValidationException(
        'Código de moeda de $context inválido: $code. Deve ter $_currencyCodeLength caracteres',
      );
    }

    // Verificar se contém apenas letras
    if (!RegExp(r'^[A-Za-z]+$').hasMatch(code)) {
      throw ValidationException(
        'Código de moeda de $context deve conter apenas letras: $code',
      );
    }
  }

  /// Obtém todas as taxas de câmbio para uma moeda base
  static Future<Map<String, dynamic>> _getRates(String baseCurrency) async {
    try {
      // Tentar obter do cache primeiro
      final cachedRates = await _getCachedRates(baseCurrency);
      if (cachedRates != null) {
        return cachedRates;
      }

      // Buscar da API
      final url = Uri.parse('$_baseUrl/$baseCurrency');
      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 10),
        useCache: false, // Usa cache próprio do serviço
      );

      if (response == null) {
        throw NetworkException.timeout();
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;

        if (rates == null) {
          throw NetworkException(
            'Taxas de câmbio não retornadas pela API',
            code: 'invalid_response',
          );
        }

        // Salvar no cache
        await _cacheRates(baseCurrency, rates);

        return rates;
      } else if (response.statusCode == 404) {
        throw NetworkException(
          'Moeda não encontrada: $baseCurrency',
          statusCode: 404,
          code: 'currency_not_found',
        );
      } else if (response.statusCode == 429) {
        throw NetworkException.rateLimitExceeded();
      } else {
        throw NetworkException(
          'Erro ao buscar taxas de câmbio: ${response.statusCode}',
          statusCode: response.statusCode,
          code: 'rates_fetch_failed',
        );
      }
    } on NetworkException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Erro inesperado ao buscar taxas',
        code: 'unexpected_error',
        originalError: e,
      );
    }
  }

  /// Salva taxas no cache
  static Future<void> _cacheRates(
    String baseCurrency,
    Map<String, dynamic> rates,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'baseCurrency': baseCurrency,
        'rates': rates,
      };

      await prefs.setString(
        '${_cacheKey}_$baseCurrency',
        json.encode(cacheData),
      );

      await prefs.setInt(
        '${_cacheTimeKey}_$baseCurrency',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Não lançar exceção se falhar ao salvar cache
      // O serviço continua funcionando sem cache
    }
  }

  /// Obtém taxas do cache se ainda válidas
  static Future<Map<String, dynamic>?> _getCachedRates(
    String baseCurrency,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt('${_cacheTimeKey}_$baseCurrency');

      if (cacheTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final hoursSinceCache = (now - cacheTime) / (1000 * 60 * 60);

        if (hoursSinceCache < _cacheDurationHours) {
          final cachedData = prefs.getString('${_cacheKey}_$baseCurrency');

          if (cachedData != null) {
            final data = json.decode(cachedData) as Map<String, dynamic>;
            return data['rates'] as Map<String, dynamic>;
          }
        }
      }

      return null;
    } catch (e) {
      // Se falhar ao ler cache, retorna null para buscar da API
      return null;
    }
  }
}

// Made with Bob
