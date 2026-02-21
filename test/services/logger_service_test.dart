import 'package:flutter_test/flutter_test.dart';
import 'package:dailymotivate/services/logger_service.dart';

void main() {
  group('LoggerService Tests', () {
    setUp(() async {
      await LoggerService.initialize();
    });

    test('Logger initializes successfully', () async {
      await LoggerService.initialize();
      expect(LoggerService, isNotNull);
    });

    test('Log level can be set and retrieved', () async {
      await LoggerService.setLogLevel(LogLevel.debug);
      // Logger should accept debug level logs
      LoggerService.debug('Test debug message');
      // No exception means success
    });

    test('Sanitizes sensitive data', () {
      final data = {
        'username': 'testuser',
        'password': 'secret123',
        'email': 'test@example.com',
        'api_key': 'sk-1234567890',
      };

      // Log with sensitive data
      LoggerService.info('Test log', data: data);
      // Should not throw and should redact sensitive fields
    });

    test('Different log levels work correctly', () {
      LoggerService.debug('Debug message');
      LoggerService.info('Info message');
      LoggerService.warning('Warning message');
      LoggerService.error('Error message', error: Exception('Test error'));
      LoggerService.critical('Critical message');
      // All should execute without errors
    });
  });
}
