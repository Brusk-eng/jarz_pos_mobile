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
  testWidgets('staff sheet shows orders and flavours but no totals', (
    tester,
  ) async {
    await _pump(tester, _payload(manager: false));
    expect(find.textContaining('#1001'), findsOneWidget);
    expect(find.textContaining('#1002'), findsOneWidget);
    expect(find.text('Pickup'), findsOneWidget);
    expect(find.textContaining('Unpaid'), findsOneWidget);
    expect(find.text('Mango'), findsOneWidget);
    expect(find.text('Large'), findsNothing, reason: 'all-zero column hidden');
    expect(find.text('Small'), findsOneWidget);
    expect(find.text('Shift totals'), findsNothing);
    expect(find.text('Expected closing'), findsNothing);
    expect(find.text('Counted closing'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manager sheet shows the totals card', (tester) async {
    await _pump(tester, _payload(manager: true));
    expect(find.text('Shift totals'), findsOneWidget);
    expect(find.text('Expected closing'), findsOneWidget);
    expect(find.text('Counted closing'), findsOneWidget);
    expect(find.text('Sales total'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in Arabic (RTL) at 360 wide without overflow', (
    tester,
  ) async {
    await _pump(tester, _payload(manager: true), locale: const Locale('ar'));
    expect(find.text('ورقة الوردية'), findsOneWidget);
    expect(find.text('إجماليات الوردية'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
