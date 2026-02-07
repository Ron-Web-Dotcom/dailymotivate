import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Enhanced widget for managing notification settings with frequency and preset options
class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({super.key});

  @override
  State<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends State<NotificationSettingsWidget> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  NotificationFrequency _selectedFrequency = NotificationFrequency.daily;
  NotificationPreset _selectedPreset = NotificationPreset.custom;
  bool _isLoading = true;
  bool _isSendingTest = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      final hour = prefs.getInt('notification_hour') ?? 9;
      final minute = prefs.getInt('notification_minute') ?? 0;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);

      final frequencyString =
          prefs.getString('notification_frequency') ?? 'daily';
      _selectedFrequency = NotificationFrequency.values.firstWhere(
        (e) => e.toString().split('.').last == frequencyString,
        orElse: () => NotificationFrequency.daily,
      );

      final presetString = prefs.getString('notification_preset') ?? 'custom';
      _selectedPreset = NotificationPreset.values.firstWhere(
        (e) => e.toString().split('.').last == presetString,
        orElse: () => NotificationPreset.custom,
      );

      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setInt('notification_hour', _selectedTime.hour);
    await prefs.setInt('notification_minute', _selectedTime.minute);
    await prefs.setString(
      'notification_frequency',
      _selectedFrequency.toString().split('.').last,
    );
    await prefs.setString(
      'notification_preset',
      _selectedPreset.toString().split('.').last,
    );

    if (_notificationsEnabled) {
      final permissionGranted = await _notificationService.requestPermissions();
      if (!permissionGranted) {
        setState(() {
          _statusMessage =
              'Permission denied. Please enable notifications in settings.';
          _notificationsEnabled = false;
        });
        await prefs.setBool('notifications_enabled', false);
        return;
      }

      final scheduled = await _notificationService
          .scheduleNotificationWithFrequency(
            hour: _selectedTime.hour,
            minute: _selectedTime.minute,
            frequency: _selectedFrequency,
          );

      if (scheduled) {
        setState(() {
          _statusMessage =
              '${NotificationService.getFrequencyLabel(_selectedFrequency)} reminder set for ${_formatTime(_selectedTime)}';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _statusMessage = null;
            });
          }
        });
      }
    } else {
      await _notificationService.cancelAllNotifications();
      setState(() {
        _statusMessage = 'Notifications disabled';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _statusMessage = null;
          });
        }
      });
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isSendingTest = true;
      _statusMessage = null;
    });

    try {
      final success = await _notificationService.sendTestNotification();

      if (success) {
        setState(() {
          _statusMessage =
              'Test notification sent! Check your notification tray. 🎉';
          _isSendingTest = false;
        });
      } else {
        setState(() {
          _statusMessage =
              'Failed to send notification. Please enable notification permissions in your device settings.';
          _isSendingTest = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error sending notification. Please try again.';
        _isSendingTest = false;
      });
    }

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _statusMessage = null;
        });
      }
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: theme.colorScheme.surface,
              hourMinuteTextColor: theme.colorScheme.primary,
              dayPeriodTextColor: theme.colorScheme.primary,
              dialHandColor: theme.colorScheme.primary,
              dialBackgroundColor: theme.colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _selectedPreset = NotificationPreset.custom;
      });
      await _saveSettings();
    }
  }

  void _selectPreset(NotificationPreset preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset != NotificationPreset.custom) {
        _selectedTime = NotificationService.getPresetTime(preset);
      }
    });
    _saveSettings();
  }

  void _selectFrequency(NotificationFrequency frequency) {
    setState(() {
      _selectedFrequency = frequency;
    });
    _saveSettings();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(4.w),
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Schedule',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable Notifications',
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Get motivational quotes regularly',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _notificationsEnabled,
                onChanged: (value) async {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  await _saveSettings();
                },
              ),
            ],
          ),
          if (_statusMessage != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_notificationsEnabled) ...[
            SizedBox(height: 2.h),
            Divider(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              height: 1,
            ),
            SizedBox(height: 2.h),
            Text(
              'Frequency',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            ...NotificationFrequency.values.map((frequency) {
              final isSelected = _selectedFrequency == frequency;
              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: InkWell(
                  onTap: () => _selectFrequency(frequency),
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                NotificationService.getFrequencyLabel(
                                  frequency,
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 0.3.h),
                              Text(
                                NotificationService.getFrequencyDescription(
                                  frequency,
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isSelected
                                      ? theme.colorScheme.onPrimaryContainer
                                            .withValues(alpha: 0.8)
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 2.h),
            Divider(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              height: 1,
            ),
            SizedBox(height: 2.h),
            Text(
              'Time Preset',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children:
                  [
                    NotificationPreset.morningMotivation,
                    NotificationPreset.middayBoost,
                    NotificationPreset.eveningReflection,
                  ].map((preset) {
                    final isSelected = _selectedPreset == preset;
                    return InkWell(
                      onTap: () => _selectPreset(preset),
                      borderRadius: BorderRadius.circular(20.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surface,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          NotificationService.getPresetLabel(preset),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            SizedBox(height: 2.h),
            InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedPreset == NotificationPreset.custom
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: _selectedPreset == NotificationPreset.custom ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Custom Time', style: theme.textTheme.bodyMedium),
                        SizedBox(height: 0.5.h),
                        Text(
                          _formatTime(_selectedTime),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    CustomIconWidget(
                      iconName: 'access_time',
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSendingTest ? null : _sendTestNotification,
                icon: _isSendingTest
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : Icon(Icons.notifications_active, size: 20),
                label: Text(
                  _isSendingTest ? 'Sending...' : 'Send Test Notification',
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  side: BorderSide(
                    color: _isSendingTest
                        ? theme.colorScheme.outline
                        : theme.colorScheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
