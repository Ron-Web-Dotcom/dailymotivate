import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Production-safe logging service with multiple log levels
class LoggerService {
  static const String _logLevelKey = 'app_log_level';
  static LogLevel _currentLevel = LogLevel.info;

  /// Initialize logger with saved preferences
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLevel = prefs.getString(_logLevelKey);
      if (savedLevel != null) {
        _currentLevel = LogLevel.values.firstWhere(
          (level) => level.name == savedLevel,
          orElse: () => LogLevel.info,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize logger: $e');
      }
    }
  }

  /// Set log level
  static Future<void> setLogLevel(LogLevel level) async {
    _currentLevel = level;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_logLevelKey, level.name);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save log level: $e');
      }
    }
  }

  /// Log debug message (development only)
  static void debug(String message, {Map<String, dynamic>? data}) {
    if (!kDebugMode) return;
    if (_currentLevel.index > LogLevel.debug.index) return;

    _log('DEBUG', message, data: data);
  }

  /// Log info message
  static void info(String message, {Map<String, dynamic>? data}) {
    if (_currentLevel.index > LogLevel.info.index) return;

    _log('INFO', message, data: data);
  }

  /// Log warning message
  static void warning(String message, {Map<String, dynamic>? data}) {
    if (_currentLevel.index > LogLevel.warning.index) return;

    _log('WARNING', message, data: data);
  }

  /// Log error message
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (_currentLevel.index > LogLevel.error.index) return;

    _log('ERROR', message, error: error, stackTrace: stackTrace, data: data);
  }

  /// Log critical error (always logged)
  static void critical(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log('CRITICAL', message, error: error, stackTrace: stackTrace, data: data);
  }

  /// Internal logging method
  static void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (!kDebugMode && level != 'CRITICAL') {
      // In production, only log critical errors
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer();

    buffer.write('[$timestamp] [$level] $message');

    if (data != null && data.isNotEmpty) {
      buffer.write(' | Data: ${_sanitizeData(data)}');
    }

    if (error != null) {
      buffer.write(' | Error: ${_sanitizeError(error)}');
    }

    if (kDebugMode) {
      print(buffer.toString());

      if (stackTrace != null) {
        print('Stack trace:\n$stackTrace');
      }
    }
  }

  /// Sanitize data to remove PII
  static Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();

      // Remove sensitive fields
      if (key.contains('password') ||
          key.contains('token') ||
          key.contains('secret') ||
          key.contains('key') ||
          key.contains('email') ||
          key.contains('phone')) {
        sanitized[entry.key] = '[REDACTED]';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }

    return sanitized;
  }

  /// Sanitize error messages
  static String _sanitizeError(Object error) {
    final errorStr = error.toString();

    // Remove potential API keys or tokens from error messages
    return errorStr
        .replaceAll(RegExp(r'sk-[a-zA-Z0-9]{48}'), '[API_KEY_REDACTED]')
        .replaceAll(RegExp(r'Bearer [a-zA-Z0-9._-]+'), '[TOKEN_REDACTED]')
        .replaceAll(
          RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
          '[EMAIL_REDACTED]',
        );
  }
}

/// Log levels
enum LogLevel { debug, info, warning, error, critical }
