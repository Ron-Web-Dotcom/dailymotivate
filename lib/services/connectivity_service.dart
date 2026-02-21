import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import './logger_service.dart';

/// Network connectivity monitoring service
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  /// Stream of connection status (true = connected, false = disconnected)
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);

      // Listen to connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          LoggerService.error('Connectivity monitoring error', error: error);
        },
      );

      LoggerService.info('Connectivity service initialized');
    } catch (e) {
      LoggerService.error(
        'Failed to initialize connectivity service',
        error: e,
      );
    }
  }

  /// Update connection status
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;

    // Check if any connection type is available
    _isConnected = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );

    // Notify listeners if status changed
    if (wasConnected != _isConnected) {
      _connectionStatusController.add(_isConnected);

      if (kDebugMode) {
        LoggerService.info(
          'Connection status changed: ${_isConnected ? "Connected" : "Disconnected"}',
        );
      }
    }
  }

  /// Check current connectivity
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return _isConnected;
    } catch (e) {
      LoggerService.error('Failed to check connectivity', error: e);
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}
