import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for managing quote category preferences with multi-select interface
class QuotePreferencesWidget extends StatefulWidget {
  const QuotePreferencesWidget({super.key});

  @override
  State<QuotePreferencesWidget> createState() => _QuotePreferencesWidgetState();
}

class _QuotePreferencesWidgetState extends State<QuotePreferencesWidget> {
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Success', 'icon': 'emoji_events', 'selected': true},
    {'name': 'Discipline', 'icon': 'self_improvement', 'selected': true},
    {'name': 'Happiness', 'icon': 'sentiment_satisfied', 'selected': true},
    {'name': 'Fitness', 'icon': 'fitness_center', 'selected': true},
    {'name': 'Study', 'icon': 'school', 'selected': true},
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var category in _categories) {
        final key = 'category_${category['name'].toString().toLowerCase()}';
        category['selected'] = prefs.getBool(key) ?? true;
      }
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    for (var category in _categories) {
      final key = 'category_${category['name'].toString().toLowerCase()}';
      await prefs.setBool(key, category['selected'] as bool);
    }
  }

  void _toggleCategory(int index) {
    setState(() {
      _categories[index]['selected'] =
          !(_categories[index]['selected'] as bool);
    });
    _savePreferences();
  }

  void _toggleSelectAll() {
    final allSelected = _categories.every((cat) => cat['selected'] as bool);
    setState(() {
      for (var category in _categories) {
        category['selected'] = !allSelected;
      }
    });
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(4.w),
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    final allSelected = _categories.every((cat) => cat['selected'] as bool);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quote Categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _toggleSelectAll,
                child: Text(
                  allSelected ? 'Deselect All' : 'Select All',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Choose categories for your daily quotes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (context, index) => SizedBox(height: 1.h),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category['selected'] as bool;

              return InkWell(
                onTap: () => _toggleCategory(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.05)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: category['icon'] as String,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          category['name'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) => _toggleCategory(index),
                        activeColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
