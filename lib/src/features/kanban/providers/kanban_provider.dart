import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/kanban_models.dart';
import '../services/kanban_service.dart';
import '../services/notification_polling_service.dart';
import '../widgets/transfer_proof_logic.dart'
    show ReceiptLookupFailure, classifyReceiptLookupError;
import 'collect_cash_prompt.dart';
import 'dispatch_outcome.dart';
import '../../../core/constants/ws_events.dart';
import '../../../core/network/dio_provider.dart'; // shared Dio instance
import '../../../core/network/frappe_error_message.dart';
import '../../../core/websocket/websocket_service.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../pos/state/pos_notifier.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

// Provider for KanbanService
final kanbanServiceProvider = Provider<KanbanService>((ref) {
  final dio = ref.watch(dioProvider); // use shared Dio with cookies
  return KanbanService(dio);
});

// State class for Kanban data
class KanbanState {
  final List<KanbanColumn> columns;
  final Map<String, List<InvoiceCard>> invoices;
  final bool isLoading;
  final String? error;
  final KanbanFilters filters;
  final List<CustomerOption> customers;
  final Set<String> transitioningInvoices; // Phase 7
  final Set<String> selectedBranches; // POS profile names filter

  KanbanState({
    this.columns = const [],
    this.invoices = const {},
    this.isLoading = false,
    this.error,
    this.filters = const KanbanFilters(),
    this.customers = const [],
    this.transitioningInvoices = const {},
    this.selectedBranches = const {},
  });

  KanbanState copyWith({
    List<KanbanColumn>? columns,
    Map<String, List<InvoiceCard>>? invoices,
    bool? isLoading,
    String? error,
    KanbanFilters? filters,
    List<CustomerOption>? customers,
    Set<String>? transitioningInvoices,
    Set<String>? selectedBranches,
  }) {
    return KanbanState(
      columns: columns ?? this.columns,
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filters: filters ?? this.filters,
      customers: customers ?? this.customers,
      transitioningInvoices: transitioningInvoices ?? this.transitioningInvoices,
      selectedBranches: selectedBranches ?? this.selectedBranches,
    );
  }
}

/// Whether a socket event concerns one of [selected] branches.
///
/// Empty [selected] means "all of my branches" (the server already scoped the
/// event to them), and an event that names no branch is let through rather
/// than risk dropping a legitimate update. Shared by the board and the app-wide
/// collect-cash listener so both judge an event the same way.
bool kanbanEventIsForBranches(Map<String, dynamic> event, Set<String> selected) {
  if (selected.isEmpty) return true;
  final branch = (event['kanban_profile'] ??
          event['custom_kanban_profile'] ??
          event['pos_profile'] ??
          '')
      .toString()
      .trim();
  if (branch.isEmpty) return true;
  return selected.contains(branch);
}

// Kanban state notifier
class KanbanNotifier extends StateNotifier<KanbanState> {
  final KanbanService _kanbanService;
  WebSocketService? _wsService;
  StreamSubscription<Map<String, dynamic>>? _kanbanSub;
  StreamSubscription<Map<String, dynamic>>? _pollingSub;
  StreamSubscription<Map<String, dynamic>>? _invoiceSub;
  final Ref _ref; // store ref for offline queue & connectivity
  bool _autoBranchesInitialized = false; // ensure we don't override user choice
  Timer? _loadInvoicesDebounce; // debounce rapid loadInvoices calls
  Completer<void>? _pendingLoad; // awaiters of the currently debounced load
  //: Monotonic id of the most recently *issued* board fetch.
  //:
  //: The board is reloaded from ~35 call sites, several of them driven by
  //: realtime events and screen lifecycle rather than by the user. Those fire
  //: while a search request is still in flight, and responses come back in
  //: completion order, not request order — so an unfiltered background refresh
  //: that started earlier could land last and replace the search results with
  //: the whole board. Only the newest request may write to state.
  int _loadInvoicesSeq = 0;

  String _formatActionError(
    Object error, {
    required String action,
    String? fallback,
  }) {
    final message = extractFrappeErrorMessage(
      error,
      fallback: fallback ?? action,
    );
    return message == action ? action : '$action: $message';
  }

