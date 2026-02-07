import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import './quote_buffer_service.dart';
import './ai_quote_service.dart';
import 'dart:math';

class DailyQuoteService {
  static final DailyQuoteService _instance = DailyQuoteService._internal();
  factory DailyQuoteService() => _instance;
  DailyQuoteService._internal();

  final QuoteBufferService _bufferService = QuoteBufferService();
  final AIQuoteService _aiQuoteService = AIQuoteService();
  final Random _random = Random();

  static const String _dailyQuoteKey = 'daily_quote';
  static const String _lastQuoteDateKey = 'last_quote_date';
  static const String _dailyQuoteSetKey = 'daily_quote_set';
  static const int _quotesPerDay = 10;

  /// Fallback quotes when AI generation fails
  final List<Map<String, dynamic>> _fallbackQuotes = [
    {
      'id': 1,
      'text':
          'Success is not final, failure is not fatal: it is the courage to continue that counts.',
      'author': 'Winston Churchill',
      'category': 'Success',
    },
    {
      'id': 2,
      'text': 'The only way to do great work is to love what you do.',
      'author': 'Steve Jobs',
      'category': 'Success',
    },
    {
      'id': 3,
      'text': 'Discipline is the bridge between goals and accomplishment.',
      'author': 'Jim Rohn',
      'category': 'Discipline',
    },
    {
      'id': 4,
      'text':
          'Happiness is not something ready made. It comes from your own actions.',
      'author': 'Dalai Lama',
      'category': 'Happiness',
    },
    {
      'id': 5,
      'text': 'Take care of your body. It\'s the only place you have to live.',
      'author': 'Jim Rohn',
      'category': 'Fitness',
    },
    {
      'id': 6,
      'text':
          'Education is the most powerful weapon which you can use to change the world.',
      'author': 'Nelson Mandela',
      'category': 'Study',
    },
    {
      'id': 7,
      'text':
          'The future belongs to those who believe in the beauty of their dreams.',
      'author': 'Eleanor Roosevelt',
      'category': 'Motivation',
    },
    {
      'id': 8,
      'text':
          'It does not matter how slowly you go as long as you do not stop.',
      'author': 'Confucius',
      'category': 'Resilience',
    },
    {
      'id': 9,
      'text':
          'The present moment is the only time over which we have dominion.',
      'author': 'Thích Nhất Hạnh',
      'category': 'Mindfulness',
    },
    {
      'id': 10,
      'text':
          'Leadership is not about being in charge. It is about taking care of those in your charge.',
      'author': 'Simon Sinek',
      'category': 'Leadership',
    },
  ];

