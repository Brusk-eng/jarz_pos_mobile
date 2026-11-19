import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/network/user_service.dart';
import 'package:jarz_pos/src/features/reports/presentation/screens/stock_reports_screen.dart';
import 'package:jarz_pos/src/features/reports/presentation/widgets/final_products_reserved.dart';
import 'package:jarz_pos/src/features/reports/state/reports_providers.dart';

const _finalProducts = <String, dynamic>{
  'groups': [
    {
      'group_name': 'Jars',
      'warehouses': ['Maadi - JB'],
      'items': [
        {
          'item_name': 'Chocolate Jar',
          'warehouse_qty': {'Maadi - JB': 4},
          'total_qty': 4,
          'stock_value': 400,
        },
      ],
      'totals': {'qty': 4, 'stock_value': 400},
    },
  ],
  'totals': {'qty': 4, 'stock_value': 400},
};

/// The same report from a server that sends days of cover.
const _finalProductsWithCover = <String, dynamic>{
  'cover': {'sales_days': 14, 'red_below': 3, 'green_above': 7},
  'groups': [
    {
      'group_name': 'Jars',
      'warehouses': ['Maadi - JB', 'Zamalek - JB', 'Nasr - JB'],
      'items': [
        {
          'item_name': 'Chocolate Jar',
          'warehouse_qty': {'Maadi - JB': 4, 'Zamalek - JB': 20, 'Nasr - JB': 0},
          'total_qty': 24,
          'stock_value': 2400,
          // Maadi amber, Zamalek green, Nasr empty (red).
          // (Nasr sells it, so the backend reports 0.0 cover, not null.)
          'days_cover': {'Maadi - JB': 4.5, 'Zamalek - JB': 10.0, 'Nasr - JB': 0.0},
          'total_days_cover': 2.0,
          'sells_per_day': {'Maadi - JB': 1.0, 'Zamalek - JB': 2.0, 'Nasr - JB': 0.5},
          'total_sells_per_day': 3.5,
        },
        {
          'item_name': 'Vanilla Jar',
          'warehouse_qty': {'Maadi - JB': 5, 'Zamalek - JB': 5, 'Nasr - JB': 5},
          'total_qty': 15,
          'stock_value': 1500,
          // No recent sales anywhere: left untinted.
          'days_cover': {'Maadi - JB': null, 'Zamalek - JB': null, 'Nasr - JB': null},
          'total_days_cover': null,
          'sells_per_day': {'Maadi - JB': 0, 'Zamalek - JB': 0, 'Nasr - JB': 0},
          'total_sells_per_day': 0,
        },
      ],
      'totals': {'qty': 39, 'stock_value': 3900},
    },
  ],
  'totals': {'qty': 39, 'stock_value': 3900},
};

