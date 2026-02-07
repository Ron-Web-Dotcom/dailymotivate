import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './presentation/splash_screen/splash_screen.dart';
import './routes/app_routes.dart';
import './services/cloud_sync_service.dart';
import './services/notification_service.dart';
import './services/supabase_service.dart';
import './services/theme_service.dart';
import './theme/app_theme.dart';
import 'core/app_export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with error handling
  try {
    await SupabaseService.initialize();
    if (kDebugMode) {
      print('Supabase initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Supabase initialization failed: $e');
    }
    // App continues without cloud sync - local features still work
  }

  // Initialize theme with error handling
  try {
    await ThemeService().initialize();
    if (kDebugMode) {
      print('Theme service initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Theme initialization failed: $e');
    }
    // App continues with default theme
  }

  // Initialize notifications with error handling
  try {
    await NotificationService().initialize();
    if (kDebugMode) {
      print('Notification service initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Notification initialization failed: $e');
    }
    // App continues without notifications
  }

  // Initialize cloud sync only if authenticated
  try {
    if (CloudSyncService.instance.isAuthenticated) {
      await CloudSyncService.instance.initializeRealtimeSync();
      if (kDebugMode) {
        print('Cloud sync initialized successfully');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Cloud sync initialization failed: $e');
    }
    // App continues without real-time sync
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return AnimatedBuilder(
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
        );
      },
    );
  }
}
