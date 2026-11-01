/// Grid clustering + distance maths for the leads map.
///
/// Deliberately dependency-free and pure: no plugin, no network, no paid
/// service. Clustering is done here rather than with a marker-cluster package
/// because the packages that wrap flutter_map track its major versions closely
/// and go stale, and because a grid we own is trivially testable — which
/// matters when the output is what a rep counts on to plan a route.
///
/// Distance is straight-line (haversine) on purpose. Road distance and traffic
/// need a routing service, and every usable one is paid or rate-limited.
/// "As the crow flies" is honest, free, works offline, and is the right measure
/// for the actual question — which of these places are near me.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/localization/localization_extensions.dart';

import '../data/models/lead.dart';

/// One map pin: either a single lead or a group of them.
class LeadCluster {
  const LeadCluster({required this.center, required this.leads});

  /// Where the pin sits. For a group this is the mean of its members.
  final LatLng center;

  /// Members, never empty. Length 1 means an ordinary single-lead pin.
  final List<Lead> leads;

  bool get isSingle => leads.length == 1;
  int get count => leads.length;

  /// The lead a single-pin cluster represents. Null for a real group.
  Lead? get single => isSingle ? leads.first : null;
}

/// Deepest zoom the leads map allows.
const double kLeadMapMaxZoom = 18;

/// Zoom from which tapping a group lists its members instead of zooming in.
const double kLeadMapListFromZoom = 16;

/// Whether tapping [cluster] at [zoom] should list its members rather than
/// zoom in on them.
///
/// Zooming is the right answer while it still pulls the pins apart. It stops
/// being one when the members would still share one pin at the deepest zoom
/// (two shops in the same mall, or one place saved twice) — a tap there used
/// to zoom to the limit and then do nothing, leaving both leads unreachable.
/// Close in, a short list is also simply quicker than another pinch.
bool clusterNeedsPicker(
  LeadCluster cluster,
  double zoom, {
  double maxZoom = kLeadMapMaxZoom,
  double listFromZoom = kLeadMapListFromZoom,
}) {
  if (cluster.isSingle) return false;
  if (zoom >= listFromZoom) return true;
  return clusterLeads(cluster.leads, maxZoom).length == 1;
}

/// Leads that carry usable coordinates. Everything else cannot be mapped.
///
/// (0, 0) is excluded: Null Island is what a failed parse looks like, not a
/// real coffee shop, and one bogus pin off the coast of Africa drags the
/// auto-fit bounds across the whole Atlantic.
List<Lead> locatableLeads(Iterable<Lead> leads) {
  return leads.where((l) {
    final lat = l.latitude;
    final lng = l.longitude;
    if (lat == null || lng == null) return false;
    if (lat == 0 && lng == 0) return false;
    return lat.abs() <= 90 && lng.abs() <= 180;
  }).toList();
}

/// Groups [leads] into pins for the given [zoom].
///
/// [cellPx] is the grid size in screen pixels, so a cluster is roughly "things
/// that would overlap at this zoom" rather than a fixed distance on the ground
/// — which is what makes the grouping feel right at every zoom level instead of
/// only one. Larger values group more aggressively.
///
/// Returns single-lead clusters unchanged, so the caller renders one code path.
List<LeadCluster> clusterLeads(
  Iterable<Lead> leads,
  double zoom, {
  double cellPx = 72,
}) {
  final located = locatableLeads(leads);
  if (located.isEmpty) return const [];

  final worldPx = 256 * math.pow(2, zoom).toDouble();

  // Bucket into a pixel grid, keeping each cell's centroid in pixel space so
  // the neighbour pass below can measure without reprojecting.
  final buckets = <_Cell, List<Lead>>{};
  final sums = <_Cell, _Point>{};

  for (final lead in located) {
    final x = _projectX(lead.longitude!, worldPx);
    final y = _projectY(lead.latitude!, worldPx);
    final cell = _Cell((x / cellPx).floor(), (y / cellPx).floor());
    buckets.putIfAbsent(cell, () => <Lead>[]).add(lead);
    final sum = sums[cell];
    sums[cell] = sum == null ? _Point(x, y) : _Point(sum.x + x, sum.y + y);
  }

  // A plain grid splits neighbours that happen to straddle a cell edge — two
  // shops on the same street rendering as two pins at city zoom, which is
  // exactly what clustering is supposed to prevent. One greedy pass merges a
  // cell into an adjacent one when their centroids are within a cell of each
  // other. Seeds are taken densest-first (ties broken by cell coordinates) so
  // the result is deterministic and the big groups anchor the small ones.
  final order = buckets.keys.toList()
    ..sort((a, b) {
      final byCount = buckets[b]!.length.compareTo(buckets[a]!.length);
      if (byCount != 0) return byCount;
      final byX = a.x.compareTo(b.x);
      return byX != 0 ? byX : a.y.compareTo(b.y);
    });

  final consumed = <_Cell>{};
  final clusters = <LeadCluster>[];

  for (final seed in order) {
    if (consumed.contains(seed)) continue;
    consumed.add(seed);

    final members = <Lead>[...buckets[seed]!];
    var centroid = _centroid(sums[seed]!, buckets[seed]!.length);

    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        final neighbour = _Cell(seed.x + dx, seed.y + dy);
        if (consumed.contains(neighbour)) continue;
        final leads = buckets[neighbour];
        if (leads == null) continue;

        final other = _centroid(sums[neighbour]!, leads.length);
        if (_pixelGap(centroid, other) > cellPx) continue;

        consumed.add(neighbour);
        final total = members.length + leads.length;
        centroid = _Point(
          (centroid.x * members.length + other.x * leads.length) / total,
          (centroid.y * members.length + other.y * leads.length) / total,
        );
        members.addAll(leads);
      }
    }

    clusters.add(LeadCluster(center: _meanPoint(members), leads: members));
  }

  // Biggest groups last so they paint on top of the small ones they overlap —
  // a "20" hiding behind a single pin is the one thing clustering must not do.
  clusters.sort((a, b) => a.count.compareTo(b.count));
  return clusters;
}

