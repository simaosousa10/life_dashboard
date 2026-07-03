import '../../core/constants/app_constants.dart';
import 'model_helpers.dart';

class RecurringTask {
  const RecurringTask({
    required this.id,
    required this.userId,
    required this.title,
    required this.weekdays,
    required this.startDate,
    required this.priority,
    required this.isActive,
    required this.createdAt,
    this.description,
    this.time,
    this.endDate,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final List<int> weekdays;
  final String? time;
  final DateTime startDate;
  final DateTime? endDate;
  final String priority;
  final bool isActive;
  final DateTime createdAt;

  factory RecurringTask.fromMap(Map<String, dynamic> map) {
    final rawWeekdays = map['weekdays'] as List<dynamic>;
    return RecurringTask(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      weekdays: rawWeekdays.map((value) => (value as num).toInt()).toList()
        ..sort(),
      time: map['time'] as String?,
      startDate: parseDate(map['start_date']),
      endDate: parseOptionalDate(map['end_date']),
      priority: map['priority'] as String,
      isActive: map['is_active'] as bool,
      createdAt: parseDate(map['created_at']),
    );
  }

  bool appliesTo(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = endDate == null
        ? null
        : DateTime(endDate!.year, endDate!.month, endDate!.day);

    if (!isActive || !weekdays.contains(day.weekday)) {
      return false;
    }
    if (day.isBefore(start)) {
      return false;
    }
    if (end != null && day.isAfter(end)) {
      return false;
    }
    return true;
  }
}

class RecurringTaskInput {
  const RecurringTaskInput({
    required this.title,
    required this.weekdays,
    required this.startDate,
    required this.priority,
    required this.isActive,
    this.description,
    this.time,
    this.endDate,
  });

  final String title;
  final String? description;
  final List<int> weekdays;
  final String? time;
  final DateTime startDate;
  final DateTime? endDate;
  final String priority;
  final bool isActive;

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'title': title.trim(),
    'description': description,
    'weekdays': [...weekdays]..sort(),
    'time': time,
    'start_date': formatDateKey(startDate),
    'end_date': endDate == null ? null : formatDateKey(endDate!),
    'priority': priority,
    'is_active': isActive,
  };

  Map<String, dynamic> toUpdateMap() => {
    'title': title.trim(),
    'description': description,
    'weekdays': [...weekdays]..sort(),
    'time': time,
    'start_date': formatDateKey(startDate),
    'end_date': endDate == null ? null : formatDateKey(endDate!),
    'priority': priority,
    'is_active': isActive,
  };
}
