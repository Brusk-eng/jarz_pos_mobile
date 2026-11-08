import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/models/branch_replenishment.dart';
import '../../state/replenishment_providers.dart';
import 'replenishment_format.dart';

/// The factory cannot cover everything, but other branches can help.
///
/// Suggestions only: nothing moves until the person presses a request button,
/// and even then stock only moves once the receiving branch confirms it got
/// the jars. A move already requested drops out of the plan until then.
class BranchMovesCard extends ConsumerWidget {
  const BranchMovesCard({super.key, required this.branch, required this.moves});

  final ReplenishmentBranch branch;
  final List<ReplenishmentBranchMove> moves;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sending = ref.watch(
      replenishmentDraftProvider.select((d) => d.sending),
    );

    // One group per source branch, keeping the server's order.
    final groups = <String, List<ReplenishmentBranchMove>>{};
    for (final move in moves) {
      groups.putIfAbsent(move.fromWarehouse, () => []).add(move);
    }

    final total = moves.fold<double>(0, (sum, m) => sum + m.qty.toDouble());

    // Collapsed by default: this is the exception, not the job, and an open
    // card here pushes the item list off a phone screen.
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.tertiaryContainer,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: AlignmentDirectional.centerStart,
          leading: const Icon(Icons.swap_horiz, size: 20),
          title: Text(
            l10n.replenishmentMovesSummary(trimQty(total)),
            style: theme.textTheme.titleSmall,
          ),
          children: [
            Text(
              l10n.replenishmentMovesTitle,
              style: theme.textTheme.bodySmall,
            ),
            for (final entry in groups.entries) ...[
              const SizedBox(height: 8),
              Text(
                l10n.replenishmentMovesFrom(
                  entry.value.first.displayFrom,
                  _itemsText(entry.value),
                ),
                style: theme.textTheme.bodyMedium,
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton(
                  onPressed: sending
                      ? null
                      : () => _request(context, ref, entry.value),
                  child: Text(
                    l10n.replenishmentMovesRequest(
                      entry.value.first.displayFrom,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _itemsText(List<ReplenishmentBranchMove> moves) =>
      moves.map((m) => '${m.displayName} × ${m.qty}').join(', ');

  Future<void> _request(
    BuildContext context,
    WidgetRef ref,
    List<ReplenishmentBranchMove> group,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(replenishmentDraftProvider.notifier);
    final from = group.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.replenishmentMovesConfirmTitle(from.displayFrom)),
        content: Text(
          l10n.replenishmentMovesConfirmBody(
            from.displayFrom,
            _itemsText(group),
            branch.displayName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.replenishmentConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await notifier.requestMove(
      fromWarehouse: from.fromWarehouse,
      targetWarehouse: branch.warehouse,
      lines: [
        for (final m in group) {'item_code': m.itemCode, 'qty': m.qty},
      ],
    );
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? l10n.replenishmentMovesSent(from.displayFrom)
              : l10n.replenishmentMovesFailed(
                  from.displayFrom,
                  context.userErrorMessage(error),
                ),
        ),
      ),
    );
  }
}
