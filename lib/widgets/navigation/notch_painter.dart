import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Custom painter for the floating bottom navigation bar that renders
/// a smooth pill shape with a cubic-bezier concave center notch.
///
/// Designed to wrap the 60px circular cart button with continuous smooth curves.
class FloatingNavNotchPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final double notchRadius;
  final double notchDepth;
  final double cornerRadius;
  final double borderWidth;

  const FloatingNavNotchPainter({
    required this.color,
    this.borderColor = AppColors.border,
    this.shadowColor = const Color(0x1F2A1415), // 0 8 24 rgba(42,20,21,0.12)
    this.notchRadius = 36.0,
    this.notchDepth = 22.0,
    this.cornerRadius = 28.0,
    this.borderWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    const transition = 14.0;

    final path = Path();
    path.moveTo(cornerRadius, 0);

    // Top-left line towards the center notch
    path.lineTo(cx - notchRadius - transition, 0);

    // Smooth cubic bezier down into the notch
    path.cubicTo(
      cx - notchRadius,
      0,
      cx - notchRadius + 4,
      notchDepth,
      cx,
      notchDepth,
    );

    // Smooth cubic bezier out of the notch
    path.cubicTo(
      cx + notchRadius - 4,
      notchDepth,
      cx + notchRadius,
      0,
      cx + notchRadius + transition,
      0,
    );

    // Top-right line to corner
    path.lineTo(w - cornerRadius, 0);

    // Top-right corner
    path.arcToPoint(
      Offset(w, cornerRadius),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Right side
    path.lineTo(w, h - cornerRadius);

    // Bottom-right corner
    path.arcToPoint(
      Offset(w - cornerRadius, h),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Bottom edge
    path.lineTo(cornerRadius, h);

    // Bottom-left corner
    path.arcToPoint(
      Offset(0, h - cornerRadius),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Left side
    path.lineTo(0, cornerRadius);

    // Top-left corner
    path.arcToPoint(
      Offset(cornerRadius, 0),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    path.close();

    // 1. Soft blurred elevation shadow (0 8 24 rgba(42,20,21,0.12))
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawPath(path.shift(const Offset(0, 8)), shadowPaint);

    // 2. Bar surface fill
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Subtle stroke border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant FloatingNavNotchPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.notchRadius != notchRadius ||
        oldDelegate.notchDepth != notchDepth ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.borderWidth != borderWidth;
  }
}
