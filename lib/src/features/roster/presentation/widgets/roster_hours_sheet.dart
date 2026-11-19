import 'package:jarz_pos/src/core/localization/user_error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../models/roster_models.dart';
import '../../state/roster_filter.dart';
import '../roster_cell_style.dart';
import '../roster_formats.dart';

/// The month's hours, as payroll reads them.
Future<void> showRosterHoursSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const RosterHoursSheet(),
  );
}

class RosterHoursSheet extends ConsumerWidget {
  const RosterHoursSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Narrowed to the people the grid's filter shows, totals re-added.
    final hoursAsync = ref.watch(rosterVisibleHoursProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: hoursAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text(context.userErrorMessage(error))),
          data: (hours) => ListView(
            controller: controller,
            children: [
              Text(
                l10n.rosterHoursTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                // Says outright where the number comes from. Auto-attendance is
                // off, so these are rostered hours, not clocked hours — and
                // somebody will eventually ask why they differ from the
                // check-in log.
                l10n.rosterHoursBasis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _Totals(hours: hours),
              const SizedBox(height: 16),
              if (hours.rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text(l10n.rosterNobodyRostered)),
                )
              else
                ...hours.rows.map((row) => _HoursRowTile(row: row)),
              SizedBox(
                height: 24 + MediaQuery.paddingOf(context).bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.hours});

  final RosterHours hours;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Metric(
            label: l10n.rosterWorkedHours,
            value: rosterNumber(context, hours.totalWorkedHours),
          ),
          _Metric(
            label: l10n.rosterOvertimeHours,
            value: rosterNumber(context, hours.totalOvertimeHours),
          ),
          _Metric(
            label: l10n.rosterCreditedHours,
            value: rosterNumber(context, hours.totalCreditedHours),
            emphasise: true,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: emphasise ? theme.colorScheme.primary : null,
          ),
        ),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _HoursRowTile extends StatelessWidget {
  const _HoursRowTile({required this.row});

  final RosterHoursRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hasOvertime = row.overtimeHours > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.employeeName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (row.isCourier)
                  // The 2x multiplier is the single biggest number on this
                  // sheet and it used to arrive as an unstyled default Chip,
                  // indistinguishable from decoration.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: RosterColors.markerChip,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: RosterColors.markerInk),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.two_wheeler,
                          size: 13,
                          color: RosterColors.markerInk,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.rosterCourierTag(
                            rosterNumber(context, row.overtimeMultiplier),
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: RosterColors.markerInk,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.rosterRowDays(row.workedDays, row.offDays, row.coverDays),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _Pill(
                  label: l10n.rosterWorkedHours,
                  value: rosterNumber(context, row.workedHours),
                ),
                if (hasOvertime)
                  _Pill(
                    label: l10n.rosterOvertimeHours,
                    value: rosterNumber(context, row.overtimeHours),
                  ),
                if (hasOvertime)
                  _Pill(
                    label: l10n.rosterCreditedOvertime,
                    value: rosterNumber(context, row.creditedOvertimeHours),
                    highlight: true,
                  ),
                _Pill(
                  label: l10n.rosterCreditedHours,
                  value: rosterNumber(context, row.creditedHours),
                  highlight: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $value',
        style: theme.textTheme.labelSmall?.copyWith(
          color: highlight ? theme.colorScheme.onPrimaryContainer : null,
          fontWeight: highlight ? FontWeight.w700 : null,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
