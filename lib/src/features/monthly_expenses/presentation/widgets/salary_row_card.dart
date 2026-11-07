import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../models/monthly_expense_models.dart';
import 'employee_penalty_sheet.dart' show formatPenaltyDays;
import 'monthly_expense_payment_list.dart';
import 'monthly_expense_status_chip.dart';

/// One employee's salary for the month, and everything that reduces it.
///
/// Deliberately the same shape as [RecurringExpenseCard] minus the manage menu:
/// a salary is not a registry entry, so there is nothing here to edit, pause or
/// end — that lives in HR.
///
/// The deductions block is rendered ONLY when something is actually deducted.
/// This list is sixteen people long, and printing "− Penalty 0 − Advance 0 −
/// Jars 0" on every clean row would turn a scannable list into a wall and hide
/// the two rows that do carry debt.
class SalaryRowCard extends StatelessWidget {
  final SalaryRow row;
  final String currency;
  final bool isBusy;

  final VoidCallback? onPay;
  final void Function(MonthlyExpensePayment payment)? onCancelPayment;

  /// Null hides the Add-penalty affordance — a read-only viewer.
  final VoidCallback? onAddPenalty;

  /// Null hides the per-penalty cancel action. Gated on the same server flag as
  /// the Cancel-payment button (`can_cancel_payments`), which is a NARROWER
  /// role set than the one that may read this screen.
  final void Function(PenaltyEntry penalty)? onCancelPenalty;

