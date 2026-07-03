import '../../core/constants/app_constants.dart';
import 'model_helpers.dart';

class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.userId,
    required this.activityName,
    required this.durationMinutes,
    required this.met,
    required this.weightKg,
    required this.caloriesBurned,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String activityName;
  final int durationMinutes;
  final double met;
  final double weightKg;
  final double caloriesBurned;
  final DateTime date;
  final DateTime createdAt;

  factory ActivityEntry.fromMap(Map<String, dynamic> map) {
    return ActivityEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      activityName: map['activity_name'] as String,
      durationMinutes: readInt(map, 'duration_minutes'),
      met: readDouble(map, 'met'),
      weightKg: readDouble(map, 'weight_kg'),
      caloriesBurned: readDouble(map, 'calories_burned'),
      date: parseDate(map['date']),
      createdAt: parseDate(map['created_at']),
    );
  }
}

class ActivityEntryInput {
  const ActivityEntryInput({
    required this.activityName,
    required this.durationMinutes,
    required this.met,
    required this.weightKg,
    required this.date,
  });

  final String activityName;
  final int durationMinutes;
  final double met;
  final double weightKg;
  final DateTime date;

  double get caloriesBurned => met * weightKg * (durationMinutes / 60);

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'activity_name': activityName.trim(),
    'duration_minutes': durationMinutes,
    'met': met,
    'weight_kg': weightKg,
    'calories_burned': caloriesBurned,
    'date': formatDateKey(date),
  };

  Map<String, dynamic> toUpdateMap() => {
    'activity_name': activityName.trim(),
    'duration_minutes': durationMinutes,
    'met': met,
    'weight_kg': weightKg,
    'calories_burned': caloriesBurned,
    'date': formatDateKey(date),
  };
}
