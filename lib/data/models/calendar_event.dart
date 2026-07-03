import '../../core/constants/app_constants.dart';
import 'model_helpers.dart';

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    required this.eventDate,
    required this.category,
    required this.createdAt,
    this.description,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String category;
  final DateTime createdAt;

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      eventDate: parseDate(map['event_date']),
      category: map['category'] as String,
      createdAt: parseDate(map['created_at']),
    );
  }
}

class CalendarEventInput {
  const CalendarEventInput({
    required this.title,
    required this.eventDate,
    required this.category,
    this.description,
  });

  final String title;
  final String? description;
  final DateTime eventDate;
  final String category;

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'title': title.trim(),
    'description': description,
    'event_date': formatDateKey(eventDate),
    'category': category,
  };

  Map<String, dynamic> toUpdateMap() => {
    'title': title.trim(),
    'description': description,
    'event_date': formatDateKey(eventDate),
    'category': category,
  };
}
