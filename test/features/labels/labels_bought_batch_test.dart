// ignore_for_file: overridden_fields

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/core/constants/api_endpoints.dart';
import 'package:jarz_pos/src/core/network/user_service.dart';
import 'package:jarz_pos/src/features/labels/data/labels_repository.dart';
import 'package:jarz_pos/src/features/labels/models/label_models.dart';
import 'package:jarz_pos/src/features/labels/presentation/screens/label_detail_screen.dart';
import 'package:jarz_pos/src/features/labels/presentation/widgets/label_sheets.dart';

import '../../helpers/mock_services.dart';

/// Captures POST bodies; answers each path from [responses], and can fail the
/// next N calls to [failPath] the way a timeout does.
class _FakeDio with DioMixin implements Dio {
  final List<({String path, dynamic data})> calls = [];
  final Map<String, dynamic> responses = {};
  String? failPath;
  int failuresLeft = 0;

  @override
  BaseOptions options = BaseOptions();

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    calls.add((path: path, data: data));
    if (path == failPath && failuresLeft > 0) {
      failuresLeft--;
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.receiveTimeout,
        message: 'Receive timeout',
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: createSuccessResponse(data: responses[path] ?? const {}) as T,
    );
  }

  List<Map> bodiesFor(String path) => calls
      .where((c) => c.path == path)
      .map((c) => c.data as Map)
      .toList();
}

Map<String, dynamic> _labelJson({
  int defaultSheets = 2,
  int labelsPerSheet = 21,
  List<Map<String, dynamic>> printOrders = const [],
}) {
  return {
    'name': 'JLBL-00001',
    'customer': 'CUST-A',
    'customer_name': 'Cafe X',
    'label_title': 'Mango',
    'item': 'Mango Jar',
    'size': 'Medium',
    'storage_location': 'Dokki - J',
    'enabled': 1,
    'we_print': 1,
    'tracked': 1,
    'labels_per_unit': 1,
    'labels_per_sheet': labelsPerSheet,
    'default_print_sheets': defaultSheets,
    'on_hand_qty': 10,
    'min_stock_qty': 0,
    'suggested_print_sheets': 3,
    'suggested_print_qty': 3 * labelsPerSheet,
    'avg_daily_usage': 5.0,
    'days_of_cover': 2.0,
    'status': 'Reorder Now',
    'needs_attention': true,
    'lead_days': 4,
    'open_print_orders': const [],
    'print_orders': printOrders,
    'movements': const [],
  };
}

Map<String, dynamic> _boughtResponse() => {
      'print_order': 'JLPO-9',
      'purchase_invoice': 'ACC-PINV-2026-00042',
      // The refreshed detail lists the new batch, billed, with its printer.
      'label': _labelJson(printOrders: [
        {
          'name': 'JLPO-9',
          'qty': 42,
          'qty_sheets': 2,
          'status': 'Received',
          'received_qty': 42,
          'supplier': 'Print House Co',
          'purchase_invoice': 'ACC-PINV-2026-00042',
          'billing_status': 'Billed',
        },
      ]),
    };

