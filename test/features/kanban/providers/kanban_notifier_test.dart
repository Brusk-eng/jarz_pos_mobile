import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarz_pos/src/core/connectivity/connectivity_service.dart';
import 'package:jarz_pos/src/core/offline/offline_queue.dart';
import 'package:jarz_pos/src/core/websocket/websocket_service.dart';
import 'package:jarz_pos/src/features/kanban/models/kanban_filter_options.dart';
import 'package:jarz_pos/src/features/kanban/models/kanban_models.dart';
import 'package:jarz_pos/src/features/kanban/providers/kanban_provider.dart';
import 'package:jarz_pos/src/features/pos/data/models/draft_cart.dart';
import 'package:jarz_pos/src/features/kanban/services/kanban_service.dart';
import 'package:jarz_pos/src/features/kanban/services/notification_polling_service.dart';
import 'package:jarz_pos/src/features/pos/data/repositories/draft_cart_repository.dart';
import 'package:jarz_pos/src/features/pos/data/repositories/pos_repository.dart';
import 'package:jarz_pos/src/features/pos/state/pos_notifier.dart';

class _FakeKanbanService extends KanbanService {
  _FakeKanbanService()
      : super(Dio(BaseOptions()));

  Map<String, dynamic>? lastFilters;
  String? lastUpdatedInvoice;
  String? lastUpdatedState;
  String? lastExpectedState;
  bool updateShouldSucceed = true;
  Object? fetchInvoicesError;

  /// Lets a test hold a board fetch open so two loads can be in flight at once,
  /// and hand back a result set keyed to the request that asked for it.
  Completer<Map<String, List<InvoiceCard>>>? Function(Map<String, dynamic>? filters)?
      fetchInvoicesGate;
  final Map<String, List<InvoiceNote>> notesByInvoice = {
    'INV-OLD': [
      InvoiceNote.fromJson({
        'name': 'JIN-001',
        'sales_invoice': 'INV-OLD',
        'note': 'Initial note',
        'added_by': 'tester@example.com',
        'added_by_full_name': 'Tester',
        'added_on': '2026-06-04 09:00:00',
      }),
    ],
  };

  @override
  Future<List<KanbanColumn>> getKanbanColumns() async {
    return [
      KanbanColumn(id: 'received', name: 'Received', color: '#FFF'),
      KanbanColumn(id: 'processing', name: 'Processing', color: '#EEE'),
    ];
  }

  @override
  Future<Map<String, List<InvoiceCard>>> getKanbanInvoices({Map<String, dynamic>? filters}) async {
    if (fetchInvoicesError != null) {
      throw fetchInvoicesError!;
    }
    lastFilters = filters == null ? null : Map<String, dynamic>.from(filters);
    final gate = fetchInvoicesGate?.call(filters);
    if (gate != null) {
      return gate.future;
    }
    final older = InvoiceCard.fromJson({
      'name': 'INV-OLD',
      'invoice_id_short': 'OLD',
      'customer_name': 'Alice',
      'customer': 'CUST-1',
      'territory': 'Metro',
      'status': 'Received',
      'posting_date': '2024-03-01',
      'posting_time': '09:15:00',
      'creation': '2024-03-01 09:10:00',
      'grand_total': 100,
      'net_total': 90,
      'total_taxes_and_charges': 10,
      'full_address': '123 Test',
      'note_count': 1,
      'items': const [],
    });
    final newer = InvoiceCard.fromJson({
      'name': 'INV-NEW',
      'invoice_id_short': 'NEW',
      'customer_name': 'Bob',
      'customer': 'CUST-2',
      'territory': 'Metro',
      'status': 'Received',
      'posting_date': '2024-03-01',
      'posting_time': '18:45:00',
      'creation': '2024-03-01 18:40:00',
      'grand_total': 150,
      'net_total': 140,
      'total_taxes_and_charges': 10,
      'full_address': '456 Test',
      'items': const [],
    });
    return {
      'received': [older, newer],
      'processing': const [],
    };
  }

