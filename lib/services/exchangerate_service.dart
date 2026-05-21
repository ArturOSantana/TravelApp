import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/exceptions/app_exceptions.dart';
import 'http_client_service.dart';

class ExchangeRateService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _cacheKey = 'exchange_rates_cache';
  static const String _cacheTimeKey = 'exchange_rates_cache_time';
  static const int _cacheDurationHours = 24;

  static const int _currencyCodeLength = 3;
  static const double _minAmount = 0.0;
  static const double _maxAmount = 999999999.99;

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

  static String formatCurrency(double amount, String currency) {
    final symbol = getCurrencySymbol(currency);
    return '$symbol ${amount.toStringAsFixed(2)}';
  }

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

    if (!RegExp(r'^[A-Za-z]+$').hasMatch(code)) {
      throw ValidationException(
        'Código de moeda de $context deve conter apenas letras: $code',
      );
    }
  }

  static Future<Map<String, dynamic>> _getRates(String baseCurrency) async {
    try {
      final cachedRates = await _getCachedRates(baseCurrency);
      if (cachedRates != null) {
        return cachedRates;
      }

      final url = Uri.parse('$_baseUrl/$baseCurrency');
      final response = await HttpClientService.get(
        url,
        timeout: const Duration(seconds: 10),
        useCache: false,
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
    } catch (e) {}
  }

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
      return null;
    }
  }
}
