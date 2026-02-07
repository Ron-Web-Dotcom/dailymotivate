import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

class NavigationArrowsWidget extends StatelessWidget {
  final VoidCallback? onPreviousTap;
  final VoidCallback? onNextTap;

  const NavigationArrowsWidget({super.key, this.onPreviousTap, this.onNextTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Previous Arrow Button (Left)
        if (onPreviousTap != null)
          Positioned(
            left: 4.w,
            top: 50.h,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPreviousTap,
                customBorder: const CircleBorder(),
                child: Semantics(
                  label: 'Previous quote',
                  button: true,
                  child: Container(
                    width: 12.w,
                    height: 12.w,
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
                        iconName: 'chevron_left',
                        color: theme.colorScheme.primary,
                        size: 7.w,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Next Arrow Button (Right)
        Positioned(
          right: 4.w,
          top: 50.h,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onNextTap,
              customBorder: const CircleBorder(),
              child: Semantics(
                label: 'Next quote',
                button: true,
                child: Container(
                  width: 12.w,
                  height: 12.w,
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
                      iconName: 'chevron_right',
                      color: theme.colorScheme.primary,
                      size: 7.w,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
