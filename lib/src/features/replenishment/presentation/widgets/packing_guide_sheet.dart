import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../data/models/branch_replenishment.dart';
import '../../domain/carton_packing.dart';
import '../../domain/replenishment_draft.dart';
import '../../state/replenishment_providers.dart';
import 'done_cartons_section.dart';

/// "3 B2B cartons" / "1 large carton + 2 B2B cartons"; empty when nothing packs.
String cartonCountText(AppLocalizations l10n, PackingResult result) {
  final parts = <String>[
    if (result.largeUsed > 0)
      l10n.replenishmentCartonCountLarge(result.largeUsed),
    if (result.b2bUsed > 0) l10n.replenishmentCartonCountB2b(result.b2bUsed),
  ];
  return parts.join(' + ');
}

String _typeLabel(AppLocalizations l10n, CartonType type) =>
    type == CartonType.large
    ? l10n.replenishmentCartonTypeLarge
    : l10n.replenishmentCartonTypeB2b;

String _fillLabel(AppLocalizations l10n, Carton carton) =>
    carton.fillPercent >= 100
    ? l10n.replenishmentCartonFull
    : l10n.replenishmentCartonPercent(carton.fillPercent);

/// Plain-text version of the guide, for sharing.
String packingGuideText(
  AppLocalizations l10n,
  String branchName,
  PackingResult result,
) {
  final out = StringBuffer(l10n.replenishmentPackingShareHeader(branchName))
    ..writeln()
    ..writeln(
      l10n.replenishmentPackingSummary(result.cartons.length, result.totalJars),
    );
  for (final carton in result.cartons) {
    out
      ..writeln()
      ..writeln(
        l10n.replenishmentCartonTitle(
          carton.number,
          _typeLabel(l10n, carton.type),
          _fillLabel(l10n, carton),
        ),
      );
    for (final line in carton.lines) {
      out.writeln('- ${line.name} × ${line.qty}');
    }
  }
  if (result.unpacked.isNotEmpty) {
    out
      ..writeln()
      ..writeln(l10n.replenishmentPackByHand);
    for (final line in result.unpacked) {
      out.writeln('- ${line.name} × ${line.qty}');
    }
  }
  return out.toString().trimRight();
}

/// Opens the packing guide for [branch] as a tall bottom sheet.
Future<void> showPackingGuide(
  BuildContext context,
  ReplenishmentBranch branch,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PackingGuideSheet(branch: branch),
  );
}

class PackingGuideSheet extends ConsumerWidget {
  const PackingGuideSheet({super.key, required this.branch});

  final ReplenishmentBranch branch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final handProvider = largeCartonsInHandProvider(branch.warehouse);
    final inHand = ref.watch(handProvider);
    final draft = ref.watch(replenishmentDraftProvider);
    final result = packCartons(
      packLinesFor(branch, draft.quantitiesFor(branch)),
      largeInHand: inHand,
    );
    final packedProvider = packedCartonsProvider(branch.warehouse);
    final ticked = ref.watch(packedProvider);
    final keys = [for (final c in result.cartons) cartonPackKey(c)];
    // Only ticks that still match a carton on the current plan count: a tick
    // on a carton whose contents changed is dropped, not carried over.
    final packedCount = keys.where(ticked.contains).length;
    void toggle(String key) {
      final next = {...ticked.where(keys.contains)};
      if (!next.remove(key)) next.add(key);
      ref.read(packedProvider.notifier).state = next;
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.replenishmentPackingGuide} · ${branch.displayName}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.commonClose,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.replenishmentLargeInHand,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    IconButton.outlined(
                      onPressed: inHand > 0
                          ? () => ref.read(handProvider.notifier).state =
                                inHand - 1
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$inHand',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton.outlined(
                      onPressed: () =>
                          ref.read(handProvider.notifier).state = inHand + 1,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                Text(
                  l10n.replenishmentCartonCapacityHint,
                  style: theme.textTheme.bodySmall,
                ),
                const Divider(height: 24),
                if (result.isEmpty)
                  Text(l10n.replenishmentPackingEmpty)
                else ...[
                  Text(
                    l10n.replenishmentPackingSummary(
                      result.cartons.length,
                      result.totalJars,
                    ),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _PackedProgress(
                    packed: packedCount,
                    total: result.cartons.length,
                    onClear: packedCount > 0
                        ? () => ref.read(packedProvider.notifier).state =
                              const <String>{}
                        : null,
                  ),
                  const SizedBox(height: 4),
                  // Still to pack, in order; ticked cartons leave this list.
                  for (var i = 0; i < result.cartons.length; i++)
                    if (!ticked.contains(keys[i]))
                      _CartonCard(
                        key: ValueKey(keys[i]),
                        carton: result.cartons[i],
                        packed: false,
                        onToggle: () => toggle(keys[i]),
                      ),
                  if (result.unpacked.isNotEmpty)
                    Card(
                      color: theme.colorScheme.tertiaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.replenishmentPackByHand,
                              style: theme.textTheme.titleSmall,
                            ),
                            for (final line in result.unpacked)
                              Text('${line.name} × ${line.qty}'),
                          ],
                        ),
                      ),
                    ),
                  DoneCartonsSection(
                    children: [
                      for (var i = 0; i < result.cartons.length; i++)
                        if (ticked.contains(keys[i]))
                          _CartonCard(
                            key: ValueKey(keys[i]),
                            carton: result.cartons[i],
                            packed: true,
                            onToggle: () => toggle(keys[i]),
                          ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: result.isEmpty
                      ? null
                      : () => SharePlus.instance.share(
                          ShareParams(
                            text: packingGuideText(
                              l10n,
                              branch.displayName,
                              result,
                            ),
                          ),
                        ),
                  icon: const Icon(Icons.share),
                  label: Text(l10n.replenishmentPackingShare),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "3 of 7 cartons packed", a bar, and a way to start over.
class _PackedProgress extends StatelessWidget {
  const _PackedProgress({
    required this.packed,
    required this.total,
    required this.onClear,
  });

  final int packed;
  final int total;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final done = total > 0 && packed >= total;
    final doneColor = Colors.green.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.inventory_2_outlined,
              size: 18,
              color: done ? doneColor : theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                done
                    ? l10n.replenishmentCartonsAllPacked
                    : l10n.replenishmentCartonsPackedProgress(packed, total),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: done ? doneColor : null,
                ),
              ),
            ),
            if (onClear != null)
              TextButton(
                onPressed: onClear,
                child: Text(l10n.replenishmentCartonsClearPacked),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : packed / total,
            minHeight: 6,
            color: done ? doneColor : null,
          ),
        ),
      ],
    );
  }
}

/// One carton. Tapping anywhere on it (or its box) ticks it off as packed;
/// a packed carton dims so the eye goes to the next one still to fill.
class _CartonCard extends StatelessWidget {
  const _CartonCard({
    super.key,
    required this.carton,
    required this.packed,
    required this.onToggle,
  });

  final Carton carton;
  final bool packed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: packed ? theme.colorScheme.surfaceContainerHighest : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: packed,
                onChanged: (_) => onToggle(),
                semanticLabel: l10n.replenishmentCartonPackedToggle,
              ),
              Expanded(
                child: Opacity(
                  opacity: packed ? 0.55 : 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.replenishmentCartonTitle(
                            carton.number,
                            _typeLabel(l10n, carton.type),
                            _fillLabel(l10n, carton),
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            decoration: packed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final line in carton.lines)
                          Text('${line.name} × ${line.qty}'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
