import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../models/monthly_expense_models.dart';
import 'monthly_expense_payment_list.dart';
import 'monthly_expense_status_chip.dart';

/// What the card menu can ask for. Kept as an enum so the screen switches on a
/// value the compiler checks rather than on a string.
enum RecurringExpenseMenuAction { edit, pause, resume, end }

class RecurringExpenseCard extends StatelessWidget {
  final RecurringExpenseItem item;
  final String currency;
  final bool canManage;
  final bool isBusy;

  /// The board month, `YYYY-MM`. Lets the card say whether an amount change
  /// already applies or is still upcoming. Empty hides that note.
  final String boardMonth;

  final VoidCallback? onPay;
  final void Function(RecurringExpenseMenuAction action)? onMenuAction;
  final void Function(MonthlyExpensePayment payment)? onCancelPayment;

  const RecurringExpenseCard({
    super.key,
    required this.item,
    required this.currency,
    required this.canManage,
    this.isBusy = false,
    this.boardMonth = '',
    this.onPay,
    this.onMenuAction,
    this.onCancelPayment,
  });

  /// "Raised to 6,500 from Nov 2026 (was 5,500)" once the board month has
  /// reached the latest change, or "6,500 from Nov 2026" while that change is
  /// still ahead of the board month. Null when the history has a single row.
  String? _amountChangeNote(
    BuildContext context,
    String Function(double) money,
  ) {
    final history = item.amountHistory;
    if (history.length < 2) return null;
    final l10n = context.l10n;
    final latest = history.last;
    final previous = history[history.length - 2];
    final monthLabel = DateFormat.yMMM(l10n.localeName)
        .format(DateTime(latest.effectiveFrom.year, latest.effectiveFrom.month));

    final board = DateTime.tryParse('$boardMonth-01');
    if (board != null && board.isBefore(latest.effectiveFrom)) {
      return l10n.monthlyExpensesAmountUpcoming(
        money(latest.amount),
        monthLabel,
      );
    }
    return latest.amount >= previous.amount
        ? l10n.monthlyExpensesAmountRaised(
            money(latest.amount), monthLabel, money(previous.amount))
        : l10n.monthlyExpensesAmountLowered(
            money(latest.amount), monthLabel, money(previous.amount));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    String money(double value) =>
        formatCurrency(context, value, currencyCode: currency);

    final statusColor = monthlyExpenseStatusColor(context, item.paymentStatus);
    // `can_pay` is the server's answer and wins; the client only adds "not
    // while another mutation is in flight".
    final payable = item.canPay && !isBusy && onPay != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(
            monthlyExpenseStatusIcon(item.paymentStatus),
            color: statusColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              money(item.dueAmount),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  MonthlyExpenseStatusChip(status: item.paymentStatus),
                  if (item.isPaused)
                    MonthlyExpenseStatusChip(
                      status: item.status,
                      overrideLabel: l10n.monthlyExpensesLifecyclePaused,
                      overrideColor: Colors.amber.shade800,
                      icon: Icons.pause_circle_outline,
                    ),
                  if (item.isEnded)
                    MonthlyExpenseStatusChip(
                      status: item.status,
                      overrideLabel: l10n.monthlyExpensesLifecycleEnded,
                      overrideColor: theme.colorScheme.onSurfaceVariant,
                      icon: Icons.stop_circle_outlined,
                    ),
                  // Honesty badges. `inferred` means the paid figure came out
                  // of the ledger rather than a payment made here, and
                  // `shared_account` means it could not be attributed at all —
                  // both change what "paid" is worth, so both are on the face
                  // of the card, not buried in the expanded section.
                  if (item.inferred)
                    MonthlyExpenseStatusChip(
                      status: item.paymentStatus,
                      overrideLabel: l10n.monthlyExpensesInferredBadge,
                      overrideColor: Colors.indigo,
                      icon: Icons.auto_awesome_motion_outlined,
                    ),
                  if (item.sharedAccount)
                    MonthlyExpenseStatusChip(
                      status: item.paymentStatus,
                      overrideLabel: l10n.monthlyExpensesSharedAccountBadge,
                      overrideColor: Colors.brown,
                      icon: Icons.call_split,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_amountChangeNote(context, money) case final note?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              _AmountsRow(
                due: money(item.dueAmount),
                paid: money(item.paidAmount),
                remaining: money(item.remaining),
              ),
            ],
          ),
        ),
        children: [
          const Divider(),
          if (item.inferred)
            _Disclosure(
              icon: Icons.auto_awesome_motion_outlined,
              color: Colors.indigo,
              text: l10n.monthlyExpensesInferredExplain(
                money(item.paidUnlinked),
              ),
            ),
          if (item.sharedAccount)
            _Disclosure(
              icon: Icons.call_split,
              color: Colors.brown,
              text: l10n.monthlyExpensesSharedAccountExplain(
                item.accountDisplayLabel,
              ),
            ),
          _InfoRow(
            label: l10n.monthlyExpensesAmountLabel,
            value: money(item.monthAmount),
          ),
          _InfoRow(
            label: l10n.monthlyExpensesFrequencyLabel,
            value: item.frequency,
          ),
          if (item.monthlyEquivalent > 0 &&
              (item.monthlyEquivalent - item.amount).abs() > 0.005)
            _InfoRow(
              label: l10n.monthlyExpensesMonthlyEquivalentLabel,
              value: money(item.monthlyEquivalent),
            ),
          if (item.payOnVisit)
            _InfoRow(
              label: l10n.monthlyExpensesDueDateLabel,
              value: l10n.monthlyExpensesPaidOnVisit,
            )
          else if (item.dueDate != null)
            _InfoRow(
              label: l10n.monthlyExpensesDueDateLabel,
              value: formatDate(context, item.dueDate!),
            ),
          _InfoRow(
            label: l10n.monthlyExpensesAccountLabel,
            value: item.accountDisplayLabel,
          ),
          if ((item.costCenter ?? '').isNotEmpty)
            _InfoRow(
              label: l10n.monthlyExpensesCostCenterLabel,
              value: item.costCenter!,
            ),
          if ((item.supplier ?? '').isNotEmpty)
            _InfoRow(
              label: l10n.monthlyExpensesSupplierLabel,
              value: item.supplier!,
            ),
          if ((item.notes ?? '').isNotEmpty)
            _InfoRow(
              label: l10n.monthlyExpensesNotesLabel,
              value: item.notes!,
            ),
          const SizedBox(height: 12),
          MonthlyExpensePaymentList(
            payments: item.payments,
            currency: currency,
            onCancel: (isBusy || onCancelPayment == null)
                ? null
                : (payment) => onCancelPayment!(payment),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (canManage && onMenuAction != null)
                PopupMenuButton<RecurringExpenseMenuAction>(
                  tooltip: l10n.monthlyExpensesManageTooltip,
                  enabled: !isBusy,
                  onSelected: onMenuAction,
                  itemBuilder: (ctx) {
                    final menuL10n = ctx.l10n;
                    return [
                      PopupMenuItem(
                        value: RecurringExpenseMenuAction.edit,
                        child: Text(menuL10n.monthlyExpensesEditAction),
                      ),
                      if (item.isActive)
                        PopupMenuItem(
                          value: RecurringExpenseMenuAction.pause,
                          child: Text(menuL10n.monthlyExpensesPauseAction),
                        ),
                      if (!item.isActive)
                        PopupMenuItem(
                          value: RecurringExpenseMenuAction.resume,
                          child: Text(menuL10n.monthlyExpensesResumeAction),
                        ),
                      if (!item.isEnded)
                        PopupMenuItem(
                          value: RecurringExpenseMenuAction.end,
                          child: Text(menuL10n.monthlyExpensesEndAction),
                        ),
                    ];
                  },
                ),
              const SizedBox(width: 8),
              if (item.canPay)
                FilledButton.icon(
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: Text(l10n.monthlyExpensesPayAction),
                  onPressed: payable ? onPay : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Due / Paid / Remaining side by side, with Remaining emphasised — the same
/// hierarchy as the month header, one item down.
class _AmountsRow extends StatelessWidget {
  final String due;
  final String paid;
  final String remaining;

  const _AmountsRow({
    required this.due,
    required this.paid,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    Widget cell(String label, String value, {bool emphasise = false}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: emphasise ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 20,
      runSpacing: 6,
      children: [
        cell(l10n.monthlyExpensesDue, due),
        cell(l10n.monthlyExpensesPaid, paid),
        cell(l10n.monthlyExpensesRemaining, remaining, emphasise: true),
      ],
    );
  }
}

class _Disclosure extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Disclosure({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
