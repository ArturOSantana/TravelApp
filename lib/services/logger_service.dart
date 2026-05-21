import 'package:flutter/foundation.dart';

class LoggerService {
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '[DEBUG]';
      debugPrint('$prefix $message');
    }
  }

  static void info(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag]' : '[INFO]';
    debugPrint('$prefix $message');
  }

  static void warning(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag]' : '[WARNING]';
    debugPrint('$prefix $message');
  }

  static void error(String message, {String? tag, Object? error}) {
    final prefix = tag != null ? '[$tag]' : '[ERROR]';
    debugPrint('$prefix $message');
    if (error != null) {
      debugPrint('$prefix Error details: $error');
    }
  }
}
