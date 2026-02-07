import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for sharing quotes to various social media platforms
class ShareService {
  static const String _appLink = 'https://dailymotivate.app';
  static const String _appName = 'Daily Motivate';

  /// Format quote text with motivational message and app link
  String _formatQuoteText(String quote, String author) {
    return '"$quote"\n\n- $author\n\n✨ Get daily motivation from $_appName\n$_appLink';
  }

  /// Share to WhatsApp
  Future<bool> shareToWhatsApp(String quote, String author) async {
    try {
      final text = _formatQuoteText(quote, author);
      final encodedText = Uri.encodeComponent(text);
      final url = Uri.parse('whatsapp://send?text=$encodedText');

      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web WhatsApp
        final webUrl = Uri.parse('https://wa.me/?text=$encodedText');
        if (await canLaunchUrl(webUrl)) {
          return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error sharing to WhatsApp: $e');
      return false;
    }
  }

  /// Share to Twitter (X)
  Future<bool> shareToTwitter(String quote, String author) async {
    try {
      final text = '"$quote" - $author\n\n✨ $_appName\n$_appLink';
      final encodedText = Uri.encodeComponent(text);

      // Try Twitter app first
      final url = Uri.parse('twitter://post?message=$encodedText');
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }

      // Fallback to web Twitter
      final webUrl = Uri.parse(
        'https://twitter.com/intent/tweet?text=$encodedText',
      );
      if (await canLaunchUrl(webUrl)) {
        return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }

      return false;
    } catch (e) {
      debugPrint('Error sharing to Twitter: $e');
      return false;
    }
  }

