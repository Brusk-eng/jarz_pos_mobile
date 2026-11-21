import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/models/chat_flavour_models.dart';
import '../../state/chat_flavour_providers.dart';
import '../chat_labels.dart';

/// Flavour availability for the AI chat drafts. The drafts hide a flavour
/// when stock is under `min_stock` jars; stock lags reality, so a moderator
/// can force a flavour Available or Paused, or set it back to Auto.
///
/// Opened from the inbox app bar with a plain `MaterialPageRoute` (no
/// GoRouter entry), so the feature stays a Dart-only Shorebird patch.
class ChatFlavourAvailabilityScreen extends ConsumerWidget {
  const ChatFlavourAvailabilityScreen({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    builder: (_) => const ChatFlavourAvailabilityScreen(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(chatFlavourAvailabilityProvider);
    final notifier = ref.read(chatFlavourAvailabilityProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(chatBi(context, 'Flavour availability', 'النكهات المتاحة')),
        actions: [
          IconButton(
            tooltip: l10n.commonRetry,
            icon: const Icon(Icons.refresh),
            onPressed: () => unawaited(notifier.refresh()),
          ),
        ],
      ),
      body: Column(
        children: [
          if (async.isLoading && async.hasValue)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: async.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        context.userErrorMessage(
                          e,
                          fallback: l10n.chatInboxLoadError,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => unawaited(notifier.refresh()),
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (page) => RefreshIndicator(
                onRefresh: notifier.refresh,
                child: ListView(
                  key: const ValueKey('chat-flavours-list'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _Header(minStock: page.minStock),
                    if (page.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            chatBi(
                              context,
                              'No flavours found.',
                              'مفيش نكهات.',
                            ),
                          ),
                        ),
                      ),
                    for (final group in page.bySize) ...[
                      _SizeHeader(rows: group.value),
                      for (final row in group.value)
                        _FlavourTile(key: ValueKey(row.itemCode), row: row),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.minStock});

  final int minStock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = formatCount(context, minStock);
    return Container(
      key: const ValueKey('chat-flavours-header'),
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              chatBi(
                context,
                'The AI replies pause a flavour when stock is under $count '
                    'jars. If the flavour is really there (on the way, or in '
                    "the branch but not moved in the system yet), set it to "
                    'Available.',
                'النكهة بتتوقف في ردود الـ AI لما المخزون يقل عن $count. '
                    'لو النكهة موجودة فعلًا (في الطريق أو في الفرع ولسه '
                    'ماتنقلتش على السيستم) خليها متاح.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeHeader extends StatelessWidget {
  const _SizeHeader({required this.rows});

  final List<ChatFlavourAvailability> rows;

  @override
  Widget build(BuildContext context) {
    final first = rows.first;
    final label = chatBi(
      context,
      first.size.isNotEmpty ? first.size : first.sizeAr,
      first.sizeAr.isNotEmpty ? first.sizeAr : first.size,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
      child: Text(
        label.isEmpty ? '—' : label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _availabilityLabel(BuildContext context, String value) =>
    switch (value) {
      ChatFlavourAvailabilityValues.available => chatBi(
        context,
        'Available',
        'متاح',
      ),
      ChatFlavourAvailabilityValues.paused => chatBi(
        context,
        'Paused',
        'متوقف',
      ),
      _ => chatBi(context, 'Auto', 'تلقائي'),
    };

String _stockLabel(BuildContext context, double? stock) {
  if (stock == null) return '—';
  final count = formatCount(
    context,
    stock == stock.roundToDouble() ? stock.toInt() : stock,
  );
  return chatBi(context, '$count jars', '$count برطمان');
}

class _FlavourTile extends ConsumerWidget {
  const _FlavourTile({super.key, required this.row});

  final ChatFlavourAvailability row;

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    String availability,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final fallback = chatBi(
      context,
      'Could not save. Try again.',
      'ماتحفظش. جرّب تاني.',
    );
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(chatFlavourAvailabilityProvider.notifier)
          .setAvailability(row.itemCode, availability);
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(userErrorMessageFor(l10n, e, fallback: fallback)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = chatBi(
      context,
      row.name.isNotEmpty ? row.name : row.nameAr,
      row.nameAr.isNotEmpty ? row.nameAr : row.name,
    );
    final available = row.isAvailable;
    final chipColor = available ? Colors.green.shade700 : Colors.grey.shade600;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? row.itemCode : name,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _stockLabel(context, row.stock),
                        key: ValueKey('flavour-stock-${row.itemCode}'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  key: ValueKey('flavour-status-${row.itemCode}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: chipColor),
                  ),
                  child: Text(
                    _availabilityLabel(context, row.effective),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: chipColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              key: ValueKey('flavour-choice-${row.itemCode}'),
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                for (final value in ChatFlavourAvailabilityValues.choices)
                  ButtonSegment<String>(
                    value: value,
                    label: Text(
                      _availabilityLabel(context, value),
                      key: ValueKey('flavour-choice-${row.itemCode}-$value'),
                    ),
                  ),
              ],
              selected: {row.override},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) return;
                unawaited(_set(context, ref, selection.first));
              },
            ),
            if (row.isManual) ...[
              const SizedBox(height: 6),
              Text(
                chatBi(
                  context,
                  'Set by hand — stock says: '
                      '${_availabilityLabel(context, row.auto)}',
                  'تم التعديل يدويًا — المخزون يقول: '
                      '${_availabilityLabel(context, row.auto)}',
                ),
                key: ValueKey('flavour-manual-${row.itemCode}'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
