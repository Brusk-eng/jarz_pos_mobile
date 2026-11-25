import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../shoots/data/shoots_repository.dart';
import '../../shell/more_common.dart';
import '../../shell/more_strings.dart';
import '../references_strings.dart';
import '../state/references_state.dart';

/// Pick a shoot, then a shot in it. Returns the shot id, or null.
Future<String?> showShotPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => const _ShotPicker(),
  );
}

class _ShotPicker extends ConsumerStatefulWidget {
  const _ShotPicker();

  @override
  ConsumerState<_ShotPicker> createState() => _ShotPickerState();
}

class _ShotPickerState extends ConsumerState<_ShotPicker> {
  String? _shootId;

  @override
  Widget build(BuildContext context) {
    final t = ReferencesStrings.of(context);
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.7;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StudioSpacing.gutter,
              ),
              child: Row(
                children: [
                  if (_shootId != null)
                    IconButton(
                      key: const ValueKey('picker-back'),
                      tooltip: t.backToShoots,
                      icon: const BackButtonIcon(),
                      onPressed: () => setState(() => _shootId = null),
                    ),
                  Expanded(
                    child: Text(
                      _shootId == null ? t.pickShootTitle : t.pickShotTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _shootId == null
                  ? _Shoots(onPick: (id) => setState(() => _shootId = id))
                  : _Shots(shootId: _shootId!),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shoots extends ConsumerWidget {
  const _Shoots({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReferencesStrings.of(context);
    final m = MoreStrings.of(context);
    final shoots = ref.watch(shotPickerShootsProvider);
    return shoots.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(shotPickerShootsProvider),
          child: Text(m.retry),
        ),
      ),
      data: (items) => items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(StudioSpacing.xl),
                child: Text(t.noShoots, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              children: [
                for (final s in items)
                  ListTile(
                    key: ValueKey('pick-shoot-${s.id}'),
                    title: Text(s.title),
                    subtitle: Text(
                      [
                        if (s.shootDate != null) m.date(s.shootDate),
                        t.shotsInShoot(s.nShots),
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onPick(s.id),
                  ),
              ],
            ),
    );
  }
}

class _Shots extends ConsumerWidget {
  const _Shots({required this.shootId});

  final String shootId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReferencesStrings.of(context);
    final m = MoreStrings.of(context);
    final shoot = ref.watch(shootProvider(shootId));
    return shoot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(shootProvider(shootId)),
          child: Text(m.retry),
        ),
      ),
      data: (s) => s.shots.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(StudioSpacing.xl),
                child: Text(t.noShots, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              children: [
                for (final shot in s.shots)
                  ListTile(
                    key: ValueKey('pick-shot-${shot.id}'),
                    title: Text(shot.what),
                    subtitle: shot.setup == null ? null : Text(shot.setup!),
                    onTap: () => Navigator.of(context).pop(shot.id),
                  ),
              ],
            ),
    );
  }
}

/// Pick a piece by searching. Returns the piece id, or null.
Future<String?> showPiecePicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => const _PiecePicker(),
  );
}

class _PiecePicker extends ConsumerStatefulWidget {
  const _PiecePicker();

  @override
  ConsumerState<_PiecePicker> createState() => _PiecePickerState();
}

class _PiecePickerState extends ConsumerState<_PiecePicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final t = ReferencesStrings.of(context);
    final m = MoreStrings.of(context);
    final pieces = ref.watch(piecePickerProvider(_q));
    final height = MediaQuery.sizeOf(context).height * 0.7;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StudioSpacing.gutter,
                ),
                child: Text(
                  t.pickPieceTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              MoreSearchField(
                hint: t.searchPieces,
                onChanged: (q) => setState(() => _q = q),
              ),
              Expanded(
                child: pieces.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: TextButton(
                      onPressed: () => ref.invalidate(piecePickerProvider(_q)),
                      child: Text(m.retry),
                    ),
                  ),
                  data: (items) => items.isEmpty
                      ? Center(child: Text(t.noPieces))
                      : ListView(
                          children: [
                            for (final p in items)
                              ListTile(
                                key: ValueKey('pick-piece-${p.id}'),
                                leading: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: StudioThumb(media: p.picture),
                                ),
                                title: Text(p.title),
                                subtitle: Text(p.id),
                                onTap: () => Navigator.of(context).pop(p.id),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