  DateTime _parseInvoiceTimestamp(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime _receivedPostingDateTime(InvoiceCard card) {
    final date = card.postingDate.trim();
    final creationFallback = _parseInvoiceTimestamp(card.creation);
    if (date.isEmpty) {
      return creationFallback;
    }

    final time = (card.postingTime ?? '').trim();
    final postingDateTime = time.isEmpty
        ? DateTime.tryParse(date)
        : DateTime.tryParse('$date $time');
    return postingDateTime ?? DateTime.tryParse(date) ?? creationFallback;
  }

  int _compareReceivedCards(InvoiceCard a, InvoiceCard b) {
    final postingCompare = _receivedPostingDateTime(b).compareTo(_receivedPostingDateTime(a));
    if (postingCompare != 0) {
      return postingCompare;
    }

    final creationCompare = _parseInvoiceTimestamp(b.creation).compareTo(_parseInvoiceTimestamp(a.creation));
    if (creationCompare != 0) {
      return creationCompare;
    }

    return b.name.compareTo(a.name);
  }

  Map<String, List<InvoiceCard>> _sortReceivedColumn(Map<String, List<InvoiceCard>> invoices) {
    final receivedKey = _stateKey('Received');
    final received = invoices[receivedKey];
    if (received == null || received.length < 2) {
      return invoices;
    }

    final sorted = List<InvoiceCard>.from(received)..sort(_compareReceivedCards);
    invoices[receivedKey] = sorted;
    return invoices;
  }

  KanbanNotifier(this._kanbanService, Ref ref) : _ref = ref, super(KanbanState()) {
    _wsService = ref.read(webSocketServiceProvider);
    _initializeKanban();
    _attachRealtime();
    _attachNotificationPolling();
    _listenConnectivity();
    _autoSelectAllBranchesIfNeeded();
    // React to POS profile list becoming available later (after async load)
    _ref.listen(posNotifierProvider, (prev, next) {
      // If user already made a branch selection, do nothing
      if (_autoBranchesInitialized || state.selectedBranches.isNotEmpty) return;
      // When multiple profiles exist, preselect all to reflect multi-branch view
      if ((next.profiles.length) > 1) {
        final all = next.profiles
            .map((p) => (p['name'] ?? p['title'])?.toString())
            .whereType<String>()
            .toSet();
        if (all.isNotEmpty) {
          state = state.copyWith(selectedBranches: all);
          _autoBranchesInitialized = true;
          // Reload invoices with branch filter applied
          loadInvoices();
        }
      }
    });
  }

  // Lightweight passthrough helpers (some widgets expect these names)
  Future<Map<String, List<InvoiceCard>>> fetchInvoices() async {
    return _kanbanService.getKanbanInvoices(filters: state.filters.toJson());
  }

  Future<List<InvoiceNote>> getInvoiceNotes(String invoiceId) async {
    return _kanbanService.getInvoiceNotes(invoiceId);
  }

  Future<InvoiceNoteSaveResult?> addInvoiceNote({
    required String invoiceId,
    required String note,
  }) async {
    final result = await _kanbanService.addInvoiceNote(
      invoiceId: invoiceId,
      note: note,
    );
    // The note we just saved is by definition the latest one, so patch the
    // card-face preview too instead of waiting for a refetch.
    final savedNote = result.note.note.trim();
    _patchInvoiceNoteCount(
      invoiceId,
      result.noteCount,
      latestNote: savedNote.isEmpty ? null : savedNote,
    );
    return result;
  }

  void _autoSelectAllBranchesIfNeeded() {
    if (_autoBranchesInitialized || state.selectedBranches.isNotEmpty) return;
    final posState = _ref.read(posNotifierProvider);
    final profiles = posState.profiles;
    if (profiles.length > 1) {
      final all = profiles
          .map((p) => (p['name'] ?? p['title'])?.toString())
          .whereType<String>()
          .toSet();
      if (all.isNotEmpty) {
        state = state.copyWith(selectedBranches: all);
        _autoBranchesInitialized = true;
      }
    }
  }

  Future<dynamic> rawPost(String path, Map<String, dynamic> data) async {
    return _kanbanService.rawPost(path, data);
  }

  Future<dynamic> callBackend(String path, {Map<String, dynamic>? data}) async {
    // Use underlying KanbanService dio instance (exposed via method) or create lightweight post
    try {
      return await _kanbanService.rawPost(path, data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshSingle(String invoiceId) async {
    try {
      // The details payload backs the receipt and the order-details sheet, and it is
      // NOT autoDispose — without this it would serve whatever the invoice looked like
      // the first time it was opened, long after the card itself moved on.
      _ref.invalidate(invoiceDetailsProvider(invoiceId));
      final data = await fetchInvoices();
      // Find updated invoice card in result set, then patch existing state without full reload
      InvoiceCard? updated;
      for (final list in data.values) {
        final idx = list.indexWhere((c) => c.id == invoiceId || c.name == invoiceId);
        if (idx >= 0) {
          updated = list[idx];
          break;
        }
      }
      if (updated == null) return; // not found; skip
      final updatedCard = updated;
      final current = Map<String, List<InvoiceCard>>.from(state.invoices);
      // Remove from any column
      for (final key in current.keys) {
        final list = List<InvoiceCard>.from(current[key] ?? []);
        final before = list.length;
        list.removeWhere((c) => c.id == invoiceId || c.name == invoiceId);
        if (before != list.length) {
          current[key] = list;
        }
      }
      final destKey = _stateKey(updatedCard.status);
      final dest = List<InvoiceCard>.from(current[destKey] ?? []);
      dest.removeWhere((c) => c.id == updatedCard.id);
      dest.add(updatedCard);
      current[destKey] = dest;
      state = state.copyWith(invoices: _sortReceivedColumn(current));
    } catch (e) {
      debugPrint('Refresh single invoice failed for $invoiceId: $e');
      state = state.copyWith(
        error: _formatActionError(e, action: 'Failed to refresh invoice'),
      );
      rethrow;
    }
  }

  /// Patches the note badge count and the card-face note preview in place so the
  /// board reflects a new note without a refetch.
  ///
  /// [latestNote] null means "leave the existing preview alone" — except when
  /// [noteCount] drops to zero, where the preview is explicitly cleared (a
  /// hand-written copyWith cannot set a field back to null on its own).
  void _patchInvoiceNoteCount(
    String invoiceId,
    int noteCount, {
    String? latestNote,
  }) {
    final current = Map<String, List<InvoiceCard>>.from(state.invoices);
    for (final entry in current.entries) {
      final list = List<InvoiceCard>.from(entry.value);
      final index =
          list.indexWhere((card) => card.id == invoiceId || card.name == invoiceId);
      if (index < 0) {
        continue;
      }
      list[index] = list[index].copyWith(
        noteCount: noteCount,
        latestNote: latestNote,
        clearLatestNote: noteCount <= 0,
      );
      current[entry.key] = list;
      state = state.copyWith(invoices: _sortReceivedColumn(current));
      return;
    }
  }

  void _patchInvoiceWooOrderId(String invoiceId, int wooOrderId) {
    final current = Map<String, List<InvoiceCard>>.from(state.invoices);
    for (final entry in current.entries) {
      final list = List<InvoiceCard>.from(entry.value);
      final index =
          list.indexWhere((card) => card.id == invoiceId || card.name == invoiceId);
      if (index < 0) {
        continue;
      }
      list[index] = list[index].copyWith(wooOrderId: wooOrderId);
      current[entry.key] = list;
      state = state.copyWith(invoices: _sortReceivedColumn(current));
      return;
    }
  }

  Future<void> _initializeKanban() async {
    await loadColumns();
    await loadInvoices(immediate: true);
    await loadFilters();
  }

  Future<void> loadKanbanData() async {
    await _initializeKanban();
  }

  /// Whether a socket event concerns a branch this board is currently showing.
  ///
  /// The backend now addresses events to the owning branch's users, so this is
  /// a second line of defence for the case that actually bit us: a user
  /// assigned to several branches who has filtered down to one. Without it,
  /// another branch's order could still trigger a board reload or — worse — pop
  /// a "collect cash" dialog for an order this user is not handling.
  bool _eventIsForVisibleBranch(Map<String, dynamic> event) =>
      kanbanEventIsForBranches(event, state.selectedBranches);

  /// Whether a realtime event is a courier stop outcome or an address pin
  /// correction — the events that change a card's contents without moving it
  /// between columns.
  ///
  /// Reads the same set the WebSocket service binds and routes, so this branch
  /// cannot go live for an event the transport never subscribes to. Matched on the
  /// frozen [WsEvents] constants rather than substrings, so a backend rename shows
  /// up as a dead branch instead of a silently-matching prefix.
  static bool _isCourierStopEvent(String eventName) =>
      WebSocketService.courierStopEvents.contains(eventName);

  void _attachRealtime() {
    try {
      // Listen for kanban state change updates
      _kanbanSub = _wsService?.kanbanUpdates.listen((event) {
        if (!_eventIsForVisibleBranch(event)) return;
        final invoiceId = event['invoice'] as String? ?? event['invoice_id'] as String?;
        final eventName = (event['event'] ?? '').toString().toLowerCase();
        final paymentChanged = const [true, 1, '1', 'true', 'True']
            .contains(event['payment_changed']);

        final wooId = event['woo_order_id'];
        if (wooId != null && invoiceId != null) {
          _patchInvoiceWooOrderId(invoiceId, (wooId as num).toInt());
          return;
        }

        if (eventName == 'invoice_note_added' && invoiceId != null) {
          final noteCount = event['note_count'] is int
              ? event['note_count'] as int
              : int.tryParse((event['note_count'] ?? '').toString());
          final rawLatestNote = event['latest_note']?.toString().trim();
          if (noteCount != null) {
            _patchInvoiceNoteCount(
              invoiceId,
              noteCount,
              latestNote: (rawLatestNote == null || rawLatestNote.isEmpty)
                  ? null
                  : rawLatestNote,
            );
          } else {
            refreshSingle(invoiceId);
          }
          return;
        }

        // Courier stop outcomes + address pin corrections (COURIER_CONTRACTS §7).
        //
        // Handled before the generic move handler below because none of these
        // carry a state transition: a failed delivery keeps the invoice at Out
        // for Delivery by design (§5 invariant 4), and a pin update changes only
        // the Address. Falling through to `_applyRealtimeMove` would find no
        // `new_state_key` and drop the event, leaving the board stale until
        // somebody refreshed by hand.
        //
        // `refreshSingle` re-reads the card, which is what brings the new
        // `custom_delivered_at` / failure fields — and therefore the recomputed
        // run progress — onto the board.
        if (_isCourierStopEvent(eventName)) {
          if (invoiceId != null) {
            refreshSingle(invoiceId);
          } else {
            // A pin correction is about an Address, so the payload may name no
            // invoice at all — several cards can share one address. Fall back to
            // a board reload rather than dropping the event and leaving the pin
            // badge stale. `loadInvoices` is debounced (500 ms), so a burst of
            // these collapses into a single fetch.
            loadInvoices();
          }
          return;
        }

        if (eventName.contains('custom_shipping') || eventName.contains('trip_')) {
          loadInvoices();
          return;
        }

        if (paymentChanged && invoiceId != null) {
          refreshSingle(invoiceId);
          return;
        }

        // The collect-cash dialog for these events is opened app-wide by
        // [collectCashPromptListenerProvider], not here: this notifier exists
        // only once Kanban has been opened. The board just patches its cards.
        // Detect Sales Partner unpaid Out For Delivery fast-path realtime event
        // Backend event: jarz_pos_sales_partner_unpaid_ofd (mode == sales_partner_unpaid_cash)
        try {
          final mode = (event['mode'] ?? '').toString();
          final paymentEntry = event['payment_entry'];
          final hasPartner = (event['sales_partner'] ?? event['salesPartner'] ?? '').toString().isNotEmpty;
          if (invoiceId != null && hasPartner && mode == 'sales_partner_unpaid_cash' && paymentEntry != null) {
            // Ensure card patched to Out For Delivery
            _patchInvoiceOutForDelivery(invoiceId, event);
            return; // handled
          }
        } catch (_) {}
        // If it's a new invoice broadcast (no old state), just refresh invoices
        final oldKeyForNew = event['old_state_key'] as String?;
        if ((oldKeyForNew == null || oldKeyForNew.isEmpty) && event['new_state_key'] != null) {
          // New cards created from other devices/sources
          loadInvoices();
          return;
        }
        if (event['event'] == 'jarz_pos_out_for_delivery_transition' || event.containsKey('courier_transaction')) {
          if (invoiceId != null) {
            _patchInvoiceOutForDelivery(invoiceId, event);
          }
          return; // skip generic move handler
        }
        final oldKey = event['old_state_key'] as String?;
        final newKey = event['new_state_key'] as String?;
        if (invoiceId != null && newKey != null) {
            _applyRealtimeMove(invoiceId, oldKey, newKey);
        }
      });
  // Also listen for new POS invoices and refresh the Received column
      _invoiceSub = _wsService?.invoiceStream.listen((inv) async {
        // Basic guard: ensure Kanban is initialized
        if (state.columns.isEmpty) return;
        if (!_eventIsForVisibleBranch(inv)) return;
        // Simple strategy: reload invoices to pick up the new card
        await loadInvoices();
      });
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          debugPrint('Kanban realtime attach failed: $e');
        }
      }
    }
  }

  // UI helper for the board's own actions (the unpaid Sales Partner dispatch
  // and a cash payment). One hand-off reaches the dialog up to four times: the
  // tap itself, then the collect-prompt, unpaid-OFD and state-change events
  // (handled app-wide by [collectCashPromptListenerProvider]). All of them go
  // through the one shared [CollectCashPromptGate], so staff see one dialog.
  void _showCollectCashDialog({required String amount, String? invoiceId, Object? wooOrderId}) {
    _ref.read(collectCashPrompterProvider).show(
          amount: amount,
          invoiceId: invoiceId,
          wooOrderId: wooOrderId,
        );
  }

  void _attachNotificationPolling() {
    try {
      // Start the notification polling service
      final pollingService = _ref.read(notificationPollingServiceProvider);
      pollingService.startPolling();
      
      // Listen for polling notifications
      _pollingSub = pollingService.notificationStream.listen((event) {
        if (kDebugMode) {
          if (kDebugMode) {
            debugPrint('📊 KANBAN: Received polling notification: ${event['type']}');
          }
        }
        
        final eventType = event['type'] as String?;
        switch (eventType) {
          case 'new_invoice':
            final invoiceData = event['data'] as Map<String, dynamic>?;
            if (invoiceData != null) {
              if (kDebugMode) {
                if (kDebugMode) {
                  debugPrint('📊 KANBAN: New invoice from polling: ${invoiceData['name']}');
                }
              }
              // Refresh invoices to show the new one
              loadInvoices();
            }
            break;
          case 'invoice_updated':
            final invoiceData = event['data'] as Map<String, dynamic>?;
            if (invoiceData != null) {
              if (kDebugMode) {
                if (kDebugMode) {
                  debugPrint('📊 KANBAN: Updated invoice from polling: ${invoiceData['name']}');
                }
              }
              // Refresh invoices to show updates
              loadInvoices();
            }
            break;
          case 'updates_available':
            final totalUpdates = event['total_updates'] as int?;
            if (totalUpdates != null && totalUpdates > 0) {
              if (kDebugMode) {
                if (kDebugMode) {
                  debugPrint('📊 KANBAN: $totalUpdates updates available from polling');
                }
              }
              // Refresh invoices to show all updates
              loadInvoices();
            }
            break;
        }
      });
      
      if (kDebugMode) {
        if (kDebugMode) {
          debugPrint('📊 KANBAN: Notification polling service attached');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          debugPrint('❌ KANBAN: Failed to attach notification polling: $e');
        }
      }
    }
  }

  void _patchInvoiceOutForDelivery(String invoiceId, Map<String, dynamic> payload) {
    final current = Map<String, List<InvoiceCard>>.from(state.invoices);
  InvoiceCard? card; // find source column and remove from there
    for (final e in current.entries) {
      final idx = e.value.indexWhere((c) => c.id == invoiceId);
      if (idx >= 0) { card = e.value[idx]; break; }
    }
    if (card == null) return;
    final outKey = _stateKey('Out For Delivery');
    final shippingAmt = (payload['shipping_amount'] ?? card.shippingExpense);
    // Not every dispatch collects the money any more. An order paid by bank
    // transfer, and one taken on account, both go out while the customer still
    // owes — see `dispatch_outcome.dart`. Stamping those Paid here showed the
    // floor a collected order until the next board reload, which is the same
    // thing the backend fix stopped doing to the ledger.
    final leftUnpaid = dispatchLeftInvoiceUnpaid(payload);
    final awaitsTransfer = dispatchAwaitsTransfer(payload);
    final updated = card.copyWith(
      status: 'Out For Delivery',
      docStatus: leftUnpaid ? docStatusAfterUnpaidDispatch(card.docStatus) : 'Paid',
      paymentConfirmationStatus: awaitsTransfer
          ? 'Awaiting Payment'
          : card.paymentConfirmationStatus,
      shippingExpense: (shippingAmt is num ? shippingAmt.toDouble() : card.shippingExpense),
      courier: payload['display_name'] ?? payload['courier'] ?? card.courier,
      settlementMode: payload['mode'] ?? payload['settlement'] ?? card.settlementMode,
    );
    // Remove from whichever column contains it
    for (final key in current.keys) {
      final list = List<InvoiceCard>.from(current[key] ?? []);
  final before = list.length;
  list.removeWhere((c) => c.id == invoiceId);
  if (list.length != before) {
        current[key] = list;
        break;
      }
    }
    final dest = List<InvoiceCard>.from(current[outKey] ?? []);
    dest.removeWhere((c) => c.id == invoiceId);
    dest.add(updated);
    current[outKey] = dest;
    final ti = Set<String>.from(state.transitioningInvoices)..remove(invoiceId);
    state = state.copyWith(invoices: _sortReceivedColumn(current), transitioningInvoices: ti);
    if (awaitsTransfer) {
      // The server did more than move the card: it also corrected the order's
      // declared payment method to the receipt's (a Woo order reaches dispatch
      // labelled Cash however the customer paid), and the response carries no
      // method to copy. Pull the row rather than guess it — this is the same
      // reconcile the InstaPay dispatch path does, and it only runs for the
      // rare order that carries a transfer screenshot.
      unawaited(refreshSingle(invoiceId));
    }
  }

  /// The column a card currently occupies, or null when it is not on the board.
  String? _currentStateOf(String invoiceId) {
    for (final entry in state.invoices.entries) {
      for (final card in entry.value) {
        if (card.id == invoiceId) return card.status;
      }
    }
    return null;
  }

  void _applyRealtimeMove(String invoiceId, String? oldStateKey, String newStateKey) {
    final current = Map<String, List<InvoiceCard>>.from(state.invoices);
    InvoiceCard? card;
    // oldStateKey/newStateKey are keys (already normalized) from backend payload
    if (oldStateKey != null && current.containsKey(oldStateKey)) {
      final list = List<InvoiceCard>.from(current[oldStateKey]!);
      final idx = list.indexWhere((c) => c.id == invoiceId);
      if (idx >= 0) { card = list.removeAt(idx); current[oldStateKey] = list; }
    } else {
      for (final entry in current.entries) {
        final idx = entry.value.indexWhere((c) => c.id == invoiceId);
        if (idx >= 0) { final list = List<InvoiceCard>.from(entry.value); card = list.removeAt(idx); current[entry.key] = list; break; }
      }
    }
    if (card != null) {
      final displayName = state.columns.firstWhere(
        (c) => c.id == newStateKey,
        orElse: () => KanbanColumn(id: newStateKey, name: newStateKey.replaceAll('_', ' '), color: '#F5F5F5'),
      ).name;
      final updatedCard = card.copyWith(status: displayName);
      final dest = List<InvoiceCard>.from(current[newStateKey] ?? []);
      dest.removeWhere((c) => c.id == invoiceId);
      dest.add(updatedCard);
      current[newStateKey] = dest;
      state = state.copyWith(invoices: _sortReceivedColumn(current));
    }
  }

  // Removed unused _getStateDisplayName helper (was only used for display mapping; realtime path now resolves directly)

  Future<void> loadColumns() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final columns = await _kanbanService.getKanbanColumns();
      state = state.copyWith(columns: columns, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _formatActionError(e, action: 'Failed to load columns'),
      );
    }
  }

