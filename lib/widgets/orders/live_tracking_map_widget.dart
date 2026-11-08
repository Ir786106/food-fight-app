import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/rider_location_service.dart';
import '../../theme/app_theme.dart';

/// Shows live rider GPS on native Google Maps and coordinates in a web fallback.
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

class _LiveTrackingMapWidgetState extends State<LiveTrackingMapWidget> {
  GoogleMapController? _mapController;

  LatLng? _riderLatLng;
  final Set<Marker> _markers = {};

  StreamSubscription<RiderLocationData?>? _locationSub;

  @override
  void initState() {
    super.initState();
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
            // Web uses a coordinate card because the map plugin is not reliable there.
            // On Mobile (iOS/Android): Render real hardware GoogleMap
            if (kIsWeb)
              _buildWebLocationCard(isDark)
            else
              GoogleMap(
                onMapCreated: _onMapCreated,
                style: isDark ? _darkMapStyle : null,
                initialCameraPosition: CameraPosition(
                  target: _riderLatLng!,
                  zoom: 15,
                ),
                markers: _markers,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLocationCard(bool isDark) {
    final position = _riderLatLng!;
    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 44,
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          Text(
            'Live rider coordinates',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Road map view is unavailable on web.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
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
        : (isOutForDelivery ? 'RIDER DISPATCHED' : 'LOCATION AVAILABLE');

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
