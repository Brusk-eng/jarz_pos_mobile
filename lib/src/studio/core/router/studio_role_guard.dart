import '../../data/models/studio_models.dart';
import '../../features/session/data/me_profile_x.dart';
import '../roles/studio_role.dart';

/// Which screen of the More section a typed address opens, as the nav key
/// `session.me` uses for it; null for a screen no role is kept out of.
String? _navKeyOf(String path) {
  final m = RegExp(
    r'^/more/(references|paid|results|reports|settings)(?=$|/)',
  ).firstMatch(path);
  if (m != null) return m.group(1);
  // Shoots and the Library sit at the contract's own paths, above the shell.
  return RegExp(r'^/(shoots|assets)(?=$|/)').firstMatch(path)?.group(1);
}

/// The path a person may not open, or null when the address is fine.
///
/// A role only opens the screens its menu offers (`session.me.nav`, the
/// order in [moreOrder] when the server gave none), and the sub-routes of an
/// allowed entry. Returns true when [location] must be turned away.
bool studioRoleBlocks(MeProfile me, String location) {
  final path = Uri.parse(location).path;
  final key = _navKeyOf(path);
  if (key == null) return false;
  final role = me.primaryRole;
  final allowed = me.nav.isNotEmpty
      ? {for (final n in me.nav) n.key}
      : {
          if (role != null)
            for (final i in moreOrder[role]!) i.name,
        };
  // A creator's Results come with the app, not the server's list.
  // The sub-routes of an allowed entry (Settings > Moments) follow it.
  return !allowed.contains(key);
}
