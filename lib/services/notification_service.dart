import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum NotificationFrequency { daily, weekly, weekdaysOnly, weekendsOnly }

enum NotificationPreset {
  custom,
  morningMotivation,
  middayBoost,
  eveningReflection,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionsGranted = false;

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    try {
      // Initialize timezone with proper error handling
      try {
        tz.initializeTimeZones();
        final locationName = tz.local.name;
        if (kDebugMode) {
          print('Timezone initialized: $locationName');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Timezone initialization error: $e');
        }
        // Fallback to UTC if local timezone fails
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(initSettings);

      // Create notification channel for Android
      await _createNotificationChannel();

      _initialized = true;

      if (kDebugMode) {
        print('NotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService initialization error: $e');
      }
    }
  }

  Future<void> _createNotificationChannel() async {
    if (kIsWeb) return;

    try {
      const androidChannel = AndroidNotificationChannel(
        'daily_motivation',
        'Daily Motivation',
        description: 'Daily motivational quote notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(androidChannel);
        if (kDebugMode) {
          print('Notification channel created successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating notification channel: $e');
      }
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    if (_permissionsGranted) return true;

    try {
      bool granted = false;

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        granted = await androidPlugin.requestNotificationsPermission() ?? false;
        if (kDebugMode) {
          print('Android notification permission: $granted');
        }
      }

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        granted =
            await iosPlugin.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        if (kDebugMode) {
          print('iOS notification permission: $granted');
        }
      }

      _permissionsGranted = granted;

      // Save permission status for UI
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_permission_granted', granted);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to save permission status: $e');
        }
      }

      return granted;
    } catch (e) {
      if (kDebugMode) {
        print('Permission request error: $e');
      }
      return false;
    }
  }

  Future<bool> scheduleNotificationWithFrequency({
    required int hour,
    required int minute,
    required NotificationFrequency frequency,
  }) async {
    if (kIsWeb || !_initialized) return false;

    try {
      await _notifications.cancelAll();

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      switch (frequency) {
        case NotificationFrequency.daily:
          return await _scheduleDailyNotification(hour, minute);

        case NotificationFrequency.weekly:
          return await _scheduleWeeklyNotification(hour, minute);

        case NotificationFrequency.weekdaysOnly:
          return await _scheduleWeekdaysNotification(hour, minute);

        case NotificationFrequency.weekendsOnly:
          return await _scheduleWeekendsNotification(hour, minute);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Schedule notification error: $e');
      }
      return false;
    }
  }

  Future<bool> _scheduleDailyNotification(int hour, int minute) async {
    try {
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      await _notifications.zonedSchedule(
        0,
        '💪 Daily Motivation',
        'Your daily dose of inspiration awaits!',
        tzScheduledDate,
        _getNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      if (kDebugMode) {
        print('Daily notification scheduled for: $tzScheduledDate');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Daily notification error: $e');
      }
      return false;
    }
  }

  Future<bool> _scheduleWeeklyNotification(int hour, int minute) async {
    try {
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      // Schedule for next Monday
      int daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
      if (daysUntilMonday == 0 && scheduledDate.isBefore(now)) {
        daysUntilMonday = 7;
      }

      scheduledDate = scheduledDate.add(Duration(days: daysUntilMonday));
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      await _notifications.zonedSchedule(
        1,
        '🌟 Weekly Motivation',
        'Start your week with powerful inspiration!',
        tzScheduledDate,
        _getNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      if (kDebugMode) {
        print('Weekly notification scheduled for: $tzScheduledDate');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Weekly notification error: $e');
      }
      return false;
    }
  }

  Future<bool> _scheduleWeekdaysNotification(int hour, int minute) async {
    try {
      final now = DateTime.now();
      final weekdays = [
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      ];

      // Schedule for each weekday
      for (int i = 0; i < weekdays.length; i++) {
        var scheduledDate = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
        int daysUntilWeekday = (weekdays[i] - now.weekday + 7) % 7;

        if (daysUntilWeekday == 0 && scheduledDate.isBefore(now)) {
          daysUntilWeekday = 7;
        }

        scheduledDate = scheduledDate.add(Duration(days: daysUntilWeekday));
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

        await _notifications.zonedSchedule(
          10 + i,
          '💼 Weekday Motivation',
          'Keep pushing! Your dedication makes a difference.',
          tzScheduledDate,
          _getNotificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }

      if (kDebugMode) {
        print('Weekdays notifications scheduled');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Weekdays notification error: $e');
      }
      return false;
    }
  }

  Future<bool> _scheduleWeekendsNotification(int hour, int minute) async {
    try {
      final now = DateTime.now();
      final weekends = [DateTime.saturday, DateTime.sunday];

      // Schedule for Saturday and Sunday
      for (int i = 0; i < weekends.length; i++) {
        var scheduledDate = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
        int daysUntilWeekend = (weekends[i] - now.weekday + 7) % 7;

        if (daysUntilWeekend == 0 && scheduledDate.isBefore(now)) {
          daysUntilWeekend = 7;
        }

        scheduledDate = scheduledDate.add(Duration(days: daysUntilWeekend));
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

        await _notifications.zonedSchedule(
          20 + i,
          '🌴 Weekend Inspiration',
          'Recharge and reflect with today\'s wisdom.',
          tzScheduledDate,
          _getNotificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }

      if (kDebugMode) {
        print('Weekends notifications scheduled');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Weekends notification error: $e');
      }
      return false;
    }
  }

  NotificationDetails _getNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_motivation',
        'Daily Motivation',
        channelDescription: 'Daily motivational quote notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // Deprecated - use scheduleNotificationWithFrequency instead
  @Deprecated('Use scheduleNotificationWithFrequency instead')
  Future<bool> scheduleDailyNotification(int hour, int minute) async {
    return await scheduleNotificationWithFrequency(
      hour: hour,
      minute: minute,
      frequency: NotificationFrequency.daily,
    );
  }

  Future<bool> sendTestNotification() async {
    if (kIsWeb || !_initialized) {
      if (kDebugMode) {
        print('Cannot send notification: Web platform or not initialized');
      }
      return false;
    }

    try {
      // Request permissions first
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        if (kDebugMode) {
          print('Test notification failed: Permission denied');
        }
        return false;
      }

      await _notifications.show(
        999,
        'Test Notification',
        'Daily reminders are working! You\'ll receive your quote at the scheduled time. 🎉',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_motivation',
            'Daily Motivation',
            channelDescription: 'Daily motivational quote notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      if (kDebugMode) {
        print('Test notification sent successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Test notification error: $e');
      }
      return false;
    }
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb || !_initialized) return;

    try {
      await _notifications.cancelAll();
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> syncWithSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notifications_enabled') ?? true;
      final hour = prefs.getInt('notification_hour') ?? 9;
      final minute = prefs.getInt('notification_minute') ?? 0;
      final frequencyString =
          prefs.getString('notification_frequency') ?? 'daily';

      final frequency = NotificationFrequency.values.firstWhere(
        (e) => e.toString().split('.').last == frequencyString,
        orElse: () => NotificationFrequency.daily,
      );

      if (kDebugMode) {
        print(
          'Syncing notifications: enabled=$enabled, time=$hour:$minute, frequency=$frequency',
        );
      }

      if (enabled) {
        await requestPermissions();
        await scheduleNotificationWithFrequency(
          hour: hour,
          minute: minute,
          frequency: frequency,
        );
      } else {
        await cancelAllNotifications();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sync settings error: $e');
      }
    }
  }

  static TimeOfDay getPresetTime(NotificationPreset preset) {
    switch (preset) {
      case NotificationPreset.morningMotivation:
        return const TimeOfDay(hour: 7, minute: 30);
      case NotificationPreset.middayBoost:
        return const TimeOfDay(hour: 12, minute: 0);
      case NotificationPreset.eveningReflection:
        return const TimeOfDay(hour: 19, minute: 0);
      case NotificationPreset.custom:
        return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  static String getPresetLabel(NotificationPreset preset) {
    switch (preset) {
      case NotificationPreset.morningMotivation:
        return 'Morning Motivation (7:30 AM)';
      case NotificationPreset.middayBoost:
        return 'Midday Boost (12:00 PM)';
      case NotificationPreset.eveningReflection:
        return 'Evening Reflection (7:00 PM)';
      case NotificationPreset.custom:
        return 'Custom Time';
    }
  }

  static String getFrequencyLabel(NotificationFrequency frequency) {
    switch (frequency) {
      case NotificationFrequency.daily:
        return 'Daily';
      case NotificationFrequency.weekly:
        return 'Weekly (Mondays)';
      case NotificationFrequency.weekdaysOnly:
        return 'Weekdays Only';
      case NotificationFrequency.weekendsOnly:
        return 'Weekends Only';
    }
  }

  static String getFrequencyDescription(NotificationFrequency frequency) {
    switch (frequency) {
      case NotificationFrequency.daily:
        return 'Receive motivation every day';
      case NotificationFrequency.weekly:
        return 'Start each week with inspiration';
      case NotificationFrequency.weekdaysOnly:
        return 'Monday to Friday motivation';
      case NotificationFrequency.weekendsOnly:
        return 'Saturday and Sunday inspiration';
    }
  }
}
