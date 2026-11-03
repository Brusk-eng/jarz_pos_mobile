import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../models/roster_models.dart';
import '../roster_formats.dart';
import '../roster_shift_filter.dart';

/// The list of shift types to roster onto, shared by the single-day sheet and
/// the bulk bar.
///
/// There used to be two copies (`_ShiftPicker` in the day sheet and
/// `_BulkShiftPicker` in the bulk bar) that had already drifted apart.
///
/// Each shift is its name and its time window — no colour swatch. Colour on
/// the roster means "needs fixing" and nothing else, so it never says which
/// shift a day is; the grid writes the time, and so does the picker.
///
/// Given an [employee], it lists only that person's shifts (see
/// [rosterShiftsFor]) with a "Show all shifts" escape hatch underneath, for
/// the rare day somebody works outside their usual group.
class RosterShiftPicker extends StatefulWidget {
  const RosterShiftPicker({
    super.key,
    required this.catalog,
    required this.onPick,
    this.employee,
    this.dates = const [],
    this.selected,
    this.allowReselect = false,
    this.maxHeight = 260,
  });

  final List<RosterShift> catalog;
  final ValueChanged<RosterShift> onPick;

  /// Whose day(s) are being changed. Null shows the whole catalog.
  final RosterEmployee? employee;

  /// The ISO dates being changed; decides whether the Friday variants show.
  final Iterable<String> dates;

  /// The shift the day is already on, if any. It is marked and not tappable:
  /// re-assigning the same shift would be a write that changes nothing.
  final String? selected;

  /// Keep [selected] tappable. A repeating change ("Repeat every {weekday}")
  /// or a branch move is a real write even onto the shift the day already has.
  final bool allowReselect;
  final double maxHeight;

  @override
  State<RosterShiftPicker> createState() => _RosterShiftPickerState();
}

class _RosterShiftPickerState extends State<RosterShiftPicker> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final full = widget.catalog;
    final mine = rosterShiftsFor(
      widget.employee,
      full,
      dates: widget.dates,
      selected: widget.selected,
    );
    final narrowed = mine.length < full.length;
    final catalog = _showAll || !narrowed ? full : mine;
    final selected = widget.selected;
    final onPick = widget.onPick;
    final maxHeight = widget.maxHeight;

    if (catalog.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(context.l10n.rosterNoShiftTypes),
      );
    }
    final list = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: catalog.length,
        itemBuilder: (context, index) {
          final shift = catalog[index];
          final isSelected = shift.shiftType == selected;
          return ListTile(
            dense: true,
            selected: isSelected,
            title: Text(shift.shiftType),
            subtitle: Text(
              context.l10n.rosterShiftWindow(
                shift.window,
                rosterNumber(context, shift.hours),
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, size: 20)
                : null,
            onTap: isSelected && !widget.allowReselect
                ? null
                : () => onPick(shift),
          );
        },
      ),
    );
    if (!narrowed) return list;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        list,
        TextButton.icon(
          key: rosterShowAllShiftsKey,
          onPressed: () => setState(() => _showAll = !_showAll),
          icon: Icon(
            _showAll ? Icons.filter_list : Icons.unfold_more,
            size: 18,
          ),
          label: Text(
            _showAll
                ? context.l10n.rosterShowMyShifts
                : context.l10n.rosterShowAllShifts(full.length),
          ),
        ),
      ],
    );
  }
}

const rosterShowAllShiftsKey = ValueKey('roster-show-all-shifts');

/// [RosterShiftPicker] in its own bottom sheet, resolving to the pick (or
/// null when dismissed). Used by the bulk bar.
Future<RosterShift?> showRosterShiftPickerSheet(
  BuildContext context, {
  required String title,
  required List<RosterShift> catalog,
  RosterEmployee? employee,
  Iterable<String> dates = const [],
}) {
  return showModalBottomSheet<RosterShift>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                sheetContext,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            RosterShiftPicker(
              catalog: catalog,
              employee: employee,
              dates: dates,
              maxHeight: 320,
              onPick: (shift) => Navigator.of(sheetContext).pop(shift),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
