import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/calendar_event.dart';
import 'repository_utils.dart';

class CalendarRepository {
  const CalendarRepository(this._client);

  final SupabaseClient _client;

  String get _userId => requireAuthenticatedUserId(_client);

  Future<List<CalendarEvent>> list() async {
    final rows = await _client
        .from('calendar_events')
        .select()
        .eq('user_id', _userId)
        .order('event_date')
        .order('start_time', nullsFirst: true);

    return rows.map(CalendarEvent.fromMap).toList();
  }

  Future<List<CalendarEvent>> upcoming({int limit = 5}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    final rows = await _client
        .from('calendar_events')
        .select()
        .eq('user_id', _userId)
        .gte('event_date', today.substring(0, 10))
        .order('event_date')
        .order('start_time', nullsFirst: true)
        .limit(limit);

    return rows.map(CalendarEvent.fromMap).toList();
  }

  Future<void> create(CalendarEventInput input) {
    return _client.from('calendar_events').insert(input.toMap(_userId));
  }

  Future<void> update(String id, CalendarEventInput input) {
    return _client
        .from('calendar_events')
        .update(input.toUpdateMap())
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> delete(String id) {
    return _client
        .from('calendar_events')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
