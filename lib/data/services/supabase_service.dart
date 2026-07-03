import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/supabase_config.dart';

class SupabaseService {
  static Future<void> initialize() {
    return Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );
  }
}
