import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../shell/more_common.dart';
import '../../shell/more_strings.dart';
import '../data/references_repository.dart';
import '../references_strings.dart';
import '../state/references_state.dart';
import 'references_screen.dart' show referenceStatusColors;
import 'reference_pickers.dart';

/// One reference: its picture and source, the numbers, our take, the notes,
/// what it is linked to, and the buttons the server allows.
class ReferenceScreen extends ConsumerWidget {
  const ReferenceScreen({super.key, required this.referenceId});

  final String referenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReferencesStrings.of(context);
    final value = ref.watch(referenceProvider(referenceId));
    return ViewEditScaffold(
      title: value.valueOrNull?.title ?? t.pageTitle,
      parentRoute: '/more/references',
      actions: [moreHelpAction(context, title: t.helpTitle, lines: t.help)],
      body: MoreBody(
        child: StudioAsyncView<StudioReference>(
          value: value,
          onRetry: () => ref.invalidate(referenceProvider(referenceId)),
          empty: StudioEmptyConfig(
            purpose: t.emptyPurpose,
            firstStep: t.emptyFirstStep,
          ),
          builder: (context, r) => _ReferenceBody(r: r),
        ),
      ),
    );
  }
}

class _ReferenceBody extends ConsumerWidget {
  const _ReferenceBody({required this.r});

  final StudioReference r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReferencesStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);
    final colors = referenceStatusColors(r.status);

    return ListView(
      key: const ValueKey('reference-body'),
      padding: const EdgeInsets.only(bottom: StudioSpacing.xxl),
      children: [
        if (r.image != null)
          GestureDetector(
            key: const ValueKey('ref-image'),
            onTap: () => openStudioMediaViewer(context, items: [r.image!]),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: StudioThumb(
                media: r.image,
                fit: BoxFit.contain,
                radius: BorderRadius.zero,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(StudioSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: StudioSpacing.sm,
                runSpacing: StudioSpacing.xs,
                children: [
                  MorePill(
                    t.statusLabel(r.status),
                    foreground: colors.fg,
                    background: colors.bg == Colors.white
                        ? StudioColors.softBlush
                        : colors.bg,
                  ),
                  if (r.mediaType != null && r.mediaType != RefMedia.unknown)
                    MorePill(t.formatLabel(r.mediaType!)),
                  if (r.srcType != null && r.srcType != RefSrcType.unknown)
                    MorePill(t.sourceLabel(r.srcType!)),
                  if (r.remake != null && r.remake != RemakeFit.unknown)
                    MorePill(t.remakeLabel(r.remake!.wire)),
                ],
              ),
              const SizedBox(height: StudioSpacing.md),
              Text(r.title, style: theme.textTheme.headlineSmall),
              if (r.brand != null || r.competitor != null)
                Padding(
                  padding: const EdgeInsets.only(top: StudioSpacing.xs),
                  child: r.competitor != null
                      ? TextButton.icon(
                          key: const ValueKey('ref-competitor'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            alignment: AlignmentDirectional.centerStart,
                          ),
                          onPressed: () => context.go(
                            '/more/references/competitors/${r.competitor!.key}',
                          ),
                          icon: const Icon(Icons.groups_outlined, size: 18),
                          label: Text(r.competitor!.name),
                        )
                      : Text(r.brand!, style: theme.textTheme.bodyMedium),
                ),
              if (r.sourceDate != null)
                Text(m.date(r.sourceDate), style: theme.textTheme.bodySmall),
              if (r.locked)
                Padding(
                  padding: const EdgeInsets.only(top: StudioSpacing.sm),
                  child: Text(t.lockedNote, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
        _Buttons(r: r),
        if (r.url != null && r.url!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.gutter,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const ValueKey('ref-open-source'),
                onPressed: () => openMoreLink(context, ref, r.url!),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(t.openSource),
              ),
            ),
          ),
        if (r.take != null) _Block(label: t.ourTake, text: r.take!),
        if (r.why != null) _Block(label: t.whyItWorks, text: r.why!),
        if (r.text != null) _Block(label: t.textOnIt, text: r.text!),
        if (r.feasibility != null && r.feasibility != Feasibility.unknown)
          _Feasibility(r: r),
        SectionLabel(t.numbers),
        _Numbers(metrics: r.metrics),
        SectionLabel(t.usedFor),
        _Links(r: r),
        if (r.made.isNotEmpty) ...[
          SectionLabel(t.madeFromIt),
          for (final item in r.made)
            ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(item.title),
            ),
        ],
        SectionLabel(t.notes),
        if (r.notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.gutter,
            ),
            child: Text(t.noNotes, style: theme.textTheme.bodySmall),
          )
        else
          for (final n in r.notes)
            MoreCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.text, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: StudioSpacing.xs),
                  Text(
                    '${n.author.fullName}, ${m.dateTime(n.at)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        if (r.addedBy != null)
          Padding(
            padding: const EdgeInsets.all(StudioSpacing.gutter),
            child: Text(
              '${t.addedBy}: ${r.addedBy}',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionLabel(label),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.gutter),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}

class _Feasibility extends StatelessWidget {
  const _Feasibility({required this.r});

  final StudioReference r;

  @override
  Widget build(BuildContext context) {
    final t = ReferencesStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(t.canWeMakeIt),
        MoreCard(
          child: Column(
            children: [
              LabeledValue(
                t.canWeMakeIt,
                t.feasibilityLabel(r.feasibility!),
                emphasise: true,
              ),
              if (r.feasibilityMake != null)
                LabeledValue(t.whatToMake, r.feasibilityMake!),
              if (r.feasibilityBlock != null)
                LabeledValue(t.whatBlocks, r.feasibilityBlock!),
            ],
          ),
        ),
      ],
    );
  }
}

