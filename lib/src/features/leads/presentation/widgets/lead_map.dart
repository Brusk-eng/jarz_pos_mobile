import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/lead.dart';
import '../../domain/lead_clustering.dart';
import '../leads_theme.dart';

/// OpenStreetMap-backed map of the leads.
///
/// Three things it has to get right, all of which used to be wrong:
///
/// * **Visibility.** Pins were a 32px icon in a tier colour, one of which is
///   near-white — invisible on pale OSM tiles the moment you zoomed out.
///   They are now filled teardrops with a white ring and a drop shadow, so
///   they read against tiles, parks and water alike.
/// * **Density.** 1,300 leads in Greater Cairo is a solid blob at city zoom.
///   Pins now collapse into counted clusters, so zoomed out you see "20 here,
///   5 here" instead of an unreadable smear.
/// * **Meaning.** Colour now encodes the lead CATEGORY rather than tier, which
///   is what a rep is actually scanning for on a map.
class LeadMap extends StatefulWidget {
  const LeadMap({
    super.key,
    required this.leads,
    required this.onMarkerTap,
    this.onClusterTap,
    this.onStackTap,
    this.categoryColors = const {},
    this.myLocation,
    this.myLocationAccuracy,
    this.selected,
    this.center = const LatLng(30.05, 31.24), // Cairo
    this.initialZoom = 10,
    this.mapController,
  });

  final List<Lead> leads;
  final void Function(Lead lead) onMarkerTap;

  /// Called when a counted cluster is tapped. The map zooms in on it either
  /// way; this lets the screen react too (e.g. list what is inside).
  final void Function(LeadCluster cluster)? onClusterTap;

  /// Called INSTEAD of zooming when zooming cannot separate a group's pins
  /// (see [clusterNeedsPicker]), so the screen can let the rep pick one.
  final void Function(LeadCluster cluster)? onStackTap;

  /// Category name -> configured colour from the backend master.
  final Map<String, String?> categoryColors;

  final LatLng? myLocation;
  final double? myLocationAccuracy;

  /// Currently open lead, drawn larger so it stays findable behind the card.
  final Lead? selected;

  final LatLng center;
  final double initialZoom;
  final MapController? mapController;

  @override
  State<LeadMap> createState() => _LeadMapState();
}

class _LeadMapState extends State<LeadMap> {
  late final MapController _controller =
      widget.mapController ?? MapController();

  /// Zoom the clusters were last built for. Rounded to a whole level: a pinch
  /// emits a continuous stream of zooms, and re-bucketing 1,300 leads on every
  /// frame of it would drop the gesture. Regrouping at each level is invisible
  /// to the eye and cheap.
  int _clusterZoom = 0;
  late double _zoom = widget.initialZoom;

  @override
  Widget build(BuildContext context) {
    final clusters = clusterLeads(widget.leads, _clusterZoom.toDouble());

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: widget.myLocation ?? widget.center,
        initialZoom: widget.initialZoom,
        minZoom: 4,
        maxZoom: kLeadMapMaxZoom,
        onPositionChanged: (position, _) {
          final rounded = position.zoom.round();
          if (rounded != _clusterZoom) {
            setState(() {
              _clusterZoom = rounded;
              _zoom = position.zoom;
            });
          } else {
            _zoom = position.zoom;
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.jarz.pos',
          maxZoom: 19,
        ),

        // Accuracy halo under everything else, so it never obscures a pin.
        if (widget.myLocation != null && (widget.myLocationAccuracy ?? 0) > 0)
          CircleLayer(
            circles: [
              CircleMarker(
                point: widget.myLocation!,
                radius: widget.myLocationAccuracy!,
                useRadiusInMeter: true,
                color: const Color(0x221B6CA8),
                borderColor: const Color(0x551B6CA8),
                borderStrokeWidth: 1,
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            for (final cluster in clusters)
              if (cluster.isSingle)
                _singleMarker(cluster.single!)
              else
                _clusterMarker(cluster),
            if (widget.myLocation != null)
              Marker(
                point: widget.myLocation!,
                width: 26,
                height: 26,
                child: const _MyLocationDot(),
              ),
          ],
        ),
      ],
    );
  }

