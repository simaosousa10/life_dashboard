import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import 'repository_utils.dart';

class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  String get _userId => requireAuthenticatedUserId(_client);

  Future<UserProfile?> getProfile() async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return UserProfile.fromMap(row);
  }

  Future<void> save(UserProfileInput input) {
    return _client
        .from('profiles')
        .upsert(input.toMap(_userId), onConflict: 'user_id');
  }
}