/// A server that also reports jars held by open (undispatched) orders.
/// Nasr has 100 Mango on the shelf, 50 of them on an order.
const _finalProductsWithReserved = <String, dynamic>{
  'cover': {'sales_days': 14, 'red_below': 3, 'green_above': 7},
  'groups': [
    {
      'group_name': 'Jars',
      'warehouses': ['Maadi - JB', 'Nasr city - JB'],
      'items': [
        {
          'item_name': 'Mango Medium',
          'warehouse_qty': {'Maadi - JB': 10, 'Nasr city - JB': 100},
          'total_qty': 110,
          'stock_value': 11000,
          'days_cover': {'Maadi - JB': 5.0, 'Nasr city - JB': 8.0},
          'total_days_cover': 7.5,
          'reserved_qty': {'Maadi - JB': 0.0, 'Nasr city - JB': 50.0},
          'available_qty': {'Maadi - JB': 10.0, 'Nasr city - JB': 50.0},
          'available_days_cover': {'Maadi - JB': 5.0, 'Nasr city - JB': 4.0},
          'total_reserved_qty': 50.0,
          'total_available_qty': 60.0,
          'total_available_days_cover': 4.1,
        },
        {
          'item_name': 'Vanilla Jar',
          'warehouse_qty': {'Maadi - JB': 3, 'Nasr city - JB': 2},
          'total_qty': 5,
          'stock_value': 500,
          'days_cover': {'Maadi - JB': null, 'Nasr city - JB': null},
          'total_days_cover': null,
          // More on orders than on the shelf: oversold after orders.
          'reserved_qty': {'Maadi - JB': 0.0, 'Nasr city - JB': 6.0},
          'available_qty': {'Maadi - JB': 3.0, 'Nasr city - JB': -4.0},
          'available_days_cover': {'Maadi - JB': null, 'Nasr city - JB': null},
          'total_reserved_qty': 6.0,
          'total_available_qty': -1.0,
          'total_available_days_cover': null,
        },
      ],
      'totals': {'qty': 115, 'stock_value': 11500, 'reserved_qty': 56.0},
    },
  ],
  'totals': {'qty': 115, 'stock_value': 11500, 'reserved_qty': 56.0},
  'reserved': {
    'qty': 56.0,
    'order_count': 2,
    'overdue_count': 1,
    'failed': false,
    'states': ['Recieved', 'In Progress'],
    'orders': [
      {
        'invoice': 'ACC-SINV-2026-00011',
        'woo_order_id': 17529,
        'customer': 'CUST-0002',
        'customer_name': 'Cafe Nour',
        'state': 'Recieved',
        'posting_date': '2026-07-03',
        'delivery_date': null,
        'delivery_slot_label': null,
        'warehouse': 'Nasr city - JB',
        'qty': 6.0,
        'overdue': true,
        'items': [
          {'item_code': 'ITEM-2', 'item_name': 'Vanilla Jar', 'qty': 6.0},
        ],
      },
      {
        'invoice': 'ACC-SINV-2026-00012',
        'woo_order_id': null,
        'customer': 'CUST-0001',
        'customer_name': 'Lucaffe',
        'state': 'In Progress',
        'posting_date': '2026-11-19',
        'delivery_date': '2026-11-20',
        'delivery_slot_label': null,
        'warehouse': 'Nasr city - JB',
        'qty': 50.0,
        'overdue': false,
        'items': [
          {'item_code': 'ITEM-1', 'item_name': 'Mango Medium', 'qty': 50.0},
        ],
      },
    ],
  },
};

const _materials = <String, dynamic>{
  'raw_materials': [
    {
      'item_name': 'Flour',
      'stock_uom': 'Kg',
      'total_qty': 10,
      'stock_value': 250,
      'warehouse_qty': {'Maadi - JB': 10},
    },
  ],
  'sub_assemblies': [],
  'consumables': [],
  'bucket_totals': {
    'raw_materials': {'qty': 10, 'stock_value': 250},
  },
  'totals': {'qty': 10, 'stock_value': 250},
};

