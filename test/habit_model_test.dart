import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/data/models/habit.dart';

void main() {
  test('Habit.appliesTo respects weekday, active state and date range', () {
    final habit = _habit(weekdays: const [1, 3]);

    expect(habit.appliesTo(DateTime(2026, 7, 6)), isTrue);
    expect(habit.appliesTo(DateTime(2026, 7, 7)), isFalse);
    expect(habit.appliesTo(DateTime(2026, 6, 30)), isFalse);
    expect(habit.appliesTo(DateTime(2026, 8, 1)), isFalse);
    expect(_habit(isActive: false).appliesTo(DateTime(2026, 7, 6)), isFalse);
  });

  test('WeeklyHabitSummary calculates completed and planned totals', () {
    final summary = WeeklyHabitSummary(
      weekStart: DateTime(2026, 7, 6),
      weekEnd: DateTime(2026, 7, 12),
      stats: [
        WeeklyHabitStat(
          habit: _habit(id: 'habit-1'),
          plannedDays: 5,
          completedDays: 3,
          currentStreak: 2,
        ),
        WeeklyHabitStat(
          habit: _habit(id: 'habit-2'),
          plannedDays: 2,
          completedDays: 0,
          currentStreak: 0,
        ),
      ],
    );

    expect(summary.plannedDays, 7);
    expect(summary.completedDays, 3);
    expect(summary.completionRate, closeTo(3 / 7, 0.0001));
    expect(summary.bestHabits.first.habit.id, 'habit-1');
    expect(summary.weakestHabits.first.habit.id, 'habit-2');
  });

  test('HabitLogInput conflict key prevents duplicate logs for a day', () {
    final date = DateTime(2026, 7, 6);
    final first = HabitLogInput(
      habitId: 'habit-1',
      date: date,
      isCompleted: true,
      value: 20,
    );
    final second = HabitLogInput(
      habitId: 'habit-1',
      date: date,
      isCompleted: false,
      value: 10,
    );

    expect(first.conflictKey('user-1'), second.conflictKey('user-1'));
    expect(
      first.conflictKey('user-1'),
      habitLogConflictKey(userId: 'user-1', habitId: 'habit-1', date: date),
    );
  });
}

Habit _habit({
  String id = 'habit',
  List<int> weekdays = const [1, 2, 3, 4, 5],
  bool isActive = true,
}) {
  return Habit(
    id: id,
    userId: 'user-1',
    title: 'Habit',
    targetType: HabitTargetType.boolean,
    weekdays: weekdays,
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 31),
    isActive: isActive,
    createdAt: DateTime(2026, 7, 1),
  );
}