void main() {
  // ── Repository wire format ──────────────────────────────────────────────
  group('recordBoughtBatch wire format', () {
    test('owed: exact params, is_paid 0 and no payment_option', () async {
      final dio = _FakeDio()
        ..responses[ApiEndpoints.recordLabelBoughtBatch] = _boughtResponse();

      final result = await LabelsRepository(dio).recordBoughtBatch(
        label: 'JLBL-00001',
        qtySheets: 2,
        receivedQty: 40,
        supplier: ' Print House Co ',
        totalCost: 210,
        billNo: 'PH-7',
        billDate: '2026-10-30',
        receivedOn: '2026-10-30',
        notes: 'short by 2',
        clientRequestId: 'lbl-bought-1',
      );

      expect(dio.calls.single.path, ApiEndpoints.recordLabelBoughtBatch);
      expect(dio.calls.single.data, {
        'label': 'JLBL-00001',
        'qty_sheets': 2,
        'received_qty': 40,
        'supplier': 'Print House Co',
        'total_cost': 210.0,
        'bill_no': 'PH-7',
        'bill_date': '2026-10-30',
        'received_on': '2026-10-30',
        'is_paid': 0,
        'notes': 'short by 2',
        'client_request_id': 'lbl-bought-1',
      });
      expect(result.printOrder, 'JLPO-9');
      expect(result.purchaseInvoice, 'ACC-PINV-2026-00042');
      expect(result.label.name, 'JLBL-00001');
    });

    test('paid: is_paid 1 with the payment option', () async {
      final dio = _FakeDio()
        ..responses[ApiEndpoints.recordLabelBoughtBatch] = _boughtResponse();

      await LabelsRepository(dio).recordBoughtBatch(
        label: 'JLBL-00001',
        qtySheets: 1,
        supplier: 'Print House Co',
        totalCost: 105,
        isPaid: true,
        paymentOption: 'custody:Ahmed',
        clientRequestId: 'lbl-bought-2',
      );

      final body = dio.calls.single.data as Map;
      expect(body['is_paid'], 1);
      expect(body['payment_option'], 'custody:Ahmed');
    });

    test('blank optional fields are omitted, so the server defaults them',
        () async {
      final dio = _FakeDio()
        ..responses[ApiEndpoints.recordLabelBoughtBatch] = _boughtResponse();

      await LabelsRepository(dio).recordBoughtBatch(
        label: 'JLBL-00001',
        qtySheets: 3,
        supplier: 'Print House Co',
        totalCost: 300,
        billNo: '  ',
        notes: '',
        clientRequestId: 'lbl-bought-3',
      );

      final body = dio.calls.single.data as Map;
      for (final key in [
        'received_qty',
        'bill_no',
        'bill_date',
        'received_on',
        'notes',
        'payment_option',
      ]) {
        expect(body.containsKey(key), isFalse, reason: key);
      }
      expect(body['is_paid'], 0);
    });

    test('paid without a source is refused before anything is sent', () async {
      final dio = _FakeDio();
      expect(
        () => LabelsRepository(dio).recordBoughtBatch(
          label: 'JLBL-00001',
          qtySheets: 1,
          supplier: 'Print House Co',
          totalCost: 105,
          isPaid: true,
          clientRequestId: 'lbl-bought-4',
        ),
        throwsArgumentError,
      );
      expect(dio.calls, isEmpty);
    });
  });

  group('billPrintOrder payment', () {
    test('without isPaid the old wire format is unchanged', () async {
      final dio = _FakeDio()
        ..responses[ApiEndpoints.billLabelPrintOrder] = _boughtResponse();
      await LabelsRepository(dio).billPrintOrder(
        printOrder: 'JLPO-1',
        supplier: 'Print House Co',
        totalCost: 210,
      );
      final body = dio.calls.single.data as Map;
      expect(body.containsKey('is_paid'), isFalse);
      expect(body.containsKey('payment_option'), isFalse);
    });

    test('owed sends is_paid 0 and no option', () async {
      final dio = _FakeDio()
        ..responses[ApiEndpoints.billLabelPrintOrder] = _boughtResponse();
      await LabelsRepository(dio).billPrintOrder(
        printOrder: 'JLPO-1',
        supplier: 'Print House Co',
        totalCost: 210,
        isPaid: false,
        paymentOption: 'cash',
      );
      final body = dio.calls.single.data as Map;
      expect(body['is_paid'], 0);
      expect(body.containsKey('payment_option'), isFalse);
    });

    test('paid sends is_paid 1 and the option', () async {
      final dio = _FakeDio()
        ..responses[ApiEndpoints.billLabelPrintOrder] = _boughtResponse();
      await LabelsRepository(dio).billPrintOrder(
        printOrder: 'JLPO-1',
        supplier: 'Print House Co',
        totalCost: 210,
        isPaid: true,
        paymentOption: 'Dokki',
      );
      final body = dio.calls.single.data as Map;
      expect(body['is_paid'], 1);
      expect(body['payment_option'], 'Dokki');
    });
  });

  // ── BoughtBatchSheet ────────────────────────────────────────────────────
  group('BoughtBatchSheet', () {
    /// Opens the sheet; the returned getter reads what it popped.
    Future<BoughtBatchRequest? Function()> pumpSheet(
      WidgetTester tester, {
      String? initialSupplier,
      String? clientRequestId,
    }) async {
      BoughtBatchRequest? result;
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showModalBottomSheet<BoughtBatchRequest>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => BoughtBatchSheet(
                        label: CustomerLabel.fromJson(_labelJson()),
                        initialSupplier: initialSupplier,
                        clientRequestId: clientRequestId,
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return () => result;
    }

    String fieldText(WidgetTester tester, String key) => tester
        .widget<TextField>(find.byKey(ValueKey(key)))
        .controller!
        .text;

    FilledButton saveButton(WidgetTester tester) =>
        tester.widget<FilledButton>(find.byKey(const ValueKey('bought-save')));

    Future<void> save(WidgetTester tester) async {
      final button = find.byKey(const ValueKey('bought-save'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('labels received follows the sheets until the user edits it',
        (tester) async {
      await pumpSheet(tester);

      // The label's default batch: 2 sheets x 21.
      expect(fieldText(tester, 'bought-sheets'), '2');
      expect(fieldText(tester, 'bought-received'), '42');

      await tester.tap(find.byKey(const ValueKey('bought-sheets-plus')));
      await tester.pump();
      expect(fieldText(tester, 'bought-sheets'), '3');
      expect(fieldText(tester, 'bought-received'), '63');

      await tester.enterText(find.byKey(const ValueKey('bought-sheets')), '5');
      await tester.pump();
      expect(fieldText(tester, 'bought-received'), '105');

      // Delivered short: the typed count is theirs from now on.
      await tester.enterText(
          find.byKey(const ValueKey('bought-received')), '100');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('bought-sheets-plus')));
      await tester.pump();
      expect(fieldText(tester, 'bought-sheets'), '6');
      expect(fieldText(tester, 'bought-received'), '100');
    });

    testWidgets('no supplier keeps save disabled, even with a cost',
        (tester) async {
      await pumpSheet(tester);

      expect(saveButton(tester).onPressed, isNull);
      await tester.enterText(find.byKey(const ValueKey('bought-cost')), '210');
      await tester.pump();
      expect(saveButton(tester).onPressed, isNull);
    });

    testWidgets('cost 0 disables save even with a supplier', (tester) async {
      await pumpSheet(tester, initialSupplier: 'Print House Co');

      expect(saveButton(tester).onPressed, isNull);
      await tester.enterText(find.byKey(const ValueKey('bought-cost')), '0');
      await tester.pump();
      expect(saveButton(tester).onPressed, isNull);

      await tester.enterText(find.byKey(const ValueKey('bought-cost')), '210');
      await tester.pump();
      expect(saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('the popped request carries every field', (tester) async {
      final result = await pumpSheet(
        tester,
        initialSupplier: 'Print House Co',
        clientRequestId: 'lbl-bought-retry',
      );

      await tester.enterText(
          find.byKey(const ValueKey('bought-cost')), '210.5');
      await tester.pump();
      await save(tester);

      final request = result();
      expect(request, isNotNull);
      expect(request!.qtySheets, 2);
      expect(request.receivedQty, 42);
      expect(request.supplier, 'Print House Co');
      expect(request.totalCost, 210.5);
      expect(request.billNo, isNull);
      expect(request.boughtOn, DateUtils.dateOnly(DateTime.now()));
      expect(request.isPaid, isFalse);
      expect(request.paymentOption, isNull);
      // A key handed in (a failed attempt's) is reused, not replaced.
      expect(request.clientRequestId, 'lbl-bought-retry');
    });

    testWidgets('without a key handed in, the sheet makes one', (tester) async {
      final result =
          await pumpSheet(tester, initialSupplier: 'Print House Co');
      await tester.enterText(find.byKey(const ValueKey('bought-cost')), '99');
      await tester.pump();
      await save(tester);
      expect(result()!.clientRequestId, startsWith('lbl-bought-'));
    });
  });

  group('RecordBillSheet payment', () {
    testWidgets('defaults to owed to the printer', (tester) async {
      BillRequest? result;
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      final order = LabelPrintOrder.fromJson({
        'name': 'JLPO-1',
        'qty': 42,
        'qty_sheets': 2,
        'status': 'Received',
        'received_qty': 42,
        'supplier': 'Print House Co',
        'total_cost': 210,
      });
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showModalBottomSheet<BillRequest>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => RecordBillSheet(order: order),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Owed to supplier (pay later)'), findsOneWidget);
      expect(find.text('Paid now'), findsOneWidget);
      await tester.tap(find.text('Record bill'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.isPaid, isFalse);
      expect(result!.paymentOption, isNull);
    });
  });

  // ── Detail screen: gate + retry replays the same request id ──────────────
  group('LabelDetailScreen bought & received', () {
    Future<_FakeDio> pumpScreen(WidgetTester tester, {required bool canBill}) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      final dio = _FakeDio()
        ..responses[ApiEndpoints.getLabelDetail] = _labelJson(printOrders: [
          {
            'name': 'JLPO-1',
            'qty': 42,
            'qty_sheets': 2,
            'status': 'Received',
            'supplier': 'Print House Co',
            'billing_status': 'Billed',
          },
        ])
        ..responses[ApiEndpoints.recordLabelBoughtBatch] = _boughtResponse();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          labelsRepositoryProvider.overrideWithValue(LabelsRepository(dio)),
          canAccessPurchaseInvoiceProvider.overrideWithValue(canBill),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const LabelDetailScreen(labelName: 'JLBL-00001'),
        ),
      ));
      await tester.pumpAndSettle();
      return dio;
    }

    testWidgets('hidden from users who cannot bill', (tester) async {
      await pumpScreen(tester, canBill: false);
      expect(find.text('Order'), findsOneWidget);
      expect(find.byKey(const ValueKey('label-action-bought')), findsNothing);
    });

    testWidgets('a retry after a timeout replays the same client_request_id',
        (tester) async {
      final dio = await pumpScreen(tester, canBill: true);
      dio
        ..failPath = ApiEndpoints.recordLabelBoughtBatch
        ..failuresLeft = 1;

      Future<void> fillAndSave() async {
        await tester.tap(find.byKey(const ValueKey('label-action-bought')));
        await tester.pumpAndSettle();
        // The last batch's printer is pre-selected.
        expect(find.text('Print House Co'), findsWidgets);
        await tester.enterText(
            find.byKey(const ValueKey('bought-cost')), '210');
        await tester.pump();
        final save = find.byKey(const ValueKey('bought-save'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
      }

      // Lets the current snackbar time out so the next one can show.
      Future<void> drainSnackBar() async {
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
      }

      await fillAndSave(); // times out
      await drainSnackBar();
      await fillAndSave(); // the retry
      expect(find.text('Recorded 42 labels, bill ACC-PINV-2026-00042'),
          findsOneWidget);
      await drainSnackBar();
      // A fresh purchase after the success gets a new key.
      await fillAndSave();

      final bodies = dio.bodiesFor(ApiEndpoints.recordLabelBoughtBatch);
      expect(bodies, hasLength(3));
      expect(bodies[1]['client_request_id'], bodies[0]['client_request_id']);
      expect(bodies[2]['client_request_id'],
          isNot(bodies[1]['client_request_id']));
      final today = DateUtils.dateOnly(DateTime.now());
      final ymd =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      expect(bodies[1]['received_on'], ymd);
      expect(bodies[1]['bill_date'], ymd);
      expect(bodies[1]['supplier'], 'Print House Co');
      expect(bodies[1]['is_paid'], 0);
    });
  });
}
