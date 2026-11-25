import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/how_this_works_sheet.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../shoots_strings.dart';
import '../state/on_set_state.dart';
import 'shoot_widgets.dart';

/// On set: one shot at a time, built for one hand. Works with no connection:
/// the shoot comes from the phone's own copy, and ticks and notes are kept
/// and sent when the connection returns.
class OnSetScreen extends ConsumerStatefulWidget {
  const OnSetScreen({super.key, required this.shootId, this.startShotId});

  final String shootId;

  /// Opens at this shot instead of the first one still to film.
  final String? startShotId;

  @override
  ConsumerState<OnSetScreen> createState() => _OnSetScreenState();
}

class _OnSetScreenState extends ConsumerState<OnSetScreen> {
  PageController? _pages;
  int _index = 0;
  var _positioned = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await ref.read(onSetProvider.notifier).openShoot(widget.shootId);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  List<ShootShot> _shots(StudioShoot s) =>
      [...s.shots]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  void _position(List<ShootShot> shots) {
    if (_positioned || shots.isEmpty) return;
    _positioned = true;
    var i = 0;
    if (widget.startShotId != null) {
      i = shots.indexWhere((s) => s.id == widget.startShotId);
      if (i < 0) i = 0;
    } else {
      i = shots.indexWhere((s) => !s.done);
      if (i < 0) i = 0;
    }
    _index = i;
    _pages = PageController(initialPage: i);
  }

