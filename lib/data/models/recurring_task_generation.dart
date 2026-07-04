import '../../core/constants/app_constants.dart';
import 'recurring_task.dart';
import 'recurring_task_exception.dart';

class GeneratedRecurringTodo {
  const GeneratedRecurringTodo({
    required this.userId,
    required this.recurringTaskId,
    required this.title,
    required this.dueDate,
    required this.priority,
    this.description,
    this.dueTime,
  });

  final String userId;
  final String recurringTaskId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final String? dueTime;
  final String priority;

  String get conflictKey =>
      '$userId|$recurringTaskId|${formatDateKey(dueDate)}';

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'recurring_task_id': recurringTaskId,
    'title': title,
    'description': description,
    'due_date': formatDateKey(dueDate),
    'due_time': dueTime,
    'priority': priority,
    'is_completed': false,
  };
}

List<GeneratedRecurringTodo> buildRecurringTodosForDate({
  required String userId,
  required DateTime date,
  required List<RecurringTask> tasks,
  required List<RecurringTaskException> exceptions,
  required List<RecurringTaskException> rescheduledToDate,
}) {
  final day = DateTime(date.year, date.month, date.day);
  final exceptionsByTask = {
    for (final exception in exceptions) exception.recurringTaskId: exception,
  };
  final tasksById = {for (final task in tasks) task.id: task};
  final byConflictKey = <String, GeneratedRecurringTodo>{};

  for (final task in tasks) {
    if (!task.appliesTo(day)) {
      continue;
    }
    final exception = exceptionsByTask[task.id];
    if (exception != null &&
        exception.exceptionType != RecurringTaskExceptionType.modified) {
      continue;
    }
    final todo = GeneratedRecurringTodo(
      userId: userId,
      recurringTaskId: task.id,
      title: task.title,
      description: task.description,
      dueDate: day,
      dueTime: exception?.newTime ?? task.time,
      priority: task.priority,
    );
    byConflictKey.putIfAbsent(todo.conflictKey, () => todo);
  }

  for (final exception in rescheduledToDate) {
    if (exception.exceptionType != RecurringTaskExceptionType.reschedule ||
        exception.newDueDate == null ||
        formatDateKey(exception.newDueDate!) != formatDateKey(day)) {
      continue;
    }
    final task = tasksById[exception.recurringTaskId];
    if (task == null) {
      continue;
    }
    final todo = GeneratedRecurringTodo(
      userId: userId,
      recurringTaskId: task.id,
      title: task.title,
      description: task.description,
      dueDate: day,
      dueTime: exception.newTime ?? task.time,
      priority: task.priority,
    );
    byConflictKey.putIfAbsent(todo.conflictKey, () => todo);
  }

  return byConflictKey.values.toList()..sort((left, right) {
    final leftTime = left.dueTime ?? '';
    final rightTime = right.dueTime ?? '';
    final timeCompare = leftTime.compareTo(rightTime);
    if (timeCompare != 0) {
      return timeCompare;
    }
    return left.title.compareTo(right.title);
  });
}
