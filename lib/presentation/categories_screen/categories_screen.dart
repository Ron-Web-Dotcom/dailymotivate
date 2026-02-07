import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/category_card_widget.dart';
import './widgets/search_bar_widget.dart';
import '../../services/ai_category_service.dart';

/// Categories Screen - Browse motivational quotes by theme
/// Displays grid of AI-generated category cards with search and random selection
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AICategoryService _categoryService = AICategoryService();
  List<Map<String, dynamic>> _filteredCategories = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isAIGenerated = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCategories);
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      // Try to get cached categories first
      final cached = await _categoryService.getCachedCategories();

      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _categories = cached;
          _filteredCategories = List.from(_categories);
          _isAIGenerated = _categories.first['isAIGenerated'] ?? false;
          _isLoading = false;
        });
        return;
      }

      // Generate new AI categories
      final aiCategories = await _categoryService.generateCategories(
        count: 12,
        userPreferences: await _getUserPreferences(),
      );

      await _categoryService.cacheCategories(aiCategories);

      setState(() {
        _categories = aiCategories;
        _filteredCategories = List.from(_categories);
        _isAIGenerated = true;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to default categories
      setState(() {
        _categories = _getDefaultCategories();
        _filteredCategories = List.from(_categories);
        _isAIGenerated = false;
        _isLoading = false;
      });
    }
  }

  Future<List<String>> _getUserPreferences() async {
    // Could be expanded to read from SharedPreferences
    return ['Success', 'Happiness', 'Growth'];
  }

  List<Map<String, dynamic>> _getDefaultCategories() {
    return [
      {
        "id": 1,
        "name": "Success",
        "icon": "emoji_events",
        "quoteCount": 156,
        "color": 0xFF2C5F41,
        "description": "Achieve your goals and reach new heights",
        "isAIGenerated": false,
      },
      {
        "id": 2,
        "name": "Discipline",
        "icon": "self_improvement",
        "quoteCount": 142,
        "color": 0xFF7B9E87,
        "description": "Build habits that transform your life",
        "isAIGenerated": false,
      },
      {
        "id": 3,
        "name": "Happiness",
        "icon": "sentiment_satisfied_alt",
        "quoteCount": 189,
        "color": 0xFFE8B86D,
        "description": "Find joy in every moment",
        "isAIGenerated": false,
      },
      {
        "id": 4,
        "name": "Fitness",
        "icon": "fitness_center",
        "quoteCount": 128,
        "color": 0xFF2C5F41,
        "description": "Strengthen body and mind together",
        "isAIGenerated": false,
      },
      {
        "id": 5,
        "name": "Study",
        "icon": "menu_book",
        "quoteCount": 134,
        "color": 0xFF7B9E87,
        "description": "Learn, grow, and expand your horizons",
        "isAIGenerated": false,
      },
      {
        "id": 6,
        "name": "Motivation",
        "icon": "local_fire_department",
        "quoteCount": 201,
        "color": 0xFFE8B86D,
        "description": "Ignite your inner fire",
        "isAIGenerated": false,
      },
    ];
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = query.isEmpty
          ? List.from(_categories)
          : _categories
                .where(
                  (category) => (category["name"] as String)
                      .toLowerCase()
                      .contains(query),
                )
                .toList();
    });
  }

  Future<void> _refreshCategories() async {
    HapticFeedback.mediumImpact();
    await _loadCategories();
  }

  void _navigateToCategory(Map<String, dynamic> category) {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/category-detail-screen', arguments: category);
  }

  void _showCategoryPreview(Map<String, dynamic> category) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPreviewBottomSheet(category),
    );
  }

  void _selectRandomCategory() {
    HapticFeedback.mediumImpact();
    final random = (_categories..shuffle()).first;
    _navigateToCategory(random);
  }

  Widget _buildPreviewBottomSheet(Map<String, dynamic> category) {
    final theme = Theme.of(context);
    final color = category["color"] is int
        ? Color(category["color"] as int)
        : Color(0xFF2C5F41);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: category["icon"] as String,
                  color: color,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category["name"] as String,
                      style: theme.textTheme.titleLarge,
                    ),
                    SizedBox(height: 4),
                    Text(
                      category["description"] as String? ?? "Inspiring quotes",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (category['isAIGenerated'] == true) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'AI-Generated Category',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToCategory(category);
              },
              child: Text("Explore Quotes"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;
    final crossAxisCount = isTablet ? 3 : 2;

    return Column(
      children: [
        // App Bar Content
        Container(
          color: theme.scaffoldBackgroundColor,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isAIGenerated)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'AI',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(width: 40),
                  Text("Categories", style: theme.textTheme.titleLarge),
                  SizedBox(width: 40),
                ],
              ),
              SizedBox(height: 16),
              SearchBarWidget(
                controller: _searchController,
                onClear: () {
                  _searchController.clear();
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Generating AI categories...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshCategories,
                  child: _filteredCategories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No categories found',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: _filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = _filteredCategories[index];
                            return CategoryCardWidget(
                              category: category,
                              onTap: () => _navigateToCategory(category),
                              onLongPress: () => _showCategoryPreview(category),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}
