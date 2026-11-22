import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/user_error_message.dart';
import '../../../core/localization/localized_display_mappers.dart';
import '../../../core/localization/localized_formatters.dart';
import '../../auth/state/login_notifier.dart';
import '../../pos/presentation/widgets/courier_balances_dialog.dart';
import '../models/shift_models.dart';
import '../state/shift_notifier.dart';
import 'shift_sheet_screen.dart';
import 'widgets/shift_history.dart';

String _normalizeShiftError(String error) {
  return error.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
}

String _localizedShiftError(BuildContext context, String error) {
  final l10n = context.l10n;
  final message = _normalizeShiftError(error);

  switch (message) {
    case 'Unexpected start shift response':
      return l10n.shiftUnexpectedStartResponse;
    case 'Unexpected shift summary response':
      return l10n.shiftUnexpectedSummaryResponse;
    case 'Unexpected end shift response':
      return l10n.shiftUnexpectedEndResponse;
    default:
      if (message.isEmpty) {
        return l10n.commonError;
      }
      return context.userErrorMessage(message, fallback: l10n.commonError);
  }
}

double? _parseShiftAmount(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final amount = double.tryParse(trimmed);
  if (amount == null || amount.isNaN || amount.isInfinite || amount < 0) {
    return null;
  }
  return amount;
}

String? _validateShiftAmount(BuildContext context, String text) {
  final l10n = context.l10n;
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return l10n.shiftCashCountRequired;
  }

  final amount = double.tryParse(trimmed);
  if (amount == null || amount.isNaN || amount.isInfinite) {
    return l10n.shiftCashCountInvalid;
  }

  if (amount < 0) {
    return l10n.shiftCashCountNegative;
  }

  return null;
}

class ShiftEndScreen extends ConsumerStatefulWidget {
  const ShiftEndScreen({super.key});

  @override
  ConsumerState<ShiftEndScreen> createState() => _ShiftEndScreenState();
}

class _ShiftEndScreenState extends ConsumerState<ShiftEndScreen> {
  final Map<String, TextEditingController> _controllers = {};

  /// Courier Transaction names the closer has ticked as "cash still with the
  /// courier". Held by name rather than by index so a mid-close settlement by a
  /// colleague simply drops the row without shifting anyone else's tick.
  final Set<String> _confirmedCourierTransactions = {};
  ShiftSummary? _endResult;
  String? _validationError;
  bool _loggingOut = false;

  /// The pre-close summary request, cached per opening entry. Building it
  /// inline in `build` re-fetched the summary on every `setState` (each
  /// keystroke in a count field, each courier tick), so it is created once
  /// and only replaced by [_refreshSummary].
  Future<ShiftSummary?>? _summaryFuture;
  String? _summaryOpeningEntry;

  Future<ShiftSummary?> _summaryFor(String openingEntry) {
    final cached = _summaryFuture;
    if (cached != null && _summaryOpeningEntry == openingEntry) {
      return cached;
    }
    _summaryOpeningEntry = openingEntry;
    return _summaryFuture = ref
        .read(shiftNotifierProvider.notifier)
        .getCurrentShiftSummary(openingEntry: openingEntry);
  }

