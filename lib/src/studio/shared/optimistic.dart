import 'package:flutter/material.dart';

import '../core/l10n/studio_strings.dart';

/// Optimistic update: take a snapshot, apply the change to local state at
/// once, call the server, and on failure roll back and tell the user.
///
/// Returns true when the server accepted the change. [failureMessage]
/// defaults to the generic "that change was not saved" string.
Future<bool> optimistic<T>({
  required BuildContext context,
  required T Function() snapshot,
  required void Function() apply,
  required void Function(T previous) rollback,
  required Future<void> Function() call,
  String? failureMessage,
}) async {
  // Resolve everything that needs the context before the first await.
  final messenger = ScaffoldMessenger.maybeOf(context);
  final message = failureMessage ?? StudioStrings.of(context).changeFailed;

  final previous = snapshot();
  apply();
  try {
    await call();
    return true;
  } catch (_) {
    rollback(previous);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    return false;
  }
}
