// ignore_for_file: overridden_fields

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/core/constants/api_endpoints.dart';
import 'package:jarz_pos/src/features/manager/data/manager_api.dart';

import '../../../helpers/mock_services.dart';

/// Minimal Dio stand-in that captures requests and returns canned responses.
class _FakeDio with DioMixin implements Dio {
  final List<({String method, String path, dynamic data, Map<String, dynamic>? query})> calls = [];
  Response? nextResponse;
  DioException? nextError;

  @override
  BaseOptions options = BaseOptions();

  Future<Response<T>> _handle<T>(String method, String path, {dynamic data, Map<String, dynamic>? query}) async {
    calls.add((method: method, path: path, data: data, query: query));
    if (nextError != null) {
      final err = nextError!;
      nextError = null;
      throw err;
    }
    final resp = nextResponse ?? Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: createSuccessResponse(data: {}),
    );
    nextResponse = null;
    return resp as Response<T>;
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) => _handle<T>('GET', path, query: queryParameters);

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) => _handle<T>('POST', path, data: data);
}

void main() {
  late _FakeDio dio;
  late ManagerApi api;

  setUp(() {
    dio = _FakeDio();
    api = ManagerApi(dio);
  });

  // ── getSummary ────────────────────────────────────────────────────────

  group('getSummary', () {
    test('returns parsed DashboardSummary', () async {
      dio.nextResponse = Response(
        requestOptions: RequestOptions(path: ApiEndpoints.getManagerDashboardSummary),
        statusCode: 200,
        data: {
          'message': {
            'branches': [
              {'name': 'Branch A', 'title': 'Branch A', 'cash_account': 'Cash', 'balance': 5000},
              {'name': 'Branch B', 'title': 'Branch B', 'balance': 3000},
            ],
            'total_balance': 8000,
          },
        },
      );

      final summary = await api.getSummary();
      expect(summary.branches, hasLength(2));
      expect(summary.branches.first.name, 'Branch A');
      expect(summary.totalBalance, 8000);
    });

    test('passes company param', () async {
      dio.nextResponse = Response(
        requestOptions: RequestOptions(path: ApiEndpoints.getManagerDashboardSummary),
        statusCode: 200,
        data: {'message': {'branches': [], 'total_balance': 0}},
      );

      await api.getSummary(company: 'JARZ');
      expect(dio.calls.first.query?['company'], 'JARZ');
    });
  });

  // ── getOrders ─────────────────────────────────────────────────────────

  group('getOrders', () {
    test('returns parsed invoices', () async {
      dio.nextResponse = Response(
        requestOptions: RequestOptions(path: ApiEndpoints.getManagerOrders),
        statusCode: 200,
        data: {
          'message': {
            'invoices': [
              {
                'name': 'INV-1',
                'customer': 'C1',
                'customer_name': 'Customer 1',
                'posting_date': '2024-06-01',
                'posting_time': '10:00:00',
                'grand_total': 500,
                'net_total': 450,
                'status': 'Paid',
                'branch': 'B1',
                'order_purpose': 'B2B Supply',
              },
            ],
            'has_more': true,
          },
        },
      );

      final page = await api.getOrders();
      final invoices = page.invoices;
      expect(page.hasMore, isTrue);
      expect(invoices.first.isB2b, isTrue);
      expect(invoices, hasLength(1));
      expect(invoices.first.name, 'INV-1');
      expect(invoices.first.grandTotal, 500);
      expect(invoices.first.branchName, 'B1');
    });

    test('returns empty list when no invoices key', () async {
      dio.nextResponse = Response(
        requestOptions: RequestOptions(path: ApiEndpoints.getManagerOrders),
        statusCode: 200,
        data: {'message': {}},
      );

      final page = await api.getOrders();
      expect(page.invoices, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('passes branch and state filters', () async {
      dio.nextResponse = Response(
        requestOptions: RequestOptions(path: ApiEndpoints.getManagerOrders),
        statusCode: 200,
        data: {'message': {'invoices': []}},
      );

      await api.getOrders(
          branch: 'B1', state: 'Received', channel: 'b2b', start: 20);
      expect(dio.calls.first.query?['channel'], 'b2b');
      expect(dio.calls.first.query?['start'], 20);
      expect(dio.calls.first.query?['limit'], 20);
      expect(dio.calls.first.query?['branch'], 'B1');
      expect(dio.calls.first.query?['state'], 'Received');
    });
  });

  // ── getStates ─────────────────────────────────────────────────────────

  group('getStates', () {
    test('returns list of state strings', () async {
      dio.nextResponse = Response(
        requestOptions: RequestOptions(path: ApiEndpoints.getManagerStates),
        statusCode: 200,
        data: {
          'message': {
            'states': ['Received', 'Ready', 'Out for Delivery', 'Delivered'],
          },
        },
      );

      final states = await api.getStates();
      expect(states, hasLength(4));
      expect(states, contains('Received'));
    });
  });

  // ── updateInvoiceBranch ───────────────────────────────────────────────

  group('updateInvoiceBranch', () {
    test('succeeds when server returns success', () async {
      dio.nextResponse = Response(
        requestOptions: RequestOptions(path: ApiEndpoints.updateInvoiceBranch),
        statusCode: 200,
        data: {'message': {'success': true}},
      );

      await api.updateInvoiceBranch(invoiceId: 'INV-1', newBranch: 'B2');
      expect(dio.calls.first.data, {'invoice_id': 'INV-1', 'new_branch': 'B2'});
    });

    test('throws when server returns failure', () async {
      dio.nextResponse = Response(
        requestOptions: RequestOptions(path: ApiEndpoints.updateInvoiceBranch),
        statusCode: 200,
        data: {
          'message': {
            'success': false,
            'error': 'Only submitted POS invoices can be reassigned',
          },
        },
      );

      expect(
        () => api.updateInvoiceBranch(invoiceId: 'INV-1', newBranch: 'B2'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Only submitted POS invoices can be reassigned'),
          ),
        ),
      );
    });

    test('throws backend reason from Dio response errors', () async {
      final requestOptions = RequestOptions(path: ApiEndpoints.updateInvoiceBranch);
      dio.nextError = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 417,
          data: {
            'message': {
              'error': 'Not allowed to change POS Profile after submission from Dokki to Nasr city',
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        () => api.updateInvoiceBranch(invoiceId: 'INV-1', newBranch: 'B2'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Not allowed to change POS Profile after submission from Dokki to Nasr city'),
          ),
        ),
      );
    });
  });

  // ── Model classes ─────────────────────────────────────────────────────

  group('BranchBalance.fromJson', () {
    test('parses all fields', () {
      final b = BranchBalance.fromJson({
        'name': 'branch-1',
        'title': 'Main Branch',
        'cash_account': 'Cash - JZ',
        'balance': 1500.5,
      });
      expect(b.name, 'branch-1');
      expect(b.title, 'Main Branch');
      expect(b.cashAccount, 'Cash - JZ');
      expect(b.balance, 1500.5);
    });

    test('title falls back to name', () {
      final b = BranchBalance.fromJson({
        'name': 'X',
        'balance': 0,
      });
      expect(b.title, 'X');
    });
  });

  group('ManagerInvoice.fromJson', () {
    test('parses all fields', () {
      final inv = ManagerInvoice.fromJson({
        'name': 'SI-1',
        'customer': 'C1',
        'customer_name': 'John',
        'posting_date': '2024-06-01',
        'posting_time': '12:00',
        'grand_total': 100,
        'net_total': 90,
        'status': 'Paid',
        'branch': 'B1',
      });
      expect(inv.name, 'SI-1');
      expect(inv.customerName, 'John');
      expect(inv.grandTotal, 100);
    });

    test('customer_name falls back to customer', () {
      final inv = ManagerInvoice.fromJson({
        'name': 'SI-1',
        'customer': 'C2',
        'posting_date': '2024-06-01',
        'posting_time': '12:00',
        'grand_total': 100,
        'net_total': 90,
        'status': 'Paid',
        'branch': 'B1',
      });
      expect(inv.customerName, 'C2');
    });
  });
}
