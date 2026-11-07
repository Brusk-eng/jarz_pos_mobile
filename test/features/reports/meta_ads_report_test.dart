// Meta Ads report: the model reads the contract payload tolerantly (numbers
// as int, double or string; nulls; missing keys), sorting and the filter
// rules behave, the repository sends the contract's arguments, and the
// screen renders in English and Arabic on a small phone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/constants/api_endpoints.dart';
import 'package:jarz_pos/src/features/reports/data/models/meta_ads_report.dart';
import 'package:jarz_pos/src/features/reports/data/reports_repository.dart';
import 'package:jarz_pos/src/features/reports/presentation/screens/meta_ads_screen.dart';
import 'package:jarz_pos/src/features/reports/state/meta_ads_providers.dart';
import 'package:jarz_pos/src/features/reports/state/reports_providers.dart';

import '../../helpers/mock_services.dart';

/// A payload shaped like the contract, with the number types mixed on purpose.
Map<String, dynamic> _payload({String level = 'ad'}) => {
  'configured': true,
  'level': level,
  'date_from': '2026-11-01',
  'date_to': '2026-11-07',
  'currency': 'EGP',
  'fetched_at': '2026-11-07 14:03:11',
  'totals': {
    'spend': 1500, // int
    'impressions': '120000', // string
    'reach': 80000.0, // double for an int field
    'frequency': 1.5,
    'link_clicks': 2400,
    'ctr': '2.0',
    'cpc': 0.625,
    'cpm': 12.5,
    'purchases': 30,
    'purchase_value': 21000.5,
    'roas': 14.0,
    'cost_per_purchase': 50,
    'erp_orders': '18',
    'erp_revenue': 12600,
    'erp_roas': 8.4,
  },
  'rows': [
    {
      'id': '120001',
      'name': 'UGC-Sarah v2',
      'status': 'ACTIVE',
      'campaign_id': 'c1',
      'campaign_name': 'Sales — Jars',
      'adset_id': 's1',
      'adset_name': 'Cairo 25-45',
      'thumbnail_url': 'https://example.invalid/thumb.jpg',
      'spend': 1000.0,
      'impressions': 90000,
      'link_clicks': 1800,
      'ctr': 2.0,
      'purchases': 20,
      'purchase_value': 15000,
      'roas': 15.0,
      'cost_per_purchase': 50.0,
      'erp_orders': 12,
      'erp_revenue': 9000,
      'erp_roas': 9.0,
    },
    {
      'id': 120002, // id as a number
      'name': 'Static - Gift box',
      'status': 'paused',
      'campaign_id': 'c1',
      'campaign_name': 'Sales — Jars',
      'adset_id': 's2',
      'adset_name': 'Giza',
      'thumbnail_url': null,
      'spend': '500',
      'impressions': 30000,
      'link_clicks': 600,
      'ctr': '2.00',
      'purchases': '10',
      'purchase_value': 6000.5,
      'roas': 12.001,
      'cost_per_purchase': '50',
      'erp_orders': 6,
      'erp_revenue': 3600,
      'erp_roas': 7.2,
    },
  ],
  'filters': {
    'campaigns': [
      {'id': 'c1', 'name': 'Sales — Jars', 'status': 'ACTIVE'},
      {'id': 'c2', 'name': 'Awareness', 'status': 'PAUSED'},
    ],
    'adsets': [
      {'id': 's1', 'name': 'Cairo 25-45', 'campaign_id': 'c1', 'status': 'ACTIVE'},
      {'id': 's2', 'name': 'Giza', 'campaign_id': 'c1', 'status': 'ACTIVE'},
      {'id': 's3', 'name': 'Lookalike', 'campaign_id': 'c2', 'status': 'PAUSED'},
    ],
  },
  'notes': ['Meta counts every placed web order, cancelled ones too.'],
};

