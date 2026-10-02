import 'package:flutter/material.dart';

/// Custom painter for the Category Side Rail that paints the brand-colored rail
/// background and renders a smooth concave notch on the right edge around the
/// currently selected category item.
class RailNotchPainter extends CustomPainter {
  final Color railColor;
  final Color contentBgColor;
  final double? notchCenterY;
  final double notchRadius;
  final double notchDepth;
  final double outerCornerRadius;
  final double transition;

  const RailNotchPainter({
    required this.railColor,
    required this.contentBgColor,
    this.notchCenterY,
    this.notchRadius = 30.0,
    this.notchDepth = 14.0,
    this.outerCornerRadius = 28.0,
    this.transition = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();

    // Start at top-left corner
    path.moveTo(0, 0);

    // Top edge to top-right
    path.lineTo(w, 0);

    // If there is an active notch on the right edge
    if (notchCenterY != null && notchCenterY! > 0) {
      final cy = notchCenterY!;
      final topY = cy - notchRadius - transition;
      final bottomY = cy + notchRadius + transition;

      // Line down to the notch top entry
      path.lineTo(w, topY.clamp(0.0, h));

      // Smooth cubic bezier inwards (concave curve into the rail)
      path.cubicTo(
        w,
        cy - notchRadius,
        w - notchDepth,
        cy - notchRadius + 4,
        w - notchDepth,
        cy,
      );

      // Smooth cubic bezier outwards back to the rail right edge
      path.cubicTo(
        w - notchDepth,
        cy + notchRadius - 4,
        w,
        cy + notchRadius,
        w,
        bottomY.clamp(0.0, h),
      );
    }

    // Down to bottom-right
    path.lineTo(w, h);

    // Bottom edge to bottom-left
    path.lineTo(0, h);

    // Up the left edge back to start
    path.lineTo(0, 0);

    path.close();

    final paint = Paint()
      ..color = railColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Draw smooth curved arc highlight at the notch corner
    if (notchCenterY != null && notchCenterY! > 0) {
      final cy = notchCenterY!;
      final arcPaint = Paint()
        ..color = contentBgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final arcPath = Path();
      arcPath.moveTo(w, cy - notchRadius - transition);
      arcPath.cubicTo(
        w,
        cy - notchRadius,
        w - notchDepth,
        cy - notchRadius + 4,
        w - notchDepth,
        cy,
      );
      arcPath.cubicTo(
        w - notchDepth,
        cy + notchRadius - 4,
        w,
        cy + notchRadius,
        w,
        cy + notchRadius + transition,
      );
      canvas.drawPath(arcPath, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RailNotchPainter oldDelegate) {
    return oldDelegate.railColor != railColor ||
        oldDelegate.contentBgColor != contentBgColor ||
        oldDelegate.notchCenterY != notchCenterY ||
        oldDelegate.notchRadius != notchRadius ||
        oldDelegate.notchDepth != notchDepth;
  }
}
