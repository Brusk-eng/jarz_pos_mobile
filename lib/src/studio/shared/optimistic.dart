import 'package:flutter/material.dart';

import '../core/l10n/studio_strings.dart';
import '../data/optimistic_write.dart';
import 'studio_toast.dart';

/// Optimistic update: take a snapshot, apply the change to local state at
/// once, call the server, and on failure roll back and tell the user.
///
/// Returns true when the server accepted the change. [failureMessage]
/// defaults to the generic "that change was not saved" string. Notifiers use
/// the context-free [runOptimistic] directly.
Future<bool> optimistic<T>({
  required BuildContext context,
  required T Function() snapshot,
  required void Function() apply,
  required void Function(T previous) rollback,
  required Future<void> Function() call,
  String? failureMessage,
}) async {
  // Resolve everything that needs the context before the first await.
  final message = failureMessage ?? StudioStrings.of(context).changeFailed;

  try {
    await runOptimistic<T, void>(
      snapshot: snapshot,
      apply: apply,
      rollback: rollback,
      call: call,
    );
    return true;
  } catch (_) {
    showStudioToast(message);
    return false;
  }
}
