import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuoteHistoryService {
  static final QuoteHistoryService _instance = QuoteHistoryService._internal();
  static const String _historyKey = 'quote_history';
  static const int _maxHistorySize = 500;

  factory QuoteHistoryService() => _instance;

  QuoteHistoryService._internal();

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      return historyJson
          .map((item) => json.decode(item) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addQuote(Map<String, dynamic> quote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();

      final quoteEntry = {
        'text': quote['text'],
        'author': quote['author'],
        'category': quote['category'],
        'timestamp': DateTime.now().toIso8601String(),
        'source': quote['source'] ?? 'unknown',
      };

      history.insert(0, quoteEntry);

      if (history.length > _maxHistorySize) {
        history.removeRange(_maxHistorySize, history.length);
      }

      final historyJson = history.map((item) => json.encode(item)).toList();
      await prefs.setStringList(_historyKey, historyJson);
    } catch (e) {
      // Silent fail - don't block quote generation
    }
  }

  Future<bool> isDuplicate(String quoteText) async {
    try {
      final history = await getHistory();
      final normalizedNew = _normalizeText(quoteText);

      for (final entry in history) {
        final normalizedExisting = _normalizeText(entry['text'] as String);
        if (normalizedExisting == normalizedNew) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isSimilar(String quoteText, {double threshold = 0.85}) async {
    try {
      final history = await getHistory();
      final normalizedNew = _normalizeText(quoteText);

      for (final entry in history) {
        final normalizedExisting = _normalizeText(entry['text'] as String);
        final similarity = _calculateSimilarity(
          normalizedNew,
          normalizedExisting,
        );

        if (similarity >= threshold) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _calculateSimilarity(String text1, String text2) {
    final words1 = text1.split(' ').toSet();
    final words2 = text2.split(' ').toSet();

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;

    return intersection / union;
  }

  Future<List<String>> getRecentQuoteTexts({int count = 50}) async {
    try {
      final history = await getHistory();
      return history
          .take(count)
          .map((entry) => entry['text'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      // Silent fail
    }
  }

  Future<Map<String, int>> getStatistics() async {
    try {
      final history = await getHistory();
      final categories = <String, int>{};
      final sources = <String, int>{};

      for (final entry in history) {
        final category = entry['category'] as String? ?? 'Unknown';
        final source = entry['source'] as String? ?? 'unknown';

        categories[category] = (categories[category] ?? 0) + 1;
        sources[source] = (sources[source] ?? 0) + 1;
      }

      return {
        'total': history.length,
        'openai': sources['openai'] ?? 0,
        'gemini': sources['gemini'] ?? 0,
        ...categories.map((key, value) => MapEntry('category_$key', value)),
      };
    } catch (e) {
      return {'total': 0};
    }
  }
}
