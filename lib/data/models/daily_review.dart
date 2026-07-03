import '../../core/constants/app_constants.dart';
import 'model_helpers.dart';

class DailyReview {
  const DailyReview({
    required this.id,
    required this.userId,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.mood,
  });

  final String id;
  final String userId;
  final DateTime date;
  final String? note;
  final int? mood;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory DailyReview.fromMap(Map<String, dynamic> map) {
    return DailyReview(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      date: parseDate(map['date']),
      note: map['note'] as String?,
      mood: map['mood'] as int?,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }
}

class DailyReviewInput {
  const DailyReviewInput({required this.date, this.note, this.mood});

  final DateTime date;
  final String? note;
  final int? mood;

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'date': formatDateKey(date),
    'note': note,
    'mood': mood,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };
}
