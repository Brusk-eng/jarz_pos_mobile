import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/studio_api.dart';
import '../../core/roles/studio_role.dart';
import '../../core/theme/studio_tokens.dart';
import '../session/state/studio_session_notifier.dart';
import 'walkthrough_strings.dart';

/// Opens the walkthrough for [role]: three or four cards, skippable. Returns
/// when the person finishes or skips.
Future<void> showWalkthrough(BuildContext context, StudioRole role) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WalkthroughDialog(role: role),
    );

class _WalkthroughDialog extends StatefulWidget {
  const _WalkthroughDialog({required this.role});
  final StudioRole role;

  @override
  State<_WalkthroughDialog> createState() => _WalkthroughDialogState();
}

class _WalkthroughDialogState extends State<_WalkthroughDialog> {
  final _pages = PageController();
  var _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = WalkthroughStrings.of(context);
    final theme = Theme.of(context);
    final cards = t.cards(widget.role);
    final last = _index == cards.length - 1;
    return Dialog(
      key: const ValueKey('walkthrough'),
      insetPadding: const EdgeInsets.all(StudioSpacing.gutter),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 460),
        child: Padding(
          padding: const EdgeInsets.all(StudioSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: PageView(
                  key: const ValueKey('walkthrough-pages'),
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    for (final c in cards)
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(c.icon, size: 40, color: StudioColors.berryPink),
                            const SizedBox(height: StudioSpacing.md),
                            Text(c.title, style: theme.textTheme.headlineSmall),
                            const SizedBox(height: StudioSpacing.sm),
                            Text(c.body, style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: StudioSpacing.md),
              Text(
                t.step(_index + 1, cards.length),
                key: const ValueKey('walkthrough-step'),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: StudioSpacing.sm),
              Row(
                children: [
                  if (!last)
                    TextButton(
                      key: const ValueKey('walkthrough-skip'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(t.skip),
                    ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey('walkthrough-next'),
                    onPressed: last
                        ? () => Navigator.of(context).pop()
                        : () => _pages.nextPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          ),
                    child: Text(last ? t.done : t.next),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps the signed-in app: the first time a person opens it, their role's
/// walkthrough shows once, and `session.help_seen` remembers that it did (so
/// it does not come back on another device). Skipping counts as seen.
class FirstLoginWalkthrough extends ConsumerStatefulWidget {
  const FirstLoginWalkthrough({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<FirstLoginWalkthrough> createState() =>
      _FirstLoginWalkthroughState();
}

class _FirstLoginWalkthroughState extends ConsumerState<FirstLoginWalkthrough> {
  var _asked = false;

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(studioSessionProvider).valueOrNull;
    final role = me?.primaryRole;
    if (!_asked && me != null && role != null) {
      final key = WalkthroughStrings.keyFor(role);
      if (!me.seenHelp.contains(key)) {
        _asked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await showWalkthrough(context, role);
          try {
            await ref.read(studioApiProvider).sessionHelpSeen(key: key);
            ref.read(studioSessionProvider.notifier).markHelpSeen(key);
          } catch (_) {
            // Not saved: it shows again next time, which is harmless.
          }
        });
      }
    }
    return widget.child;
  }
}
