import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/studio_tokens.dart';
import '../../data/paging.dart';
import '../../data/studio_error.dart';
import '../../shared/how_this_works_sheet.dart';
import '../../shared/media/studio_media_widgets.dart';
import 'more_strings.dart';
import '../../shared/studio_toast.dart';
import '../../core/l10n/studio_strings.dart';

/// The sentence for a failed write, in plain words. VALIDATION shows the
/// server's own message (it names the field); every other code has its own
/// sentence.
String moreErrorText(MoreStrings t, Object error) {
  return switch (error) {
    StudioShadowMode _ => t.errShadow,
    StudioStale _ => t.errStale,
    StudioNotPermitted _ => t.errNotPermitted,
    StudioAlreadyDone _ => t.errAlreadyDone,
    StudioNetworkError _ => t.errNetwork,
    StudioNotFound _ => t.errNotFound,
    StudioValidation e when e.message.isNotEmpty => e.message,
    StudioGateFailed e when e.message.isNotEmpty => e.message,
    _ => t.errGeneric,
  };
}

/// Shows [text] as a toast on the root messenger.
void showMoreSnack(String text) => showStudioToast(text);

/// Runs a write: on success returns true (and shows [okText] when given); on
/// failure shows the error in plain words and returns false. A `STALE` or
/// `ALREADY_DONE` answer has already been taken into state by the notifier.
Future<bool> runMoreWrite(
  BuildContext context,
  Future<void> Function() call, {
  String? okText,
}) async {
  final t = MoreStrings.of(context);
  try {
    await call();
    if (okText != null) showMoreSnack(okText);
    return true;
  } catch (e) {
    showMoreSnack(moreErrorText(t, e));
    return false;
  }
}

/// The "?" in the app bar: this screen's "how this works" sheet.
Widget moreHelpAction(
  BuildContext context, {
  required String title,
  required List<String> lines,
}) {
  final t = MoreStrings.of(context);
  return IconButton(
    key: const ValueKey('help'),
    tooltip: t.howThisWorks,
    icon: const Icon(Icons.help_outline),
    onPressed: () =>
        HowThisWorksSheet.show(context, title: title, lines: lines),
  );
}

/// Keeps a screen readable on a wide window: centred, at most [maxWidth].
class MoreBody extends StatelessWidget {
  const MoreBody({super.key, required this.child, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Small caps label above a block.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      StudioSpacing.gutter,
      StudioSpacing.lg,
      StudioSpacing.gutter,
      StudioSpacing.sm,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: StudioColors.plumMuted,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// A small coloured pill with plain text.
class MorePill extends StatelessWidget {
  const MorePill(
    this.text, {
    super.key,
    this.foreground = StudioColors.deepPlum,
    this.background = StudioColors.softBlush,
  });

  final String text;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: StudioSpacing.md,
      vertical: StudioSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(StudioRadii.pill),
    ),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: foreground),
    ),
  );
}

/// A white card with the Studio border, used for list rows.
class MoreCard extends StatelessWidget {
  const MoreCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: StudioSpacing.gutter,
      vertical: StudioSpacing.xs,
    ),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioRadii.md),
        side: const BorderSide(color: StudioColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(StudioSpacing.md),
          child: child,
        ),
      ),
    ),
  );
}

/// "Label    value" on one row.
class LabeledValue extends StatelessWidget {
  const LabeledValue(this.label, this.value, {super.key, this.emphasise});

  final String label;
  final String value;
  final bool? emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: StudioSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          const SizedBox(width: StudioSpacing.md),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: emphasise == true
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// The end of a cursor-paged list: a "show more" button while there is a next
/// page, and a "try again" line when loading more failed.
class ShowMoreFooter extends StatefulWidget {
  const ShowMoreFooter({super.key, required this.state, required this.onMore});

  final PagedState<dynamic> state;
  final Future<void> Function() onMore;

  @override
  State<ShowMoreFooter> createState() => _ShowMoreFooterState();
}

class _ShowMoreFooterState extends State<ShowMoreFooter> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.state.hasMore) return const SizedBox(height: StudioSpacing.xl);
    final t = MoreStrings.of(context);
    return Padding(
      padding: const EdgeInsets.all(StudioSpacing.gutter),
      child: Column(
        children: [
          if (_failed)
            Padding(
              padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
              child: Text(
                t.showMoreFailed,
                key: const ValueKey('show-more-failed'),
                style: const TextStyle(color: StudioColors.danger),
              ),
            ),
          OutlinedButton(
            key: const ValueKey('show-more'),
            onPressed: widget.state.loadingMore
                ? null
                : () async {
                    setState(() => _failed = false);
                    try {
                      await widget.onMore();
                    } catch (_) {
                      if (mounted) setState(() => _failed = true);
                    }
                  },
            child: widget.state.loadingMore
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.showMore),
          ),
        ],
      ),
    );
  }
}

