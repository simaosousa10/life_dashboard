import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/todo_item.dart';
import 'repository_utils.dart';

class TodosRepository {
  const TodosRepository(this._client);

  final SupabaseClient _client;

  String get _userId => requireAuthenticatedUserId(_client);

  Future<List<TodoItem>> list() async {
    final rows = await _client
        .from('todos')
        .select()
        .eq('user_id', _userId)
        .order('is_completed')
        .order('due_date', nullsFirst: false)
        .order('due_time', nullsFirst: false)
        .order('created_at', ascending: false);

    return rows.map(TodoItem.fromMap).toList();
  }

  Future<void> create(TodoItemInput input) {
    return _client.from('todos').insert(input.toMap(_userId));
  }

  Future<void> update(String id, TodoItemInput input) {
    return _client
        .from('todos')
        .update(input.toUpdateMap())
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> setCompleted(String id, bool isCompleted) {
    return _client
        .from('todos')
        .update({'is_completed': isCompleted})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> delete(String id) {
    return _client.from('todos').delete().eq('id', id).eq('user_id', _userId);
  }
}
