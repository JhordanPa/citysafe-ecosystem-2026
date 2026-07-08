import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../services/api_service.dart';
import '../widgets/common/custom_popups.dart';
import '../widgets/report/category_selector.dart';
import '../widgets/report/location_picker_map.dart';
import '../widgets/report/urgency_selector.dart';

class ReportEmergencyScreen extends StatefulWidget {
  const ReportEmergencyScreen({super.key});

  @override
  State<ReportEmergencyScreen> createState() => _ReportEmergencyScreenState();
}

class _ReportEmergencyScreenState extends State<ReportEmergencyScreen> {
  String? _selectedCategory;
  int _urgency = 1;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  String _addressText = 'Toca para buscar tu ubicación';
  bool _isGettingLocation = false;

  MapLibreMapController? mapController;
  LatLng _mapCenter = const LatLng(-12.0464, -77.0428); // Lima por defecto

  final List<Map<String, dynamic>> _categories = [
    {"name": "Seguridad", "icon": Icons.shield_rounded, "color": Colors.blue},
    {
      "name": "Médicas",
      "icon": Icons.medical_services_rounded,
      "color": Colors.red,
    },
    {
      "name": "Servicios Públicos",
      "icon": Icons.construction_rounded,
      "color": Colors.orange,
    },
    {
      "name": "Protección Civil",
      "icon": Icons.warning_rounded,
      "color": Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getLocation();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() {
      _isGettingLocation = true;
      _addressText = 'Obteniendo coordenadas...';
    });
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
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      setState(() {
        _mapCenter = LatLng(position.latitude, position.longitude);
        _addressText = 'Buscando dirección...';
      });

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_mapCenter, 16.0),
        );
      }

      await _updateAddressFromLatLng(_mapCenter);
    } catch (e) {
      if (mounted) {
        setState(
          () => _addressText = 'Error de ubicación: intenta mover el mapa',
        );
        CustomPopups.showError(
          context: context,
          title: 'Error de ubicación',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _updateAddressFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (mounted) {
          setState(() {
            _addressText =
                '${place.street ?? ""}, ${place.subLocality ?? place.locality ?? place.administrativeArea ?? ""} (${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)})';
          });
        }
      } else {
        if (mounted) {
          setState(
            () => _addressText =
                'Dirección desconocida (${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)})',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _addressText =
              'Coordenadas: ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}',
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (_selectedCategory == null) {
      CustomPopups.showError(
        context: context,
        title: 'Falta categoría',
        message: 'Por favor, selecciona el tipo de emergencia.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService().createIncident(
        _selectedCategory!,
        _mapCenter.latitude,
        _mapCenter.longitude,
        _urgency,
        _descriptionController.text.trim(),
      );

      if (!mounted) return;

      CustomPopups.showSuccess(
        context: context,
        title: '¡Reporte enviado!',
        message:
            'La emergencia ha sido reportada. Las autoridades han sido notificadas.',
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      CustomPopups.showError(
        context: context,
        title: 'Error al reportar',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    _mapCenter = position.target;
  }

  void _onCameraIdle() {
    if (mapController != null) {
      if (mapController!.cameraPosition != null) {
        _mapCenter = mapController!.cameraPosition!.target;
      }
      setState(() {
        _addressText = 'Cargando dirección...';
      });
      _updateAddressFromLatLng(_mapCenter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    // Forzamos el esquema de color a un rojo expressive sin perder el modo oscuro/claro
    final theme = baseTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.red,
        brightness: baseTheme.brightness,
      ),
    );

    final colorScheme = theme.colorScheme;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text(
            'Reportar Emergencia',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. Tipo de emergencia',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                CategorySelector(
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (cat) =>
                      setState(() => _selectedCategory = cat),
                  colorScheme: colorScheme,
                ),
                Text(
                  '2. Nivel de urgencia',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                UrgencySelector(
                  urgency: _urgency,
                  onUrgencySelected: (u) => setState(() => _urgency = u),
                ),
                const SizedBox(height: 32),

                Text(
                  '3. Descripción (opcional)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Detalla lo ocurrido para ayudar a los gestores...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                const SizedBox(height: 32),

                Text(
                  '4. Ubicación exacta (mueve el mapa si es incorrecta)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                LocationPickerMap(
                  mapCenter: _mapCenter,
                  addressText: _addressText,
                  isGettingLocation: _isGettingLocation,
                  onMapCreated: _onMapCreated,
                  onCameraIdle: _onCameraIdle,
                  onCameraMove: _onCameraMove,
                  onGetLocation: _getLocation,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 40),
                SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _submitReport,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isLoading ? 'ENVIANDO...' : 'ENVIAR REPORTE',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 600.ms)
                    .scale(curve: Curves.easeOutBack),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
