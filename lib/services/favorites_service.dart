import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import './cloud_sync_service.dart';

/// Service for managing favorite quotes with cloud sync
class FavoritesService {
  static const String _favoritesKey = 'user_favorites';

  /// Get all favorite quotes with cloud sync
  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      // Try cloud first if authenticated
      if (CloudSyncService.instance.isAuthenticated) {
        final cloudFavorites = await CloudSyncService.instance
            .getFavoritesFromCloud();
        if (cloudFavorites.isNotEmpty) {
          // Update local cache
          await _updateLocalCache(cloudFavorites);
          return cloudFavorites;
        }
      }

      // Fallback to local storage
      return await _getLocalFavorites();
    } catch (error) {
      print('Error getting favorites: $error');
      return await _getLocalFavorites();
    }
  }

  /// Get local favorites from SharedPreferences
  Future<List<Map<String, dynamic>>> _getLocalFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];

    return favoritesJson.map((jsonStr) {
      return Map<String, dynamic>.from(json.decode(jsonStr));
    }).toList();
  }

  /// Update local cache with cloud data
  Future<void> _updateLocalCache(List<Map<String, dynamic>> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = favorites.map((fav) => json.encode(fav)).toList();
    await prefs.setStringList(_favoritesKey, favoritesJson);
  }

  /// Add a quote to favorites with cloud sync
  Future<void> addFavorite(Map<String, dynamic> quote) async {
    // Add to local first
    final prefs = await SharedPreferences.getInstance();
    final favorites = await _getLocalFavorites();

    // Check if already exists
    final exists = favorites.any((fav) => fav['id'] == quote['id']);
    if (exists) return;

    // Add timestamp when favorited
    final favoriteQuote = Map<String, dynamic>.from(quote);
    favoriteQuote['addedDate'] = DateTime.now().toIso8601String();
    favoriteQuote['isFavorite'] = true;

    favorites.insert(0, favoriteQuote);

    final favoritesJson = favorites.map((fav) => json.encode(fav)).toList();
    await prefs.setStringList(_favoritesKey, favoritesJson);

    // Sync to cloud if authenticated
    if (CloudSyncService.instance.isAuthenticated) {
      try {
        await CloudSyncService.instance.addFavoriteToCloud(favoriteQuote);
      } catch (error) {
        print('Error syncing favorite to cloud: $error');
      }
    }
  }

  /// Remove a quote from favorites with cloud sync
  Future<void> removeFavorite(int quoteId) async {
    // Remove from local
    final prefs = await SharedPreferences.getInstance();
    final favorites = await _getLocalFavorites();

    favorites.removeWhere((fav) => fav['id'] == quoteId);

    final favoritesJson = favorites.map((fav) => json.encode(fav)).toList();
    await prefs.setStringList(_favoritesKey, favoritesJson);

    // Sync to cloud if authenticated
    if (CloudSyncService.instance.isAuthenticated) {
      try {
        await CloudSyncService.instance.removeFavoriteFromCloud(quoteId);
      } catch (error) {
        print('Error removing favorite from cloud: $error');
      }
    }
  }

  /// Check if a quote is favorited
  Future<bool> isFavorite(int quoteId) async {
    try {
      // Check cloud first if authenticated
      if (CloudSyncService.instance.isAuthenticated) {
        return await CloudSyncService.instance.isFavoriteInCloud(quoteId);
      }

      // Fallback to local
      final favorites = await _getLocalFavorites();
      return favorites.any((fav) => fav['id'] == quoteId);
    } catch (error) {
      print('Error checking favorite status: $error');
      final favorites = await _getLocalFavorites();
      return favorites.any((fav) => fav['id'] == quoteId);
    }
  }

  /// Toggle favorite status with cloud sync
  Future<bool> toggleFavorite(Map<String, dynamic> quote) async {
    final quoteId = quote['id'] as int;
    final isFav = await isFavorite(quoteId);

    if (isFav) {
      await removeFavorite(quoteId);
      return false;
    } else {
      await addFavorite(quote);
      return true;
    }
  }

  /// Clear all favorites with cloud sync
  Future<void> clearFavorites() async {
    // Clear cloud first if authenticated
    if (CloudSyncService.instance.isAuthenticated) {
      try {
        await CloudSyncService.instance.clearFavoritesFromCloud();
      } catch (error) {
        print('Error clearing favorites from cloud: $error');
      }
    }

    // Clear local after cloud
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
  }

  /// Get favorites count
  Future<int> getFavoritesCount() async {
    final favorites = await getFavorites();
    return favorites.length;
  }

  /// Move favorite to top
  Future<void> moveToTop(int quoteId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await _getLocalFavorites();

    final index = favorites.indexWhere((fav) => fav['id'] == quoteId);
    if (index == -1 || index == 0) return;

    final quote = favorites.removeAt(index);
    favorites.insert(0, quote);

    final favoritesJson = favorites.map((fav) => json.encode(fav)).toList();
    await prefs.setStringList(_favoritesKey, favoritesJson);
  }

  /// Remove multiple favorites
  Future<void> removeFavorites(List<int> quoteIds) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await _getLocalFavorites();

    favorites.removeWhere((fav) => quoteIds.contains(fav['id']));

    final favoritesJson = favorites.map((fav) => json.encode(fav)).toList();
    await prefs.setStringList(_favoritesKey, favoritesJson);

    // Sync to cloud if authenticated
    if (CloudSyncService.instance.isAuthenticated) {
      try {
        for (final quoteId in quoteIds) {
          await CloudSyncService.instance.removeFavoriteFromCloud(quoteId);
        }
      } catch (error) {
        print('Error removing favorites from cloud: $error');
      }
    }
  }

  /// Sync local favorites to cloud on auth
  Future<void> syncLocalToCloud() async {
    if (!CloudSyncService.instance.isAuthenticated) return;

    try {
      final localFavorites = await _getLocalFavorites();

      for (final favorite in localFavorites) {
        try {
          await CloudSyncService.instance.addFavoriteToCloud(favorite);
        } catch (error) {
          print('Error syncing favorite to cloud: $error');
        }
      }
    } catch (error) {
      print('Error syncing local favorites to cloud: $error');
    }
  }
}
