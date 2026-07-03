import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_error.dart';
import '../../../data/models/habit.dart';
import '../../../providers/app_providers.dart';

class WeeklyHabitsDashboard extends ConsumerWidget {
  const WeeklyHabitsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(weeklyHabitSummaryProvider);

    return summary.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: LinearProgressIndicator(),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.error_outline),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  friendlyErrorMessage(error),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        if (data.stats.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.auto_graph_outlined),
                  SizedBox(width: 10),
                  Expanded(child: Text('Sem habitos planeados esta semana.')),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habitos da semana',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 700 ? 3 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  childAspectRatio: columns == 2 ? 1.95 : 2.35,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _MiniStatCard(
                      icon: Icons.percent,
                      value:
                          '${(data.completionRate * 100).round().clamp(0, 100)}%',
                      label: 'Cumprimento',
                    ),
                    _MiniStatCard(
                      icon: Icons.task_alt,
                      value: '${data.completedDays}/${data.plannedDays}',
                      label: 'Dias feitos',
                    ),
                    _MiniStatCard(
                      icon: Icons.trending_up,
                      value: _habitNames(data.bestHabits),
                      label: 'Mais fortes',
                    ),
                    _MiniStatCard(
                      icon: Icons.trending_down,
                      value: _habitNames(data.weakestHabits),
                      label: 'A rever',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            ...data.stats.map((stat) => _HabitProgressTile(stat: stat)),
          ],
        );
      },
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitProgressTile extends StatelessWidget {
  const _HabitProgressTile({required this.stat});

  final WeeklyHabitStat stat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stat.habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${stat.completedDays}/${stat.plannedDays}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: stat.completionRate,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 5),
            Text(
              '${(stat.completionRate * 100).round().clamp(0, 100)}% - streak ${stat.currentStreak}d',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

String _habitNames(List<WeeklyHabitStat> stats) {
  if (stats.isEmpty) {
    return '-';
  }
  return stats.map((stat) => stat.habit.title).join(', ');
}
