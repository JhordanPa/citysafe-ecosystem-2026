import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/api_service.dart';
import '../widgets/home/incident_list_area.dart';
import '../widgets/home/stat_card.dart';
import 'incident_map_screen.dart';

class GestorHomeScreen extends StatefulWidget {
  const GestorHomeScreen({super.key});

  @override
  State<GestorHomeScreen> createState() => _GestorHomeScreenState();
}

class _GestorHomeScreenState extends State<GestorHomeScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allIncidents = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final incidents = await ApiService().fetchIncidents();
      incidents.sort((a, b) {
        final urgencyCompare = b.nivelUrgencia.compareTo(a.nivelUrgencia);
        if (urgencyCompare != 0) return urgencyCompare;
        return b.fechaReporte.compareTo(a.fechaReporte);
      });

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

            var timeStr = '00:00';
            if (i.fechaReporte.contains('T')) {
              timeStr = i.fechaReporte.split('T').last.substring(0, 5);
            }

            return {
              'id': i.id,
              'category': i.tipo,
              'title': i.tipo,
              'description': i.descripcion ?? 'Sin descripción detallada.',
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
      _refreshData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Widget _buildLeftPanel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = _allIncidents.length;
    final criticos = _allIncidents.where((i) => i['severity'] == 3).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              StatCard(
                title: 'TOTAL',
                value: total.toString(),
                icon: Icons.analytics_rounded,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 16),
              StatCard(
                title: 'CRÍTICOS',
                value: criticos.toString(),
                icon: Icons.warning_rounded,
                color: colorScheme.error,
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.list_alt_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Incidentes Activos',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : IncidentListArea(
                          incidents: _allIncidents,
                          selectedCategory: null,
                          onRefresh: _refreshData,
                          onReportEmergency: () {},
                          onDeleteIncident: _deleteIncident,
                          showFloatingButtons: false,
                        ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ),
      ],
    );
  }

  Widget _buildMapPanel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: const IncidentMapScreen(showAppBar: false),
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determinamos si la pantalla es ancha (Landscape/Web/Tablet) o estrecha (Portrait Mobile)
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Centro de Comando',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Monitoreo en vivo de incidentes',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshData,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ApiService().logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/');
            },
            tooltip: 'Cerrar sesión',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: isWideScreen
            ? Row(
                children: [
                  SizedBox(width: 400, child: _buildLeftPanel(context)),
                  Expanded(child: _buildMapPanel(context)),
                ],
              )
            : Column(
                children: [
                  Expanded(flex: 4, child: _buildMapPanel(context)),
                  Expanded(flex: 5, child: _buildLeftPanel(context)),
                ],
              ),
      ),
    );
  }
}
