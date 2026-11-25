/// Every destination in the Studio shell. Strings, help sheets and empty
/// states are looked up by this key.
enum StudioScreen {
  today,
  approve,
  decisions,
  ideas,
  calendar,
  pieces,
  piece,
  shoots,
  shoot,
  assets,
  references,
  paid,
  results,
  reports,
  settings,
}

/// Route paths. Hash URLs on web come from go_router's default strategy.
class StudioRoutes {
  StudioRoutes._();

  static const boot = '/boot';
  static const login = '/login';
  static const noAccess = '/no-access';
  static const today = '/today';
  static const inboxApprove = '/inbox/approve';
  static const inboxDecisions = '/inbox/decisions';
  static const inboxIdeas = '/inbox/ideas';
  static const calendar = '/calendar';
  static const pieces = '/pieces';
  static const more = '/more';
  static const shoots = '/shoots';
  static const assets = '/assets';
  static const references = '/references';
  static const paid = '/paid';
  static const results = '/results';
  static const reports = '/reports';
  static const settings = '/settings';

  static String piece(String id) => '/pieces/$id';
  static String shoot(String id) => '/shoots/$id';
}
