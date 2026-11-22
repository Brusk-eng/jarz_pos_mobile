import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/features/pos/data/models/customer_duplicate_models.dart';
import 'package:jarz_pos/src/features/pos/presentation/widgets/duplicate_customer_dialog.dart';

class _Holder {
  DuplicateCustomerDecision? decision;
  bool done = false;
}

final _check = CustomerDuplicateCheck.fromJson({
  'matches': [
    {
      'name': 'CUST-1',
      'customer_name': 'Ahmed Ali',
      'mobile_no': '01011112222',
      'customer_primary_address': 'Primary addr',
      'territory': 'Maadi',
      'match_reasons': ['phone', 'address'],
      'matched_address': '9 Road, Maadi',
      'order_count': 7,
      'last_order_date': '2026-11-20',
    },
    {
      'name': 'CUST-2',
      'customer_name': 'Ahmed A.',
      'mobile_no': '01155556666',
      'match_reasons': ['secondary_phone', 'name'],
      'order_count': 0,
    },
  ],
  'name_invalid': false,
});

Future<_Holder> _open(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  bool allowUseExisting = true,
  Size size = const Size(360, 720),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final holder = _Holder();
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            key: const ValueKey('open'),
            onPressed: () async {
              holder.decision = await showDuplicateCustomerDialog(
                context,
                matches: _check.matches,
                allowUseExisting: allowUseExisting,
              );
              holder.done = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open')));
  await tester.pumpAndSettle();
  return holder;
}

void main() {
  test('parses the contract and falls back on junk', () {
    expect(_check.matches, hasLength(2));
    final first = _check.matches.first;
    expect(first.displayAddress, '9 Road, Maadi');
    expect(first.orderCount, 7);
    expect(first.raw['territory'], 'Maadi');
    expect(_check.matches[1].displayAddress, isNull);
    expect(CustomerDuplicateCheck.fromJson(null).hasMatches, isFalse);
    expect(CustomerDuplicateCheck.fromJson('oops').hasMatches, isFalse);
    expect(
      CustomerDuplicateCheck.fromJson({'name_invalid': 1}).nameInvalid,
      isTrue,
    );
  });

  testWidgets('renders every match with details and reason chips', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('This customer may already exist'), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('01011112222'), findsOneWidget);
    expect(find.text('9 Road, Maadi'), findsOneWidget);
    expect(find.text('7 orders · last 2026-11-20'), findsOneWidget);
    expect(find.text('No orders yet'), findsOneWidget);
    expect(find.text('Same phone'), findsOneWidget);
    expect(find.text('Same address'), findsOneWidget);
    expect(find.text('Same second phone'), findsOneWidget);
    expect(find.text('Same name'), findsOneWidget);
    expect(find.text('Use this customer'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Use this customer returns that match', (tester) async {
    final holder = await _open(tester);
    final button = find.byKey(const ValueKey('dup-customer-use-CUST-2'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(holder.done, isTrue);
    expect(holder.decision!.action, DuplicateCustomerAction.useExisting);
    expect(holder.decision!.match!.name, 'CUST-2');
    expect(find.byKey(const ValueKey('dup-customer-dialog')), findsNothing);
  });

  testWidgets('Create new anyway returns createNew', (tester) async {
    final holder = await _open(tester);
    final button = find.byKey(const ValueKey('dup-customer-create-anyway'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(holder.decision!.action, DuplicateCustomerAction.createNew);
    expect(holder.decision!.match, isNull);
  });

  testWidgets('Cancel and dismissing both return cancel', (tester) async {
    var holder = await _open(tester);
    final cancel = find.byKey(const ValueKey('dup-customer-cancel'));
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(holder.decision!.action, DuplicateCustomerAction.cancel);

    holder = await _open(tester);
    await tester.tapAt(const Offset(5, 5)); // barrier
    await tester.pumpAndSettle();
    expect(holder.done, isTrue);
    expect(holder.decision!.action, DuplicateCustomerAction.cancel);
  });

  testWidgets('without allowUseExisting there is no per-match button', (
    tester,
  ) async {
    await _open(tester, allowUseExisting: false);
    expect(find.text('Use this customer'), findsNothing);
    expect(
      find.byKey(const ValueKey('dup-customer-create-anyway')),
      findsOneWidget,
    );
  });

  testWidgets('Arabic UI on a small phone: Arabic strings, no overflow', (
    tester,
  ) async {
    await _open(tester, locale: const Locale('ar'), size: const Size(320, 480));
    expect(find.text('العميل ده ممكن يكون موجود قبل كده'), findsOneWidget);
    expect(find.text('نفس رقم الموبايل'), findsOneWidget);
    expect(find.text('7 طلب · آخر طلب 2026-11-20'), findsOneWidget);
    expect(find.text('استخدم العميل ده'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
