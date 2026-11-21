import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/models/shortage_count_plan.dart';
import 'production_format.dart';
import 'shortage_fix_strings.dart';

/// "16:55 · 2026-11-20" from the server's "2026-11-20 16:55:00".
String shortageCountMoment(String raw) {
  final parts = raw.trim().split(' ');
  if (parts.length < 2) return raw;
  final time = parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1];
  return '$time · ${parts[0]}';
}

/// The one confirmation before the shortage is added as a stock count.
///
/// Lists every item and the quantity being added, the moment the count
/// posts (a few minutes before production), and asks the user to state that
/// the stock was COUNTED WRONG — not a base nobody produced, not a purchase
/// invoice nobody entered. Those two have their own fixes, and covering them
/// with a count would hide a real gap in the books. Confirm stays disabled
/// until the statement is ticked.
///
/// Returns true only when the user confirmed.
Future<bool> confirmShortageCountFix(
  BuildContext context,
  ShortageCountPlan plan,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _ShortageCountFixDialog(plan: plan),
  );
  return result ?? false;
}

class _ShortageCountFixDialog extends StatefulWidget {
  const _ShortageCountFixDialog({required this.plan});

  final ShortageCountPlan plan;

  @override
  State<_ShortageCountFixDialog> createState() =>
      _ShortageCountFixDialogState();
}

class _ShortageCountFixDialogState extends State<_ShortageCountFixDialog> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = ShortageFixStrings.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plan = widget.plan;

    return AlertDialog(
      title: Text(t.title),
      content: SizedBox(
        width: ResponsiveUtils.getDialogWidth(
          context,
          small: 340,
          medium: 440,
          large: 520,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.when(
                  shortageCountMoment(plan.countAt),
                  shortageCountMoment(plan.productionAt),
                ),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final item in plan.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              item.warehouse,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${trimQty(item.missingQty, decimals: 3)} ${item.uom}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                          Text(
                            t.becomes(
                              trimQty(item.currentQty, decimals: 3),
                              trimQty(item.countedQty, decimals: 3),
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (plan.skippedCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  t.skipped(plan.skippedCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _confirmed,
                onChanged: (v) => setState(() => _confirmed = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  t.confirmCheck,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _confirmed ? () => Navigator.of(context).pop(true) : null,
          child: Text(t.submit),
        ),
      ],
    );
  }
}
