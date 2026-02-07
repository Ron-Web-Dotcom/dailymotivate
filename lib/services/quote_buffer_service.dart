import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import './ai_quote_service.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class QuoteBufferService {
  static final QuoteBufferService _instance = QuoteBufferService._internal();
  final AIQuoteService _aiQuoteService = AIQuoteService();
  final Random _random = Random();

  static const String _bufferKey = 'quote_buffer';
  static const int _minBufferSize = 10;
  static const int _maxBufferSize = 30;
  static const int _prefetchThreshold = 5;
  static const int _batchSize = 5;

  bool _isGenerating = false;
  Timer? _backgroundTimer;
  List<String> _availableCategories = [
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

  factory QuoteBufferService() => _instance;

  QuoteBufferService._internal();

  Future<void> initialize() async {
    await _loadAvailableCategories();
    await _ensureMinimumBuffer();
    _startBackgroundGeneration();
  }

  Future<void> _loadAvailableCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_categories');
      if (cached != null) {
        final List<dynamic> categories = json.decode(cached);
        final categoryNames = categories
            .map((cat) => cat['name'] as String)
            .toList();

        if (categoryNames.isNotEmpty) {
          _availableCategories = categoryNames;
        }
      }
    } catch (e) {
      // Use default categories
    }
  }

  void _startBackgroundGeneration() {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _generateBatchIfNeeded(),
    );
  }

  Future<void> _ensureMinimumBuffer() async {
    final buffer = await _getBuffer();
    if (buffer.length < _minBufferSize) {
      await _generateBatch(_minBufferSize - buffer.length);
    }
  }

  Future<List<Map<String, dynamic>>> _getBuffer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bufferJson = prefs.getStringList(_bufferKey) ?? [];
      return bufferJson
          .map((item) => json.decode(item) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveBuffer(List<Map<String, dynamic>> buffer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bufferJson = buffer.map((item) => json.encode(item)).toList();
      await prefs.setStringList(_bufferKey, bufferJson);
    } catch (e) {
      // Silent fail
    }
  }

  Future<Map<String, dynamic>?> getNextQuote() async {
    final buffer = await _getBuffer();

    if (buffer.isEmpty) {
      try {
        return await _generateQuoteNow();
      } catch (e) {
        if (kDebugMode) {
          print('Failed to generate quote: $e');
        }
        return null; // Let caller handle fallback
      }
    }

    final quote = buffer.removeAt(0);
    await _saveBuffer(buffer);

    // Trigger background refill
    if (buffer.length <= _prefetchThreshold) {
      // Use unawaited to avoid blocking
      _generateBatchIfNeeded();
    }

    return quote;
  }

  Future<void> _generateBatchIfNeeded() async {
    if (_isGenerating) return;

    final buffer = await _getBuffer();
    if (buffer.length >= _maxBufferSize) return;

    final needed = _minBufferSize - buffer.length;
    if (needed > 0) {
      await _generateBatch(needed);
    }
  }

  Future<void> _generateBatch(int count) async {
    if (_isGenerating) return;

    _isGenerating = true;

    try {
      final buffer = await _getBuffer();
      final prefs = await SharedPreferences.getInstance();
      final tone = prefs.getString('ai_tone') ?? 'inspirational';
      final enablePersonalization =
          prefs.getBool('ai_personalization') ?? false;
      final userName = enablePersonalization
          ? prefs.getString('user_name')
          : null;

      for (int i = 0; i < count && buffer.length < _maxBufferSize; i++) {
        try {
          final category = _getRandomCategory();
          final quote = await _aiQuoteService.generateQuote(
            category: category,
            tone: tone,
            userName: userName,
            requireHighQuality: true,
          );
          buffer.add(quote);
        } catch (e) {
          // Skip failed generation
        }
      }

      await _saveBuffer(buffer);
    } finally {
      _isGenerating = false;
    }
  }

  Future<Map<String, dynamic>> _generateQuoteNow() async {
    final prefs = await SharedPreferences.getInstance();
    final tone = prefs.getString('ai_tone') ?? 'inspirational';
    final enablePersonalization = prefs.getBool('ai_personalization') ?? false;
    final userName = enablePersonalization
        ? prefs.getString('user_name')
        : null;
    final category = _getRandomCategory();

    return await _aiQuoteService.generateQuote(
      category: category,
      tone: tone,
      userName: userName,
      requireHighQuality: true,
    );
  }

  String _getRandomCategory() {
    return _availableCategories[_random.nextInt(_availableCategories.length)];
  }

  Future<void> prefillBuffer() async {
    await _generateBatch(_minBufferSize);
  }

  Future<int> getBufferSize() async {
    final buffer = await _getBuffer();
    return buffer.length;
  }

  Future<void> clearBuffer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bufferKey);
    } catch (e) {
      // Silent fail
    }
  }

  void dispose() {
    _backgroundTimer?.cancel();
  }
}
