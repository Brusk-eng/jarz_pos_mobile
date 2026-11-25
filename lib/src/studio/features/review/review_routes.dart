import 'package:go_router/go_router.dart';

import 'presentation/rate_feed_screen.dart';
import 'presentation/version_screen.dart';

/// The routes of the review screens. An integration step adds them to the
/// Studio router (as top-level routes, above the shell, so the bottom bar
/// does not cover the action bar):
///
/// - `/versions/:id` and `/inbox/approve/:id`: one version (media, verdict,
///   ratings, comments, actions).
/// - `/inbox/rate`: the swipe feed of versions waiting for my rating.
///
/// `/inbox/approve/:id` must be listed before any `/inbox/:tab` route so the
/// id is not read as a tab.
List<RouteBase> reviewRoutes() => [
  GoRoute(
    path: '/versions/:id',
    builder: (_, state) => VersionScreen(
      versionId: state.pathParameters['id']!,
      parentRoute: '/pieces',
    ),
  ),
  GoRoute(
    path: '/inbox/approve/:id',
    builder: (_, state) => VersionScreen(
      versionId: state.pathParameters['id']!,
      parentRoute: '/inbox/approve',
    ),
  ),
  GoRoute(
    path: '/inbox/rate',
    builder: (_, _) => const RateFeedScreen(parentRoute: '/inbox/approve'),
  ),
];