  /// What the dispatch endpoint answers. The backend picks the shape: an order
  /// carrying a transfer screenshot comes back `unpaid_online_deliver_unconfirmed`
  /// rather than as a collected cash order.
  Map<String, dynamic> ofdResponse = const {'success': true, 'mode': 'settle_later'};
  Map<String, dynamic>? lastOfdRequest;

  @override
  Future<Map<String, dynamic>> handleOutForDeliveryTransition({
    required String invoiceName,
    required String courier,
    required String mode,
    required String posProfile,
    required String idempotencyToken,
    String? partyType,
    String? party,
  }) async {
    lastOfdRequest = {
      'invoice': invoiceName,
      'courier': courier,
      'mode': mode,
      'pos_profile': posProfile,
    };
    return Map<String, dynamic>.from(ofdResponse);
  }

  @override
  Future<KanbanFilterOptions> getKanbanFilters() async {
    return KanbanFilterOptions(
      customers: [FilterOption(value: 'CUST-1', label: 'Alice')],
      states: const [],
    );
  }

  @override
  Future<bool> updateInvoiceState(
    String invoiceId,
    String newState, {
    bool shortageApproved = false,
    String? shortageReason,
    String? expectedState,
  }) async {
    lastUpdatedInvoice = invoiceId;
    lastUpdatedState = newState;
    lastExpectedState = expectedState;
    return updateShouldSucceed;
  }

  @override
  Future<Map<String, dynamic>> cancelInvoice({
    required String invoiceName,
    required String reason,
    String? notes,
  }) async {
    return {'success': true};
  }

  @override
  Future<List<InvoiceNote>> getInvoiceNotes(String invoiceId) async {
    return List<InvoiceNote>.from(notesByInvoice[invoiceId] ?? const []);
  }

  @override
  Future<InvoiceNoteSaveResult> addInvoiceNote({
    required String invoiceId,
    required String note,
  }) async {
    final saved = InvoiceNote.fromJson({
      'name': 'JIN-${(notesByInvoice[invoiceId]?.length ?? 0) + 1}',
      'sales_invoice': invoiceId,
      'note': note,
      'added_by': 'tester@example.com',
      'added_by_full_name': 'Tester',
      'added_on': '2026-06-04 10:30:00',
    });
    final items = List<InvoiceNote>.from(notesByInvoice[invoiceId] ?? const []);
    items.add(saved);
    notesByInvoice[invoiceId] = items;
    return InvoiceNoteSaveResult(note: saved, noteCount: items.length);
  }

  @override
  Future<dynamic> rawPost(String path, Map<String, dynamic> data) async {
    return {'message': 'ok'};
  }

  final List<String?> returnRequestIds = [];
  final List<String?> returnGoodsConditions = [];

  @override
  Future<Map<String, dynamic>> submitInvoiceReturn({
    required String invoiceName,
    required List<Map<String, dynamic>> lines,
    required String reason,
    required String returnType,
    required String refundMode,
    required bool payCourierForTrip,
    String? goodsCondition,
    String? notes,
    String? requestId,
  }) async {
    returnGoodsConditions.add(goodsCondition);
    returnRequestIds.add(requestId);
    return {'success': true, 'credit_note': 'ACC-SINV-CN-1'};
  }
}

class _FakeWebSocketService extends WebSocketService {
  final _kanbanController = StreamController<Map<String, dynamic>>.broadcast();
  final _invoiceController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  void connect() {}

  @override
  Stream<Map<String, dynamic>> get kanbanUpdates => _kanbanController.stream;

  @override
  Stream<Map<String, dynamic>> get invoiceStream => _invoiceController.stream;

  @override
  void dispose() {
    _kanbanController.close();
    _invoiceController.close();
  }
}

class _FakeNotificationPollingService extends NotificationPollingService {
  _FakeNotificationPollingService() : super(Dio());

  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get notificationStream => _controller.stream;

  @override
  void startPolling({Duration interval = const Duration(seconds: 30)}) {}

  @override
  void stopPolling() {}

