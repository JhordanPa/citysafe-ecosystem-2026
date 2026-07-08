import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../common/glass_container.dart';

class LocationPickerMap extends StatelessWidget {
  final LatLng mapCenter;
  final String addressText;
  final bool isGettingLocation;
  final void Function(MapLibreMapController) onMapCreated;
  final VoidCallback onCameraIdle;
  final void Function(CameraPosition)? onCameraMove;
  final VoidCallback onGetLocation;
  final ColorScheme colorScheme;

  const LocationPickerMap({
    super.key,
    required this.mapCenter,
    required this.addressText,
    required this.isGettingLocation,
    required this.onMapCreated,
    required this.onCameraIdle,
    this.onCameraMove,
    required this.onGetLocation,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              alignment: Alignment.center,
              children: [
                MapLibreMap(
                  onMapCreated: onMapCreated,
                  onCameraIdle: onCameraIdle,
                  onCameraMove: onCameraMove,
                  initialCameraPosition: CameraPosition(
                    target: mapCenter,
                    zoom: 14.0,
                  ),
                  styleString:
                      'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json',
                  myLocationEnabled: !kIsWeb,
                  trackCameraPosition: true,
                ),
                const Icon(Icons.location_on, size: 48, color: Colors.red),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'my_loc_btn',
                    backgroundColor: colorScheme.primaryContainer,
                    onPressed: onGetLocation,
                    child: isGettingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.my_location,
                            color: colorScheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 12),
        GlassContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.place_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    addressText,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}
