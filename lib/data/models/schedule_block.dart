import 'model_helpers.dart';

class ScheduleBlock {
  const ScheduleBlock({
    required this.id,
    required this.userId,
    required this.title,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.category,
    required this.createdAt,
    this.description,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final int weekday;
  final String startTime;
  final String endTime;
  final String category;
  final DateTime createdAt;

  factory ScheduleBlock.fromMap(Map<String, dynamic> map) {
    return ScheduleBlock(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      weekday: readInt(map, 'weekday'),
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      category: map['category'] as String,
      createdAt: parseDate(map['created_at']),
    );
  }
}

class ScheduleBlockInput {
  const ScheduleBlockInput({
    required this.title,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.category,
    this.description,
  });

  final String title;
  final String? description;
  final int weekday;
  final String startTime;
  final String endTime;
  final String category;

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'title': title.trim(),
    'description': description,
    'weekday': weekday,
    'start_time': startTime,
    'end_time': endTime,
    'category': category,
  };

  Map<String, dynamic> toUpdateMap() => {
    'title': title.trim(),
    'description': description,
    'weekday': weekday,
    'start_time': startTime,
    'end_time': endTime,
    'category': category,
  };
}
