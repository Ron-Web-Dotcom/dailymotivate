import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sizer/sizer.dart';

import './presentation/splash_screen/splash_screen.dart';
import './services/cloud_sync_service.dart';
import './services/notification_service.dart';
import './services/supabase_service.dart';
import './services/theme_service.dart';
import './services/logger_service.dart';
import './services/connectivity_service.dart';
import './services/performance_service.dart';
import './services/onboarding_service.dart';
import './services/crash_reporting_service.dart';
import './core/app_export.dart';
import './core/state_restoration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize performance monitoring
  PerformanceService().initialize();

  // Initialize logger
  await LoggerService.initialize();
  LoggerService.info('App starting...');

  // Initialize Firebase for crash reporting
  try {
    await Firebase.initializeApp();
    await CrashReportingService().initialize();
    LoggerService.info('Firebase and crash reporting initialized');
  } catch (e) {
    LoggerService.error('Firebase initialization failed', error: e);
  }

  // Initialize connectivity monitoring
  await ConnectivityService().initialize();

  // Initialize Supabase with error handling
  try {
    await SupabaseService.initialize();
    LoggerService.info('Supabase initialized successfully');
  } catch (e) {
    LoggerService.error('Supabase initialization failed', error: e);
    // App continues without cloud sync - local features still work
  }

  // Initialize theme with error handling
  try {
    await ThemeService().initialize();
    LoggerService.info('Theme service initialized successfully');
  } catch (e) {
    LoggerService.error('Theme initialization failed', error: e);
    // App continues with default theme
  }

  // Initialize notifications with error handling
  try {
    await NotificationService().initialize();
    LoggerService.info('Notification service initialized successfully');
  } catch (e) {
    LoggerService.error('Notification initialization failed', error: e);
    // App continues without notifications
  }

  // Initialize onboarding service
  try {
    await OnboardingService().initialize();
    LoggerService.info('Onboarding service initialized successfully');
  } catch (e) {
    LoggerService.error('Onboarding initialization failed', error: e);
  }

  // Initialize cloud sync only if authenticated
  try {
    if (CloudSyncService.instance.isAuthenticated) {
      await CloudSyncService.instance.initializeRealtimeSync();
      LoggerService.info('Cloud sync initialized successfully');
    }
  } catch (e) {
    LoggerService.error('Cloud sync initialization failed', error: e);
    // App continues without real-time sync
  }

  // Record app launch completion
  PerformanceService().recordAppLaunch();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return AppLifecycleManager(
          child: AnimatedBuilder(
            animation: ThemeService(),
            builder: (context, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Daily Motivate',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: ThemeService().themeMode,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(1.0)),
                    child: child!,
                  );
                },
                home: const SplashScreen(),
                routes: AppRoutes.routes,
              );
            },
          ),
        );
      },
    );
  }
}
