import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/models/branch_replenishment.dart';
import '../../state/replenishment_providers.dart';

/// The factory cannot cover everything, but other branches can help.
///
/// Suggestions only: nothing moves until the person presses a request button,
/// and even then stock only moves once the receiving branch confirms it got
/// the jars. A move already requested drops out of the plan until then.
class BranchMovesCard extends ConsumerWidget {
  const BranchMovesCard({
    super.key,
    required this.branch,
    required this.moves,
  });

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

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.replenishmentMovesTitle,
              style: theme.textTheme.titleSmall,
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
