import 'package:flutter/material.dart';

import '../utils/app_error.dart';

void showErrorSnackBar(BuildContext context, Object error) {
  final colorScheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(friendlyErrorMessage(error)),
      backgroundColor: colorScheme.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}
