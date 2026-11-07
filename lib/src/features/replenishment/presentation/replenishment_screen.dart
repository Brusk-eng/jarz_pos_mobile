import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/user_error_message.dart';
import '../../../core/network/user_service.dart';
import '../../../core/widgets/app_drawer.dart';
import '../data/models/branch_replenishment.dart';
import '../domain/carton_packing.dart';
import '../domain/replenishment_draft.dart';
import '../state/replenishment_providers.dart';
import 'widgets/branch_moves_card.dart';
import 'widgets/packing_guide_sheet.dart';
import 'widgets/replenishment_format.dart';
import 'widgets/replenishment_item_row.dart';

/// What the factory should put on the van for one branch, and the button that
/// puts it there.
///
/// One branch at a time on purpose. The decision this screen supports is "load
/// this van, for this shop, now" — a combined board of all three branches reads
/// as a report, and a report is what everybody had before and nobody acted on.
class ReplenishmentScreen extends ConsumerWidget {
  const ReplenishmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final roles = ref.watch(userRolesFutureProvider);
    final canPlanProduction = ref.watch(canAccessProductionBoardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.replenishmentTitle),
        actions: [
          // The sibling screen: this one says what to SEND, Production Round
          // says what to MAKE so there is something to send. Offered only to
          // the roles its endpoint accepts.
          if (canPlanProduction)
            IconButton(
              tooltip: l10n.productionRoundOpenFromSend,
              icon: const Icon(Icons.event_repeat),
              onPressed: () => context.go(AppRoutes.productionRound),
            ),
          IconButton(
            tooltip: l10n.replenishmentRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(replenishmentDraftProvider.notifier).resetAndReload(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: roles.when(
        // While the roles are still in flight the answer is "not yet", not
        // "not permitted" — flashing a refusal at a manager is worse than a
        // spinner.
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(text: l10n.replenishmentNotAllowed),
        data: (data) => data.canAccessStockTransfer
            ? const _ReplenishmentBody()
            : _Message(text: l10n.replenishmentNotAllowed),
      ),
    );
  }
}

class _ReplenishmentBody extends ConsumerWidget {
  const _ReplenishmentBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final planAsync = ref.watch(replenishmentPlanProvider);
    final plan = planAsync.valueOrNull;

    if (plan == null && planAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (plan == null) {
      return _Message(
        text: l10n.replenishmentLoadFailed,
        detail: context.userErrorMessage(planAsync.error),
        onRetry: () =>
            ref.read(replenishmentDraftProvider.notifier).resetAndReload(),
        retryLabel: l10n.commonRetry,
      );
    }

    return Column(
      children: [
        if (planAsync.isLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _PlanView(plan: plan)),
      ],
    );
  }
}

class _PlanView extends ConsumerWidget {
  const _PlanView({required this.plan});

  final ReplenishmentPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    if (!plan.hasBranches) {
      // An empty run always has a reason, and the server sends it. Rendering a
      // bare empty list here is what teaches people the screen is broken.
      return _Message(
        text: l10n.replenishmentEmptyTitle,
        detail: (plan.notice ?? '').trim().isNotEmpty
            ? plan.notice!.trim()
            : l10n.replenishmentEmptyNoBranches,
      );
    }

    final picked = ref.watch(selectedBranchWarehouseProvider);
    final branch =
        plan.branchFor(picked) ??
        plan.branchFor(defaultBranchWarehouse(plan)) ??
        plan.branches.first;
    final draft = ref.watch(replenishmentDraftProvider);

