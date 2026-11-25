import 'package:go_router/go_router.dart';

import '../decisions/presentation/decision_screen.dart';
import '../ideas/presentation/my_ideas_screen.dart';
import '../notifications/presentation/notification_prefs_screen.dart';
import '../notifications/presentation/notifications_screen.dart';

/// Extra Inbox routes, relative to `/inbox`. The integration step adds them
/// as children of the `/inbox` GoRoute in `studio_router.dart`:
///
/// * `/inbox/decisions/:id`        one decision (push and Today deep link)
/// * `/inbox/my-ideas`            the ideas I raised, any status
/// * `/inbox/notifications`        the notification list
/// * `/inbox/notifications/settings`  quiet hours and digest
///
/// `/inbox/rate` and `/inbox/approve/:id` belong to the version screens.
List<RouteBase> inboxRoutes() => [
  GoRoute(
    path: 'decisions/:id',
    builder: (_, state) =>
        DecisionScreen(decisionId: state.pathParameters['id']!),
  ),
  GoRoute(path: 'my-ideas', builder: (_, _) => const MyIdeasScreen()),
  GoRoute(
    path: 'notifications',
    builder: (_, _) => const NotificationsScreen(),
    routes: [
      GoRoute(
        path: 'settings',
        builder: (_, _) => const NotificationPrefsScreen(),
      ),
    ],
  ),
];
