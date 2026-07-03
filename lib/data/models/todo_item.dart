import '../../core/constants/app_constants.dart';
import 'model_helpers.dart';

class TodoItem {
  const TodoItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.priority,
    required this.isCompleted,
    required this.createdAt,
    this.recurringTaskId,
    this.description,
    this.dueDate,
    this.dueTime,
  });

  final String id;
  final String userId;
  final String? recurringTaskId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? dueTime;
  final String priority;
  final bool isCompleted;
  final DateTime createdAt;

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      recurringTaskId: map['recurring_task_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: parseOptionalDate(map['due_date']),
      dueTime: map['due_time'] as String?,
      priority: map['priority'] as String,
      isCompleted: map['is_completed'] as bool,
      createdAt: parseDate(map['created_at']),
    );
  }
}

class TodoItemInput {
  const TodoItemInput({
    required this.title,
    required this.priority,
    this.description,
    this.dueDate,
    this.dueTime,
    this.recurringTaskId,
    this.isCompleted = false,
  });

  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? dueTime;
  final String? recurringTaskId;
  final String priority;
  final bool isCompleted;

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'recurring_task_id': recurringTaskId,
    'title': title.trim(),
    'description': description,
    'due_date': dueDate == null ? null : formatDateKey(dueDate!),
    'due_time': dueTime,
    'priority': priority,
    'is_completed': isCompleted,
  };

  Map<String, dynamic> toUpdateMap() => {
    'title': title.trim(),
    'description': description,
    'due_date': dueDate == null ? null : formatDateKey(dueDate!),
    'due_time': dueTime,
    'priority': priority,
    'is_completed': isCompleted,
  };
}
