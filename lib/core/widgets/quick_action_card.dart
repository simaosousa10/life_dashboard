import 'package:flutter/material.dart';

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
    this.tint,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = tint ?? colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
