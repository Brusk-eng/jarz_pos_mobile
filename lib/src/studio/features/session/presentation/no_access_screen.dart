import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/studio_config.dart';
import '../../../core/l10n/studio_strings.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../shared/language_switch.dart';
import '../state/studio_session_notifier.dart';

/// A signed-in user who holds no Studio role.
class StudioNoAccessScreen extends ConsumerWidget {
  const StudioNoAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = StudioStrings.of(context);
    final theme = Theme.of(context);
    final fake = ref.watch(studioFakeProvider);
    return Scaffold(
      appBar: AppBar(actions: const [LanguageSwitchButton()]),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(StudioSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: StudioColors.berryPink,
                ),
                const SizedBox(height: StudioSpacing.lg),
                Text(
                  t.noAccessTitle,
                  key: const ValueKey('no-access-title'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: StudioSpacing.md),
                Text(
                  t.noAccessBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                if (!fake) ...[
                  const SizedBox(height: StudioSpacing.xl),
                  OutlinedButton(
                    key: const ValueKey('sign-out'),
                    onPressed: () =>
                        ref.read(studioSessionProvider.notifier).signOut(),
                    child: Text(t.signOut),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
