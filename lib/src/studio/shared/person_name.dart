/// The one place a raw person id from the server (`claude`, `abdelrahman`,
/// `kareem`: `posted_by`, `waits_on`, `raised_by`) becomes a name to show.
///
/// A person object (`PersonRef`) already carries `full_name`: use that and
/// never this. This is only for the contract's plain-string fields. Each word
/// of the id gets a capital letter (`claude` is Claude, `ali_mamdouh` is Ali
/// Mamdouh); an id that is already written as a name is left as it is.
String personName(String? id) {
  final raw = (id ?? '').trim();
  if (raw.isEmpty) return '';
  // An email address or a Frappe user name: the part before the @.
  final base = raw.contains('@') ? raw.split('@').first : raw;
  if (base.contains(' ') || base != base.toLowerCase()) return base;
  return base
      .split(RegExp(r'[._\-]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
