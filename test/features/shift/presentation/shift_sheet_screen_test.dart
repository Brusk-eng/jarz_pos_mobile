import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/shift/models/shift_sheet_models.dart';
import 'package:jarz_pos/src/features/shift/presentation/shift_sheet_screen.dart';

Map<String, dynamic> _payload({required bool manager}) => {
  'opening_entry': 'POS-OPE-1',
  'pos_profile': 'Zamalek',
  'branch_label': 'Zamalek Branch',
  'user_full_name': 'Amr Ali',
  'opened_at': '2026-11-20 09:00:00',
  'is_open': 1,
  'is_manager_view': manager,
  'amounts_hidden': manager ? 0 : 1,
  'orders': [
    {
      'name': 'ACC-1',
      'order_number': '1001',
      'created_at': '2026-11-20 10:15:00',
      'jars': 3,
      'grand_total': 250,
      'outstanding_amount': 50,
      'delivery_fee': 30,
      'courier': 'Hassan Abdel Rahman Mohamed',
      'is_pickup': 0,
      'area': 'Maadi Sarayat Compound',
      'payment_method': 'Cash',
      'shipping_expense': 45,
      'courier_cash_in': 205,
      'courier_fee_paid': 45,
    },
    {
      'name': 'ACC-2',
      'order_number': '1002',
      'jars': 1,
      'grand_total': 80,
      'is_pickup': 1,
    },
  ],
  'jars_by_flavour': [
    {'flavour': 'Mango', 'small': 1, 'medium': 2, 'large': 0},
    {'flavour': 'Strawberry', 'small': 3, 'medium': 0, 'large': 0},
  ],
  'payouts': [
    {
      'kind': 'expense',
      'name': 'E1',
      'label': 'Ice',
      'amount': 40,
      'status': 'Approved',
    },
  ],
  'totals': manager
      ? {
          'orders': 2,
          'jars': 4,
          'grand_total': 330,
          'delivery_fees': 30,
          'payouts': 40,
          'opening_amount': 500,
          'expected_closing': 790,
          'actual_closing': 780,
          'difference': -10,
          'delivery_orders': 1,
          'delivery_income': 30,
          'delivery_cost': 45,
          'delivery_net': -15,
        }
      : null,
  'cash_flow': manager
      ? {
          'opening': 500,
          'sales_cash': 80,
          'courier_orders': 205,
          'courier_fees': -45,
          'expenses': -40,
          'refunds': 0,
          'handovers': 0,
          'other': 0,
          'expected': 700,
          'counted': 690,
          'difference': -10,
          'is_open': false,
          'lines': [
            {
              'kind': 'expenses',
              'voucher_no': 'E1',
              'label': 'Ice',
              'amount': -40,
              'at': '2026-11-20T11:00:00',
            },
          ],
        }
      : null,
};

