import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/data/models/today_timeline_item.dart';
import 'package:life_dashboard/features/dashboard/timeline_helpers.dart';

void main() {
  test('sortTimelineItems keeps timed items ordered before all-day items', () {
    final date = DateTime(2026, 7, 4);
    final items = [
      TodayTimelineItem(
        id: 'habit',
        title: 'Habit',
        category: 'Habit',
        start: date,
        type: TodayItemType.habit,
        hasTime: false,
      ),
      TodayTimelineItem(
        id: 'late',
        title: 'Late',
        category: 'Schedule',
        start: DateTime(2026, 7, 4, 16),
        type: TodayItemType.schedule,
        hasTime: true,
      ),
      TodayTimelineItem(
        id: 'early',
        title: 'Early',
        category: 'Schedule',
        start: DateTime(2026, 7, 4, 9),
        type: TodayItemType.schedule,
        hasTime: true,
      ),
    ];

    final sorted = sortTimelineItems(items);

    expect(sorted.map((item) => item.id), ['early', 'late', 'habit']);
  });

  test('timeProgress clamps progress between zero and one', () {
    final item = TodayTimelineItem(
      id: 'block',
      title: 'Block',
      category: 'Schedule',
      start: DateTime(2026, 7, 4, 10),
      end: DateTime(2026, 7, 4, 12),
      type: TodayItemType.schedule,
      hasTime: true,
    );

    expect(timeProgress(item, DateTime(2026, 7, 4, 9)), 0);
    expect(timeProgress(item, DateTime(2026, 7, 4, 11)), 0.5);
    expect(timeProgress(item, DateTime(2026, 7, 4, 13)), 1);
  });

  test('currentTimelineItem returns the running timed item', () {
    final items = [
      TodayTimelineItem(
        id: 'past',
        title: 'Past',
        category: 'Schedule',
        start: DateTime(2026, 7, 4, 8),
        end: DateTime(2026, 7, 4, 9),
        type: TodayItemType.schedule,
        hasTime: true,
      ),
      TodayTimelineItem(
        id: 'current',
        title: 'Current',
        category: 'Schedule',
        start: DateTime(2026, 7, 4, 10),
        end: DateTime(2026, 7, 4, 12),
        type: TodayItemType.schedule,
        hasTime: true,
      ),
      TodayTimelineItem(
        id: 'all-day',
        title: 'All day',
        category: 'Habit',
        start: DateTime(2026, 7, 4),
        type: TodayItemType.habit,
        hasTime: false,
      ),
    ];

    final current = currentTimelineItem(items, DateTime(2026, 7, 4, 11));

    expect(current?.id, 'current');
  });

  test('upcomingTimelineItems excludes current and elapsed timed items', () {
    final now = DateTime(2026, 7, 4, 11);
    final items = [
      TodayTimelineItem(
        id: 'past',
        title: 'Past',
        category: 'Schedule',
        start: DateTime(2026, 7, 4, 8),
        end: DateTime(2026, 7, 4, 9),
        type: TodayItemType.schedule,
        hasTime: true,
      ),
      TodayTimelineItem(
        id: 'current',
        title: 'Current',
        category: 'Schedule',
        start: DateTime(2026, 7, 4, 10),
        end: DateTime(2026, 7, 4, 12),
        type: TodayItemType.schedule,
        hasTime: true,
      ),
      TodayTimelineItem(
        id: 'future',
        title: 'Future',
        category: 'Event',
        start: DateTime(2026, 7, 4, 13),
        type: TodayItemType.calendarEvent,
        hasTime: true,
      ),
      TodayTimelineItem(
        id: 'todo',
        title: 'Todo',
        category: 'Task',
        start: DateTime(2026, 7, 4),
        type: TodayItemType.todo,
        hasTime: false,
      ),
    ];

    final upcoming = upcomingTimelineItems(items, now);

    expect(upcoming.map((item) => item.id), ['future', 'todo']);
  });
}
