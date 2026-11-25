import 'package:flutter/material.dart';

String? _textOf(Widget label) => label is Text ? label.data : null;

/// A chip that picks one of a set (a filter, a tab, a sort). A screen reader
/// hears a button that is selected or not, not a checkbox: only a real on/off
/// switch (FilterChip) stays a toggle.
class StudioChoiceChip extends StatelessWidget {
  const StudioChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.avatar,
  });

  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: onSelected != null,
    label: _textOf(label),
    onTap: onSelected == null ? null : () => onSelected!(!selected),
    excludeSemantics: _textOf(label) != null,
    child: ChoiceChip(
      avatar: avatar,
      label: label,
      selected: selected,
      onSelected: onSelected,
    ),
  );
}

/// A chip that does something when tapped: announced as a button.
class StudioActionChip extends StatelessWidget {
  const StudioActionChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.avatar,
    this.visualDensity,
  });

  final Widget label;
  final VoidCallback? onPressed;
  final Widget? avatar;
  final VisualDensity? visualDensity;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: _textOf(label),
    onTap: onPressed,
    excludeSemantics: _textOf(label) != null,
    child: ActionChip(
      avatar: avatar,
      label: label,
      visualDensity: visualDensity,
      onPressed: onPressed,
    ),
  );
}

/// A chip that only names something (a format, a level, a flavour): plain
/// text to a screen reader, not a checkbox and not a button.
class StudioLabelChip extends StatelessWidget {
  const StudioLabelChip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    label: text,
    excludeSemantics: true,
    child: Chip(label: Text(text)),
  );
}
