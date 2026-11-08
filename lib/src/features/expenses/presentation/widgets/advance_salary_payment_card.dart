import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../models/employee_advance_models.dart';

/// Read-only card for salary a manager paid out from the Monthly Expenses
/// board. Deliberately has no actions: there is nothing to approve here.
class AdvanceSalaryPaymentCard extends StatelessWidget {
  final AdvanceSalaryPayment payment;

  const AdvanceSalaryPaymentCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final source = payment.localizedPaymentLabel(languageCode);

    // Formatted here, in the app's locale, like EmployeeAdvanceCard: the
    // server's label is always English. It is only the fallback.
    final day = salaryMonthDate(payment.salaryMonth);
    String? monthLabel =
        day == null ? null : formatDate(context, day, pattern: 'MMMM yyyy');
    if (monthLabel == null && (payment.salaryMonthLabel ?? '').isNotEmpty) {
      monthLabel = payment.salaryMonthLabel;
    }
    final paidBy = payment.paidByName ?? payment.paidBy;
    final remarks = payment.remarks;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.teal.withValues(alpha: 0.15),
              child: const Icon(Icons.payments_outlined, color: Colors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          payment.employeeName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        formatCurrency(context, payment.amount,
                            currencyCode: payment.currency),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (payment.postingDate != null)
                        Text(formatDate(context, payment.postingDate!)),
                      if (monthLabel != null)
                        Text(
                          l10n.expensesAdvanceSalaryMonthChip(monthLabel),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (payment.branch != null)
                        Text(
                          payment.branch!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                  if (source.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.expensesAdvancePayFromLabel}: $source',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (paidBy != null && paidBy.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.expensesAdvanceSalaryPaidByValue(paidBy),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                  if (remarks != null && remarks.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(remarks, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
