import 'package:go_router/go_router.dart';

import 'presentation/asset_form_screens.dart';
import 'presentation/asset_screen.dart';
import 'presentation/library_screen.dart';

/// The routes of the Library screens. An integration step adds them to the
/// Studio router as top-level routes above the shell:
///
/// - `/assets`: the Library grid.
/// - `/assets/new`: add files (must be listed before `/assets/:id`).
/// - `/assets/:id`: one file; `/assets/:id/edit`.
List<RouteBase> assetsRoutes() => [
  GoRoute(path: '/assets', builder: (_, _) => const LibraryScreen()),
  GoRoute(path: '/assets/new', builder: (_, _) => const AssetAddScreen()),
  GoRoute(
    path: '/assets/:id',
    builder: (_, state) => AssetScreen(assetId: state.pathParameters['id']!),
    routes: [
      GoRoute(
        path: 'edit',
        builder: (_, state) =>
            AssetEditScreen(assetId: state.pathParameters['id']!),
      ),
    ],
  ),
];
