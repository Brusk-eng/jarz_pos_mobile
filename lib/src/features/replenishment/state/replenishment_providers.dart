import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/frappe_error_message.dart';
import '../../stock_transfer/data/stock_handover_models.dart';
import '../../stock_transfer/data/stock_transfer_service.dart';
import '../data/models/branch_replenishment.dart';
import '../data/replenishment_service.dart';
import '../domain/replenishment_draft.dart';

/// What the factory should send today.
///
/// Not auto-disposed on a timer and not polled: the numbers move with the
/// day's sales, and a list that reshuffles under the hand loading the van is
/// worse than one that is ten minutes old. Refresh is an explicit action, plus
/// an automatic one after a send.
final replenishmentPlanProvider =
    FutureProvider.autoDispose<ReplenishmentPlan>((ref) {
  return ref.watch(replenishmentServiceProvider).getPlan();
});

/// The branch the user picked, or null while they have not picked one — in
/// which case the screen falls back to [defaultBranchWarehouse]. Kept null
/// rather than eagerly resolved so a refresh that changes which branch is
/// worst does not yank the selection out from under someone mid-typing.
final selectedBranchWarehouseProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Large cartons the preparer has in hand, per branch warehouse.
///
/// Not auto-disposed: the number is remembered for the session, so reopening
/// the packing guide does not reset it to zero.
final largeCartonsInHandProvider = StateProvider.family<int, String>(
  (ref, warehouse) => 0,
);

/// The outcome of the last send, kept on screen until the next attempt.
class ReplenishmentSendResult {
  const ReplenishmentSendResult.sent({
    required this.branchLabel,
    required this.lineCount,
    required this.totalQty,
    required this.stockEntry,
    this.handover = '',
    this.pending = false,
  }) : success = true,
       error = null,
       failedItemName = null;

  const ReplenishmentSendResult.failed({
    required this.branchLabel,
    required this.error,
    required this.failedItemName,
  }) : success = false,
       lineCount = 0,
       totalQty = 0,
       stockEntry = '',
       handover = '',
       pending = false;

  final bool success;
  final String branchLabel;
  final int lineCount;
  final double totalQty;
  final String stockEntry;

  /// Set when the branch must confirm before anything moves: `submit_transfer`
  /// answered `pending: true` with a handover name instead of a Stock Entry.
  final String handover;
  final bool pending;

  /// The raw failure, so the screen can run it through the app's own error
  /// presenter instead of this layer guessing at wording.
  final Object? error;

  /// The row the server complained about, when its message named one.
  final String? failedItemName;
}

/// Typed quantities, held as OVERRIDES rather than a seeded copy.
///
/// A row with no entry here reads its quantity straight off the plan's
/// `send_now`, so nothing has to be copied when the payload arrives and there
/// is no window where the screen shows stale figures. [generation] changes
/// whenever the overrides are dropped, and the rows key their text controllers
/// on it so the fields re-read their initial value.
class ReplenishmentDraft {
  const ReplenishmentDraft({
    this.edits = const {},
    this.generation = 0,
    this.sending = false,
    this.result,
  });

  final Map<String, Map<String, double>> edits;
  final int generation;
  final bool sending;
  final ReplenishmentSendResult? result;

  double qtyFor(String warehouse, ReplenishmentItem item) =>
      edits[warehouse]?[item.itemCode] ?? item.sendNow;

  Map<String, double> quantitiesFor(ReplenishmentBranch branch) => {
    for (final item in branch.items)
      item.itemCode: qtyFor(branch.warehouse, item),
  };

