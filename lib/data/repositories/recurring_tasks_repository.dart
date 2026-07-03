import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/recurring_task.dart';
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

  Future<void> generateTasksForDate(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final dateKey = formatDateKey(day);
    final recurringTasks = await list();
    final applicable = recurringTasks
        .where((task) => task.appliesTo(day))
        .toList();

    if (applicable.isEmpty) {
      return;
    }

    final rows = applicable.map((task) {
      return {
        'user_id': _userId,
        'recurring_task_id': task.id,
        'title': task.title,
        'description': task.description,
        'due_date': dateKey,
        'due_time': task.time,
        'priority': task.priority,
        'is_completed': false,
      };
    }).toList();

    await _client
        .from('todos')
        .upsert(
          rows,
          onConflict: 'user_id,recurring_task_id,due_date',
          ignoreDuplicates: true,
        );
  }
}
