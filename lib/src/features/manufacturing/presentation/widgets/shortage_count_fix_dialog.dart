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
/// The count is dated a few minutes before production by default. When
/// [recount] is given, "Change date" lets the user date it EARLIER (the
/// miscount usually happened at an earlier count); [recount] asks the server
/// for the plan at that moment, so the balances shown are the ones posted.
///
/// Returns null when cancelled. Otherwise the confirmed choice: its
/// [ShortageCountChoice.countAt] is null for the default moment.
Future<ShortageCountChoice?> confirmShortageCountFix(
  BuildContext context,
  ShortageCountPlan plan, {
  Future<ShortageCountPlan> Function(String countAt)? recount,
}) {
  return showDialog<ShortageCountChoice>(
    context: context,
    builder: (dialogContext) =>
        _ShortageCountFixDialog(plan: plan, recount: recount),
  );
}

/// What the user confirmed in the dialog.
class ShortageCountChoice {
  const ShortageCountChoice({this.countAt});

  /// "YYYY-MM-DD HH:MM:SS" the user chose, or null for the default moment.
  final String? countAt;
}

/// Parses the server's "YYYY-MM-DD HH:MM:SS" (null when malformed).
DateTime? parseShortageMoment(String raw) =>
    DateTime.tryParse(raw.trim().replaceFirst(' ', 'T'));

String _two(int v) => v.toString().padLeft(2, '0');

/// "YYYY-MM-DD HH:MM:00": whole minutes, the server's clock format.
String formatShortageMoment(DateTime d) =>
    '${d.year}-${_two(d.month)}-${_two(d.day)} '
    '${_two(d.hour)}:${_two(d.minute)}:00';

class _ShortageCountFixDialog extends StatefulWidget {
  const _ShortageCountFixDialog({required this.plan, this.recount});

  final ShortageCountPlan plan;
  final Future<ShortageCountPlan> Function(String countAt)? recount;

  @override
  State<_ShortageCountFixDialog> createState() =>
      _ShortageCountFixDialogState();
}

class _ShortageCountFixDialogState extends State<_ShortageCountFixDialog> {
  bool _confirmed = false;
  late ShortageCountPlan _plan = widget.plan;

  /// The moment the user picked; null while the default is in use.
  String? _chosen;
  bool _loading = false;
  String? _error;

  Future<void> _changeDate() async {
    if (widget.recount == null) return;
    final latest = parseShortageMoment(_plan.latestCountAt);
    final current = parseShortageMoment(_plan.countAt) ?? latest;
    if (latest == null || current == null) return;

    final day = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: latest.subtract(const Duration(days: 120)),
      lastDate: latest,
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;

    var picked = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    // Never past the default moment: the server would refuse it.
    final latestMinute = DateTime(
      latest.year,
      latest.month,
      latest.day,
      latest.hour,
      latest.minute,
    );
    if (picked.isAfter(latestMinute)) picked = latestMinute;
    await _recount(formatShortageMoment(picked));
  }

  /// Re-asks the server for the plan at [countAt] (null: the default).
  Future<void> _recount(String? countAt) async {
    final recount = widget.recount;
    if (recount == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final next = await recount(countAt ?? widget.plan.latestCountAt);
      if (!mounted) return;
      setState(() {
        _plan = next;
        _chosen = countAt;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = ShortageFixStrings.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plan = _plan;
    final blocked = plan.laterCounts.isNotEmpty || plan.items.isEmpty;

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
                _chosen == null
                    ? t.when(
                        shortageCountMoment(plan.countAt),
                        shortageCountMoment(plan.productionAt),
                      )
                    : t.chosenWhen(
                        shortageCountMoment(plan.countAt),
                        shortageCountMoment(plan.productionAt),
                      ),
                style: theme.textTheme.bodyMedium,
              ),
              if (widget.recount != null)
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      key: const ValueKey('shortage-change-date'),
                      onPressed: _loading ? null : _changeDate,
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(t.changeDate),
                    ),
                    if (_chosen != null)
                      TextButton(
                        onPressed: _loading ? null : () => _recount(null),
                        child: Text(t.useDefaultDate),
                      ),
                  ],
                ),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ),
              for (final later in plan.laterCounts)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    t.laterCount(
                      later.itemCode,
                      shortageCountMoment(later.postedAt),
                      later.stockReconciliation,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ),
              if (plan.items.isEmpty && !_loading)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(t.nothing),
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _confirmed && !_loading && !blocked
              ? () => Navigator.of(
                  context,
                ).pop(ShortageCountChoice(countAt: _chosen))
              : null,
          child: Text(t.submit),
        ),
      ],
    );
  }
}
