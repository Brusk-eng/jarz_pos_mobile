import '../router/studio_screen.dart';

/// Where a tapped push (or in-app notification) opens.
///
/// A pure function of the FCM data payload (contract 1.10; every value is a
/// string): `type` is `studio_<event>`, `route` the exact route to open,
/// `doctype`/`docname` the record. No Firebase here; the push plumbing calls
/// this with `message.data`.
///
/// The contract's `route` is used as is when it is one of the known shapes
/// (see [isKnownStudioRoute]). When it is missing or unknown the event code
/// decides, built from `docname`; an unknown event with no usable route opens
/// Today. Detail routes (`/inbox/approve/<id>`, `/calendar/post/<id>`...) are
/// returned verbatim: a screen that does not exist yet is the router's job to
/// fall back from, not this table's.
String studioPushLocation(Map<String, String?> payload) =>
    studioAppRoute(_contractRoute(payload));

/// The contract names every screen at the top (`/paid`, `/references`...). The
/// Shoots, Library and prep screens live at those paths; References, Paid,
/// Results, Reports and Settings live under `/more` (so the More tab stays
/// selected), and the contract's name redirects there. This maps a contract route (query kept) to the app's route and
/// leaves every other route as it is.
String studioAppRoute(String route) {
  final m = RegExp(
    r'^/(references|paid|results|reports|settings)(?=$|[/?#])',
  ).firstMatch(route);
  if (m == null) return route;
  final rest = route.substring(m.end);
  // `/settings?section=rules` (the rules-changed line on Today) opens the Rules.
  if (m.group(1) == 'settings' && rest == '?section=rules') {
    return '/more/settings/rules';
  }
  return '/more/${m.group(1)}$rest';
}

String _contractRoute(Map<String, String?> payload) {
  final route = (payload['route'] ?? '').trim();
  if (route.isNotEmpty && isKnownStudioRoute(route)) return route;
  final id = (payload['docname'] ?? '').trim();
  final byEvent = _byEvent(
    payload['type'] ?? '',
    id,
    (payload['doctype'] ?? '').trim(),
  );
  return byEvent ?? StudioRoutes.today;
}

/// The notification id of a push, for `notifications.mark_read` when opened.
String? studioPushNotificationId(Map<String, String?> payload) {
  final id = (payload['notification_id'] ?? '').trim();
  return id.isEmpty ? null : id;
}

final _routePatterns = <RegExp>[
  RegExp(
    r'^/(today|inbox|inbox/approve|inbox/ideas|calendar|pieces|shoots|assets|references|paid|results|reports|settings|more)$',
  ),
  RegExp(r'^/inbox/approve/[^/?#]+$'),
  RegExp(r'^/inbox/decisions/[^/?#]+$'),
  RegExp(r'^/calendar/post/[^/?#]+$'),
  RegExp(r'^/pieces/[^/?#]+$'),
  RegExp(r'^/shoots/[^/?#]+$'),
  RegExp(r'^/prep/[^/?#]+$'),
];

/// True when [route] (query string allowed) has one of the shapes of contract 1.9.
bool isKnownStudioRoute(String route) {
  final path = route.split('?').first;
  return _routePatterns.any((p) => p.hasMatch(path));
}

String? _byEvent(String type, String id, String doctype) {
  String withId(String base) => id.isEmpty ? base : '$base/$id';
  switch (type) {
    case 'studio_version_waiting':
    case 'studio_waited_too_long':
      return id.isEmpty ? StudioRoutes.inboxApprove : '/inbox/approve/$id';
    case 'studio_decision_waiting':
      return id.isEmpty ? StudioRoutes.inboxDecisions : '/inbox/decisions/$id';
    case 'studio_sent_back':
    case 'studio_rated':
    case 'studio_commented':
      return withId(StudioRoutes.pieces);
    case 'studio_assigned':
      if (id.isEmpty) return StudioRoutes.today;
      return switch (doctype) {
        'Studio Piece' => '/pieces/$id',
        'Studio Shoot' => '/shoots/$id',
        'Social Post' => '/calendar/post/$id',
        _ => '/today?task=$id',
      };
    case 'studio_shoot_tomorrow':
      return withId(StudioRoutes.shoots);
    case 'studio_ready_to_post':
    case 'studio_post_published':
    case 'studio_post_failed':
    case 'studio_read_due':
      return id.isEmpty ? StudioRoutes.calendar : '/calendar/post/$id';
    case 'studio_paid_due':
      return StudioRoutes.paid;
    case 'studio_job_failed':
    case 'studio_digest':
      return StudioRoutes.today;
  }
  return null;
}
