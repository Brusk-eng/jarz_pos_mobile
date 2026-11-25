import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/roles/studio_role.dart';
import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../session/state/studio_session_notifier.dart';
import '../pieces_strings.dart';
import '../state/pieces_view_state.dart';
import 'board_view.dart';
import 'list_view.dart';
import 'piece_create_screen.dart';
import 'week_view.dart';

/// The Pieces tab: three views of the same list, remembered per person.
class PiecesScreen extends ConsumerWidget {
  const PiecesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = StudioStrings.of(context);
    final s = PiecesStrings.of(context);
    final view = ref.watch(piecesViewProvider);
    final role = ref.watch(studioSessionProvider).valueOrNull?.primaryRole;
    // Making a piece is for the lead and the founder.
    final canCreate = role == StudioRole.founder || role == StudioRole.lead;

    return ViewEditScaffold(
      title: t.tabPieces,
      rootTab: true,
      screen: StudioScreen.pieces,
      showLanguageSwitch: true,
      actions: [
        if (canCreate)
          IconButton(
            key: const ValueKey('new-piece'),
            tooltip: s.newPiece,
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              final id = await Navigator.of(context, rootNavigator: true)
                  .push<String>(
                    MaterialPageRoute(
                      builder: (_) => const PieceCreateScreen(),
                    ),
                  );
              if (id != null && context.mounted) {
                context.push('/pieces/$id');
              }
            },
          ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StudioSpacing.gutter,
              StudioSpacing.sm,
              StudioSpacing.gutter,
              0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<PiecesView>(
                key: const ValueKey('pieces-view-switch'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: PiecesView.board,
                    label: Text(s.viewBoard, key: const ValueKey('view-board')),
                  ),
                  ButtonSegment(
                    value: PiecesView.week,
                    label: Text(s.viewWeek, key: const ValueKey('view-week')),
                  ),
                  ButtonSegment(
                    value: PiecesView.list,
                    label: Text(s.viewList, key: const ValueKey('view-list')),
                  ),
                ],
                selected: {view},
                onSelectionChanged: (v) =>
                    ref.read(piecesViewProvider.notifier).choose(v.first),
              ),
            ),
          ),
          Expanded(
            child: switch (view) {
              PiecesView.board => const PiecesBoardView(),
              PiecesView.week => const PiecesWeekView(),
              PiecesView.list => const PiecesListView(),
            },
          ),
        ],
      ),
    );
  }
}
