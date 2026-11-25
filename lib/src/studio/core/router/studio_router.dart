import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/calendar_routes.dart';
import '../../features/inbox/inbox_routes.dart';
import '../../features/pieces/pieces_routes.dart';
import '../../features/review/review_routes.dart';
import '../../features/assets/assets_routes.dart';
import '../../features/session/presentation/boot_screen.dart';
import '../../features/shoots/shoots_routes.dart';
import '../../features/shell/more_routes.dart';
import '../../features/session/presentation/login_screen.dart';
import '../../features/session/presentation/no_access_screen.dart';
import '../../features/session/state/studio_session_notifier.dart';
import '../../features/shell/presentation/inbox_screen.dart';
import '../../features/shell/presentation/more_screen.dart';
import '../../features/shell/presentation/shell_scaffold.dart';
import '../../features/shell/presentation/today_screen.dart';
import '../push/studio_push_router.dart';
import 'studio_screen.dart';

const _authRoutes = {
  StudioRoutes.boot,
  StudioRoutes.login,
  StudioRoutes.noAccess,
  '/',
};

/// The Studio router. Hash URLs on web are go_router's default; every
/// destination is deep-linkable. Signed-out users are sent to /login and
/// returned to the page they asked for.
final studioRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(studioSessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  String withFrom(String target, GoRouterState state) {
    final loc = state.matchedLocation;
    final from =
        state.uri.queryParameters['from'] ??
        (_authRoutes.contains(loc) ? null : state.uri.toString());
    return from == null
        ? target
        : Uri(path: target, queryParameters: {'from': from}).toString();
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final session = ref.read(studioSessionProvider);
    final loc = state.matchedLocation;
    // The contract's route names (/paid, /shoots/<id>...) open the screens
    // under /more.
    final here = state.uri.toString();
    final mapped = studioAppRoute(here);
    if (mapped != here) return mapped;
    if (loc.startsWith('/prep/')) return null; // public read-only page

    if (session.isLoading || session.hasError) {
      return loc == StudioRoutes.boot
          ? null
          : withFrom(StudioRoutes.boot, state);
    }
    final me = session.valueOrNull;
    if (me == null) {
      return loc == StudioRoutes.login
          ? null
          : withFrom(StudioRoutes.login, state);
    }
    if (!me.hasStudioAccess) {
      return loc == StudioRoutes.noAccess ? null : StudioRoutes.noAccess;
    }
    if (_authRoutes.contains(loc)) {
      return state.uri.queryParameters['from'] ?? StudioRoutes.today;
    }
    return null;
  }

  return GoRouter(
    initialLocation: StudioRoutes.today,
    refreshListenable: refresh,
    redirect: redirect,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => StudioRoutes.today),
      GoRoute(
        path: StudioRoutes.boot,
        builder: (_, _) => const StudioBootScreen(),
      ),
      GoRoute(
        path: StudioRoutes.login,
        builder: (_, _) => const StudioLoginScreen(),
      ),
      GoRoute(
        path: StudioRoutes.noAccess,
        builder: (_, _) => const StudioNoAccessScreen(),
      ),
      // Above the shell, so the bottom bar does not cover the action bar.
      // `/inbox/approve/:id` comes before any `/inbox/:tab` route.
      ...reviewRoutes(),
      // Top-level, above the shell (On set is full screen); the contract's
      // paths. `/prep/:token` is public: the redirect lets it through.
      ...shootsRoutes(),
      ...assetsRoutes(),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => StudioShellScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: StudioRoutes.today,
                builder: (_, _) => const StudioTodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                redirect: (_, state) => state.fullPath == '/inbox'
                    ? StudioRoutes.inboxApprove
                    : null,
                routes: [
                  for (final (i, name) in [
                    'approve',
                    'decisions',
                    'ideas',
                  ].indexed)
                    GoRoute(
                      path: name,
                      builder: (_, _) => StudioInboxScreen(initialIndex: i),
                    ),
                  ...inboxRoutes(),
                ],
              ),
            ],
          ),
          StatefulShellBranch(routes: calendarRoutes()),
          StatefulShellBranch(routes: piecesRoutes()),
          // More owns the list and every screen reachable from it, so the
          // More tab stays selected while you are inside one.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: StudioRoutes.more,
                builder: (_, _) => const StudioMoreScreen(),
                routes: [...moreRoutes()],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
