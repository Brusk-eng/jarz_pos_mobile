import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../manager/presentation/sync_staff_customers_action.dart';
import '../../models/monthly_expense_models.dart';
import 'salary_row_card.dart';

/// Unpaid staff (Employee-purpose) orders whose customer is linked to no
/// employee. They reach no salary row, so without this card the debt is
/// invisible. The sync action links staff customers to employees, which is what
/// clears these orphans.
class UnattributedOrdersCard extends StatelessWidget {
  final List<EmployeeOrderEntry> orders;
  final double total;
  final String currency;

  /// Called after a successful staff-customer sync, to refetch the month.
  final VoidCallback? onSynced;

  const UnattributedOrdersCard({
    super.key,
    required this.orders,
    required this.total,
    required this.currency,
    this.onSynced,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // Group by customer, keeping first-seen order.
    final groups = <String, List<EmployeeOrderEntry>>{};
    for (final order in orders) {
      groups.putIfAbsent(order.displayCustomer, () => []).add(order);
    }

    return Card(
      key: const ValueKey('unattributed-orders-card'),
      elevation: 0,
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(
            Icons.person_off_outlined,
            color: theme.colorScheme.error,
          ),
          title: Text(
            l10n.monthlyExpensesUnattributedTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            l10n.monthlyExpensesUnattributedSummary(
              orders.length,
              formatCurrency(context, total, currencyCode: currency),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.monthlyExpensesUnattributedHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SyncStaffCustomersAction(onSynced: onSynced),
            const SizedBox(height: 12),
            for (final entry in groups.entries) ...[
              Text(
                entry.key,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              for (final order in entry.value)
                StaffOrderLine(
                  order: order,
                  currency: currency,
                  showCustomer: false,
                ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}
