import '../../core/constants/app_constants.dart';
import 'model_helpers.dart';

class StudyNote {
  const StudyNote({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.subject,
    required this.needsReview,
    required this.createdAt,
    this.nextReviewDate,
    this.difficulty,
  });

  final String id;
  final String userId;
  final String title;
  final String content;
  final String subject;
  final bool needsReview;
  final DateTime? nextReviewDate;
  final String? difficulty;
  final DateTime createdAt;

  factory StudyNote.fromMap(Map<String, dynamic> map) {
    return StudyNote(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      subject: map['subject'] as String,
      needsReview: map['needs_review'] as bool? ?? false,
      nextReviewDate: parseOptionalDate(map['next_review_date']),
      difficulty: map['difficulty'] as String?,
      createdAt: parseDate(map['created_at']),
    );
  }
}

class StudyNoteInput {
  const StudyNoteInput({
    required this.title,
    required this.content,
    required this.subject,
    required this.needsReview,
    this.nextReviewDate,
    this.difficulty,
  });

  final String title;
  final String content;
  final String subject;
  final bool needsReview;
  final DateTime? nextReviewDate;
  final String? difficulty;

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'title': title.trim(),
    'content': content.trim(),
    'subject': subject.trim(),
    'needs_review': needsReview,
    'next_review_date': nextReviewDate == null
        ? null
        : formatDateKey(nextReviewDate!),
    'difficulty': difficulty,
  };

  Map<String, dynamic> toUpdateMap() => {
    'title': title.trim(),
    'content': content.trim(),
    'subject': subject.trim(),
    'needs_review': needsReview,
    'next_review_date': nextReviewDate == null
        ? null
        : formatDateKey(nextReviewDate!),
    'difficulty': difficulty,
  };
}
