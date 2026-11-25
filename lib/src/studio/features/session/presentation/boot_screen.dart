import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../shared/studio_async_view.dart';
import '../state/studio_session_notifier.dart';

/// Shown while `session.me` is in flight, and when it could not be reached.
class StudioBootScreen extends ConsumerWidget {
  const StudioBootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(studioSessionProvider);
    final t = StudioStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.appName)),
      body: session.hasError && !session.isLoading
          ? StudioErrorState(
              onRetry: () => ref.read(studioSessionProvider.notifier).reload(),
            )
          : const StudioSkeleton(),
    );
  }
}
