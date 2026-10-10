import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base shimmer container utility providing dark and light mode reactive skeleton gradients
class ShimmerContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final ShapeBorder? shapeBorder;

  const ShimmerContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shapeBorder,
  });

  const ShimmerContainer.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = size / 2,
        shapeBorder = const CircleBorder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF1E293B) : Colors.grey.shade300;
    final highlightColor = isDark ? const Color(0xFF334155) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: shapeBorder != null
            ? ShapeDecoration(shape: shapeBorder!, color: baseColor)
            : BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
      ),
    );
  }
}
