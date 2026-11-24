import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/kanban/widgets/return_order_dialog.dart';

import '../../../helpers/test_helpers.dart';

Map<String, dynamic> _preview({
  bool canRefundNow = true,
  bool canChooseCourierFee = true,
  bool canWriteOffGoods = false,
  List<Map<String, dynamic>>? lines,
}) {
  return {
    // Only a server that can book the loss sends this block.
    if (canWriteOffGoods)
      'goods': {
        'can_write_off': true,
        'write_off_account': 'Stock Adjustment - J',
      },
    'invoice_id': 'ACC-SINV-2026-00001',
    'customer_name': 'Test Customer',
    'currency': 'EGP',
    'can_return': true,
    'money_state': 'prepaid',
    'lines': lines ??
        [
          {
            'si_detail': 'row-1',
            'item_code': 'ITEM-A',
            'item_name': 'Item A',
            'rate': 100.0,
            'qty_sold': 2.0,
            'qty_already_returned': 0.0,
            'qty_returnable': 2.0,
          },
          {
            'si_detail': 'row-2',
            'item_code': 'ITEM-B',
            'item_name': 'Item B',
            'rate': 50.0,
            'qty_sold': 1.0,
            'qty_already_returned': 0.0,
            'qty_returnable': 1.0,
          },
        ],
    'courier': {'party_type': 'Supplier', 'party': 'SUP-1', 'shipping_amount': 30.0},
    'toggles': {
      'can_choose_courier_fee': canChooseCourierFee,
      'can_refund_now': canRefundNow,
      'refund_blocked_reason': canRefundNow ? null : 'Start a shift to refund cash.',
    },
    'side_effects': const {},
  };
}