Future<List<String?>> _pump(
  WidgetTester tester, {
  required int initialTab,
  bool singleReport = true,
  List<String> roles = const ['JARZ Manager'],
  Object? error,
  Map<String, dynamic> finalProducts = _finalProducts,
  Locale locale = const Locale('en'),
  double bottomInset = 0,
}) async {
  final view = tester.view;
  view.physicalSize = const Size(400 * 2, 1600 * 2);
  view.devicePixelRatio = 2;
  addTearDown(view.resetPhysicalSize);
  addTearDown(view.resetDevicePixelRatio);
  if (bottomInset > 0) {
    // Android draws edge to edge: the bottom inset is the navigation bar.
    view.padding = FakeViewPadding(bottom: bottomInset * 2);
    view.viewPadding = FakeViewPadding(bottom: bottomInset * 2);
    addTearDown(view.resetPadding);
    addTearDown(view.resetViewPadding);
  }

  final requested = <String?>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        finalProductsReportProvider.overrideWith((ref, branch) async {
          requested.add(branch);
          if (error != null) throw error;
          return finalProducts;
        }),
        materialsReportProvider.overrideWith((ref, branch) async {
          requested.add(branch);
          if (error != null) throw error;
          return _materials;
        }),
        reportBranchesProvider.overrideWith((ref) => const []),
        reportBranchProvider.overrideWith((ref) => 'Maadi'),
        userRolesFutureProvider.overrideWith(
          (ref) async => UserRoles(user: 'u@jarz.pos', roles: roles),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: StockReportsScreen(
          initialTab: initialTab,
          singleReport: singleReport,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return requested;
}

/// Every tinted cell background in the Final Products table.
List<Color> _tints(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(DataTable),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((d) => d.decoration)
    .whereType<BoxDecoration>()
    .map((d) => d.color)
    .whereType<Color>()
    .where((c) => c.a > 0.1 && c.a < 0.25)
    .toList();

void main() {
  group('coverTone', () {
    test('nothing on hand is red when the item sells there', () {
      expect(coverTone(0, 0, 3, 7), CoverTone.red);
      expect(coverTone(-2, 30, 3, 7), CoverTone.red);
    });
    test('nothing on hand where it never sells is untinted', () {
      expect(coverTone(0, null, 3, 7), CoverTone.none);
      expect(coverTone(-2, null, 3, 7), CoverTone.none);
    });
    test('no recent sales is untinted', () {
      expect(coverTone(5, null, 3, 7), CoverTone.none);
    });
    test('thresholds: < red_below red, up to green_above amber, above green',
        () {
      expect(coverTone(5, 2.9, 3, 7), CoverTone.red);
      expect(coverTone(5, 3, 3, 7), CoverTone.amber);
      expect(coverTone(5, 7, 3, 7), CoverTone.amber);
      expect(coverTone(5, 7.1, 3, 7), CoverTone.green);
    });
    test('thresholds come from the payload, defaulting to 3 and 7', () {
      final d = CoverThresholds.fromJson(null);
      expect(d.redBelow, 3);
      expect(d.greenAbove, 7);
      final c = CoverThresholds.fromJson({'red_below': 2, 'green_above': 10});
      expect(c.redBelow, 2);
      expect(c.greenAbove, 10);
      expect(coverTone(5, 8, c.redBelow, c.greenAbove), CoverTone.amber);
    });
  });

  testWidgets('single Final Products report: branch, value and totals',
      (tester) async {
    final requested = await _pump(tester, initialTab: 0);

    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Final Products'), findsOneWidget);
    // The selected branch reaches the provider.
    expect(requested, contains('Maadi'));
    expect(find.text('Chocolate Jar'), findsOneWidget);
    expect(find.text('Grand total'), findsOneWidget);
    expect(find.text('Stock value'), findsWidgets);
  });

  testWidgets('single Materials report shows bucket totals', (tester) async {
    await _pump(tester, initialTab: 1);

    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Materials & Consumables'), findsOneWidget);
    expect(find.text('Flour'), findsOneWidget);
    expect(find.text('Grand total'), findsOneWidget);
    expect(find.textContaining('Total qty'), findsWidgets);
  });

  testWidgets('tabbed mode never offers Final Products to a materials-only '
      'user', (tester) async {
    await _pump(tester, initialTab: 0, singleReport: false, roles: const []);

    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Materials & Consumables'), findsOneWidget);
    expect(find.text('Chocolate Jar'), findsNothing);
  });

  testWidgets('a branch without a stock warehouse shows the error view',
      (tester) async {
    await _pump(
      tester,
      initialTab: 0,
      error: Exception('No stock warehouse configured for Maadi'),
    );

    expect(find.text("Couldn't load report"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('an older server without days of cover: no legend, no tints',
      (tester) async {
    await _pump(tester, initialTab: 0);
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('final-products-cover-legend')),
      findsNothing,
    );
    expect(_tints(tester), isEmpty);
  });

  testWidgets('days of cover: legend and green / amber / red cells',
      (tester) async {
    await _pump(
      tester,
      initialTab: 0,
      finalProducts: _finalProductsWithCover,
    );
    expect(tester.takeException(), isNull);

    final legend = find.byKey(const ValueKey('final-products-cover-legend'));
    expect(legend, findsOneWidget);
    for (final label in ['Days cover', '< 3', '3–7', '> 7', 'No sales']) {
      expect(
        find.descendant(of: legend, matching: find.text(label)),
        findsOneWidget,
        reason: label,
      );
    }

    // Chocolate: Maadi amber, Zamalek green, Nasr red (empty), total red
    // (2 days). Vanilla: no sales, nothing tinted.
    final tints = _tints(tester);
    expect(tints, hasLength(4));
    Color hue(Color c) => c.withValues(alpha: 1);
    expect(tints.map(hue).toSet(), {
      const Color(0xFFFFA000),
      const Color(0xFF43A047),
      const Color(0xFFE53935),
    });
    expect(
      tints.where((c) => hue(c) == const Color(0xFFE53935)),
      hasLength(2),
    );

    // The tooltip carries the days of cover.
    expect(find.byTooltip('Maadi: 4\n4.5 days cover'), findsOneWidget);
    expect(find.byTooltip('Maadi: 5\nNo sales yet'), findsOneWidget);
  });

  testWidgets('days of cover legend fits a phone in Arabic', (tester) async {
    await _pump(
      tester,
      initialTab: 0,
      finalProducts: _finalProductsWithCover,
      locale: const Locale('ar'),
    );
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('final-products-cover-legend')),
      findsOneWidget,
    );
  });

  group('jars held by open orders', () {
    Finder inTable(Finder f) =>
        find.descendant(of: find.byType(DataTable), matching: f);
    final toggle = find.byKey(const ValueKey('final-products-view-toggle'));
    final summary = find.byKey(const ValueKey('final-products-held-summary'));

    testWidgets('an older server: on-hand numbers, no toggle, no summary',
        (tester) async {
      await _pump(
        tester,
        initialTab: 0,
        finalProducts: _finalProductsWithCover,
      );
      expect(tester.takeException(), isNull);
      expect(toggle, findsNothing);
      expect(summary, findsNothing);
      expect(find.byType(ReservedMarkerDot), findsNothing);
      expect(find.byTooltip('Maadi: 4\n4.5 days cover'), findsOneWidget);
      expect(find.textContaining('Held'), findsNothing);
    });

    testWidgets('a failed reservation read looks like an older server',
        (tester) async {
      await _pump(
        tester,
        initialTab: 0,
        finalProducts: {
          ..._finalProductsWithReserved,
          'reserved': {'qty': 0.0, 'failed': true, 'orders': []},
        },
      );
      expect(tester.takeException(), isNull);
      expect(toggle, findsNothing);
      expect(summary, findsNothing);
      expect(find.byTooltip('Nasr city: 100\n8 days cover'), findsOneWidget);
    });

    testWidgets('defaults to After orders; In stock shows the shelf',
        (tester) async {
      await _pump(
        tester,
        initialTab: 0,
        finalProducts: _finalProductsWithReserved,
      );
      expect(tester.takeException(), isNull);
      expect(toggle, findsOneWidget);

      // After orders: Nasr shows 50 of its 100 Mango, marked as held.
      expect(
        find.byTooltip(
          'Nasr city: 50 after orders · 100 in stock · 50 held · 4 days cover',
        ),
        findsOneWidget,
      );
      expect(
        find.byTooltip(
          'Total: 60 after orders · 110 in stock · 50 held · 4.1 days cover',
        ),
        findsOneWidget,
      );
      // Nothing held at Maadi: the plain tooltip, no marker.
      expect(find.byTooltip('Maadi: 10\n5 days cover'), findsOneWidget);
      expect(inTable(find.text('100')), findsNothing);
      expect(inTable(find.text('50')), findsOneWidget);
      // Vanilla is oversold once the orders go out.
      expect(inTable(find.text('-4')), findsOneWidget);
      // Mango Nasr + total, Vanilla Nasr + total.
      expect(inTable(find.byType(ReservedMarkerDot)), findsNWidgets(4));

      // Header: the summary, the after-orders grand total and the legend.
      expect(
        find.text('56 jars held for 2 open orders'),
        findsOneWidget,
      );
      expect(find.text('1 overdue'), findsOneWidget);
      expect(find.text('59'), findsOneWidget);
      expect(find.text('of 115 in stock'), findsOneWidget);
      expect(find.textContaining('Held: 56'), findsOneWidget);
      expect(find.text('Held for open orders'), findsOneWidget);

      await tester.tap(find.text('In stock'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Nasr city: 100\n8 days cover'), findsOneWidget);
      expect(find.byTooltip('Total: 110\n7.5 days cover'), findsOneWidget);
      expect(inTable(find.text('100')), findsOneWidget);
      expect(inTable(find.text('-4')), findsNothing);
      expect(find.byType(ReservedMarkerDot), findsNothing);
      expect(find.text('of 115 in stock'), findsNothing);
      expect(find.textContaining('Held: 56'), findsNothing);
      expect(find.text('Held for open orders'), findsNothing);
      // The summary stays: the orders are still open.
      expect(summary, findsOneWidget);
    });

    testWidgets('the summary opens the held orders, overdue marked',
        (tester) async {
      await _pump(
        tester,
        initialTab: 0,
        finalProducts: _finalProductsWithReserved,
      );
      await tester.tap(summary);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final sheet = find.byType(ReservedOrdersSheet);
      expect(sheet, findsOneWidget);
      Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
      expect(inSheet(find.text('Jars held for open orders')), findsOneWidget);
      // The Woo number wins; a POS order shows its invoice number.
      expect(inSheet(find.text('#17529')), findsOneWidget);
      expect(inSheet(find.text('Cafe Nour')), findsOneWidget);
      expect(inSheet(find.text('2026-00012')), findsOneWidget);
      expect(inSheet(find.text('Lucaffe')), findsOneWidget);
      expect(inSheet(find.text('Overdue')), findsOneWidget);
      expect(inSheet(find.text('6 jars')), findsOneWidget);
      expect(inSheet(find.text('50 jars')), findsOneWidget);
      expect(inSheet(find.text('Vanilla Jar ×6')), findsOneWidget);
      expect(inSheet(find.textContaining('no delivery date')), findsOneWidget);
      expect(inSheet(find.textContaining('Received')), findsOneWidget);
    });

    testWidgets('the last held order stays above the navigation bar',
        (tester) async {
      await _pump(
        tester,
        initialTab: 0,
        finalProducts: _finalProductsWithReserved,
        bottomInset: 48,
      );
      await tester.tap(summary);
      await tester.pumpAndSettle();

      final last = find.byKey(
        const ValueKey('reserved-order-ACC-SINV-2026-00012-Nasr city - JB'),
      );
      expect(last, findsOneWidget);
      const navBarTop = 1600.0 - 48;
      expect(tester.getRect(last).bottom, lessThanOrEqualTo(navBarTop));
    });

    testWidgets('works in Arabic', (tester) async {
      await _pump(
        tester,
        initialTab: 0,
        finalProducts: _finalProductsWithReserved,
        locale: const Locale('ar'),
      );
      expect(tester.takeException(), isNull);
      expect(toggle, findsOneWidget);
      expect(inTable(find.byType(ReservedMarkerDot)), findsNWidgets(4));
      await tester.tap(summary);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ReservedOrdersSheet), findsOneWidget);
    });
  });
}
