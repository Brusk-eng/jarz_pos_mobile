import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../data/models/branch_replenishment.dart';
import '../../domain/carton_packing.dart';
import '../../domain/replenishment_draft.dart';
import '../../state/replenishment_providers.dart';

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
                  for (final carton in result.cartons)
                    _CartonCard(carton: carton),
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

class _CartonCard extends StatelessWidget {
  const _CartonCard({required this.carton});

  final Carton carton;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.replenishmentCartonTitle(
                carton.number,
                _typeLabel(l10n, carton.type),
                _fillLabel(l10n, carton),
              ),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            for (final line in carton.lines) Text('${line.name} × ${line.qty}'),
          ],
        ),
      ),
    );
  }
}
