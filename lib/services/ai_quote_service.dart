import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './quote_history_service.dart';
import './openai_service.dart';
import './gemini_service.dart';
import 'dart:math';
import 'dart:convert';

class AIQuoteService {
  final OpenAIService _openAIService = OpenAIService();
  final GeminiService _geminiService = GeminiService();
  final QuoteHistoryService _historyService = QuoteHistoryService();
  final Random _random = Random();
  static int _idCounter = 0;
  static const int _maxRetries = 5;

  int _generateUniqueId() {
    _idCounter++;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomComponent = _random.nextInt(1000);
    return timestamp + _idCounter + randomComponent;
  }

  factory AIQuoteService() => _instance;

  AIQuoteService._internal();

  static final AIQuoteService _instance = AIQuoteService._internal();

  /// Check if any AI service is available
  bool get isAnyServiceAvailable {
    return _openAIService.isConfigured || _geminiService.isConfigured;
  }

  Future<Map<String, dynamic>> generateQuote({
    required String category,
    String tone = 'inspirational',
    String? userName,
    bool requireHighQuality = true,
  }) async {
    // Check if any service is available
    if (!isAnyServiceAvailable) {
      throw AIQuoteException(
        'No AI services configured. Please add API keys to environment variables.',
      );
    }

    int attempts = 0;

    while (attempts < _maxRetries) {
      try {
        // Choose available service
        final useOpenAI =
            _openAIService.isConfigured &&
            (_random.nextBool() || !_geminiService.isConfigured);

        final quote = useOpenAI
            ? await _generateWithOpenAI(category, tone, userName)
            : await _generateWithGemini(category, tone, userName);

        final qualityScore = _calculateQualityScore(quote['text'] as String);
        quote['qualityScore'] = qualityScore;

        final isUnique = await _validateUniqueness(quote['text'] as String);
        final meetsQuality = !requireHighQuality || qualityScore >= 75;

        if (isUnique && meetsQuality) {
          await _historyService.addQuote(quote);
          return quote;
        }

        attempts++;

        // Add exponential backoff to prevent rapid retries
        if (attempts < _maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempts));
        }
      } catch (e) {
        attempts++;
        if (attempts >= _maxRetries) {
          throw AIQuoteException(
            'Failed to generate high-quality unique quote after $_maxRetries attempts: $e',
          );
        }
        // Add delay before retry
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }

