import 'habit.dart';

class WeeklyReviewData {
  const WeeklyReviewData({
    required this.weekStart,
    required this.weekEnd,
    required this.habitSummary,
    required this.completedTasks,
    required this.overdueTasks,
    required this.averageWaterMl,
    required this.caloriesIn,
    required this.caloriesOut,
    required this.dailyReviewCount,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final WeeklyHabitSummary habitSummary;
  final int completedTasks;
  final int overdueTasks;
  final int averageWaterMl;
  final int caloriesIn;
  final int caloriesOut;
  final int dailyReviewCount;

  WeeklyHabitStat? get bestHabit {
    if (habitSummary.bestHabits.isEmpty) {
      return null;
    }
    return habitSummary.bestHabits.first;
  }

  WeeklyHabitStat? get weakestHabit {
    if (habitSummary.weakestHabits.isEmpty) {
      return null;
    }
    return habitSummary.weakestHabits.first;
  }
}
