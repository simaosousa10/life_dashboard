import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_async_value.dart';
import '../../core/widgets/app_snackbars.dart';
import '../../data/models/day_plan.dart';
import '../../data/models/todo_item.dart';
import '../../providers/app_providers.dart';
import '../dashboard/timeline_helpers.dart';
import '../dashboard/widgets/current_activity_card.dart';
import '../dashboard/widgets/empty_state_card.dart';
import '../dashboard/widgets/home_header.dart';
import '../dashboard/widgets/upcoming_activity_card.dart';
import '../habits/widgets/today_habits_check_in.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.onSelectTab});

  final ValueChanged<int>? onSelectTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateKey = formatDateKey(todayDate());
    final plan = ref.watch(dayPlanProvider(dateKey));
    final now = ref.watch(timelineClockProvider).valueOrNull ?? DateTime.now();

    return ColoredBox(
      color: const Color(0xFF10151F),
      child: SafeArea(
        child: AppAsyncValue(
          value: plan,
          onRetry: () => ref.invalidate(dayPlanProvider(dateKey)),
          builder: (data) {
            final currentItem = currentTimelineItem(data.timelineItems, now);
            final upcomingItems = upcomingTimelineItems(
              data.timelineItems,
              now,
            );

            return RefreshIndicator(
              color: const Color(0xFFFFA726),
              backgroundColor: const Color(0xFF1F2937),
              onRefresh: () async => invalidateDashboardData(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                children: [
                  HomeHeader(
                    displayName: data.displayName,
                    date: data.date,
                    onProfileTap: () => onSelectTab?.call(4),
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Agora'),
                  const SizedBox(height: 8),
                  if (currentItem == null)
                    const EmptyStateCard(
                      icon: Icons.self_improvement_outlined,
                      message: 'Sem atividade neste momento',
                    )
                  else
                    CurrentActivityCard(item: currentItem, now: now),
                  const SizedBox(height: 20),
                  const _SectionTitle('A seguir'),
                  const SizedBox(height: 8),
                  if (upcomingItems.isEmpty)
                    const EmptyStateCard(
                      icon: Icons.event_available_outlined,
                      message: 'Nada mais planeado para hoje',
                    )
                  else
                    ...upcomingItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: UpcomingActivityCard(item: item),
                      ),
                    ),
                  const SizedBox(height: 14),
                  const _SectionTitle('Tarefas de hoje'),
                  const SizedBox(height: 8),
                  _TodayTasksCard(tasks: data.todos),
                  const SizedBox(height: 14),
                  const _SectionTitle('Fecho do dia'),
                  const SizedBox(height: 8),
                  const TodayHabitsCheckIn(),
                  const SizedBox(height: 14),
                  const _SectionTitle('Resumo'),
                  const SizedBox(height: 8),
                  _DailySummary(data: data),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.data});

  final DayPlanData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        return GridView.count(
          crossAxisCount: wide ? 4 : 2,
          childAspectRatio: wide ? 2.9 : 2.25,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _SummaryTile(
              label: 'Tarefas',
              value: '${data.completedTasks}/${data.totalTasks}',
              icon: Icons.task_alt,
            ),
            _SummaryTile(
              label: 'Habitos',
              value: '${data.completedHabits}/${data.totalHabits}',
              icon: Icons.fact_check_outlined,
            ),
            _SummaryTile(
              label: 'Água',
              value: '${data.waterMl}/${data.waterGoalMl} ml',
              icon: Icons.water_drop_outlined,
            ),
            _SummaryTile(
              label: 'Ingeridas',
              value: '${data.caloriesIn} kcal',
              icon: Icons.restaurant_outlined,
            ),
            _SummaryTile(
              label: 'Gastas',
              value: '${data.caloriesOut} kcal',
              icon: Icons.local_fire_department_outlined,
            ),
          ],
        );
      },
    );
  }
}

class _TodayTasksCard extends ConsumerWidget {
  const _TodayTasksCard({required this.tasks});

  final List<TodoItem> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.task_alt,
        message: 'Sem tarefas para hoje',
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: tasks.take(5).map((task) {
          return CheckboxListTile(
            value: task.isCompleted,
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFFFFA726),
            checkColor: Colors.black,
            onChanged: (value) async {
              try {
                await ref
                    .read(todosRepositoryProvider)
                    .setCompleted(task.id, value ?? false);
                invalidateDashboardData(ref);
              } catch (error) {
                if (context.mounted) {
                  showErrorSnackBar(context, error);
                }
              }
            },
            title: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text(
              [
                if (task.dueTime != null) compactTime(task.dueTime!),
                task.priority,
                if (task.recurringTaskId != null) 'recorrente',
              ].join(' - '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFFD166), size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 11,
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
