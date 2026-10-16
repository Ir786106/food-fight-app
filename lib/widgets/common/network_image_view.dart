import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_fight/core/constants/app_colors.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/services/app_image_storage_service.dart';
import '../skeleton/shimmer_container.dart';

/// Production-ready Image Viewer supporting:
/// - Provider-agnostic storage resolution (Firebase / Supabase fallback / CDN)
/// - Robust disk & memory caching via CachedNetworkImage
/// - Retry mechanism with exponential backoff
/// - Visually distinct states: "No Image Set" vs "Failed to Load"
/// - Branded local fallback asset (Food Fight emblem)
/// - Non-blocking failure protection
class NetworkImageView extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final String fallbackEmoji;
  final IconData fallbackIcon;
  final bool enableRetry;

  const NetworkImageView({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
    this.fallbackEmoji = '',
    this.fallbackIcon = Icons.fastfood_rounded,
    this.enableRetry = true,
  });

  @override
  State<NetworkImageView> createState() => _NetworkImageViewState();
}

class _NetworkImageViewState extends State<NetworkImageView> {
  int _retryAttempt = 0;
  bool _isRetrying = false;
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolveUrl();
  }

  @override
  void didUpdateWidget(covariant NetworkImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _retryAttempt = 0;
      _resolveUrl();
    }
  }

  void _resolveUrl() {
    _resolvedUrl = AppImageStorageService.resolveImageUrl(widget.imageUrl);
  }

  void _handleRetry() {
    if (_isRetrying || !widget.enableRetry) return;

    setState(() {
      _isRetrying = true;
      _retryAttempt++;
    });

    // Exponential backoff: 300ms, 600ms, 1200ms (max 2s)
    final backoffMs = (300 * (1 << (_retryAttempt - 1))).clamp(300, 2000);
    Future.delayed(Duration(milliseconds: backoffMs), () {
      if (!mounted) return;
      // Invalidate CachedNetworkImage memory cache entry by forcing a tick
      PaintingBinding.instance.imageCache.clearLiveImages();
      setState(() {
        _isRetrying = false;
        _resolveUrl();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final safeWidth = (widget.width != null && widget.width! > 0 && !widget.width!.isNaN && !widget.width!.isInfinite)
        ? widget.width
        : null;
    final safeHeight = (widget.height != null && widget.height! > 0 && !widget.height!.isNaN && !widget.height!.isInfinite)
        ? widget.height
        : null;

    Widget content;

    // 1. If URL is empty or null -> "No Image Set" visual
    if (_resolvedUrl == null || _resolvedUrl!.isEmpty) {
      content = _buildNoImageSet(context, safeWidth, safeHeight);
    }
    // 2. Local asset URL
    else if (_resolvedUrl!.startsWith('assets/')) {
      content = Image.asset(
        _resolvedUrl!,
        width: safeWidth,
        height: safeHeight,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _buildNoImageSet(context, safeWidth, safeHeight),
      );
    }
    // 3. Network URL
    else {
      final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
      final int? memWidth = safeWidth != null ? (safeWidth * dpr).round().clamp(48, 1080) : null;
      final int? memHeight = safeHeight != null ? (safeHeight * dpr).round().clamp(48, 1080) : null;

      content = CachedNetworkImage(
        key: ValueKey('${_resolvedUrl}_retry_$_retryAttempt'),
        imageUrl: _resolvedUrl!,
        width: safeWidth,
        height: safeHeight,
        fit: widget.fit,
        memCacheWidth: memWidth,
        memCacheHeight: memHeight,
        maxWidthDiskCache: 1080,
        maxHeightDiskCache: 1080,
        placeholder: (context, url) => ShimmerContainer(
          width: safeWidth,
          height: safeHeight,
          borderRadius: widget.borderRadius,
        ),
        errorWidget: (context, url, error) {
          AppLogger.warn('Image failed to load: $url (error: $error)', tag: 'NetworkImageView');
          return _buildFailedToLoad(context, safeWidth, safeHeight);
        },
      );
    }

    if (widget.borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: content,
      );
    }

    return content;
  }

  /// Visually distinct state: No image set by admin/restaurant
  Widget _buildNoImageSet(BuildContext context, double? safeWidth, double? safeHeight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = (safeHeight != null && safeHeight > 0) ? (safeHeight * 0.40).clamp(16.0, 56.0) : 24.0;

    return Container(
      width: safeWidth,
      height: safeHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.brandYellow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : AppColors.brandYellow.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Center(
        child: widget.fallbackEmoji.isNotEmpty
            ? Text(widget.fallbackEmoji, style: TextStyle(fontSize: size))
            : Icon(
                widget.fallbackIcon,
                color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                size: size,
              ),
      ),
    );
  }

  /// Visually distinct state: Failed to load over network, with retry capability
  Widget _buildFailedToLoad(BuildContext context, double? safeWidth, double? safeHeight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconSize = (safeHeight != null && safeHeight > 0) ? (safeHeight * 0.30).clamp(14.0, 32.0) : 18.0;

    return Container(
      width: safeWidth,
      height: safeHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1E1E) : const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: InkWell(
        onTap: widget.enableRetry ? _handleRetry : null,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Center(
          child: _isRetrying
              ? SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                      size: iconSize,
                    ),
                    if (safeHeight != null && safeHeight > 70) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
