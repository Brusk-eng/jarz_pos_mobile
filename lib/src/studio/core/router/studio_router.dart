import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/session/presentation/boot_screen.dart';
import '../../features/session/presentation/login_screen.dart';
import '../../features/session/presentation/no_access_screen.dart';
import '../../features/session/state/studio_session_notifier.dart';
import '../../features/shell/presentation/inbox_screen.dart';
import '../../features/shell/presentation/more_screen.dart';
import '../../features/shell/presentation/shell_scaffold.dart';
import '../../features/shell/presentation/today_screen.dart';
import '../../shared/placeholder_screen.dart';
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

  Widget placeholder(StudioScreen s, {String? parent}) =>
      StudioPlaceholderScreen(screen: s, parentRoute: parent);

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
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: StudioRoutes.calendar,
                builder: (_, _) => placeholder(StudioScreen.calendar),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: StudioRoutes.pieces,
                builder: (_, _) => placeholder(StudioScreen.pieces),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => StudioPlaceholderScreen(
                      screen: StudioScreen.piece,
                      parentRoute: StudioRoutes.pieces,
                      titleSuffix: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // More owns the list and every screen reachable from it, so the
          // More tab stays selected while you are inside one.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: StudioRoutes.more,
                builder: (_, _) => const StudioMoreScreen(),
              ),
              GoRoute(
                path: StudioRoutes.shoots,
                builder: (_, _) =>
                    placeholder(StudioScreen.shoots, parent: StudioRoutes.more),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => StudioPlaceholderScreen(
                      screen: StudioScreen.shoot,
                      parentRoute: StudioRoutes.shoots,
                      titleSuffix: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: StudioRoutes.assets,
                builder: (_, _) =>
                    placeholder(StudioScreen.assets, parent: StudioRoutes.more),
              ),
              GoRoute(
                path: StudioRoutes.references,
                builder: (_, _) => placeholder(
                  StudioScreen.references,
                  parent: StudioRoutes.more,
                ),
              ),
              GoRoute(
                path: StudioRoutes.paid,
                builder: (_, _) =>
                    placeholder(StudioScreen.paid, parent: StudioRoutes.more),
              ),
              GoRoute(
                path: StudioRoutes.results,
                builder: (_, _) => placeholder(
                  StudioScreen.results,
                  parent: StudioRoutes.more,
                ),
              ),
              GoRoute(
                path: StudioRoutes.reports,
                builder: (_, _) => placeholder(
                  StudioScreen.reports,
                  parent: StudioRoutes.more,
                ),
              ),
              GoRoute(
                path: StudioRoutes.settings,
                builder: (_, _) => placeholder(
                  StudioScreen.settings,
                  parent: StudioRoutes.more,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
