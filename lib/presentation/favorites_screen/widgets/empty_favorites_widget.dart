import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Empty state widget for favorites screen
class EmptyFavoritesWidget extends StatelessWidget {
  final bool hasSearchQuery;
  final VoidCallback onBrowseQuotes;

  const EmptyFavoritesWidget({
    super.key,
    required this.hasSearchQuery,
    required this.onBrowseQuotes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: hasSearchQuery ? 'search_off' : 'favorite_border',
                  color: theme.colorScheme.primary,
                  size: 20.w,
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // Title
            Text(
              hasSearchQuery ? 'No Results Found' : 'No Favorites Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2.h),

            // Description
            Text(
              hasSearchQuery
                  ? 'Try adjusting your search terms or browse all favorites'
                  : 'Start saving your favorite quotes to build your personal collection',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 4.h),

            // Action button
            if (!hasSearchQuery)
              ElevatedButton.icon(
                onPressed: onBrowseQuotes,
                icon: CustomIconWidget(
                  iconName: 'format_quote',
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text('Browse Quotes'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
