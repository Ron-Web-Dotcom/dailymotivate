import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/quote_card_widget.dart';
import '../../services/ai_quote_service.dart';
import '../../services/quote_buffer_service.dart';
import '../../services/favorites_service.dart';
import '../../services/daily_quote_service.dart';
import '../../services/share_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreenInitialPage extends StatefulWidget {
  const HomeScreenInitialPage({super.key});

  @override
  State<HomeScreenInitialPage> createState() => _HomeScreenInitialPageState();
}

class _HomeScreenInitialPageState extends State<HomeScreenInitialPage> {
  final PageController _pageController = PageController();
  int _currentQuoteIndex = 0;
  bool _isFavorite = false;
  bool _isRefreshing = false;
  final AIQuoteService _aiQuoteService = AIQuoteService();
  final QuoteBufferService _bufferService = QuoteBufferService();
  final FavoritesService _favoritesService = FavoritesService();
  final DailyQuoteService _dailyQuoteService = DailyQuoteService();
  final ShareService _shareService = ShareService();
  bool _isLoadingMore = false;

  final List<Map<String, dynamic>> _quotes = [];

  final Set<int> _shownQuoteIds = {};

  @override
  void initState() {
    super.initState();
    _loadDailyQuote();
    _checkFavoriteStatus();
  }

  Future<void> _loadDailyQuote() async {
    try {
      final dailyQuote = await _dailyQuoteService.getDailyQuote();
      setState(() {
        _quotes.clear();
        _quotes.add(dailyQuote);
        _currentQuoteIndex = 0;
      });
      await _checkFavoriteStatus();
      await _loadInitialQuotes();
    } catch (e) {
      // Fallback to loading regular quotes
      await _loadInitialQuotes();
    }
  }

  Future<void> _loadInitialQuotes() async {
    await _bufferService.initialize();
    _loadMoreQuotesIfNeeded();
  }

  Future<void> _loadMoreQuotesIfNeeded() async {
    if (_isLoadingMore) return;

    final remainingQuotes = _quotes.length - _currentQuoteIndex - 1;
    if (remainingQuotes <= 3) {
      await _loadNextQuote();
    }
  }

  Future<void> _loadNextQuote() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final newQuote = await _bufferService.getNextQuote();

      if (newQuote != null) {
        setState(() {
          _quotes.add(newQuote);
          _isLoadingMore = false;
        });

        if (_currentQuoteIndex >= _quotes.length - 1) {
          setState(() {
            _currentQuoteIndex = _quotes.length - 1;
            _shownQuoteIds.add(newQuote['id'] as int);
          });
          _checkFavoriteStatus();
          _pageController.animateToPage(
            _currentQuoteIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refreshQuote() async {
    setState(() => _isRefreshing = true);

    try {
      // Refresh the daily quote
      final newQuote = await _dailyQuoteService.refreshDailyQuote();

      setState(() {
        _quotes[0] = newQuote;
        _currentQuoteIndex = 0;
        _isRefreshing = false;
      });
      _pageController.jumpToPage(_currentQuoteIndex);
      await _checkFavoriteStatus();
    } catch (e) {
      setState(() => _isRefreshing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate quote. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<String> _getSelectedCategories(SharedPreferences prefs) {
    final categories = [
      'Success',
      'Discipline',
      'Happiness',
      'Fitness',
      'Study',
    ];
    return categories
        .where((cat) => prefs.getBool('category_${cat.toLowerCase()}') ?? true)
        .toList();
  }

  /// Check if current quote is favorited
  Future<void> _checkFavoriteStatus() async {
    if (_quotes.isEmpty || _currentQuoteIndex >= _quotes.length) return;

    final currentQuote = _quotes[_currentQuoteIndex];
    final quoteId = currentQuote['id'] as int;
    final isFav = await _favoritesService.isFavorite(quoteId);

    setState(() {
      _isFavorite = isFav;
    });
  }

  /// Toggle favorite status and persist to storage
  Future<void> _toggleFavorite() async {
    if (_quotes.isEmpty || _currentQuoteIndex >= _quotes.length) return;

    final currentQuote = _quotes[_currentQuoteIndex];
    final newStatus = await _favoritesService.toggleFavorite(currentQuote);

    setState(() {
      _isFavorite = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus ? 'Added to favorites' : 'Removed from favorites',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showShareOptions() {
    if (_quotes.isEmpty) return;

    final currentQuote = _quotes[_currentQuoteIndex];
    _shareService.showShareOptions(
      context,
      currentQuote['text'] as String,
      currentQuote['author'] as String,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshQuote,
          color: theme.colorScheme.primary,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                physics: const PageScrollPhysics(),
                pageSnapping: true,
                itemCount: _quotes.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentQuoteIndex = index;
                  });
                  _checkFavoriteStatus();
                  _loadMoreQuotesIfNeeded();
                },
                itemBuilder: (context, index) {
                  return QuoteCardWidget(
                    quote: _quotes[index],
                    onNext: () {
                      if (_currentQuoteIndex < _quotes.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    onPrevious: () {
                      if (_currentQuoteIndex > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  );
                },
              ),

              Positioned(
                bottom: 3.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _showShareOptions,
                        child: Container(
                          width: 14.w,
                          height: 14.w,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.shadow,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: CustomIconWidget(
                              iconName: 'share',
                              color: theme.colorScheme.primary,
                              size: 6.w,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: _toggleFavorite,
                        child: Container(
                          width: 14.w,
                          height: 14.w,
                          decoration: BoxDecoration(
                            color: _isFavorite
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.shadow,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: CustomIconWidget(
                              iconName: _isFavorite
                                  ? 'favorite'
                                  : 'favorite_border',
                              color: _isFavorite
                                  ? theme.colorScheme.onTertiary
                                  : theme.colorScheme.primary,
                              size: 6.w,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}