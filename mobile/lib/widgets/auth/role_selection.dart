import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../common/glass_container.dart';

class RoleSelection extends StatelessWidget {
  final ThemeData theme;
  final ValueChanged<String> onRoleSelected;

  const RoleSelection({
    super.key,
    required this.theme,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '¿Cómo deseas ingresar?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onRoleSelected('ciudadano'),
                child: GlassContainer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ciudadano',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.2),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => onRoleSelected('gestor'),
                child: GlassContainer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 48,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gestor',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.2),
            ),
          ],
        ),
      ],
    );
  }
}
