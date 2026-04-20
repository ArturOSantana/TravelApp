// ignore_for_file: unused_import

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    print('✅ Cache Service inicializado');
  }

  static Future<bool> saveData(String key, dynamic data) async {
    try {
      if (_prefs == null) await initialize();

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
      print('❌ Erro ao salvar cache: $e');
      return false;
    }
  }

  static dynamic getData(String key, {dynamic defaultValue}) {
    try {
      if (_prefs == null) return defaultValue;
      return _prefs!.get(key) ?? defaultValue;
    } catch (e) {
      print('❌ Erro ao recuperar cache: $e');
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
      print('❌ Erro ao recuperar JSON do cache: $e');
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
      print('❌ Erro ao remover chave do cache: $e');
      return false;
    }
  }

  static Future<bool> clearAll() async {
    try {
      if (_prefs == null) await initialize();
      return await _prefs!.clear();
    } catch (e) {
      print('❌ Erro ao limpar cache: $e');
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
}
