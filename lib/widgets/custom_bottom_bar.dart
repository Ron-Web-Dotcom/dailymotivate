import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom bottom navigation bar widget for the motivational quote app.
/// Implements thumb-friendly navigation with haptic feedback and smooth transitions.
///
/// This widget is parameterized and reusable - navigation logic should be
/// implemented in the parent widget, not hardcoded here.
class CustomBottomBar extends StatelessWidget {
  /// Current selected index
  final int currentIndex;

  /// Callback when a navigation item is tapped
  final Function(int) onTap;

  /// Optional elevation for the bottom bar
  final double? elevation;

  /// Optional background color override
  final Color? backgroundColor;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.elevation,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        // Provide haptic feedback on tap (150ms micro-interaction)
        HapticFeedback.lightImpact();
        onTap(index);
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor:
          backgroundColor ?? theme.bottomNavigationBarTheme.backgroundColor,
      selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
      unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
      selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle,
      unselectedLabelStyle: theme.bottomNavigationBarTheme.unselectedLabelStyle,
      elevation: elevation ?? 8.0,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      enableFeedback: true,

      // Navigation items matching Mobile Navigation Hierarchy
      items: [
        // Home/Quote Icon - Daily quote consumption
        BottomNavigationBarItem(
          icon: _buildIcon(
            icon: Icons.format_quote_outlined,
            isSelected: false,
            context: context,
          ),
          activeIcon: _buildIcon(
            icon: Icons.format_quote,
            isSelected: true,
            context: context,
          ),
          label: 'Home',
          tooltip: 'Daily quotes',
        ),

        // Categories/Grid Icon - Themed quote browsing
        BottomNavigationBarItem(
          icon: _buildIcon(
            icon: Icons.grid_view_outlined,
            isSelected: false,
            context: context,
          ),
          activeIcon: _buildIcon(
            icon: Icons.grid_view,
            isSelected: true,
            context: context,
          ),
          label: 'Categories',
          tooltip: 'Browse by category',
        ),

        // Heart Icon - Personal favorites collection
        BottomNavigationBarItem(
          icon: _buildIcon(
            icon: Icons.favorite_outline,
            isSelected: false,
            context: context,
          ),
          activeIcon: _buildIcon(
            icon: Icons.favorite,
            isSelected: true,
            context: context,
          ),
          label: 'Favorites',
          tooltip: 'Saved quotes',
        ),

        // Settings/Gear Icon - App configuration
        BottomNavigationBarItem(
          icon: _buildIcon(
            icon: Icons.settings_outlined,
            isSelected: false,
            context: context,
          ),
          activeIcon: _buildIcon(
            icon: Icons.settings,
            isSelected: true,
            context: context,
          ),
          label: 'Settings',
          tooltip: 'App settings',
        ),
      ],
    );
  }

  /// Builds an icon with subtle scale animation for selected state
  /// Implements 0.95x scale transform with 150ms duration for micro-feedback
  Widget _buildIcon({
    required IconData icon,
    required bool isSelected,
    required BuildContext context,
  }) {
    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: Icon(icon, size: 24),
    );
  }
}
