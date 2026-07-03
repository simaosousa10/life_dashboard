import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/schedule_block.dart';
import 'repository_utils.dart';

class ScheduleRepository {
  const ScheduleRepository(this._client);

  final SupabaseClient _client;

  String get _userId => requireAuthenticatedUserId(_client);

  Future<List<ScheduleBlock>> list() async {
    final rows = await _client
        .from('schedule_blocks')
        .select()
        .eq('user_id', _userId)
        .order('weekday')
        .order('start_time');

    return rows.map(ScheduleBlock.fromMap).toList();
  }

  Future<void> create(ScheduleBlockInput input) {
    return _client.from('schedule_blocks').insert(input.toMap(_userId));
  }

  Future<void> update(String id, ScheduleBlockInput input) {
    return _client
        .from('schedule_blocks')
        .update(input.toUpdateMap())
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> delete(String id) {
    return _client
        .from('schedule_blocks')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
