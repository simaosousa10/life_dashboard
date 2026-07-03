import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_async_value.dart';
import '../../data/models/today_timeline_item.dart';
import '../../providers/app_providers.dart';
import 'timeline_helpers.dart';
import 'widgets/current_activity_card.dart';
import 'widgets/empty_state_card.dart';
import 'widgets/home_header.dart';
import 'widgets/upcoming_activity_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({required this.onSelectTab, super.key});

  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(homeTimelineProvider);
    final now = ref.watch(timelineClockProvider).valueOrNull ?? DateTime.now();

    return ColoredBox(
      color: const Color(0xFF10151F),
      child: SafeArea(
        child: AppAsyncValue(
          value: timeline,
          onRetry: () => ref.invalidate(homeTimelineProvider),
          builder: (data) {
            final currentItem = currentTimelineItem(data.items, now);
            final upcomingItems = upcomingTimelineItems(data.items, now);

            return RefreshIndicator(
              color: const Color(0xFFFFA726),
              backgroundColor: const Color(0xFF1F2937),
              onRefresh: () async => ref.invalidate(homeTimelineProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                children: [
                  HomeHeader(
                    displayName: data.displayName,
                    date: data.date,
                    onProfileTap: () => onSelectTab(1),
                  ),
                  const SizedBox(height: 28),
                  const _SectionTitle('Agora'),
                  const SizedBox(height: 12),
                  if (currentItem == null)
                    const EmptyStateCard(
                      icon: Icons.self_improvement_outlined,
                      message: 'Sem atividade neste momento',
                    )
                  else
                    CurrentActivityCard(item: currentItem, now: now),
                  const SizedBox(height: 28),
                  const _SectionTitle('A seguir'),
                  const SizedBox(height: 12),
                  if (upcomingItems.isEmpty)
                    const EmptyStateCard(
                      icon: Icons.event_available_outlined,
                      message: 'Nada mais planeado para hoje',
                    )
                  else
                    ...upcomingItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: UpcomingActivityCard(item: item),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Resumo'),
                  const SizedBox(height: 12),
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

  final TodayTimelineData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        return GridView.count(
          crossAxisCount: wide ? 4 : 2,
          childAspectRatio: wide ? 2.2 : 1.65,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _SummaryTile(
              label: 'Tarefas',
              value: '${data.completedTasks}/${data.totalTasks}',
              icon: Icons.task_alt,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: const Color(0xFFFFD166), size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
