import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget displaying a single quote card with category-specific styling
class QuoteCardWidget extends StatelessWidget {
  final String quote;
  final String author;
  final String category;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onShare;

  const QuoteCardWidget({
    super.key,
    required this.quote,
    required this.author,
    required this.category,
    required this.isFavorite,
    required this.onFavoriteToggle,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 90.w,
      constraints: BoxConstraints(minHeight: 40.h, maxHeight: 60.h),
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          // Quote text
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                '"$quote"',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          // Author attribution
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '— $author',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  // Share button
                  if (onShare != null)
                    GestureDetector(
                      onTap: onShare,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: CustomIconWidget(
                          iconName: 'share',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ),
                  SizedBox(width: 2.w),
                  // Favorite button
                  GestureDetector(
                    onTap: onFavoriteToggle,
                    child: AnimatedScale(
                      scale: isFavorite ? 1.1 : 1.0,
                      duration: Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? theme.colorScheme.tertiary.withValues(
                                  alpha: 0.2,
                                )
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: CustomIconWidget(
                          iconName: isFavorite ? 'favorite' : 'favorite_border',
                          color: isFavorite
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
