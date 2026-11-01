import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/lead.dart';
import '../../domain/lead_clustering.dart';
import '../leads_theme.dart';
import 'tier_pill.dart';

/// Lists the leads behind one map pin that zooming cannot pull apart — two
/// shops in the same mall, or one place saved twice — so the rep can still
/// open each of them. Returns the lead picked, or null when dismissed.
///
/// Carries no new strings on purpose: every row is the lead's own name, area
/// and tier, and the header is just a count.
class StackedLeadsSheet extends StatelessWidget {
  const StackedLeadsSheet({
    super.key,
    required this.leads,
    this.categoryColors = const {},
    this.myLocation,
  });

  final List<Lead> leads;
  final Map<String, String?> categoryColors;

  /// When known, rows are nearest-first and show their distance.
  final LatLng? myLocation;

  static Future<Lead?> show(
    BuildContext context, {
    required List<Lead> leads,
    Map<String, String?> categoryColors = const {},
    LatLng? myLocation,
  }) {
    return showModalBottomSheet<Lead>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => StackedLeadsSheet(
        leads: leads,
        categoryColors: categoryColors,
        myLocation: myLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final origin = myLocation;
    final rows = origin != null
        ? sortByDistance(leads, origin)
        : ([...leads]..sort((a, b) => _label(a)
            .toLowerCase()
            .compareTo(_label(b).toLowerCase())));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                // An icon already bundled elsewhere: a glyph new to the app
                // rewrites the tree-shaken icon font, and Shorebird refuses
                // to patch an asset change.
                const Icon(Icons.location_on, color: LeadsTheme.deepPlum),
                const SizedBox(width: 8),
                Text(
                  '${leads.length}',
                  style: LeadsTheme.heading.copyWith(fontSize: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
              itemBuilder: (context, i) => _row(context, rows[i], origin),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, Lead lead, LatLng? origin) {
    final label = _label(lead);
    final metres = origin == null ? null : metresToLead(origin, lead);
    final details = [
      if (lead.primaryArea.isNotEmpty) lead.primaryArea,
      if (lead.category?.isNotEmpty ?? false) lead.category!,
      if (metres != null) formatDistance(context, metres),
    ].join('  ·  ');

    return ListTile(
      onTap: () => Navigator.of(context).pop(lead),
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: LeadsTheme.categoryColor(
          lead.category,
          configuredColor: categoryColors[lead.category],
        ),
      ),
      title: Directionality(
        textDirection: LeadsTheme.isArabic(label)
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LeadsTheme.nameStyle(label),
        ),
      ),
      subtitle: details.isEmpty
          ? null
          : Text(details,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LeadsTheme.bodyMuted),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TierPill(lead.tier, dense: true),
          const SizedBox(width: 4),
          // Mirrors itself under Arabic (matchTextDirection).
          const Icon(Icons.chevron_right, color: LeadsTheme.muted),
        ],
      ),
    );
  }

  static String _label(Lead lead) =>
      lead.leadName.isEmpty ? lead.name : lead.leadName;
}