Future<void> _pump(
  WidgetTester tester,
  Map<String, dynamic> payload, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shiftSheetProvider.overrideWith(
          (ref, entry) async => ShiftSheet.fromJson(payload),
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
        home: const ShiftSheetScreen(openingEntry: 'POS-OPE-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('staff sheet shows orders and flavours but no money cards', (
    tester,
  ) async {
    await _pump(tester, _payload(manager: false));
    expect(find.textContaining('#1001'), findsOneWidget);
    expect(find.textContaining('#1002'), findsOneWidget);
    expect(find.text('Pickup'), findsOneWidget);
    expect(find.textContaining('Unpaid'), findsOneWidget);
    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('Cash drawer'), findsNothing);
    expect(find.text('Sales total'), findsNothing);
    expect(find.text('Delivery profit'), findsNothing);
    expect(find.text('Delivery loss'), findsNothing);
    expect(find.textContaining('Courier cost'), findsNothing);
    expect(find.textContaining('Courier handed in'), findsNothing);
    // Flavours are collapsed until tapped.
    expect(find.text('Mango'), findsNothing);
    await tester.scrollUntilVisible(find.text('Jars by flavour'), 200);
    await tester.ensureVisible(find.text('Jars by flavour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jars by flavour'));
    await tester.pumpAndSettle();
    expect(find.text('Mango'), findsOneWidget);
    expect(find.text('Large'), findsNothing, reason: 'all-zero column hidden');
    expect(find.text('Small'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manager sheet shows cash drawer, sales and delivery', (
    tester,
  ) async {
    await _pump(tester, _payload(manager: true));
    expect(find.text('Cash drawer'), findsOneWidget);
    expect(find.text('Opening cash'), findsOneWidget);
    expect(find.text('Cash sales at the branch'), findsOneWidget);
    expect(find.text('Expected in drawer'), findsOneWidget);
    expect(find.text('Counted'), findsOneWidget);
    expect(find.textContaining('Short'), findsOneWidget);
    // zero rows are hidden
    expect(find.text('Refunds paid in cash'), findsNothing);
    expect(find.text('Handed over / deposited'), findsNothing);

    // The expenses row expands to its voucher lines.
    expect(find.text('Ice'), findsNothing);
    await tester.tap(find.text('Expenses & advances'));
    await tester.pumpAndSettle();
    expect(find.text('Ice'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Sales total'), 200);
    expect(find.text('Sales total'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Delivery loss'), 200);
    expect(find.text('Delivery loss'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Courier handed in'),
      200,
    );
    expect(find.textContaining('Courier cost '), findsOneWidget);
    expect(find.textContaining('Courier handed in'), findsOneWidget);
    expect(find.textContaining('Settled:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('open shift shows expected so far and hides the count', (
    tester,
  ) async {
    final payload = _payload(manager: true);
    payload['cash_flow'] = {
      ...(payload['cash_flow'] as Map<String, dynamic>),
      'is_open': true,
      'counted': null,
      'difference': null,
    };
    await _pump(tester, payload);
    expect(find.text('Expected so far'), findsOneWidget);
    expect(find.text('Counted'), findsNothing);
    expect(find.byKey(const ValueKey('shiftSheetDiffPill')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manager sheet from an old server has no cash or delivery card', (
    tester,
  ) async {
    final payload = _payload(manager: true)..remove('cash_flow');
    (payload['totals'] as Map<String, dynamic>).remove('delivery_orders');
    await _pump(tester, payload);
    expect(find.text('Cash drawer'), findsNothing);
    expect(find.text('Sales total'), findsOneWidget);
    expect(find.text('Delivery loss'), findsNothing);
    expect(find.text('Delivery profit'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  Map<String, dynamic> withPaidAndOverdue(Map<String, dynamic> payload) {
    final orders = List<Map<String, dynamic>>.from(payload['orders'] as List);
    orders.add({
      'name': 'ACC-3',
      'order_number': '1003',
      'grand_total': 120,
      'is_pickup': 1,
      'reasons': ['created', 'paid'],
      'paid_at': '2026-11-20T12:30:00',
      'paid_amount': 120,
    });
    return {
      ...payload,
      'orders': orders,
      'overdue': [
        {
          'name': 'ACC-7',
          'order_number': '1007',
          'customer_name': 'Mona Hassan',
          'slot_label': '10 AM - 12 PM',
          'deadline': '2026-11-20T12:00:00',
          'minutes_late': 95,
          'state': 'In Progress',
          'due_in_this_shift': true,
        },
        {
          'name': 'ACC-6',
          'order_number': '1006',
          'slot_start': '2026-11-19T18:00:00',
          'deadline': '2026-11-19T20:00:00',
          'minutes_late': 1530,
          'state': 'Recieved',
          'is_pickup': true,
          'due_in_this_shift': false,
          'went_out_at': '2026-11-20T21:00:00',
        },
      ],
    };
  }

  testWidgets('paid-in-drawer filter and the late orders section', (
    tester,
  ) async {
    await _pump(tester, withPaidAndOverdue(_payload(manager: true)));
    await tester.scrollUntilVisible(find.text('Paid in drawer (1)'), 200);
    expect(find.text('New (3)'), findsNothing, reason: 'New filter dropped');
    await tester.ensureVisible(find.text('Paid in drawer (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paid in drawer (1)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('#1003'), findsOneWidget);
    expect(find.textContaining('#1001'), findsNothing);
    expect(find.text('New'), findsOneWidget, reason: 'row reason chip kept');
    expect(find.textContaining('Paid in drawer at 12:30 PM ·'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Late — not sent out'), 200);
    await tester.scrollUntilVisible(find.textContaining('#1006'), 200);
    expect(find.text('#1007 · Mona Hassan'), findsOneWidget);
    expect(find.text('Late by 1h 35m'), findsOneWidget);
    expect(find.text('Due this shift'), findsOneWidget);
    expect(find.text('Not sent out yet'), findsOneWidget);
    expect(find.text('10 AM - 12 PM'), findsOneWidget);
    expect(find.text('Late by 1d 1h'), findsOneWidget);
    expect(find.text('From an earlier shift'), findsOneWidget);
    expect(find.textContaining('Went out later at'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('staff sees the paid time but not the drawer amount', (
    tester,
  ) async {
    await _pump(tester, withPaidAndOverdue(_payload(manager: false)));
    await tester.scrollUntilVisible(find.textContaining('#1003'), 200);
    expect(find.text('Paid in drawer at 12:30 PM'), findsOneWidget);
    expect(find.textContaining('Paid in drawer at 12:30 PM ·'), findsNothing);
    await tester.scrollUntilVisible(find.text('Late — not sent out'), 200);
    expect(find.text('Late — not sent out'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no late orders shows the empty state', (tester) async {
    await _pump(tester, _payload(manager: false));
    await tester.scrollUntilVisible(find.text('No late orders'), 200);
    expect(find.text('No late orders'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in Arabic (RTL) at 360 wide without overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      withPaidAndOverdue(_payload(manager: true)),
      locale: const Locale('ar'),
    );
    expect(find.text('ورقة الوردية'), findsOneWidget);
    expect(find.text('درج الكاش'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('متأخرة — لم تخرج'), 200);
    await tester.scrollUntilVisible(find.textContaining('#1006'), 200);
    expect(find.text('لسه ماخرجش'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
