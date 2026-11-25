import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../calendar/state/cairo_format.dart';
import '../../calendar/state/cairo_time.dart';
import '../../settings/data/settings_repository.dart';
import '../pieces_strings.dart';
import 'piece_widgets.dart';

/// A dropdown where the first entry is "none".
class OptionDropdown<T> extends StatelessWidget {
  const OptionDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.noneLabel,
    this.errorText,
  });

  final String label;
  final T? value;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;

  /// Text of the empty choice; null means no empty choice.
  final String? noneLabel;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.md),
      child: DropdownButtonFormField<T?>(
        initialValue: items.any((i) => i.$1 == value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, errorText: errorText),
        items: [
          if (noneLabel != null)
            DropdownMenuItem<T?>(value: null, child: Text(noneLabel!)),
          for (final i in items)
            DropdownMenuItem<T?>(value: i.$1, child: Text(i.$2)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// A plain text field with the form's spacing.
class FormText extends StatelessWidget {
  const FormText({
    super.key,
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.errorText,
    this.rtl = false,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final String? errorText;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.md),
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: maxLines,
        textDirection: rtl ? TextDirection.rtl : null,
        decoration: InputDecoration(labelText: label, errorText: errorText),
      ),
    );
  }
}

/// A date shown in words, with a picker and a clear button.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;

  /// `2026-11-26` or null.
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    final d = CairoTime.parse(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.event_outlined),
              label: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  d == null
                      ? '$label: ${s.pickDate}'
                      : '$label: ${CairoFormat.full(d, isArabic(context))}',
                ),
              ),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: d ?? now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 3),
                );
                if (picked != null) onChanged(CairoTime.date(picked));
              },
            ),
          ),
          if (d != null)
            IconButton(
              tooltip: s.clearDate,
              icon: const Icon(Icons.close),
              onPressed: () => onChanged(null),
            ),
        ],
      ),
    );
  }
}

/// Owner choice: a person (`p:kareem`) or a team (`t:creators`, `t:claude`).
class OwnerDropdown extends ConsumerWidget {
  const OwnerDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowTeams = true,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool allowTeams;

  /// Decodes the dropdown value into `(assignee, assigneeTeam)`.
  static (String?, String?) split(String? v) {
    if (v == null) return (null, null);
    if (v.startsWith('p:')) return (v.substring(2), null);
    if (v.startsWith('t:')) return (null, v.substring(2));
    return (null, null);
  }

  /// The dropdown value of a piece's current owner.
  static String? of(PersonRef? assignee, OwnerTeam? team) {
    if (assignee != null) return 'p:${assignee.key}';
    if (team != null && team != OwnerTeam.unknown) return 't:${team.wire}';
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = PiecesStrings.of(context);
    final people = ref.watch(peopleProvider).valueOrNull ?? const [];
    return OptionDropdown<String>(
      label: s.fieldOwner,
      value: value,
      noneLabel: s.nobodyYet,
      items: [
        if (allowTeams) ...[
          ('t:${OwnerTeam.creators.wire}', s.ownerCreators),
          ('t:${OwnerTeam.claude.wire}', s.ownerClaude),
        ],
        for (final p in people.where((p) => p.enabled))
          ('p:${p.key}', p.fullName),
      ],
      onChanged: onChanged,
    );
  }
}

/// Flavours as chips you tick.
class FlavourChips extends ConsumerWidget {
  const FlavourChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = PiecesStrings.of(context);
    final flavours = ref.watch(flavoursProvider).valueOrNull ?? const [];
    if (flavours.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.fieldFlavours, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: StudioSpacing.xs),
          Wrap(
            spacing: StudioSpacing.sm,
            children: [
              for (final f in flavours)
                FilterChip(
                  key: ValueKey('flavour-${f.id}'),
                  label: Text(f.name),
                  selected: selected.contains(f.id),
                  onSelected: (on) {
                    final next = {...selected};
                    on ? next.add(f.id) : next.remove(f.id);
                    onChanged(next);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
