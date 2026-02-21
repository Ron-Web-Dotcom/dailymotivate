import 'package:flutter_test/flutter_test.dart';
import 'package:dailymotivate/services/onboarding_service.dart';

void main() {
  group('OnboardingService Tests', () {
    late OnboardingService onboardingService;

    setUp(() async {
      onboardingService = OnboardingService();
      await onboardingService.initialize();
      // Reset onboarding for each test
      await onboardingService.resetOnboarding();
    });

    test('Onboarding service initializes', () async {
      await onboardingService.initialize();
      expect(onboardingService, isNotNull);
    });

    test('Should show onboarding for first-time users', () async {
      final shouldShow = await onboardingService.shouldShowOnboarding();
      expect(shouldShow, isTrue);
    });

    test('Should not show onboarding after completion', () async {
      await onboardingService.completeOnboarding();
      final shouldShow = await onboardingService.shouldShowOnboarding();
      expect(shouldShow, isFalse);
    });

    test('Onboarding can be reset', () async {
      await onboardingService.completeOnboarding();
      await onboardingService.resetOnboarding();
      final shouldShow = await onboardingService.shouldShowOnboarding();
      expect(shouldShow, isTrue);
    });

    test('Returns correct onboarding steps', () {
      final steps = onboardingService.getOnboardingSteps();
      expect(steps, isNotEmpty);
      expect(steps.length, equals(5));
      expect(steps.first.title, contains('Welcome'));
    });
  });
}
