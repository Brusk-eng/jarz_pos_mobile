import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/localized_formatters.dart';
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
        Expanded(
          child: plan.hasBranches
              ? _PlanView(
                  key: ValueKey(
                    plan.branches.map((b) => b.warehouse).join('|'),
                  ),
                  plan: plan,
                )
              : _Message(
                  text: l10n.replenishmentEmptyTitle,
                  detail: (plan.notice ?? '').trim().isNotEmpty
                      ? plan.notice!.trim()
                      : l10n.replenishmentEmptyNoBranches,
                ),
        ),
      ],
    );
  }
}

class _PlanView extends ConsumerStatefulWidget {
  const _PlanView({super.key, required this.plan});

  final ReplenishmentPlan plan;

  @override
  ConsumerState<_PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends ConsumerState<_PlanView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late int _shownIndex;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    final picked = ref.read(selectedBranchWarehouseProvider);
    final start =
        plan.branchFor(picked) ??
        plan.branchFor(defaultBranchWarehouse(plan)) ??
        plan.branches.first;
    _shownIndex = plan.branches.indexWhere(
      (b) => b.warehouse == start.warehouse,
    );
    if (_shownIndex < 0) _shownIndex = 0;
    _tab = TabController(
      length: plan.branches.length,
      initialIndex: _shownIndex,
      vsync: this,
    );
    _tab.addListener(_onTab);
  }

  void _onTab() {
    if (_tab.index == _shownIndex) return;
    // Tap and swipe both land here. Each branch keeps its own draft in the
    // provider, so changing the page only changes which one is on show.
    setState(() => _shownIndex = _tab.index);
    ref.read(selectedBranchWarehouseProvider.notifier).state =
        widget.plan.branches[_tab.index].warehouse;
    ref.read(replenishmentDraftProvider.notifier).clearResult();
  }

  @override
  void dispose() {
    _tab.removeListener(_onTab);
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plan = widget.plan;
    final draft = ref.watch(replenishmentDraftProvider);
    final branch =
        plan.branches[_shownIndex.clamp(0, plan.branches.length - 1)];
    final moves = plan.movesInto(branch.warehouse);

    return Center(
      child: ConstrainedBox(
        // Tablets: the rows are short, and a full-width 1000 dp line would put
        // the quantity box a hand width away from the item it belongs to.
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            // Pinned: branches are the one control that must stay reachable
            // however far the list has been scrolled.
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                controller: _tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  for (final b in plan.branches)
                    Tab(
                      height: 40,
                      text: l10n.replenishmentTabLabel(
                        b.displayName,
                        b.summary.itemsBelowCover,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: NestedScrollView(
                // One scroll for the page: the header slides away with the
                // list instead of holding a third of the screen.
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PlanHeader(plan: plan),
                          if (draft.result != null) ...[
                            const SizedBox(height: 8),
                            _SendResultCard(result: draft.result!),
                          ],
                          if (moves.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            BranchMovesCard(branch: branch, moves: moves),
                          ],
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tab,
                  children: [
                    for (final b in plan.branches) _BranchList(branch: b),
                  ],
                ),
              ),
            ),
            _SendBar(plan: plan, branch: branch),
          ],
        ),
      ),
    );
  }
}

/// The scrolling item list for one branch: one page of the swipeable body.
///
/// Split into three groups so the van loader reads only what moves:
/// - **To send**: rows the plan puts a quantity on. Open.
/// - **Nothing to send**: the rest, collapsed. Still editable once opened, for
///   the odd extra jar typed by hand.
/// - **Small jars**: collapsed in a section of their own whatever their
///   quantity. Small was a one-off line (owner, 2026-11-13), kept reachable but
///   out of the way. Its header warns when any small row is still set to go,
///   because a hidden row that ships would be worse than a cluttered list.
///
/// Grouping reads the PLAN's `send_now`, not the typed figure, so a row never
/// jumps sections (and loses its keyboard) while someone is typing into it.
class _BranchList extends ConsumerStatefulWidget {
  const _BranchList({required this.branch});

  final ReplenishmentBranch branch;

  @override
  ConsumerState<_BranchList> createState() => _BranchListState();
}

class _BranchListState extends ConsumerState<_BranchList> {
  bool _showIdle = false;
  bool _showSmall = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final branch = widget.branch;
    final draft = ref.watch(replenishmentDraftProvider);

    final toSend = <ReplenishmentItem>[];
    final idle = <ReplenishmentItem>[];
    final small = <ReplenishmentItem>[];
    for (final item in branch.items) {
      if (item.jarSize.toLowerCase() == 'small') {
        small.add(item);
      } else if (item.sendNow > 0) {
        toSend.add(item);
      } else {
        idle.add(item);
      }
    }
    final smallTyped = small.fold<double>(
      0,
      (sum, item) => sum + draft.qtyFor(branch.warehouse, item),
    );

