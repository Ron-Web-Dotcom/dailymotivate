import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget providing tap-based navigation arrows for quote browsing
class NavigationArrowsWidget extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoPrevious;
  final bool canGoNext;

  const NavigationArrowsWidget({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.canGoPrevious,
    required this.canGoNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          _buildArrowButton(
            context: context,
            icon: 'chevron_left',
            onTap: canGoPrevious ? onPrevious : null,
            theme: theme,
          ),
          // Next button
          _buildArrowButton(
            context: context,
            icon: 'chevron_right',
            onTap: canGoNext ? onNext : null,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton({
    required BuildContext context,
    required String icon,
    required VoidCallback? onTap,
    required ThemeData theme,
  }) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: () {
        if (isEnabled) {
          onTap();
        }
      },
      child: Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          color: isEnabled
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: theme.colorScheme.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: icon,
            color: isEnabled
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            size: 28,
          ),
        ),
      ),
    );
  }
}
