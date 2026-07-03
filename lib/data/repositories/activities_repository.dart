import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity_entry.dart';
import 'repository_utils.dart';

class ActivitiesRepository {
  const ActivitiesRepository(this._client);

  final SupabaseClient _client;

  String get _userId => requireAuthenticatedUserId(_client);

  Future<List<ActivityEntry>> listByDate(String dateKey) async {
    final rows = await _client
        .from('activity_entries')
        .select()
        .eq('user_id', _userId)
        .eq('date', dateKey)
        .order('created_at', ascending: false);

    return rows.map(ActivityEntry.fromMap).toList();
  }

  Future<void> create(ActivityEntryInput input) {
    return _client.from('activity_entries').insert(input.toMap(_userId));
  }

  Future<void> update(String id, ActivityEntryInput input) {
    return _client
        .from('activity_entries')
        .update(input.toUpdateMap())
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> delete(String id) {
    return _client
        .from('activity_entries')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