  ReplenishmentDraft copyWith({
    Map<String, Map<String, double>>? edits,
    int? generation,
    bool? sending,
    ReplenishmentSendResult? result,
    bool clearResult = false,
  }) {
    return ReplenishmentDraft(
      edits: edits ?? this.edits,
      generation: generation ?? this.generation,
      sending: sending ?? this.sending,
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

class ReplenishmentDraftNotifier extends AutoDisposeNotifier<ReplenishmentDraft> {
  @override
  ReplenishmentDraft build() => const ReplenishmentDraft();

  void setQty(String warehouse, String itemCode, double qty) {
    final next = {
      for (final entry in state.edits.entries)
        entry.key: Map<String, double>.from(entry.value),
    };
    (next[warehouse] ??= <String, double>{})[itemCode] = qty < 0 ? 0 : qty;
    state = state.copyWith(edits: next);
  }

  /// Drops every override and re-reads the plan. Used after a send and by the
  /// refresh action — the point of both is to stop trusting what was typed.
  void resetAndReload() {
    state = state.copyWith(
      edits: const {},
      generation: state.generation + 1,
      clearResult: true,
    );
    ref.invalidate(replenishmentPlanProvider);
  }

  /// Re-reads the plan but keeps what was typed (the generation change only
  /// makes the rows re-read their quantity from the kept overrides).
  void refreshPlan() {
    state = state.copyWith(generation: state.generation + 1);
    ref.invalidate(replenishmentPlanProvider);
  }

  /// Asks another branch to hand [lines] to [targetWarehouse] through the same
  /// `submit_transfer` path the factory send uses. The server turns a
  /// branch-to-branch transfer into a pending handover the other side confirms.
  /// Returns null on success, the raw error otherwise.
  Future<Object?> requestMove({
    required String fromWarehouse,
    required String targetWarehouse,
    required List<Map<String, dynamic>> lines,
  }) async {
    if (state.sending || lines.isEmpty) return null;
    state = state.copyWith(sending: true);
    try {
      await ref
          .read(stockTransferServiceProvider)
          .submitTransfer(
            sourceWarehouse: fromWarehouse,
            targetWarehouse: targetWarehouse,
            lines: lines,
          );
      state = state.copyWith(sending: false);
      refreshPlan();
      return null;
    } catch (error) {
      state = state.copyWith(sending: false);
      return error;
    }
  }

  void clearResult() {
    if (state.result == null) return;
    state = state.copyWith(clearResult: true);
  }

  /// Sends exactly what is typed for [branch] through `submit_transfer`.
  ///
  /// Reuses the Stock Transfer transport on purpose: this screen decides WHAT
  /// to move, it is not a second way to move things, and a divergent client
  /// for the same endpoint is how the two screens would drift apart.
  Future<bool> send({
    required ReplenishmentBranch branch,
    required String sourceWarehouse,
  }) async {
    if (state.sending) return false;
    final quantities = state.quantitiesFor(branch);
    final lines = sendLines(branch, quantities);
    if (lines.isEmpty) return false;
    final totals = totalsFor(branch, quantities);

    state = state.copyWith(sending: true, clearResult: true);
    try {
      final response = await ref
          .read(stockTransferServiceProvider)
          .submitTransfer(
            sourceWarehouse: sourceWarehouse,
            targetWarehouse: branch.warehouse,
            lines: lines,
          );
      final outcome = TransferSubmitOutcome.fromJson(response);
      state = state.copyWith(
        sending: false,
        edits: {
          for (final entry in state.edits.entries)
            if (entry.key != branch.warehouse)
              entry.key: Map<String, double>.from(entry.value),
        },
        generation: state.generation + 1,
        result: ReplenishmentSendResult.sent(
          branchLabel: branch.displayName,
          lineCount: totals.lineCount,
          totalQty: totals.totalQty,
          stockEntry: outcome.stockEntry ?? '',
          handover: outcome.handover ?? '',
          pending: outcome.pending,
        ),
      );
      ref.invalidate(replenishmentPlanProvider);
      return true;
    } catch (error) {
      // Freeze what was typed into the overrides. Untouched rows were reading
      // through to the plan, and a background refresh would otherwise quietly
      // reset them — the one thing a failed send must never do.
      final failed = failedItemFromError(
        extractFrappeErrorMessage(error, fallback: ''),
        branch,
      );
      state = state.copyWith(
        sending: false,
        edits: {
          for (final entry in state.edits.entries)
            entry.key: Map<String, double>.from(entry.value),
          branch.warehouse: quantities,
        },
        result: ReplenishmentSendResult.failed(
          branchLabel: branch.displayName,
          error: error,
          failedItemName: failed?.displayName,
        ),
      );
      return false;
    }
  }
}

final replenishmentDraftProvider =
    NotifierProvider.autoDispose<ReplenishmentDraftNotifier, ReplenishmentDraft>(
      ReplenishmentDraftNotifier.new,
    );
