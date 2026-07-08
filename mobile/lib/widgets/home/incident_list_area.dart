import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m3e_core/m3e_core.dart';

import 'incident_card.dart';

class IncidentListArea extends StatelessWidget {
  final List<Map<String, dynamic>> incidents;
  final String? selectedCategory;
  final Future<void> Function() onRefresh;
  final VoidCallback onReportEmergency;
  final VoidCallback? onOpenMap;
  final Function(int)? onDeleteIncident;
  final bool showFloatingButtons;

  const IncidentListArea({
    super.key,
    required this.incidents,
    required this.selectedCategory,
    required this.onRefresh,
    required this.onReportEmergency,
    this.onOpenMap,
    this.onDeleteIncident,
    this.showFloatingButtons = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Fondo Animado
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.2,
            child:
                M3EShape(
                      Shapes.circle,
                      width: size.width * 0.9,
                      height: size.width * 0.9,
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .moveY(
                      begin: -15,
                      end: 15,
                      duration: 4.seconds,
                      curve: Curves.easeInOutSine,
                    )
                    .animate()
                    .scale(duration: 800.ms, curve: Curves.easeOutBack),
          ),
          Positioned(
            bottom: -size.width * 0.4,
            left: -size.width * 0.3,
            child:
                M3EShape(
                      Shapes.slanted,
                      width: size.width,
                      height: size.width,
                      color: theme.colorScheme.tertiaryContainer.withValues(
                        alpha: 0.4,
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .moveX(
                      begin: -20,
                      end: 20,
                      duration: 5.seconds,
                      curve: Curves.easeInOutSine,
                    )
                    .animate()
                    .slide(duration: 800.ms, curve: Curves.easeOutCubic)
                    .fadeIn(),
          ),
          Positioned(
            top: size.height * 0.2,
            left: -size.width * 0.15,
            child:
                M3EShape(
                      Shapes.circle,
                      width: size.width * 0.4,
                      height: size.width * 0.4,
                      color: theme.colorScheme.secondaryContainer.withValues(
                        alpha: 0.3,
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .move(
                      begin: const Offset(15, -15),
                      end: const Offset(-15, 15),
                      duration: 6.seconds,
                      curve: Curves.easeInOutSine,
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 800.ms),
          ),

          // Lista de Reportes
          RefreshIndicator(
            onRefresh: onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (incidents.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 100,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.4,
                            ),
                          ).animate().scale(
                            delay: 400.ms,
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Todo tranquilo',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48.0,
                            ),
                            child: Text(
                              selectedCategory == null
                                  ? 'No hay incidentes reportados actualmente en tu ciudad.'
                                  : 'No hay incidentes reportados en $selectedCategory.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      bottom: 100.0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final incident = incidents[index];
                        return IncidentCard(
                          incident: incident,
                          index: index,
                          onDelete: onDeleteIncident != null
                              ? () => onDeleteIncident!(incident['id'])
                              : null,
                        );
                      }, childCount: incidents.length),
                    ),
                  ),
              ],
            ),
          ),

          // FAB posicionado dentro de la tarjeta
          if (showFloatingButtons)
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (onOpenMap != null) ...[
                    FloatingActionButton.small(
                      heroTag: 'map_btn',
                      backgroundColor: theme.colorScheme.tertiaryContainer,
                      foregroundColor: theme.colorScheme.onTertiaryContainer,
                      tooltip: 'Mapa de Incidentes',
                      onPressed: onOpenMap,
                      child: const Icon(Icons.map_rounded),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FloatingActionButton.extended(
                    onPressed: onReportEmergency,
                    backgroundColor: theme.colorScheme.errorContainer
                        .withValues(alpha: 0.8),
                    foregroundColor: theme.colorScheme.onErrorContainer,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    icon: const Icon(Icons.add_alert_rounded, size: 28),
                    label: const Text(
                      "Reportar",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
