import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MemoryManagerService {
  static final MemoryManagerService _instance =
      MemoryManagerService._internal();
  factory MemoryManagerService() => _instance;
  MemoryManagerService._internal();

  final Map<String, ImageProvider> _imageCache = {};
  static const int _maxImageCacheSize = 20; // Limite para dispositivos antigos

  bool _isLowEndDevice = false;
  bool get isLowEndDevice => _isLowEndDevice;

  Future<void> initialize() async {
    await _detectDeviceCapability();

    if (_isLowEndDevice) {
      debugPrint(
          '[MEMORY] Dispositivo de baixa performance detectado - Otimizações ativadas');
      _setupMemoryOptimizations();
    }
  }

  Future<void> _detectDeviceCapability() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        _isLowEndDevice = true;
      }
    } catch (e) {
      debugPrint('Erro ao detectar capacidade do dispositivo: $e');
      _isLowEndDevice = true;
    }
  }

  void _setupMemoryOptimizations() {
    Timer.periodic(const Duration(minutes: 5), (_) {
      clearImageCache();
    });
  }

  ImageProvider getCachedImage(String url, {bool forceReload = false}) {
    if (forceReload || !_imageCache.containsKey(url)) {
      if (_imageCache.length >= _maxImageCacheSize) {
        _imageCache.remove(_imageCache.keys.first);
      }

      _imageCache[url] = NetworkImage(url);
    }

    return _imageCache[url]!;
  }

  void clearImageCache() {
    _imageCache.clear();
    debugPrint('[MEMORY] Cache de imagens limpo');
  }

  Map<String, dynamic> getOptimizedSettings() {
    if (_isLowEndDevice) {
      return {
        'imageQuality': 75,
        'maxImageSize': 800,
        'enableAnimations': true,
        'cacheSize': 30 * 1024 * 1024,
        'preloadImages': false,
        'enableHaptics': false,
        'thumbnailSize': 200,
      };
    } else {
      return {
        'imageQuality': 90,
        'maxImageSize': 2048,
        'enableAnimations': true,
        'cacheSize': 100 * 1024 * 1024,
        'preloadImages': true,
        'enableHaptics': true,
        'thumbnailSize': 400,
      };
    }
  }

  Duration getAnimationDuration(Duration defaultDuration) {
    if (_isLowEndDevice) {
      return Duration(milliseconds: defaultDuration.inMilliseconds ~/ 2);
    }
    return defaultDuration;
  }

  bool shouldUseAnimations() {
    return !_isLowEndDevice;
  }

  int getOptimalPageSize() {
    return _isLowEndDevice ? 15 : 30;
  }

  int getOptimalGridColumns() {
    return _isLowEndDevice ? 2 : 3;
  }

  void setLowEndMode(bool enabled) {
    _isLowEndDevice = enabled;
    if (enabled) {
      debugPrint('[MEMORY] Modo de baixa performance ativado manualmente');
      _setupMemoryOptimizations();
    }
  }

  void dispose() {
    clearImageCache();
  }
}