  /// Get today's date in YYYY-MM-DD format
  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Check if we need a new quote (new day)
  Future<bool> _needsNewQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastQuoteDateKey);
    final todayDate = _getTodayDate();

    return lastDate != todayDate;
  }

  /// Get diverse categories for daily variety
  List<String> _getDailyCategories() {
    final allCategories = [
      'Success',
      'Discipline',
      'Happiness',
      'Fitness',
      'Study',
      'Motivation',
      'Resilience',
      'Mindfulness',
      'Leadership',
      'Creativity',
    ];

    // Shuffle and take a subset for variety
    final shuffled = List<String>.from(allCategories)..shuffle(_random);
    return shuffled.take(_quotesPerDay).toList();
  }

  /// Generate a fresh set of quotes for the day
  Future<List<Map<String, dynamic>>> _generateDailyQuoteSet() async {
    final categories = _getDailyCategories();
    final quotes = <Map<String, dynamic>>[];
    final prefs = await SharedPreferences.getInstance();
    final tone = prefs.getString('ai_tone') ?? 'inspirational';
    final enablePersonalization = prefs.getBool('ai_personalization') ?? false;
    final userName = enablePersonalization
        ? prefs.getString('user_name')
        : null;

    // Try AI generation first
    bool aiGenerationFailed = false;
    for (final category in categories) {
      try {
        final quote = await _aiQuoteService.generateQuote(
          category: category,
          tone: tone,
          userName: userName,
          requireHighQuality: true,
        );
        quotes.add(quote);
      } catch (e) {
        aiGenerationFailed = true;
        // Skip failed generation, will use fallback
        break;
      }
    }

    // If AI generation failed or didn't produce enough quotes, use fallback
    if (aiGenerationFailed || quotes.isEmpty) {
      return List<Map<String, dynamic>>.from(_fallbackQuotes)..shuffle(_random);
    }

    // If we didn't get enough quotes, fill from buffer or fallback
    while (quotes.length < _quotesPerDay) {
      final bufferQuote = await _bufferService.getNextQuote();
      if (bufferQuote != null) {
        quotes.add(bufferQuote);
      } else {
        // Use fallback quotes
        final remainingFallback = _fallbackQuotes
            .where((fb) => !quotes.any((q) => q['id'] == fb['id']))
            .toList();
        if (remainingFallback.isNotEmpty) {
          quotes.add(
            remainingFallback[_random.nextInt(remainingFallback.length)],
          );
        } else {
          break;
        }
      }
    }

    return quotes;
  }

  /// Get the daily quote - returns cached if same day, generates new if different day
  Future<Map<String, dynamic>> getDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      if (await _needsNewQuote()) {
        await _bufferService.initialize();
        final quoteSet = await _generateDailyQuoteSet();

        if (quoteSet.isNotEmpty) {
          await _saveDailyQuoteSet(quoteSet);
          return quoteSet.first;
        } else {
          return _getRandomFallbackQuote();
        }
      } else {
        final cachedQuoteJson = prefs.getString(_dailyQuoteKey);
        if (cachedQuoteJson != null) {
          return json.decode(cachedQuoteJson) as Map<String, dynamic>;
        } else {
          await _bufferService.initialize();
          final quoteSet = await _generateDailyQuoteSet();
          if (quoteSet.isNotEmpty) {
            await _saveDailyQuoteSet(quoteSet);
            return quoteSet.first;
          } else {
            return _getRandomFallbackQuote();
          }
        }
      }
    } catch (e) {
      // Return fallback quote on any error
      return _getRandomFallbackQuote();
    }
  }

  /// Get the full daily quote set for variety
  Future<List<Map<String, dynamic>>> getDailyQuoteSet() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      if (await _needsNewQuote()) {
        await _bufferService.initialize();
        final quoteSet = await _generateDailyQuoteSet();
        if (quoteSet.isNotEmpty) {
          await _saveDailyQuoteSet(quoteSet);
          return quoteSet;
        }
        return List<Map<String, dynamic>>.from(_fallbackQuotes);
      } else {
        final cachedSetJson = prefs.getString(_dailyQuoteSetKey);
        if (cachedSetJson != null) {
          final List<dynamic> decoded = json.decode(cachedSetJson);
          return decoded.map((item) => item as Map<String, dynamic>).toList();
        } else {
          await _bufferService.initialize();
          final quoteSet = await _generateDailyQuoteSet();
          if (quoteSet.isNotEmpty) {
            await _saveDailyQuoteSet(quoteSet);
            return quoteSet;
          }
          return List<Map<String, dynamic>>.from(_fallbackQuotes);
        }
      }
    } catch (e) {
      return List<Map<String, dynamic>>.from(_fallbackQuotes);
    }
  }

  /// Save daily quote set to SharedPreferences
  Future<void> _saveDailyQuoteSet(List<Map<String, dynamic>> quoteSet) async {
    final prefs = await SharedPreferences.getInstance();
    final setJson = json.encode(quoteSet);
    final todayDate = _getTodayDate();

    // Save the full set
    await prefs.setString(_dailyQuoteSetKey, setJson);
    // Save the first quote as the main daily quote
    await prefs.setString(_dailyQuoteKey, json.encode(quoteSet.first));
    await prefs.setString(_lastQuoteDateKey, todayDate);
  }

  Map<String, dynamic> _getRandomFallbackQuote() {
    return _fallbackQuotes[_random.nextInt(_fallbackQuotes.length)];
  }

  /// Force refresh daily quote (for manual refresh)
  Future<Map<String, dynamic>> refreshDailyQuote() async {
    try {
      await _bufferService.initialize();
      final quoteSet = await _generateDailyQuoteSet();

      if (quoteSet.isNotEmpty) {
        await _saveDailyQuoteSet(quoteSet);
        return quoteSet.first;
      } else {
        return _getRandomFallbackQuote();
      }
    } catch (e) {
      return _getRandomFallbackQuote();
    }
  }

  /// Clear daily quote cache (for testing)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dailyQuoteKey);
    await prefs.remove(_lastQuoteDateKey);
    await prefs.remove(_dailyQuoteSetKey);
  }
}
