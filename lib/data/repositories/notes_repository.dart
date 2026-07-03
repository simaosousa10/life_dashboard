import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/study_note.dart';
import 'repository_utils.dart';

class NotesRepository {
  const NotesRepository(this._client);

  final SupabaseClient _client;

  String get _userId => requireAuthenticatedUserId(_client);

  Future<List<StudyNote>> list() async {
    final rows = await _client
        .from('study_notes')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return rows.map(StudyNote.fromMap).toList();
  }

  Future<void> create(StudyNoteInput input) {
    return _client.from('study_notes').insert(input.toMap(_userId));
  }

  Future<void> update(String id, StudyNoteInput input) {
    return _client
        .from('study_notes')
        .update(input.toUpdateMap())
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> delete(String id) {
    return _client
        .from('study_notes')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
