import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_async_value.dart';
import '../../data/models/day_plan.dart';
import '../../data/models/today_timeline_item.dart';
import '../../providers/app_providers.dart';
import '../dashboard/timeline_helpers.dart';
import '../schedule/schedule_screen.dart';
import '../todos/todos_screen.dart';
import 'calendar_screen.dart';

enum _CalendarSection { month, today, tasks, schedule }

class CalendarHubScreen extends ConsumerStatefulWidget {
  const CalendarHubScreen({super.key});

  @override
  ConsumerState<CalendarHubScreen> createState() => _CalendarHubScreenState();
}

class _CalendarHubScreenState extends ConsumerState<CalendarHubScreen> {
  _CalendarSection _section = _CalendarSection.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<_CalendarSection>(
                segments: const [
                  ButtonSegment(
                    value: _CalendarSection.month,
                    icon: Icon(Icons.calendar_month_outlined),
                    label: Text('Mes'),
                  ),
                  ButtonSegment(
                    value: _CalendarSection.today,
                    icon: Icon(Icons.today_outlined),
                    label: Text('Hoje'),
                  ),
                  ButtonSegment(
                    value: _CalendarSection.tasks,
                    icon: Icon(Icons.checklist_outlined),
                    label: Text('Tarefas'),
                  ),
                  ButtonSegment(
                    value: _CalendarSection.schedule,
                    icon: Icon(Icons.view_week_outlined),
                    label: Text('Horario'),
                  ),
                ],
                selected: {_section},
                onSelectionChanged: (value) {
                  setState(() => _section = value.first);
                },
              ),
            ),
          ),
          Expanded(
            child: switch (_section) {
              _CalendarSection.month => const CalendarScreen(),
              _CalendarSection.today => const _TodayCalendarPanel(),
              _CalendarSection.tasks => const TodosScreen(),
              _CalendarSection.schedule => const ScheduleScreen(),
            },
          ),
        ],
      ),
    );
  }
}

class _TodayCalendarPanel extends ConsumerWidget {
  const _TodayCalendarPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateKey = formatDateKey(todayDate());
    final plan = ref.watch(dayPlanProvider(dateKey));

    return AppAsyncValue(
      value: plan,
      onRetry: () => ref.invalidate(dayPlanProvider(dateKey)),
      builder: (data) {
        return RefreshIndicator(
          onRefresh: () async => invalidateDashboardData(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Hoje',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(formatDate(data.date)),
              const SizedBox(height: 14),
              _TodayMetricRow(data: data),
              const SizedBox(height: 14),
              _AgendaSection(
                title: 'Agenda',
                icon: Icons.route_outlined,
                children: data.timelineItems
                    .map(
                      (item) => ListTile(
                        leading: Icon(_iconForType(item.type)),
                        title: Text(item.title),
                        subtitle: Text(
                          '${timelineTimeLabel(item)} - ${item.category}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodayMetricRow extends StatelessWidget {
  const _TodayMetricRow({required this.data});

  final DayPlanData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 700 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          childAspectRatio: columns == 2 ? 2.2 : 2.5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _MiniMetric(
              icon: Icons.task_alt,
              label: 'Tarefas',
              value: '${data.completedTasks}/${data.totalTasks}',
            ),
            _MiniMetric(
              icon: Icons.fact_check_outlined,
              label: 'Habitos',
              value: '${data.completedHabits}/${data.totalHabits}',
            ),
            _MiniMetric(
              icon: Icons.water_drop_outlined,
              label: 'Agua',
              value: '${data.waterMl} ml',
            ),
            _MiniMetric(
              icon: Icons.local_fire_department_outlined,
              label: 'Kcal',
              value: '${data.caloriesIn - data.caloriesOut}',
            ),
          ],
        );
      },
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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

class _AgendaSection extends StatelessWidget {
  const _AgendaSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (children.isEmpty)
              const ListTile(title: Text('Nada planeado para hoje.'))
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

IconData _iconForType(TodayItemType type) {
  return switch (type) {
    TodayItemType.schedule => Icons.calendar_view_week_outlined,
    TodayItemType.calendarEvent => Icons.event_outlined,
    TodayItemType.todo => Icons.check_circle_outline,
    TodayItemType.recurringTask => Icons.repeat,
    TodayItemType.habit => Icons.fact_check_outlined,
  };
}
