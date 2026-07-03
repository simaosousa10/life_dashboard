import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/daily_review.dart';
import 'repository_utils.dart';

class DailyReviewsRepository {
  const DailyReviewsRepository(this._client);

  final SupabaseClient _client;

  String get _userId => requireAuthenticatedUserId(_client);

  Future<DailyReview?> getByDate(DateTime date) async {
    final row = await _client
        .from('daily_reviews')
        .select()
        .eq('user_id', _userId)
        .eq('date', formatDateKey(date))
        .maybeSingle();

    if (row == null) {
      return null;
    }
    return DailyReview.fromMap(row);
  }

  Future<List<DailyReview>> listByRange(DateTime start, DateTime end) async {
    final rows = await _client
        .from('daily_reviews')
        .select()
        .eq('user_id', _userId)
        .gte('date', formatDateKey(start))
        .lte('date', formatDateKey(end))
        .order('date');

    return rows.map(DailyReview.fromMap).toList();
  }

  Future<void> save(DailyReviewInput input) {
    return _client
        .from('daily_reviews')
        .upsert(input.toMap(_userId), onConflict: 'user_id,date');
  }
}
