import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'cache_service.dart';
import 'logger_service.dart';

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
        LoggerService.debug('Cache hit: ${url.toString()}', tag: 'HTTP');
        return cached;
      }
    }

    int attempts = 0;
    Exception? lastException;

    while (attempts < _maxRetries) {
      try {
        LoggerService.debug(
            'Tentativa ${attempts + 1}/$_maxRetries: ${url.toString()}',
            tag: 'HTTP');

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
          LoggerService.warning('Client error: ${response.statusCode}',
              tag: 'HTTP');
          return response;
        }
      } on TimeoutException catch (e) {
        LoggerService.warning('Timeout na tentativa ${attempts + 1}',
            tag: 'HTTP');
        lastException = e;
        attempts++;
        if (attempts < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      } catch (e) {
        LoggerService.error('Erro na tentativa ${attempts + 1}',
            tag: 'HTTP', error: e);
        lastException = e as Exception;
        attempts++;
        if (attempts < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      }
    }

    LoggerService.error('Falha após $_maxRetries tentativas: ${url.toString()}',
        tag: 'HTTP');

    if (useCache) {
      final oldCache = _getCachedResponse(url.toString(), ignoreExpiry: true);
      if (oldCache != null) {
        LoggerService.info('Usando cache expirado como fallback', tag: 'HTTP');
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
        LoggerService.debug(
            'POST tentativa ${attempts + 1}/$_maxRetries: ${url.toString()}',
            tag: 'HTTP');

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
        LoggerService.warning('POST timeout na tentativa ${attempts + 1}',
            tag: 'HTTP');
        lastException = e;
        attempts++;
        if (attempts < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      } catch (e) {
        LoggerService.error('POST erro na tentativa ${attempts + 1}',
            tag: 'HTTP', error: e);
        lastException = e as Exception;
        attempts++;
        if (attempts < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      }
    }

    throw lastException ?? Exception('Failed to post data');
  }

  static Future<void> _cacheResponse(
    String url,
    http.Response response,
    Duration duration,
  ) async {
    try {
      final cacheData = {
        'statusCode': response.statusCode,
        'body': response.body,
        'headers': response.headers,
      };
      final cacheKey = _generateCacheKey(url);
      await CacheService.saveData(
        cacheKey,
        cacheData,
        expiration: duration,
      );
    } catch (e) {
      LoggerService.error('Erro ao salvar cache', tag: 'HTTP', error: e);
    }
  }

  static http.Response? _getCachedResponse(
    String url, {
    bool ignoreExpiry = false,
  }) {
    try {
      final cacheKey = _generateCacheKey(url);

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
      LoggerService.error('Erro ao ler cache', tag: 'HTTP', error: e);
    }
    return null;
  }

  static String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final hash = sha256.convert(bytes);
    return 'http_${hash.toString().substring(0, 32)}';
  }

  static http.Response _buildResponseFromCache(Map<String, dynamic> cached) {
    return http.Response(
      cached['body'] as String,
      cached['statusCode'] as int,
      headers: Map<String, String>.from(cached['headers'] as Map),
    );
  }

  static Future<void> clearCache() async {
    LoggerService.info('Cache HTTP limpo', tag: 'HTTP');
  }

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
