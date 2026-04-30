import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class CacheService {
  static SharedPreferences? _prefs;
  static Timer? _cleanupTimer;
  static const int _maxCacheSize = 50; // Máximo de 50 entradas no cache
  static const Duration _cacheExpiration = Duration(hours: 24);

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    print('[CACHE] Cache Service inicializado');

    // Limpa cache expirado na inicialização
    await _cleanExpiredCache();

    // Configura limpeza periódica (a cada 6 horas)
    _cleanupTimer = Timer.periodic(const Duration(hours: 6), (_) {
      _cleanExpiredCache();
    });
  }

  static Future<bool> saveData(String key, dynamic data,
      {Duration? expiration}) async {
    try {
      if (_prefs == null) await initialize();

      // Verifica limite de cache
      await _checkCacheLimit();

      // Salva timestamp de expiração
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
    } catch (e) {
      print('[ERROR] Erro ao salvar cache: $e');
      return false;
    }
  }

  static dynamic getData(String key, {dynamic defaultValue}) {
    try {
      if (_prefs == null) return defaultValue;

      // Verifica se o cache expirou
      if (_isExpired(key)) {
        removeKey(key);
        return defaultValue;
      }

      return _prefs!.get(key) ?? defaultValue;
    } catch (e) {
      print('[ERROR] Erro ao recuperar cache: $e');
      return defaultValue;
    }
  }

  static Map<String, dynamic>? getJsonData(String key) {
    try {
      if (_prefs == null) return null;
      final jsonString = _prefs!.getString(key);
      if (jsonString == null) return null;
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('[ERROR] Erro ao recuperar JSON do cache: $e');
      return null;
    }
  }

  static bool hasKey(String key) {
    if (_prefs == null) return false;
    return _prefs!.containsKey(key);
  }

  static Future<bool> removeKey(String key) async {
    try {
      if (_prefs == null) await initialize();
      return await _prefs!.remove(key);
    } catch (e) {
      print('[ERROR] Erro ao remover chave do cache: $e');
      return false;
    }
  }

  static Future<bool> clearAll() async {
    try {
      if (_prefs == null) await initialize();
      return await _prefs!.clear();
    } catch (e) {
      print('[ERROR] Erro ao limpar cache: $e');
      return false;
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

  /// Verifica se uma chave expirou
  static bool _isExpired(String key) {
    final expiryTime = _prefs?.getInt('${key}_expiry');
    if (expiryTime == null) return false;
    return DateTime.now().millisecondsSinceEpoch > expiryTime;
  }

  /// Limpa cache expirado
  static Future<void> _cleanExpiredCache() async {
    try {
      if (_prefs == null) return;

      final keys = _prefs!.getKeys();
      int cleaned = 0;

      for (final key in keys) {
        if (key.endsWith('_expiry')) continue;
        if (_isExpired(key)) {
          await removeKey(key);
          await removeKey('${key}_expiry');
          cleaned++;
        }
      }

      if (cleaned > 0) {
        print('[CACHE] $cleaned entradas expiradas removidas');
      }
    } catch (e) {
      print('[ERROR] Erro ao limpar cache expirado: $e');
    }
  }

  /// Verifica e limita o tamanho do cache
  static Future<void> _checkCacheLimit() async {
    try {
      if (_prefs == null) return;

      final keys =
          _prefs!.getKeys().where((k) => !k.endsWith('_expiry')).toList();

      if (keys.length >= _maxCacheSize) {
        // Remove as entradas mais antigas (primeiras 10)
        final keysToRemove = keys.take(10).toList();
        for (final key in keysToRemove) {
          await removeKey(key);
          await removeKey('${key}_expiry');
        }
        print(
            '[CACHE] Cache limitado: ${keysToRemove.length} entradas removidas');
      }
    } catch (e) {
      print('[ERROR] Erro ao verificar limite de cache: $e');
    }
  }

  /// Obtém estatísticas do cache
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
    };
  }

  /// Libera recursos
  static void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }
}
