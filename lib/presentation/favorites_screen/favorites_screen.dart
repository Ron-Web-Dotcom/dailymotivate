import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../core/app_export.dart';
import '../../services/favorites_service.dart';
import '../../services/share_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/empty_favorites_widget.dart';
import './widgets/favorite_quote_card_widget.dart';

/// Favorites Screen - Personal collection management for saved quotes
/// Provides mobile-optimized list interface with swipe actions and search
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FavoritesService _favoritesService = FavoritesService();
  final ShareService _shareService = ShareService();

  List<Map<String, dynamic>> _allFavorites = [];
  List<Map<String, dynamic>> _filteredFavorites = [];
  final Set<int> _selectedQuotes = {};
  bool _isSelectionMode = false;
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load favorites from local database
  Future<void> _loadFavorites() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final favorites = await _favoritesService.getFavorites();

      if (!mounted) return; // Critical check before setState

      // Parse dates if stored as strings
      final parsedFavorites = favorites.map((fav) {
        if (fav['addedDate'] is String) {
          fav['addedDate'] = DateTime.parse(fav['addedDate'] as String);
        }
        return fav;
      }).toList();

      setState(() {
        _allFavorites = parsedFavorites;
        _filteredFavorites = List.from(_allFavorites);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // Critical check before setState
      setState(() {
        _allFavorites = [];
        _filteredFavorites = [];
        _isLoading = false;
      });
    }
  }

  /// Filter favorites based on search query
  void _filterFavorites(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredFavorites = List.from(_allFavorites);
      } else {
        _filteredFavorites = _allFavorites.where((quote) {
          final quoteText = (quote["text"] as String).toLowerCase();
          final author = (quote["author"] as String).toLowerCase();
          return quoteText.contains(_searchQuery) ||
              author.contains(_searchQuery);
        }).toList();
      }
    });
  }

  /// Remove quote from favorites with undo option
  void _removeFromFavorites(Map<String, dynamic> quote, int index) async {
    final quoteId = quote["id"] as int;
    await _favoritesService.removeFavorite(quoteId);

    setState(() {
      _allFavorites.removeWhere((q) => q["id"] == quote["id"]);
      _filteredFavorites.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${quote["author"]}" from favorites'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await _favoritesService.addFavorite(quote);
            await _loadFavorites();
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Share quote using platform-native sharing
  Future<void> _shareQuote(Map<String, dynamic> quote) async {
    final text = '"${quote["text"]}"\n\n- ${quote["author"]}';
    await Share.share(text, subject: 'Motivational Quote');
  }

  /// Copy quote text to clipboard
  void _copyQuoteText(Map<String, dynamic> quote) {
    Clipboard.setData(ClipboardData(text: quote["text"] as String));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quote copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Move quote to top of list
  void _moveToTop(Map<String, dynamic> quote, int index) async {
    final quoteId = quote["id"] as int;
    await _favoritesService.moveToTop(quoteId);

    await _loadFavorites();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Moved to top'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Navigate to category detail screen
  void _viewCategory(String category) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/category-detail-screen', arguments: {'category': category});
  }

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedQuotes.clear();
      }
    });
  }

  /// Toggle quote selection
  void _toggleQuoteSelection(int quoteId) {
    setState(() {
      if (_selectedQuotes.contains(quoteId)) {
        _selectedQuotes.remove(quoteId);
      } else {
        _selectedQuotes.add(quoteId);
      }
    });
  }

  /// Delete selected quotes
  void _deleteSelectedQuotes() async {
    final quoteIds = _selectedQuotes.toList();
    await _favoritesService.removeFavorites(quoteIds);

    setState(() {
      _allFavorites.removeWhere(
        (quote) => _selectedQuotes.contains(quote["id"] as int),
      );
      _filterFavorites(_searchQuery);
      _selectedQuotes.clear();
      _isSelectionMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selected quotes removed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Show context menu for quote
  void _showContextMenu(
    BuildContext context,
    Map<String, dynamic> quote,
    int index,
  ) {
    _shareService.showShareOptions(
      context,
      quote['text'] as String,
      quote['author'] as String,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Custom app bar with search
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Favorites',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_filteredFavorites.isNotEmpty)
                    IconButton(
                      icon: CustomIconWidget(
                        iconName: _isSelectionMode ? 'close' : 'edit',
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      onPressed: _toggleSelectionMode,
                      tooltip: _isSelectionMode ? 'Cancel' : 'Edit',
                    ),
                ],
              ),
              if (_filteredFavorites.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: _filterFavorites,
                  decoration: InputDecoration(
                    hintText: 'Search quotes or authors...',
                    prefixIcon: CustomIconWidget(
                      iconName: 'search',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: CustomIconWidget(
                              iconName: 'clear',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterFavorites('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Content area
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
              : _filteredFavorites.isEmpty
              ? EmptyFavoritesWidget(
                  hasSearchQuery: _searchQuery.isNotEmpty,
                  onBrowseQuotes: () {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed('/home-screen');
                  },
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  color: theme.colorScheme.primary,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredFavorites.length,
                    itemBuilder: (context, index) {
                      final quote = _filteredFavorites[index];
                      final isSelected = _selectedQuotes.contains(
                        quote["id"] as int,
                      );

                      return Slidable(
                        key: ValueKey(quote["id"]),
                        enabled: !_isSelectionMode,
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _shareQuote(quote),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              icon: Icons.share,
                              label: 'Share',
                            ),
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) =>
                                  _removeFromFavorites(quote, index),
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Remove',
                            ),
                          ],
                        ),
                        child: FavoriteQuoteCardWidget(
                          quote: quote,
                          isSelected: isSelected,
                          isSelectionMode: _isSelectionMode,
                          searchQuery: _searchQuery,
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleQuoteSelection(quote["id"] as int);
                            } else {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pushNamed(
                                '/home-screen',
                                arguments: {'quoteId': quote["id"]},
                              );
                            }
                          },
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              _showContextMenu(context, quote, index);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),

        // Bulk action bar
        if (_isSelectionMode && _selectedQuotes.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedQuotes.length} selected',
                    style: theme.textTheme.titleMedium,
                  ),
                  ElevatedButton.icon(
                    onPressed: _deleteSelectedQuotes,
                    icon: CustomIconWidget(
                      iconName: 'delete',
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
