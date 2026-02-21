import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import './logger_service.dart';

/// Crash reporting service using Firebase Crashlytics
class CrashReportingService {
  static final CrashReportingService _instance =
      CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  bool _initialized = false;

  /// Initialize crash reporting
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        // Disable Crashlytics in debug mode
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          false,
        );
        LoggerService.info('Crashlytics disabled in debug mode');
        return;
      }

      // Enable Crashlytics in production
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // Pass all uncaught errors to Crashlytics
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      _initialized = true;
      LoggerService.info('Crash reporting initialized successfully');
    } catch (e) {
      LoggerService.error('Failed to initialize crash reporting', error: e);
    }
  }

  /// Log non-fatal error
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
  }) async {
    if (!_initialized) return;

    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        information:
            context?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
        fatal: false,
      );

      LoggerService.error(
        reason ?? 'Non-fatal error',
        error: error,
        stackTrace: stackTrace,
        data: context,
      );
    } catch (e) {
      LoggerService.error('Failed to log error to Crashlytics', error: e);
    }
  }

  /// Set user identifier
  Future<void> setUserId(String userId) async {
    if (!_initialized) return;

    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      LoggerService.info(
        'User ID set for crash reporting',
        data: {'userId': userId},
      );
    } catch (e) {
      LoggerService.error('Failed to set user ID', error: e);
    }
  }

  /// Set custom key-value pair
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_initialized) return;

    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      LoggerService.error('Failed to set custom key', error: e);
    }
  }

  /// Log custom message
  Future<void> log(String message) async {
    if (!_initialized) return;

    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (e) {
      LoggerService.error('Failed to log message', error: e);
    }
  }

  /// Test crash reporting (debug only)
  Future<void> testCrash() async {
    if (!kDebugMode) return;

    try {
      throw Exception('Test crash from CrashReportingService');
    } catch (e, stack) {
      await logError(e, stack, reason: 'Test crash');
    }
  }
}
