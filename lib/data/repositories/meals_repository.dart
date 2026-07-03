import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meal_entry.dart';
import 'repository_utils.dart';

class MealsRepository {
  const MealsRepository(this._client);

  final SupabaseClient _client;

  String get _userId => requireAuthenticatedUserId(_client);

  Future<List<MealEntry>> listByDate(String dateKey) async {
    final rows = await _client
        .from('meal_entries')
        .select()
        .eq('user_id', _userId)
        .eq('date', dateKey)
        .order('created_at', ascending: false);

    return rows.map(MealEntry.fromMap).toList();
  }

  Future<void> create(MealEntryInput input) {
    return _client.from('meal_entries').insert(input.toMap(_userId));
  }

  Future<void> update(String id, MealEntryInput input) {
    return _client
        .from('meal_entries')
        .update(input.toUpdateMap())
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> delete(String id) {
    return _client
        .from('meal_entries')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
