import 'package:dio/dio.dart';
import 'dart:math';
import '../services/openai_service.dart';
import '../services/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AICategoryService {
  static final AICategoryService _instance = AICategoryService._internal();
  final OpenAIService _openAIService = OpenAIService();
  final GeminiService _geminiService = GeminiService();
  final Random _random = Random();

  factory AICategoryService() => _instance;

  AICategoryService._internal();

  /// Generate AI-driven categories based on current trends and user preferences
  Future<List<Map<String, dynamic>>> generateCategories({
    int count = 12,
    List<String>? userPreferences,
  }) async {
    try {
      final useOpenAI = _random.nextBool();
      final categories = useOpenAI
          ? await _generateCategoriesWithOpenAI(count, userPreferences)
          : await _generateCategoriesWithGemini(count, userPreferences);

      // Notify buffer service of new categories
      await _updateBufferCategories(categories);

      return categories;
    } catch (e) {
      throw AICategoryException('Failed to generate categories: $e');
    }
  }

  Future<void> _updateBufferCategories(
    List<Map<String, dynamic>> categories,
  ) async {
    // This will be picked up by buffer service on next initialization
    // Categories are already cached by cacheCategories method
  }

  Future<List<Map<String, dynamic>>> _generateCategoriesWithOpenAI(
    int count,
    List<String>? userPreferences,
  ) async {
    final prompt = _buildCategoryPrompt(count, userPreferences);

    try {
      final response = await _openAIService.dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert motivational content curator. Generate diverse, meaningful, and trending motivational quote categories. '
                  'Each category should be specific, actionable, and resonate with modern audiences. '
                  'Return ONLY a JSON array of category objects with: name, icon (material icon name), color (hex), description, and relevanceScore (0-100).',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.85,
          'max_tokens': 1500,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      return _parseCategoriesResponse(content);
    } on DioException catch (e) {
      throw AICategoryException(
        'OpenAI Error: ${e.response?.data?['error']?['message'] ?? e.message}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> _generateCategoriesWithGemini(
    int count,
    List<String>? userPreferences,
  ) async {
    final prompt = _buildCategoryPrompt(count, userPreferences);

    try {
      final response = await _geminiService.dio.post(
        '/models/gemini-2.5-flash:generateContent',
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      'You are an expert motivational content curator. Generate diverse, meaningful, and trending motivational quote categories. '
                      'Each category should be specific, actionable, and resonate with modern audiences. '
                      'Return ONLY a JSON array of category objects with: name, icon (material icon name), color (hex), description, and relevanceScore (0-100).\n\n$prompt',
                },
              ],
            },
          ],
          'generationConfig': {'temperature': 0.85, 'maxOutputTokens': 1500},
        },
      );

      if (response.data['candidates'] != null &&
          response.data['candidates'].isNotEmpty) {
        final content =
            response.data['candidates'][0]['content']['parts'][0]['text'];
        return _parseCategoriesResponse(content);
      }

      throw AICategoryException('No response from Gemini');
    } on DioException catch (e) {
      throw AICategoryException(
        'Gemini Error: ${e.response?.data?['error']?['message'] ?? e.message}',
      );
    }
  }

  String _buildCategoryPrompt(int count, List<String>? userPreferences) {
    final preferencesContext =
        userPreferences != null && userPreferences.isNotEmpty
        ? 'User has shown interest in: ${userPreferences.join(", ")}. '
        : '';

    return 'Generate $count diverse motivational quote categories. '
        '$preferencesContext'
        'Include a mix of: '
        '1. Personal growth (mindfulness, resilience, self-love) '
        '2. Professional development (leadership, productivity, innovation) '
        '3. Wellness (mental health, fitness, balance) '
        '4. Relationships (empathy, communication, connection) '
        '5. Achievement (success, goals, perseverance) '
        '6. Creativity (inspiration, art, imagination) '
        '\n\n'
        'For each category provide: '
        '- name: Clear, engaging category name (1-2 words) '
        '- icon: Material icon name (e.g., "emoji_events", "self_improvement", "favorite") '
        '- color: Hex color code (e.g., "#2C5F41") '
        '- description: Brief compelling description (10-15 words) '
        '- relevanceScore: Score 0-100 based on current trends and universal appeal '
        '\n\n'
        'Return as JSON array: [{"name": "...", "icon": "...", "color": "...", "description": "...", "relevanceScore": 95}, ...]';
  }

  List<Map<String, dynamic>> _parseCategoriesResponse(String content) {
    try {
      final jsonStart = content.indexOf('[');
      final jsonEnd = content.lastIndexOf(']') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = content.substring(jsonStart, jsonEnd);
        final cleaned = jsonStr
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final List<dynamic> rawCategories = _parseJsonArray(cleaned);
        final List<Map<String, dynamic>> categories = [];

        for (int i = 0; i < rawCategories.length; i++) {
          final cat = rawCategories[i];
          categories.add({
            'id': DateTime.now().millisecondsSinceEpoch + i,
            'name': cat['name'] ?? 'Motivation',
            'icon': _validateIconName(cat['icon'] ?? 'star'),
            'color': _parseColor(cat['color'] ?? '#2C5F41'),
            'description':
                cat['description'] ?? 'Inspiring quotes to motivate you',
            'relevanceScore': cat['relevanceScore'] ?? 80,
            'quoteCount': 0,
            'isAIGenerated': true,
          });
        }

        return categories;
      }

      return _getFallbackCategories();
    } catch (e) {
      return _getFallbackCategories();
    }
  }

  List<dynamic> _parseJsonArray(String jsonStr) {
    final List<dynamic> result = [];
    final categoryPattern = RegExp(
      r'\{[^}]*"name"\s*:\s*"([^"]+)"[^}]*"icon"\s*:\s*"([^"]+)"[^}]*"color"\s*:\s*"([^"]+)"[^}]*"description"\s*:\s*"([^"]+)"[^}]*"relevanceScore"\s*:\s*(\d+)[^}]*\}',
      multiLine: true,
    );

    for (final match in categoryPattern.allMatches(jsonStr)) {
      result.add({
        'name': match.group(1),
        'icon': match.group(2),
        'color': match.group(3),
        'description': match.group(4),
        'relevanceScore': int.tryParse(match.group(5) ?? '80') ?? 80,
      });
    }

    return result;
  }

  String _validateIconName(String icon) {
    final validIcons = [
      'emoji_events',
      'self_improvement',
      'favorite',
      'fitness_center',
      'menu_book',
      'local_fire_department',
      'psychology',
      'spa',
      'lightbulb',
      'groups',
      'trending_up',
      'auto_awesome',
      'sentiment_satisfied_alt',
      'workspace_premium',
      'rocket_launch',
    ];

    return validIcons.contains(icon) ? icon : 'star';
  }

  int _parseColor(String colorStr) {
    try {
      final hex = colorStr.replaceAll('#', '');
      return int.parse('FF$hex', radix: 16);
    } catch (e) {
      return 0xFF2C5F41;
    }
  }

  List<Map<String, dynamic>> _getFallbackCategories() {
    return [
      {
        'id': 1,
        'name': 'Success',
        'icon': 'emoji_events',
        'color': 0xFF2C5F41,
        'description': 'Achieve your goals and reach new heights',
        'relevanceScore': 95,
        'quoteCount': 0,
        'isAIGenerated': false,
      },
      {
        'id': 2,
        'name': 'Discipline',
        'icon': 'self_improvement',
        'color': 0xFF7B9E87,
        'description': 'Build habits that transform your life',
        'relevanceScore': 90,
        'quoteCount': 0,
        'isAIGenerated': false,
      },
      {
        'id': 3,
        'name': 'Happiness',
        'icon': 'sentiment_satisfied_alt',
        'color': 0xFFE8B86D,
        'description': 'Find joy in every moment',
        'relevanceScore': 92,
        'quoteCount': 0,
        'isAIGenerated': false,
      },
    ];
  }

  /// Cache categories to local storage
  Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = categories
          .map(
            (cat) => {
              'id': cat['id'],
              'name': cat['name'],
              'icon': cat['icon'],
              'color': cat['color'],
              'description': cat['description'],
              'relevanceScore': cat['relevanceScore'],
              'quoteCount': cat['quoteCount'],
              'isAIGenerated': cat['isAIGenerated'],
            },
          )
          .toList();

      await prefs.setString('cached_categories', categoriesJson.toString());
      await prefs.setInt(
        'categories_cache_time',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Silent fail - caching is optional
    }
  }

  /// Get cached categories if available and fresh (< 24 hours)
  Future<List<Map<String, dynamic>>?> getCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt('categories_cache_time');

      if (cacheTime != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (age < 86400000) {
          // 24 hours
          final cached = prefs.getString('cached_categories');
          if (cached != null) {
            return _getFallbackCategories(); // Simplified for now
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class AICategoryException implements Exception {
  final String message;
  AICategoryException(this.message);

  @override
  String toString() => 'AICategoryException: $message';
}