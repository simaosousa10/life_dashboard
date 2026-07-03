class TodayTimelineData {
  const TodayTimelineData({
    required this.displayName,
    required this.date,
    required this.items,
    required this.completedTasks,
    required this.totalTasks,
    required this.waterMl,
    required this.waterGoalMl,
    required this.caloriesIn,
    required this.caloriesOut,
  });

  final String displayName;
  final DateTime date;
  final List<TodayTimelineItem> items;
  final int completedTasks;
  final int totalTasks;
  final int waterMl;
  final int waterGoalMl;
  final int caloriesIn;
  final int caloriesOut;
}

class TodayTimelineItem {
  const TodayTimelineItem({
    required this.id,
    required this.title,
    required this.category,
    required this.start,
    required this.type,
    required this.hasTime,
    this.description,
    this.end,
  });

  final String id;
  final String title;
  final String? description;
  final String category;
  final DateTime start;
  final DateTime? end;
  final TodayItemType type;
  final bool hasTime;
}

enum TodayItemType { schedule, calendarEvent, todo }
