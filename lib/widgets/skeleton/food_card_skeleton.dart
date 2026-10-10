import 'package:flutter/material.dart';
import 'shimmer_container.dart';

/// Shimmer skeleton loader for FoodCard items in Grid and List views
class FoodCardSkeleton extends StatelessWidget {
  final bool isRow;

  const FoodCardSkeleton({super.key}) : isRow = false;

  const FoodCardSkeleton.row({super.key}) : isRow = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isRow) {
      return Container(
        height: 104,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: const Row(
          children: [
            ShimmerContainer(
              width: 80,
              height: 80,
              borderRadius: 14,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerContainer(
                    width: 140,
                    height: 14,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 6),
                  ShimmerContainer(
                    width: 90,
                    height: 10,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 12),
                  ShimmerContainer(
                    width: 60,
                    height: 16,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            ShimmerContainer.circular(size: 32),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          Expanded(
            child: ShimmerContainer(
              width: double.infinity,
              borderRadius: 12,
            ),
          ),
          SizedBox(height: 12),
          // Title skeleton
          ShimmerContainer(
            width: double.infinity,
            height: 14,
            borderRadius: 4,
          ),
          SizedBox(height: 6),
          // Subtitle skeleton
          ShimmerContainer(
            width: 80,
            height: 10,
            borderRadius: 4,
          ),
          SizedBox(height: 12),
          // Price & Add button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerContainer(
                width: 60,
                height: 16,
                borderRadius: 4,
              ),
              ShimmerContainer.circular(size: 32),
            ],
          ),
        ],
      ),
    );
  }
}