  @override
  void dispose() {
    _controller.close();
  }
}

class _FakeOfflineQueue extends OfflineQueue {
  final List<Map<String, dynamic>> _transactions = [];

  @override
  Future<void> addTransaction(Map<String, dynamic> transaction) async {
    _transactions.add({
      'id': (_transactions.length + 1).toString(),
      'data': transaction,
      'status': 'pending',
      'endpoint': transaction['endpoint'],
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    return _transactions
        .where((tx) => tx['status'] == 'pending')
        .map((tx) => Map<String, dynamic>.from(tx))
        .toList();
  }

  @override
  Future<void> markAsProcessed(String id) async {
    for (final tx in _transactions) {
      if (tx['id'] == id) {
        tx['status'] = 'processed';
      }
    }
  }

  @override
  Future<void> markAsError(String id, String error) async {
    for (final tx in _transactions) {
      if (tx['id'] == id) {
        tx['status'] = 'error';
        tx['error'] = error;
      }
    }
  }

  @override
  Future<int> getPendingCount() async {
    return _transactions.where((tx) => tx['status'] == 'pending').length;
  }

  @override
  Future<void> clearAll() async {
    _transactions.clear();
  }
}

class _FakeConnectivityService extends ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  bool _online = true;

  @override
  Stream<bool> get connectivityStream => _controller.stream;

  @override
  void startMonitoring() {}

  @override
  Future<bool> hasConnection() async => _online;

  @override
  bool get isOnline => _online;

  void setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    _controller.add(value);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

class _DummyPosRepository extends PosRepository {
  _DummyPosRepository() : super(Dio());

  @override
  Future<List<Map<String, dynamic>>> getPosProfiles() async => const [];

  @override
  Future<List<Map<String, dynamic>>> getItems(
    String posProfile, {
    String? priceList,
    String? customer,
    String? orderPurpose,
  }) async => const [];

  @override
  Future<List<Map<String, dynamic>>> getBundles(
    String posProfile, {
    String? priceList,
    String? customer,
    String? orderPurpose,
  }) async => const [];

  @override
  Future<List<Map<String, dynamic>>> getPosPriceLists(String posProfile) async =>
      const [];
}

class _FakeDraftCartRepository extends DraftCartRepository {
  @override
  Future<List<DraftCart>> loadAll() async => const [];

  @override
  Future<void> upsert(DraftCart draft) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> clearAll() async {}
}

class _PosNotifierStub extends PosNotifier {
  _PosNotifierStub() : super(_DummyPosRepository(), _FakeDraftCartRepository()) {
    state = state.copyWith(
      profiles: const [
        {'name': 'Main'},
        {'name': 'Branch-2'},
      ],
    );
  }
}

Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);

InvoiceCard _card(String id) => InvoiceCard.fromJson({
      'name': id,
      'invoice_id_short': id,
      'customer_name': 'Whoever',
      'customer': 'CUST-9',
      'territory': 'Metro',
      'status': 'Received',
      'posting_date': '2024-03-02',
      'posting_time': '10:00:00',
      'creation': '2024-03-02 10:00:00',
      'grand_total': 10,
      'net_total': 10,
      'total_taxes_and_charges': 0,
      'full_address': 'Somewhere',
      'items': const [],
    });
InvoiceCard _unpaidCard(String id) => InvoiceCard.fromJson({
      'name': id,
      'invoice_id_short': id,
      'customer_name': 'Whoever',
      'customer': 'CUST-9',
      'territory': 'Metro',
      'status': 'Received',
      'doc_status': 'Unpaid',
      'posting_date': '2024-03-02',
      'posting_time': '10:00:00',
      'creation': '2024-03-02 10:00:00',
      'grand_total': 480,
      'net_total': 480,
      'outstanding_amount': 480,
      'total_taxes_and_charges': 0,
      'payment_method': 'Cash',
      'full_address': 'Somewhere',
      'items': const [],
    });
Future<void> _waitForInvoiceReloadDebounce() =>
    Future<void>.delayed(const Duration(milliseconds: 600));

void main() {
  group('KanbanNotifier', () {
    late ProviderContainer container;
    late _FakeKanbanService service;

    setUp(() {
      service = _FakeKanbanService();
      container = ProviderContainer(
        overrides: [
          kanbanServiceProvider.overrideWithValue(service),
          webSocketServiceProvider.overrideWithValue(_FakeWebSocketService()),
          notificationPollingServiceProvider
              .overrideWithValue(_FakeNotificationPollingService()),
          offlineQueueProvider.overrideWithValue(_FakeOfflineQueue()),
          connectivityServiceProvider.overrideWithValue(_FakeConnectivityService()),
          connectivityStatusProvider.overrideWith((ref) => Stream<bool>.value(true)),
          posNotifierProvider.overrideWith((ref) => _PosNotifierStub()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loadInvoices sorts Received column by posting datetime descending', () async {
      final notifier = container.read(kanbanProvider.notifier);

      await notifier.loadKanbanData();
      await _flushMicrotasks();

      final state = container.read(kanbanProvider);
      final received = state.invoices['received'];
      expect(received, isNotNull);
      expect(received, hasLength(2));
      expect(received!.first.id, 'INV-NEW');
      expect(received.last.id, 'INV-OLD');
    });

    /// Serve one board on the first fetch and an empty one afterwards.
    ///
    /// The second fetch is the reconcile that a transfer dispatch kicks off;
    /// answering it with a board that no longer holds the card makes
    /// `refreshSingle` a no-op, so what these tests assert is the optimistic
    /// patch itself rather than the server's later correction of it.
    var boardIsEmpty = false;
    void serveBoardOnce(InvoiceCard card) {
      boardIsEmpty = false;
      service.fetchInvoicesGate = (_) {
        final gate = Completer<Map<String, List<InvoiceCard>>>();
        gate.complete(boardIsEmpty
            ? {'received': const <InvoiceCard>[], 'out_for_delivery': const <InvoiceCard>[]}
            : {'received': [card], 'out_for_delivery': const <InvoiceCard>[]});
        return gate;
      };
    }

    InvoiceCard? cardInColumn(String column, String id) {
      final list = container.read(kanbanProvider).invoices[column] ?? const <InvoiceCard>[];
      for (final c in list) {
        if (c.id == id) return c;
      }
      return null;
    }

    test('a dispatch that collected the money still marks the card paid', () async {
      serveBoardOnce(_unpaidCard('INV-CASH'));
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      service.ofdResponse = const {
        'success': true,
        'mode': 'settle_later',
        'shipping_amount': 25,
      };
      boardIsEmpty = true; // the reconcile fetch must not re-seed the card
      await notifier.outForDeliveryUnified(
        invoiceId: 'INV-CASH',
        courier: 'HR-EMP-1',
        mode: 'later',
        posProfile: 'Dokki',
      );
      await _flushMicrotasks();

      final card = cardInColumn('out_for_delivery', 'INV-CASH');
      expect(card, isNotNull);
      expect(card!.docStatus, 'Paid');
      expect(card.isAwaitingOnlinePayment, isFalse);
    });

    test('a transfer dispatch leaves the card unpaid and awaiting the transfer', () async {
      // The card used to claim Paid the moment the order went out, for an order
      // whose money is still in the customer's bank until a manager confirms
      // the screenshot -- the same lie the backend stopped telling the ledger.
      serveBoardOnce(_unpaidCard('INV-TRANSFER'));
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      service.ofdResponse = const {
        'success': true,
        'mode': 'unpaid_online_deliver_unconfirmed',
        'payment_confirmation_status': 'Awaiting Payment',
        'shipping_amount': 25,
      };
      boardIsEmpty = true; // the reconcile fetch must not re-seed the card
      await notifier.outForDeliveryUnified(
        invoiceId: 'INV-TRANSFER',
        courier: 'HR-EMP-1',
        mode: 'later',
        posProfile: 'Dokki',
      );
      await _flushMicrotasks();

      final card = cardInColumn('out_for_delivery', 'INV-TRANSFER');
      expect(card, isNotNull, reason: 'the card still moves to Out For Delivery');
      expect(card!.docStatus, 'Unpaid');
      expect(card.isFullyPaid, isFalse);
      expect(card.isAwaitingOnlinePayment, isTrue);
    });

    test('an on-account dispatch leaves the card unpaid without queueing a transfer',
        () async {
      serveBoardOnce(_unpaidCard('INV-CREDIT'));
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      service.ofdResponse = const {
        'success': true,
        'mode': 'credit_deliver_on_account',
        'payment_confirmation_status': null,
      };
      boardIsEmpty = true; // the reconcile fetch must not re-seed the card
      await notifier.outForDeliveryUnified(
        invoiceId: 'INV-CREDIT',
        courier: 'HR-EMP-1',
        mode: 'later',
        posProfile: 'Dokki',
      );
      await _flushMicrotasks();

      final card = cardInColumn('out_for_delivery', 'INV-CREDIT');
      expect(card, isNotNull);
      expect(card!.docStatus, 'Unpaid');
      // Not awaiting: a credit order owes no transfer, and flagging one would
      // park it in the manager's reconciliation queue for ever.
      expect(card.isAwaitingOnlinePayment, isFalse);
    });

    test('updateFilters forwards filter payload to service', () async {
      final notifier = container.read(kanbanProvider.notifier);

      await notifier.loadKanbanData();
      await _flushMicrotasks();

      notifier.updateFilters(const KanbanFilters(searchTerm: 'bob'));
      await _waitForInvoiceReloadDebounce();

      expect(service.lastFilters?['searchTerm'], 'bob');
    });

    test('a slower background refresh cannot overwrite newer search results', () async {
      // The board is reloaded from realtime events and screen lifecycle as well
      // as by the user. Those responses used to be applied in completion order,
      // so an unfiltered refresh that started *before* a search but answered
      // *after* it replaced the search results with the whole board — the board
      // visibly snapping back moments after the matches appeared.
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      final backgroundGate = Completer<Map<String, List<InvoiceCard>>>();
      final searchGate = Completer<Map<String, List<InvoiceCard>>>();
      service.fetchInvoicesGate = (filters) {
        final term = (filters?['searchTerm'] ?? '') as String;
        return term == 'bob' ? searchGate : backgroundGate;
      };

      // A background refresh goes out first and is left in flight.
      unawaited(notifier.loadInvoices(immediate: true));
      await _flushMicrotasks();

      // The user searches while it is still open.
      notifier.updateFilters(const KanbanFilters(searchTerm: 'bob'));
      await _waitForInvoiceReloadDebounce();

      // The search answers first and is shown.
      searchGate.complete({
        'received': [_card('INV-BOB')],
        'processing': const <InvoiceCard>[],
      });
      await _flushMicrotasks();
      expect(
        container.read(kanbanProvider).invoices['received']!.map((c) => c.id).toList(),
        ['INV-BOB'],
      );

      // The stale unfiltered refresh lands afterwards and must be dropped.
      backgroundGate.complete({
        'received': [_card('INV-STALE')],
        'processing': const <InvoiceCard>[],
      });
      await _flushMicrotasks();
      expect(
        container.read(kanbanProvider).invoices['received']!.map((c) => c.id).toList(),
        ['INV-BOB'],
      );
    });

    test('a superseded load that fails does not post an error over the search', () async {
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      final backgroundGate = Completer<Map<String, List<InvoiceCard>>>();
      final searchGate = Completer<Map<String, List<InvoiceCard>>>();
      service.fetchInvoicesGate = (filters) {
        final term = (filters?['searchTerm'] ?? '') as String;
        return term == 'bob' ? searchGate : backgroundGate;
      };

      unawaited(notifier.loadInvoices(immediate: true));
      await _flushMicrotasks();

      notifier.updateFilters(const KanbanFilters(searchTerm: 'bob'));
      await _waitForInvoiceReloadDebounce();

      searchGate.complete({
        'received': [_card('INV-BOB')],
        'processing': const <InvoiceCard>[],
      });
      await _flushMicrotasks();

      backgroundGate.completeError(Exception('network dropped'));
      await _flushMicrotasks();

      final state = container.read(kanbanProvider);
      expect(state.error, isNull);
      expect(state.isLoading, isFalse);
      expect(
        state.invoices['received']!.map((c) => c.id).toList(),
        ['INV-BOB'],
      );
    });

    test('branch selection injects branches filter', () async {
      final notifier = container.read(kanbanProvider.notifier);

      await notifier.loadKanbanData();
      await _flushMicrotasks();

      notifier.setSelectedBranches({'Main'});
      await _waitForInvoiceReloadDebounce();
      expect(service.lastFilters?['branches'], equals(['Main']));

      notifier.toggleBranch('Branch-2');
      await _waitForInvoiceReloadDebounce();
      final selected = container.read(kanbanProvider).selectedBranches;
      expect(selected, containsAll({'Main', 'Branch-2'}));
      expect(service.lastFilters?['branches'], containsAll(['Main', 'Branch-2']));
    });

    test('loadColumns sets columns and clears isLoading', () async {
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadColumns();
      await _flushMicrotasks();

      final state = container.read(kanbanProvider);
      expect(state.columns, hasLength(2));
      expect(state.columns.first.name, 'Received');
      expect(state.isLoading, false);
    });

    test('loadFilters populates customers list', () async {
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadFilters();
      await _flushMicrotasks();

      final state = container.read(kanbanProvider);
      expect(state.customers, hasLength(1));
      expect(state.customers.first.customer, 'CUST-1');
    });

    test('loadKanbanData initializes columns, invoices and filters', () async {
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      final state = container.read(kanbanProvider);
      expect(state.columns, isNotEmpty);
      expect(state.invoices, isNotEmpty);
      expect(state.customers, isNotEmpty);
    });

    test('refreshSingle keeps Received sorted after replacing a card', () async {
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      await notifier.refreshSingle('INV-NEW');
      await _flushMicrotasks();

      final state = container.read(kanbanProvider);
      final received = state.invoices['received'] ?? [];
      expect(received.map((card) => card.id).toList(), ['INV-NEW', 'INV-OLD']);
    });

    test('refreshSingle surfaces errors so callers can fallback to reload', () async {
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      service.fetchInvoicesError = Exception('network failed');

      await expectLater(
        notifier.refreshSingle('INV-OLD'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('network failed'),
          ),
        ),
      );

      final state = container.read(kanbanProvider);
      expect(state.error, contains('Failed to refresh invoice'));
    });

    Future<Map<String, dynamic>?> submitReturn(KanbanNotifier notifier) {
      return notifier.submitInvoiceReturn(
        invoiceId: 'INV-OLD',
        lines: const [
          {'si_detail': 'row-1', 'qty': 1},
        ],
        reason: 'Customer refused',
        returnType: 'Customer Return',
        refundMode: 'customer_credit',
        payCourierForTrip: true,
      );
    }

    test('a posted return is reported as posted even if the card refresh fails',
        () async {
      // Showing "Return failed" here invited the operator to submit again.
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();
      service.fetchInvoicesError = Exception('network failed');

      final result = await submitReturn(notifier);

      expect(result, isNotNull);
      expect(result!['credit_note'], 'ACC-SINV-CN-1');
      expect(container.read(kanbanProvider).transitioningInvoices, isEmpty);
    });

    test('every return submission carries its own request id', () async {
      // Without one the server hashes (invoice, lines, options), so a second
      // identical partial return was taken for a replay and never posted.
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      await submitReturn(notifier);
      await submitReturn(notifier);

      expect(service.returnRequestIds, hasLength(2));
      expect(service.returnRequestIds.every((id) => id != null && id.startsWith('ret-app-')),
          isTrue);
      expect(service.returnRequestIds[0], isNot(service.returnRequestIds[1]));
    });

    test('the goods answer reaches the server, and silence stays silence', () async {
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      // The dialog did not ask (older server): nothing may be invented here.
      await submitReturn(notifier);
      await notifier.submitInvoiceReturn(
        invoiceId: 'INV-OLD',
        lines: const [
          {'si_detail': 'row-1', 'qty': 1},
        ],
        reason: 'Melted on the way back',
        returnType: 'Failed Delivery',
        refundMode: 'customer_credit',
        payCourierForTrip: true,
        goodsCondition: 'waste',
      );

      expect(service.returnGoodsConditions, [null, 'waste']);
    });

    test('clearError sets error to null', () async {
      final notifier = container.read(kanbanProvider.notifier);
      // Force an error state
      notifier.updateFilters(const KanbanFilters(searchTerm: 'anything'));
      await _flushMicrotasks();

      notifier.clearError();
      final state = container.read(kanbanProvider);
      expect(state.error, isNull);
    });

    test('toggleBranch adds and removes branches', () async {
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      notifier.setSelectedBranches({'Main'});
      await _flushMicrotasks();
      expect(container.read(kanbanProvider).selectedBranches, {'Main'});

      notifier.toggleBranch('Main');
      await _flushMicrotasks();
      expect(container.read(kanbanProvider).selectedBranches, isEmpty);
    });

    test('cancelInvoice removes the card and reloads', () async {
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      await notifier.cancelInvoice(invoiceId: 'INV-OLD', reason: 'test');
      await _flushMicrotasks();

      // After cancel reloads, both still appear from fake
      // but the cancel flow itself should not throw
      final state = container.read(kanbanProvider);
      expect(state.error, isNull);
    });

    test('addInvoiceNote patches note count on the existing card', () async {
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      final result = await notifier.addInvoiceNote(
        invoiceId: 'INV-OLD',
        note: 'Second note',
      );

      expect(result, isNotNull);
      final state = container.read(kanbanProvider);
      final card = state.invoices['received']!.firstWhere((entry) => entry.id == 'INV-OLD');
      expect(card.noteCount, 2);
      expect(card.hasNotes, isTrue);
    });

    test('addInvoiceNote patches the card face preview with the saved note', () async {
      final notifier = container.read(kanbanProvider.notifier);
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      await notifier.addInvoiceNote(
        invoiceId: 'INV-OLD',
        note: 'Second note',
      );

      final state = container.read(kanbanProvider);
      final card = state.invoices['received']!.firstWhere((entry) => entry.id == 'INV-OLD');
      expect(card.latestNote, 'Second note');
      expect(card.latestNotePreview, 'Second note');
    });

    test('realtime out-for-delivery transition keeps a transfer order unpaid', () async {
      // The realtime event and the API response are handled by the SAME patch,
      // so a dispatch made on another device must not mark this board's card
      // Paid either. The socket forwards the backend payload verbatim.
      serveBoardOnce(_unpaidCard('INV-WS-TRANSFER'));
      final notifier = container.read(kanbanProvider.notifier);
      final ws = container.read(webSocketServiceProvider) as _FakeWebSocketService;
      await notifier.loadKanbanData();
      await _flushMicrotasks();
      boardIsEmpty = true; // the reconcile fetch must not re-seed the card

      ws._kanbanController.add({
        'event': 'jarz_pos_out_for_delivery_transition',
        'invoice': 'INV-WS-TRANSFER',
        'invoice_id': 'INV-WS-TRANSFER',
        'mode': 'unpaid_online_deliver_unconfirmed',
        'payment_confirmation_status': 'Awaiting Payment',
        'courier_transaction': 'CT-1',
        'shipping_amount': 25,
      });
      await _flushMicrotasks();

      final card = cardInColumn('out_for_delivery', 'INV-WS-TRANSFER');
      expect(card, isNotNull);
      expect(card!.docStatus, 'Unpaid');
      expect(card.isAwaitingOnlinePayment, isTrue);
    });

    test('realtime invoice_note_added updates card badge count without reload', () async {
      final notifier = container.read(kanbanProvider.notifier);
      final ws = container.read(webSocketServiceProvider) as _FakeWebSocketService;
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      ws._kanbanController.add({
        'event': 'invoice_note_added',
        'invoice_id': 'INV-OLD',
        'note_count': 4,
      });
      await _flushMicrotasks();

      final state = container.read(kanbanProvider);
      final card = state.invoices['received']!.firstWhere((entry) => entry.id == 'INV-OLD');
      expect(card.noteCount, 4);
    });

    test('realtime invoice_note_added patches latest_note onto the card', () async {
      final notifier = container.read(kanbanProvider.notifier);
      final ws = container.read(webSocketServiceProvider) as _FakeWebSocketService;
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      ws._kanbanController.add({
        'event': 'invoice_note_added',
        'invoice_id': 'INV-OLD',
        'note_count': 4,
        'latest_note': 'Courier is at the gate',
      });
      await _flushMicrotasks();

      final state = container.read(kanbanProvider);
      final card = state.invoices['received']!.firstWhere((entry) => entry.id == 'INV-OLD');
      expect(card.noteCount, 4);
      expect(card.latestNote, 'Courier is at the gate');
    });

    test('realtime invoice_note_added without latest_note keeps the existing preview', () async {
      final notifier = container.read(kanbanProvider.notifier);
      final ws = container.read(webSocketServiceProvider) as _FakeWebSocketService;
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      ws._kanbanController.add({
        'event': 'invoice_note_added',
        'invoice_id': 'INV-OLD',
        'note_count': 2,
        'latest_note': 'First realtime note',
      });
      await _flushMicrotasks();

      // Older backend / partial payload: no latest_note key at all.
      ws._kanbanController.add({
        'event': 'invoice_note_added',
        'invoice_id': 'INV-OLD',
        'note_count': 3,
      });
      await _flushMicrotasks();

      final state = container.read(kanbanProvider);
      final card = state.invoices['received']!.firstWhere((entry) => entry.id == 'INV-OLD');
      expect(card.noteCount, 3);
      expect(card.latestNote, 'First realtime note');
    });

    test('realtime invoice_note_added clears the preview when note count drops to zero', () async {
      final notifier = container.read(kanbanProvider.notifier);
      final ws = container.read(webSocketServiceProvider) as _FakeWebSocketService;
      await notifier.loadKanbanData();
      await _flushMicrotasks();

      ws._kanbanController.add({
        'event': 'invoice_note_added',
        'invoice_id': 'INV-OLD',
        'note_count': 1,
        'latest_note': 'Note to be removed',
      });
      await _flushMicrotasks();

      ws._kanbanController.add({
        'event': 'invoice_note_added',
        'invoice_id': 'INV-OLD',
        'note_count': 0,
      });
      await _flushMicrotasks();

      final state = container.read(kanbanProvider);
      final card = state.invoices['received']!.firstWhere((entry) => entry.id == 'INV-OLD');
      expect(card.noteCount, 0);
      expect(card.hasNotes, isFalse);
      expect(card.latestNote, isNull);
    });
  });

  group('KanbanState.copyWith', () {
    test('copies all fields when none overridden', () {
      final state = KanbanState(
        isLoading: true,
        error: 'test error',
        selectedBranches: {'B1'},
        transitioningInvoices: {'INV-1'},
      );
      final copy = state.copyWith();
      expect(copy.isLoading, true);
      // error is not preserved by design (copyWith sets error: error param which defaults to null)
      expect(copy.selectedBranches, {'B1'});
      expect(copy.transitioningInvoices, {'INV-1'});
    });

    test('overrides individual fields', () {
      final state = KanbanState();
      final updated = state.copyWith(
        isLoading: true,
        error: 'err',
        selectedBranches: {'X'},
      );
      expect(updated.isLoading, true);
      expect(updated.error, 'err');
      expect(updated.selectedBranches, {'X'});
    });

    test('error defaults to null when not provided', () {
      final state = KanbanState(error: 'old');
      final copy = state.copyWith(isLoading: false);
      expect(copy.error, isNull);
    });
  });
}
