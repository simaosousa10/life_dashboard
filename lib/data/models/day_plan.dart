import 'activity_entry.dart';
import 'calendar_event.dart';
import 'habit.dart';
import 'meal_entry.dart';
import 'schedule_block.dart';
import 'today_timeline_item.dart';
import 'todo_item.dart';
import 'user_profile.dart';
import 'water_entry.dart';

class DayPlanData {
  const DayPlanData({
    required this.displayName,
    required this.date,
    required this.profile,
    required this.scheduleBlocks,
    required this.events,
    required this.todos,
    required this.habits,
    required this.waterEntries,
    required this.mealEntries,
    required this.activityEntries,
    required this.timelineItems,
  });

  final String displayName;
  final DateTime date;
  final UserProfile? profile;
  final List<ScheduleBlock> scheduleBlocks;
  final List<CalendarEvent> events;
  final List<TodoItem> todos;
  final List<TodayHabitEntry> habits;
  final List<WaterEntry> waterEntries;
  final List<MealEntry> mealEntries;
  final List<ActivityEntry> activityEntries;
  final List<TodayTimelineItem> timelineItems;

  int get completedTasks => todos.where((todo) => todo.isCompleted).length;

  int get totalTasks => todos.length;

  int get completedHabits =>
      habits.where((entry) => entry.log?.isCompleted == true).length;

  int get totalHabits => habits.length;

  int get waterMl => waterEntries.fold(0, (sum, entry) => sum + entry.amountMl);

  int get waterGoalMl => profile?.dailyWaterGoalMl ?? 2000;

  int get caloriesIn =>
      mealEntries.fold(0, (sum, entry) => sum + entry.calories);

  int get caloriesOut => activityEntries.fold(
    0,
    (sum, entry) => sum + entry.caloriesBurned.round(),
  );
}
