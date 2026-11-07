import 'package:jarz_pos/src/core/localization/user_error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/manager_providers.dart';
import '../data/manager_api.dart';
import '../../../core/network/frappe_error_message.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/localized_formatters.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/utils/territory_label.dart';

String _normalizedManagerError(Object error) {
  final extracted = extractFrappeErrorMessage(error, fallback: '').trim();
  final message = extracted.isNotEmpty ? extracted : error.toString().trim();
  return message.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
}

String _localizedManagerErrorDetail(BuildContext context, Object error) {
  final l10n = context.l10n;
  final message = _normalizedManagerError(error);

  switch (message) {
    case 'Failed to load transfer branches':
      return l10n.managerTransferBranchesLoadFailed;
    case 'Failed to transfer branch':
      return l10n.invoiceTransferFailed;
    case 'Failed to fetch pending custom shipping requests':
      return l10n.managerPendingCustomShippingLoadFailed;
    default:
      return context.userErrorMessage(error);
  }
}

String _localizedManagerApproveError(BuildContext context, Object error) {
  final l10n = context.l10n;
  final message = _normalizedManagerError(error);

  if (message == 'Failed to approve') {
    return l10n.managerApproveDefaultError;
  }

  return context.userErrorMessage(_localizedManagerErrorDetail(context, error));
}

String _localizedManagerRejectError(BuildContext context, Object error) {
  final l10n = context.l10n;
  final message = _normalizedManagerError(error);

  if (message == 'Failed to reject') {
    return l10n.managerRejectDefaultError;
  }

  return context.userErrorMessage(_localizedManagerErrorDetail(context, error));
}

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final ordersAsync = ref.watch(managerOrdersProvider);
    final statesAsync = ref.watch(managerStatesProvider);
    final pendingCustomShippingAsync = ref.watch(pendingCustomShippingProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: l10n.managerMenuTooltip,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(l10n.managerDashboardTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(managerOrdersProvider);
          ref.invalidate(pendingCustomShippingProvider);
          await Future.wait([
            ref.read(dashboardSummaryProvider.future),
            ref.read(managerOrdersProvider.future),
            ref.read(pendingCustomShippingProvider.future),
          ]);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            // Near the bottom of the dashboard list: fetch the next 20 orders.
            if (n.depth == 0 &&
                n.metrics.axis == Axis.vertical &&
                n.metrics.extentAfter < 300) {
              ref.read(managerOrdersProvider.notifier).loadMore();
            }
            return false;
          },
          child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            summaryAsync.when(
              data: (summary) => _SummaryHeader(summary: summary),
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )),
              error: (e, st) => _ErrorTile(error: e, onRetry: () {
                ref.invalidate(dashboardSummaryProvider);
              }),
            ),
            const SizedBox(height: 12),
            _BranchChips(),
            const SizedBox(height: 8),
            statesAsync.when(
              data: (states) => _StateFilter(states: states),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            Text(l10n.managerPendingCustomShipping, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            pendingCustomShippingAsync.when(
              data: (items) => _PendingCustomShippingSection(items: items),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, st) => _ErrorTile(error: e, onRetry: () {
                ref.invalidate(pendingCustomShippingProvider);
              }),
            ),
            const SizedBox(height: 12),
            Text(l10n.managerRecentOrders, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const _ChannelChips(),
            const SizedBox(height: 4),
            ordersAsync.when(
              data: (orders) => orders.invoices.isEmpty
                  ? Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(l10n.managerNoRecentOrders)),
                    )
                  : Column(
                      children: [
                        for (final o in orders.invoices) _OrderTile(invoice: o),
                        if (orders.loadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )),
              error: (e, st) => _ErrorTile(error: e, onRetry: () {
                ref.invalidate(managerOrdersProvider);
              }),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final DashboardSummary summary;
  const _SummaryHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currencyStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.green.shade700,
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.managerBranchBalances, style: Theme.of(context).textTheme.titleMedium),
                // Simple hint button to guide switching in POS/Kanban headers
                TextButton.icon(
                  onPressed: () {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.managerSwitchProfileTip)),
                    );
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(l10n.managerSwitchProfile),
                )
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in summary.branches)
                  Chip(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(formatCurrency(context, b.balance), style: currencyStyle),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.managerTotalCash),
                Text(formatCurrency(context, summary.totalBalance), style: currencyStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(dashboardSummaryProvider).maybeWhen(
          data: (s) => s,
          orElse: () => null,
        );
    final selected = ref.watch(selectedBranchProvider);

    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          selected: selected == 'all',
          label: Text(l10n.managerAll),
          onSelected: (_) => ref.read(selectedBranchProvider.notifier).state = 'all',
        ),
        if (summary != null)
          for (final b in summary.branches)
            ChoiceChip(
              selected: selected == b.name,
              label: Text(b.title),
              onSelected: (_) => ref.read(selectedBranchProvider.notifier).state = b.name,
            ),
      ],
    );
  }
}

class _ChannelChips extends ConsumerWidget {
  const _ChannelChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(managerOrdersChannelProvider);
    final labels = {
      ManagerOrdersChannel.all: l10n.managerOrdersChannelAll,
      ManagerOrdersChannel.b2c: l10n.managerOrdersChannelB2c,
      ManagerOrdersChannel.b2b: l10n.managerOrdersChannelB2b,
    };
    return Wrap(
      spacing: 8,
      children: [
        for (final channel in ManagerOrdersChannel.values)
          ChoiceChip(
            selected: selected == channel,
            label: Text(labels[channel]!),
            onSelected: (_) =>
                ref.read(managerOrdersChannelProvider.notifier).state = channel,
          ),
      ],
    );
  }
}

