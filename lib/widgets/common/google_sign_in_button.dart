import 'package:flutter/material.dart';

/// Styled "Continue with Google" button with custom-drawn official 4-color Google icon
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continue with Google',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.7 : 0.9),
          width: 1.2,
        ),
      ),
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GoogleLogoWidget(size: 22),
                    const SizedBox(width: 12),
                    Text(
                      text,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Custom painted Google "G" logo with authentic 4 colors
class GoogleLogoWidget extends StatelessWidget {
  final double size;

  const GoogleLogoWidget({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double radius = w * 0.44;

    final Paint blue = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    final Paint red = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;
    final Paint yellow = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    final Paint green = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;

    final Rect rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Red (top)
    final Path redPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(rect, -3.14159 * 0.75, 3.14159 * 0.55, false)
      ..close();
    canvas.drawPath(redPath, red);

    // Yellow (left)
    final Path yellowPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(rect, -3.14159 * 1.3, 3.14159 * 0.55, false)
      ..close();
    canvas.drawPath(yellowPath, yellow);

    // Green (bottom)
    final Path greenPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(rect, 3.14159 * 0.15, 3.14159 * 0.60, false)
      ..close();
    canvas.drawPath(greenPath, green);

    // Blue (right & horizontal bar)
    final Path bluePath = Path()
      ..moveTo(cx, cy)
      ..arcTo(rect, -3.14159 * 0.20, 3.14159 * 0.45, false)
      ..close();
    canvas.drawPath(bluePath, blue);

    // Center circle mask
    final Paint centerWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius * 0.58, centerWhite);

    // Blue horizontal bar
    final Paint barPaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    final Rect barRect = Rect.fromLTWH(cx, cy - (radius * 0.24), radius, radius * 0.48);
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
