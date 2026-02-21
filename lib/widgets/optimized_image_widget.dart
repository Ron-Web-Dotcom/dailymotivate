import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/logger_service.dart';

/// Optimized image loading widget with caching and error handling
class OptimizedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? 'Image',
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ??
            Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        errorWidget: (context, url, error) {
          LoggerService.warning(
            'Failed to load image',
            data: {'url': url, 'error': error.toString()},
          );
          return errorWidget ??
              Icon(
                Icons.broken_image,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              );
        },
        // Caching configuration
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
      ),
    );
  }
}

/// Preload images for better performance
class ImagePreloader {
  static Future<void> preloadImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    try {
      for (final url in imageUrls) {
        await precacheImage(CachedNetworkImageProvider(url), context);
      }
      LoggerService.info('Preloaded ${imageUrls.length} images');
    } catch (e) {
      LoggerService.error('Failed to preload images', error: e);
    }
  }

  static Future<void> clearImageCache() async {
    try {
      await CachedNetworkImage.evictFromCache('');
      LoggerService.info('Image cache cleared');
    } catch (e) {
      LoggerService.error('Failed to clear image cache', error: e);
    }
  }
}