class _OrderTile extends StatelessWidget {
  final ManagerInvoice invoice;
  const _OrderTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        dense: true,
        title: Row(
          children: [
            Flexible(
              child: Text(
                '${invoice.displayId} • ${invoice.customerName}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (invoice.isB2b) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  context.l10n.managerOrdersChannelB2b,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text('${invoice.postingDate} ${invoice.postingTime}  |  ${invoice.status}  |  ${invoice.branch}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatCurrency(context, invoice.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            _ChangeBranchButton(invoice: invoice),
          ],
        ),
      ),
    );
  }
}

class _PendingCustomShippingSection extends ConsumerWidget {
  final List<CustomShippingRequest> items;
  const _PendingCustomShippingSection({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(context.l10n.managerNoPendingRequests),
        ),
      );
    }

    return Column(
      children: [
        for (final item in items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.invoice} • ${item.customerName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${formatCurrency(context, item.originalAmount)} '
                        '${Directionality.of(context) == TextDirection.rtl ? '←' : '→'} '
                        '${formatCurrency(context, item.requestedAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(context.l10n.settlementTerritoryLabel(
                    territoryLabel(nameAr: item.territoryNameAr, raw: item.territory),
                  )),
                  const SizedBox(height: 4),
                  Text(context.l10n.managerReasonLabel(item.reason)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _reject(context, ref, item),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: Text(context.l10n.managerReject, style: const TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _approve(context, ref, item),
                        icon: const Icon(Icons.check),
                        label: Text(context.l10n.expensesApprove),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref, CustomShippingRequest item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(managerApiProvider).approveCustomShipping(item.name);
      if (!context.mounted) return;
      ref.invalidate(pendingCustomShippingProvider);
      ref.invalidate(managerOrdersProvider);
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.managerCustomShippingApproved)));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_localizedManagerApproveError(context, e))));
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, CustomShippingRequest item) async {
    final messenger = ScaffoldMessenger.of(context);
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final l10n = ctx.l10n;

        return AlertDialog(
          title: Text(l10n.managerRejectCustomShippingTitle),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.commonReasonLabel,
              hintText: l10n.managerRejectReasonHint,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.commonCancel)),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(reasonController.text.trim()), child: Text(l10n.managerReject)),
          ],
        );
      },
    );
    if (reason == null) return;

    try {
      await ref.read(managerApiProvider).rejectCustomShipping(item.name, reason: reason);
      if (!context.mounted) return;
      ref.invalidate(pendingCustomShippingProvider);
      ref.invalidate(managerOrdersProvider);
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.managerCustomShippingRejected)));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_localizedManagerRejectError(context, e))));
    }
  }
}

class _StateFilter extends ConsumerWidget {
  final List<String> states;
  const _StateFilter({required this.states});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(selectedStateProvider) ?? 'all';
    final items = ['all', ...states];
    return Row(
      children: [
        Text(l10n.managerFilterByState),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: items.contains(selected) ? selected : 'all',
          onChanged: (v) {
            ref.read(selectedStateProvider.notifier).state = v;
            ref.invalidate(managerOrdersProvider);
          },
          items: [
            for (final s in items)
              DropdownMenuItem<String>(
                value: s,
                child: Text(s == 'all' ? l10n.managerAll : s),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChangeBranchButton extends ConsumerWidget {
  final ManagerInvoice invoice;
  const _ChangeBranchButton({required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return IconButton(
      tooltip: l10n.managerChangeBranch,
      icon: const Icon(Icons.swap_horiz),
      onPressed: () async {
        // Capture messenger before awaits to avoid using context across async gaps
        final messenger = ScaffoldMessenger.of(context);
        final summary = await ref.read(dashboardSummaryProvider.future);
        final branches = summary.branches;
        final current = invoice.branchName;
        String? selected = current;
        if (!context.mounted) return;
        final picked = await showDialog<String>(
          context: context,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setState) => AlertDialog(
                title: Text(l10n.managerAssignToBranch),
                content: SizedBox(
                  width: ResponsiveUtils.getDialogWidth(ctx, small: 320, medium: 380, large: 400),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: ResponsiveUtils.getDialogHeight(ctx, phoneFraction: 0.55, tabletFraction: 0.45, max: 400),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final b in branches)
                            ListTile(
                              title: Text(b.title),
                              trailing: selected == b.name ? const Icon(Icons.check) : null,
                              onTap: () => setState(() {
                                selected = b.name;
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonCancel)),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, selected),
                    child: Text(l10n.commonSubmit),
                  ),
                ],
              ),
            );
          },
        );
        if (!context.mounted) return;
        if (picked == null || picked == current) return;
        try {
          await ref.read(managerApiProvider).updateInvoiceBranch(invoiceId: invoice.name, newBranch: picked);
          final targetBranch = branches.firstWhere(
            (branch) => branch.name == picked,
            orElse: () => BranchBalance(
              name: picked,
              title: picked,
              cashAccount: null,
              balance: 0,
            ),
          );

          // Refresh the current manager list so the moved invoice leaves stale filters.
          ref.invalidate(managerOrdersProvider);
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.invoiceTransferSuccess(targetBranch.title))),
          );
        } catch (e) {
          if (!context.mounted) return;
          final errorMessage = _localizedManagerErrorDetail(context, e);
          messenger.showSnackBar(SnackBar(content: Text(context.userErrorMessage(errorMessage))));
        }
      },
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorTile({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = _localizedManagerErrorDetail(context, error);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(message == l10n.commonError ? message : context.userErrorMessage(message)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
