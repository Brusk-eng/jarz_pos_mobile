import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_status_colors.dart' as theme;
import '../../../core/theme/studio_theme.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/studio_error.dart';
import '../../../shared/media_row.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/verdict_badge.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../calendar/presentation/calendar_widgets.dart';
import '../../calendar/state/cairo_format.dart';
import '../../calendar/state/cairo_time.dart';
import '../data/pieces_repository.dart';
import '../pieces_strings.dart';
import 'add_version_screen.dart';
import 'piece_edit_screen.dart';
import 'piece_widgets.dart';

/// The piece screen (`/pieces/:id`): where the piece is, what happens next and
/// who has it, then everything about it. Buttons come only from the piece's
/// `actions` and `next_moves`.
class PieceScreen extends ConsumerStatefulWidget {
  const PieceScreen({super.key, required this.pieceId});

  final String pieceId;

  @override
  ConsumerState<PieceScreen> createState() => _PieceScreenState();
}

class _PieceScreenState extends ConsumerState<PieceScreen> {
  bool _busy = false;
  bool _fullHistory = false;

  PieceNotifier get _notifier =>
      ref.read(pieceProvider(widget.pieceId).notifier);

  /// Runs a write, then says what happened in plain words.
  Future<void> _run(
    Future<void> Function() op, {
    required String done,
    StudioPiece? piece,
  }) async {
    final s = PiecesStrings.of(context);
    setState(() => _busy = true);
    try {
      await op();
      if (mounted) showSnack(context, done);
    } on StudioGateFailed catch (e) {
      if (!mounted) return;
      await showGateProblemsSheet(
        context,
        problems: e.problems,
        message: e.message,
        fixFor: piece == null ? null : (p) => _fixFor(p, piece),
      );
    } on StudioNotFound {
      if (mounted) {
        showSnack(context, s.gone);
        context.go('/pieces');
      }
    } on StudioNotPermitted catch (e) {
      // The actions were stale: show the message and reload.
      if (mounted) showSnack(context, s.error(e));
      await _notifier.refresh();
    } catch (e) {
      if (mounted) showSnack(context, s.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Where a refused move can be fixed, when we can tell from the problem.
  VoidCallback? _fixFor(StudioProblem p, StudioPiece piece) {
    final code = p.code.toLowerCase();
    final version = piece.currentVersion;
    bool has(List<String> words) => words.any(code.contains);
    if (version != null &&
        has(['version', 'review', 'approv', 'file', 'caption', 'verdict'])) {
      return () => context.push('/versions/${version.id}');
    }
    if (has(['shoot', 'shot'])) {
      final shot = piece.shots.isEmpty ? null : piece.shots.first;
      return () =>
          context.push(shot == null ? '/shoots' : '/shoots/${shot.shootId}');
    }
    if (piece.actions.contains('edit') &&
        has(['script', 'label', 'voice', 'title', 'copy', 'flavour', 'line'])) {
      return () => _edit(piece);
    }
    return null;
  }

  Future<void> _edit(StudioPiece piece) async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (_) => PieceEditScreen(pieceId: piece.id)),
    );
  }

  Future<void> _move(StudioPiece piece, Move m) async {
    final s = PiecesStrings.of(context);
    String? reason;
    String? skip;
    if (m.needs == MoveNeeds.reason) {
      reason = await askText(context, title: m.label, label: s.reasonLabel);
      if (reason == null) return;
    } else if (m.needs == MoveNeeds.skipShootReason) {
      skip = await askText(
        context,
        title: m.label,
        label: s.skipShootReasonLabel,
      );
      if (skip == null) return;
    }
    if (!mounted) return;
    final target = stageName(context, m.to);
    await _run(
      () => _notifier.move(
        m.to.wire,
        reason: reason,
        skipShootReason: skip,
        requestId: const Uuid().v4(),
      ),
      done: s.movedTo(target),
      piece: piece,
    );
  }

