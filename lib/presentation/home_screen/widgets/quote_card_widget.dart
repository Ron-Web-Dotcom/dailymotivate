import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/favorites_service.dart';
import '../../../services/share_service.dart';
import '../../../widgets/custom_icon_widget.dart';

class QuoteCardWidget extends StatefulWidget {
  final Map<String, dynamic> quote;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const QuoteCardWidget({
    required this.quote,
    required this.onNext,
    required this.onPrevious,
    super.key,
  });

  @override
  State<QuoteCardWidget> createState() => _QuoteCardWidgetState();
}

class _QuoteCardWidgetState extends State<QuoteCardWidget> {
  final FavoritesService _favoritesService = FavoritesService();
  final ShareService _shareService = ShareService();
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  @override
  void didUpdateWidget(QuoteCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quote['id'] != widget.quote['id']) {
      _checkFavoriteStatus();
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _favoritesService.isFavorite(widget.quote['id'] as int);
    if (mounted) {
      setState(() => _isFavorite = isFav);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (_isFavorite) {
        await _favoritesService.removeFavorite(widget.quote['id'] as int);
        if (mounted) {
          setState(() => _isFavorite = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await _favoritesService.addFavorite(widget.quote);
        if (mounted) {
          setState(() => _isFavorite = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to favorites'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(
      ClipboardData(
        text: '"${widget.quote['text']}" - ${widget.quote['author']}',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quote copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showShareOptions() {
    _shareService.showShareOptions(
      context,
      widget.quote['text'] as String,
      widget.quote['author'] as String,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quote icon
          Semantics(
            label: 'Motivational quote',
            child: CustomIconWidget(
              iconName: 'format_quote',
              color: theme.colorScheme.primary,
              size: 12.w,
            ),
          ),
          SizedBox(height: 4.h),

          // Quote text
          Semantics(
            label: 'Quote: ${widget.quote['text']}',
            child: Text(
              widget.quote['text'] as String,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 3.h),

          // Author
          Semantics(
            label: 'Author: ${widget.quote['author']}',
            child: Text(
              '— ${widget.quote['author']}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 4.h),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Semantics(
                label: _isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                button: true,
                child: _buildActionButton(
                  icon: _isFavorite ? 'favorite' : 'favorite_border',
                  onTap: _toggleFavorite,
                  color: _isFavorite ? Colors.red : theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
              Semantics(
                label: 'Copy quote to clipboard',
                button: true,
                child: _buildActionButton(
                  icon: 'content_copy',
                  onTap: _copyToClipboard,
                  color: theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
              Semantics(
                label: 'Share quote',
                button: true,
                child: _buildActionButton(
                  icon: 'share',
                  onTap: _showShareOptions,
                  color: theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required VoidCallback onTap,
    required Color color,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomIconWidget(iconName: icon, color: color, size: 6.w),
      ),
    );
  }
}