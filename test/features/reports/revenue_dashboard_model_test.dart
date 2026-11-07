// Revenue dashboard (contract v2, daily-first): the model reads the backend's
// payload key for key (fixtures are real builder output), an old payload
// without the v2 keys still parses, and the screen renders the period
// buttons, hero, attention rows and breakdowns on a 360dp phone in both
// languages, without the removed trend / donut / top lists.

import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/reports/data/models/revenue_dashboard.dart';
import 'package:jarz_pos/src/features/reports/presentation/screens/revenue_dashboard_screen.dart';
import 'package:jarz_pos/src/features/reports/state/reports_providers.dart';

Map<String, dynamic> _json([String name = 'revenue_dashboard']) =>
    Map<String, dynamic>.from(
      jsonDecode(
            File('test/fixtures/reports/$name.json').readAsStringSync(),
          )
          as Map,
    );

const _periodKeys = [
  'revenue-period-today',
  'revenue-period-yesterday',
  'revenue-period-last-7-days',
  'revenue-period-month-to-date',
  'revenue-period-custom',
];

void main() {
  group('model, today', () {
    final d = RevenueDashboard.fromJson(_json());

    test('reads the envelope and filters', () {
      expect(d.isEmpty, isFalse);
      expect(d.generatedAt, '2026-10-18 14:05:11');
      expect(d.today, '2026-10-18');
      expect(d.filters.dateFrom, '2026-10-18');
      expect(d.filters.dateTo, '2026-10-18');
      expect(d.filters.branch, isNull);
    });

    test('reads the snapshot periods with their v2 comparison fields', () {
      final t = d.snapshot.today;
      expect(t.netSales, 4682.5);
      expect(t.changePct, -36.0);
      expect(t.compareFrom, '2026-10-11');
      expect(t.compareTo, '2026-10-11');
      expect(t.compareAov, 365.98);
      expect(t.ordersChangePct, -10.0);
      expect(t.aovChangePct, -23.6);
      expect(t.compareCutAt, '14:05');
      expect(t.labelFrom, '2026-10-18');
      expect(t.labelTo, '2026-10-18');
      expect(d.snapshot.yesterday.changePct, -0.7);
      expect(d.snapshot.yesterday.compareCutAt, isNull);
      expect(d.snapshot.last7Days.labelFrom, '2026-10-12');
      expect(d.snapshot.last7Days.labelTo, '2026-10-18');
      expect(d.snapshot.last7Days.changePct, -4.6);
      expect(d.snapshot.monthToDate.labelFrom, '2026-10-01');
      expect(d.snapshot.monthToDate.changePct, -2.0);
    });

    test('B2C incl. shipping parses, and is null on an old server', () {
      final s = RevenueSummary.fromJson({
        'b2c': 100,
        'b2c_shipping_income': 12.5,
        'b2c_incl_shipping': 112.5,
      });
      expect(s.b2cShippingIncome, 12.5);
      expect(s.b2cInclShipping, 112.5);
      final old = RevenueSummary.fromJson({'b2c': 100});
      expect(old.b2cShippingIncome, 0);
      expect(old.b2cInclShipping, isNull);
    });

    test('reads the summary and the like-for-like previous window', () {
      final s = d.summary;
      expect(s.netSales, 4682.5);
      expect(s.orders, 18);
      expect(s.aov, 279.58);
      expect(s.b2c, 4562.5);
      expect(s.b2b, 0);
      expect(s.newCustomers, 9);
      expect(s.discountTotal, 147.37);
      expect(s.returns, 1);
      expect(s.returnsValue, 350.0);
      expect(s.cancelled, 2);
      expect(s.cancelledValue, 780.0);
      expect(s.totalRevenue, 5087.5);
      expect(s.days, 1);
      final p = s.previous;
      expect(p.dateFrom, '2026-10-11');
      expect(p.dateTo, '2026-10-11');
      expect(p.cutAt, '14:05');
      expect(p.aov, 365.98);
      expect(p.aovChangePct, -23.6);
      expect(p.discountTotal, 215.99);
      expect(p.ordersChangePct, -10.0);
      expect(p.changePct, -36.0);
    });

    test('reads the attention items in the backend order', () {
      expect(d.hasAttention, isTrue);
      expect(d.attention.map((a) => a.kind), [
        'cancelled',
        'returns',
        'branch_drop',
        'branch_drop',
        'source_drop',
        'source_drop',
      ]);
      expect(d.attention[0].count, 2);
      expect(d.attention[0].value, 780.0);
      expect(d.attention[0].isHigh, isFalse);
      final zamalek = d.attention[2];
      expect(zamalek.name, 'Zamalek');
      expect(zamalek.isHigh, isTrue);
      expect(zamalek.netSales, 808.49);
      expect(zamalek.compareNetSales, 2422.73);
      expect(zamalek.changePct, -66.6);
      expect(d.attention[4].name, 'talabat');
      expect(d.attention[4].isHigh, isTrue);
      expect(d.attention[5].severity, 'medium');
    });

    test('reads the breakdowns with their change fields', () {
      expect(d.bySource.map((r) => r.source), [
        'pos',
        'woo',
        'talabat',
        'partner',
        'staff',
      ]);
      expect(d.bySource[2].compareNetSales, 1352.16);
      expect(d.bySource[2].changePct, -76.6);
      expect(d.bySource.last.changePct, 0.0);

      expect(d.byPayment.map((r) => r.method), [
        'Instapay',
        'Cash',
        'Card',
        'Kashier',
        'Talabat',
      ]);
      expect(d.byPayment.first.sharePct, 32.0);

      expect(d.byBranch.map((r) => r.branch), ['Nasr City', 'Dokki', 'Zamalek']);
      final nasr = d.byBranch.first;
      expect(nasr.compareNetSales, 2444.0);
      expect(nasr.changePct, -10.9);
      expect(nasr.compareB2c, 2324.0);
      expect(nasr.b2cChangePct, -11.5);

      expect(d.hourly, hasLength(24));
      expect(d.hourly[9].netSales, 0);
      expect(d.hourly[10].netSales, greaterThan(0));
      expect(d.hourly[13].netSales, greaterThan(0));
      expect(d.hourly[14].netSales, 0);

      expect(d.fulfilment.deliveryOrders, 15);
      expect(d.fulfilment.pickupOrders, 3);
    });
  });

  group('model, last 7 days', () {
    final d = RevenueDashboard.fromJson(_json('revenue_dashboard_week'));

    test('reads the range figures and the previous window', () {
      expect(d.filters.dateFrom, '2026-10-12');
      expect(d.filters.dateTo, '2026-10-18');
      final s = d.summary;
      expect(s.days, 7);
      expect(s.dailyAverage, 12111.6);
      expect(s.bestDay?.date, '2026-10-12');
      expect(s.bestDay?.netSales, 15838.59);
      expect(s.worstDay?.date, '2026-10-14');
      expect(s.previous.dateFrom, '2026-10-05');
      expect(s.previous.dateTo, '2026-10-11');
      expect(s.previous.cutAt, '14:05');
      expect(d.attention.map((a) => a.kind), ['cancelled', 'returns']);
      expect(d.fulfilment.deliveryOrders, 192);
      expect(d.fulfilment.pickupOrders, 49);
      expect(d.hourly[10].netSales, greaterThan(0));
      expect(d.hourly[23].netSales, greaterThan(0));
    });
  });

  group('model, tolerance', () {
    test('an old (v1) payload without the v2 keys still parses', () {
      final old = _json()
        ..remove('attention')
        ..['summary'] = (Map<String, dynamic>.from(_json()['summary'] as Map)
          ..['previous'] = {
            'date_from': '2026-10-11',
            'date_to': '2026-10-11',
            'net_sales': 7319.52,
            'orders': 20,
            'change_pct': -36.0,
          })
        ..['snapshot'] = {
          'today': {'net_sales': 100, 'change_pct': 5.0},
        }
        ..['by_source'] = [
          {'source': 'pos', 'net_sales': 10, 'orders': 1, 'share_pct': 100},
        ]
        ..['by_branch'] = [
          {'branch': 'Dokki', 'net_sales': 10, 'orders': 1},
        ];
      final d = RevenueDashboard.fromJson(old);
      expect(d.hasAttention, isFalse);
      expect(d.attention, isEmpty);
      expect(d.snapshot.today.netSales, 100);
      expect(d.snapshot.today.compareAov, isNull);
      expect(d.snapshot.today.ordersChangePct, isNull);
      expect(d.snapshot.today.aovChangePct, isNull);
      expect(d.snapshot.today.compareCutAt, isNull);
      expect(d.summary.previous.aov, isNull);
      expect(d.summary.previous.aovChangePct, isNull);
      expect(d.summary.previous.discountTotal, 0);
      expect(d.summary.previous.cutAt, isNull);
      expect(d.bySource.single.changePct, isNull);
      expect(d.bySource.single.compareNetSales, 0);
      expect(d.byBranch.single.changePct, isNull);
      expect(d.byBranch.single.b2cChangePct, isNull);
    });

    test('unknown attention kinds are dropped, the rest kept in order', () {
      final d = RevenueDashboard.fromJson({
        'attention': [
          {'kind': 'weather_alert', 'severity': 'high'},
          {'kind': 'returns', 'count': 1, 'value': 50},
          'not an item',
          {'severity': 'high'},
          {'kind': 'discount_high', 'severity': 'HIGH', 'value': 900},
        ],
      });
      expect(d.hasAttention, isTrue);
      expect(d.attention.map((a) => a.kind), ['returns', 'discount_high']);
      expect(d.attention.first.severity, 'medium');
      expect(d.attention.last.isHigh, isTrue);
    });

    test('a sparse {} payload does not throw and reads as zeros', () {
      final e = RevenueDashboard.fromJson(const {});
      expect(e.isEmpty, isTrue);
      expect(e.hasAttention, isFalse);
      expect(e.snapshot.today.netSales, 0);
      expect(e.snapshot.today.changePct, isNull);
      expect(e.summary.netSales, 0);
      expect(e.summary.aov, isNull);
      expect(e.summary.bestDay, isNull);
      expect(e.summary.previous.changePct, isNull);
      expect(e.bySource, isEmpty);
      expect(e.byBranch, isEmpty);
      expect(e.fulfilment.total, 0);
      expect(e.hourly, hasLength(24));
      expect(e.hourly.every((h) => h.orders == 0), isTrue);
    });

    test('partial rows and wrong types fall back instead of throwing', () {
      final e = RevenueDashboard.fromJson({
        'snapshot': {
          'today': {'net_sales': '1500.5', 'orders': null},
        },
        'summary': {'best_day': null, 'previous': 'oops'},
        'attention': 'oops',
        'by_hour': [
          {'hour': 20, 'orders': 3},
          {'orders': 9}, // no hour: dropped
          'not a row',
        ],
      });
      expect(e.snapshot.today.netSales, 1500.5);
      expect(e.snapshot.today.orders, 0);
      expect(e.summary.bestDay, isNull);
      expect(e.summary.previous.netSales, 0);
      expect(e.hasAttention, isFalse);
      expect(e.hourly[20].orders, 3);
      expect(e.hourly.fold<int>(0, (a, h) => a + h.orders), 3);
    });
  });

  group('screen', () {
    Future<void> pump(
      WidgetTester tester,
      RevenueDashboard data,
      Locale locale, {
      ReportRange? range,
    }) async {
      final view = tester.view;
      view.physicalSize = const Size(360 * 2, 7000 * 2);
      view.devicePixelRatio = 2;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            revenueDashboardProvider.overrideWith((ref, q) => data),
            reportBranchesProvider.overrideWith((ref) => const []),
            reportBranchProvider.overrideWith((ref) => null),
            revenueRangeProvider.overrideWith(
              (ref) =>
                  range ??
                  ReportRange(
                    from: DateTime(2026, 10, 18),
                    to: DateTime(2026, 10, 18),
                  ),
            ),
          ],
          child: MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const RevenueDashboardScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
    }

    Finder inKey(String key, Finder matching) =>
        find.descendant(of: find.byKey(ValueKey(key)), matching: matching);

    testWidgets('English, 360dp, today: every section, no removed card', (
      tester,
    ) async {
      await pump(tester, RevenueDashboard.fromJson(_json()), const Locale('en'));
      expect(tester.takeException(), isNull);

      for (final k in _periodKeys) {
        expect(find.byKey(ValueKey(k)), findsOneWidget, reason: k);
      }
      expect(inKey('revenue-period-today', find.text('Today')), findsOneWidget);
      expect(
        inKey('revenue-period-yesterday', find.text('▼ 0.7%')),
        findsOneWidget,
      );
      expect(
        inKey('revenue-period-month-to-date', find.text('▼ 2.0%')),
        findsOneWidget,
      );

      // Hero.
      expect(find.byKey(const ValueKey('revenue-hero')), findsOneWidget);
      expect(inKey('revenue-hero', find.text('▼ 36.0%')), findsOneWidget);
      expect(inKey('revenue-hero', find.text('▼ 10.0%')), findsOneWidget);
      expect(inKey('revenue-hero', find.text('▼ 23.6%')), findsOneWidget);
      expect(inKey('revenue-hero', find.text('Average order')), findsOneWidget);
      expect(find.text('vs Sun 11 Oct up to 14:05'), findsOneWidget);
      expect(find.textContaining('9 new customers'), findsOneWidget);
      expect(find.textContaining('15 delivery / 3 pickup'), findsOneWidget);
      expect(find.textContaining('Cancelled 2'), findsOneWidget);
      // B2C / B2B is a visual split, no longer caption text; discounts left
      // the hero (they stay in the attention list and the CSV).
      const split = 'revenue-hero-channel-split';
      expect(inKey('revenue-hero', find.byKey(const ValueKey(split))),
          findsOneWidget);
      expect(inKey(split, find.text('B2C')), findsOneWidget);
      expect(inKey(split, find.text('B2B')), findsOneWidget);
      expect(inKey(split, find.text('100.0%')), findsOneWidget);
      expect(inKey(split, find.text('0.0%')), findsOneWidget);
      expect(inKey('revenue-hero', find.textContaining('Discounts')),
          findsNothing);
      expect(inKey('revenue-hero', find.textContaining('B2C 4')), findsNothing);
      // A single day has no daily average / best / worst line.
      expect(find.byKey(const ValueKey('revenue-hero-days')), findsNothing);

      // Needs attention: six rows in order.
      expect(find.byKey(const ValueKey('revenue-attention')), findsOneWidget);
      expect(find.text('Needs attention'), findsOneWidget);
      for (var i = 0; i < 6; i++) {
        expect(
          find.byKey(ValueKey('revenue-attention-$i')),
          findsOneWidget,
          reason: 'row $i',
        );
      }
      expect(
        inKey('revenue-attention-0', find.textContaining('2 cancelled orders')),
        findsOneWidget,
      );
      expect(
        inKey('revenue-attention-1', find.textContaining('1 return')),
        findsOneWidget,
      );
      expect(
        inKey(
          'revenue-attention-2',
          find.textContaining('Zamalek B2C down 66.6%'),
        ),
        findsOneWidget,
      );
      expect(
        inKey('revenue-attention-4', find.textContaining('Talabat down 76.6%')),
        findsOneWidget,
      );
      expect(
        inKey('revenue-attention-5', find.textContaining('Website down 35.8%')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('revenue-attention-empty')),
        findsNothing,
      );

      // Where it came from.
      expect(find.text('By source'), findsOneWidget);
      expect(find.text('By payment method'), findsWidgets);
      expect(find.text('By branch'), findsOneWidget);
      expect(
        inKey('revenue-where-from', find.text('▼ 76.6%')),
        findsOneWidget,
      );
      expect(inKey('revenue-where-from', find.text('Zamalek')), findsOneWidget);

      // By hour, footer links, updated time.
      expect(find.byKey(const ValueKey('revenue-by-hour')), findsOneWidget);
      expect(find.text('By hour'), findsOneWidget);
      expect(find.byKey(const ValueKey('revenue-link-products')), findsOneWidget);
      expect(find.byKey(const ValueKey('revenue-link-b2b')), findsOneWidget);
      expect(find.text('Updated 14:05'), findsOneWidget);

      // Removed: trend, donut / split card, top lists, fulfilment card.
      expect(find.text('B2B vs B2C trend'), findsNothing);
      expect(find.text('Top 10 products'), findsNothing);
      expect(find.text('Top 10 B2B customers'), findsNothing);
      expect(find.text('Delivery vs pickup'), findsNothing);
      expect(find.text('Jar 0'), findsNothing);
      expect(find.text('Cafe One'), findsNothing);
      expect(find.byType(PieChart), findsNothing);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('English, last 7 days: range comparison and day stats', (
      tester,
    ) async {
      await pump(
        tester,
        RevenueDashboard.fromJson(_json('revenue_dashboard_week')),
        const Locale('en'),
        range: ReportRange(
          from: DateTime(2026, 10, 12),
          to: DateTime(2026, 10, 18),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('vs 5–11 Oct up to 14:05'), findsOneWidget);
      expect(find.byKey(const ValueKey('revenue-hero-days')), findsOneWidget);
      expect(find.textContaining('Best Mon 12 Oct'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('revenue-hero-channel-split')),
        findsOneWidget,
      );
      expect(find.textContaining('Worst Wed 14 Oct'), findsOneWidget);
      expect(find.byKey(const ValueKey('revenue-attention-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('revenue-attention-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('revenue-attention-2')), findsNothing);
    });

    testWidgets('an empty attention list shows one subtle line', (
      tester,
    ) async {
      final json = _json()..['attention'] = <Object>[];
      await pump(tester, RevenueDashboard.fromJson(json), const Locale('en'));
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('revenue-attention-empty')),
        findsOneWidget,
      );
      expect(find.text('Nothing needs attention'), findsOneWidget);
      expect(find.byKey(const ValueKey('revenue-attention')), findsNothing);
    });

    testWidgets('an old payload without attention hides the section', (
      tester,
    ) async {
      final json = _json()..remove('attention');
      await pump(tester, RevenueDashboard.fromJson(json), const Locale('en'));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('revenue-attention')), findsNothing);
      expect(
        find.byKey(const ValueKey('revenue-attention-empty')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('revenue-hero')), findsOneWidget);
    });

    testWidgets('B2C tile shows "incl. shipping" only when the server sends it', (
      tester,
    ) async {
      final withIt = _json();
      (withIt['summary'] as Map<String, dynamic>)
        ..['b2c_shipping_income'] = 300.0
        ..['b2c_incl_shipping'] = 4862.5;
      await pump(tester, RevenueDashboard.fromJson(withIt), const Locale('en'));
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('revenue-hero-channel-split')),
          matching: find.textContaining('incl. shipping'),
        ),
        findsOneWidget,
      );
      // The grey leakage line no longer carries the total.
      expect(inKey('revenue-hero', find.textContaining('Total incl.')),
          findsNothing);
    });

    testWidgets('B2C tile hides "incl. shipping" on an old server', (
      tester,
    ) async {
      await pump(tester, RevenueDashboard.fromJson(_json()), const Locale('en'));
      expect(find.byKey(const ValueKey('revenue-hero-b2c-incl-shipping')),
          findsNothing);
    });

    testWidgets('Arabic, 360dp: renders right-to-left without overflow', (
      tester,
    ) async {
      await pump(tester, RevenueDashboard.fromJson(_json()), const Locale('ar'));
      expect(tester.takeException(), isNull);
      for (final k in _periodKeys) {
        expect(find.byKey(ValueKey(k)), findsOneWidget, reason: k);
      }
      expect(inKey('revenue-period-today', find.text('اليوم')), findsOneWidget);
      expect(find.text('يحتاج متابعة'), findsOneWidget);
      expect(find.byKey(const ValueKey('revenue-attention-5')), findsOneWidget);
      expect(find.text('حسب المصدر'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('revenue-hero-channel-split')),
        findsOneWidget,
      );
    });

    testWidgets('Arabic, last 7 days renders without overflow', (tester) async {
      await pump(
        tester,
        RevenueDashboard.fromJson(_json('revenue_dashboard_week')),
        const Locale('ar'),
        range: ReportRange(
          from: DateTime(2026, 10, 12),
          to: DateTime(2026, 10, 18),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('revenue-hero-days')), findsOneWidget);
    });

    testWidgets('a sparse payload shows the empty state, not a crash', (
      tester,
    ) async {
      await pump(tester, RevenueDashboard.fromJson(const {}), const Locale('en'));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('revenue-hero')), findsNothing);
      // The period buttons stay so the range can be changed.
      expect(find.byKey(const ValueKey('revenue-period-today')), findsOneWidget);
    });

    testWidgets('a zeroed payload still renders every card', (tester) async {
      await pump(
        tester,
        RevenueDashboard.fromJson(const {'today': '2026-10-18'}),
        const Locale('en'),
      );
      expect(tester.takeException(), isNull);
      for (final k in _periodKeys) {
        expect(find.byKey(ValueKey(k)), findsOneWidget, reason: k);
      }
      expect(find.byKey(const ValueKey('revenue-hero')), findsOneWidget);
      expect(find.byKey(const ValueKey('revenue-where-from')), findsOneWidget);
      // No B2C or B2B sales: no channel split.
      expect(
        find.byKey(const ValueKey('revenue-hero-channel-split')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('revenue-by-hour')), findsOneWidget);
    });
  });
}
