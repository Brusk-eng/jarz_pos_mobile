import 'package:go_router/go_router.dart';

import 'presentation/add_version_screen.dart';
import 'presentation/piece_screen.dart';
import 'presentation/pieces_screen.dart';

/// The Pieces tab root and the piece screen. The integration step puts these
/// in the router in place of the placeholders:
///
/// * `/pieces` is [PiecesScreen] (the tab root).
/// * `/pieces/:id` is [PieceScreen]; `/pieces/:id/add-version` adds a cut or
///   the frames of a story.
List<RouteBase> piecesRoutes() => [
  GoRoute(
    path: '/pieces',
    builder: (_, _) => const PiecesScreen(),
    routes: [
      GoRoute(
        path: ':id',
        builder: (_, state) =>
            PieceScreen(pieceId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'add-version',
            builder: (_, state) =>
                AddVersionScreen(pieceId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  ),
];
