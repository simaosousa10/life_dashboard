import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/habit.dart';
import 'repository_utils.dart';

class HabitsRepository {
  const HabitsRepository(this._client);

  final SupabaseClient _client;

  String get _userId => requireAuthenticatedUserId(_client);

  Future<List<Habit>> getHabits() async {
    final rows = await _client
        .from('habits')
        .select()
        .eq('user_id', _userId)
        .order('is_active', ascending: false)
        .order('title');

    return rows.map(Habit.fromMap).toList();
  }

  Future<void> createHabit(HabitInput input) {
    return _client.from('habits').insert(input.toMap(_userId));
  }

  Future<void> updateHabit(String id, HabitInput input) {
    return _client
        .from('habits')
        .update(input.toUpdateMap())
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> deleteHabit(String id) {
    return _client.from('habits').delete().eq('id', id).eq('user_id', _userId);
  }

  Future<List<Habit>> getHabitsForDate(DateTime date) async {
    final habits = await getHabits();
    return habits.where((habit) => habit.appliesTo(date)).toList();
  }

  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    final rows = await _client
        .from('habit_logs')
        .select()
        .eq('user_id', _userId)
        .eq('date', formatDateKey(date))
        .order('created_at');

    return rows.map(HabitLog.fromMap).toList();
  }

  Future<void> upsertHabitLog(HabitLogInput input) {
    return _client
        .from('habit_logs')
        .upsert(input.toMap(_userId), onConflict: 'user_id,habit_id,date');
  }

  Future<List<HabitLog>> getLogsForWeek(
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    final rows = await _client
        .from('habit_logs')
        .select()
        .eq('user_id', _userId)
        .gte('date', formatDateKey(weekStart))
        .lte('date', formatDateKey(weekEnd))
        .order('date');

    return rows.map(HabitLog.fromMap).toList();
  }

  Future<List<TodayHabitEntry>> getTodayEntries(DateTime date) async {
    final habits = await getHabitsForDate(date);
    final logs = await getLogsForDate(date);
    final logsByHabit = {for (final log in logs) log.habitId: log};
    return habits
        .map(
          (habit) => TodayHabitEntry(habit: habit, log: logsByHabit[habit.id]),
        )
        .toList();
  }

  Future<WeeklyHabitSummary> getWeeklySummary(
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    final habits = await getHabits();
    final logs = await getLogsForWeek(weekStart, weekEnd);
    final completedKeys = logs
        .where((log) => log.isCompleted)
        .map((log) => _habitDateKey(log.habitId, log.date))
        .toSet();

    final stats = habits
        .map((habit) {
          final plannedDates = _plannedDatesForHabit(habit, weekStart, weekEnd);
          final completedDays = plannedDates
              .where(
                (date) => completedKeys.contains(_habitDateKey(habit.id, date)),
              )
              .length;

          return WeeklyHabitStat(
            habit: habit,
            plannedDays: plannedDates.length,
            completedDays: completedDays,
            currentStreak: _currentStreak(habit, completedKeys, todayDate()),
          );
        })
        .where((stat) => stat.plannedDays > 0)
        .toList();

    return WeeklyHabitSummary(
      weekStart: weekStart,
      weekEnd: weekEnd,
      stats: stats,
    );
  }
}

List<DateTime> _plannedDatesForHabit(
  Habit habit,
  DateTime start,
  DateTime end,
) {
  final dates = <DateTime>[];
  var current = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);

  while (!current.isAfter(last)) {
    if (habit.appliesTo(current)) {
      dates.add(current);
    }
    current = current.add(const Duration(days: 1));
  }

  return dates;
}

int _currentStreak(Habit habit, Set<String> completedKeys, DateTime fromDate) {
  var streak = 0;
  var current = DateTime(fromDate.year, fromDate.month, fromDate.day);

  for (var checked = 0; checked < 7; checked += 1) {
    if (!habit.appliesTo(current)) {
      current = current.subtract(const Duration(days: 1));
      continue;
    }
    if (!completedKeys.contains(_habitDateKey(habit.id, current))) {
      break;
    }
    streak += 1;
    current = current.subtract(const Duration(days: 1));
  }

  return streak;
}

String _habitDateKey(String habitId, DateTime date) {
  return '$habitId:${formatDateKey(date)}';
}
