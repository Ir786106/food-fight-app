import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/logger.dart';

/// Interactive Map Pin Picker Dialog for setting branch coordinates
class LocationPickerMapDialog extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const LocationPickerMapDialog({
    super.key,
    this.initialLat = 31.4697, // Default Lahore/Islamabad
    this.initialLng = 74.4101,
  });

  static Future<LatLng?> show(
    BuildContext context, {
    double? initialLat,
    double? initialLng,
    double? initialLatitude,
    double? initialLongitude,
  }) {
    final lat = initialLatitude ?? initialLat ?? 31.4697;
    final lng = initialLongitude ?? initialLng ?? 74.4101;
    return showDialog<LatLng>(
      context: context,
      builder: (ctx) => LocationPickerMapDialog(
        initialLat: lat,
        initialLng: lng,
      ),
    );
  }

  @override
  State<LocationPickerMapDialog> createState() => _LocationPickerMapDialogState();
}

class _LocationPickerMapDialogState extends State<LocationPickerMapDialog> {
  late LatLng _currentCenter;
  GoogleMapController? _mapController;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _currentCenter = LatLng(widget.initialLat, widget.initialLng);
  }

  Future<void> _moveToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        final newCenter = LatLng(pos.latitude, pos.longitude);
        setState(() => _currentCenter = newCenter);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newCenter, 15));
      }
    } catch (e) {
      AppLogger.warn('Could not locate user: $e', tag: 'MapPicker');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 520,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentCenter,
                  zoom: 14.5,
                ),
                onMapCreated: (ctrl) => _mapController = ctrl,
                onCameraMove: (pos) => _currentCenter = pos.target,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),

              // Fixed Center Pin
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 36),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 46,
                    color: AppColors.brandMaroon,
                  ),
                ),
              ),

              // Top Header Bar
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app_rounded, color: AppColors.brandMaroon, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Drag map to position pin on branch location',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),

              // My Location FAB
              Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton.small(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: AppColors.brandMaroon,
                  onPressed: _locating ? null : _moveToCurrentLocation,
                  child: _locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandMaroon),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
              ),

              // Bottom Confirmation Button
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandYellow,
                    foregroundColor: AppColors.brandMaroon,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    'Confirm Location (${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)})',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  onPressed: () => Navigator.pop(context, _currentCenter),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
