import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import '../core/exceptions/app_exceptions.dart';

class CacheService {
  static SharedPreferences? _prefs;
  static Timer? _cleanupTimer;

  static const int _maxCacheSize = 50;
  static const Duration _cleanupInterval = Duration(hours: 6);
  static const int _batchRemoveSize = 10;

  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      try {
        await _cleanExpiredCache();
      } catch (e) {
        debugPrint('[CacheService] Erro ao limpar cache expirado: $e');
      }

      _cleanupTimer?.cancel();
      _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
        _cleanExpiredCache().catchError((e) {
          debugPrint('[CacheService] Erro no cleanup periódico: $e');
        });
      });
    } catch (e, stackTrace) {
      debugPrint('[CacheService] Erro fatal na inicialização: $e');
      debugPrint('[CacheService] Stack trace: $stackTrace');
      throw CacheException(
        'Erro ao inicializar cache',
        code: 'initialization_failed',
        originalError: e,
      );
    }
  }

  static Future<bool> saveData(
    String key,
    dynamic data, {
    Duration? expiration,
  }) async {
    _validateKey(key);

    try {
      if (_prefs == null) await initialize();

      await _checkCacheLimit();

      if (expiration != null) {
        final expiryTime =
            DateTime.now().add(expiration).millisecondsSinceEpoch;
        await _prefs!.setInt('${key}_expiry', expiryTime);
      }

      if (data is String) {
        return await _prefs!.setString(key, data);
      } else if (data is int) {
        return await _prefs!.setInt(key, data);
      } else if (data is double) {
        return await _prefs!.setDouble(key, data);
      } else if (data is bool) {
        return await _prefs!.setBool(key, data);
      } else if (data is List<String>) {
        return await _prefs!.setStringList(key, data);
      } else {
        final jsonString = json.encode(data);
        return await _prefs!.setString(key, jsonString);
      }
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw CacheException(
        'Erro ao salvar no cache',
        code: 'save_failed',
        originalError: e,
      );
    }
  }

  static dynamic getData(String key, {dynamic defaultValue}) {
    _validateKey(key);

    try {
      if (_prefs == null) return defaultValue;

      if (_isExpired(key)) {
        removeKey(key);
        return defaultValue;
      }

      return _prefs!.get(key) ?? defaultValue;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw CacheException(
        'Erro ao recuperar do cache',
        code: 'get_failed',
        originalError: e,
      );
    }
  }

  static Map<String, dynamic>? getJsonData(String key) {
    _validateKey(key);

    try {
      if (_prefs == null) return null;

      final jsonString = _prefs!.getString(key);
      if (jsonString == null) return null;

      return json.decode(jsonString) as Map<String, dynamic>;
    } on ValidationException {
      rethrow;
    } on FormatException catch (e) {
      throw CacheException(
        'JSON inválido no cache',
        code: 'invalid_json',
        originalError: e,
      );
    } catch (e) {
      throw CacheException(
        'Erro ao recuperar JSON do cache',
        code: 'get_json_failed',
        originalError: e,
      );
    }
  }

  static bool hasKey(String key) {
    _validateKey(key);

    if (_prefs == null) return false;
    return _prefs!.containsKey(key);
  }

  static Future<bool> removeKey(String key) async {
    _validateKey(key);

    try {
      if (_prefs == null) await initialize();

      await _prefs!.remove('${key}_expiry');
      return await _prefs!.remove(key);
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw CacheException(
        'Erro ao remover do cache',
        code: 'remove_failed',
        originalError: e,
      );
    }
  }

  static Future<bool> clearAll() async {
    try {
      if (_prefs == null) await initialize();
      return await _prefs!.clear();
    } catch (e) {
      throw CacheException(
        'Erro ao limpar cache',
        code: 'clear_failed',
        originalError: e,
      );
    }
  }

  static bool isOnboardingCompleted() {
    return getData('onboarding_completed', defaultValue: false) as bool;
  }

  static Future<bool> setOnboardingCompleted() {
    return saveData('onboarding_completed', true);
  }

  static Future<bool> cacheUserData(Map<String, dynamic> userData) {
    return saveData('user_data', userData);
  }

  static Map<String, dynamic>? getCachedUserData() {
    return getJsonData('user_data');
  }

  static Future<bool> saveLastSync() {
    return saveData('last_sync', DateTime.now().toIso8601String());
  }

  static DateTime? getLastSync() {
    final syncString = getData('last_sync') as String?;
    if (syncString == null) return null;
    return DateTime.tryParse(syncString);
  }

  static bool needsSync() {
    final lastSync = getLastSync();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync).inHours >= 1;
  }

  static bool _isExpired(String key) {
    final expiryTime = _prefs?.getInt('${key}_expiry');
    if (expiryTime == null) return false;
    return DateTime.now().millisecondsSinceEpoch > expiryTime;
  }

  static Future<void> _cleanExpiredCache() async {
    try {
      if (_prefs == null) return;

      final keys = _prefs!.getKeys();
      var cleaned = 0;

      for (final key in keys) {
        if (key.endsWith('_expiry')) continue;
        if (_isExpired(key)) {
          await removeKey(key);
          cleaned++;
        }
      }
    } catch (e) {
      throw CacheException(
        'Erro ao limpar cache expirado',
        code: 'cleanup_failed',
        originalError: e,
      );
    }
  }

  static Future<void> _checkCacheLimit() async {
    try {
      if (_prefs == null) return;

      final keys =
          _prefs!.getKeys().where((k) => !k.endsWith('_expiry')).toList();

      if (keys.length >= _maxCacheSize) {
        final keysToRemove = keys.take(_batchRemoveSize).toList();
        for (final key in keysToRemove) {
          await removeKey(key);
        }
      }
    } catch (e) {
      throw CacheException(
        'Erro ao verificar limite de cache',
        code: 'limit_check_failed',
        originalError: e,
      );
    }
  }

  static Map<String, dynamic> getCacheStats() {
    if (_prefs == null) return {};

    final keys = _prefs!.getKeys();
    final dataKeys = keys.where((k) => !k.endsWith('_expiry')).toList();
    final expiredCount = dataKeys.where((k) => _isExpired(k)).length;

    return {
      'totalEntries': dataKeys.length,
      'expiredEntries': expiredCount,
      'activeEntries': dataKeys.length - expiredCount,
      'maxSize': _maxCacheSize,
      'usagePercent': (_maxCacheSize > 0)
          ? ((dataKeys.length / _maxCacheSize) * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  static void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  static void _validateKey(String key) {
    if (key.trim().isEmpty) {
      throw ValidationException('Chave do cache não pode estar vazia');
    }
    if (key.length > 255) {
      throw ValidationException(
          'Chave do cache muito longa (máx. 255 caracteres)');
    }
    if (key.contains(RegExp(r'[^\w\-_.]'))) {
      throw ValidationException(
        'Chave do cache contém caracteres inválidos (use apenas letras, números, -, _ e .)',
      );
    }
  }
}

// Made with Bob
