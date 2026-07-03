import '../../core/constants/app_constants.dart';
import 'model_helpers.dart';

enum RecurringTaskExceptionType { skip, reschedule, modified }

RecurringTaskExceptionType recurringTaskExceptionTypeFromValue(String value) {
  return RecurringTaskExceptionType.values.firstWhere(
    (type) => type.value == value,
    orElse: () => RecurringTaskExceptionType.skip,
  );
}

extension RecurringTaskExceptionTypeValue on RecurringTaskExceptionType {
  String get value {
    return switch (this) {
      RecurringTaskExceptionType.skip => 'skip',
      RecurringTaskExceptionType.reschedule => 'reschedule',
      RecurringTaskExceptionType.modified => 'modified',
    };
  }
}

class RecurringTaskException {
  const RecurringTaskException({
    required this.id,
    required this.userId,
    required this.recurringTaskId,
    required this.date,
    required this.exceptionType,
    required this.createdAt,
    this.newDueDate,
    this.newTime,
  });

  final String id;
  final String userId;
  final String recurringTaskId;
  final DateTime date;
  final RecurringTaskExceptionType exceptionType;
  final DateTime? newDueDate;
  final String? newTime;
  final DateTime createdAt;

  factory RecurringTaskException.fromMap(Map<String, dynamic> map) {
    return RecurringTaskException(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      recurringTaskId: map['recurring_task_id'] as String,
      date: parseDate(map['date']),
      exceptionType: recurringTaskExceptionTypeFromValue(
        map['exception_type'] as String,
      ),
      newDueDate: parseOptionalDate(map['new_due_date']),
      newTime: map['new_time'] as String?,
      createdAt: parseDate(map['created_at']),
    );
  }
}

class RecurringTaskExceptionInput {
  const RecurringTaskExceptionInput({
    required this.recurringTaskId,
    required this.date,
    required this.exceptionType,
    this.newDueDate,
    this.newTime,
  });

  final String recurringTaskId;
  final DateTime date;
  final RecurringTaskExceptionType exceptionType;
  final DateTime? newDueDate;
  final String? newTime;

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'recurring_task_id': recurringTaskId,
    'date': formatDateKey(date),
    'exception_type': exceptionType.value,
    'new_due_date': newDueDate == null ? null : formatDateKey(newDueDate!),
    'new_time': newTime,
  };
}
