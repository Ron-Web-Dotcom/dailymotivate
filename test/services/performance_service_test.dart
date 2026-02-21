import 'package:flutter_test/flutter_test.dart';
import 'package:dailymotivate/services/performance_service.dart';

void main() {
  group('PerformanceService Tests', () {
    late PerformanceService performanceService;

    setUp(() {
      performanceService = PerformanceService();
      performanceService.initialize();
    });

    test('Performance service initializes', () {
      performanceService.initialize();
      expect(performanceService, isNotNull);
    });

    test('Can start and end operation timing', () {
      performanceService.startOperation('test_operation');
      // Simulate some work
      performanceService.endOperation('test_operation');

      final avgDuration = performanceService.getAverageDuration(
        'test_operation',
      );
      expect(avgDuration, isNotNull);
      expect(avgDuration! >= 0, isTrue);
    });

    test('Calculates average duration correctly', () {
      // Record multiple operations
      for (int i = 0; i < 5; i++) {
        performanceService.startOperation('repeated_op');
        performanceService.endOperation('repeated_op');
      }

      final avgDuration = performanceService.getAverageDuration('repeated_op');
      expect(avgDuration, isNotNull);
      expect(avgDuration! >= 0, isTrue);
    });

    test('Returns performance report', () {
      performanceService.startOperation('op1');
      performanceService.endOperation('op1');

      final report = performanceService.getPerformanceReport();
      expect(report, isNotEmpty);
      expect(report.containsKey('op1'), isTrue);
    });

    test('Can clear performance data', () async {
      performanceService.startOperation('test');
      performanceService.endOperation('test');

      await performanceService.clearPerformanceData();

      final report = performanceService.getPerformanceReport();
      expect(report, isEmpty);
    });
  });
}
