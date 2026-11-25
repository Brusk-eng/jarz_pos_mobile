import '../../../shared/studio_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/studio_error.dart';
import '../../inbox/presentation/inbox_strings.dart';
import '../../session/state/studio_session_notifier.dart';
import '../data/ideas_repository.dart';
import 'ideas_strings.dart';
import '../../../shared/studio_error_text.dart';
import '../../../shared/studio_toast.dart';

const _formats = ['reel', 'trial', 'static', 'carousel', 'story'];

/// Asks why an idea is dropped. Returns the reason, or null when cancelled.
Future<String?> showDropReasonDialog(BuildContext context) {
  final t = IdeasStrings.of(context);
  final s = InboxStrings.of(context);
  final controller = TextEditingController();
  String? error;
  return showDialog<String>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => AlertDialog(
        title: Text(t.dropTitle),
        content: TextField(
          key: const ValueKey('drop-reason'),
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: t.dropReasonLabel,
            errorText: error,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(s.cancel)),
          FilledButton(
            key: const ValueKey('drop-confirm'),
            onPressed: () {
              final r = controller.text.trim();
              if (r.isEmpty) {
                setState(() => error = t.dropReasonRequired);
                return;
              }
              Navigator.pop(c, r);
            },
            child: Text(t.drop),
          ),
        ],
      ),
    ),
  );
}

/// The short "bring an idea" form. Returns true when the idea was sent.
Future<bool> showProposeSheet(
  BuildContext context,
  WidgetRef ref, {
  String? sourceReferenceId,
  String? initialTitle,
  String? sourceName,
}) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _IdeaFormSheet(
      idea: null,
      sourceReferenceId: sourceReferenceId,
      initialTitle: initialTitle,
      sourceName: sourceName,
    ),
  );
  return done ?? false;
}

/// The edit form of an open idea. Returns true when saved.
Future<bool> showEditIdeaSheet(
  BuildContext context,
  WidgetRef ref,
  StudioIdea idea,
) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _IdeaFormSheet(idea: idea),
  );
  return done ?? false;
}

class _IdeaFormSheet extends ConsumerStatefulWidget {
  const _IdeaFormSheet({
    required this.idea,
    this.sourceReferenceId,
    this.initialTitle,
    this.sourceName,
  });
  final StudioIdea? idea;

  /// The reference the idea is made from, named in the sheet.
  final String? sourceName;

  /// Set when the idea is made from a reference (`source_reference_id`).
  final String? sourceReferenceId;
  final String? initialTitle;

  @override
  ConsumerState<_IdeaFormSheet> createState() => _IdeaFormSheetState();
}

class _IdeaFormSheetState extends ConsumerState<_IdeaFormSheet> {
  late final _title = TextEditingController(
    text: widget.idea?.title ?? widget.initialTitle ?? '',
  );
  late final _titleAr = TextEditingController(text: widget.idea?.titleAr ?? '');
  late final _hook = TextEditingController(text: widget.idea?.hook ?? '');
  late String? _format = widget.idea?.format == null
      ? null
      : (widget.idea!.format!.name == 'staticValue'
            ? 'static'
            : widget.idea!.format!.name);
  final String _requestId = const Uuid().v4();
  String? _titleError;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _titleAr.dispose();
    _hook.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = IdeasStrings.of(context);
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = t.titleRequired);
      return;
    }
    setState(() => _busy = true);
    final repo = ref.read(ideasRepositoryProvider);
    final nav = Navigator.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    String? text(String v) => v.trim().isEmpty ? null : v.trim();
    try {
      final idea = widget.idea;
      if (idea == null) {
        await repo.propose(
          title: title,
          titleAr: text(_titleAr.text),
          hook: text(_hook.text),
          format: _format,
          sourceReferenceId: widget.sourceReferenceId,
          requestId: _requestId,
        );
      } else {
        await repo.update(idea.id, {
          'title': title,
          'title_ar': text(_titleAr.text),
          'hook': text(_hook.text),
          if (_format != null) 'format': _format,
        }, baseModified: idea.modified);
      }
      if (idea == null) {
        final founder =
            ref.read(studioSessionProvider).valueOrNull?.isFounder ?? false;
        showStudioToast(founder ? t.ideaAddedFounder : t.ideaSent);
      }
      nav.pop(true);
    } catch (e) {
      final gone = e is StudioStale || e is StudioAlreadyDone;
      if (gone) ref.invalidate(ideasProvider);
      showStudioToast(
        studioErrorMessage(e, ar: isAr),
        duration: studioErrorToastDuration,
      );
      if (gone) {
        nav.pop(false);
      } else if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = IdeasStrings.of(context);
    final s = InboxStrings.of(context);
    final editing = widget.idea != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.gutter,
            0,
            StudioSpacing.gutter,
            StudioSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editing ? t.editTitle : t.newIdeaTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (!editing && widget.sourceName != null) ...[
                const SizedBox(height: StudioSpacing.xs),
                Text(
                  t.fromReference(widget.sourceName!),
                  key: const ValueKey('idea-from'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: StudioSpacing.md),
              TextField(
                key: const ValueKey('idea-title'),
                controller: _title,
                decoration: InputDecoration(
                  labelText: t.titleLabel,
                  errorText: _titleError,
                ),
              ),
              const SizedBox(height: StudioSpacing.md),
              TextField(
                key: const ValueKey('idea-hook'),
                controller: _hook,
                maxLines: 2,
                decoration: InputDecoration(labelText: t.hookLabel),
              ),
              const SizedBox(height: StudioSpacing.md),
              TextField(
                key: const ValueKey('idea-title-ar'),
                controller: _titleAr,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(labelText: t.titleArLabel),
              ),
              const SizedBox(height: StudioSpacing.md),
              Text(
                t.formatLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: StudioSpacing.xs),
              Wrap(
                spacing: StudioSpacing.sm,
                children: [
                  for (final f in _formats)
                    StudioChoiceChip(
                      key: ValueKey('format-$f'),
                      label: Text(t.format(f)),
                      selected: _format == f,
                      onSelected: (v) => setState(() => _format = v ? f : null),
                    ),
                ],
              ),
              const SizedBox(height: StudioSpacing.lg),
              Row(
                children: [
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.pop(context, false),
                    child: Text(s.cancel),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey('idea-submit'),
                    onPressed: _busy ? null : _submit,
                    child: Text(editing ? s.save : t.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
