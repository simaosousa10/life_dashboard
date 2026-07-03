import 'package:flutter/material.dart';

class DayAgendaItemCard extends StatelessWidget {
  const DayAgendaItemCard({
    required this.title,
    required this.category,
    required this.icon,
    super.key,
    this.description,
    this.time,
    this.status,
    this.trailing,
  });

  final String title;
  final String category;
  final IconData icon;
  final String? description;
  final String? time;
  final String? status;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Icon(icon, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _secondaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }

  String get _secondaryText {
    final parts = <String>[
      if (time != null && time!.trim().isNotEmpty) time!,
      category,
      if (description != null && description!.trim().isNotEmpty) description!,
      if (status != null && status!.trim().isNotEmpty) status!,
    ];
    return parts.join(' - ');
  }
}
