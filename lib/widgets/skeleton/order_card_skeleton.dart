import 'package:flutter/material.dart';
import 'shimmer_container.dart';

/// Shimmer skeleton loader for Order items
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerContainer(width: 100, height: 14, borderRadius: 4),
              ShimmerContainer(width: 70, height: 22, borderRadius: 12),
            ],
          ),
          SizedBox(height: 12),
          ShimmerContainer(width: 180, height: 12, borderRadius: 4),
          SizedBox(height: 8),
          ShimmerContainer(width: 120, height: 12, borderRadius: 4),
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerContainer(width: 80, height: 16, borderRadius: 4),
              ShimmerContainer(width: 90, height: 32, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}
