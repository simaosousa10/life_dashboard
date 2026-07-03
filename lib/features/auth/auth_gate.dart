import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../main_shell.dart';
import 'auth_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateProvider, (previous, next) {
      final user = next.valueOrNull?.session?.user;
      if (next.hasValue && user == null) {
        invalidateUserScopedData(ref);
      }
    });

    final authState = ref.watch(authStateProvider);
    final user = ref.watch(currentUserProvider);

    if (user != null) {
      return const MainShell();
    }

    return authState.when(
      data: (_) => const AuthScreen(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const AuthScreen(),
    );
  }
}
