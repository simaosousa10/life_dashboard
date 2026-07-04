import '../../core/constants/app_constants.dart';
import 'model_helpers.dart';

enum HabitTargetType { boolean, duration, quantity }

HabitTargetType habitTargetTypeFromValue(String value) {
  return HabitTargetType.values.firstWhere(
    (type) => type.value == value,
    orElse: () => HabitTargetType.boolean,
  );
}

extension HabitTargetTypeText on HabitTargetType {
  String get value {
    return switch (this) {
      HabitTargetType.boolean => 'boolean',
      HabitTargetType.duration => 'duration',
      HabitTargetType.quantity => 'quantity',
    };
  }

  String get label {
    return switch (this) {
      HabitTargetType.boolean => 'Feito',
      HabitTargetType.duration => 'Duracao',
      HabitTargetType.quantity => 'Quantidade',
    };
  }
}

class Habit {
  const Habit({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetType,
    required this.weekdays,
    required this.startDate,
    required this.isActive,
    required this.createdAt,
    this.description,
    this.category,
    this.targetValue,
    this.targetUnit,
    this.endDate,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? category;
  final HabitTargetType targetType;
  final double? targetValue;
  final String? targetUnit;
  final List<int> weekdays;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  factory Habit.fromMap(Map<String, dynamic> map) {
    final rawWeekdays = map['weekdays'] as List<dynamic>;
    return Habit(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
      targetType: habitTargetTypeFromValue(map['target_type'] as String),
      targetValue: _readNullableDouble(map['target_value']),
      targetUnit: map['target_unit'] as String?,
      weekdays: rawWeekdays.map((value) => (value as num).toInt()).toList()
        ..sort(),
      startDate: parseDate(map['start_date']),
      endDate: parseOptionalDate(map['end_date']),
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

class HabitInput {
  const HabitInput({
    required this.title,
    required this.targetType,
    required this.weekdays,
    required this.startDate,
    required this.isActive,
    this.description,
    this.category,
    this.targetValue,
    this.targetUnit,
    this.endDate,
  });

  final String title;
  final String? description;
  final String? category;
  final HabitTargetType targetType;
  final double? targetValue;
  final String? targetUnit;
  final List<int> weekdays;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'title': title.trim(),
    'description': description,
    'category': category,
    'target_type': targetType.value,
    'target_value': targetValue,
    'target_unit': targetUnit,
    'weekdays': [...weekdays]..sort(),
    'start_date': formatDateKey(startDate),
    'end_date': endDate == null ? null : formatDateKey(endDate!),
    'is_active': isActive,
  };

  Map<String, dynamic> toUpdateMap() => {
    'title': title.trim(),
    'description': description,
    'category': category,
    'target_type': targetType.value,
    'target_value': targetValue,
    'target_unit': targetUnit,
    'weekdays': [...weekdays]..sort(),
    'start_date': formatDateKey(startDate),
    'end_date': endDate == null ? null : formatDateKey(endDate!),
    'is_active': isActive,
  };
}

class HabitLog {
  const HabitLog({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.date,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.value,
    this.note,
  });

  final String id;
  final String userId;
  final String habitId;
  final DateTime date;
  final bool isCompleted;
  final double? value;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      habitId: map['habit_id'] as String,
      date: parseDate(map['date']),
      isCompleted: map['is_completed'] as bool,
      value: _readNullableDouble(map['value']),
      note: map['note'] as String?,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }
}

class HabitLogInput {
  const HabitLogInput({
    required this.habitId,
    required this.date,
    required this.isCompleted,
    this.value,
    this.note,
  });

  final String habitId;
  final DateTime date;
  final bool isCompleted;
  final double? value;
  final String? note;

  String conflictKey(String userId) =>
      habitLogConflictKey(userId: userId, habitId: habitId, date: date);

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'habit_id': habitId,
    'date': formatDateKey(date),
    'is_completed': isCompleted,
    'value': value,
    'note': note,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };
}

String habitLogConflictKey({
  required String userId,
  required String habitId,
  required DateTime date,
}) {
  return '$userId|$habitId|${formatDateKey(date)}';
}

class TodayHabitEntry {
  const TodayHabitEntry({required this.habit, this.log});

  final Habit habit;
  final HabitLog? log;
}

class WeeklyHabitSummary {
  const WeeklyHabitSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.stats,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final List<WeeklyHabitStat> stats;

  int get plannedDays => stats.fold(0, (sum, stat) => sum + stat.plannedDays);

  int get completedDays =>
      stats.fold(0, (sum, stat) => sum + stat.completedDays);

  double get completionRate {
    if (plannedDays == 0) {
      return 0;
    }
    return completedDays / plannedDays;
  }

  List<WeeklyHabitStat> get bestHabits {
    final items = stats.where((stat) => stat.plannedDays > 0).toList()
      ..sort(
        (left, right) => right.completionRate.compareTo(left.completionRate),
      );
    return items.take(2).toList();
  }

  List<WeeklyHabitStat> get weakestHabits {
    final items = stats.where((stat) => stat.plannedDays > 0).toList()
      ..sort(
        (left, right) => left.completionRate.compareTo(right.completionRate),
      );
    return items.take(2).toList();
  }
}

class WeeklyHabitStat {
  const WeeklyHabitStat({
    required this.habit,
    required this.plannedDays,
    required this.completedDays,
    required this.currentStreak,
  });

  final Habit habit;
  final int plannedDays;
  final int completedDays;
  final int currentStreak;

  double get completionRate {
    if (plannedDays == 0) {
      return 0;
    }
    return completedDays / plannedDays;
  }
}

double? _readNullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}