    final entries = <Widget Function()>[
      () => _GroupHeader(
        title: l10n.replenishmentGroupToSend(toSend.length),
        icon: Icons.local_shipping_outlined,
      ),
      if (toSend.isEmpty)
        () => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            l10n.replenishmentBranchCovered(branch.displayName),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      for (final item in toSend) () => _row(item, draft),
      if (idle.isNotEmpty)
        () => _GroupHeader(
          title: l10n.replenishmentGroupNothing(idle.length),
          icon: Icons.inventory_2_outlined,
          expanded: _showIdle,
          onTap: () => setState(() => _showIdle = !_showIdle),
        ),
      if (_showIdle)
        for (final item in idle) () => _row(item, draft),
      if (small.isNotEmpty)
        () => _GroupHeader(
          title: l10n.replenishmentGroupSmall(small.length),
          subtitle: smallTyped > 0
              ? l10n.replenishmentGroupSmallSending(trimQty(smallTyped))
              : l10n.replenishmentGroupSmallHint,
          warn: smallTyped > 0,
          icon: Icons.visibility_off_outlined,
          expanded: _showSmall,
          onTap: () => setState(() => _showSmall = !_showSmall),
        ),
      if (_showSmall)
        for (final item in small) () => _row(item, draft),
    ];

    return ListView.builder(
      key: PageStorageKey<String>('replenishment-${branch.warehouse}'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      itemCount: entries.length,
      itemBuilder: (context, index) => entries[index](),
    );
  }

  Widget _row(ReplenishmentItem item, ReplenishmentDraft draft) {
    final branch = widget.branch;
    return ReplenishmentItemRow(
      // The generation is part of the key so a refresh (or a completed
      // send) rebuilds the field from the new plan instead of keeping a
      // stale typed number.
      key: ValueKey('${branch.warehouse}|${item.itemCode}|${draft.generation}'),
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
  }
}

/// A section title in the branch list; tappable (with a chevron) when the
/// section can be collapsed.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.title,
    required this.icon,
    this.subtitle,
    this.expanded = true,
    this.onTap,
    this.warn = false,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final bool expanded;
  final VoidCallback? onTap;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subColor = warn
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subColor,
                          fontWeight: warn ? FontWeight.w600 : null,
                        ),
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(expanded ? Icons.expand_less : Icons.expand_more),
            ],
          ),
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

    // How fresh the figures are. Shown because the answer moves with the day's
    // sales, and somebody deciding a van load needs to know whether they are
    // reading this morning or last Thursday.
    final raw = plan.generatedOn.trim();
    String? updated;
    if (raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      updated = l10n.replenishmentUpdatedAt(
        parsed == null
            ? isolateLtr(raw)
            : formatDateTime(context, parsed, pattern: 'HH:mm'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: l10n.replenishmentSourceLine(
                  isolateLtr(plan.source.warehouse),
                ),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text:
                    ' · ${l10n.replenishmentHeaderBasis(plan.coverDays, plan.salesDays)}',
              ),
              if (updated != null) TextSpan(text: ' · $updated'),
            ],
          ),
          style: theme.textTheme.bodySmall,
        ),
        if (summary.negativeBins > 0 || summary.totalShortBy > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (summary.negativeBins > 0)
                  _WarnChip(
                    icon: Icons.report_gmailerrorred,
                    text: l10n.replenishmentNegativeBinsCount(
                      summary.negativeBins,
                    ),
                    color: theme.colorScheme.error,
                  ),
                // The company-wide shortfall is the owner's number, not the
                // van loader's: it is the one figure on the screen that says
                // "produce more" rather than "move stock".
                if (summary.totalShortBy > 0)
                  _WarnChip(
                    icon: Icons.trending_down,
                    text: l10n.replenishmentTotalShort(
                      trimQty(summary.totalShortBy),
                    ),
                    color: theme.colorScheme.tertiary,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WarnChip extends StatelessWidget {
  const _WarnChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
    final cartonCount = packing.cartons.length;

    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          // One slim row: what is typed (tap for the packing guide) and the
          // send button. The button's long name lives in its tooltip and the
          // confirmation dialog, so it no longer needs a full-width row.
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: totals.isEmpty
                      ? null
                      : () => showPackingGuide(context, branch),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n.replenishmentTypedTotal(
                              totals.lineCount,
                              trimQty(totals.totalQty),
                            ),
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!totals.isEmpty && cartonCount > 0) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: cartonsText,
                            child: Text(
                              '📦 $cartonCount',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                        if (!totals.isEmpty)
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            semanticLabel: l10n.replenishmentPackingGuide,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: l10n.replenishmentSendAction(branch.displayName),
                child: FilledButton.icon(
                  onPressed: canSend ? () => _send(context, ref) : null,
                  icon: draft.sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.local_shipping, size: 18),
                  label: Text(l10n.replenishmentSendShort),
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
