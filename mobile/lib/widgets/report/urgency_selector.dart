import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../common/glass_container.dart';

class UrgencySelector extends StatelessWidget {
  final int urgency;
  final ValueChanged<int> onUrgencySelected;

  const UrgencySelector({
    super.key,
    required this.urgency,
    required this.onUrgencySelected,
  });

  Widget _buildUrgencyButton(
    BuildContext context,
    int value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = urgency == value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: () => onUrgencySelected(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            _buildUrgencyButton(context, 1, 'Baja', Icons.low_priority, Colors.green),
            const SizedBox(width: 8),
            _buildUrgencyButton(context, 2, 'Media', Icons.priority_high, Colors.orange),
            const SizedBox(width: 8),
            _buildUrgencyButton(context, 3, 'Alta', Icons.warning, Colors.red),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }
}
