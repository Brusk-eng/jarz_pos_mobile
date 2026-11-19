import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../state/lead_filter.dart';
import '../leads_theme.dart';

/// Multi-select area picker.
///
/// Replaces a single-choice dropdown, because a rep works several
/// neighbourhoods in one trip and had to re-filter for each. A dropdown cannot
/// express that, and with a catalog this size the list is long enough that a
/// plain menu of checkboxes would not be usable either — hence the search box
/// and the selected-first ordering.
///
/// Selection is applied live rather than on a Done button: the list behind the
/// sheet updates as areas are ticked, which is what tells a rep whether they
/// have picked the right ones.
class AreaPickerSheet extends ConsumerStatefulWidget {
  const AreaPickerSheet({super.key, required this.areas});

  /// Every area present in the catalog, already sorted.
  final List<String> areas;

  static Future<void> show(BuildContext context, List<String> areas) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LeadsTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AreaPickerSheet(areas: areas),
    );
  }

  @override
  ConsumerState<AreaPickerSheet> createState() => _AreaPickerSheetState();
}

class _AreaPickerSheetState extends ConsumerState<AreaPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(leadFilterProvider).selectedAreas;
    final notifier = ref.read(leadFilterProvider.notifier);

    final query = _query.trim().toLowerCase();
    final matching = query.isEmpty
        ? widget.areas
        : widget.areas
            .where((a) => a.toLowerCase().contains(query))
            .toList();

    // Ticked areas float to the top, so what is currently applied is visible
    // without scrolling a long list to find it.
    final ordered = [
      ...matching.where(selected.contains),
      ...matching.where((a) => !selected.contains(a)),
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: LeadsTheme.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(context.l10n.leadsFilterAreas, style: LeadsTheme.heading),
                const Spacer(),
                if (selected.isNotEmpty)
                  TextButton(
                    onPressed: notifier.clearAreas,
                    style: TextButton.styleFrom(
                      foregroundColor: LeadsTheme.berryPink,
                    ),
                    child: Text(
                        context.l10n.leadsAreaClearCount(selected.length)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              style: LeadsTheme.body,
              decoration: InputDecoration(
                hintText: context.l10n.leadsAreaSearchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: LeadsTheme.line),
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ordered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          context.l10n.leadsAreaNoMatch(_query),
                          style: LeadsTheme.bodyMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: ordered.length,
                      itemBuilder: (context, index) {
                        final area = ordered[index];
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: LeadsTheme.berryPink,
                          value: selected.contains(area),
                          title: Text(area, style: LeadsTheme.body),
                          onChanged: (_) => notifier.toggleArea(area),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: LeadsTheme.berryPink,
                ),
                child: Text(context.l10n.leadsFilterDone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The button that opens [AreaPickerSheet], labelled with the current choice.
class AreaFilterButton extends ConsumerWidget {
  const AreaFilterButton({super.key, required this.areas});

  final List<String> areas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(leadFilterProvider).selectedAreas;

    // Name the one area when there is one — "1 area" would be strictly less
    // information than the area's own name for the same width.
    final label = switch (selected.length) {
      0 => context.l10n.leadsAreaAll,
      1 => selected.first,
      _ => context.l10n.leadsAreaSelectedCount(selected.length),
    };

    return TextButton.icon(
      onPressed: () => AreaPickerSheet.show(context, areas),
      icon: const Icon(Icons.place_outlined, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LeadsTheme.body.copyWith(
                fontWeight:
                    selected.isEmpty ? FontWeight.w400 : FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.expand_more, size: 18),
        ],
      ),
      style: TextButton.styleFrom(
        foregroundColor:
            selected.isEmpty ? LeadsTheme.muted : LeadsTheme.deepPlum,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
