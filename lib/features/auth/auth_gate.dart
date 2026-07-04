import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_error.dart';
import '../../core/widgets/error_state.dart';
import '../../providers/app_providers.dart';
import '../main_shell.dart';
import '../onboarding/onboarding_screen.dart';
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
      final profile = ref.watch(userProfileProvider);
      return profile.when(
        data: (data) =>
            data == null ? const OnboardingScreen() : const MainShell(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(
          body: ErrorState(
            message: friendlyErrorMessage(error),
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
        ),
      );
    }

    return authState.when(
      data: (_) => const AuthScreen(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const AuthScreen(),
    );
  }
}
