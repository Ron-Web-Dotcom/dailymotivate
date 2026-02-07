import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import './supabase_service.dart';

/// Service for cloud synchronization of favorites and settings
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  static CloudSyncService get instance => _instance;

  CloudSyncService._internal();

  final _client = SupabaseService.instance.client;
  RealtimeChannel? _favoritesChannel;
  RealtimeChannel? _settingsChannel;

  final _favoritesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _settingsController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<List<Map<String, dynamic>>> get favoritesStream =>
      _favoritesController.stream;
  Stream<Map<String, dynamic>> get settingsStream => _settingsController.stream;

  String? get userId {
    try {
      final user = _client.auth.currentUser;
      return user?.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting userId: $e');
      }
      return null;
    }
  }

  bool get isAuthenticated {
    try {
      return userId != null;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking authentication: $e');
      }
      return false;
    }
  }

  /// Initialize real-time subscriptions for favorites and settings
  Future<void> initializeRealtimeSync() async {
    if (!isAuthenticated) return;

    try {
      // Subscribe to favorites changes
      _favoritesChannel = _client
          .channel('public:user_favorites')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_favorites',
            callback: (payload) async {
              try {
                await _handleFavoritesChange(payload);
              } catch (e) {
                print('Error handling favorites change: $e');
              }
            },
          )
          .subscribe();

      // Subscribe to settings changes
      _settingsChannel = _client
          .channel('public:user_settings')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_settings',
            callback: (payload) async {
              try {
                await _handleSettingsChange(payload);
              } catch (e) {
                print('Error handling settings change: $e');
              }
            },
          )
          .subscribe();

      // Initial data load
      await syncFavoritesFromCloud();
      await syncSettingsFromCloud();
    } catch (error) {
      print('Error initializing real-time sync: $error');
    }
  }

  /// Handle favorites real-time changes
  Future<void> _handleFavoritesChange(PostgresChangePayload payload) async {
    if (!isAuthenticated) return;

    final event = payload.eventType;
    final newRecord = payload.newRecord;

    if (newRecord['user_id'] != userId) return;

    if (event == PostgresChangeEvent.insert ||
        event == PostgresChangeEvent.update ||
        event == PostgresChangeEvent.delete) {
      // Reload all favorites when change detected
      await syncFavoritesFromCloud();
    }
  }

  /// Handle settings real-time changes
  Future<void> _handleSettingsChange(PostgresChangePayload payload) async {
    if (!isAuthenticated) return;

    final event = payload.eventType;
    final newRecord = payload.newRecord;

    if (newRecord['user_id'] != userId) return;

    if (event == PostgresChangeEvent.insert ||
        event == PostgresChangeEvent.update) {
      _settingsController.add(newRecord);
    }
  }

  /// Sync favorites from cloud to local and emit stream
  Future<void> syncFavoritesFromCloud() async {
    if (!isAuthenticated) return;

    try {
      final response = await _client
          .from('user_favorites')
          .select()
          .eq('user_id', userId!)
          .order('added_date', ascending: false);

      _favoritesController.add(List<Map<String, dynamic>>.from(response));
    } catch (error) {
      print('Error syncing favorites from cloud: $error');
      _favoritesController.addError(error);
    }
  }

  /// Sync settings from cloud to local and emit stream
  Future<void> syncSettingsFromCloud() async {
    if (!isAuthenticated) return;

    try {
      final response = await _client
          .from('user_settings')
          .select()
          .eq('user_id', userId!)
          .maybeSingle();

      if (response != null) {
        _settingsController.add(Map<String, dynamic>.from(response));
      } else {
        // Create default settings if none exist
        await createDefaultSettings();
      }
    } catch (error) {
      print('Error syncing settings from cloud: $error');
      _settingsController.addError(error);
    }
  }

  /// Add favorite to cloud
  Future<void> addFavoriteToCloud(Map<String, dynamic> quote) async {
    if (!isAuthenticated) return;

    try {
      final data = {
        'user_id': userId,
        'quote_id': quote['id'] as int,
        'quote_text': quote['text'] as String,
        'quote_author': quote['author'] as String?,
        'quote_category': quote['category'] as String?,
        'quote_tags': quote['tags'] as String?,
        'quote_image': quote['image'] as String?,
        'is_favorite': true,
        'added_date': DateTime.now().toIso8601String(),
      };

      await _client.from('user_favorites').insert(data).select();
    } catch (error) {
      throw Exception('Failed to add favorite to cloud: $error');
    }
  }

  /// Remove favorite from cloud
  Future<void> removeFavoriteFromCloud(int quoteId) async {
    if (!isAuthenticated) return;

    try {
      await _client
          .from('user_favorites')
          .delete()
          .eq('user_id', userId!)
          .eq('quote_id', quoteId)
          .select();
    } catch (error) {
      throw Exception('Failed to remove favorite from cloud: $error');
    }
  }

  /// Check if quote is favorited in cloud
  Future<bool> isFavoriteInCloud(int quoteId) async {
    if (!isAuthenticated) return false;

    try {
      final response = await _client
          .from('user_favorites')
          .select('id')
          .eq('user_id', userId!)
          .eq('quote_id', quoteId)
          .maybeSingle();

      return response != null;
    } catch (error) {
      print('Error checking favorite status: $error');
      return false;
    }
  }

  /// Get all favorites from cloud
  Future<List<Map<String, dynamic>>> getFavoritesFromCloud() async {
    if (!isAuthenticated) return [];

    try {
      final response = await _client
          .from('user_favorites')
          .select()
          .eq('user_id', userId!)
          .order('added_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('Error getting favorites from cloud: $error');
      return [];
    }
  }

  /// Create default settings for new user
  Future<void> createDefaultSettings() async {
    if (!isAuthenticated) return;

    try {
      final data = {
        'user_id': userId,
        'theme_mode': 'system',
        'notifications_enabled': true,
        'daily_notification_time': '09:00:00',
        'ai_enabled': true,
        'ai_provider': 'openai',
        'haptic_feedback': true,
      };

      final response = await _client
          .from('user_settings')
          .insert(data)
          .select();

      if (response.isNotEmpty) {
        _settingsController.add(Map<String, dynamic>.from(response[0]));
      }
    } catch (error) {
      print('Error creating default settings: $error');
    }
  }

  /// Update settings in cloud
  Future<void> updateSettingsInCloud(Map<String, dynamic> settings) async {
    if (!isAuthenticated) return;

    try {
      final updateData = {...settings, 'user_id': userId};

      await _client
          .from('user_settings')
          .upsert(updateData)
          .eq('user_id', userId!)
          .select();
    } catch (error) {
      throw Exception('Failed to update settings in cloud: $error');
    }
  }

  /// Get settings from cloud
  Future<Map<String, dynamic>?> getSettingsFromCloud() async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('user_settings')
          .select()
          .eq('user_id', userId!)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (error) {
      print('Error getting settings from cloud: $error');
      return null;
    }
  }

  /// Clear favorites from cloud
  Future<void> clearFavoritesFromCloud() async {
    if (!isAuthenticated) return;

    try {
      await _client
          .from('user_favorites')
          .delete()
          .eq('user_id', userId!)
          .select();

      // Emit empty list to stream to update UI immediately
      _favoritesController.add([]);
    } catch (error) {
      throw Exception('Failed to clear favorites from cloud: $error');
    }
  }

  /// Clear settings from cloud
  Future<void> clearSettingsFromCloud() async {
    if (!isAuthenticated) return;

    try {
      await _client
          .from('user_settings')
          .delete()
          .eq('user_id', userId!)
          .select();

      // Emit empty map to stream to update UI immediately
      _settingsController.add({});
    } catch (error) {
      throw Exception('Failed to clear settings from cloud: $error');
    }
  }

  /// Dispose subscriptions
  void dispose() {
    _favoritesChannel?.unsubscribe();
    _settingsChannel?.unsubscribe();
    _favoritesController.close();
    _settingsController.close();
  }
}
