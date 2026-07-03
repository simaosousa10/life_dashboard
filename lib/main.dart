import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'data/services/supabase_service.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/supabase_setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await SupabaseService.initialize();
  }

  runApp(
    ProviderScope(
      child: LifeDashboardApp(
        isSupabaseConfigured: SupabaseConfig.isConfigured,
      ),
    ),
  );
}

class LifeDashboardApp extends StatelessWidget {
  const LifeDashboardApp({required this.isSupabaseConfigured, super.key});

  final bool isSupabaseConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: isSupabaseConfigured
          ? const AuthGate()
          : const SupabaseSetupScreen(),
    );
  }
}