/// A search field that reports the text when the person submits it, and has a
/// clear button.
class MoreSearchField extends StatefulWidget {
  const MoreSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.initial = '',
    this.liveChange = false,
  });

  final String hint;
  final String initial;
  final ValueChanged<String> onChanged;

  /// Report on every keystroke (client-side filters) instead of on submit.
  final bool liveChange;

  @override
  State<MoreSearchField> createState() => _MoreSearchFieldState();
}

class _MoreSearchFieldState extends State<MoreSearchField> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StudioSpacing.gutter,
        StudioSpacing.sm,
        StudioSpacing.gutter,
        StudioSpacing.xs,
      ),
      child: TextField(
        key: const ValueKey('search-field'),
        controller: _c,
        textInputAction: TextInputAction.search,
        onChanged: widget.liveChange ? widget.onChanged : null,
        onSubmitted: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hint,
          isDense: true,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ListenableBuilder(
            listenable: _c,
            builder: (context, _) => _c.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    key: const ValueKey('search-clear'),
                    tooltip: StudioStrings.of(context).clear,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _c.clear();
                      widget.onChanged('');
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

/// A row of single-choice chips; [value] null means "All".
class ChoiceChipRow<T> extends StatelessWidget {
  const ChoiceChipRow({
    super.key,
    required this.options,
    required this.value,
    required this.labelOf,
    required this.onChanged,
    this.allLabel,
  });

  final List<T> options;
  final T? value;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final String? allLabel;

  @override
  Widget build(BuildContext context) {
    final t = MoreStrings.of(context);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: StudioSpacing.gutter,
          vertical: StudioSpacing.xs,
        ),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: StudioSpacing.sm),
            child: ChoiceChip(
              key: const ValueKey('chip-all'),
              label: Text(allLabel ?? t.all),
              selected: value == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          for (final o in options)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: StudioSpacing.sm),
              child: ChoiceChip(
                key: ValueKey('chip-${labelOf(o)}'),
                label: Text(labelOf(o)),
                selected: value == o,
                onSelected: (_) => onChanged(o),
              ),
            ),
        ],
      ),
    );
  }
}

/// Asks for a line of text. Returns null when cancelled. [required] keeps the
/// button off until something is typed.
Future<String?> askForText(
  BuildContext context, {
  required String title,
  String? hint,
  String confirm = '',
  bool required = false,
  String initial = '',
  int maxLines = 4,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _TextDialog(
      title: title,
      hint: hint,
      confirm: confirm,
      required: required,
      initial: initial,
      maxLines: maxLines,
    ),
  );
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.hint,
    required this.confirm,
    required this.required,
    required this.initial,
    required this.maxLines,
  });

  final String title;
  final String? hint;
  final String confirm;
  final bool required;
  final String initial;
  final int maxLines;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = MoreStrings.of(context);
    return AlertDialog(
      key: const ValueKey('text-dialog'),
      title: Text(widget.title),
      content: TextField(
        key: const ValueKey('text-dialog-field'),
        controller: _c,
        autofocus: true,
        minLines: 1,
        maxLines: widget.maxLines,
        decoration: InputDecoration(hintText: widget.hint),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          key: const ValueKey('text-dialog-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        FilledButton(
          key: const ValueKey('text-dialog-confirm'),
          onPressed: widget.required && _c.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_c.text.trim()),
          child: Text(widget.confirm.isEmpty ? t.save : widget.confirm),
        ),
      ],
    );
  }
}

/// Opens [url] outside the app. Tells the person when it could not.
Future<void> openMoreLink(
  BuildContext context,
  WidgetRef ref,
  String url,
) async {
  final t = MoreStrings.of(context);
  final uri = Uri.tryParse(url);
  var ok = false;
  if (uri != null) {
    try {
      ok = await ref.read(studioLinkOpenerProvider)(uri);
    } catch (_) {}
  }
  if (!ok) showMoreSnack(t.couldNotOpen);
}

/// Turns "avg_watch_s" into "Avg watch s" (for fields the contract names
/// but this app has no word for yet).
String humanizeKey(String key) {
  final s = key.replaceAll('_', ' ').trim();
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Today's date as `YYYY-MM-DD`.
String todayIso([DateTime? now]) {
  final d = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

String isoDate(DateTime d) => todayIso(d);
