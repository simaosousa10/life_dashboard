import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/water_entry.dart';
import 'repository_utils.dart';

class WaterRepository {
  const WaterRepository(this._client);

  final SupabaseClient _client;

  String get _userId => requireAuthenticatedUserId(_client);

  Future<List<WaterEntry>> listByDate(String dateKey) async {
    final rows = await _client
        .from('water_entries')
        .select()
        .eq('user_id', _userId)
        .eq('date', dateKey)
        .order('created_at', ascending: false);

    return rows.map(WaterEntry.fromMap).toList();
  }

  Future<void> add(WaterEntryInput input) {
    return _client.from('water_entries').insert(input.toMap(_userId));
  }

  Future<void> delete(String id) {
    return _client
        .from('water_entries')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
