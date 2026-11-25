import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../inbox/presentation/inbox_strings.dart';
import '../../inbox/presentation/ui_helpers.dart';
import '../../review/data/review_repository.dart';
import '../data/ideas_repository.dart';
import 'idea_forms.dart';
import 'ideas_strings.dart';
import '../../../shared/studio_error_text.dart';

/// One idea: hook, format, who it is for, source. Keep, Drop and Edit appear
/// only when the server lists them in `actions`.
class IdeaCard extends ConsumerStatefulWidget {
  const IdeaCard({super.key, required this.idea});

  final StudioIdea idea;

  @override
  ConsumerState<IdeaCard> createState() => _IdeaCardState();
}

class _IdeaCardState extends ConsumerState<IdeaCard> {
  String _keepRid = const Uuid().v4();
  String _dropRid = const Uuid().v4();
  bool _busy = false;

  Future<void> _keep() async {
    final t = IdeasStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.keepTitle),
        content: Text(t.keepBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(InboxStrings.of(c).cancel),
          ),
          FilledButton(
            key: const ValueKey('keep-confirm'),
            onPressed: () => Navigator.pop(c, true),
            child: Text(t.keep),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final router = GoRouter.maybeOf(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final piece = await ref
          .read(ideasProvider.notifier)
          .keep(widget.idea.id, requestId: _keepRid);
      _keepRid = const Uuid().v4();
      ref.invalidate(inboxCountsProvider);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(t.ideaKept),
            action: piece == null
                ? null
                : SnackBarAction(
                    label: t.openPiece,
                    onPressed: () => router?.push('/pieces/${piece.id}'),
                  ),
          ),
        );
    } catch (e) {
      if (mounted) showStudioError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _drop() async {
    final t = IdeasStrings.of(context);
    final reason = await showDropReasonDialog(context);
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ideasProvider.notifier)
          .drop(widget.idea.id, reason, requestId: _dropRid);
      _dropRid = const Uuid().v4();
      ref.invalidate(inboxCountsProvider);
      if (mounted) showStudioNote(context, t.ideaDropped);
    } catch (e) {
      if (mounted) showStudioError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final saved = await showEditIdeaSheet(context, ref, widget.idea);
    if (saved && mounted) {
      showStudioNote(context, IdeasStrings.of(context).ideaSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final idea = widget.idea;
    final t = IdeasStrings.of(context);
    final s = InboxStrings.of(context);
    final theme = Theme.of(context);
    final arabic = s.isArabic;
    final title = arabic && (idea.titleAr?.isNotEmpty ?? false)
        ? idea.titleAr!
        : idea.title;
    final fmt = idea.format == null
        ? null
        : t.format(
            idea.format!.name == 'staticValue' ? 'static' : idea.format!.name,
          );
    final who = idea.raisedBy?.fullName ?? t.source(idea.source.name);
    final canKeep = idea.actions.contains('keep');
    final canDrop = idea.actions.contains('drop');
    final canEdit = idea.actions.contains('edit');

    return Card(
      key: ValueKey('idea-${idea.id}'),
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                if (canEdit)
                  IconButton(
                    key: const ValueKey('idea-edit'),
                    tooltip: t.edit,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: _busy ? null : _edit,
                  ),
              ],
            ),
            if (idea.hook != null && idea.hook!.isNotEmpty) ...[
              const SizedBox(height: StudioSpacing.xs),
              Text(idea.hook!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: StudioSpacing.sm),
            Wrap(
              spacing: StudioSpacing.sm,
              runSpacing: StudioSpacing.xs,
              children: [
                if (fmt != null) _Tag(fmt),
                for (final f in idea.flavours) _Tag(f.name),
                _Tag(t.from(who)),
              ],
            ),
            if (idea.angle != null && idea.angle!.isNotEmpty) ...[
              const SizedBox(height: StudioSpacing.sm),
              Text(
                '${t.forWho}: ${idea.angle}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: StudioSpacing.md),
            if (idea.status == IdeaStatus.open) ...[
              if (canKeep || canDrop)
                Row(
                  children: [
                    if (canKeep)
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey('idea-keep'),
                          onPressed: _busy ? null : _keep,
                          child: Text(t.keep),
                        ),
                      ),
                    if (canKeep && canDrop)
                      const SizedBox(width: StudioSpacing.sm),
                    if (canDrop)
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('idea-drop'),
                          onPressed: _busy ? null : _drop,
                          child: Text(t.drop),
                        ),
                      ),
                  ],
                ),
              if (canKeep || canDrop) const SizedBox(height: StudioSpacing.sm),
              NextStepLine(
                canKeep || canDrop ? t.nextOpenCanDecide : t.nextOpenWaiting,
              ),
            ] else if (idea.status == IdeaStatus.kept) ...[
              NextStepLine(t.nextKept),
              if (idea.keptPieceId != null)
                TextButton.icon(
                  key: const ValueKey('idea-open-piece'),
                  onPressed: () => context.push('/pieces/${idea.keptPieceId}'),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(t.openPiece),
                ),
            ] else ...[
              NextStepLine(t.nextDropped),
              if (idea.dropReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: StudioSpacing.xs),
                  child: Text(
                    t.reasonOf(idea.dropReason!),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: StudioColors.blushPale,
        border: Border.all(color: StudioColors.border),
        borderRadius: BorderRadius.circular(StudioRadii.pill),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
