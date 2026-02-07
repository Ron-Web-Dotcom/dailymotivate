import 'package:dio/dio.dart';

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  late final Dio _dio;
  static const String apiKey = String.fromEnvironment('OPENAI_API_KEY');
  bool _isInitialized = false;

  factory OpenAIService() {
    return _instance;
  }

  OpenAIService._internal() {
    _initializeService();
  }

  void _initializeService() {
    if (apiKey.isEmpty) {
      _isInitialized = false;
      // Create a dummy Dio instance to prevent null errors
      _dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.openai.com/v1',
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return;
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    _isInitialized = true;
  }

  Dio get dio {
    if (!_isInitialized) {
      throw Exception(
        'OpenAI API key not configured. Please add OPENAI_API_KEY to environment variables.',
      );
    }
    return _dio;
  }

  bool get isConfigured => _isInitialized;
}
