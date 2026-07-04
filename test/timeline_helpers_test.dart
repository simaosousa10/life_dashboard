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
}
