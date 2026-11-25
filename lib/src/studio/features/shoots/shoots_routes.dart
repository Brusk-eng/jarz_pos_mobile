import 'package:go_router/go_router.dart';

import 'presentation/on_set_screen.dart';
import 'presentation/public_prep_screen.dart';
import 'presentation/shoot_edit_screen.dart';
import 'presentation/shoot_screen.dart';
import 'presentation/shoots_list_screen.dart';

/// The routes of the shoot screens. An integration step adds them to the
/// Studio router, as top-level routes above the shell (On set is full screen):
///
/// - `/shoots`: upcoming and past shoots.
/// - `/shoots/new`: plan a shoot. Must be listed before `/shoots/:id`.
/// - `/shoots/:id`: the shoot page; `/shoots/:id/edit`; `/shoots/:id/on-set`
///   (optional `?shot=<shot id>` opens at that shot).
/// - `/prep/:token`: the public read-only prep page. The router's sign-in
///   redirect must let it through (no login).
List<RouteBase> shootsRoutes() => [
  GoRoute(path: '/shoots', builder: (_, _) => const ShootsListScreen()),
  GoRoute(path: '/shoots/new', builder: (_, _) => const ShootEditScreen()),
  GoRoute(
    path: '/shoots/:id',
    builder: (_, state) => ShootScreen(shootId: state.pathParameters['id']!),
    routes: [
      GoRoute(
        path: 'edit',
        builder: (_, state) =>
            ShootEditScreen(shootId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: 'on-set',
        builder: (_, state) => OnSetScreen(
          shootId: state.pathParameters['id']!,
          startShotId: state.uri.queryParameters['shot'],
        ),
      ),
    ],
  ),
  GoRoute(
    path: '/prep/:token',
    builder: (_, state) =>
        PublicPrepScreen(token: state.pathParameters['token']!),
  ),
];
