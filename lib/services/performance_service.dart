import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './logger_service.dart';

/// Performance monitoring and optimization service
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  DateTime? _appStartTime;
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, List<int>> _operationDurations = {};

  /// Initialize performance monitoring
  void initialize() {
    _appStartTime = DateTime.now();
    LoggerService.info('Performance monitoring initialized');
  }

  /// Record app launch completion
  Future<void> recordAppLaunch() async {
    if (_appStartTime == null) return;

    final launchDuration = DateTime.now()
        .difference(_appStartTime!)
        .inMilliseconds;

    LoggerService.info(
      'App launch completed',
      data: {'duration_ms': launchDuration},
    );

    // Save launch time for analytics
    try {
      final prefs = await SharedPreferences.getInstance();
      final launches = prefs.getStringList('app_launch_times') ?? [];
      launches.add(launchDuration.toString());

      // Keep only last 10 launches
      if (launches.length > 10) {
        launches.removeAt(0);
      }

      await prefs.setStringList('app_launch_times', launches);
    } catch (e) {
      LoggerService.error('Failed to save launch time', error: e);
    }
  }

  /// Start timing an operation
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }

  /// End timing an operation
  void endOperation(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime == null) return;

    final duration = DateTime.now().difference(startTime).inMilliseconds;

    // Store duration
    _operationDurations.putIfAbsent(operationName, () => []);
    _operationDurations[operationName]!.add(duration);

    // Keep only last 20 measurements
    if (_operationDurations[operationName]!.length > 20) {
      _operationDurations[operationName]!.removeAt(0);
    }

    if (kDebugMode) {
      LoggerService.debug(
        'Operation completed: $operationName',
        data: {'duration_ms': duration},
      );
    }

    _operationStartTimes.remove(operationName);
  }

  /// Get average duration for an operation
  double? getAverageDuration(String operationName) {
    final durations = _operationDurations[operationName];
    if (durations == null || durations.isEmpty) return null;

    final sum = durations.reduce((a, b) => a + b);
    return sum / durations.length;
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};

    for (final entry in _operationDurations.entries) {
      final avg = getAverageDuration(entry.key);
      if (avg != null) {
        report[entry.key] = {
          'average_ms': avg.toStringAsFixed(2),
          'samples': entry.value.length,
        };
      }
    }

    return report;
  }

  /// Get memory usage (approximate)
  Future<Map<String, dynamic>> getMemoryUsage() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Note: Actual memory usage requires platform-specific implementation
        // This is a placeholder for future implementation
        return {
          'status':
              'Memory monitoring requires platform-specific implementation',
        };
      }
    } catch (e) {
      LoggerService.error('Failed to get memory usage', error: e);
    }

    return {};
  }

  /// Battery optimization recommendations
  List<String> getBatteryOptimizationTips() {
    return [
      'Reduce background API calls',
      'Use efficient image caching',
      'Minimize notification frequency',
      'Optimize animation frame rates',
      'Use dark theme to save battery on OLED screens',
    ];
  }

  /// Clear performance data
  Future<void> clearPerformanceData() async {
    _operationStartTimes.clear();
    _operationDurations.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('app_launch_times');
      LoggerService.info('Performance data cleared');
    } catch (e) {
      LoggerService.error('Failed to clear performance data', error: e);
    }
  }
}
