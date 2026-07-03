import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_category.dart';
import 'repository_utils.dart';

class CategoriesRepository {
  const CategoriesRepository(this._client);

  final SupabaseClient _client;

  String get _userId => requireAuthenticatedUserId(_client);

  Future<List<AppCategory>> list() async {
    final rows = await _client
        .from('categories')
        .select()
        .eq('user_id', _userId)
        .order('name');

    return rows.map(AppCategory.fromMap).toList();
  }

  Future<void> create(AppCategoryInput input) {
    return _client.from('categories').insert(input.toMap(_userId));
  }

  Future<void> delete(String id) {
    return _client
        .from('categories')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
