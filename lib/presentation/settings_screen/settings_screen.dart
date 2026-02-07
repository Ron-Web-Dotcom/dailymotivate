import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/cloud_sync_service.dart';
import './widgets/about_section_widget.dart';
import './widgets/ai_preferences_widget.dart';
import './widgets/data_management_widget.dart';
import './widgets/notification_settings_widget.dart';
import './widgets/theme_settings_widget.dart';

/// Settings Screen for app personalization and configuration
/// Accessed via bottom tab bar navigation
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final bool _isLoading = false;
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = CloudSyncService.instance.isAuthenticated;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        children: [
          // Cloud Sync Status Card (only show when authenticated)
          if (isAuthenticated) ...[
            _buildCloudSyncCard(),
            SizedBox(height: 2.h),
          ],

          // Existing settings widgets
          const ThemeSettingsWidget(),
          SizedBox(height: 2.h),
          const NotificationSettingsWidget(),
          SizedBox(height: 2.h),
          const AIPreferencesWidget(),
          SizedBox(height: 2.h),
          const DataManagementWidget(),
          SizedBox(height: 2.h),
          const AboutSectionWidget(),
        ],
      ),
    );
  }

  Widget _buildCloudSyncCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.green, size: 6.w),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cloud Sync Active',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Your favorites and settings are automatically backed up',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _syncNow,
                    icon: _isSyncing
                        ? SizedBox(
                            width: 4.w,
                            height: 4.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.sync),
                    label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Real-time sync: All changes are automatically saved to cloud',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);

    try {
      // Sync favorites
      await CloudSyncService.instance.syncFavoritesFromCloud();

      // Sync settings
      await CloudSyncService.instance.syncSettingsFromCloud();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }
}