  /// Drops the cached summary so the next build fetches a fresh one.
  void _refreshSummary() {
    if (!mounted) return;
    setState(() {
      _summaryFuture = null;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The post-close summary is pure local state: the shift is closed and the
    // session is already gone, so this branch must not touch the API again.
    // Checked before any watch so the shift lookup is not kept alive either.
    final endResult = _endResult;
    if (endResult != null) {
      return _buildClosedSummary(context, endResult);
    }

    final l10n = context.l10n;
    final shiftState = ref.watch(shiftNotifierProvider);
    final activeShiftAsync = ref.watch(activeShiftProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shiftEndTitle),
        actions: [
          // A cashier's own past shifts. Amounts stay server-side unless the
          // viewer is a manager, so this does not undo the blind close.
          IconButton(
            tooltip: l10n.shiftHistoryTitle,
            icon: const Icon(Icons.history),
            onPressed: () => ShiftHistory.show(context, ref),
          ),
          IconButton(
            tooltip: l10n.shiftRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: shiftState.isLoading ? null : _refreshSummary,
          ),
        ],
      ),
      body: activeShiftAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(context.userErrorMessage(_normalizeShiftError(e.toString()))),
        ),
        data: (activeShift) {
          if (activeShift == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.shiftNoActive),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.pos),
                    child: Text(l10n.shiftBackToPos),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<ShiftSummary?>(
            future: _summaryFor(activeShift.name),
            builder: (context, snapshot) {
              final waiting = snapshot.connectionState == ConnectionState.waiting;
              // A refresh keeps the previous summary on screen (FutureBuilder
              // carries the last data across a new future), so the counts the
              // closer already typed do not vanish behind a spinner.
              if (waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError && !waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _localizedShiftError(context, snapshot.error.toString()),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _refreshSummary,
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.shiftRefresh),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final summary = snapshot.data;
              if (summary == null) {
                return Center(child: Text(l10n.shiftSummaryLoadFailed));
              }

              return _buildPreCloseView(context, summary, shiftState);
            },
          );
        },
      ),
    );
  }

  // ── Pre-close view: invoices table + closing input ──

  Widget _buildPreCloseView(BuildContext context, ShiftSummary summary, ShiftState shiftState) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final courierCloseBlock = summary.courierCloseBlock;
    final hasCourierCloseBlock = courierCloseBlock?.blocked == true;
    // A backend that offers per-line confirmation lets the shift close with
    // money still out; one that does not still refuses, and the old
    // "go settle first" flow is the only way through.
    final canAcknowledge = courierCloseBlock?.requiresAcknowledgement == true;
    final courierTransactions = courierCloseBlock?.transactions ?? const <ShiftCourierCloseTransaction>[];
    final allCourierConfirmed = courierTransactions.every(
      (row) => _confirmedCourierTransactions.contains(row.courierTransaction),
    );
    final hasClosingPaymentModes = summary.paymentReconciliation.isNotEmpty;
    final displayError = _validationError ??
        (shiftState.error != null ? _localizedShiftError(context, shiftState.error!) : null);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.shiftLabel(summary.openingEntry), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _infoRow(l10n.shiftInvoices(summary.invoiceCount), Icons.receipt_long),
          const Divider(height: 24),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                // The paper sales sheet, on screen. Rows only for staff: the
                // server sends no totals, so the blind count below stays blind.
                Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(l10n.shiftSheetReviewAction),
                    subtitle: Text(l10n.shiftSheetReviewHint),
                    onTap: () =>
                        ShiftSheetScreen.open(context, summary.openingEntry),
                  ),
                ),
                if (hasCourierCloseBlock) ...[
                  if (canAcknowledge)
                    _buildCourierCarryCard(context, courierCloseBlock!, summary)
                  else
                    _buildCourierCloseBlockCard(context, courierCloseBlock!),
                  const SizedBox(height: 14),
                ],
                Text(l10n.shiftClosingPrompt, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  l10n.shiftBlindCountHint,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                if (!hasClosingPaymentModes)
                  _buildMissingPaymentModesCard(context)
                else
                  ...summary.paymentReconciliation.map((row) {
                    final controller = _controllers.putIfAbsent(
                      row.modeOfPayment,
                      () => TextEditingController(),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(localizedPaymentMethodLabel(context, row.modeOfPayment)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) {
                              if (_validationError != null) {
                                setState(() {
                                  _validationError = null;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              labelText: l10n.shiftCountedClosingAmount,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          if (displayError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                displayError,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: shiftState.isLoading ? null : () => context.go(AppRoutes.pos),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l10n.shiftBackToPos),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: shiftState.isLoading
                      ? null
                      : (hasCourierCloseBlock && !canAcknowledge)
                      ? () => _handleCourierSettlementReview(summary)
                      : !hasClosingPaymentModes
                      ? null
                      : (hasCourierCloseBlock && !allCourierConfirmed)
                      ? null
                      : () => _handleEndShift(summary),
                  icon: Icon(
                    (hasCourierCloseBlock && !canAcknowledge)
                        ? Icons.local_shipping_outlined
                        : Icons.task_alt_outlined,
                  ),
                  label: Text(
                    (hasCourierCloseBlock && !canAcknowledge)
                        ? l10n.shiftCourierReviewButton
                        : l10n.shiftEndButton,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Post-close summary ──

  Widget _buildClosedSummary(BuildContext context, ShiftSummary result) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shiftClosedSummaryTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shiftEndedSuccess, style: theme.textTheme.titleMedium?.copyWith(color: Colors.green)),
            const SizedBox(height: 12),
            if (result.closingEntry != null)
              _infoRow('${l10n.shiftClosingEntry}: ${result.closingEntry}', Icons.check_circle),
            _infoRow(l10n.shiftInvoices(result.invoiceCount), Icons.receipt_long),
            // The last thing the closer reads before logging out: what is still
            // out there, and that it stays open until somebody settles it.
            if (result.carriedCourierCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.shiftCourierCarriedSummary(
                            result.carriedCourierCount,
                            formatCurrency(context, result.carriedCourierAmount),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (result.journalEntry != null && result.journalEntry!.isNotEmpty && result.journalEntry != 'null')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${l10n.shiftJournalCreated}: ${result.journalEntry}',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Divider(height: 24),
            Expanded(
              child: ListView(
                children: [
                  ...result.paymentReconciliation.map((row) {
                    final diff = row.difference;
                    final diffColor = diff == 0
                        ? theme.colorScheme.onSurface
                        : (diff > 0 ? Colors.green : theme.colorScheme.error);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.modeOfPayment,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (result.varianceVisible)
                            Text(
                              l10n.shiftExpectedAmount(
                                formatCurrency(context, row.expectedAmount),
                              ),
                            ),
                          Text(
                            '${l10n.shiftCountedClosingAmount}: ${formatCurrency(context, row.closingAmount)}',
                          ),
                          if (result.varianceVisible)
                            Text(
                              '${l10n.shiftDifference}: ${formatCurrency(context, diff)}',
                              style: TextStyle(
                                color: diffColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loggingOut ? null : _handleLogout,
                child: Text(l10n.shiftLogout),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _infoRow(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  /// The end-of-day confirmation: every order whose cash is still with a
  /// courier, listed one by one and grouped by who is holding it.
  ///
  /// A courier who takes the last order of the day and drives home is a normal
  /// night, so this is not a wall — but it is not a formality either. The closer
  /// ticks each line, and what they tick is stamped onto the transaction as the
  /// shift that let the money walk.
  Widget _buildCourierCarryCard(
    BuildContext context,
    ShiftCourierCloseBlock block,
    ShiftSummary summary,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final transactions = block.transactions;
    final confirmedCount = transactions
        .where((row) => _confirmedCourierTransactions.contains(row.courierTransaction))
        .length;
    final allConfirmed = confirmedCount == transactions.length;

    // Grouped by courier, in the order the server sent them (oldest dispatch
    // first), so the money that has been out longest is read first.
    final groups = <String, List<ShiftCourierCloseTransaction>>{};
    for (final row in transactions) {
      groups.putIfAbsent(row.partyKey, () => []).add(row);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.local_shipping_outlined, color: Colors.orange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.shiftCourierCarryTitle,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.shiftCourierCarryBody(
                        block.transactionCount,
                        formatCurrency(context, block.netBalance),
                        block.partyCount,
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.shiftCourierCarryHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.shiftCourierCarryConfirmedOf(confirmedCount, transactions.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: allConfirmed ? Colors.green.shade700 : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  if (allConfirmed) {
                    _confirmedCourierTransactions.clear();
                  } else {
                    _confirmedCourierTransactions.addAll(
                      transactions.map((row) => row.courierTransaction),
                    );
                  }
                  _validationError = null;
                }),
                child: Text(
                  allConfirmed
                      ? l10n.shiftCourierCarryClearAll
                      : l10n.shiftCourierCarryConfirmAll,
                ),
              ),
            ],
          ),
          for (final entry in groups.entries) ...[
            const Divider(height: 18),
            Text(
              l10n.shiftCourierBlockPartySummary(
                entry.value.first.displayName.isNotEmpty
                    ? entry.value.first.displayName
                    : entry.value.first.party,
                entry.value.length,
                entry.value.map((row) => row.referenceInvoice).toSet().length,
              ),
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            ...entry.value.map((row) => _buildCourierCarryRow(context, row)),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => _handleCourierSettlementReview(summary),
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: Text(l10n.shiftCourierCarrySettleNow),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourierCarryRow(
    BuildContext context,
    ShiftCourierCloseTransaction row,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final confirmed = _confirmedCourierTransactions.contains(row.courierTransaction);

    // These rows sit inside the tinted carry-over box, and a ListTile paints
    // its tap ink on the nearest Material - the Scaffold, underneath that
    // tint, so the splash was never visible. Flutter 3.41+ asserts on it. A
    // transparent Material gives the row a surface of its own without
    // changing how the box looks.
    return Material(
      type: MaterialType.transparency,
      child: CheckboxListTile(
      value: confirmed,
      onChanged: (value) => setState(() {
        if (value == true) {
          _confirmedCourierTransactions.add(row.courierTransaction);
        } else {
          _confirmedCourierTransactions.remove(row.courierTransaction);
        }
        _validationError = null;
      }),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        l10n.shiftCourierCarryRowLabel(
          row.referenceInvoice,
          row.customerName.isNotEmpty ? row.customerName : row.displayName,
        ),
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.shiftCourierCarryCheckboxLabel} · '
            '${l10n.shiftCourierBlockNetBalance(formatCurrency(context, row.netBalance))}',
            style: theme.textTheme.bodySmall,
          ),
          // Second night out is a different fact from the first, and the only
          // place it can be read at close time is right here.
          if (row.carried)
            Text(
              l10n.shiftCourierCarryCarriedBadge(row.carryCount, row.daysOutstanding),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildCourierCloseBlockCard(
    BuildContext context,
    ShiftCourierCloseBlock block,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final extraCouriers = block.partyCount - block.parties.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.local_shipping_outlined, color: Colors.orange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.shiftCourierBlockTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.shiftCourierBlockBody(
                        block.transactionCount,
                        block.partyCount,
                        block.invoiceCount,
                        block.posProfile,
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.shiftCourierBlockHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (block.parties.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...block.parties.map(
              (party) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.shiftCourierBlockPartySummary(
                          party.displayName.isNotEmpty ? party.displayName : party.party,
                          party.transactionCount,
                          party.invoiceCount,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.shiftCourierBlockNetBalance(
                        formatCurrency(context, party.netBalance),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (extraCouriers > 0)
            Text(
              l10n.shiftCourierBlockMore(extraCouriers),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMissingPaymentModesCard(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.shiftNoClosingPaymentMethodsTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.shiftNoClosingPaymentMethodsBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCourierSettlementReview(ShiftSummary summary) async {
    final activeBlock = summary.courierCloseBlock?.parties ?? const <ShiftCourierCloseParty>[];
    final shouldFilterDialog = summary.courierCloseBlock != null &&
        summary.courierCloseBlock!.partyCount == activeBlock.length;

    await showCourierBalancesDialog(
      context,
      allowedPartyKeys: shouldFilterDialog
          ? activeBlock.map((party) => '${party.partyType}::${party.party}').toSet()
          : null,
    );
    if (!mounted) return;

    ref.read(shiftNotifierProvider.notifier).clearError();
    // A settlement in the dialog changes the courier block, so re-read it.
    setState(() {
      _validationError = null;
      _summaryFuture = null;
    });
  }

  Future<void> _handleEndShift(ShiftSummary summary) async {
    if (summary.paymentReconciliation.isEmpty) {
      setState(() {
        _validationError = context.l10n.shiftNoClosingPaymentMethodsBody;
      });
      return;
    }

    final courierTransactions =
        summary.courierCloseBlock?.transactions ?? const <ShiftCourierCloseTransaction>[];
    final acknowledged = courierTransactions
        .map((row) => row.courierTransaction)
        .where(_confirmedCourierTransactions.contains)
        .toList();
    if (acknowledged.length != courierTransactions.length) {
      setState(() {
        _validationError = context.l10n.shiftCourierCarryUnconfirmed;
      });
      return;
    }

    final balances = <Map<String, dynamic>>[];
    for (final row in summary.paymentReconciliation) {
      final text = _controllers[row.modeOfPayment]?.text ?? '';
      final validationError = _validateShiftAmount(context, text);
      if (validationError != null) {
        setState(() {
          _validationError = validationError;
        });
        return;
      }

      balances.add(
        {
          'mode_of_payment': row.modeOfPayment,
          'closing_amount': _parseShiftAmount(text)!,
        },
      );
    }

    final result = await ref
        .read(shiftNotifierProvider.notifier)
        .endShift(
          closingBalances: balances,
          openingEntry: summary.openingEntry,
          acknowledgedCourierTransactions: acknowledged,
        );

    if (!mounted) return;
    if (result == null) {
      // A refused close is often the server seeing something this summary
      // does not (a new courier line, a moved payment); re-read it so the
      // screen matches what the next attempt will be judged against.
      _refreshSummary();
      return;
    }

    setState(() {
      _validationError = null;
      _endResult = result;
    });
    // Refreshed before the session goes: whichever way the lookup lands (null
    // now, or an error once the session is gone) the shift gate reads "no open
    // shift", so any route out of here leads to Start Shift rather than a POS
    // screen backed by a closed till.
    ref.invalidate(activeShiftProvider);

    // Closing the shift signs the operator out. The backend session is dropped
    // here, the moment the till is counted out, rather than waiting on the
    // button below — walking away from the terminal or killing the app must
    // not leave a closed till holding a live session. The client-side flip is
    // deferred to `_handleLogout` so the closing summary survives long enough
    // to be read (it goes down with the router the instant auth flips).
    await ref.read(loginNotifierProvider.notifier).endSession();
  }

  Future<void> _handleLogout() async {
    if (_loggingOut) return;
    setState(() {
      _loggingOut = true;
    });

    try {
      await ref.read(loginNotifierProvider.notifier).logout();
    } finally {
      // The session is already gone either way; always land on the login
      // screen rather than stranding the user on a dead summary.
      if (mounted) context.go(AppRoutes.login);
    }
  }
}