/// Pump a host, open the dialog, and settle.
///
/// Returns the dialog's own future *without* awaiting it, so the caller can
/// drive the UI and only then await the result. Awaiting it inside the helper
/// would deadlock the test, and letting the helper's own async work interleave
/// with the caller's taps trips the test-async guard.
Future<Future<OrderReturnRequest?>> _openDialog(
  WidgetTester tester, {
  Map<String, dynamic>? preview,
}) async {
  late BuildContext hostContext;

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
          hostContext = context;
          return const Scaffold(body: SizedBox.shrink());
        },
      ),
    ),
  );

  final future = ReturnOrderDialog.show(
    hostContext,
    preview: preview ?? _preview(),
  );

  await tester.pumpAndSettle();
  return future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  group('ReturnOrderDialog', () {
    testWidgets('defaults to returning every available line', (tester) async {
      final pending = await _openDialog(tester);

      // 2 of Item A and 1 of Item B => 2*100 + 1*50 = 250.
      expect(find.text('250 EGP'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        'Customer changed their mind',
      );
      await tester.tap(find.text('Confirm return'));
      await tester.pumpAndSettle();

      final result = await pending;
      expect(result, isNotNull);
      expect(result!.lines.length, 2);
      expect(result.reason, 'Customer changed their mind');
    });

    testWidgets('reason is required before the return can be confirmed',
        (tester) async {
      final pending = await _openDialog(tester);

      await tester.tap(find.text('Confirm return'));
      await tester.pumpAndSettle();

      // Still open — validation blocked the submit.
      expect(find.text('Confirm return'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Damaged on arrival');
      await tester.tap(find.text('Confirm return'));
      await tester.pumpAndSettle();

      expect((await pending)!.reason, 'Damaged on arrival');
    });

    testWidgets('decrementing a line produces a partial return', (tester) async {
      final pending = await _openDialog(tester);

      // Drop Item A from 2 to 1 => 1*100 + 1*50 = 150.
      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pumpAndSettle();
      expect(find.text('150 EGP'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Kept one');
      await tester.tap(find.text('Confirm return'));
      await tester.pumpAndSettle();

      final result = await pending;
      final rowA = result!.lines.firstWhere((l) => l['si_detail'] == 'row-1');
      expect(rowA['qty'], 1.0);
    });

    testWidgets('refund-now is unavailable when the server says so',
        (tester) async {
      final pending = await _openDialog(tester, preview: _preview(canRefundNow: false));

      expect(find.text('Start a shift to refund cash.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'No shift open');
      await tester.tap(find.text('Confirm return'));
      await tester.pumpAndSettle();

      // Must fall back to credit rather than sending a mode the server rejects.
      expect((await pending)!.refundMode, 'customer_credit');
    });

    testWidgets('courier fee toggle is hidden when there is no courier',
        (tester) async {
      final pending = await _openDialog(
        tester,
        preview: _preview(canChooseCourierFee: false),
      );

      expect(find.text('Pay the courier for this trip'), findsNothing);

      await tester.enterText(find.byType(TextFormField).first, 'Pickup order');
      await tester.tap(find.text('Confirm return'));
      await tester.pumpAndSettle();

      expect((await pending)!.payCourierForTrip, isTrue);
    });

    testWidgets('declining the courier fee is carried into the request',
        (tester) async {
      final pending = await _openDialog(tester);

      // The toggle sits below the fold in the test viewport.
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Courier no-show');
      await tester.tap(find.text('Confirm return'));
      await tester.pumpAndSettle();

      expect((await pending)!.payCourierForTrip, isFalse);
    });

    testWidgets('the goods question is not asked on a server that cannot act on it',
        (tester) async {
      final pending = await _openDialog(tester);

      expect(find.text('The goods are damaged'), findsNothing);

      await tester.enterText(find.byType(TextFormField).first, 'Old server');
      await tester.tap(find.text('Confirm return'));
      await tester.pumpAndSettle();

      // Nothing sent, so the server keeps its own rule.
      expect((await pending)!.goodsCondition, isNull);
    });

    testWidgets('returned goods go back to stock unless the operator says otherwise',
        (tester) async {
      final pending = await _openDialog(
        tester,
        preview: _preview(canWriteOffGoods: true),
      );

      expect(find.text('The goods are damaged'), findsOneWidget);
      expect(
        find.text('They go back into branch stock, ready to sell.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextFormField).first, 'Changed mind');
      await tester.tap(find.text('Confirm return'));
      await tester.pumpAndSettle();

      expect((await pending)!.goodsCondition, 'restock');
    });

    testWidgets('marking the goods damaged sends them to waste', (tester) async {
      final pending = await _openDialog(
        tester,
        preview: _preview(canWriteOffGoods: true),
      );

      final goodsSwitch = find.byKey(const Key('return-goods-damaged-switch'));
      await tester.ensureVisible(goodsSwitch);
      await tester.pumpAndSettle();
      await tester.tap(goodsSwitch);
      await tester.pumpAndSettle();

      expect(
        find.text('Written off as waste. They will not go back into stock.'),
        findsOneWidget,
      );

      // A failed delivery that melted on the way back: the type stays what it
      // is, the goods are still waste.
      await tester.enterText(find.byType(TextFormField).first, 'Melted');
      await tester.tap(find.text('Confirm return'));
      await tester.pumpAndSettle();

      final result = await pending;
      expect(result!.goodsCondition, 'waste');
      expect(result.returnType, 'Customer Return');
    });

    testWidgets('choosing the Damaged type switches the goods to damaged',
        (tester) async {
      final pending = await _openDialog(
        tester,
        preview: _preview(canWriteOffGoods: true),
      );

      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Damaged').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Broken jar');
      await tester.tap(find.text('Confirm return'));
      await tester.pumpAndSettle();

      final result = await pending;
      expect(result!.returnType, 'Damaged');
      expect(result.goodsCondition, 'waste');
    });

    testWidgets('a fully returned line cannot be selected again',
        (tester) async {
      await _openDialog(
        tester,
        preview: _preview(lines: [
          {
            'si_detail': 'row-1',
            'item_code': 'ITEM-A',
            'item_name': 'Item A',
            'rate': 100.0,
            'qty_sold': 2.0,
            'qty_already_returned': 2.0,
            'qty_returnable': 0.0,
          },
        ]),
      );

      expect(find.text('Already returned'), findsOneWidget);
      // Nothing selectable => nothing to credit.
      expect(find.text('0 EGP'), findsOneWidget);
    });

    testWidgets('cancelling returns null', (tester) async {
      final pending = await _openDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await pending, isNull);
    });
  });
}
