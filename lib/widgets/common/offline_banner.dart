import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Connectivity aware offline banner.
/// Shows a non-intrusive top banner when internet connectivity is lost,
/// and smoothly animates away when back online.
class OfflineBanner extends StatefulWidget {
  final Widget? child;

  const OfflineBanner({super.key, this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _checkConnectivity();
      // Periodically check connection every 10 seconds
      _checkTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkConnectivity());
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (mounted && _isOffline != !hasConnection) {
        setState(() {
          _isOffline = !hasConnection;
        });
      }
    } catch (_) {
      if (mounted && !_isOffline) {
        setState(() {
          _isOffline = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF382C10) : const Color(0xFFFFF7E6),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.brandYellow.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 14,
                  color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                ),
                const SizedBox(width: 8),
                Text(
                  "You're offline. Browsing in cached mode.",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon,
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: _isOffline ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
