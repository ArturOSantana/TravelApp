import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/memory_manager_service.dart';

class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final memoryManager = MemoryManagerService();
    final settings = memoryManager.getOptimizedSettings();

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      maxWidthDiskCache: settings['maxImageSize'],
      maxHeightDiskCache: settings['maxImageSize'],
      memCacheWidth:
          memoryManager.isLowEndDevice ? (width?.toInt() ?? 400) : null,
      memCacheHeight:
          memoryManager.isLowEndDevice ? (height?.toInt() ?? 400) : null,
      placeholder: (context, url) {
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
      },
      errorWidget: (context, url, error) {
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(Icons.error_outline, color: Colors.grey),
            );
      },
      fadeInDuration: memoryManager.getAnimationDuration(
        const Duration(milliseconds: 300),
      ),
      fadeOutDuration: memoryManager.getAnimationDuration(
        const Duration(milliseconds: 100),
      ),
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

class OptimizedAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const OptimizedAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final memoryManager = MemoryManagerService();

    Widget imageWidget = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: memoryManager.isLowEndDevice ? width?.toInt() : null,
      cacheHeight: memoryManager.isLowEndDevice ? height?.toInt() : null,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error_outline, color: Colors.grey),
        );
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

class OptimizedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;

  const OptimizedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Icon(fallbackIcon, size: radius),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: CachedNetworkImageProvider(
        imageUrl!,
        maxWidth: (radius * 2).toInt(),
        maxHeight: (radius * 2).toInt(),
      ),
    );
  }
}