MetaAdsRow _row(
  String name, {
  double spend = 0,
  double purchases = 0,
  double roas = 0,
  double ctr = 0,
  double cpp = 0,
  int erp = 0,
}) => MetaAdsRow(
  id: name,
  name: name,
  metrics: MetaAdsMetrics(
    spend: spend,
    purchases: purchases,
    roas: roas,
    ctr: ctr,
    costPerPurchase: cpp,
    erpOrders: erp,
  ),
);

void main() {
  group('model', () {
    final report = MetaAdsReport.fromJson(_payload());

    test('reads the envelope', () {
      expect(report.configured, isTrue);
      expect(report.level, MetaAdsLevel.ad);
      expect(report.dateFrom, '2026-11-01');
      expect(report.dateTo, '2026-11-07');
      expect(report.currency, 'EGP');
      expect(report.fetchedAt, '2026-11-07 14:03:11');
      expect(report.notes, hasLength(1));
      expect(report.campaigns.map((c) => c.id), ['c1', 'c2']);
      expect(report.adsets.map((a) => a.campaignId), ['c1', 'c1', 'c2']);
    });

    test('totals accept int, double and string numbers', () {
      final t = report.totals;
      expect(t.spend, 1500.0);
      expect(t.impressions, 120000);
      expect(t.reach, 80000);
      expect(t.linkClicks, 2400);
      expect(t.ctr, 2.0);
      expect(t.purchases, 30);
      expect(t.purchaseValue, 21000.5);
      expect(t.roas, 14.0);
      expect(t.costPerPurchase, 50.0);
      expect(t.erpOrders, 18);
      expect(t.erpRevenue, 12600.0);
      expect(t.erpRoas, 8.4);
    });

    test('rows read metrics from the row itself, ids and status normalised', () {
      final a = report.rows.first;
      expect(a.name, 'UGC-Sarah v2');
      expect(a.adsetName, 'Cairo 25-45');
      expect(a.thumbnailUrl, startsWith('https://'));
      expect(a.metrics.spend, 1000.0);
      expect(a.metrics.erpOrders, 12);

      final b = report.rows.last;
      expect(b.id, '120002');
      expect(b.status, 'PAUSED');
      expect(b.thumbnailUrl, isNull);
      expect(b.metrics.spend, 500.0);
      expect(b.metrics.purchases, 10);
      expect(b.metrics.costPerPurchase, 50.0);
    });

    test('nulls, garbage and missing keys fall back to zero / empty', () {
      final r = MetaAdsReport.fromJson({
        'level': 'ADSET',
        'totals': {'spend': null, 'ctr': 'n/a', 'erp_orders': '3.0'},
        'rows': [
          {'id': 's9', 'name': null, 'adset_id': null, 'thumbnail_url': ''},
          'not a map',
        ],
        'filters': null,
        'notes': [null, '', 'kept'],
      });
      expect(r.configured, isTrue);
      expect(r.level, MetaAdsLevel.adset);
      expect(r.currency, 'EGP');
      expect(r.totals.spend, 0);
      expect(r.totals.ctr, 0);
      expect(r.totals.erpOrders, 3);
      expect(r.rows, hasLength(1));
      expect(r.rows.single.name, 's9');
      expect(r.rows.single.adsetId, isNull);
      expect(r.rows.single.thumbnailUrl, isNull);
      expect(r.campaigns, isEmpty);
      expect(r.notes, ['kept']);
    });

    test('an empty payload does not throw', () {
      final r = MetaAdsReport.fromJson(const {});
      expect(r.rows, isEmpty);
      expect(r.level, MetaAdsLevel.ad);
      expect(r.totals.roas, 0);
    });

    test('configured=false is read in every spelling', () {
      for (final v in [false, 0, '0', 'false']) {
        expect(
          MetaAdsReport.fromJson({'configured': v}).configured,
          isFalse,
          reason: '$v',
        );
      }
    });
  });

  group('sorting', () {
    final rows = [
      _row('a', spend: 100, purchases: 2, roas: 3, ctr: 1.5, cpp: 50, erp: 1),
      _row('b', spend: 300, purchases: 0, roas: 0, ctr: 2.5, cpp: 0, erp: 0),
      _row('c', spend: 200, purchases: 8, roas: 5, ctr: 0.5, cpp: 25, erp: 4),
    ];
    List<String> names(MetaAdsSort s) =>
        sortMetaAdsRows(rows, s).map((r) => r.name).toList();

    test('descending metrics put the best first', () {
      expect(names(MetaAdsSort.spend), ['b', 'c', 'a']);
      expect(names(MetaAdsSort.purchases), ['c', 'a', 'b']);
      expect(names(MetaAdsSort.roas), ['c', 'a', 'b']);
      expect(names(MetaAdsSort.ctr), ['b', 'a', 'c']);
      expect(names(MetaAdsSort.erpOrders), ['c', 'a', 'b']);
    });

    test('cost per purchase is cheapest first, no purchases last', () {
      expect(names(MetaAdsSort.costPerPurchase), ['c', 'a', 'b']);
    });

    test('ties fall back to spend', () {
      final tied = [
        _row('low', spend: 10, roas: 2),
        _row('high', spend: 90, roas: 2),
      ];
      expect(
        sortMetaAdsRows(tied, MetaAdsSort.roas).map((r) => r.name),
        ['high', 'low'],
      );
    });

    test('does not mutate the input', () {
      sortMetaAdsRows(rows, MetaAdsSort.spend);
      expect(rows.map((r) => r.name), ['a', 'b', 'c']);
    });
  });

  group('filters', () {
    test('campaign level clears both filters; ad set level clears the ad set', () {
      final n = MetaAdsFiltersNotifier(
        const MetaAdsFilters(campaignId: 'c1', adsetId: 's1'),
      );
      n.setLevel(MetaAdsLevel.adset);
      expect(n.state.campaignId, 'c1');
      expect(n.state.adsetId, isNull);
      n.setLevel(MetaAdsLevel.campaign);
      expect(n.state.campaignId, isNull);
    });

    test('changing the campaign clears the ad set', () {
      final n = MetaAdsFiltersNotifier(
        const MetaAdsFilters(campaignId: 'c1', adsetId: 's1'),
      );
      n.setCampaign('c2');
      expect(n.state.campaignId, 'c2');
      expect(n.state.adsetId, isNull);
      n.setCampaign('');
      expect(n.state.campaignId, isNull);
    });

    test('picking an ad set selects its campaign; clearing keeps it', () {
      final n = MetaAdsFiltersNotifier();
      n.setAdset('s3', campaignId: 'c2');
      expect(n.state.adsetId, 's3');
      expect(n.state.campaignId, 'c2');
      n.setAdset(null);
      expect(n.state.adsetId, isNull);
      expect(n.state.campaignId, 'c2');
    });

    test('drill-down: campaign → its ad sets → its ads', () {
      final n = MetaAdsFiltersNotifier(
        const MetaAdsFilters(level: MetaAdsLevel.campaign),
      );
      expect(n.drillInto(const MetaAdsRow(id: 'c1', name: 'C')), isTrue);
      expect(n.state.level, MetaAdsLevel.adset);
      expect(n.state.campaignId, 'c1');
      expect(
        n.drillInto(const MetaAdsRow(id: 's1', campaignId: 'c1')),
        isTrue,
      );
      expect(n.state.level, MetaAdsLevel.ad);
      expect(n.state.adsetId, 's1');
      expect(n.state.campaignId, 'c1');
      expect(n.drillInto(const MetaAdsRow(id: 'ad1')), isFalse);
      expect(n.state.level, MetaAdsLevel.ad);
    });

    test('the sort survives level changes', () {
      final n = MetaAdsFiltersNotifier();
      n.setSort(MetaAdsSort.roas);
      n.setLevel(MetaAdsLevel.campaign);
      expect(n.state.sort, MetaAdsSort.roas);
    });
  });

  group('repository', () {
    final range = ReportRange(
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 7),
    );

    test('sends the contract arguments and unwraps the message', () async {
      final dio = MockDio();
      dio.setResponse(ApiEndpoints.getAdsReport, {'message': _payload()});
      final repo = ReportsRepository(dio);

      final r = await repo.fetchMetaAdsReport(
        MetaAdsQuery(
          range: range,
          level: MetaAdsLevel.adset,
          campaignId: 'c1',
        ),
        refresh: true,
      );

      expect(r.rows, hasLength(2));
      final sent = dio.requestLog.single;
      expect(sent['path'], ApiEndpoints.getAdsReport);
      expect(sent['data'], {
        'level': 'adset',
        'date_from': '2026-11-01',
        'date_to': '2026-11-07',
        'campaign_id': 'c1',
        'refresh': 1,
      });
    });

    test('omits empty filters and refresh by default', () async {
      final dio = MockDio();
      dio.setResponse(ApiEndpoints.getAdsReport, {
        'message': {'configured': false, 'rows': []},
      });
      final r = await ReportsRepository(dio).fetchMetaAdsReport(
        MetaAdsQuery(range: range),
      );
      expect(r.configured, isFalse);
      expect(dio.requestLog.single['data'], {
        'level': 'ad',
        'date_from': '2026-11-01',
        'date_to': '2026-11-07',
      });
    });

    test('the refresh mark is consumed once', () {
      final marks = MetaAdsRefreshRequests();
      final q = MetaAdsQuery(range: range);
      marks.mark(q);
      expect(marks.take(MetaAdsQuery(range: range)), isTrue);
      expect(marks.take(q), isFalse);
    });
  });

  group('screen', () {
    Future<List<MetaAdsQuery>> pump(
      WidgetTester tester,
      Locale locale, {
      Map<String, dynamic>? payload,
    }) async {
      final view = tester.view;
      view.physicalSize = const Size(360 * 2, 4000 * 2);
      view.devicePixelRatio = 2;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);

      final asked = <MetaAdsQuery>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            metaAdsReportProvider.overrideWith((ref, q) {
              asked.add(q);
              return MetaAdsReport.fromJson(
                payload ?? _payload(level: q.level.apiValue),
              );
            }),
            reportRangeProvider.overrideWith(
              (ref) => ReportRange(
                from: DateTime(2026, 11, 1),
                to: DateTime(2026, 11, 7),
              ),
            ),
          ],
          child: MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const MetaAdsScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      return asked;
    }

    testWidgets('English, 360dp: KPIs and rows render without overflow', (
      tester,
    ) async {
      await pump(tester, const Locale('en'));
      expect(tester.takeException(), isNull);
      expect(find.text('Meta Ads'), findsOneWidget);
      expect(find.text('UGC-Sarah v2'), findsOneWidget);
      expect(find.text('Static - Gift box'), findsOneWidget);
      // KPI ROAS, two decimals with an x.
      expect(find.text('14.00x'), findsOneWidget);
      expect(find.text('2.00%'), findsWidgets);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
      // Thumbnail fails to load in tests → fallback icon, no exception.
      expect(find.byIcon(Icons.image_not_supported_outlined), findsNWidgets(2));
      expect(find.textContaining('Meta counts every placed'), findsOneWidget);
    });

    testWidgets('Arabic, 360dp: renders right-to-left without overflow', (
      tester,
    ) async {
      await pump(tester, const Locale('ar'));
      expect(tester.takeException(), isNull);
      expect(find.text('إعلانات ميتا'), findsOneWidget);
      expect(find.text('UGC-Sarah v2'), findsOneWidget);
    });

    testWidgets('tapping a campaign drills into its ad sets', (tester) async {
      final asked = await pump(tester, const Locale('en'));
      await tester.tap(find.text('Campaigns'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(asked.last.level, MetaAdsLevel.campaign);

      await tester.tap(find.text('UGC-Sarah v2'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(asked.last.level, MetaAdsLevel.adset);
      expect(asked.last.campaignId, '120001');
    });

    testWidgets('configured=false shows the not-configured state', (
      tester,
    ) async {
      await pump(
        tester,
        const Locale('en'),
        payload: const {'configured': false, 'rows': []},
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('not configured'), findsOneWidget);
      expect(find.text('Campaigns'), findsNothing);
    });
  });
}
