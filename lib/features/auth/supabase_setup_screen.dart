import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class SupabaseSetupScreen extends StatelessWidget {
  const SupabaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Configura SUPABASE_URL e SUPABASE_ANON_KEY com --dart-define para iniciar a aplicacao.',
                    ),
                    const SizedBox(height: 16),
                    const SelectableText(
                      'flutter run --dart-define=SUPABASE_URL=https://...supabase.co --dart-define=SUPABASE_ANON_KEY=...',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
