import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ExchangeRateService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _cacheKey = 'exchange_rates_cache';
  static const String _cacheTimeKey = 'exchange_rates_cache_time';
  static const int _cacheDurationHours = 24; // Cache por 24 horas

  
  static Future<double?> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    try {
      final rate = await getExchangeRate(from: from, to: to);
      if (rate != null) {
        return amount * rate;
      }
      return null;
    } catch (e) {
      print('Erro ao converter moeda: $e');
      return null;
    }
  }

  // câmbio entre duas moedas
  static Future<double?> getExchangeRate({
    required String from,
    required String to,
  }) async {
    try {
      final rates = await _getRates(from);
      if (rates != null && rates.containsKey(to)) {
        return (rates[to] as num).toDouble();
      }
      return null;
    } catch (e) {
      print('Erro ao obter taxa de câmbio: $e');
      return null;
    }
  }

  /// Obtém todas as taxas de câmbio 
  static Future<Map<String, dynamic>?> _getRates(String baseCurrency) async {
    try {
      final cachedRates = await _getCachedRates(baseCurrency);
      if (cachedRates != null) {
        return cachedRates;
      }

      final url = Uri.parse('$_baseUrl/$baseCurrency');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        await _cacheRates(baseCurrency, rates);

        return rates;
      }
      return null;
    } catch (e) {
      print('Erro ao buscar taxas: $e');
      return null;
    }
  }

  ///  múltiplos de uma vez
  static Future<List<Map<String, dynamic>>> convertMultiple({
    required List<Map<String, dynamic>> amounts,
    required String targetCurrency,
  }) async {
    final results = <Map<String, dynamic>>[];

    for (final item in amounts) {
      final amount = item['amount'] as double;
      final from = item['currency'] as String;

      final converted = await convert(
        amount: amount,
        from: from,
        to: targetCurrency,
      );

      results.add({
        'original': amount,
        'originalCurrency': from,
        'converted': converted,
        'targetCurrency': targetCurrency,
        'description': item['description'] ?? '',
      });
    }

    return results;
  }


  static Future<Map<String, double>> getMultipleRates({
    required String baseCurrency,
    required List<String> targetCurrencies,
  }) async {
    final rates = <String, double>{};

    for (final currency in targetCurrencies) {
      final rate = await getExchangeRate(from: baseCurrency, to: currency);
      if (rate != null) {
        rates[currency] = rate;
      }
    }

    return rates;
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
    };
    return symbols[currencyCode] ?? currencyCode;
  }

  static Future<void> _cacheRates(
      String baseCurrency, Map<String, dynamic> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'baseCurrency': baseCurrency,
        'rates': rates,
      };
      await prefs.setString(
          '$_cacheKey\_$baseCurrency', json.encode(cacheData));
      await prefs.setInt('$_cacheTimeKey\_$baseCurrency',
          DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Erro ao salvar cache: $e');
    }
  }

  static Future<Map<String, dynamic>?> _getCachedRates(
      String baseCurrency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt('$_cacheTimeKey\_$baseCurrency');

      if (cacheTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final hoursSinceCache = (now - cacheTime) / (1000 * 60 * 60);

        if (hoursSinceCache < _cacheDurationHours) {
          final cachedData = prefs.getString('$_cacheKey\_$baseCurrency');
          if (cachedData != null) {
            final data = json.decode(cachedData);
            return data['rates'] as Map<String, dynamic>;
          }
        }
      }
      return null;
    } catch (e) {
      print('Erro ao ler cache: $e');
      return null;
    }
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
      print('Erro ao limpar cache: $e');
    }
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

  /// Calcula orçamento total em moeda local
  ///
  /// [expenses] Lista de despesas em diferentes moedas
  /// [targetCurrency] Moeda de destino
  static Future<Map<String, dynamic>> calculateTotalBudget({
    required List<Map<String, dynamic>> expenses,
    required String targetCurrency,
  }) async {
    double total = 0;
    final breakdown = <Map<String, dynamic>>[];

    for (final expense in expenses) {
      final amount = expense['amount'] as double;
      final currency = expense['currency'] as String;

      if (currency == targetCurrency) {
        total += amount;
        breakdown.add({
          'description': expense['description'],
          'amount': amount,
          'currency': currency,
          'converted': amount,
        });
      } else {
        final converted = await convert(
          amount: amount,
          from: currency,
          to: targetCurrency,
        );

        if (converted != null) {
          total += converted;
          breakdown.add({
            'description': expense['description'],
            'amount': amount,
            'currency': currency,
            'converted': converted,
          });
        }
      }
    }

    return {
      'total': total,
      'currency': targetCurrency,
      'breakdown': breakdown,
      'formattedTotal': formatCurrency(total, targetCurrency),
    };
  }
}