  /// Share to Instagram using platform-native intents with proper app detection
  Future<bool> shareToInstagram(
    String quote,
    String author,
    BuildContext context,
  ) async {
    try {
      final text = _formatQuoteText(quote, author);

      // Copy text to clipboard first (user can paste in Instagram)
      await Clipboard.setData(ClipboardData(text: text));

      // Try multiple Instagram deep link schemes
      final instagramSchemes = [
        'instagram://camera', // Instagram camera (most universal)
        'instagram://story-camera', // Instagram story
        'instagram://app', // Instagram main app
      ];

      bool appOpened = false;

      for (final scheme in instagramSchemes) {
        try {
          final url = Uri.parse(scheme);
          // Try to launch without checking canLaunchUrl first
          // This is more reliable as canLaunchUrl may fail even when app exists
          final launched = await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          ).timeout(const Duration(seconds: 2), onTimeout: () => false);

          if (launched) {
            appOpened = true;
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Quote copied! Paste it in Instagram'),
                  duration: Duration(seconds: 3),
                  backgroundColor: Color(0xFFE4405F),
                ),
              );
            }
            return true;
          }
        } catch (e) {
          // Continue to next scheme
          debugPrint('Instagram scheme $scheme failed: $e');
          continue;
        }
      }

      // If no deep link worked, try platform share with Instagram hint
      if (!appOpened) {
        try {
          final result = await Share.share(text, subject: 'Share to Instagram');

          if (result.status == ShareResultStatus.success) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '📋 Quote copied! Select Instagram from share menu',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return true;
          }
        } catch (shareError) {
          debugPrint('Share sheet error: $shareError');
        }
      }

      // Final fallback - show helpful message
      if (!appOpened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '📋 Quote copied to clipboard!\n'
              'Open Instagram and paste to share',
            ),
            duration: Duration(seconds: 4),
            backgroundColor: Color(0xFFE4405F),
          ),
        );
      }

      return false;
    } catch (e) {
      debugPrint('Error sharing to Instagram: $e');
      // Always ensure clipboard copy as absolute fallback
      try {
        await Clipboard.setData(
          ClipboardData(text: _formatQuoteText(quote, author)),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📋 Quote copied to clipboard!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (clipboardError) {
        debugPrint('Clipboard fallback error: $clipboardError');
      }
      return false;
    }
  }

  /// Share to TikTok using platform-native intents with proper app detection
  Future<bool> shareToTikTok(
    String quote,
    String author,
    BuildContext context,
  ) async {
    try {
      final text = _formatQuoteText(quote, author);

      // Copy text to clipboard first
      await Clipboard.setData(ClipboardData(text: text));

      // TikTok deep link schemes for different regions and versions
      final tiktokSchemes = [
        'tiktok://camera', // TikTok camera
        'snssdk1233://camera', // TikTok alternative
        'snssdk1180://camera', // TikTok Lite
        'tiktok://app', // TikTok main app
      ];

      bool appOpened = false;

      for (final scheme in tiktokSchemes) {
        try {
          final url = Uri.parse(scheme);
          // Try to launch without checking canLaunchUrl first
          final launched = await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          ).timeout(const Duration(seconds: 2), onTimeout: () => false);

          if (launched) {
            appOpened = true;
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Quote copied! Paste it in TikTok'),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.black,
                ),
              );
            }
            return true;
          }
        } catch (e) {
          // Continue to next scheme
          debugPrint('TikTok scheme $scheme failed: $e');
          continue;
        }
      }

      // If no deep link worked, try platform share
      if (!appOpened) {
        try {
          final result = await Share.share(text, subject: 'Share to TikTok');

          if (result.status == ShareResultStatus.success) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '📋 Quote copied! Select TikTok from share menu',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return true;
          }
        } catch (shareError) {
          debugPrint('Share sheet error: $shareError');
        }
      }

      // Final fallback - show helpful message
      if (!appOpened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '📋 Quote copied to clipboard!\n'
              'Open TikTok and paste to share',
            ),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.black,
          ),
        );
      }

      return false;
    } catch (e) {
      debugPrint('Error sharing to TikTok: $e');
      // Always ensure clipboard copy as absolute fallback
      try {
        await Clipboard.setData(
          ClipboardData(text: _formatQuoteText(quote, author)),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📋 Quote copied to clipboard!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (clipboardError) {
        debugPrint('Clipboard fallback error: $clipboardError');
      }
      return false;
    }
  }

  /// Share via Email
  Future<bool> shareViaEmail(String quote, String author) async {
    try {
      final subject = Uri.encodeComponent('Motivational Quote from $_appName');
      final body = Uri.encodeComponent(_formatQuoteText(quote, author));
      final url = Uri.parse('mailto:?subject=$subject&body=$body');

      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('Error sharing via email: $e');
      return false;
    }
  }

  /// Share via SMS
  Future<bool> shareViaSMS(String quote, String author) async {
    try {
      final text = _formatQuoteText(quote, author);
      final encodedText = Uri.encodeComponent(text);
      final url = Uri.parse('sms:?body=$encodedText');

      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('Error sharing via SMS: $e');
      return false;
    }
  }

  /// Generic share (uses platform share sheet)
  Future<bool> shareGeneric(String quote, String author) async {
    try {
      final text = _formatQuoteText(quote, author);
      final result = await Share.share(
        text,
        subject: 'Motivational Quote from $_appName',
      );
      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('Error with generic share: $e');
      return false;
    }
  }

  /// Show share options bottom sheet
  Future<void> showShareOptions(
    BuildContext context,
    String quote,
    String author,
  ) async {
    final theme = Theme.of(context);

    await showModalBottomSheet(
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
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Share Quote',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildShareOption(
                context,
                'WhatsApp',
                const Color(0xFF25D366),
                () async {
                  Navigator.pop(context);
                  final success = await shareToWhatsApp(quote, author);
                  if (!success && context.mounted) {
                    _showErrorSnackBar(context, 'WhatsApp not available');
                  }
                },
              ),
              _buildShareOption(
                context,
                'Twitter (X)',
                const Color(0xFF1DA1F2),
                () async {
                  Navigator.pop(context);
                  final success = await shareToTwitter(quote, author);
                  if (!success && context.mounted) {
                    _showErrorSnackBar(context, 'Twitter not available');
                  }
                },
              ),
              _buildShareOption(
                context,
                'Email',
                theme.colorScheme.primary,
                () async {
                  Navigator.pop(context);
                  final success = await shareViaEmail(quote, author);
                  if (!success && context.mounted) {
                    _showErrorSnackBar(context, 'Email not available');
                  }
                },
              ),
              _buildShareOption(
                context,
                'SMS',
                theme.colorScheme.secondary,
                () async {
                  Navigator.pop(context);
                  final success = await shareViaSMS(quote, author);
                  if (!success && context.mounted) {
                    _showErrorSnackBar(context, 'SMS not available');
                  }
                },
              ),
              _buildShareOption(
                context,
                'More Options',
                theme.colorScheme.tertiary,
                () async {
                  Navigator.pop(context);
                  await shareGeneric(quote, author);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption(
    BuildContext context,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(Icons.share, color: color, size: 24),
      title: Text(title, style: theme.textTheme.bodyLarge),
      onTap: onTap,
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
