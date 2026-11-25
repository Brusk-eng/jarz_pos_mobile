import 'package:flutter/material.dart';

import '../core/theme/studio_tokens.dart';
import 'studio_error_text.dart';
import 'studio_tr.dart';

/// One text field of a [StudioFormSheet].
class SheetField {
  const SheetField(
    this.name,
    this.label, {
    this.lines = 1,
    this.ltr = false,
    this.required = false,
    this.initial = '',
    this.keyboard,
  });

  /// The key in the values map, also the widget key `form-<name>`.
  final String name;
  final String label;
  final int lines;

  /// Links and handles read left to right.
  final bool ltr;
  final bool required;
  final String initial;
  final TextInputType? keyboard;
}

/// The one small form in a bottom sheet: some text fields, optional extra
/// widgets (chips, a date) that write into [values], and a save button that
/// shows the server's refusal in words and stays open.
///
/// `onSubmit` gets the trimmed text of every field (empty is `''`) and the
/// extra values; it throws to show an error. The sheet returns true when it
/// saved.
class StudioFormSheet extends StatefulWidget {
  const StudioFormSheet({
    super.key,
    required this.title,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    this.intro,
    this.extra,
    this.initialValues = const {},
    this.validate,
  });

  final String title;
  final String? intro;
  final List<SheetField> fields;
  final String submitLabel;
  final Future<void> Function(Map<String, String> values) onSubmit;

  /// Extra widgets under the fields; [values] is the live map they write to.
  final Widget Function(
    BuildContext context,
    Map<String, String> values,
    VoidCallback rebuild,
  )?
  extra;
  final Map<String, String> initialValues;

  /// A message when the values are not good enough to send, else null.
  final String? Function(BuildContext context, Map<String, String> values)?
  validate;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required List<SheetField> fields,
    required String submitLabel,
    required Future<void> Function(Map<String, String> values) onSubmit,
    String? intro,
    Widget Function(
      BuildContext context,
      Map<String, String> values,
      VoidCallback rebuild,
    )?
    extra,
    Map<String, String> initialValues = const {},
    String? Function(BuildContext context, Map<String, String> values)?
    validate,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => StudioFormSheet(
      title: title,
      intro: intro,
      fields: fields,
      submitLabel: submitLabel,
      onSubmit: onSubmit,
      extra: extra,
      initialValues: initialValues,
      validate: validate,
    ),
  );

  @override
  State<StudioFormSheet> createState() => _StudioFormSheetState();
}

class _StudioFormSheetState extends State<StudioFormSheet> {
  late final Map<String, TextEditingController> _c = {
    for (final f in widget.fields)
      f.name: TextEditingController(text: f.initial),
  };
  late final Map<String, String> _extra = {...widget.initialValues};
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> _values() => {
    ..._extra,
    for (final e in _c.entries) e.key: e.value.text.trim(),
  };

  Future<void> _save() async {
    final values = _values();
    for (final f in widget.fields) {
      if (f.required && (values[f.name] ?? '').isEmpty) {
        setState(
          () => _error = context.tr('Fill in: ${f.label}', 'اكتب: ${f.label}'),
        );
        return;
      }
    }
    final problem = widget.validate?.call(context, values);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    final nav = Navigator.of(context);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(values);
      nav.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = studioErrorMessage(e, ar: ar);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.gutter,
            0,
            StudioSpacing.gutter,
            StudioSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: theme.textTheme.headlineSmall),
              if (widget.intro != null) ...[
                const SizedBox(height: StudioSpacing.xs),
                Text(widget.intro!, style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: StudioSpacing.md),
              for (final f in widget.fields) ...[
                TextField(
                  key: ValueKey('form-${f.name}'),
                  controller: _c[f.name],
                  minLines: f.lines,
                  maxLines: f.lines == 1 ? 1 : f.lines + 2,
                  keyboardType: f.keyboard,
                  textDirection: f.ltr ? TextDirection.ltr : null,
                  decoration: InputDecoration(
                    labelText: f.required ? '${f.label} *' : f.label,
                  ),
                ),
                const SizedBox(height: StudioSpacing.sm),
              ],
              if (widget.extra != null)
                widget.extra!(context, _extra, () => setState(() {})),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: StudioSpacing.sm),
                  child: Text(
                    _error!,
                    key: const ValueKey('form-error'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: StudioColors.danger,
                    ),
                  ),
                ),
              const SizedBox(height: StudioSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('form-save'),
                  onPressed: _busy ? null : _save,
                  child: Text(widget.submitLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
