import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
    this.subtitle,
    this.progress,
    this.progressLabel,
    this.tint,
  });

  final String title;
  final String value;
  final String? subtitle;
  final double? progress;
  final String? progressLabel;
  final IconData icon;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = tint ?? colorScheme.primary;
    final progressValue = progress?.clamp(0.0, 1.0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  foregroundColor: color,
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (progressValue != null) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: progressValue,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
              if (progressLabel != null) ...[
                const SizedBox(height: 8),
                Text(
                  progressLabel!,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
