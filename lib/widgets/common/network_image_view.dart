import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_fight/core/constants/app_colors.dart';
import '../../services/supabase/supabase_image_storage_service.dart';
import '../skeleton/shimmer_container.dart';

/// Image viewer supporting Supabase public URLs, CachedNetworkImage, error fallback, and loading shimmer
class NetworkImageView extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final String fallbackEmoji;
  final IconData fallbackIcon;

  const NetworkImageView({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
    this.fallbackEmoji = '🥊',
    this.fallbackIcon = Icons.fastfood_rounded,
  });

  @override
  Widget build(BuildContext context) {
    String? resolvedUrl;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      final trimmed = imageUrl!.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        resolvedUrl = Uri.encodeFull(trimmed);
      } else if (!trimmed.startsWith('assets/')) {
        final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
        try {
          final publicUrl = SupabaseImageStorageService().getImageUrl(cleanPath);
          if (publicUrl.isNotEmpty && publicUrl.startsWith('http')) {
            resolvedUrl = Uri.encodeFull(publicUrl);
          }
        } catch (_) {}
      }
    }

    final safeWidth = (width != null && width! > 0 && !width!.isNaN && !width!.isInfinite) ? width : null;
    final safeHeight = (height != null && height! > 0 && !height!.isNaN && !height!.isInfinite) ? height : null;

    Widget imageContent;

    if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
      imageContent = CachedNetworkImage(
        imageUrl: resolvedUrl,
        width: safeWidth,
        height: safeHeight,
        fit: fit,
        placeholder: (context, url) => ShimmerContainer(
          width: safeWidth,
          height: safeHeight,
          borderRadius: borderRadius,
        ),
        errorWidget: (context, url, error) {
          debugPrint('NetworkImageView failed to load: $url, error: $error');
          return _buildFallback(safeWidth, safeHeight);
        },
      );
    } else {
      imageContent = _buildFallback(safeWidth, safeHeight);
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildFallback(double? safeWidth, double? safeHeight) {
    final fontSize = (safeHeight != null && safeHeight > 0) ? (safeHeight * 0.44).clamp(14.0, 72.0) : 24.0;

    return Container(
      width: safeWidth,
      height: safeHeight,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Center(
        child: fallbackEmoji.isNotEmpty
            ? Text(fallbackEmoji, style: TextStyle(fontSize: fontSize))
            : Icon(fallbackIcon, color: AppColors.primary, size: fontSize),
      ),
    );
  }
}