  Marker _singleMarker(Lead lead) {
    final isSelected = widget.selected?.name == lead.name;
    // Bigger than the old 32px icon, and bigger again when selected so the pin
    // behind an open card is still findable.
    final size = isSelected ? 46.0 : 38.0;
    return Marker(
      point: LatLng(lead.latitude!, lead.longitude!),
      width: size,
      height: size,
      // Bottom-centre: a teardrop points AT its location, so anchoring the
      // centre would place every pin half a pin north of the truth.
      alignment: Alignment.bottomCenter,
      child: _LeadPin(
        color: LeadsTheme.categoryColor(
          lead.category,
          configuredColor: widget.categoryColors[lead.category],
        ),
        size: size,
        selected: isSelected,
        notSuitable: lead.notSuitable,
        onTap: () => widget.onMarkerTap(lead),
      ),
    );
  }

  Marker _clusterMarker(LeadCluster cluster) {
    // Grows with the log of the count: linear scaling makes a 500-cluster
    // swallow the screen while a 3-cluster stays invisible.
    final magnitude = math.log(cluster.count.toDouble()) / math.ln10;
    // A group hiding the open lead is ringed, so it stays findable behind the
    // card the same way a selected single pin does.
    final holdsSelected = widget.selected != null &&
        cluster.leads.any((l) => l.name == widget.selected!.name);
    final diameter =
        (34 + 14 * magnitude).clamp(34.0, 64.0) + (holdsSelected ? 6 : 0);
    return Marker(
      point: cluster.center,
      width: diameter,
      height: diameter,
      child: _ClusterPin(
        count: cluster.count,
        diameter: diameter,
        color: _dominantColor(cluster),
        selected: holdsSelected,
        onTap: () {
          widget.onClusterTap?.call(cluster);
          if (widget.onStackTap != null && clusterNeedsPicker(cluster, _zoom)) {
            widget.onStackTap!(cluster);
            return;
          }
          // Zoom toward the cluster so a tap always makes progress.
          final target = (_zoom + 2).clamp(4.0, kLeadMapMaxZoom);
          _controller.move(cluster.center, target);
        },
      ),
    );
  }

  /// The colour of the most common category in the group, so a cluster still
  /// says something about what is inside it.
  Color _dominantColor(LeadCluster cluster) {
    final counts = <String?, int>{};
    for (final lead in cluster.leads) {
      counts[lead.category] = (counts[lead.category] ?? 0) + 1;
    }
    var best = counts.entries.first;
    for (final entry in counts.entries) {
      if (entry.value > best.value) best = entry;
    }
    return LeadsTheme.categoryColor(
      best.key,
      configuredColor: widget.categoryColors[best.key],
    );
  }
}

/// A filled teardrop with a white ring — readable on any tile.
class _LeadPin extends StatelessWidget {
  const _LeadPin({
    required this.color,
    required this.size,
    required this.selected,
    required this.notSuitable,
    required this.onTap,
  });

  final Color color;
  final double size;
  final bool selected;
  final bool notSuitable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: size,
            // A grey pin for a prospect already ruled out: it is only on the
            // map at all when the rep has asked to see them, and it should
            // never compete with live ones for attention.
            color: notSuitable ? LeadsTheme.muted : color,
            shadows: const [
              Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          // White ring in the teardrop's eye, which is what separates one pin
          // from the pin behind it when they overlap.
          Positioned(
            top: size * 0.20,
            child: Container(
              width: size * 0.30,
              height: size * 0.30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: LeadsTheme.deepPlum, width: 2)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A counted group: "20 here".
class _ClusterPin extends StatelessWidget {
  const _ClusterPin({
    required this.count,
    required this.diameter,
    required this.color,
    required this.onTap,
    this.selected = false,
  });

  final int count;
  final double diameter;
  final Color color;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? LeadsTheme.deepPlum : Colors.white,
            width: selected ? 4 : 2.5,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2)),
          ],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$count',
              style: const TextStyle(
                fontFamily: LeadsTheme.bodyFont,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The familiar blue "you are here" dot.
class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B6CA8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}
