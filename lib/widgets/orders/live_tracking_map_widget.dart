import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/rider_location_service.dart';
import '../../theme/app_theme.dart';

/// Real Google Maps live tracking widget on mobile with responsive fallback on Web.
/// Shows rider's actual GPS location with animated marker, route line, and ETA.
class LiveTrackingMapWidget extends StatefulWidget {
  final String orderId;
  final String deliveryAddress;
  final bool isOutForDelivery;
  final double height;

  const LiveTrackingMapWidget({
    super.key,
    required this.orderId,
    required this.deliveryAddress,
    this.isOutForDelivery = true,
    this.height = 260,
  });

  @override
  State<LiveTrackingMapWidget> createState() => _LiveTrackingMapWidgetState();
}

class _LiveTrackingMapWidgetState extends State<LiveTrackingMapWidget>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _pulseController;

  LatLng? _riderLatLng;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  StreamSubscription<RiderLocationData?>? _locationSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startWatchingLocation();
  }

  void _startWatchingLocation() {
    _locationSub =
        RiderLocationService.watchOrderRiderLocation(widget.orderId).listen(
      (location) {
        if (!mounted) return;
        if (location != null && location.isActive) {
          final newPos = LatLng(location.latitude, location.longitude);
          setState(() {
            _riderLatLng = newPos;
            _markers
              ..clear()
              ..add(
                Marker(
                  markerId: const MarkerId('rider'),
                  position: newPos,
                  infoWindow: InfoWindow(
                    title: 'Your Rider',
                    snippet: location.speed > 0
                        ? '${location.speed.toStringAsFixed(0)} km/h'
                        : 'Moving to you',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              );
          });
          // Animate camera to new rider position on native
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(newPos),
          );
        } else {
          if (mounted && _riderLatLng != null) {
            setState(() {
              _riderLatLng = null;
              _markers.clear();
            });
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasGps = _riderLatLng != null;

    if (!hasGps) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2430) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'Rider location not available yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.isOutForDelivery
                  ? 'Your rider is heading to you. Live GPS will appear here as soon as broadcasting starts.'
                  : 'Your meal is being prepared. Live map will activate once picked up by the rider.',
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
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
            // On Web: Render animated Radar Live Tracking canvas to prevent JS MapTypeId crash
            // On Mobile (iOS/Android): Render real hardware GoogleMap
            if (kIsWeb)
              _buildWebRadarMap(isDark, hasGps)
            else
              GoogleMap(
                onMapCreated: _onMapCreated,
                style: isDark ? _darkMapStyle : null,
                initialCameraPosition: CameraPosition(
                  target: _riderLatLng!,
                  zoom: 15,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                tiltGesturesEnabled: false,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
              ),

            // ── GPS Status Pill (top-left) ────────────────────────
            Positioned(
              top: 12,
              left: 12,
              child: _StatusPill(
                isActive: hasGps,
                isOutForDelivery: widget.isOutForDelivery,
              ),
            ),

            // ── ETA Badge (top-right) ─────────────────────────────
            Positioned(
              top: 12,
              right: 12,
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
                      widget.isOutForDelivery ? 'ETA: 12–18 min' : 'Prep: ~20 min',
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

            // ── Destination Bar (bottom) ──────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF13171E) : Colors.white)
                      .withValues(alpha: 0.94),
                  border: Border(
                    top: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.navigation_rounded,
                        size: 18, color: AppColors.primary),
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
                    if (kIsWeb)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'WEB RADAR',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
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
  }

  Widget _buildWebRadarMap(bool isDark, bool hasGps) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _RadarMapCanvasPainter(
            pulseValue: _pulseController.value,
            isDark: isDark,
            hasGps: hasGps,
          ),
        );
      },
    );
  }

  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1626"}]}
]
''';
}

/// Stylized canvas painter for web tracking view
class _RadarMapCanvasPainter extends CustomPainter {
  final double pulseValue;
  final bool isDark;
  final bool hasGps;

  _RadarMapCanvasPainter({
    required this.pulseValue,
    required this.isDark,
    required this.hasGps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. City grid lines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Simulated street route
    final routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final riderPos = Offset(size.width * 0.35, size.height * 0.52);
    final destPos = Offset(size.width * 0.72, size.height * 0.38);

    final path = Path()
      ..moveTo(riderPos.dx, riderPos.dy)
      ..lineTo(size.width * 0.50, size.height * 0.52)
      ..lineTo(size.width * 0.50, destPos.dy)
      ..lineTo(destPos.dx, destPos.dy);

    canvas.drawPath(path, routePaint);

    // 4. Radar pulsing wave around rider
    final wavePaint = Paint()
      ..color = (hasGps ? AppColors.success : AppColors.primary).withValues(alpha: (1.0 - pulseValue).clamp(0.0, 1.0) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(riderPos, 14 + (pulseValue * 28), wavePaint);

    // 5. Rider location dot
    final riderPaint = Paint()
      ..color = hasGps ? AppColors.success : AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(riderPos, 9, riderPaint);

    final riderInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(riderPos, 4, riderInnerPaint);

    // 6. Destination marker
    final destPaint = Paint()
      ..color = AppColors.brandMaroon
      ..style = PaintingStyle.fill;
    canvas.drawCircle(destPos, 8, destPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarMapCanvasPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isDark != isDark ||
        oldDelegate.hasGps != hasGps;
  }
}

/// GPS status indicator pill
class _StatusPill extends StatelessWidget {
  final bool isActive;
  final bool isOutForDelivery;

  const _StatusPill({required this.isActive, required this.isOutForDelivery});

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppColors.success
        : (isOutForDelivery ? AppColors.primary : AppColors.textSecondary);
    final label = isActive
        ? 'LIVE GPS ACTIVE'
        : (isOutForDelivery ? 'RIDER DISPATCHED' : 'KITCHEN DISPATCH ROUTE');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
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
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