  Future<void> _park(StudioPiece piece) async {
    final s = PiecesStrings.of(context);
    final reason = await askText(
      context,
      title: s.parkTitle,
      explain: s.parkExplain,
      label: s.reasonLabel,
    );
    if (reason == null) return;
    await _run(
      () => _notifier.park(reason, requestId: const Uuid().v4()),
      done: s.parkedDone,
    );
  }

  Future<void> _unpark() async {
    final s = PiecesStrings.of(context);
    await _run(
      () => _notifier.unpark(requestId: const Uuid().v4()),
      done: s.unparkedDone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = StudioStrings.of(context);
    final value = ref.watch(pieceProvider(widget.pieceId));
    final copy = t.screen(StudioScreen.piece);
    final piece = value.valueOrNull;
    final canEdit =
        piece != null &&
        (piece.actions.contains('edit') || piece.actions.contains('assign'));

    return ViewEditScaffold(
      title: piece == null
          ? copy.title
          : pieceTitleText(context, piece.title, piece.titleAr),
      screen: StudioScreen.piece,
      parentRoute: '/pieces',
      onEdit: canEdit ? () => _edit(piece) : null,
      body: StudioAsyncView<StudioPiece>(
        value: value,
        onRetry: () => _notifier.refresh(),
        isEmpty: (_) => false,
        empty: StudioEmptyConfig(
          purpose: copy.purpose,
          firstStep: copy.firstStep,
        ),
        builder: (context, p) => RefreshIndicator(
          onRefresh: _notifier.refresh,
          child: ListView(
            key: const ValueKey('piece-body'),
            padding: const EdgeInsets.all(StudioSpacing.gutter),
            children: [
              _Header(piece: p),
              _NextCard(
                piece: p,
                busy: _busy,
                onMove: (m) => _move(p, m),
                onPark: () => _park(p),
                onUnpark: _unpark,
              ),
              _Labels(piece: p),
              _ScriptBlock(piece: p),
              _Versions(piece: p),
              _Shots(piece: p),
              _Posts(piece: p),
              _Results(piece: p),
              _History(
                piece: p,
                full: _fullHistory,
                onShowFull: () => setState(() => _fullHistory = true),
              ),
              const SizedBox(height: StudioSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ header

class _Header extends StatelessWidget {
  const _Header({required this.piece});
  final StudioPiece piece;

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    final textTheme = Theme.of(context).textTheme;
    final verdict = switch (piece.verdict?.label) {
      VerdictLabel.rUN => theme.Verdict.run,
      VerdictLabel.fIX => theme.Verdict.fix,
      VerdictLabel.dROP => theme.Verdict.drop,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudioThumb(
              media: piece.picture ?? piece.currentVersion?.thumb,
              width: 72,
              height: 90,
              radius: BorderRadius.circular(StudioRadii.sm),
            ),
            const SizedBox(width: StudioSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pieceTitleText(context, piece.title, piece.titleAr),
                    key: const ValueKey('piece-title'),
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: StudioSpacing.xs),
                  Wrap(
                    spacing: StudioSpacing.sm,
                    runSpacing: StudioSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      KeyedSubtree(
                        key: const ValueKey('piece-stage'),
                        child: stageChipFor(piece.stage),
                      ),
                      if (verdict != null) VerdictBadge(verdict: verdict),
                      Text(
                        piece.legacyId ?? piece.id,
                        style: StudioTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (piece.parked != null)
          Padding(
            padding: const EdgeInsets.only(top: StudioSpacing.md),
            child: Container(
              key: const ValueKey('parked-banner'),
              padding: const EdgeInsets.all(StudioSpacing.md),
              decoration: BoxDecoration(
                color: StudioColors.blushPale,
                borderRadius: BorderRadius.circular(StudioRadii.md),
                border: Border.all(color: StudioColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pause_circle_outline),
                  const SizedBox(width: StudioSpacing.sm),
                  Expanded(child: Text(s.parkedWhy(piece.parked!))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String? _slotDay(String? iso, bool ar) {
  final day = CairoTime.parse(iso);
  return day == null ? null : CairoFormat.dayMonth(day, ar);
}

class _NextCard extends StatelessWidget {
  const _NextCard({
    required this.piece,
    required this.busy,
    required this.onMove,
    required this.onPark,
    required this.onUnpark,
  });

  final StudioPiece piece;
  final bool busy;
  final ValueChanged<Move> onMove;
  final VoidCallback onPark;
  final VoidCallback onUnpark;

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    final ar = isArabic(context);
    final textTheme = Theme.of(context).textTheme;
    final canMove = piece.actions.contains('move');
    final moves = canMove ? piece.nextMoves : const <Move>[];
    final due = CairoTime.parse(piece.dueDate);
    final who = piece.assignee != null
        ? s.withPerson(piece.assignee!.fullName)
        : (piece.assigneeTeam != null &&
              piece.assigneeTeam != OwnerTeam.unknown)
        ? s.withPerson(s.team(piece.assigneeTeam!))
        : s.withNobody;

    return Card(
      key: const ValueKey('next-card'),
      margin: const EdgeInsets.only(top: StudioSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.pieceNext, style: textTheme.titleMedium),
            const SizedBox(height: StudioSpacing.sm),
            Text(
              [
                who,
                if (due != null) s.dueOn(CairoFormat.dayMonth(due, ar)),
              ].join(' · '),
              key: const ValueKey('next-who'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.xs),
              child: Text(
                s.stageNext(
                  piece.stage,
                  who: piece.assignee?.fullName ??
                      (piece.assigneeTeam != null &&
                              piece.assigneeTeam != OwnerTeam.unknown
                          ? s.team(piece.assigneeTeam!)
                          : null),
                  parkedReason: piece.parked,
                  sentBack:
                      piece.currentVersion?.reviewOutcome ==
                      ReviewOutcome.fix,
                  reason: piece.versions
                      .where((v) => v.isCurrent)
                      .map((v) => v.reviewReason)
                      .firstOrNull,
                  slot: _slotDay(piece.nextPost?.slotTime, ar),
                  byHand: piece.nextPost?.postingMode == PostingMode.byHand,
                ),
                key: const ValueKey('next-stage'),
              ),
            ),
            if (piece.blocked != null)
              Padding(
                padding: const EdgeInsets.only(top: StudioSpacing.xs),
                child: Text(
                  s.waitingOn(piece.blocked!.reason),
                  key: const ValueKey('next-waiting'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: StudioColors.warning,
                  ),
                ),
              ),
            if (moves.isEmpty && piece.parked == null)
              Padding(
                padding: const EdgeInsets.only(top: StudioSpacing.sm),
                child: Text(s.nextNothing, style: textTheme.bodySmall),
              ),
            for (final m in moves)
              Padding(
                padding: const EdgeInsets.only(top: StudioSpacing.md),
                child: m.enabled
                    ? SizedBox(
                        width: double.infinity,
                        child: m.kind == MoveKind.back
                            ? OutlinedButton(
                                key: ValueKey('move-${m.to.wire}'),
                                onPressed: busy ? null : () => onMove(m),
                                child: Text(m.label),
                              )
                            : FilledButton(
                                key: ValueKey('move-${m.to.wire}'),
                                onPressed: busy ? null : () => onMove(m),
                                child: Text(m.label),
                              ),
                      )
                    : Column(
                        key: ValueKey('move-blocked-${m.to.wire}'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lock_outline, size: 16),
                              const SizedBox(width: StudioSpacing.xs),
                              Text(m.label, style: textTheme.titleSmall),
                            ],
                          ),
                          if (m.problems.isNotEmpty) ...[
                            const SizedBox(height: StudioSpacing.xs),
                            Text(s.whyNotYet, style: textTheme.bodySmall),
                            const SizedBox(height: StudioSpacing.xs),
                            ProblemChecklist(problems: m.problems),
                          ],
                        ],
                      ),
              ),
            if (piece.actions.contains('park') ||
                piece.actions.contains('unpark'))
              Padding(
                padding: const EdgeInsets.only(top: StudioSpacing.md),
                child: Wrap(
                  spacing: StudioSpacing.sm,
                  children: [
                    if (piece.actions.contains('park'))
                      OutlinedButton.icon(
                        key: const ValueKey('park'),
                        icon: const Icon(Icons.pause_circle_outline),
                        onPressed: busy ? null : onPark,
                        label: Text(s.park),
                      ),
                    if (piece.actions.contains('unpark'))
                      OutlinedButton.icon(
                        key: const ValueKey('unpark'),
                        icon: const Icon(Icons.play_circle_outline),
                        onPressed: busy ? null : onUnpark,
                        label: Text(s.unpark),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ labels

class _Labels extends StatelessWidget {
  const _Labels({required this.piece});
  final StudioPiece piece;

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    final chips = <String>[
      s.format(piece.format),
      if (piece.use != null && piece.use != PieceUse.unknown) s.use(piece.use!),
      if (piece.persona != null && piece.persona != Persona.unknown)
        s.persona(piece.persona!),
      if (piece.situation != null && piece.situation != Situation.unknown)
        s.situation(piece.situation!),
      if (piece.layer != null && piece.layer != ContentLayer.unknown)
        s.layer(piece.layer!),
      if (piece.level != null) '${s.fieldLevel} ${piece.level}',
      if (piece.series != null && piece.series!.isNotEmpty) piece.series!,
      if (piece.route != null && piece.route != ProdRoute.unknown)
        s.route(piece.route!),
      for (final f in piece.flavours) f.name,
    ].where((c) => c.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(s.sectionLabels),
        Wrap(
          key: const ValueKey('piece-labels'),
          spacing: StudioSpacing.sm,
          runSpacing: StudioSpacing.sm,
          children: [for (final c in chips) Chip(label: Text(c))],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ script

class _ScriptBlock extends StatelessWidget {
  const _ScriptBlock({required this.piece});
  final StudioPiece piece;

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    final sc = piece.script;
    final textTheme = Theme.of(context).textTheme;
    final hasAny =
        sc.lines.isNotEmpty ||
        (sc.opening?.isNotEmpty ?? false) ||
        (sc.screenAr?.isNotEmpty ?? false) ||
        (sc.screenEn?.isNotEmpty ?? false) ||
        (sc.notes?.isNotEmpty ?? false) ||
        (piece.ownText?.isNotEmpty ?? false) ||
        (piece.adCopy?.isNotEmpty ?? false);

    Widget labelled(String label, String? text, {bool rtl = false}) {
      if (text == null || text.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: StudioSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: StudioTextStyles.caption),
            Text(text, textDirection: rtl ? TextDirection.rtl : null),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(s.sectionScript),
        if (!hasAny)
          Text(
            s.noScript,
            key: const ValueKey('script-empty'),
            style: textTheme.bodySmall,
          )
        else
          Column(
            key: const ValueKey('script-block'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelled(s.opening, sc.opening),
              labelled(s.length, sc.length),
              for (final l in sc.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          [
                            if (l.t != null) l.t!,
                            s.scriptLang(l.lang),
                          ].where((x) => x.isNotEmpty).join('\n'),
                          style: StudioTextStyles.caption,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l.line,
                          textDirection: l.lang == ScriptLang.ar
                              ? TextDirection.rtl
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              labelled(s.onScreenAr, sc.screenAr, rtl: true),
              labelled(s.onScreenEn, sc.screenEn),
              labelled(s.notes, sc.notes),
              labelled(s.ownText, piece.ownText),
              labelled(s.adCopy, piece.adCopy),
              if (sc.holds.isNotEmpty) labelled(s.holds, sc.holds.join(', ')),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- versions

class _Versions extends StatelessWidget {
  const _Versions({required this.piece});
  final StudioPiece piece;

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    final versions = [...piece.versions]
      ..sort((a, b) => b.versionNo.compareTo(a.versionNo));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(s.sectionVersions),
        if (piece.actions.contains('add_version'))
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              key: const ValueKey('add-version'),
              onPressed: () => context.push('/pieces/${piece.id}/add-version'),
              icon: const Icon(Icons.add),
              label: Text(
                piece.format == PieceFormat.story
                    ? AddVersionStrings.of(context).buttonFrames
                    : AddVersionStrings.of(context).button,
              ),
            ),
          ),
        if (versions.isEmpty)
          Text(s.noVersions, style: Theme.of(context).textTheme.bodySmall),
        for (final v in versions)
          StudioMediaRow(
            key: ValueKey('version-${v.id}'),
            media: v.files.isEmpty
                ? (v.frames.isEmpty ? null : v.frames.first.asset.media)
                : v.files.first.media,
            title: [
              s.versionNo(v.versionNo),
              if (v.isCurrent) s.currentVersion,
            ].join(' · '),
            subtitle: s.reviewOutcome(v.reviewOutcome),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/versions/${v.id}'),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------ shots, posts

class _Shots extends StatelessWidget {
  const _Shots({required this.piece});
  final StudioPiece piece;

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    final ar = isArabic(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(s.sectionShots),
        if (piece.shots.isEmpty)
          Text(s.noShots, style: Theme.of(context).textTheme.bodySmall),
        for (final shot in piece.shots)
          ListTile(
            key: ValueKey('shot-${shot.id}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              shot.done ? Icons.check_circle_outline : Icons.circle_outlined,
            ),
            title: Text(shot.what),
            subtitle: Text(
              [
                shot.shootTitle,
                if (CairoTime.parse(shot.shootDate) case final d?)
                  CairoFormat.dayMonth(d, ar),
              ].join(' · '),
            ),
            trailing: Text(s.openShoot, style: StudioTextStyles.caption),
            onTap: () => context.push('/shoots/${shot.shootId}'),
          ),
      ],
    );
  }
}

class _Posts extends StatelessWidget {
  const _Posts({required this.piece});
  final StudioPiece piece;

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(s.sectionPosts),
        if (piece.posts.isEmpty)
          Text(s.noPosts, style: Theme.of(context).textTheme.bodySmall),
        for (final p in piece.posts) PostTile(post: p, showDate: true),
      ],
    );
  }
}

// ----------------------------------------------------------------- results

class _Results extends StatelessWidget {
  const _Results({required this.piece});
  final StudioPiece piece;

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    final reads = piece.reads.where((r) => r.filed).toList();
    String n(int? v) => v == null ? '–' : '$v';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(s.sectionResults),
        if (reads.isEmpty)
          Text(
            s.noResults,
            key: const ValueKey('results-empty'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        for (final r in reads)
          Card(
            margin: const EdgeInsets.only(bottom: StudioSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.all(StudioSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.readBucket(r.bucket),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: StudioSpacing.xs),
                  Wrap(
                    spacing: StudioSpacing.lg,
                    runSpacing: StudioSpacing.xs,
                    children: [
                      Text('${s.readReach}: ${n(r.reach)}'),
                      Text('${s.readViews}: ${n(r.views)}'),
                      Text('${s.readShares}: ${n(r.shares)}'),
                      Text('${s.readSaves}: ${n(r.saves)}'),
                      Text('${s.readLikes}: ${n(r.likes)}'),
                      Text('${s.readComments}: ${n(r.commentsCount)}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------------- history

class _History extends ConsumerWidget {
  const _History({
    required this.piece,
    required this.full,
    required this.onShowFull,
  });

  final StudioPiece piece;
  final bool full;
  final VoidCallback onShowFull;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = PiecesStrings.of(context);
    final ar = isArabic(context);
    List<HistoryItem> items = piece.history;
    var loading = false;
    if (full) {
      final more = ref.watch(pieceHistoryProvider(piece.id));
      loading = more.isLoading;
      items = more.valueOrNull?.items ?? piece.history;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(s.sectionHistory),
        if (items.isEmpty)
          Text(s.noHistory, style: Theme.of(context).textTheme.bodySmall),
        for (final h in items)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(h.summary),
            subtitle: Text('${h.by.fullName} · ${CairoFormat.stamp(h.at, ar)}'),
          ),
        if (loading) const LinearProgressIndicator(),
        if (!full && piece.history.isNotEmpty)
          TextButton(
            key: const ValueKey('history-full'),
            onPressed: onShowFull,
            child: Text(s.showFullHistory),
          ),
      ],
    );
  }
}