class _Numbers extends StatelessWidget {
  const _Numbers({required this.metrics});

  final Map<String, double> metrics;

  @override
  Widget build(BuildContext context) {
    final t = ReferencesStrings.of(context);
    if (metrics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.gutter),
        child: Text(t.noNumbers, style: Theme.of(context).textTheme.bodySmall),
      );
    }
    String fmt(double v) =>
        v == v.roundToDouble() ? groupDigits(v.round()) : v.toStringAsFixed(1);
    return MoreCard(
      child: Column(
        children: [
          for (final e in metrics.entries)
            LabeledValue(t.metricLabel(e.key), fmt(e.value)),
        ],
      ),
    );
  }
}

class _Links extends ConsumerWidget {
  const _Links({required this.r});

  final StudioReference r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReferencesStrings.of(context);
    final canLink = r.actions.contains('link');
    if (r.shotLinks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.gutter),
        child: Text(
          t.nothingLinked,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Column(
      children: [
        for (final l in r.shotLinks)
          MoreCard(
            key: ValueKey('link-${l.linkId}'),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.shotId != null
                            ? '${t.linkedShot} ${l.shotId}'
                            : '${t.linkedPiece} ${l.pieceId ?? ''}',
                      ),
                      Wrap(
                        spacing: StudioSpacing.sm,
                        children: [
                          if (l.grade == RefGrade.strong) MorePill(t.strongRef),
                          if (l.grade == RefGrade.weak) MorePill(t.weakRef),
                          if (l.real) MorePill(t.realRef),
                        ],
                      ),
                    ],
                  ),
                ),
                if (canLink)
                  TextButton(
                    key: ValueKey('unlink-${l.linkId}'),
                    onPressed: () => runMoreWrite(
                      context,
                      () => ref
                          .read(referenceActionsProvider(r.id))
                          .unlink(shotId: l.shotId, pieceId: l.pieceId),
                      okText: t.unlinked,
                    ),
                    child: Text(t.unlink),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The buttons of the reference, drawn from its `actions` and nothing else.
class _Buttons extends ConsumerWidget {
  const _Buttons({required this.r});

  final StudioReference r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReferencesStrings.of(context);
    final a = r.actions;
    final act = ref.read(referenceActionsProvider(r.id));

    Future<void> shortlist() => runMoreWrite(
      context,
      () => act.setStatus(RefStatus.shortlisted),
      okText: t.movedTo(t.statusLabel(RefStatus.shortlisted)),
    );

    Future<void> send() async {
      final shotId = await showShotPicker(context);
      if (shotId == null || !context.mounted) return;
      await runMoreWrite(
        context,
        () => act.setStatus(RefStatus.forAShoot, shotId: shotId),
        okText: t.movedTo(t.statusLabel(RefStatus.forAShoot)),
      );
    }

    Future<void> used() => runMoreWrite(
      context,
      () => act.setStatus(RefStatus.remade),
      okText: t.movedTo(t.statusLabel(RefStatus.remade)),
    );

    Future<void> drop() async {
      final reason = await askForText(
        context,
        title: t.dropTitle,
        hint: t.dropHint,
        confirm: t.dropConfirm,
        required: true,
      );
      if (reason == null || !context.mounted) return;
      await runMoreWrite(
        context,
        () => act.setStatus(RefStatus.dropped, note: reason),
        okText: t.movedTo(t.statusLabel(RefStatus.dropped)),
      );
    }

    Future<void> note() async {
      final text = await askForText(
        context,
        title: t.noteTitle,
        hint: t.noteHint,
        confirm: t.noteConfirm,
        required: true,
      );
      if (text == null || !context.mounted) return;
      await runMoreWrite(context, () => act.addNote(text), okText: t.noteAdded);
    }

    Future<void> link() async {
      final pieceId = await showPiecePicker(context);
      if (pieceId == null || !context.mounted) return;
      await runMoreWrite(
        context,
        () => act.linkPiece(pieceId),
        okText: t.linked,
      );
    }

    final buttons = <Widget>[
      if (a.contains('shortlist'))
        FilledButton(
          key: const ValueKey('ref-shortlist'),
          onPressed: shortlist,
          child: Text(t.shortlist),
        ),
      if (a.contains('send_to_shoot'))
        FilledButton.tonal(
          key: const ValueKey('ref-send'),
          onPressed: send,
          child: Text(t.sendToShoot),
        ),
      // "Used" is the edit action on a reference that is on a shoot.
      if (a.contains('edit') && r.status == RefStatus.forAShoot)
        FilledButton.tonal(
          key: const ValueKey('ref-used'),
          onPressed: used,
          child: Text(t.markUsed),
        ),
      if (a.contains('link'))
        OutlinedButton(
          key: const ValueKey('ref-link'),
          onPressed: link,
          child: Text(t.linkToPiece),
        ),
      if (a.contains('note'))
        OutlinedButton(
          key: const ValueKey('ref-note'),
          onPressed: note,
          child: Text(t.addNote),
        ),
      if (a.contains('drop'))
        TextButton(
          key: const ValueKey('ref-drop'),
          style: TextButton.styleFrom(foregroundColor: StudioColors.danger),
          onPressed: drop,
          child: Text(t.drop),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.gutter),
      child: Wrap(
        spacing: StudioSpacing.sm,
        runSpacing: StudioSpacing.sm,
        children: buttons,
      ),
    );
  }
}
