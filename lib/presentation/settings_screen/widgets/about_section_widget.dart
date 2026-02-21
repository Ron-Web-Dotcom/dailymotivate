import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for displaying app information and external links
class AboutSectionWidget extends StatefulWidget {
  const AboutSectionWidget({super.key});

  @override
  State<AboutSectionWidget> createState() => _AboutSectionWidgetState();
}

class _AboutSectionWidgetState extends State<AboutSectionWidget> {
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appVersion = '1.0.0';
        });
      }
    }
  }

  Future<void> _launchPrivacyPolicy(BuildContext context) async {
    const privacyPolicyUrl =
        'https://ron-web-dotcom.github.io/legal-page/privacy.html';

    try {
      final Uri url = Uri.parse(privacyPolicyUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not open privacy policy. Please try again later.',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error opening privacy policy. Please check your internet connection.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildPrivacySection(ThemeData theme, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(content, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
      ],
    );
  }

  Future<void> _requestReview(BuildContext context) async {
    final InAppReview inAppReview = InAppReview.instance;

    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your feedback!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Fallback to store listing if review not available
        await inAppReview.openStoreListing();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening app store...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open review. Please try again later.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          context: context,
          icon: 'info',
          title: 'App Version',
          subtitle: '1.0.0 (Build 1)',
          onTap: null,
        ),
        SizedBox(height: 1.h),
        _buildInfoRow(
          context: context,
          icon: 'privacy_tip',
          title: 'Privacy Policy',
          subtitle: 'View our privacy policy',
          onTap: () => _launchPrivacyPolicy(context),
        ),
        SizedBox(height: 1.h),
        _buildInfoRow(
          context: context,
          icon: 'gavel',
          title: 'Terms of Service',
          subtitle: 'View terms and conditions',
          onTap: () => _launchTermsOfService(),
        ),
      ],
    );
  }

  Future<void> _launchTermsOfService() async {
    const url = 'https://ron-web-dotcom.github.io/legal-page/terms.html';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Terms of Service'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening Terms of Service'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildInfoRow(
            context: context,
            icon: 'info',
            title: 'App Version',
            subtitle: _appVersion,
            onTap: null,
          ),
          SizedBox(height: 1.h),
          _buildInfoRow(
            context: context,
            icon: 'privacy_tip',
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            onTap: () => _launchPrivacyPolicy(context),
          ),
          SizedBox(height: 1.h),
          _buildInfoRow(
            context: context,
            icon: 'star',
            title: 'Rate App',
            subtitle: 'Share your feedback',
            onTap: () => _requestReview(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            onTap != null
                ? CustomIconWidget(
                    iconName: 'chevron_right',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}