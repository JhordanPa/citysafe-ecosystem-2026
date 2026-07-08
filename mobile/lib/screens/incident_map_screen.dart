import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../services/api_service.dart';

class IncidentMapScreen extends StatefulWidget {
  final bool showAppBar;
  const IncidentMapScreen({super.key, this.showAppBar = true});

  @override
  State<IncidentMapScreen> createState() => _IncidentMapScreenState();
}

class _IncidentMapScreenState extends State<IncidentMapScreen> {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  MapLibreMapController? mapController;
  LatLng _center = const LatLng(-12.0464, -77.0428);
  Position? _userLocation;

  // Popup Flotante
  Map<String, dynamic>? _selectedIncident;
  math.Point<double>? _popupPosition;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    try {
      final incidents = await ApiService().fetchIncidents();

      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            final locationSettings = kIsWeb
                ? const LocationSettings(
                    accuracy: LocationAccuracy.high,
                    timeLimit: Duration(seconds: 15),
                  )
                : const LocationSettings(
                    accuracy: LocationAccuracy.high,
                    timeLimit: Duration(seconds: 10),
                  );
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: locationSettings,
            );
            _userLocation = pos;
            _center = LatLng(pos.latitude, pos.longitude);
          } else if (incidents.isNotEmpty) {
            _center = LatLng(incidents.last.latitud, incidents.last.longitud);
          }
        } else if (incidents.isNotEmpty) {
          _center = LatLng(incidents.last.latitud, incidents.last.longitud);
        }
      } catch (_) {
        if (incidents.isNotEmpty) {
          _center = LatLng(incidents.last.latitud, incidents.last.longitud);
        }
      }

      setState(() {
        _data = incidents.map<Map<String, dynamic>>((inc) {
          var intensity = 0.4;
          if (inc.nivelUrgencia == 2) intensity = 0.7;
          if (inc.nivelUrgencia == 3) intensity = 1.0;

          return {
            'lat': inc.latitud,
            'lon': inc.longitud,
            'intensity': intensity,
            'urgency': inc.nivelUrgencia,
            'category': inc.tipo,
            'desc': inc.descripcion ?? 'Sin descripción',
          };
        }).toList();
      });
    } catch (e) {
      // Ignorar
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    mapController = controller;
    
    controller.addListener(() {
      if (_selectedIncident != null) {
        _updatePopupPosition();
      }
    });

    controller.onFeatureTapped.add((
      math.Point<double> point,
      LatLng coordinates,
      String layerId,
      String featureId,
      dynamic annotation,
    ) async {
      final features = await controller.queryRenderedFeatures(point, [
        'point-layer',
      ], null);
      if (features.isNotEmpty) {
        final feature = features.first;
        if (feature is Map) {
          final props = feature['properties'] as Map?;
          if (props != null && mounted) {
            setState(() {
              _selectedIncident = {
                ...props,
                'latLng': coordinates,
              };
            });
            _updatePopupPosition();
          }
        }
      } else {
        // Tapped outside
        setState(() {
          _selectedIncident = null;
        });
      }
    });
  }

  Future<void> _updatePopupPosition() async {
    if (mapController == null || _selectedIncident == null || !mounted) return;
    try {
      final LatLng coords = _selectedIncident!['latLng'];
      final point = await mapController!.toScreenLocation(coords);
      if (mounted) {
        setState(() {
          _popupPosition = math.Point<double>(point.x.toDouble(), point.y.toDouble());
        });
      }
    } catch (e) {
      // Ignorar
    }
  }

  Color _getUrgencyColorFromProp(dynamic urgency) {
    if (urgency == 3 || urgency == '3') return Theme.of(context).colorScheme.error;
    if (urgency == 2 || urgency == '2') return Colors.orange;
    return Colors.green;
  }

  Future<void> _locateUser() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación denegados permanentemente.');
      }

      final locationSettings = kIsWeb
          ? const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 15),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            );
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      if (!mounted) return;
      setState(() {
        _userLocation = pos;
      });

      if (mapController != null) {
        final theme = Theme.of(context);
        final primaryHex =
            '#${theme.colorScheme.primary.toARGB32().toRadixString(16).substring(2)}';

        try {
          await mapController!.removeLayer("user-point-layer");
          await mapController!.removeSource("user-location");
        } catch (_) {}

        await mapController!.addGeoJsonSource("user-location", {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [pos.longitude, pos.latitude],
          },
        });
        await mapController!.addCircleLayer(
          "user-location",
          "user-point-layer",
          CircleLayerProperties(
            circleRadius: 8.0,
            circleColor: primaryHex,
            circleStrokeWidth: 3.0,
            circleStrokeColor: "#FFFFFF",
          ),
        );

        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(pos.latitude, pos.longitude),
            15.0,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error de ubicación: ${e.toString().replaceAll("Exception: ", "")}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _onStyleLoaded() async {
    final controller = mapController;
    if (controller == null || !mounted) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Convertir colores a HEX para el mapa
    final primaryHex = '#${colorScheme.primary.toARGB32().toRadixString(16).substring(2)}';
    final errorHex = '#${colorScheme.error.toARGB32().toRadixString(16).substring(2)}';
    final warningHex = '#FF9800'; // Naranja
    final successHex = '#4CAF50'; // Verde
    
    if (_userLocation != null) {
      await controller.addGeoJsonSource("user-location", {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [_userLocation!.longitude, _userLocation!.latitude],
        },
      });
      await controller.addCircleLayer(
        "user-location",
        "user-point-layer",
        CircleLayerProperties(
          circleRadius: 8.0,
          circleColor: primaryHex,
          circleStrokeWidth: 3.0,
          circleStrokeColor: "#FFFFFF",
        ),
      );
    }

    if (_data.isEmpty) return;

    final features = _data.map<Map<String, dynamic>>((d) {
      return <String, dynamic>{
        "type": "Feature",
        "geometry": <String, dynamic>{
          "type": "Point",
          "coordinates": <double>[d['lon'] as double, d['lat'] as double],
        },
        "properties": <String, dynamic>{
          "urgency": d['urgency'],
          "intensity": d['intensity'],
          "category": d['category'],
          "desc": d['desc'],
        },
      };
    }).toList();

    final geojson = <String, dynamic>{
      "type": "FeatureCollection",
      "features": features,
    };

    await controller.addGeoJsonSource("incidents", geojson);

    // Mapa de calor intenso y expansivo
    await controller.addHeatmapLayer(
      "incidents",
      "heatmap-layer",
      HeatmapLayerProperties(
        heatmapWeight: ["get", "intensity"],
        heatmapIntensity: [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          1.5,
          9,
          3,
          15,
          5,
        ],
        heatmapColor: [
          "interpolate",
          ["linear"],
          ["heatmap-density"],
          0,
          "rgba(0,0,0,0)",
          0.2,
          successHex,
          0.4,
          warningHex,
          0.8,
          errorHex,
          1,
          "#8B0000", // Dark Red for center
        ],
        heatmapRadius: [
          "interpolate",
          ["linear"],
          ["zoom"],
          0,
          15,
          9,
          30,
          15,
          60,
        ],
        heatmapOpacity: 0.8,
      ),
    );

    await controller.addCircleLayer(
      "incidents",
      "point-layer",
      CircleLayerProperties(
        circleRadius: [
          "interpolate",
          ["linear"],
          ["zoom"],
          10,
          4,
          15,
          10
        ],
        circleColor: [
          "match",
          ["get", "urgency"],
          1,
          successHex,
          2,
          warningHex,
          3,
          errorHex,
          primaryHex,
        ],
        circleStrokeWidth: 2.5,
        circleStrokeColor: "#FFFFFF",
      ),
    );
  }

  Widget _buildFloatingPopup() {
    if (_selectedIncident == null || _popupPosition == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final latLng = _selectedIncident!['latLng'] as LatLng;
    final color = _getUrgencyColorFromProp(_selectedIncident!['urgency']);

    // Posición del popup: A un lado (ej: arriba a la derecha del punto)
    final double left = _popupPosition!.x + 15;
    final double top = _popupPosition!.y - 60;

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedIncident!['category']}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Urgencia: ${_selectedIncident!['urgency']}',
                          style: theme.textTheme.bodySmall?.copyWith(color: color),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedIncident = null),
                    child: Icon(Icons.close_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${_selectedIncident!['desc']}',
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Divider(color: colorScheme.outlineVariant),
              Text(
                'Lat: ${latLng.latitude.toStringAsFixed(5)}\nLon: ${latLng.longitude.toStringAsFixed(5)}',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
        ).animate().scale(curve: Curves.easeOutBack, duration: 300.ms).fadeIn(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget mapWidget = Stack(
      children: [
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : MapLibreMap(
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: _onStyleLoaded,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 13.0,
                ),
                // Estilo vibrante y colorido
                styleString:
                    'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json',
                myLocationEnabled: false,
                trackCameraPosition: true,
              ),
        
        _buildFloatingPopup(),

        if (!_isLoading)
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'map_my_location',
              elevation: 6,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              onPressed: _locateUser,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Mi Ubicación'),
            ),
          ),
      ],
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Mapa de Incidentes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 0,
        ),
        body: mapWidget,
      );
    } else {
      return Scaffold(body: mapWidget);
    }
  }
}