  void _go(int i, int total) {
    final to = i.clamp(0, total - 1);
    _pages?.animateToPage(
      to,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ShootStrings.of(context);
    final shoot = ref.watch(
      onSetProvider.select((s) => s.shoot(widget.shootId)),
    );

    if (shoot == null) {
      return Scaffold(
        appBar: AppBar(
          leading: _CloseButton(shootId: widget.shootId),
          title: Text(t.onSetTitle),
        ),
        body: _loadError == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(StudioSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        shootErrorText(t, _loadError!),
                        key: const ValueKey('onset-error'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: StudioSpacing.lg),
                      FilledButton(
                        onPressed: () {
                          setState(() => _loadError = null);
                          _load();
                        },
                        child: Text(StudioStrings.of(context).retry),
                      ),
                    ],
                  ),
                ),
              ),
      );
    }

    final shots = _shots(shoot);
    _position(shots);
    final total = shots.length;
    final done = shots.where((s) => s.done).length;
    final current = total == 0 ? null : shots[_index.clamp(0, total - 1)];
    final canTick = current?.actions.contains('tick') ?? false;
    final moved = ref.watch(onSetProvider.select((s) => s.moved));
    final refused = ref.watch(onSetProvider.select((s) => s.refused));

    return Scaffold(
      key: const ValueKey('on-set'),
      appBar: AppBar(
        leading: _CloseButton(shootId: widget.shootId),
        title: total == 0
            ? Text(t.onSetTitle, key: const ValueKey('onset-position'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.shotOf(_index + 1, total),
                    key: const ValueKey('onset-position'),
                  ),
                  Text(
                    done == total ? t.allFilmed : t.shotsOf(done, total),
                    key: const ValueKey('onset-count'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
        actions: [
          IconButton(
            key: const ValueKey('help'),
            tooltip: StudioStrings.of(context).howThisWorks,
            icon: const Icon(Icons.help_outline),
            onPressed: () => HowThisWorksSheet.show(
              context,
              title: t.onSetHelpTitle,
              lines: t.onSetHelp,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            key: const ValueKey('onset-progress'),
            value: total == 0 ? 0 : done / total,
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          const SyncBanner(),
          if (moved.isNotEmpty || refused.isNotEmpty)
            _Notices(moved: moved, refused: refused),
          Expanded(
            child: total == 0
                ? Center(child: Text(t.noShots))
                : PageView.builder(
                    key: const ValueKey('onset-pages'),
                    controller: _pages,
                    itemCount: total,
                    onPageChanged: (i) {
                      // Leaving a shot sends the note typed on it.
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() => _index = i);
                    },
                    itemBuilder: (context, i) => _ShotPage(
                      key: ValueKey('page-${shots[i].id}'),
                      shootId: shoot.id,
                      shot: shots[i],
                    ),
                  ),
          ),
          if (total > 0)
            _BottomBar(
              shot: current!,
              canTick: canTick,
              first: _index == 0,
              last: _index == total - 1,
              allDone: done == total,
              onPrevious: () => _go(_index - 1, total),
              onNext: () => _go(_index + 1, total),
              onTick: () => ref
                  .read(onSetProvider.notifier)
                  .tick(current.id, !current.done),
            ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.shootId});
  final String shootId;

  @override
  Widget build(BuildContext context) {
    final t = ShootStrings.of(context);
    return IconButton(
      key: const ValueKey('onset-close'),
      tooltip: t.exitOnSet,
      icon: const Icon(Icons.close),
      onPressed: () =>
          context.canPop() ? context.pop() : context.go('/shoots/$shootId'),
    );
  }
}

class _Notices extends ConsumerWidget {
  const _Notices({required this.moved, required this.refused});
  final List<PieceRef> moved;
  final List<String> refused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ShootStrings.of(context);
    final st = StudioStrings.of(context);
    final stage = moved.isEmpty ? '' : st.stage(moved.first.stage.wire);
    return Container(
      key: const ValueKey('onset-notices'),
      width: double.infinity,
      color: StudioColors.softBlush.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(
        horizontal: StudioSpacing.gutter,
        vertical: StudioSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (moved.isNotEmpty)
                  Text(
                    t.piecesMoved(moved.length, stage),
                    key: const ValueKey('pieces-moved'),
                  ),
                for (final r in refused) Text(t.refusedChange(r)),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('notices-dismiss'),
            tooltip: StudioStrings.of(context).dismiss,
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => ref.read(onSetProvider.notifier).clearNotices(),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.shot,
    required this.canTick,
    required this.first,
    required this.last,
    required this.allDone,
    required this.onPrevious,
    required this.onNext,
    required this.onTick,
  });

  final ShootShot shot;
  final bool canTick;
  final bool first;
  final bool last;
  final bool allDone;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTick;

  @override
  Widget build(BuildContext context) {
    final t = ShootStrings.of(context);
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(StudioSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (allDone)
                Padding(
                  padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
                  child: Text(
                    t.allFilmed,
                    key: const ValueKey('all-filmed'),
                    style: const TextStyle(color: StudioColors.success),
                  ),
                ),
              Row(
                children: [
                  IconButton.outlined(
                    key: const ValueKey('onset-prev'),
                    tooltip: t.previous,
                    iconSize: 28,
                    onPressed: first ? null : onPrevious,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: StudioSpacing.md),
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: canTick
                          ? (shot.done
                                ? FilledButton.tonalIcon(
                                    key: const ValueKey('onset-filmed'),
                                    onPressed: onTick,
                                    icon: const Icon(Icons.check_circle),
                                    label: Text(t.filmedDone),
                                  )
                                : FilledButton.icon(
                                    key: const ValueKey('onset-filmed'),
                                    onPressed: onTick,
                                    icon: const Icon(Icons.check),
                                    label: Text(
                                      t.filmedButton,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ))
                          : const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: StudioSpacing.md),
                  IconButton.outlined(
                    key: const ValueKey('onset-next'),
                    tooltip: t.next,
                    iconSize: 28,
                    onPressed: last ? null : onNext,
                    icon: const Icon(Icons.chevron_right),
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

/// One shot's card: what to film, the lines, the brief, the references, and
/// the note field.
class _ShotPage extends ConsumerStatefulWidget {
  const _ShotPage({super.key, required this.shootId, required this.shot});
  final String shootId;
  final ShootShot shot;

  @override
  ConsumerState<_ShotPage> createState() => _ShotPageState();
}

class _ShotPageState extends ConsumerState<_ShotPage> {
  late final TextEditingController _note = TextEditingController(
    text: widget.shot.note,
  );
  final _focus = FocusNode();
  Timer? _debounce;
  late final OnSetController _ctrl;
  late String _lastSaved;

  @override
  void initState() {
    super.initState();
    _ctrl = ref.read(onSetProvider.notifier);
    _lastSaved = widget.shot.note ?? '';
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(_ShotPage old) {
    super.didUpdateWidget(old);
    // A note that changed underneath (a sync) shows unless being typed.
    final fresh = widget.shot.note ?? '';
    if (!_focus.hasFocus && fresh != _note.text && fresh != _lastSaved) {
      _note.text = fresh;
      _lastSaved = fresh;
    }
  }

  void _commit() {
    final text = _note.text.trim();
    if (text == _lastSaved.trim()) return;
    _lastSaved = text;
    _ctrl.saveNote(widget.shot.id, text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // Leaving the page keeps what was typed.
    if (_note.text.trim() != _lastSaved.trim()) {
      final c = _ctrl;
      final id = widget.shot.id;
      final text = _note.text.trim();
      Future.microtask(() => c.saveNote(id, text));
    }
    _note.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ShootStrings.of(context);
    final theme = Theme.of(context);
    final shot = widget.shot;
    final b = shot.brief;
    final canNote = shot.actions.contains('note');

    Widget section(String label, String? text, {Key? key}) =>
        text == null || text.trim().isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: StudioSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                const SizedBox(height: StudioSpacing.xxs),
                Text(text, key: key, style: theme.textTheme.bodyLarge),
              ],
            ),
          );

    final images = [
      for (final r in shot.refs)
        if (r.reference.image != null) r,
    ];
    final media = [for (final r in images) r.reference.image!];

    return ShootPage(
      maxWidth: 640,
      child: ListView(
        padding: const EdgeInsets.all(StudioSpacing.gutter),
        children: [
          Text(
            shot.what,
            key: const ValueKey('shot-what'),
            style: theme.textTheme.headlineSmall,
          ),
          if (shot.lenS != null)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.xs),
              child: Text(
                t.lengthSeconds(
                  shot.lenS == shot.lenS!.roundToDouble()
                      ? '${shot.lenS!.round()}'
                      : '${shot.lenS}',
                ),
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: StudioSpacing.md),
          if (canNote)
            TextField(
              key: const ValueKey('shot-note'),
              controller: _note,
              focusNode: _focus,
              minLines: 2,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              onTapOutside: (_) => _focus.unfocus(),
              // Kept on the phone as it is typed; sent when the field is left.
              onChanged: (v) {
                _ctrl.saveNote(shot.id, v.trim(), send: false);
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 800), _commit);
              },
              decoration: InputDecoration(
                labelText: t.noteLabel,
                hintText: t.noteHint,
              ),
            )
          else if ((shot.note ?? '').isNotEmpty)
            section(t.noteLabel, shot.note),
          const SizedBox(height: StudioSpacing.lg),
          if (shot.pieces.isNotEmpty)
            section(
              t.servesPieces,
              shot.pieces.map((p) => p.title).join(' · '),
            ),
          section(t.setupLabel, shot.setup),
          section(
            t.scriptLine,
            [
              if (shot.ar != null && shot.ar!.isNotEmpty) shot.ar!,
              if (shot.en != null && shot.en!.isNotEmpty) shot.en!,
            ].join('\n'),
            key: const ValueKey('shot-script'),
          ),
          section(t.onScreenText, b.copy, key: const ValueKey('shot-copy')),
          section(t.briefWhy, b.why),
          section(t.briefFrame, b.frame),
          section(t.briefLight, b.light),
          section(t.briefAction, b.action),
          section(t.briefSound, b.sound),
          section(t.briefAvoid, b.avoid),
          section(t.briefCheck, b.check),
          section(t.briefTakes, b.takes),
          Text(t.referencesTitle, style: theme.textTheme.labelMedium),
          const SizedBox(height: StudioSpacing.sm),
          if (images.isEmpty)
            Text(t.noReferences, style: theme.textTheme.bodySmall)
          else
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: StudioSpacing.sm),
                itemBuilder: (context, i) {
                  final r = images[i];
                  return GestureDetector(
                    key: ValueKey('ref-${r.linkId}'),
                    onTap: () => openStudioMediaViewer(
                      context,
                      items: media,
                      initialIndex: i,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StudioThumb(
                          media: r.reference.image,
                          width: 90,
                          height: 120,
                          radius: BorderRadius.circular(StudioRadii.sm),
                        ),
                        Text(
                          r.real ? t.realReference : t.madeReference,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
