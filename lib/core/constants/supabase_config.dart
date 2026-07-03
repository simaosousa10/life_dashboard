class SupabaseConfig {
  static const _defaultUrl = 'https://your-project.supabase.co';
  static const _defaultAnonKey = 'your-supabase-anon-key';

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultUrl,
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultAnonKey,
  );

  static bool get isConfigured =>
      url != _defaultUrl && anonKey != _defaultAnonKey;
}