/// Web Mercator X in pixels at a world size of [worldPx].
double _projectX(double lng, double worldPx) => (lng + 180) / 360 * worldPx;

/// Web Mercator Y in pixels at a world size of [worldPx].
///
/// Latitude is clamped to the Mercator limit: the projection diverges at the
/// poles and an unclamped value produces infinity, which would silently poison
/// a bucket key.
double _projectY(double lat, double worldPx) {
  final clamped = lat.clamp(-85.05112878, 85.05112878);
  final rad = clamped * math.pi / 180.0;
  final y = (1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2;
  return y * worldPx;
}

LatLng _meanPoint(List<Lead> leads) {
  if (leads.length == 1) {
    return LatLng(leads.first.latitude!, leads.first.longitude!);
  }
  var lat = 0.0;
  var lng = 0.0;
  for (final lead in leads) {
    lat += lead.latitude!;
    lng += lead.longitude!;
  }
  return LatLng(lat / leads.length, lng / leads.length);
}

const _distance = Distance();

/// Straight-line metres between two points. Free, offline, no routing service.
double metresBetween(LatLng a, LatLng b) => _distance.as(LengthUnit.Meter, a, b);

/// Straight-line metres from [origin] to a lead, or null if it has no usable
/// coordinates.
double? metresToLead(LatLng origin, Lead lead) {
  final lat = lead.latitude;
  final lng = lead.longitude;
  if (lat == null || lng == null) return null;
  if (lat == 0 && lng == 0) return null;
  return metresBetween(origin, LatLng(lat, lng));
}

/// "820 m" / "3.4 km" / "12 km".
///
/// Sub-kilometre stays in metres because that is the difference between "next
/// door" and "across the square"; past 10 km the decimal is noise on a
/// straight-line estimate and is dropped rather than implying precision the
/// measure does not have.
String formatDistance(BuildContext context, double metres) {
  final l10n = context.l10n;
  if (metres.isNaN || metres.isInfinite || metres < 0) return '';
  if (metres < 1000) return l10n.leadsDistanceMetres('${metres.round()}');
  final km = metres / 1000;
  if (km < 10) return l10n.leadsDistanceKm(km.toStringAsFixed(1));
  return l10n.leadsDistanceKm('${km.round()}');
}

/// Sorts [leads] nearest-first from [origin]. Leads with no coordinates sort
/// last rather than being dropped — they are still real prospects, they just
/// cannot answer "how far".
List<Lead> sortByDistance(List<Lead> leads, LatLng origin) {
  final sorted = [...leads];
  sorted.sort((a, b) {
    final da = metresToLead(origin, a);
    final db = metresToLead(origin, b);
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  });
  return sorted;
}

/// A grid cell coordinate. Value type so it can key a map directly.
class _Cell {
  const _Cell(this.x, this.y);
  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is _Cell && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// A point in Web Mercator pixel space.
class _Point {
  const _Point(this.x, this.y);
  final double x;
  final double y;
}

_Point _centroid(_Point sum, int count) =>
    _Point(sum.x / count, sum.y / count);

double _pixelGap(_Point a, _Point b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}
