import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../models/monthly_expense_models.dart';

/// The server's `payment_status` in the user's language.
///
/// An unknown status falls through to itself rather than to a guess: the
/// vocabulary belongs to the backend, and a status this build has not heard of
/// is better shown verbatim than silently relabelled as something else.
String localizedMonthlyExpenseStatus(BuildContext context, String status) {
  final l10n = context.l10n;
  switch (status) {
    case MonthlyExpenseStatus.paid:
      return l10n.monthlyExpensesStatusPaid;
    case MonthlyExpenseStatus.partial:
      return l10n.monthlyExpensesStatusPartial;
    case MonthlyExpenseStatus.unpaid:
      return l10n.monthlyExpensesStatusUnpaid;
    case MonthlyExpenseStatus.notDue:
      return l10n.monthlyExpensesStatusNotDue;
    case MonthlyExpenseStatus.overpaid:
      return l10n.monthlyExpensesStatusOverpaid;
    case MonthlyExpenseStatus.awaitingVisit:
      return l10n.monthlyExpensesStatusAwaitingVisit;
    case MonthlyExpenseStatus.noVisit:
      return l10n.monthlyExpensesStatusNoVisit;
    default:
      return status;
  }
}

Color monthlyExpenseStatusColor(BuildContext context, String status) {
  switch (status) {
    case MonthlyExpenseStatus.paid:
      return Colors.green;
    case MonthlyExpenseStatus.partial:
      return Colors.orange;
    case MonthlyExpenseStatus.unpaid:
      return Colors.red;
    case MonthlyExpenseStatus.overpaid:
      // Purple, not green: overpaid is not "extra paid", it is a discrepancy
      // worth looking at — usually an Auto Repeat draft submitted in Desk on
      // top of a payment made here.
      return Colors.purple;
    case MonthlyExpenseStatus.noVisit:
      return Colors.grey;
    case MonthlyExpenseStatus.awaitingVisit:
    case MonthlyExpenseStatus.notDue:
    default:
      return Colors.blueGrey;
  }
}

IconData monthlyExpenseStatusIcon(String status) {
  switch (status) {
    case MonthlyExpenseStatus.paid:
      return Icons.check_circle;
    case MonthlyExpenseStatus.partial:
      return Icons.timelapse;
    case MonthlyExpenseStatus.unpaid:
      return Icons.error_outline;
    case MonthlyExpenseStatus.overpaid:
      return Icons.priority_high;
    case MonthlyExpenseStatus.awaitingVisit:
      return Icons.schedule;
    case MonthlyExpenseStatus.noVisit:
      return Icons.event_busy;
    case MonthlyExpenseStatus.notDue:
    default:
      return Icons.event_available;
  }
}

/// A small pill. Shared by the recurring cards and the salary rows so the two
/// halves of the screen never label the same state two different ways.
class MonthlyExpenseStatusChip extends StatelessWidget {
  final String status;

  /// A second pill rendered in the same style, used for the registry lifecycle
  /// (Paused / Ended) and for the `inferred` / `shared_account` disclosures.
  final Color? overrideColor;
  final String? overrideLabel;
  final IconData? icon;

  const MonthlyExpenseStatusChip({
    super.key,
    required this.status,
    this.overrideColor,
    this.overrideLabel,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final label = overrideLabel ?? localizedMonthlyExpenseStatus(context, status);
    final color = overrideColor ?? monthlyExpenseStatusColor(context, status);
    final chipIcon = icon ?? monthlyExpenseStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
