import 'package:go_router/go_router.dart';

import 'presentation/calendar_screen.dart';
import 'presentation/drift_screen.dart';
import 'presentation/post_screen.dart';

/// The Calendar tab root and the post screen. The integration step puts these
/// in the router in place of the placeholder:
///
/// * `/calendar` is [CalendarScreen] (the tab root).
/// * `/calendar/post/:id` is [PostScreen].
List<RouteBase> calendarRoutes() => [
  GoRoute(
    path: '/calendar',
    builder: (_, _) => const CalendarScreen(),
    routes: [
      GoRoute(path: 'drift', builder: (_, _) => const DriftScreen()),
      GoRoute(
        path: 'post/:id',
        builder: (_, state) => PostScreen(postId: state.pathParameters['id']!),
      ),
    ],
  ),
];
