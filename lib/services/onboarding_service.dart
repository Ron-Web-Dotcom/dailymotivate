import 'package:shared_preferences/shared_preferences.dart';

import './logger_service.dart';

/// Onboarding service to manage first-time user experience
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  static const String _onboardingCompleteKey = 'onboarding_completed';
  static const String _appVersionKey = 'onboarding_app_version';
  static const String _currentVersion = '1.0.0';

  bool _isOnboardingComplete = false;
  bool get isOnboardingComplete => _isOnboardingComplete;

  /// Initialize onboarding service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;

      // Check if app version changed (might need re-onboarding)
      final savedVersion = prefs.getString(_appVersionKey);
      if (savedVersion != _currentVersion) {
        // New version - could show "What's New" screen
        LoggerService.info(
          'App version changed',
          data: {'from': savedVersion, 'to': _currentVersion},
        );
      }

      LoggerService.info(
        'Onboarding service initialized',
        data: {'completed': _isOnboardingComplete},
      );
    } catch (e) {
      LoggerService.error('Failed to initialize onboarding service', error: e);
    }
  }

  /// Check if user needs onboarding
  Future<bool> shouldShowOnboarding() async {
    return !_isOnboardingComplete;
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
      await prefs.setString(_appVersionKey, _currentVersion);

      _isOnboardingComplete = true;

      LoggerService.info('Onboarding completed');
    } catch (e) {
      LoggerService.error('Failed to complete onboarding', error: e);
    }
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompleteKey);
      await prefs.remove(_appVersionKey);

      _isOnboardingComplete = false;

      LoggerService.info('Onboarding reset');
    } catch (e) {
      LoggerService.error('Failed to reset onboarding', error: e);
    }
  }

  /// Get onboarding steps
  List<OnboardingStep> getOnboardingSteps() {
    return [
      OnboardingStep(
        title: 'Welcome to DailyMotivate',
        description:
            'Get personalized AI-powered motivational quotes every day to inspire and uplift you.',
        icon: 'assets/images/img_app_logo.svg',
      ),
      OnboardingStep(
        title: 'Choose Your Categories',
        description:
            'Explore 20+ categories including Success, Happiness, Mindfulness, and more.',
        icon: 'category',
      ),
      OnboardingStep(
        title: 'Save Your Favorites',
        description:
            'Bookmark quotes that resonate with you and access them anytime, even offline.',
        icon: 'favorite',
      ),
      OnboardingStep(
        title: 'Daily Notifications',
        description:
            'Enable notifications to receive fresh motivation every day at your preferred time.',
        icon: 'notifications',
      ),
      OnboardingStep(
        title: 'Share Inspiration',
        description:
            'Spread positivity by sharing quotes with friends on social media and messaging apps.',
        icon: 'share',
      ),
    ];
  }
}

/// Onboarding step model
class OnboardingStep {
  final String title;
  final String description;
  final String icon;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}
