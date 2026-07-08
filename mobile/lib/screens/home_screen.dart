import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/home/category_navigation_bar.dart';
import '../widgets/home/home_app_bar.dart';
import '../widgets/home/incident_list_area.dart';
import 'incident_map_screen.dart';
import 'report_emergency.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;
  bool _isLoading = true;

  List<Map<String, dynamic>> _allIncidents = [];

  // CATEGORIAS PARA LA BARRA DE NAVEGACION
  final List<Map<String, dynamic>> _categories = [
    {"name": "Seguridad", "icon": Icons.shield_rounded},
    {"name": "Médicas", "icon": Icons.medical_services_rounded},
    {"name": "Servicios Públicos", "icon": Icons.construction_rounded},
    {"name": "Protección Civil", "icon": Icons.warning_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final incidents = await ApiService().fetchIncidents();
      if (mounted) {
        setState(() {
          _allIncidents = incidents.map((i) {
            Color severityColor;
            switch (i.nivelUrgencia) {
              case 1:
                severityColor = Colors.green;
                break;
              case 2:
                severityColor = Colors.orange;
                break;
              case 3:
                severityColor = Colors.red;
                break;
              default:
                severityColor = Colors.blue;
            }

            IconData categoryIcon = Icons.report_problem_rounded;
            final typeLower = i.tipo.toLowerCase();
            if (typeLower.contains('seguridad')) {
              categoryIcon = Icons.shield_rounded;
            } else if (typeLower.contains('médic')) {
              categoryIcon = Icons.medical_services_rounded;
            } else if (typeLower.contains('públic')) {
              categoryIcon = Icons.construction_rounded;
            } else if (typeLower.contains('civil')) {
              categoryIcon = Icons.warning_rounded;
            }

            String timeStr = "00:00";
            if (i.fechaReporte.contains('T')) {
              timeStr = i.fechaReporte.split('T').last.substring(0, 5);
            }

            return {
              'id': i.id,
              'category': i.tipo, // backend usa tipo
              'title': i.tipo,
              'description': i.descripcion ?? 'Sin descripción',
              'severity': i.nivelUrgencia,
              'user': i.usuario?.username ?? 'Anónimo',
              'date': i.fechaReporte,
              'color': severityColor,
              'icon': categoryIcon,
              'time': timeStr,
            };
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteIncident(int id) async {
    try {
      await ApiService().deleteIncident(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Incidente eliminado')));
      }
      _refreshData(); // Recargar la lista
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
        _refreshData(); // Recargar en caso de que visualmente se haya borrado pero fallara
      }
    }
  }

  void _openReportEmergency() async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.3),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ReportEmergencyScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    if (result == true) {
      _refreshData(); // Recargar si se reportó uno nuevo
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredIncidents = _selectedCategory == null
        ? _allIncidents
        : _allIncidents
              .where((i) => i['category'] == _selectedCategory)
              .toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.primaryContainer,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. CONTORNO SUPERIOR (Título y Usuario)
            const HomeAppBar(),

            // 2. ÁREA CENTRAL (Tarjeta con Reportes y Animaciones)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : IncidentListArea(
                      incidents: filteredIncidents,
                      selectedCategory: _selectedCategory,
                      onRefresh: _refreshData,
                      onReportEmergency: _openReportEmergency,
                      onOpenMap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const IncidentMapScreen(),
                          ),
                        );
                      },
                      onDeleteIncident: _deleteIncident,
                    ),
            ),

            // 3. CONTORNO INFERIOR (Barra de Categorías)
            CategoryNavigationBar(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
