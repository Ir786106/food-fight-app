import 'package:flutter/material.dart';
import 'package:food_fight/core/constants/app_colors.dart';

/// Image viewer supporting Supabase public URLs, error fallback, and loading shimmer
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
    final validUrl = imageUrl != null && imageUrl!.trim().isNotEmpty && imageUrl!.startsWith('http');

    Widget imageContent;

    if (validUrl) {
      imageContent = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade100,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else {
      imageContent = _buildFallback();
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Center(
        child: fallbackEmoji.isNotEmpty
            ? Text(fallbackEmoji, style: TextStyle(fontSize: (height != null ? height! * 0.45 : 24)))
            : Icon(fallbackIcon, color: AppColors.primary, size: (height != null ? height! * 0.45 : 24)),
      ),
    );
  }
}
