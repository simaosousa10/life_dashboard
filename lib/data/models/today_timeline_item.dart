class TodayTimelineItem {
  const TodayTimelineItem({
    required this.id,
    required this.title,
    required this.category,
    required this.start,
    required this.type,
    required this.hasTime,
    this.isCompleted = false,
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
  final bool isCompleted;
}

enum TodayItemType { schedule, calendarEvent, todo, recurringTask, habit }
