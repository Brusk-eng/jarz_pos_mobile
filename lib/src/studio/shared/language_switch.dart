import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/studio_locale.dart';
import '../core/l10n/studio_strings.dart';

/// App-bar button that flips the Studio between English and Arabic. The label
/// shows the language it will switch to.
class LanguageSwitchButton extends ConsumerWidget {
  const LanguageSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = StudioStrings.of(context);
    return TextButton(
      key: const ValueKey('lang-switch'),
      onPressed: () {
        final current = ref.read(studioLocaleProvider);
        ref
            .read(studioLocaleProvider.notifier)
            .state = current.languageCode == 'ar'
            ? const Locale('en')
            : const Locale('ar');
      },
      child: Tooltip(
        message: t.languageSwitchLabel,
        child: Text(t.languageSwitchTarget),
      ),
    );
  }
}
