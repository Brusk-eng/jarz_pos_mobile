// Grid clustering and straight-line distance for the leads map.
//
// This is the layer a rep trusts to answer "how many are there" and "which is
// nearest", so it is pure and tested rather than delegated to a marker-cluster
// plugin. Nothing here touches the network, a plugin, or a paid routing API.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/leads/data/models/lead.dart';
import 'package:jarz_pos/src/features/leads/domain/lead_clustering.dart';
import 'package:latlong2/latlong.dart';

/// Real Cairo coordinates, so the distances below are sanity-checkable by hand.
const _tahrir = LatLng(30.0444, 31.2357);

Lead _lead(String name, {double? lat, double? lng, String? category}) => Lead(
      name: name,
      leadName: name,
      category: category,
      latitude: lat,
      longitude: lng,
    );

void main() {
  group('locatableLeads', () {
    test('keeps leads with real coordinates', () {
      final leads = [_lead('A', lat: 30.04, lng: 31.23)];
      expect(locatableLeads(leads), hasLength(1));
    });

    test('drops leads with no coordinates', () {
      expect(locatableLeads([_lead('A')]), isEmpty);
      expect(locatableLeads([_lead('A', lat: 30.0)]), isEmpty);
      expect(locatableLeads([_lead('A', lng: 31.0)]), isEmpty);
    });

    test('drops Null Island, which is what a failed parse looks like', () {
      expect(locatableLeads([_lead('A', lat: 0, lng: 0)]), isEmpty);
    });

    test('drops out-of-range coordinates', () {
      expect(locatableLeads([_lead('A', lat: 300, lng: 31.2)]), isEmpty);
      expect(locatableLeads([_lead('A', lat: 30.0, lng: 999)]), isEmpty);
    });
  });

  group('clusterLeads', () {
    test('far-apart leads stay separate pins at high zoom', () {
      final leads = [
        _lead('A', lat: 30.0444, lng: 31.2357), // Tahrir
        _lead('B', lat: 30.0626, lng: 31.2497), // Zamalek, ~2km away
      ];
      final clusters = clusterLeads(leads, 16);
      expect(clusters, hasLength(2));
      expect(clusters.every((c) => c.isSingle), isTrue);
    });

    test('the same leads merge into one counted pin when zoomed out', () {
      final leads = [
        _lead('A', lat: 30.0444, lng: 31.2357),
        _lead('B', lat: 30.0626, lng: 31.2497),
      ];
      final clusters = clusterLeads(leads, 8);
      expect(clusters, hasLength(1));
      expect(clusters.single.count, 2);
      expect(clusters.single.isSingle, isFalse);
    });

    test('every lead is accounted for exactly once, at any zoom', () {
      // The property that matters most: clustering must never lose or
      // duplicate a prospect. A rep counts these.
      final leads = [
        for (var i = 0; i < 60; i++)
          _lead('L$i', lat: 30.0 + i * 0.004, lng: 31.2 + i * 0.004),
      ];
      for (final zoom in [4.0, 8.0, 11.0, 14.0, 18.0]) {
        final clusters = clusterLeads(leads, zoom);
        final names = <String>[];
        for (final c in clusters) {
          names.addAll(c.leads.map((l) => l.name));
        }
        expect(names, hasLength(60), reason: 'lost or duplicated at z$zoom');
        expect(names.toSet(), hasLength(60), reason: 'duplicated at z$zoom');
      }
    });

    test('zooming out never increases the pin count', () {
      final leads = [
        for (var i = 0; i < 40; i++)
          _lead('L$i', lat: 30.0 + i * 0.01, lng: 31.2 + i * 0.01),
      ];
      var previous = clusterLeads(leads, 18).length;
      for (final zoom in [16.0, 14.0, 12.0, 10.0, 8.0, 6.0]) {
        final current = clusterLeads(leads, zoom).length;
        expect(current, lessThanOrEqualTo(previous),
            reason: 'pin count grew while zooming out to z$zoom');
        previous = current;
      }
    });

    test('a single-lead cluster exposes its lead', () {
      final lead = _lead('A', lat: 30.04, lng: 31.23);
      final cluster = clusterLeads([lead], 16).single;
      expect(cluster.isSingle, isTrue);
      expect(cluster.single?.name, 'A');
    });

    test('a group exposes no single and sits between its members', () {
      final leads = [
        _lead('A', lat: 30.00, lng: 31.20),
        _lead('B', lat: 30.02, lng: 31.22),
      ];
      final cluster = clusterLeads(leads, 8).single;
      expect(cluster.single, isNull);
      expect(cluster.center.latitude, closeTo(30.01, 0.001));
      expect(cluster.center.longitude, closeTo(31.21, 0.001));
    });

    test('bigger groups sort last so they paint on top', () {
      final leads = [
        _lead('solo', lat: 31.5, lng: 30.0),
        for (var i = 0; i < 5; i++)
          _lead('c$i', lat: 30.0 + i * 0.0001, lng: 31.2),
      ];
      final clusters = clusterLeads(leads, 12);
      expect(clusters.last.count, greaterThan(clusters.first.count));
    });

    test('unmappable leads are skipped rather than clustered at (0,0)', () {
      final leads = [
        _lead('good', lat: 30.04, lng: 31.23),
        _lead('nowhere'),
        _lead('null-island', lat: 0, lng: 0),
      ];
      final clusters = clusterLeads(leads, 12);
      expect(clusters, hasLength(1));
      expect(clusters.single.single?.name, 'good');
    });

    test('an empty catalog yields no pins', () {
      expect(clusterLeads(const [], 12), isEmpty);
    });
  });

  group('distance', () {
    test('measures a known Cairo hop within a sensible tolerance', () {
      // Tahrir -> Zamalek is roughly 2 km as the crow flies.
      final metres = metresBetween(_tahrir, const LatLng(30.0626, 31.2497));
      expect(metres, greaterThan(1500));
      expect(metres, lessThan(3000));
    });

    test('is zero to itself', () {
      expect(metresBetween(_tahrir, _tahrir), closeTo(0, 0.001));
    });

    test('metresToLead returns null for an unmappable lead', () {
      expect(metresToLead(_tahrir, _lead('A')), isNull);
      expect(metresToLead(_tahrir, _lead('A', lat: 0, lng: 0)), isNull);
    });

    // The unit suffix comes from the ARB, so these need a Localizations scope.
    // Pinned to English; the Arabic wording is covered by ARB parity, not here.
    testWidgets('formats sub-kilometre in metres', (tester) async {
      await _withContext(tester, (ctx) {
        expect(formatDistance(ctx, 0), '0 m');
        expect(formatDistance(ctx, 820), '820 m');
        expect(formatDistance(ctx, 999), '999 m');
      });
    });

    testWidgets('formats a decimal km up to 10, then rounds', (tester) async {
      await _withContext(tester, (ctx) {
        expect(formatDistance(ctx, 1000), '1.0 km');
        // toStringAsFixed rounds half up
        expect(formatDistance(ctx, 3450), '3.5 km');
        expect(formatDistance(ctx, 12400), '12 km');
      });
    });

    testWidgets('never renders a garbage number', (tester) async {
      await _withContext(tester, (ctx) {
        expect(formatDistance(ctx, double.nan), '');
        expect(formatDistance(ctx, double.infinity), '');
        expect(formatDistance(ctx, -5), '');
      });
    });
  });

  group('sortByDistance', () {
    test('orders nearest first', () {
      final leads = [
        _lead('far', lat: 30.20, lng: 31.40),
        _lead('near', lat: 30.045, lng: 31.236),
        _lead('mid', lat: 30.08, lng: 31.28),
      ];
      final sorted = sortByDistance(leads, _tahrir);
      expect(sorted.map((l) => l.name), ['near', 'mid', 'far']);
    });

    test('leads with no coordinates sort last instead of vanishing', () {
      final leads = [
        _lead('nowhere'),
        _lead('near', lat: 30.045, lng: 31.236),
      ];
      final sorted = sortByDistance(leads, _tahrir);
      expect(sorted.map((l) => l.name), ['near', 'nowhere']);
      expect(sorted, hasLength(2));
    });

    test('does not mutate the input list', () {
      final leads = [
        _lead('far', lat: 30.20, lng: 31.40),
        _lead('near', lat: 30.045, lng: 31.236),
      ];
      final original = [...leads];
      sortByDistance(leads, _tahrir);
      expect(leads.map((l) => l.name), original.map((l) => l.name));
    });
  });

  group('clusterNeedsPicker', () {
    // Two shops in one mall, ~10 m apart: no zoom the map allows splits them.
    final mall = [
      _lead('Espressolab', lat: 30.08010, lng: 31.33010),
      _lead('Cake shop', lat: 30.08015, lng: 31.33018),
    ];

    LeadCluster groupOf(List<Lead> leads, double zoom) {
      final clusters = clusterLeads(leads, zoom);
      expect(clusters, hasLength(1), reason: 'fixture must form one group');
      return clusters.single;
    }

    test('lists a group that stays one pin even at max zoom', () {
      final group = groupOf(mall, kLeadMapMaxZoom);
      expect(group.count, 2);
      expect(clusterNeedsPicker(group, kLeadMapMaxZoom), isTrue);
      // Straight to the list from far out too: zooming would never help.
      expect(clusterNeedsPicker(groupOf(mall, 11), 11), isTrue);
    });

    test('zooms a far-out group that zooming will split', () {
      final spread = [
        _lead('A', lat: 30.0444, lng: 31.2357),
        _lead('B', lat: 30.0626, lng: 31.2497), // ~2 km
      ];
      expect(clusterNeedsPicker(groupOf(spread, 10), 10), isFalse);
    });

    test('lists any group once the map is close in', () {
      final street = [
        _lead('A', lat: 30.08000, lng: 31.33000),
        _lead('B', lat: 30.08000, lng: 31.33060), // ~60 m
      ];
      final group = groupOf(street, kLeadMapListFromZoom);
      expect(clusterNeedsPicker(group, kLeadMapListFromZoom), isTrue);
      expect(clusterNeedsPicker(group, kLeadMapListFromZoom - 1.5), isFalse);
    });

    test('never lists a single pin', () {
      final single = clusterLeads([mall.first], kLeadMapMaxZoom).single;
      expect(clusterNeedsPicker(single, kLeadMapMaxZoom), isFalse);
    });
  });
}

/// Hands [body] a BuildContext under a Localizations scope, for the helpers
/// that read their unit suffixes from the ARB.
Future<void> _withContext(
  WidgetTester tester,
  void Function(BuildContext context) body,
) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  body(captured);
}
