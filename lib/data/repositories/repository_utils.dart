import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_error.dart';

String requireAuthenticatedUserId(SupabaseClient client) {
  final user = client.auth.currentUser;
  if (user == null) {
    throw const AppUserMessageException(
      'A sessao expirou. Volta a entrar para continuar.',
    );
  }
  return user.id;
}
