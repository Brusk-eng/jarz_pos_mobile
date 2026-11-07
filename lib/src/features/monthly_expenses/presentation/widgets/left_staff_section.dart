import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../models/monthly_expense_models.dart';

/// People who have LEFT the company but still owe an advance or a staff order.
///
/// They used to sit among the salaries as "Off payroll" rows, which made a
/// month's payroll look longer than it is and invited paying someone who is no
/// longer employed. They now live here, at the end of the screen, collapsed by
/// default — out of the way, but the debt is still one tap from view and every
/// card keeps its actions (settle, penalty, cancel).
///
/// Renders nothing when [rows] is empty.
class LeftStaffSection extends StatelessWidget {
  final List<SalaryRow> rows;

  /// Builds the card for one row. Supplied by the screen so a left employee's
  /// card is wired to exactly the same pay / penalty / cancel handlers as an
  /// active employee's.
  final Widget Function(SalaryRow row) cardBuilder;

  const LeftStaffSection({
    super.key,
    required this.rows,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const PageStorageKey<String>('monthly-expenses-left-staff'),
        initiallyExpanded: false,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        leading: Icon(
          Icons.person_off_outlined,
          color: theme.colorScheme.error,
        ),
        title: Text(
          l10n.monthlyExpensesLeftStaffTitle(rows.length),
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          l10n.monthlyExpensesLeftStaffHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          for (final row in rows) cardBuilder(row),
        ],
      ),
    );
  }
}
