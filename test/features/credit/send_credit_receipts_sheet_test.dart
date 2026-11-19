import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/credit/data/models/credit_models.dart';
import 'package:jarz_pos/src/features/credit/presentation/widgets/send_credit_receipts_sheet.dart';
import 'package:jarz_pos/src/features/printing/pos_printer_provider.dart';
import 'package:jarz_pos/src/features/printing/pos_printer_service.dart';

const _invoices = [
  CreditInvoice(invoice: 'ACC-SINV-2026-00010', postingDate: '2026-09-01', grandTotal: 500, outstandingAmount: 500),
  CreditInvoice(invoice: 'ACC-SINV-2026-00020', postingDate: '2026-09-10', grandTotal: 300, outstandingAmount: 200),
  CreditInvoice(invoice: 'ACC-SINV-2026-00030', postingDate: '2026-09-20', grandTotal: 150, outstandingAmount: 150),
];

PrintableInvoice _printable(CreditInvoice i) => PrintableInvoice(
      id: i.invoice,
      date: DateTime(2026, 9, 1),
      customer: 'Cafe Nour',
      customerPhone: '01111034268',
      total: i.grandTotal,
      paid: i.grandTotal - i.outstandingAmount,
      outstanding: i.outstandingAmount,
      items: [PrintableInvoiceItem(name: 'Mango Jar', qty: 1, rate: i.grandTotal)],
    );

Widget _wrap(Widget child) => ProviderScope(
      overrides: [
        // No Dio: receipt branding falls back to the defaults, no network.
        posPrinterServiceProvider.overrideWith((ref) => PosPrinterService(autoInit: false)),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('starts with every open order ticked, consolidated, and totals what is due', (tester) async {
    await tester.pumpWidget(_wrap(const SendCreditReceiptsSheet(customerName: 'Cafe Nour', invoices: _invoices)));

    expect(find.text('3 of 3 selected'), findsOneWidget);
    expect(find.textContaining('Total due:'), findsOneWidget);
    expect(find.textContaining('850.00'), findsOneWidget);
    expect(find.text('All the orders you choose in one statement, with the total due.'), findsOneWidget);
  });

  testWidgets('the send buttons stay above the phone navigation bar', (tester) async {
    // Android draws apps edge to edge: the bottom 48 px belong to the
    // navigation bar, and the sheet must not put WhatsApp / Share under it.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 126);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 126);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => SendCreditReceiptsSheet.show(context, customerName: 'Cafe Nour', invoices: _invoices),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final navBarTop = screenHeight - 126 / tester.view.devicePixelRatio;
    for (final label in ['WhatsApp', 'Share']) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(button, findsOneWidget, reason: label);
      expect(tester.getRect(button).bottom, lessThanOrEqualTo(navBarTop), reason: '$label is under the navigation bar');
    }
  });

  testWidgets('a single open order defaults to its own receipt', (tester) async {
    await tester.pumpWidget(
      _wrap(SendCreditReceiptsSheet(customerName: 'Cafe Nour', invoices: [_invoices.first])),
    );
    expect(find.text('One receipt for each order you choose.'), findsOneWidget);
  });

  testWidgets('unticking an order drops it from the total and from what is sent', (tester) async {
    List<String>? loaded;
    // Opened as a bottom sheet over a page, as the credit screen does: the
    // send pops the sheet, and the outcome is reported on the page below.
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => SendCreditReceiptsSheet(
                customerName: 'Cafe Nour',
                invoices: _invoices,
                loadInvoices: (invoices) async {
                  loaded = invoices.map((i) => i.invoice).toList();
                  return invoices.map(_printable).toList();
                },
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('credit-send-ACC-SINV-2026-00020')));
    await tester.pump();
    expect(find.text('2 of 3 selected'), findsOneWidget);
    expect(find.textContaining('650.00'), findsOneWidget);

    await tester.tap(find.text('Individual receipts'));
    await tester.pump();
    expect(find.text('One receipt for each order you choose.'), findsOneWidget);

    await tester.tap(find.text('WhatsApp'));
    // The receipts are rendered as images on the engine; that work finishes
    // on real time, never under the fake clock pumpAndSettle advances.
    for (var i = 0; i < 20 && find.byType(SnackBar).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    // Oldest first, the unticked order left out.
    expect(loaded, ['ACC-SINV-2026-00010', 'ACC-SINV-2026-00030']);
    // The sheet is gone. No WhatsApp channel and no share sheet in a test, so
    // the rendered images wait behind a Send tap.
    expect(find.byType(SendCreditReceiptsSheet), findsNothing);
    expect(find.text('Receipt image ready — tap Send to share it'), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'Send'), findsOneWidget);
  });

  testWidgets('nothing ticked means nothing can be sent', (tester) async {
    await tester.pumpWidget(_wrap(const SendCreditReceiptsSheet(customerName: 'Cafe Nour', invoices: _invoices)));
    await tester.tap(find.text('Select all'));
    await tester.pump();
    expect(find.text('0 of 3 selected'), findsOneWidget);
    final whatsapp = tester.widget<FilledButton>(find.ancestor(of: find.text('WhatsApp'), matching: find.byWidgetPredicate((w) => w is FilledButton)));
    expect(whatsapp.onPressed, isNull);
  });

  testWidgets('a failed load says so and keeps the sheet open', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SendCreditReceiptsSheet(
          customerName: 'Cafe Nour',
          invoices: _invoices,
          loadInvoices: (_) async => throw Exception('503'),
        ),
      ),
    );
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load the orders. Try again.'), findsOneWidget);
    expect(find.text('3 of 3 selected'), findsOneWidget);
  });

  testWidgets('a load that comes back short is refused, not sent misaligned', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SendCreditReceiptsSheet(
          customerName: 'Cafe Nour',
          invoices: _invoices,
          loadInvoices: (invoices) async => [_printable(invoices.first)],
        ),
      ),
    );
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load the orders. Try again.'), findsOneWidget);
    final whatsapp = tester.widget<FilledButton>(find.ancestor(of: find.text('WhatsApp'), matching: find.byWidgetPredicate((w) => w is FilledButton)));
    expect(whatsapp.onPressed, isNotNull);
  });

  testWidgets('a statement asks for the shop branch of each order; a failed lookup still sends it', (tester) async {
    String? askedFor;
    await tester.pumpWidget(
      _wrap(
        SendCreditReceiptsSheet(
          customer: 'CUST-NOUR',
          customerName: 'Cafe Nour',
          invoices: _invoices,
          loadInvoices: (invoices) async => invoices.map(_printable).toList(),
          loadBranches: (customer, invoices) async {
            askedFor = customer;
            throw Exception('old server');
          },
        ),
      ),
    );
    await tester.tap(find.text('WhatsApp'));
    for (var i = 0; i < 20 && find.byType(SendCreditReceiptsSheet).evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(askedFor, 'CUST-NOUR');
    expect(find.text('Could not load the orders. Try again.'), findsNothing);
  });
}