    throw AIQuoteException(
      'Failed to generate high-quality unique quote after $_maxRetries attempts',
    );
  }

  /// Calculate quality score based on multiple factors
  int _calculateQualityScore(String quoteText) {
    int score = 50; // Base score

    // Length check (optimal 50-200 characters)
    final length = quoteText.length;
    if (length >= 50 && length <= 200) {
      score += 20;
    } else if (length > 200 && length <= 300) {
      score += 10;
    }

    // Word count (optimal 8-30 words)
    final wordCount = quoteText.split(' ').length;
    if (wordCount >= 8 && wordCount <= 30) {
      score += 15;
    }

    // Avoid clichés
    final cliches = [
      'believe in yourself',
      'never give up',
      'follow your dreams',
      'sky is the limit',
      'carpe diem',
    ];
    final lowerText = quoteText.toLowerCase();
    final hasCliche = cliches.any((cliche) => lowerText.contains(cliche));
    if (!hasCliche) {
      score += 15;
    } else {
      score -= 20;
    }

    // Check for metaphors/imagery (contains: like, as, imagine, picture, vision)
    final hasMetaphor = RegExp(
      r'\b(like|as|imagine|picture|vision|mirror|light|path|journey)\b',
      caseSensitive: false,
    ).hasMatch(quoteText);
    if (hasMetaphor) {
      score += 10;
    }

    // Punctuation variety
    final hasPunctuation =
        quoteText.contains(',') ||
        quoteText.contains(';') ||
        quoteText.contains(':');
    if (hasPunctuation) {
      score += 5;
    }

    // Avoid excessive exclamation
    final exclamationCount = '!'.allMatches(quoteText).length;
    if (exclamationCount > 2) {
      score -= 10;
    }

    return score.clamp(0, 100);
  }

  Future<bool> _validateUniqueness(String quoteText) async {
    final isDuplicate = await _historyService.isDuplicate(quoteText);
    if (isDuplicate) return false;

    final isSimilar = await _historyService.isSimilar(
      quoteText,
      threshold: 0.85,
    );
    return !isSimilar;
  }

  Future<Map<String, dynamic>> _generateWithOpenAI(
    String category,
    String tone,
    String? userName,
  ) async {
    final prompt = await _buildEnhancedPrompt(category, tone, userName);

    try {
      final response = await _openAIService.dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert curator of REAL motivational quotes from REAL historical figures, philosophers, athletes, entrepreneurs, and thought leaders. '
                  'Your mission: Select ONLY AUTHENTIC, VERIFIABLE quotes from REAL people that inspire deep reflection and action. '
                  '\n\n🚨 CRITICAL REQUIREMENTS:\n'
                  '- ABSOLUTELY NO fictional characters, made-up names, or invented attributions\n'
                  '- Use ONLY real people: historical figures, philosophers, athletes, CEOs, authors, scientists, politicians, leaders\n'
                  '- Every quote must be from a REAL PERSON who actually existed/exists\n'
                  '- Include the person\'s COMPLETE REAL NAME (e.g., "Maya Angelou", "Nelson Mandela", "Steve Jobs", "Winston Churchill")\n'
                  '- Choose quotes that are well-documented and can be verified in books, speeches, interviews, or historical records\n'
                  '- Select powerful, memorable quotes that match the requested category and tone\n'
                  '- Prefer quotes from diverse sources (different eras, cultures, fields of expertise)\n'
                  '- Balance classic wisdom with modern insights from contemporary leaders\n'
                  '\n\n❌ FORBIDDEN:\n'
                  '- Fictional characters from books, movies, TV shows\n'
                  '- Made-up names or pseudonyms without real attribution\n'
                  '- Generic or anonymous attributions like "Ancient Proverb" or "Unknown"\n'
                  '- Composite or paraphrased quotes not directly from the person\n'
                  '\n\n✅ REAL PERSON EXAMPLES:\n'
                  '- Historical: Marcus Aurelius, Abraham Lincoln, Marie Curie\n'
                  '- Modern: Oprah Winfrey, Elon Musk, Malala Yousafzai\n'
                  '- Athletes: Muhammad Ali, Serena Williams, Michael Jordan\n'
                  '- Artists: Pablo Picasso, Maya Angelou, Bob Dylan\n'
                  '- Leaders: Martin Luther King Jr., Mahatma Gandhi, Angela Merkel\n'
                  '\nReturn ONLY valid JSON without markdown: {"text": "exact real quote", "author": "Real Person Full Name"}',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 150,
          'presence_penalty': 0.6,
          'frequency_penalty': 0.8,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      final quoteData = _parseQuoteResponse(content);

      return {
        'id': _generateUniqueId(),
        'text': quoteData['text'],
        'author': quoteData['author'],
        'category': category,
        'source': 'openai',
      };
    } on DioException catch (e) {
      throw AIQuoteException(
        'OpenAI Error: ${e.response?.data?['error']?['message'] ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> _generateWithGemini(
    String category,
    String tone,
    String? userName,
  ) async {
    final prompt = await _buildEnhancedPrompt(category, tone, userName);

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
                      'You are an expert curator of REAL motivational quotes from REAL historical figures, philosophers, athletes, entrepreneurs, and thought leaders. '
                      'Your mission: Select ONLY AUTHENTIC, VERIFIABLE quotes from REAL people that inspire deep reflection and action. '
                      '\n\n🚨 CRITICAL REQUIREMENTS:\n'
                      '- ABSOLUTELY NO fictional characters, made-up names, or invented attributions\n'
                      '- Use ONLY real people: historical figures, philosophers, athletes, CEOs, authors, scientists, politicians, leaders\n'
                      '- Every quote must be from a REAL PERSON who actually existed/exists\n'
                      '- Include the person\'s COMPLETE REAL NAME (e.g., "Maya Angelou", "Nelson Mandela", "Steve Jobs", "Winston Churchill")\n'
                      '- Choose quotes that are well-documented and can be verified in books, speeches, interviews, or historical records\n'
                      '- Select powerful, memorable quotes that match the requested category and tone\n'
                      '- Prefer quotes from diverse sources (different eras, cultures, fields of expertise)\n'
                      '- Balance classic wisdom with modern insights from contemporary leaders\n'
                      '\n\n❌ FORBIDDEN:\n'
                      '- Fictional characters from books, movies, TV shows\n'
                      '- Made-up names or pseudonyms without real attribution\n'
                      '- Generic or anonymous attributions like "Ancient Proverb" or "Unknown"\n'
                      '- Composite or paraphrased quotes not directly from the person\n'
                      '\n\n✅ REAL PERSON EXAMPLES:\n'
                      '- Historical: Marcus Aurelius, Abraham Lincoln, Marie Curie\n'
                      '- Modern: Oprah Winfrey, Elon Musk, Malala Yousafzai\n'
                      '- Athletes: Muhammad Ali, Serena Williams, Michael Jordan\n'
                      '- Artists: Pablo Picasso, Maya Angelou, Bob Dylan\n'
                      '- Leaders: Martin Luther King Jr., Mahatma Gandhi, Angela Merkel\n'
                      '\nReturn ONLY valid JSON without markdown: {"text": "exact real quote", "author": "Real Person Full Name"}\n\n$prompt',
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 150,
            'topP': 0.9,
            'topK': 40,
          },
        },
      );

      if (response.data['candidates'] != null &&
          response.data['candidates'].isNotEmpty) {
        final content =
            response.data['candidates'][0]['content']['parts'][0]['text'];
        final quoteData = _parseQuoteResponse(content);

        return {
          'id': _generateUniqueId(),
          'text': quoteData['text'],
          'author': quoteData['author'],
          'category': category,
          'source': 'gemini',
        };
      }

      throw AIQuoteException('No response from Gemini');
    } on DioException catch (e) {
      throw AIQuoteException(
        'Gemini Error: ${e.response?.data?['error']?['message'] ?? e.message}',
      );
    }
  }

  Future<String> _buildEnhancedPrompt(
    String category,
    String tone,
    String? userName,
  ) async {
    final personalization = userName != null && userName.isNotEmpty
        ? 'Select a quote that would resonate with someone named $userName. '
        : '';

    final recentQuotes = await _historyService.getRecentQuoteTexts(count: 30);
    final avoidanceContext = recentQuotes.isNotEmpty
        ? '\n\n⚠️ AVOID DUPLICATES - These quotes were already shown:\n${recentQuotes.take(15).map((q) => '- "$q"').join('\n')}\n'
        : '';

    final statistics = await _historyService.getStatistics();
    final totalGenerated = statistics['total'] ?? 0;
    final diversityPrompt = totalGenerated > 0
        ? 'This is quote #${totalGenerated + 1}. Ensure variety by selecting from DIFFERENT REAL PEOPLE across different eras and fields. '
        : '';

    // Category-specific guidance
    final categoryGuidance = _getCategoryGuidance(category);

    // Tone-specific guidance
    final toneGuidance = _getToneGuidance(tone);

    return 'Find a REAL, VERIFIABLE $tone motivational quote about $category from a REAL FAMOUS PERSON. '
        '$personalization'
        '$diversityPrompt'
        '\n\n🎯 TONE REQUIREMENTS:\n$toneGuidance'
        '\n\n🎯 CATEGORY FOCUS:\n$categoryGuidance'
        '\n\n🚨 MANDATORY REAL PERSON ATTRIBUTION:\n'
        '- Choose from REAL historical figures, philosophers, athletes, entrepreneurs, authors, scientists, or leaders\n'
        '- Select quotes that are well-documented and can be found in books, speeches, or verified sources\n'
        '- Use the person\'s COMPLETE REAL NAME (First + Last Name) - e.g., "Maya Angelou", "Nelson Mandela", "Steve Jobs"\n'
        '- NEVER use fictional characters, made-up names, or anonymous attributions\n'
        '- Prefer diverse sources: different time periods, cultures, and fields of expertise\n'
        '- Choose powerful, memorable quotes that match the category perfectly\n'
        '- Find lesser-known gems from famous people, not overused quotes\n'
        '$avoidanceContext'
        '\n\n✅ REAL PERSON CATEGORIES TO CHOOSE FROM:\n'
        '- Historical Leaders: Winston Churchill, Abraham Lincoln, Cleopatra, Julius Caesar\n'
        '- Modern Leaders: Barack Obama, Angela Merkel, Jacinda Ardern, Nelson Mandela\n'
        '- Philosophers: Aristotle, Marcus Aurelius, Friedrich Nietzsche, Confucius\n'
        '- Authors: Maya Angelou, Ernest Hemingway, J.K. Rowling, Stephen King\n'
        '- Scientists: Albert Einstein, Marie Curie, Stephen Hawking, Carl Sagan\n'
        '- Athletes: Muhammad Ali, Serena Williams, Michael Jordan, Usain Bolt\n'
        '- Entrepreneurs: Steve Jobs, Elon Musk, Oprah Winfrey, Richard Branson\n'
        '- Artists: Pablo Picasso, Vincent van Gogh, Leonardo da Vinci, Frida Kahlo\n'
        '- Activists: Martin Luther King Jr., Malala Yousafzai, Rosa Parks, Greta Thunberg';
  }

  String _getToneGuidance(String tone) {
    final guidance = {
      'inspirational':
          'Create an uplifting message that sparks hope and motivation. Use powerful, positive language that encourages action and belief in possibilities. Focus on potential, growth, and transformation.',
      'humorous':
          'Inject wit, clever wordplay, or light-hearted humor while maintaining the motivational message. Use unexpected twists, playful language, or amusing observations. Keep it fun but meaningful.',
      'philosophical':
          'Explore deep truths and existential insights. Use contemplative language that provokes thought and reflection. Draw from wisdom traditions, paradoxes, or profound observations about human nature and life.',
      'practical':
          'Provide actionable wisdom and concrete guidance. Focus on real-world application, specific strategies, and tangible steps. Use clear, direct language that translates to immediate action.',
      'energetic':
          'Use dynamic, high-energy language with strong verbs and vivid imagery. Create urgency and excitement. Employ short, punchy phrases that ignite passion and drive immediate action.',
    };

    return guidance[tone] ??
        'Create a motivational quote that resonates emotionally and intellectually.';
  }

  String _getCategoryGuidance(String category) {
    final guidance = {
      'Success':
          'Focus on the journey, not just the destination. Explore unconventional paths to achievement.',
      'Discipline':
          'Connect discipline to freedom and self-mastery. Show how small actions compound.',
      'Happiness':
          'Explore the paradox of happiness - finding joy in struggle, presence over pursuit.',
      'Fitness':
          'Link physical strength to mental resilience. Body as a vehicle for life.',
      'Study':
          'Learning as transformation, not accumulation. Curiosity over grades.',
      'Motivation':
          'Internal drive vs external pressure. Sustainable motivation from purpose.',
      'Resilience':
          'Bouncing forward, not just back. Growth through adversity.',
      'Mindfulness': 'Present moment awareness. The power of now.',
      'Leadership': 'Servant leadership. Influence through example.',
      'Creativity': 'Constraints breed creativity. Embrace the process.',
      'Relationships':
          'Connection through vulnerability. Quality over quantity.',
      'Productivity': 'Deep work. Essentialism. Doing less, better.',
    };

    return guidance[category] ??
        'Create a fresh perspective on $category that challenges conventional thinking.';
  }

  String _buildPrompt(String category, String tone, String? userName) {
    final personalization = userName != null && userName.isNotEmpty
        ? 'Personalize it subtly for someone named $userName. '
        : '';

    return 'Generate a $tone motivational quote about $category. '
        '$personalization'
        'Make it unique, powerful, and memorable. '
        'Return as JSON: {"text": "quote text", "author": "author name"}';
  }

  Map<String, String> _parseQuoteResponse(String content) {
    try {
      // Remove markdown code blocks and extra whitespace
      String cleaned = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Find JSON object boundaries
      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = cleaned.substring(jsonStart, jsonEnd);

        // Try to parse as proper JSON first
        try {
          final decoded = json.decode(jsonStr) as Map<String, dynamic>;
          return {
            'text':
                decoded['text']?.toString() ??
                'Stay motivated and keep pushing forward.',
            'author': decoded['author']?.toString() ?? 'Unknown',
          };
        } catch (e) {
          // Fallback to regex parsing
          return _parseJsonWithRegex(jsonStr);
        }
      }

      // If no JSON found, return the content as-is
      return {'text': cleaned, 'author': 'Unknown'};
    } catch (e) {
      return {'text': content.trim(), 'author': 'Unknown'};
    }
  }

  Map<String, String> _parseJsonWithRegex(String jsonStr) {
    // Extract text field
    final textMatch = RegExp(
      r'"text"\s*:\s*"((?:[^"\\]|\\.)*)"',
      dotAll: true,
    ).firstMatch(jsonStr);

    // Extract author field
    final authorMatch = RegExp(
      r'"author"\s*:\s*"((?:[^"\\]|\\.)*)"',
      dotAll: true,
    ).firstMatch(jsonStr);

    String text =
        textMatch?.group(1) ?? 'Stay motivated and keep pushing forward.';
    String author = authorMatch?.group(1) ?? 'Unknown';

    // Unescape common JSON escape sequences
    text = text
        .replaceAll('\\"', '"')
        .replaceAll('\\n', '\n')
        .replaceAll('\\\\', '\\');

    author = author
        .replaceAll('\\"', '"')
        .replaceAll('\\n', ' ')
        .replaceAll('\\\\', '\\');

    return {'text': text, 'author': author};
  }

  String _parseJson(String jsonStr) {
    final cleaned = jsonStr
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final textMatch = RegExp(r'"text"\s*:\s*"([^"]+)"').firstMatch(cleaned);
    final authorMatch = RegExp(r'"author"\s*:\s*"([^"]+)"').firstMatch(cleaned);

    return textMatch?.group(1) ?? '';
  }

  Future<String> generateNotificationMessage({
    required String category,
    String tone = 'inspirational',
    String? userName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final useOpenAI = _random.nextBool();

      final personalization = userName != null && userName.isNotEmpty
          ? 'for $userName '
          : '';

      final prompt =
          'Generate a short, engaging notification message ${personalization}to motivate someone to read a $tone $category quote. '
          'Keep it under 50 characters. Be creative and compelling. '
          'Return ONLY the message text, no JSON.';

      if (useOpenAI) {
        final response = await _openAIService.dio.post(
          '/chat/completions',
          data: {
            'model': 'gpt-4o-mini',
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a creative notification message writer. Generate short, compelling messages that motivate users to engage with motivational quotes.',
              },
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.9,
            'max_tokens': 50,
          },
        );

        return response.data['choices'][0]['message']['content'].trim();
      } else {
        final response = await _geminiService.dio.post(
          '/models/gemini-2.5-flash:generateContent',
          data: {
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {'temperature': 0.9, 'maxOutputTokens': 50},
          },
        );

        if (response.data['candidates'] != null &&
            response.data['candidates'].isNotEmpty) {
          return response.data['candidates'][0]['content']['parts'][0]['text']
              .trim();
        }

        return 'Time for your daily motivation! 💪';
      }
    } catch (e) {
      return 'New motivational quote waiting for you! ✨';
    }
  }

  Future<void> warmupServices() async {
    try {
      await Future.wait([
        _openAIService.dio.get('/models'),
        _geminiService.dio.get('/models'),
      ], eagerError: false);
    } catch (e) {
      // Silent fail - services will work when needed
    }
  }
}

class AIQuoteException implements Exception {
  final String message;

  AIQuoteException(this.message);

  @override
  String toString() => 'AIQuoteException: $message';
}
