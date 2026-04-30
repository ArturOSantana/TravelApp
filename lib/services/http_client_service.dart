import 'dart:async';
import 'package:http/http.dart' as http;
import 'cache_service.dart';

class HttpClientService {
  static const Duration _defaultTimeout = Duration(seconds: 10);
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 1);

  static Future<http.Response?> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    bool useCache = true,
    Duration? cacheDuration,
  }) async {
    if (useCache) {
      final cached = _getCachedResponse(url.toString());
      if (cached != null) {
        print('[HTTP] Cache hit: ${url.toString()}');
        return cached;
      }
    }

    int attempts = 0;
    Exception? lastException;

    while (attempts < _maxRetries) {
      try {
        print(
            '[HTTP] Tentativa ${attempts + 1}/$_maxRetries: ${url.toString()}');

        final response = await http
            .get(url, headers: headers)
            .timeout(timeout ?? _defaultTimeout);

        if (response.statusCode == 200) {
          if (useCache) {
            _cacheResponse(
              url.toString(),
              response,
              cacheDuration ?? const Duration(hours: 1),
            );
          }
          return response;
        } else if (response.statusCode >= 500) {
          lastException = Exception('Server error: ${response.statusCode}');
          attempts++;
          if (attempts < _maxRetries) {
            await Future.delayed(_retryDelay);
          }
        } else {
          print('[HTTP] Client error: ${response.statusCode}');
          return response;
        }
      } on TimeoutException catch (e) {
        print('[HTTP] Timeout na tentativa ${attempts + 1}');
        lastException = e;
        attempts++;
        if (attempts < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      } catch (e) {
        print('[HTTP] Erro na tentativa ${attempts + 1}: $e');
        lastException = e as Exception;
        attempts++;
        if (attempts < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      }
    }

    print('[HTTP] Falha após $_maxRetries tentativas: ${url.toString()}');

    if (useCache) {
      final oldCache = _getCachedResponse(url.toString(), ignoreExpiry: true);
      if (oldCache != null) {
        print('[HTTP] Usando cache expirado como fallback');
        return oldCache;
      }
    }

    throw lastException ?? Exception('Failed to fetch data');
  }

  static Future<http.Response?> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < _maxRetries) {
      try {
        print(
            '[HTTP] POST tentativa ${attempts + 1}/$_maxRetries: ${url.toString()}');

        final response = await http
            .post(url, headers: headers, body: body)
            .timeout(timeout ?? _defaultTimeout);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return response;
        } else if (response.statusCode >= 500) {
          lastException = Exception('Server error: ${response.statusCode}');
          attempts++;
          if (attempts < _maxRetries) {
            await Future.delayed(_retryDelay);
          }
        } else {
          return response;
        }
      } on TimeoutException catch (e) {
        print('[HTTP] POST timeout na tentativa ${attempts + 1}');
        lastException = e;
        attempts++;
        if (attempts < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      } catch (e) {
        print('[HTTP] POST erro na tentativa ${attempts + 1}: $e');
        lastException = e as Exception;
        attempts++;
        if (attempts < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      }
    }

    throw lastException ?? Exception('Failed to post data');
  }

  static void _cacheResponse(
    String url,
    http.Response response,
    Duration duration,
  ) {
    try {
      final cacheData = {
        'statusCode': response.statusCode,
        'body': response.body,
        'headers': response.headers,
      };
      CacheService.saveData(
        'http_cache_$url',
        cacheData,
        expiration: duration,
      );
    } catch (e) {
      print('[HTTP] Erro ao salvar cache: $e');
    }
  }

  static http.Response? _getCachedResponse(
    String url, {
    bool ignoreExpiry = false,
  }) {
    try {
      final cacheKey = 'http_cache_$url';

      if (ignoreExpiry) {
        final prefs = CacheService.getData(cacheKey);
        if (prefs != null) {
          return _buildResponseFromCache(prefs);
        }
      }

      final cached = CacheService.getJsonData(cacheKey);
      if (cached != null) {
        return _buildResponseFromCache(cached);
      }
    } catch (e) {
      print('[HTTP] Erro ao ler cache: $e');
    }
    return null;
  }

  static http.Response _buildResponseFromCache(Map<String, dynamic> cached) {
    return http.Response(
      cached['body'] as String,
      cached['statusCode'] as int,
      headers: Map<String, String>.from(cached['headers'] as Map),
    );
  }

  /// Limpa cache HTTP
  static Future<void> clearCache() async {
    print('[HTTP] Cache HTTP limpo');
  }

  /// Faz múltiplas requisições em paralelo com limite
  static Future<List<http.Response?>> getMultiple(
    List<Uri> urls, {
    Map<String, String>? headers,
    Duration? timeout,
    int maxConcurrent = 3,
  }) async {
    final results = <http.Response?>[];

    // Divide em lotes para não sobrecarregar
    for (int i = 0; i < urls.length; i += maxConcurrent) {
      final batch = urls.skip(i).take(maxConcurrent);
      final batchResults = await Future.wait(
        batch.map((url) => get(url, headers: headers, timeout: timeout)),
      );
      results.addAll(batchResults);
    }

    return results;
  }
}