    return Center(
      child: ConstrainedBox(
        // Tablets: the rows are short, and a full-width 1000 dp line would put
        // the quantity box a hand width away from the item it belongs to.
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlanHeader(plan: plan),
                  const SizedBox(height: 10),
                  _BranchSelector(plan: plan, selected: branch),
                ],
              ),
            ),
            if (draft.result != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: _SendResultCard(result: draft.result!),
              ),
            if (plan.movesInto(branch.warehouse).isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: BranchMovesCard(
                  branch: branch,
                  moves: plan.movesInto(branch.warehouse),
                ),
              ),
            Expanded(
              child: branch.items.isEmpty
                  ? _Message(
                      text: l10n.replenishmentEmptyTitle,
                      detail: l10n.replenishmentBranchCovered(
                        branch.displayName,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      itemCount: branch.items.length,
                      itemBuilder: (context, index) {
                        final item = branch.items[index];
                        return ReplenishmentItemRow(
                          // The generation is part of the key so a refresh (or
                          // a completed send) rebuilds the field from the new
                          // plan instead of keeping a stale typed number.
                          key: ValueKey(
                            '${branch.warehouse}|${item.itemCode}|${draft.generation}',
                          ),
                          item: item,
                          initialQty: draft.qtyFor(branch.warehouse, item),
                          enabled: !draft.sending,
                          flagged:
                              draft.result?.success == false &&
                              draft.result?.failedItemName == item.displayName,
                          onQtyChanged: (qty) => ref
                              .read(replenishmentDraftProvider.notifier)
                              .setQty(branch.warehouse, item.itemCode, qty),
                        );
                      },
                    ),
            ),
            _SendBar(plan: plan, branch: branch),
          ],
        ),
      ),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.plan});

  final ReplenishmentPlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summary = plan.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.replenishmentSourceLine(isolateLtr(plan.source.warehouse)),
          style: theme.textTheme.titleSmall,
        ),
        Text(
          l10n.replenishmentBasis(plan.coverDays, plan.salesDays),
          style: theme.textTheme.bodySmall,
        ),
        // How fresh the figures are. Shown because the answer moves with the
        // day's sales, and somebody deciding a van load needs to know whether
        // they are reading this morning or last Thursday.
        if (plan.generatedOn.trim().isNotEmpty)
          Text(
            l10n.replenishmentGeneratedOn(isolateLtr(plan.generatedOn.trim())),
            style: theme.textTheme.bodySmall,
          ),
        if (summary.negativeBins > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.replenishmentNegativeBinsCount(summary.negativeBins),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        // The company-wide shortfall is the owner's number, not the van
        // loader's: it is the one figure on the screen that says "produce
        // more" rather than "move stock".
        if (summary.totalShortBy > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.replenishmentTotalShort(trimQty(summary.totalShortBy)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _BranchSelector extends ConsumerWidget {
  const _BranchSelector({required this.plan, required this.selected});

  final ReplenishmentPlan plan;
  final ReplenishmentBranch selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DropdownButtonFormField<String>(
      initialValue: selected.warehouse,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.replenishmentBranchLabel,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final branch in plan.branches)
          DropdownMenuItem(
            value: branch.warehouse,
            child: Text(
              // The headline is in the option itself: picking a branch is a
              // triage decision, and a bare list of names does not say which
              // one is bleeding.
              l10n.replenishmentBranchOption(
                branch.displayName,
                branch.summary.itemsBelowCover,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        ref.read(selectedBranchWarehouseProvider.notifier).state = value;
        ref.read(replenishmentDraftProvider.notifier).clearResult();
      },
    );
  }
}

class _SendResultCard extends ConsumerWidget {
  const _SendResultCard({required this.result});

  final ReplenishmentSendResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final ok = result.success;

    return Card(
      margin: EdgeInsets.zero,
      color: ok
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              ok ? Icons.local_shipping : Icons.error_outline,
              color: ok
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ok
                    ? [
                        Text(
                          l10n.replenishmentSentTitle(result.branchLabel),
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          // A branch-bound send is a pending handover now:
                          // nothing has moved until the branch confirms, so
                          // naming a Stock Entry would be a lie.
                          result.pending
                              ? l10n.replenishmentSentPendingBody(
                                  result.lineCount,
                                  trimQty(result.totalQty),
                                  result.branchLabel,
                                  isolateLtr(result.handover),
                                )
                              : l10n.replenishmentSentBody(
                                  result.lineCount,
                                  trimQty(result.totalQty),
                                  isolateLtr(result.stockEntry),
                                ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ]
                    : [
                        Text(
                          l10n.replenishmentSendFailed(
                            result.branchLabel,
                            context.userErrorMessage(result.error),
                          ),
                          style: theme.textTheme.titleSmall,
                        ),
                        if (result.failedItemName != null)
                          Text(
                            l10n.replenishmentFailedLine(
                              result.failedItemName!,
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                        Text(
                          l10n.replenishmentNumbersKept,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
              ),
            ),
            IconButton(
              tooltip: l10n.commonClose,
              icon: const Icon(Icons.close, size: 18),
              onPressed: () =>
                  ref.read(replenishmentDraftProvider.notifier).clearResult(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendBar extends ConsumerWidget {
  const _SendBar({required this.plan, required this.branch});

  final ReplenishmentPlan plan;
  final ReplenishmentBranch branch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final draft = ref.watch(replenishmentDraftProvider);
    final totals = totalsFor(branch, draft.quantitiesFor(branch));
    final canSend =
        !draft.sending && !totals.isEmpty && plan.source.warehouse.isNotEmpty;
    final packing = packCartons(
      packLinesFor(branch, draft.quantitiesFor(branch)),
      largeInHand: ref.watch(largeCartonsInHandProvider(branch.warehouse)),
    );
    final cartonsText = cartonCountText(l10n, packing);

    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          // Stacked, not side by side: the action carries the branch name, so
          // at 360 dp a Row lets the button take the whole width and squeezes
          // the total into a one-character-per-line column. The button is
          // full-width here on every size, which is also the bigger target for
          // somebody holding a tablet in one hand.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // What the branch needs, then what is actually typed. Both, in
              // that order: the gap between them is the decision the person
              // loading the van just made, and it should be visible while they
              // are making it.
              Text(
                l10n.replenishmentBelowCoverCount(
                  branch.summary.itemsBelowCover,
                ),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                l10n.replenishmentTypedTotal(
                  totals.lineCount,
                  trimQty(totals.totalQty),
                ),
                style: theme.textTheme.bodyMedium,
              ),
              if (!totals.isEmpty)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cartonsText.isEmpty
                            ? ''
                            : l10n.replenishmentCartonsBar(cartonsText),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => showPackingGuide(context, branch),
                      child: Text(l10n.replenishmentPackingGuide),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: canSend ? () => _send(context, ref) : null,
                icon: draft.sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.local_shipping),
                label: Text(
                  l10n.replenishmentSendAction(branch.displayName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(replenishmentDraftProvider.notifier);
    final totals = totalsFor(
      branch,
      ref.read(replenishmentDraftProvider).quantitiesFor(branch),
    );
    if (totals.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.replenishmentNothingToSend)),
      );
      return;
    }

    final cartonsText = cartonCountText(
      l10n,
      packCartons(
        packLinesFor(
          branch,
          ref.read(replenishmentDraftProvider).quantitiesFor(branch),
        ),
        largeInHand: ref.read(largeCartonsInHandProvider(branch.warehouse)),
      ),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.replenishmentConfirmTitle(branch.displayName)),
        content: Text(
          [
            l10n.replenishmentConfirmBody(
              totals.lineCount,
              trimQty(totals.totalQty),
              isolateLtr(plan.source.warehouse),
            ),
            if (cartonsText.isNotEmpty)
              l10n.replenishmentCartonsConfirmLine(cartonsText),
          ].join('\n\n'),
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

    final sent = await notifier.send(
      branch: branch,
      sourceWarehouse: plan.source.warehouse,
    );
    if (!sent) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.replenishmentSentTitle(branch.displayName))),
    );
  }
}

/// The one shape every non-list state on this screen takes: a headline and,
/// always, the reason underneath it.
class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    this.detail,
    this.onRetry,
    this.retryLabel,
  });

  final String text;
  final String? detail;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onRetry, child: Text(retryLabel ?? '')),
            ],
          ],
        ),
      ),
    );
  }
}