  Future<void> loadInvoices({bool immediate = false}) {
    _loadInvoicesDebounce?.cancel();

    if (immediate) {
      // A queued debounce is subsumed by this load, so its awaiters have to be
      // released when this one lands. Previously the timer was simply cancelled
      // and its completer abandoned, so anything holding that future — most
      // visibly pull-to-refresh — spun forever.
      final queued = _pendingLoad;
      _pendingLoad = null;
      final future = _doLoadInvoices();
      if (queued != null) {
        unawaited(future.whenComplete(() {
          if (!queued.isCompleted) queued.complete();
        }));
      }
      return future;
    }

    // Successive debounced calls share one completer: they all resolve when the
    // single coalesced fetch finishes.
    final completer = _pendingLoad ??= Completer<void>();
    _loadInvoicesDebounce = Timer(const Duration(milliseconds: 500), () async {
      _pendingLoad = null;
      try {
        await _doLoadInvoices();
      } finally {
        if (!completer.isCompleted) completer.complete();
      }
    });
    return completer.future;
  }

  Future<void> _doLoadInvoices() async {
    final seq = ++_loadInvoicesSeq;
    state = state.copyWith(isLoading: true, error: null);

    try {
      Map<String, dynamic> filterMap = state.filters.hasFilters ? state.filters.toJson() : {};
      // Inject branch filter if any selected (subset of allowed profiles)
      if (state.selectedBranches.isNotEmpty) {
        // Send as list of names under 'branches' key
        filterMap['branches'] = state.selectedBranches.toList();
      }
      final invoices = await _kanbanService.getKanbanInvoices(filters: filterMap);
      // A newer load was issued while this one was in flight; its filters are
      // the ones the user is looking at, so this answer is stale by definition.
      if (seq != _loadInvoicesSeq) return;
      final sorted = Map<String, List<InvoiceCard>>.from(invoices);

      state = state.copyWith(invoices: _sortReceivedColumn(sorted), isLoading: false);
    } catch (e) {
      // Same rule for failures: a superseded request must not clear the
      // spinner or post an error banner over the load that replaced it.
      if (seq != _loadInvoicesSeq) return;
      state = state.copyWith(
        isLoading: false,
        error: _formatActionError(e, action: 'Failed to load invoices'),
      );
    }
  }

