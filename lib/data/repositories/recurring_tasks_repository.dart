import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/recurring_task.dart';
import '../models/recurring_task_exception.dart';
import '../models/todo_item.dart';
import 'repository_utils.dart';

class RecurringTasksRepository {
  const RecurringTasksRepository(this._client);

  final SupabaseClient _client;

  String get _userId => requireAuthenticatedUserId(_client);

  Future<List<RecurringTask>> list() async {
    final rows = await _client
        .from('recurring_tasks')
        .select()
        .eq('user_id', _userId)
        .order('is_active', ascending: false)
        .order('created_at', ascending: false);

    return rows.map(RecurringTask.fromMap).toList();
  }

  Future<void> create(RecurringTaskInput input) {
    return _client.from('recurring_tasks').insert(input.toMap(_userId));
  }

  Future<void> update(String id, RecurringTaskInput input) {
    return _client
        .from('recurring_tasks')
        .update(input.toUpdateMap())
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> delete(String id) {
    return _client
        .from('recurring_tasks')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<List<RecurringTaskException>> listExceptionsForDate(
    DateTime date,
  ) async {
    final dateKey = formatDateKey(date);
    final rows = await _client
        .from('recurring_task_exceptions')
        .select()
        .eq('user_id', _userId)
        .eq('date', dateKey);

    return rows.map(RecurringTaskException.fromMap).toList();
  }

  Future<List<RecurringTaskException>> listRescheduledToDate(
    DateTime date,
  ) async {
    final dateKey = formatDateKey(date);
    final rows = await _client
        .from('recurring_task_exceptions')
        .select()
        .eq('user_id', _userId)
        .eq('new_due_date', dateKey);

    return rows.map(RecurringTaskException.fromMap).toList();
  }

  Future<void> skipOccurrence({
    required String recurringTaskId,
    required DateTime date,
  }) async {
    final dateKey = formatDateKey(date);
    await _client
        .from('recurring_task_exceptions')
        .upsert(
          RecurringTaskExceptionInput(
            recurringTaskId: recurringTaskId,
            date: date,
            exceptionType: RecurringTaskExceptionType.skip,
          ).toMap(_userId),
          onConflict: 'user_id,recurring_task_id,date',
        );

    await _client
        .from('todos')
        .delete()
        .eq('user_id', _userId)
        .eq('recurring_task_id', recurringTaskId)
        .eq('due_date', dateKey);
  }

  Future<void> rescheduleOccurrence({
    required TodoItem todo,
    required DateTime newDueDate,
    required String? newTime,
  }) async {
    final recurringTaskId = todo.recurringTaskId;
    final originalDate = todo.dueDate;
    if (recurringTaskId == null || originalDate == null) {
      return;
    }

    await _client
        .from('recurring_task_exceptions')
        .upsert(
          RecurringTaskExceptionInput(
            recurringTaskId: recurringTaskId,
            date: originalDate,
            exceptionType: RecurringTaskExceptionType.reschedule,
            newDueDate: newDueDate,
            newTime: newTime,
          ).toMap(_userId),
          onConflict: 'user_id,recurring_task_id,date',
        );

    await _client
        .from('todos')
        .update({'due_date': formatDateKey(newDueDate), 'due_time': newTime})
        .eq('id', todo.id)
        .eq('user_id', _userId);
  }

  Future<void> generateTasksForDate(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final dateKey = formatDateKey(day);
    final recurringTasks = await list();
    final exceptions = await listExceptionsForDate(day);
    final rescheduledToDate = await listRescheduledToDate(day);
    final exceptionsByTask = {
      for (final exception in exceptions) exception.recurringTaskId: exception,
    };
    final tasksById = {for (final task in recurringTasks) task.id: task};
    final applicable = recurringTasks.where((task) {
      if (!task.appliesTo(day)) {
        return false;
      }
      final exception = exceptionsByTask[task.id];
      return exception == null ||
          exception.exceptionType == RecurringTaskExceptionType.modified;
    }).toList();

    if (applicable.isEmpty && rescheduledToDate.isEmpty) {
      return;
    }

    final rows = applicable.map((task) {
      final exception = exceptionsByTask[task.id];
      return {
        'user_id': _userId,
        'recurring_task_id': task.id,
        'title': task.title,
        'description': task.description,
        'due_date': dateKey,
        'due_time': exception?.newTime ?? task.time,
        'priority': task.priority,
        'is_completed': false,
      };
    }).toList();

    for (final exception in rescheduledToDate) {
      if (exception.exceptionType != RecurringTaskExceptionType.reschedule ||
          exception.newDueDate == null) {
        continue;
      }
      final task = tasksById[exception.recurringTaskId];
      if (task == null) {
        continue;
      }
      rows.add({
        'user_id': _userId,
        'recurring_task_id': task.id,
        'title': task.title,
        'description': task.description,
        'due_date': formatDateKey(exception.newDueDate!),
        'due_time': exception.newTime ?? task.time,
        'priority': task.priority,
        'is_completed': false,
      });
    }

    await _client
        .from('todos')
        .upsert(
          rows,
          onConflict: 'user_id,recurring_task_id,due_date',
          ignoreDuplicates: true,
        );
  }
}
