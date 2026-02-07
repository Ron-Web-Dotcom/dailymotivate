import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/quote_history_service.dart';
import '../../../services/favorites_service.dart';
import '../../../services/cloud_sync_service.dart';

/// Widget for managing app data including favorites reset and quote restoration
class DataManagementWidget extends StatefulWidget {
  const DataManagementWidget({super.key});

  @override
  State<DataManagementWidget> createState() => _DataManagementWidgetState();
}

class _DataManagementWidgetState extends State<DataManagementWidget> {
  final QuoteHistoryService _historyService = QuoteHistoryService();
  final FavoritesService _favoritesService = FavoritesService();
  Map<String, int> _statistics = {};
  bool _isLoading = false;
  int _favoritesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    final stats = await _historyService.getStatistics();
    final favCount = await _favoritesService.getFavoritesCount();
    setState(() {
      _statistics = stats;
      _favoritesCount = favCount;
      _isLoading = false;
    });
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade700,
              size: 28,
            ),
            SizedBox(width: 2.w),
            const Text('Clear All Data?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently delete:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            _buildDeleteItem('All saved favorites ($_favoritesCount quotes)'),
            _buildDeleteItem('Quote generation history'),
            _buildDeleteItem('App preferences and settings'),
            _buildDeleteItem('AI personalization data'),
            _buildDeleteItem('Theme and notification settings'),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      try {
        // Clear cloud data first if authenticated
        if (CloudSyncService.instance.isAuthenticated) {
          await CloudSyncService.instance.clearFavoritesFromCloud();
          await CloudSyncService.instance.clearSettingsFromCloud();
        }

        // Clear local services data
        await _historyService.clearHistory();
        await _favoritesService.clearFavorites();

        // Clear SharedPreferences last
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Force reload statistics to show empty state
        if (mounted) {
          setState(() {
            _statistics = {'total': 0};
            _favoritesCount = 0;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 2.w),
                  const Text('All data cleared successfully'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing data: ${e.toString()}'),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _clearQuoteHistory() async {
    final totalQuotes = _statistics['total'] ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.history,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            SizedBox(width: 2.w),
            const Text('Clear Quote History?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will delete the history of $totalQuotes AI-generated quotes.',
              style: TextStyle(fontSize: 13.sp),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Clearing history ensures maximum variety in future quotes by allowing previously shown quotes to reappear.',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Your favorites will NOT be affected.',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Clear History'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      try {
        // Clear quote history from local storage
        await _historyService.clearHistory();

        // Force reload statistics to show empty state
        if (mounted) {
          setState(() {
            _statistics = {'total': 0, 'openai': 0, 'gemini': 0};
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing history: ${e.toString()}'),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Icon(Icons.close, color: Colors.red.shade700, size: 16),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalQuotes = _statistics['total'] ?? 0;
    final openaiCount = _statistics['openai'] ?? 0;
    final geminiCount = _statistics['gemini'] ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage_rounded,
                color: theme.colorScheme.primary,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Data Management',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage Statistics',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  _buildStatRow('Favorite Quotes', '$_favoritesCount', theme),
                  _buildStatRow('AI Quotes Generated', '$totalQuotes', theme),
                  _buildStatRow('OpenAI Quotes', '$openaiCount', theme),
                  _buildStatRow('Gemini Quotes', '$geminiCount', theme),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _clearQuoteHistory,
                icon: const Icon(Icons.history),
                label: const Text('Clear Quote History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 6.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            SizedBox(height: 1.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _clearAllData,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear All Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 6.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
