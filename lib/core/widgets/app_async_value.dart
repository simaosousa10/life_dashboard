import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_error.dart';
import 'error_state.dart';

class AppAsyncValue<T> extends StatelessWidget {
  const AppAsyncValue({
    required this.value,
    required this.builder,
    this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorState(message: friendlyErrorMessage(error), onRetry: onRetry),
    );
  }
}
