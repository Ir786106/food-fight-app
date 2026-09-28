import 'package:flutter/material.dart';
import '../../services/rider_location_service.dart';
import '../../theme/app_theme.dart';

class LiveTrackingMapWidget extends StatefulWidget {
  final String orderId;
  final String deliveryAddress;
  final bool isOutForDelivery;

  const LiveTrackingMapWidget({
    super.key,
    required this.orderId,
    required this.deliveryAddress,
    this.isOutForDelivery = true,
  });

  @override
  State<LiveTrackingMapWidget> createState() => _LiveTrackingMapWidgetState();
}

class _LiveTrackingMapWidgetState extends State<LiveTrackingMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<RiderLocationData?>(
      stream: RiderLocationService.watchOrderRiderLocation(widget.orderId),
      builder: (context, snapshot) {
        final location = snapshot.data;
        final hasActiveGps = location != null && location.isActive;

        return Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2028) : const Color(0xFFEDF2F7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Stylized Vector Map Canvas
                CustomPaint(
                  size: const Size(double.infinity, 240),
                  painter: _MapGridPainter(
                    isDark: isDark,
                    pulseValue: _pulseController.value,
                    isOutForDelivery: widget.isOutForDelivery,
                  ),
                ),

                // Top GPS Status Pill
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hasActiveGps
                          ? AppColors.success
                          : (widget.isOutForDelivery ? AppColors.primary : AppColors.textSecondary),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasActiveGps
                              ? 'LIVE GPS ACTIVE • ${location.speed > 0 ? '${location.speed.toStringAsFixed(0)} km/h' : 'Moving'}'
                              : (widget.isOutForDelivery ? 'RIDER DISPATCHED' : 'KITCHEN DISPATCH ROUTE'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Right ETA Badge
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black87 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          widget.isOutForDelivery ? 'ETA: 12-18 min' : 'Prep: ~20 min',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Location Info Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF13171E) : Colors.white).withValues(alpha: 0.94),
                      border: Border(
                        top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.navigation_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Destination: ${widget.deliveryAddress}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapGridPainter extends CustomPainter {
  final bool isDark;
  final double pulseValue;
  final bool isOutForDelivery;

  _MapGridPainter({
    required this.isDark,
    required this.pulseValue,
    required this.isOutForDelivery,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF161A22) : const Color(0xFFE8EEF5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid road network simulation
    final roadPaint = Paint()
      ..color = (isDark ? const Color(0xFF222834) : const Color(0xFFD6E0EC))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Horizontal & vertical grid avenues
    for (double y = 40; y < size.height; y += 45) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    for (double x = 40; x < size.width; x += 55) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }

    // Delivery Route Polyline
    final start = Offset(size.width * 0.18, size.height * 0.65); // Restaurant
    final end = Offset(size.width * 0.82, size.height * 0.35); // Destination
    final mid = Offset(size.width * 0.45, size.height * 0.40);

    final routePath = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(mid.dx, start.dy)
      ..lineTo(mid.dx, end.dy)
      ..lineTo(end.dx, end.dy);

    final routeGlow = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routeLine = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(routePath, routeGlow);
    canvas.drawPath(routePath, routeLine);

    // Restaurant Marker (Start)
    final restPaint = Paint()..color = const Color(0xFFFF5722);
    canvas.drawCircle(start, 9, restPaint);
    final restInner = Paint()..color = Colors.white;
    canvas.drawCircle(start, 4, restInner);

    // Destination Marker (End)
    final destPaint = Paint()..color = AppColors.error;
    canvas.drawCircle(end, 10, destPaint);
    final destInner = Paint()..color = Colors.white;
    canvas.drawCircle(end, 5, destInner);

    // Live Rider Position (animates along route or stays at active point)
    final riderPos = isOutForDelivery
        ? Offset(
            mid.dx + (end.dx - mid.dx) * 0.45,
            end.dy,
          )
        : start;

    // Pulsing Radar Ring around Rider
    final radarRadius = 14 + (pulseValue * 18);
    final radarPaint = Paint()
      ..color = const Color(0xFF00C853).withValues(alpha: 1.0 - pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(riderPos, radarRadius, radarPaint);

    // Rider Marker Core
    final riderPaint = Paint()..color = const Color(0xFF00C853);
    canvas.drawCircle(riderPos, 9, riderPaint);
    final riderCenter = Paint()..color = Colors.white;
    canvas.drawCircle(riderPos, 4, riderCenter);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isOutForDelivery != isOutForDelivery;
  }
}
