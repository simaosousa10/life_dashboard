import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/data/models/recurring_task.dart';
import 'package:life_dashboard/data/models/recurring_task_exception.dart';
import 'package:life_dashboard/data/models/recurring_task_generation.dart';

void main() {
  test(
    'RecurringTask.appliesTo respects weekday, active state and date range',
    () {
      final task = _task(weekdays: const [1, 3]);

      expect(task.appliesTo(DateTime(2026, 7, 6)), isTrue);
      expect(task.appliesTo(DateTime(2026, 7, 7)), isFalse);
      expect(task.appliesTo(DateTime(2026, 6, 30)), isFalse);
      expect(task.appliesTo(DateTime(2026, 8, 1)), isFalse);
      expect(_task(isActive: false).appliesTo(DateTime(2026, 7, 6)), isFalse);
    },
  );

  test('skip exception prevents generation for the original date', () {
    final rows = buildRecurringTodosForDate(
      userId: 'user-1',
      date: DateTime(2026, 7, 6),
      tasks: [_task()],
      exceptions: [
        _exception(
          type: RecurringTaskExceptionType.skip,
          date: DateTime(2026, 7, 6),
        ),
      ],
      rescheduledToDate: const [],
    );

    expect(rows, isEmpty);
  });

  test('reschedule exception moves generation to the new date', () {
    final originalRows = buildRecurringTodosForDate(
      userId: 'user-1',
      date: DateTime(2026, 7, 6),
      tasks: [_task()],
      exceptions: [
        _exception(
          type: RecurringTaskExceptionType.reschedule,
          date: DateTime(2026, 7, 6),
          newDueDate: DateTime(2026, 7, 7),
          newTime: '14:30',
        ),
      ],
      rescheduledToDate: const [],
    );
    final movedRows = buildRecurringTodosForDate(
      userId: 'user-1',
      date: DateTime(2026, 7, 7),
      tasks: [_task()],
      exceptions: const [],
      rescheduledToDate: [
        _exception(
          type: RecurringTaskExceptionType.reschedule,
          date: DateTime(2026, 7, 6),
          newDueDate: DateTime(2026, 7, 7),
          newTime: '14:30',
        ),
      ],
    );

    expect(originalRows, isEmpty);
    expect(movedRows, hasLength(1));
    expect(movedRows.single.dueDate, DateTime(2026, 7, 7));
    expect(movedRows.single.dueTime, '14:30');
  });

  test('modified exception keeps occurrence and applies override time', () {
    final rows = buildRecurringTodosForDate(
      userId: 'user-1',
      date: DateTime(2026, 7, 6),
      tasks: [_task(time: '09:00')],
      exceptions: [
        _exception(
          type: RecurringTaskExceptionType.modified,
          date: DateTime(2026, 7, 6),
          newTime: '11:00',
        ),
      ],
      rescheduledToDate: const [],
    );

    expect(rows, hasLength(1));
    expect(rows.single.dueTime, '11:00');
  });

  test('generation deduplicates recurring todos by user task and due date', () {
    final rows = buildRecurringTodosForDate(
      userId: 'user-1',
      date: DateTime(2026, 7, 7),
      tasks: [
        _task(weekdays: const [2], time: '09:00'),
      ],
      exceptions: const [],
      rescheduledToDate: [
        _exception(
          type: RecurringTaskExceptionType.reschedule,
          date: DateTime(2026, 7, 6),
          newDueDate: DateTime(2026, 7, 7),
          newTime: '14:30',
        ),
      ],
    );

    expect(rows, hasLength(1));
    expect(rows.single.conflictKey, 'user-1|task-1|2026-07-07');
  });
}

RecurringTask _task({
  List<int> weekdays = const [1],
  String? time = '09:00',
  bool isActive = true,
}) {
  return RecurringTask(
    id: 'task-1',
    userId: 'user-1',
    title: 'Recurring task',
    weekdays: weekdays,
    time: time,
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 31),
    priority: 'normal',
    isActive: isActive,
    createdAt: DateTime(2026, 7, 1),
  );
}

RecurringTaskException _exception({
  required RecurringTaskExceptionType type,
  required DateTime date,
  DateTime? newDueDate,
  String? newTime,
}) {
  return RecurringTaskException(
    id: '${type.value}-${date.toIso8601String()}',
    userId: 'user-1',
    recurringTaskId: 'task-1',
    date: date,
    exceptionType: type,
    newDueDate: newDueDate,
    newTime: newTime,
    createdAt: DateTime(2026, 7, 1),
  );
}
