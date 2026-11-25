import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/studio_models.dart';

/// What the person typed in the search box on the reports list.
final reportsSearchProvider = StateProvider<String>((ref) => '');

/// The reports whose title, topic (summary) or kind contain [query]. The
/// server filters by kind and date; the text search runs on what is loaded.
List<StudioReport> filterReports(List<StudioReport> items, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return [
    for (final r in items)
      if (r.title.toLowerCase().contains(q) ||
          (r.summary ?? '').toLowerCase().contains(q) ||
          r.kind.wire.toLowerCase().contains(q))
        r,
  ];
}
