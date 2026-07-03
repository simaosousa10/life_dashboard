import 'activity_entry.dart';
import 'calendar_event.dart';
import 'meal_entry.dart';
import 'schedule_block.dart';
import 'todo_item.dart';
import 'user_profile.dart';
import 'water_entry.dart';

class HomeDashboardData {
  const HomeDashboardData({
    required this.displayName,
    required this.date,
    required this.profile,
    required this.todayScheduleBlocks,
    required this.currentBlock,
    required this.nextScheduleBlocks,
    required this.todayEvents,
    required this.todayTodos,
    required this.waterEntries,
    required this.mealEntries,
    required this.activityEntries,
    required this.completedTasks,
    required this.totalTasks,
    required this.waterMl,
    required this.waterGoalMl,
    required this.caloriesIn,
    required this.caloriesOut,
  });

  final String displayName;
  final DateTime date;
  final UserProfile? profile;
  final List<ScheduleBlock> todayScheduleBlocks;
  final ScheduleBlock? currentBlock;
  final List<ScheduleBlock> nextScheduleBlocks;
  final List<CalendarEvent> todayEvents;
  final List<TodoItem> todayTodos;
  final List<WaterEntry> waterEntries;
  final List<MealEntry> mealEntries;
  final List<ActivityEntry> activityEntries;
  final int completedTasks;
  final int totalTasks;
  final int waterMl;
  final int waterGoalMl;
  final int caloriesIn;
  final int caloriesOut;
}