  const SalaryRowCard({
    super.key,
    required this.row,
    required this.currency,
    this.isBusy = false,
    this.onPay,
    this.onCancelPayment,
    this.onAddPenalty,
    this.onCancelPenalty,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    String money(double value) =>
        formatCurrency(context, value, currencyCode: currency);

    final statusColor = monthlyExpenseStatusColor(context, row.paymentStatus);
    final payable = row.canPay && !isBusy && onPay != null;
    final subtitleParts = [
      if ((row.designation ?? '').isNotEmpty) row.designation!,
      if ((row.department ?? '').isNotEmpty) row.department!,
    ];

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
          child: Icon(Icons.badge_outlined, color: statusColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                row.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              money(row.dueAmount),
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
              if (subtitleParts.isNotEmpty)
                Text(
                  subtitleParts.join(' • '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              // Who left and when: the reason this row sits in the left-staff
              // section rather than among this month's salaries.
              // Only once the date has passed: an employee serving notice carries
              // a future relieving date and has not left yet.
              if (row.relievingDate != null &&
                  (row.left || !row.relievingDate!.isAfter(DateTime.now())))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        size: 14,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n.monthlyExpensesLeftOn(
                            formatDate(context, row.relievingDate!,
                                pattern: 'd MMM yyyy'),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  MonthlyExpenseStatusChip(status: row.paymentStatus),
                  if (row.hasSalarySlip)
                    MonthlyExpenseStatusChip(
                      status: row.paymentStatus,
                      overrideLabel: l10n.monthlyExpensesSalarySlipBadge,
                      overrideColor: Colors.teal,
                      icon: Icons.description_outlined,
                    ),
                  if (row.offPayroll)
                    MonthlyExpenseStatusChip(
                      status: row.paymentStatus,
                      overrideLabel: l10n.monthlyExpensesOffPayrollBadge,
                      overrideColor: Colors.indigo,
                      icon: Icons.person_outline,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 20,
                runSpacing: 6,
                children: [
                  _cell(context, l10n.monthlyExpensesDue, money(row.dueAmount)),
                  _cell(context, l10n.monthlyExpensesPaid, money(row.paidAmount)),
                  _cell(
                    context,
                    l10n.monthlyExpensesRemaining,
                    money(row.remaining),
                    emphasise: true,
                  ),
                ],
              ),
              // Gross · − Penalty · − Advance · − Jars · = Net to pay, and only
              // the lines that are not zero.
              if (row.hasDeductions) ...[
                const SizedBox(height: 8),
                _DeductionsStrip(row: row, currency: currency),
              ],
            ],
          ),
        ),
        children: [
          const Divider(),
          if (row.hasSalarySlip)
            _NoteLine(
              icon: Icons.info_outline,
              color: Colors.teal.shade700,
              text: l10n.monthlyExpensesSalarySlipExists,
            ),
          if (row.offPayroll)
            _NoteLine(
              icon: Icons.person_outline,
              color: theme.colorScheme.onSurfaceVariant,
              text: l10n.monthlyExpensesOffPayrollExplain,
            ),
          // An off-payroll row has no structure, so "Base 0" would read as a
          // salary of nothing rather than as "there is no salary here".
          if (!row.offPayroll) ...[
            _InfoRow(
              label: l10n.monthlyExpensesSalaryBaseLabel,
              value: money(row.base),
            ),
            if (row.variable.abs() > 0.005)
              _InfoRow(
                label: l10n.monthlyExpensesSalaryVariableLabel,
                value: money(row.variable),
              ),
          ],
          if (row.penalties.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionLabel(text: l10n.monthlyExpensesPenaltiesTitle),
            for (final penalty in row.penalties)
              _PenaltyLine(
                penalty: penalty,
                currency: currency,
                onCancel: (isBusy || onCancelPenalty == null || penalty.settled)
                    ? null
                    : () => onCancelPenalty!(penalty),
              ),
          ],
          if (row.advances.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionLabel(text: l10n.monthlyExpensesAdvancesTitle),
            for (final advance in row.advances)
              _BalanceLine(
                icon: Icons.account_balance_wallet_outlined,
                title: l10n.monthlyExpensesOutstandingOf(
                  money(advance.outstanding),
                  money(advance.amount),
                ),
                subtitle: [
                  if (advance.postingDate != null)
                    formatDate(context, advance.postingDate!),
                  if (advance.status.isNotEmpty) advance.status,
                  if (advance.purpose.isNotEmpty) advance.purpose,
                ].join(' • '),
                reference: advance.name,
              ),
          ],
          if (row.orders.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionLabel(text: l10n.monthlyExpensesOrdersTitle),
            for (final order in row.orders)
              _BalanceLine(
                icon: Icons.shopping_bag_outlined,
                title: l10n.monthlyExpensesOutstandingOf(
                  money(order.outstanding),
                  money(order.grandTotal),
                ),
                subtitle: [
                  if (order.postingDate != null)
                    formatDate(context, order.postingDate!),
                  if (order.displayCustomer.isNotEmpty) order.displayCustomer,
                  if (order.status.isNotEmpty) order.status,
                ].join(' • '),
                reference: order.invoice,
              ),
          ],
          const SizedBox(height: 12),
          MonthlyExpensePaymentList(
            payments: row.payments,
            currency: currency,
            onCancel: (isBusy || onCancelPayment == null)
                ? null
                : (payment) => onCancelPayment!(payment),
          ),
          if (onAddPenalty != null || row.canPay) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  // Available even for an off-payroll employee: a penalty in
                  // money needs no salary structure, and those are exactly the
                  // people this screen was blind to.
                  if (onAddPenalty != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.gavel_outlined, size: 18),
                      label: Text(l10n.monthlyExpensesPenaltyAddAction),
                      onPressed: isBusy ? null : onAddPenalty,
                    ),
                  if (row.canPay)
                    FilledButton.icon(
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: Text(l10n.monthlyExpensesPayAction),
                      onPressed: payable ? onPay : null,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    String label,
    String value, {
    bool emphasise = false,
  }) {
    final theme = Theme.of(context);
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
}

/// Gross · − Penalty · − Advance · − Jars · = Net to pay.
///
/// Only the non-zero lines are rendered, so a row with a single advance shows
/// three figures rather than five. The net is the one the manager acts on, so
/// it is the emphasised one; the deductions are in the error colour because
/// each of them is money the company is NOT handing over today.
class _DeductionsStrip extends StatelessWidget {
  final SalaryRow row;
  final String currency;

  const _DeductionsStrip({required this.row, required this.currency});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    String money(double value) =>
        formatCurrency(context, value, currencyCode: currency);
    String minus(double value) =>
        l10n.monthlyExpensesDeductionAmount(money(value));

    final error = theme.colorScheme.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 6,
        children: [
          _figure(context, l10n.monthlyExpensesGrossLabel, money(row.grossDue)),
          if (row.penaltyTotal.abs() > 0.005)
            _figure(
              context,
              // The day equivalent rides along with the money: a penalty was
              // agreed in one of the two units and the other one has to be
              // readable without opening anything.
              row.penaltyDays.abs() > 0.005
                  ? '${l10n.monthlyExpensesPenaltyLabel} · '
                      '${l10n.monthlyExpensesPenaltyDaysAmount(formatPenaltyDays(context, row.penaltyDays))}'
                  : l10n.monthlyExpensesPenaltyLabel,
              minus(row.penaltyTotal),
              color: error,
            ),
          if (row.advanceTotal.abs() > 0.005)
            _figure(context, l10n.monthlyExpensesAdvanceLabel,
                minus(row.advanceTotal),
                color: error),
          if (row.orderTotal.abs() > 0.005)
            _figure(context, l10n.monthlyExpensesJarsLabel, minus(row.orderTotal),
                color: error),
          _figure(
            context,
            l10n.monthlyExpensesNetPayableLabel,
            money(row.netPayable),
            emphasise: true,
          ),
        ],
      ),
    );
  }

  Widget _figure(
    BuildContext context,
    String label,
    String value, {
    Color? color,
    bool emphasise = false,
  }) {
    final theme = Theme.of(context);
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
            fontWeight: emphasise ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// One penalty, with the unit it was agreed in, its date, its reason, and the
/// cancel action when the user may reverse money.
class _PenaltyLine extends StatelessWidget {
  final PenaltyEntry penalty;
  final String currency;
  final VoidCallback? onCancel;

  const _PenaltyLine({
    required this.penalty,
    required this.currency,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final subtitle = [
      if (penalty.penaltyDate != null) formatDate(context, penalty.penaltyDate!),
      if (penalty.equivalentDays.abs() > 0.005)
        l10n.monthlyExpensesPenaltyDaysAmount(
            formatPenaltyDays(context, penalty.equivalentDays)),
      if (penalty.reason.isNotEmpty) penalty.reason,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gavel_outlined, size: 16, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      formatCurrency(context, penalty.amount,
                          currencyCode: currency),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    if (penalty.settled) ...[
                      const SizedBox(width: 8),
                      Text(
                        l10n.monthlyExpensesPenaltySettledBadge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (onCancel != null)
            IconButton(
              tooltip: l10n.monthlyExpensesPenaltyCancelAction,
              icon: const Icon(Icons.undo, size: 18),
              color: theme.colorScheme.error,
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }
}

/// One open balance — an advance or a staff order — with its document name, so
/// a manager can find the posting in Desk.
class _BalanceLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String reference;

  const _BalanceLine({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (reference.isNotEmpty)
                  Text(
                    reference,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _NoteLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _NoteLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              style: theme.textTheme.bodySmall?.copyWith(color: color),
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
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
