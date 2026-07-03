import 'calendar_event.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.completedTasks,
    required this.pendingTasks,
    required this.waterMl,
    required this.caloriesIn,
    required this.caloriesOut,
    required this.upcomingEvents,
  });

  final int completedTasks;
  final int pendingTasks;
  final int waterMl;
  final int caloriesIn;
  final int caloriesOut;
  final List<CalendarEvent> upcomingEvents;
}
