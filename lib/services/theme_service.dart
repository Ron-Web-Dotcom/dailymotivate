import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './cloud_sync_service.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  ThemeMode _themeMode = ThemeMode.system;

  factory ThemeService() => _instance;

  ThemeService._internal();

  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    try {
      // Try cloud first if authenticated
      if (CloudSyncService.instance.isAuthenticated) {
        final cloudSettings = await CloudSyncService.instance
            .getSettingsFromCloud();
        if (cloudSettings != null && cloudSettings['theme_mode'] != null) {
          _themeMode = _parseThemeMode(cloudSettings['theme_mode'] as String);
          notifyListeners();
          // Update local cache
          await _updateLocalTheme(cloudSettings['theme_mode'] as String);
          return;
        }
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString('theme_mode') ?? 'system';
      _themeMode = _parseThemeMode(themeModeString);
      notifyListeners();
    } catch (error) {
      print('Error initializing theme: $error');
      _themeMode = ThemeMode.system;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(String mode) async {
    // Update local first
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
    _themeMode = _parseThemeMode(mode);
    notifyListeners();

    // Sync to cloud if authenticated
    if (CloudSyncService.instance.isAuthenticated) {
      try {
        final currentSettings =
            await CloudSyncService.instance.getSettingsFromCloud() ?? {};
        currentSettings['theme_mode'] = mode;
        await CloudSyncService.instance.updateSettingsInCloud(currentSettings);
      } catch (error) {
        print('Error syncing theme to cloud: $error');
      }
    }
  }

  Future<void> _updateLocalTheme(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Sync local theme to cloud on auth
  Future<void> syncLocalToCloud() async {
    if (!CloudSyncService.instance.isAuthenticated) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final localTheme = prefs.getString('theme_mode') ?? 'system';

      final currentSettings =
          await CloudSyncService.instance.getSettingsFromCloud() ?? {};
      currentSettings['theme_mode'] = localTheme;
      await CloudSyncService.instance.updateSettingsInCloud(currentSettings);
    } catch (error) {
      print('Error syncing theme to cloud: $error');
    }
  }
}
