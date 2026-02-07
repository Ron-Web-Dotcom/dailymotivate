import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../services/ai_quote_service.dart';
import '../../services/favorites_service.dart';
import '../../services/share_service.dart';
import './widgets/navigation_arrows_widget.dart';
import './widgets/quote_card_widget.dart';
import './widgets/quote_counter_widget.dart';
import '../../widgets/custom_icon_widget.dart';

/// Category Detail Screen - Displays AI-generated quotes within selected category
/// with swipe-based navigation and gesture controls
class CategoryDetailScreen extends StatefulWidget {
  const CategoryDetailScreen({super.key});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  Map<String, dynamic>? _category;
  String _selectedCategory = 'Success';
  final AIQuoteService _aiQuoteService = AIQuoteService();
  final FavoritesService _favoritesService = FavoritesService();
  final ShareService _shareService = ShareService();
  final List<Map<String, dynamic>> _quotes = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final Set<int> _favoriteQuoteIds = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get category from navigation arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _category == null) {
      setState(() {
        _category = args;
        _selectedCategory = args['name'] as String? ?? 'Success';
      });
      _loadCategoryQuotes();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryQuotes() async {
    setState(() => _isLoading = true);

    try {
      // Load initial batch of quotes for this category
      await _loadMoreQuotes(initialLoad: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load quotes: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreQuotes({bool initialLoad = false}) async {
    if (_isLoadingMore && !initialLoad) return;

    setState(() => _isLoadingMore = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final tone = prefs.getString('ai_tone') ?? 'inspirational';
      final enablePersonalization =
          prefs.getBool('ai_personalization') ?? false;
      final userName = enablePersonalization
          ? prefs.getString('user_name')
          : null;

      // Generate 5 quotes for this category
      final count = initialLoad ? 5 : 3;
      for (int i = 0; i < count; i++) {
        try {
          final quote = await _aiQuoteService.generateQuote(
            category: _selectedCategory,
            tone: tone,
            userName: userName,
            requireHighQuality: true,
          );
          setState(() {
            _quotes.add(quote);
          });
        } catch (e) {
          // Skip failed generation
        }
      }

      // Check favorite status for new quotes
      await _checkAllFavoriteStatuses();
    } catch (e) {
      // Silent fail
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _checkAllFavoriteStatuses() async {
    for (final quote in _quotes) {
      final quoteId = quote['id'] as int;
      final isFav = await _favoritesService.isFavorite(quoteId);
      if (isFav) {
        setState(() {
          _favoriteQuoteIds.add(quoteId);
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Load more quotes when approaching the end
    if (index >= _quotes.length - 2) {
      _loadMoreQuotes();
    }
  }

  void _navigateToPage(int index) {
    if (index >= 0 && index < _quotes.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _toggleFavorite() async {
    if (_quotes.isEmpty || _currentIndex >= _quotes.length) return;

    final currentQuote = _quotes[_currentIndex];
    final quoteId = currentQuote['id'] as int;
    final newStatus = await _favoritesService.toggleFavorite(currentQuote);

    setState(() {
      if (newStatus) {
        _favoriteQuoteIds.add(quoteId);
      } else {
        _favoriteQuoteIds.remove(quoteId);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? 'Added to favorites' : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareQuote() async {
    if (_quotes.isEmpty || _currentIndex >= _quotes.length) return;

    final currentQuote = _quotes[_currentIndex];
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'Share Quote',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'share',
                  color: const Color(0xFF25D366),
                  size: 24,
                ),
                title: Text('WhatsApp', style: theme.textTheme.bodyLarge),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await _shareService.shareToWhatsApp(
                    currentQuote['text'] as String,
                    currentQuote['author'] as String,
                  );
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('WhatsApp not available')),
                    );
                  }
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'share',
                  color: const Color(0xFF1DA1F2),
                  size: 24,
                ),
                title: Text('Twitter (X)', style: theme.textTheme.bodyLarge),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await _shareService.shareToTwitter(
                    currentQuote['text'] as String,
                    currentQuote['author'] as String,
                  );
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Twitter not available')),
                    );
                  }
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'email',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('Email', style: theme.textTheme.bodyLarge),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await _shareService.shareViaEmail(
                    currentQuote['text'] as String,
                    currentQuote['author'] as String,
                  );
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email not available')),
                    );
                  }
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'sms',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('SMS', style: theme.textTheme.bodyLarge),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await _shareService.shareViaSMS(
                    currentQuote['text'] as String,
                    currentQuote['author'] as String,
                  );
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SMS not available')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showShareOptions() {
    if (_quotes.isEmpty || _currentIndex >= _quotes.length) return;

    final currentQuote = _quotes[_currentIndex];
    _shareService.showShareOptions(
      context,
      currentQuote['text'] as String,
      currentQuote['author'] as String,
    );
  }

  void _returnToFirstQuote() {
    _navigateToPage(0);
  }

  void _viewAllCategories() {
    Navigator.of(context, rootNavigator: true).pushNamed('/categories-screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _category?['color'] is int
        ? Color(_category!['color'] as int)
        : const Color(0xFF2C5F41);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_selectedCategory, style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.category_outlined,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: _viewAllCategories,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: categoryColor),
                  SizedBox(height: 2.h),
                  Text(
                    'Loading $_selectedCategory quotes...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : _quotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No quotes available',
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 1.h),
                  ElevatedButton(
                    onPressed: _loadCategoryQuotes,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Stack(
                children: [
                  // Main Quote Display
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.horizontal,
                    physics: const PageScrollPhysics(),
                    pageSnapping: true,
                    onPageChanged: _onPageChanged,
                    itemCount: _quotes.length,
                    itemBuilder: (context, index) {
                      final quote = _quotes[index];
                      final quoteId = quote['id'] as int;
                      final isFavorite = _favoriteQuoteIds.contains(quoteId);

                      return QuoteCardWidget(
                        quote: quote['text'] as String? ?? '',
                        author: quote['author'] as String? ?? 'AI Wisdom',
                        category: _selectedCategory,
                        isFavorite: isFavorite,
                        onFavoriteToggle: _toggleFavorite,
                        onShare: _shareQuote,
                      );
                    },
                  ),

                  // Navigation Arrows
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 15.h,
                    child: NavigationArrowsWidget(
                      onPrevious: () => _navigateToPage(_currentIndex - 1),
                      onNext: () => _navigateToPage(_currentIndex + 1),
                      canGoPrevious: _currentIndex > 0,
                      canGoNext: _currentIndex < _quotes.length - 1,
                    ),
                  ),

                  // Quote Counter
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10.h,
                    child: QuoteCounterWidget(
                      currentIndex: _currentIndex + 1,
                      totalQuotes: _quotes.length,
                    ),
                  ),

                  // Loading indicator for more quotes
                  if (_isLoadingMore)
                    Positioned(
                      bottom: 5.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: categoryColor,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Loading more...',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
