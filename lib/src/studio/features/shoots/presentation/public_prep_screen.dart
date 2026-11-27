import '../../../shared/layout/studio_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/person_text.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/studio_error.dart';
import '../data/shoots_repository.dart';
import '../shoots_strings.dart';
import 'shoot_widgets.dart';
import '../../../core/l10n/studio_strings.dart';

/// `/prep/:token`: the read-only prep checklist for people without an
/// account (the kitchen). Arabic first; one button switches to English. A
/// wrong or old link shows a plain message.
class PublicPrepScreen extends ConsumerStatefulWidget {
  const PublicPrepScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<PublicPrepScreen> createState() => _PublicPrepScreenState();
}

class _PublicPrepScreenState extends ConsumerState<PublicPrepScreen> {
  var _arabic = true;

  @override
  Widget build(BuildContext context) {
    final locale = Locale(_arabic ? 'ar' : 'en');
    return Localizations.override(
      context: context,
      locale: locale,
      child: Theme(
        data: buildStudioTheme(locale: locale),
        child: Builder(
          builder: (context) => _Page(
            token: widget.token,
            onSwitch: () => setState(() => _arabic = !_arabic),
            arabic: _arabic,
          ),
        ),
      ),
    );
  }
}

class _Page extends ConsumerWidget {
  const _Page({
    required this.token,
    required this.onSwitch,
    required this.arabic,
  });
  final String token;
  final VoidCallback onSwitch;
  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ShootStrings.of(context);
    final theme = Theme.of(context);
    final value = ref.watch(publicPrepProvider(token));

    return Scaffold(
      key: const ValueKey('public-prep'),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(t.prepPageTitle),
        actions: [
          TextButton(
            key: const ValueKey('prep-lang'),
            onPressed: onSwitch,
            child: Text(arabic ? 'English' : 'عربي'),
          ),
        ],
      ),
      body: StudioPage(
        maxWidth: StudioContentWidth.reading,
        child: value.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Message(
            title: e is StudioRateLimited
                ? t.prepTryAgainLater
                : t.prepBadLinkTitle,
            body: e is StudioRateLimited
                ? null
                : e is StudioNetworkError
                ? t.errNetwork
                : t.prepBadLinkBody,
            onRetry: e is StudioNotFound
                ? null
                : () => ref.invalidate(publicPrepProvider(token)),
          ),
          data: (p) => ShootPage(
            child: ListView(
              padding: const EdgeInsets.all(StudioSpacing.gutter),
              children: [
                PersonText(
                  p.title,
                  key: const ValueKey('prep-title'),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: StudioSpacing.xs),
                Text(
                  [
                    if (p.shootDate != null)
                      t.dateLabel(p.shootDate, p.shootTime),
                    if (p.place != null) p.place!,
                  ].join(' · '),
                  style: theme.textTheme.bodyMedium,
                ),
                if (p.kit != null && p.kit!.isNotEmpty) ...[
                  const SizedBox(height: StudioSpacing.lg),
                  Text(t.prepKit, style: theme.textTheme.titleMedium),
                  const SizedBox(height: StudioSpacing.xs),
                  Text(p.kit!),
                ],
                const SizedBox(height: StudioSpacing.lg),
                Text(t.prepItems, style: theme.textTheme.titleMedium),
                const SizedBox(height: StudioSpacing.xs),
                if (p.items.isEmpty)
                  Text(t.prepNoItems, style: theme.textTheme.bodySmall)
                else
                  Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < p.items.length; i++)
                          ListTile(
                            key: ValueKey('prep-item-$i'),
                            leading: Icon(
                              p.items[i].done
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: p.items[i].done
                                  ? StudioColors.success
                                  : StudioColors.plumMuted,
                            ),
                            title: Text(p.items[i].text),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: StudioSpacing.lg),
                Text(t.prepRead, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, this.body, this.onRetry});
  final String title;
  final String? body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off, size: 40, color: StudioColors.plumMuted),
            const SizedBox(height: StudioSpacing.lg),
            Text(
              title,
              key: const ValueKey('prep-message'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (body != null) ...[
              const SizedBox(height: StudioSpacing.sm),
              Text(body!, textAlign: TextAlign.center),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: StudioSpacing.lg),
              Tooltip(
                message: StudioStrings.of(context).retry,
                child: OutlinedButton(
                  onPressed: onRetry,
                  child: const Icon(Icons.refresh),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