  Future<void> loadFilters() async {
    try {
      final filtersData = await _kanbanService.getKanbanFilters();
      // Convert FilterOptions to CustomerOptions
      final customers = filtersData.customers
          .map((option) => CustomerOption(
                customer: option.value,
                customerName: option.label,
              ))
          .toList();
      state = state.copyWith(customers: customers);
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          debugPrint('Failed to load filters: $e');
        }
      }
      // Set empty list on error
      state = state.copyWith(customers: <CustomerOption>[]);
    }
  }

  Future<Map<String, dynamic>> previewOutForDelivery(String invoiceId) {
    return _kanbanService.previewOutForDelivery(invoiceId);
  }

  Future<void> updateInvoiceState(
    String invoiceId,
    String newState, {
    bool shortageApproved = false,
    String? shortageReason,
  }) async {
    // Resolve to canonical state LABEL from either label or id/key
    String canonical;
    final cols = state.columns;
    // 1) Match by label (case-insensitive)
    final byLabel = cols.cast<KanbanColumn?>().firstWhere(
      (c) => c != null && c.name.toLowerCase() == newState.toLowerCase(),
      orElse: () => null,
    );
    if (byLabel != null) {
      canonical = byLabel.name;
    } else {
      // 2) Match by id/key (received like 'out_for_delivery')
      final key = _stateKey(newState);
      final byId = cols.cast<KanbanColumn?>().firstWhere(
        (c) => c != null && c.id.toLowerCase() == key,
        orElse: () => null,
      );
      canonical = byId?.name ?? newState;
    }

    // Capture where the card sits *now*, before any optimistic move, so the
    // server can reject the change if a colleague already moved it.
    final expectedState = _currentStateOf(invoiceId);

    // Guard: Out For Delivery handling
    if (canonical.toLowerCase() == 'out for delivery') {
      final all = state.invoices.values.expand((e) => e).toList();
      final card = all.firstWhere((c) => c.id == invoiceId, orElse: () => InvoiceCard.fromJson({'name': invoiceId}));
      final isPaid = (card.docStatus ?? '').toLowerCase() == 'paid' || (card.effectiveStatus.toLowerCase() == 'paid');
      final hasPartner = (card.salesPartner ?? '').isNotEmpty;
      final isPickup = card.isPickup;
      
      // PICKUP ORDERS: Simple state update (no courier or payment logic needed)
      if (isPickup) {
        // ENFORCE PAYMENT: Pickup orders must be paid before moving to Out For Delivery
        if (!isPaid) {
          state = state.copyWith(
            error: 'Pickup order must be paid before moving to Out For Delivery. Please mark as paid first.'
          );
          return;
        }
        
        try {
          _optimisticMove(invoiceId, canonical);
          final success = await _kanbanService.updateInvoiceState(
            invoiceId,
            canonical,
            shortageApproved: shortageApproved,
            shortageReason: shortageReason,
            expectedState: expectedState,
          );
          if (!success) {
            state = state.copyWith(error: 'Failed to update pickup order state');
          } else {
            await loadInvoices();
          }
          return;
        } catch (e) {
          state = state.copyWith(
            error: _formatActionError(e, action: 'Pickup order dispatch error'),
          );
          return;
        }
      }
      
      if (hasPartner) {
        // Branch: Sales Partner invoice
        if (!isPaid) {
          // UNPAID + Sales Partner -> invoke fast-path backend (auto cash PE & OFD)
          try {
            // Prefer the invoice's own POS profile (its branch) for the cash account.
            // Fall back to the globally selected profile so single-profile users still work.
            final posProfile = (card.posProfile?.isNotEmpty == true)
                ? card.posProfile
                : _ref.read(posNotifierProvider).selectedProfile?['name'];
            if (posProfile == null) {
              state = state.copyWith(error: 'Select POS Profile before dispatching unpaid Sales Partner invoice');
              return;
            }
            final res = await _kanbanService.salesPartnerUnpaidOutForDelivery(
              invoiceName: invoiceId,
              posProfile: posProfile,
            );
            // Patch board optimistically
            _patchInvoiceOutForDelivery(invoiceId, {
              'invoice': invoiceId,
              'mode': 'sales_partner_unpaid_cash',
              'payment_entry': res['payment_entry'],
              'sales_partner': card.salesPartner,
              'shipping_amount': 0, // backend event will correct later if needed
            });
            // Show collect prompt immediately (in addition to realtime listener) for reliability
            final amt = (res['amount'] ?? '').toString();
            if (amt.isNotEmpty) {
              _showCollectCashDialog(amount: amt, invoiceId: invoiceId, wooOrderId: card.wooOrderId);
            }
            // Refresh authoritative data
            await loadInvoices();
            return;
          } catch (e) {
            state = state.copyWith(
              error: _formatActionError(e, action: 'Sales Partner unpaid dispatch failed'),
            );
            return;
          }
        } else {
          // Already paid + Sales Partner -> use the shared kanban state endpoint so OFD shortage approval stays consistent.
          try {
            _optimisticMove(invoiceId, canonical);
            final success = await _kanbanService.updateInvoiceState(
              invoiceId,
              canonical,
              shortageApproved: shortageApproved,
              shortageReason: shortageReason,
              expectedState: expectedState,
            );
            if (!success) {
              state = state.copyWith(error: 'Sales Partner paid dispatch failed');
              return;
            }
            await loadInvoices();
          } catch (e) {
            state = state.copyWith(
              error: _formatActionError(e, action: 'Sales Partner paid dispatch error'),
            );
          }
          return;
        }
      } else {
        // Non-partner invoices must use courier flow – block drag direct change
        state = state.copyWith(error: 'Use Out For Delivery flow (courier required)');
        return;
      }
    }

    final prevState = state;
    try {
      _optimisticMove(invoiceId, canonical);
      final success = await _kanbanService.updateInvoiceState(
        invoiceId,
        canonical,
        shortageApproved: shortageApproved,
        shortageReason: shortageReason,
        expectedState: expectedState,
      );
      if (!success) {
        state = prevState.copyWith(error: 'Update failed (no success flag)');
      } else {
        // Safety: ensure card present in target column (in case optimistic move failed)
        final targetKey = _stateKey(canonical);
        final placed = state.invoices[targetKey]?.any((c) => c.id == invoiceId) ?? false;
        if (!placed) {
          _optimisticMove(invoiceId, canonical); // force-place
        }
        // Force reload from backend to reconcile with authoritative data (dual-field write)
        await loadInvoices();
        // Fallback: if target column absent (edge case), insert column key and force-place card
        if (!state.invoices.containsKey(targetKey)) {
          final refreshed = Map<String, List<InvoiceCard>>.from(state.invoices);
            refreshed[targetKey] = [];
          state = state.copyWith(invoices: refreshed);
          _optimisticMove(invoiceId, canonical);
        }
      }
    } catch (e) {
      state = prevState.copyWith(
        error: _formatActionError(e, action: 'Error updating invoice'),
      );
    }
  }

  void _optimisticMove(String invoiceId, String targetStateDisplay) {
    final targetKey = _stateKey(targetStateDisplay);
  final current = Map<String, List<InvoiceCard>>.from(state.invoices);
  InvoiceCard? card;
    for (final entry in current.entries) {
      final idx = entry.value.indexWhere((c) => c.id == invoiceId);
      if (idx >= 0) { final list = List<InvoiceCard>.from(entry.value); card = list.removeAt(idx); current[entry.key] = list; break; }
    }
    if (card == null) return;
    final updated = card.copyWith(status: targetStateDisplay);
    final dest = List<InvoiceCard>.from(current[targetKey] ?? []);
    dest.removeWhere((c) => c.id == invoiceId);
    dest.add(updated);
    current[targetKey] = dest;
    state = state.copyWith(invoices: _sortReceivedColumn(current));
  }

  Future<Map<String, dynamic>?> cancelInvoice({
    required String invoiceId,
    required String reason,
    String? notes,
  }) async {
    final transitioning = Set<String>.from(state.transitioningInvoices)..add(invoiceId);
    state = state.copyWith(transitioningInvoices: transitioning, error: null);

    try {
      final result = await _kanbanService.cancelInvoice(
        invoiceName: invoiceId,
        reason: reason,
        notes: notes,
      );

      final current = Map<String, List<InvoiceCard>>.from(state.invoices);
      for (final entry in current.entries.toList()) {
        final list = List<InvoiceCard>.from(entry.value);
        final before = list.length;
        list.removeWhere((c) => c.id == invoiceId || c.name == invoiceId);
        if (list.length != before) {
          current[entry.key] = list;
        }
      }
      state = state.copyWith(invoices: _sortReceivedColumn(current));

      await loadInvoices();
      return result;
    } catch (e) {
      state = state.copyWith(
        error: _formatActionError(e, action: 'Cancellation failed'),
      );
      return null;
    } finally {
      final updatedTransitioning = Set<String>.from(state.transitioningInvoices);
      updatedTransitioning.remove(invoiceId);
      state = state.copyWith(transitioningInvoices: updatedTransitioning);
    }
  }

  /// Load the read-only return preview that drives the confirmation dialog.
  Future<Map<String, dynamic>?> loadReturnPreview(String invoiceId) async {
    try {
      return await _kanbanService.getReturnPreview(invoiceId);
    } catch (e) {
      state = state.copyWith(
        error: _formatActionError(e, action: 'Return preview failed'),
      );
      return null;
    }
  }

  /// Post a return. Unlike a cancellation the invoice stays on the board — it
  /// is still a real, submitted order — so this refreshes the single card
  /// rather than removing it.
  Future<Map<String, dynamic>?> submitInvoiceReturn({
    required String invoiceId,
    required List<Map<String, dynamic>> lines,
    required String reason,
    required String returnType,
    required String refundMode,
    required bool payCourierForTrip,
    String? goodsCondition,
    String? notes,
  }) async {
    final transitioning = Set<String>.from(state.transitioningInvoices)..add(invoiceId);
    state = state.copyWith(transitioningInvoices: transitioning, error: null);

    try {
      // One id per submission. Without it the server derives the id from
      // (invoice, lines, options), so a second, genuinely separate partial
      // return of the same quantity is mistaken for a replay and not posted.
      final result = await _kanbanService.submitInvoiceReturn(
        invoiceName: invoiceId,
        lines: lines,
        reason: reason,
        returnType: returnType,
        refundMode: refundMode,
        payCourierForTrip: payCourierForTrip,
        goodsCondition: goodsCondition,
        notes: notes,
        requestId: 'ret-app-${const Uuid().v4()}',
      );
      // The return is posted by now. A failed card refresh must not turn it
      // into "Return failed" — the operator would try again. The realtime
      // KANBAN_UPDATE event re-places the card anyway.
      try {
        await refreshSingle(invoiceId);
      } catch (e) {
        debugPrint('Return posted but card refresh failed for $invoiceId: $e');
      }
      return result;
    } catch (e) {
      state = state.copyWith(
        error: _formatActionError(e, action: 'Return failed'),
      );
      return null;
    } finally {
      final updatedTransitioning = Set<String>.from(state.transitioningInvoices);
      updatedTransitioning.remove(invoiceId);
      state = state.copyWith(transitioningInvoices: updatedTransitioning);
    }
  }

  void updateFilters(KanbanFilters newFilters) {
    state = state.copyWith(filters: newFilters);
    loadInvoices(); // Reload with new filters
  }

  // Branch multi-select helpers
  void setSelectedBranches(Set<String> branches) {
    // If empty set, treat as ALL (i.e., clear filter)
    final newSet = Set<String>.from(branches);
    state = state.copyWith(selectedBranches: newSet);
    loadInvoices();
  }

  void toggleBranch(String branchName) {
    final s = Set<String>.from(state.selectedBranches);
    if (s.contains(branchName)) {
      s.remove(branchName);
    } else {
      s.add(branchName);
    }
    state = state.copyWith(selectedBranches: s);
    loadInvoices();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  String _stateKey(String label) => label.toLowerCase().replaceAll(' ', '_');

  @override
  void dispose() {
    _kanbanSub?.cancel();
    _pollingSub?.cancel();
    // Was never cancelled: a second listener on rebuild meant every socket
    // event triggered two full board reloads.
    _invoiceSub?.cancel();
    _loadInvoicesDebounce?.cancel();
    // Release anyone awaiting a debounced load that will now never run.
    final pending = _pendingLoad;
    _pendingLoad = null;
    if (pending != null && !pending.isCompleted) pending.complete();
    super.dispose();
  }

  Future<Map<String, dynamic>?> payInvoice({
    required String invoiceId,
    required String paymentMode,
    String? posProfile,
  }) async {
    try {
      final result = await _kanbanService.payInvoice(
        invoiceName: invoiceId,
        paymentMode: paymentMode,
        posProfile: posProfile,
      );
      
      // Show collect cash dialog if payment was successful and method is Cash
  if (result['success'] == true && paymentMode.toLowerCase() == 'cash') {
        final amount = result['amount'] ?? result['paid_amount'] ?? result['allocated_amount'];
        if (amount != null) {
          _showCollectCashDialog(
            amount: amount.toString(),
            invoiceId: invoiceId,
          );
        }
      }
      
      // Refresh invoice details & list after payment
      await loadInvoices();
      return result;
    } catch (e) {
      debugPrint('Pay invoice error: $e');
      // Rethrown, like the receipt methods below, so the card can show WHY.
      // Returning null here left the caller only the generic "Payment failed"
      // and hid refusals such as a missing confirmed transfer receipt. No
      // "Payment failed:" prefix: the server sentence alone is what the error
      // presenter matches, and the prefix pushed long refusals past its length
      // gate.
      throw Exception(extractFrappeErrorMessage(e, fallback: 'Payment failed'));
    }
  }
  
    Future<Map<String, dynamic>?> settleSingleInvoicePaid({
      required String invoiceId,
      required String posProfile,
      required String partyType,
      required String party,
    }) async {
      try {
        final res = await _kanbanService.settleSingleInvoicePaid(
          invoiceName: invoiceId,
          posProfile: posProfile,
          partyType: partyType,
          party: party,
        );
        return res;
      } catch (e) {
        return null;
      }
    }

    Future<Map<String, dynamic>?> settleCourierCollectedPayment({
      required String invoiceId,
      required String posProfile,
      required String partyType,
      required String party,
    }) async {
      try {
        final res = await _kanbanService.settleCourierCollectedPayment(
          invoiceName: invoiceId,
          posProfile: posProfile,
          partyType: partyType,
          party: party,
        );
        return res;
      } catch (e) {
        return null;
      }
    }

  /// For UNPAID invoices when staff selects "settle now":
  /// - Creates Payment Entry moving receivable to Courier Outstanding
  /// - Creates Courier Transaction with amount = invoice outstanding, shipping_amount = city expense
  /// - Sets state to Out For Delivery via backend and emits realtime event consumed by _patchInvoiceOutForDelivery
  Future<Map<String, dynamic>?> markCourierOutstanding({
    required String invoiceId,
    required String courier,
  String? partyType,
  String? party,
  String? courierDisplay,
  }) async {
    final prevState = state;
    // Clear any stale error that might render a full-screen panel
    state = state.copyWith(error: null);
    final ti = Set<String>.from(state.transitioningInvoices)..add(invoiceId);
    state = state.copyWith(transitioningInvoices: ti);
    try {
      final res = await _kanbanService.markCourierOutstanding(
        invoiceName: invoiceId,
        courier: courier,
  partyType: partyType,
  party: party,
      );
      // Preserve friendly courier label if backend doesn't include it
      if (courierDisplay != null) {
        res.putIfAbsent('display_name', () => courierDisplay);
      }
      // Move card immediately to Out For Delivery (optimistic), then reconcile.
      // Prefer backend-provided payload for accurate fields (shipping_amount/mode/courier).
      try {
        _patchInvoiceOutForDelivery(invoiceId, res);
      } catch (_) {
  _optimisticOutForDelivery(invoiceId, courier: courierDisplay ?? courier, mode: 'settle_later');
      }
      // Backend also publishes realtime; still reload to reconcile authoritative data.
      await loadInvoices();
      final ti2 = Set<String>.from(state.transitioningInvoices)..remove(invoiceId);
      state = state.copyWith(transitioningInvoices: ti2);
      return res;
    } catch (e) {
      // Keep board visible but surface the error for UX; don't revert the optimistic move here
      state = prevState.copyWith(
        error: _formatActionError(e, action: 'Mark courier outstanding failed'),
        transitioningInvoices: Set<String>.from(prevState.transitioningInvoices)..remove(invoiceId),
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> outForDeliveryUnified({
    required String invoiceId,
    required String courier,
    required String mode, // pay_now | settle_later
    required String posProfile,
  String? partyType,
  String? party,
  String? courierDisplay,
  }) async {
    final token = const Uuid().v4();
    final prevState = state;
    final ti = Set<String>.from(state.transitioningInvoices)..add(invoiceId);
    state = state.copyWith(transitioningInvoices: ti);
  _optimisticOutForDelivery(invoiceId, courier: courierDisplay ?? courier, mode: mode);

    final connectivity = _ref.read(connectivityServiceProvider);
    final offlineQueue = _ref.read(offlineQueueProvider);

    if (!connectivity.isOnline) {
      await offlineQueue.addTransaction({
        'endpoint': 'ofd_transition',
        'method': 'POST',
        'data': {
          'invoice_id': invoiceId,
          'courier': courier,
          'mode': mode,
          'pos_profile': posProfile,
          'idempotency_token': token,
          if (partyType != null) 'party_type': partyType,
          if (party != null) 'party': party,
        },
      });
      final ti2 = Set<String>.from(state.transitioningInvoices)..remove(invoiceId);
      state = state.copyWith(transitioningInvoices: ti2);
      return {
        'success': true,
        'offline_queued': true,
        'invoice': invoiceId,
        'courier': courier,
        'mode': mode,
        'idempotency_token': token,
  if (partyType != null) 'party_type': partyType,
  if (party != null) 'party': party,
      };
    }

    try {
      final res = await _kanbanService.handleOutForDeliveryTransition(
        invoiceName: invoiceId,
        courier: courier,
        mode: mode,
        posProfile: posProfile,
        idempotencyToken: token,
  partyType: partyType,
  party: party,
      );
      // Preserve friendly courier label if backend doesn't include it
      if (courierDisplay != null) {
        res.putIfAbsent('display_name', () => courierDisplay);
      }
      _patchInvoiceOutForDelivery(invoiceId, res);
      // Fallback reconcile: ensure card ended up in OFD column; otherwise force reload
      final ofdKey = _stateKey('Out For Delivery');
      final placed = state.invoices[ofdKey]?.any((c) => c.id == invoiceId) ?? false;
      if (!placed) {
        await loadInvoices();
      }
      return res;
    } catch (e) {
      state = prevState.copyWith(
        error: _formatActionError(e, action: 'Out For Delivery failed'),
        transitioningInvoices: Set<String>.from(prevState.transitioningInvoices)..remove(invoiceId),
      );
      return null;
    }
  }

  void _optimisticOutForDelivery(String invoiceId, {String? courier, String? mode}) {
  final targetKey = _stateKey('Out For Delivery'); // keep label
    if ((state.invoices[targetKey]?.any((c) => c.id == invoiceId)) ?? false) return;
    final current = Map<String, List<InvoiceCard>>.from(state.invoices);
    InvoiceCard? card;
    for (final e in current.entries) {
      final idx = e.value.indexWhere((c) => c.id == invoiceId);
      if (idx >= 0) { final list = List<InvoiceCard>.from(e.value); card = list.removeAt(idx); current[e.key] = list; break; }
    }
    if (card == null) return;
    final updated = card.copyWith(
      status: 'Out For Delivery',
      docStatus: card.docStatus ?? 'Paid',
      courier: courier ?? card.courier,
      settlementMode: mode ?? card.settlementMode,
    );
    final dest = List<InvoiceCard>.from(current[targetKey] ?? []);
    dest.removeWhere((c) => c.id == invoiceId);
    dest.add(updated);
    current[targetKey] = dest;
    state = state.copyWith(invoices: _sortReceivedColumn(current));
  }

  Future<List<Map<String, String>>> getCouriers({String? posProfile}) async {
    try {
      return await _kanbanService.fetchCouriers(posProfile: posProfile);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, String>?> createDeliveryParty({
    required String partyType,
    String? name,
    String? firstName,
    String? lastName,
    required String phone,
    String? posProfile,
    String? deliveryPartner,
    bool noDeliveryPartner = false,
  }) async {
    try {
      final res = await _kanbanService.createDeliveryParty(
        partyType: partyType,
        name: name,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        posProfile: posProfile,
        deliveryPartner: deliveryPartner,
        noDeliveryPartner: noDeliveryPartner,
      );
      return res;
    } catch (e) {
      throw Exception(_formatActionError(e, action: 'Create courier failed'));
    }
  }

  Future<List<Map<String, String>>> getDeliveryPartnersList() async {
    return _kanbanService.getDeliveryPartnersList();
  }

  void _listenConnectivity() {
    // Listen to connectivity status (AsyncValue<bool>) and replay queue when back online
    _ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (prev, next) {
      final online = next.value;
      if (online == true) {
        _replayOfflineQueue();
      }
    });
  }

  Future<void> _replayOfflineQueue() async {
    final queue = _ref.read(offlineQueueProvider);
    final pending = await queue.getPendingTransactions();
    if (pending.isEmpty) return;

    final abandoned = <String>[];
    var replayed = 0;

    for (final tx in pending) {
      final data = tx['data'] as Map<String, dynamic>?;
      if (data == null) continue;
      if (tx['endpoint'] == 'ofd_transition') {
        final invoiceId = data['invoice_id'] as String;
        final courier = data['courier'] as String;
        final mode = data['mode'] as String;
        final posProfile = data['pos_profile'] as String;
        final token = data['idempotency_token'] as String;
        final partyType = data['party_type'] as String?;
        final party = data['party'] as String?;
        try {
          final res = await _kanbanService.handleOutForDeliveryTransition(
            invoiceName: invoiceId,
            courier: courier,
            mode: mode,
            posProfile: posProfile,
            idempotencyToken: token,
            partyType: partyType,
            party: party,
          );
          _patchInvoiceOutForDelivery(invoiceId, res);
          await queue.markAsProcessed(tx['id']);
          replayed++;
        } catch (e) {
          // Retry on the next reconnect until the attempts run out; only then
          // is the action parked. Either way the staff member hears about it —
          // they were told the dispatch succeeded, so silence here means an
          // order sits "Out For Delivery" on the board and nowhere else.
          final exhausted = await queue.markAttemptFailed(tx['id'], e.toString());
          if (exhausted) abandoned.add(invoiceId);
        }
      }
    }

    if (abandoned.isNotEmpty) {
      state = state.copyWith(
        error: 'Could not sync ${abandoned.length} offline dispatch'
            '${abandoned.length == 1 ? '' : 'es'} (${abandoned.join(', ')}). '
            'Please redo the dispatch for these orders.',
      );
    }
    if (replayed > 0) {
      // Pull authoritative state for anything that did go through.
      await loadInvoices();
    }
  }

  /// Update customer address and make it the default
  Future<bool> updateCustomerAddress({
    required String customer,
    required String address,
    required String phone,
    String? invoice,
  }) async {
    try {
      final response = await _kanbanService.updateCustomerAddress(
        customer: customer,
        address: address,
        phone: phone,
        invoice: invoice,
      );
      
      return response['success'] == true || response['message'] == 'success';
    } catch (e) {
      debugPrint('Error updating customer address: $e');
      rethrow;
    }
  }

  /// Transfer invoice to a different POS profile
  Future<bool> transferInvoice({
    required String invoiceId,
    required String newBranch,
  }) async {
    try {
      await _kanbanService.transferInvoice(
        invoiceId: invoiceId,
        newBranch: newBranch,
      );
      return true;
    } catch (e) {
      debugPrint('Transfer invoice error: $e');
      // Set error state so UI can show it
      state = state.copyWith(
        error: _formatActionError(e, action: 'Transfer failed'),
      );
      return false;
    }
  }

  Future<bool> updateDeliverySlot({
    required String invoiceId,
    required String deliveryDate,
    required String deliveryTimeFrom,
    required int deliveryDuration,
    String deliverySlotLabel = '',
  }) async {
    try {
      await _kanbanService.updateDeliverySlot(
        invoiceId: invoiceId,
        deliveryDate: deliveryDate,
        deliveryTimeFrom: deliveryTimeFrom,
        deliveryDuration: deliveryDuration,
        deliverySlotLabel: deliverySlotLabel,
      );
      return true;
    } catch (e) {
      debugPrint('Update delivery slot error: $e');
      state = state.copyWith(
        error: _formatActionError(e, action: 'Update delivery slot failed'),
      );
      return false;
    }
  }

  /// Create payment receipt
  Future<Map<String, dynamic>?> createPaymentReceipt({
    required String salesInvoice,
    required String paymentMethod,
    required double amount,
    required String posProfile,
  }) async {
    try {
      final result = await _kanbanService.createPaymentReceipt(
        salesInvoice: salesInvoice,
        paymentMethod: paymentMethod,
        amount: amount,
        posProfile: posProfile,
      );
      return result;
    } catch (e) {
      debugPrint('Create payment receipt error: $e');
      throw Exception(_formatActionError(e, action: 'Failed to create receipt'));
    }
  }

  /// List payment receipts
  Future<List<Map<String, dynamic>>> listPaymentReceipts({
    String? posProfile,
    String? status,
  }) async {
    try {
      return await _kanbanService.listPaymentReceipts(
        posProfile: posProfile,
        status: status,
      );
    } catch (e) {
      debugPrint('List payment receipts error: $e');
      return [];
    }
  }

  /// One payment receipt as the server holds it now, or null when there is no
  /// current receipt: missing, or on a branch this user cannot read.
  ///
  /// Every other failure is rethrown untouched, so the caller can recognise a
  /// server that predates `get_payment_receipt` (see
  /// [classifyReceiptLookupError]) and fall back to [listPaymentReceipts].
  Future<Map<String, dynamic>?> getPaymentReceipt({
    required String receiptName,
  }) async {
    try {
      return await _kanbanService.getPaymentReceipt(receiptName: receiptName);
    } catch (e) {
      debugPrint('Get payment receipt error: $e');
      if (classifyReceiptLookupError(e) == ReceiptLookupFailure.noReceipt) {
        return null;
      }
      rethrow;
    }
  }

  /// Upload receipt image
  Future<Map<String, dynamic>?> uploadReceiptImage({
    required String receiptName,
    required String imageData,
    required String filename,
  }) async {
    try {
      return await _kanbanService.uploadReceiptImage(
        receiptName: receiptName,
        imageData: imageData,
        filename: filename,
      );
    } catch (e) {
      debugPrint('Upload receipt image error: $e');
      throw Exception(_formatActionError(e, action: 'Failed to upload image'));
    }
  }

  /// Remove receipt image
  Future<Map<String, dynamic>?> removeReceiptImage({
    required String receiptName,
  }) async {
    try {
      return await _kanbanService.removeReceiptImage(
        receiptName: receiptName,
      );
    } catch (e) {
      debugPrint('Remove receipt image error: $e');
      throw Exception(_formatActionError(e, action: 'Failed to remove image'));
    }
  }

  /// Confirm receipt
  Future<Map<String, dynamic>?> confirmReceipt({
    required String receiptName,
  }) async {
    try {
      return await _kanbanService.confirmReceipt(
        receiptName: receiptName,
      );
    } catch (e) {
      debugPrint('Confirm receipt error: $e');
      throw Exception(_formatActionError(e, action: 'Failed to confirm receipt'));
    }
  }

  /// Reject receipt
  Future<Map<String, dynamic>?> rejectReceipt({
    required String receiptName,
    required String reason,
  }) async {
    try {
      return await _kanbanService.rejectReceipt(
        receiptName: receiptName,
        reason: reason,
      );
    } catch (e) {
      debugPrint('Reject receipt error: $e');
      throw Exception(_formatActionError(e, action: 'Failed to reject receipt'));
    }
  }

  /// Get accessible POS profiles
  Future<List<String>> getAccessiblePOSProfiles() async {
    try {
      return await _kanbanService.getAccessiblePOSProfiles();
    } catch (e) {
      debugPrint('Get accessible POS profiles error: $e');
      return [];
    }
  }
}

// Provider for Kanban state
final kanbanProvider = StateNotifierProvider<KanbanNotifier, KanbanState>((ref) {
  final svc = ref.watch(kanbanServiceProvider);
  return KanbanNotifier(svc, ref);
});

/// Provider for the count of unconfirmed payment receipts (refreshed on demand).
final unconfirmedReceiptsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final svc = ref.watch(kanbanServiceProvider);
    final receipts = await svc.listPaymentReceipts(status: 'Unconfirmed');
    return receipts.length;
  } catch (_) {
    return 0;
  }
});

// Provider for specific invoice details
final invoiceDetailsProvider = FutureProvider.family<InvoiceCard?, String>((
  ref,
  invoiceId,
) async {
  final kanbanService = ref.watch(kanbanServiceProvider);
  final invoice = await kanbanService.getInvoiceDetails(invoiceId);
  return invoice;
});
