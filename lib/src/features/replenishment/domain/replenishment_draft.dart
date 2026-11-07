import '../data/models/branch_replenishment.dart';
import 'carton_packing.dart';

/// What one branch's typed load adds up to.
class SendTotals {
  const SendTotals({required this.lineCount, required this.totalQty});

  final int lineCount;
  final double totalQty;

  bool get isEmpty => lineCount == 0 || totalQty <= 0;
}

/// The branch the screen should open on.
///
/// Whoever opens this screen opened it because somebody is running out, so the
/// default is the branch with the most items below cover rather than the first
/// warehouse alphabetically. Ties break on the size of the load, then on the
/// warehouse name, so the same payload always lands on the same branch instead
/// of shuffling between refreshes.
String? defaultBranchWarehouse(ReplenishmentPlan plan) {
  if (plan.branches.isEmpty) return null;
  final ranked = [...plan.branches];
  ranked.sort((a, b) {
    final byCover = b.summary.itemsBelowCover.compareTo(
      a.summary.itemsBelowCover,
    );
    if (byCover != 0) return byCover;
    final byLoad = b.summary.totalSendNow.compareTo(a.summary.totalSendNow);
    if (byLoad != 0) return byLoad;
    return a.warehouse.compareTo(b.warehouse);
  });
  return ranked.first.warehouse;
}

/// Pre-fills the editable column from the server's capped, proportionally
/// split [ReplenishmentItem.sendNow] — never from `suggested_qty`, which can
/// exceed what the factory holds and would send a van after stock that is not
/// there.
Map<String, double> seedQuantities(ReplenishmentBranch branch) {
  return {
    for (final item in branch.items) item.itemCode: item.sendNow,
  };
}

/// The `submit_transfer` line payload for what is currently typed.
///
/// Emitted in the branch's own row order and skipping non-positive lines, so
/// the request carries exactly what the person loading the van can see on the
/// screen and nothing else.
List<Map<String, dynamic>> sendLines(
  ReplenishmentBranch branch,
  Map<String, double> quantities,
) {
  final lines = <Map<String, dynamic>>[];
  for (final item in branch.items) {
    final qty = quantities[item.itemCode] ?? 0;
    if (qty <= 0) continue;
    lines.add({'item_code': item.itemCode, 'qty': qty});
  }
  return lines;
}

SendTotals totalsFor(
  ReplenishmentBranch branch,
  Map<String, double> quantities,
) {
  var count = 0;
  var qty = 0.0;
  for (final item in branch.items) {
    final typed = quantities[item.itemCode] ?? 0;
    if (typed <= 0) continue;
    count += 1;
    qty += typed;
  }
  return SendTotals(lineCount: count, totalQty: qty);
}

/// The typed load as packing lines: whole jars only, in the branch's row order.
List<PackLine> packLinesFor(
  ReplenishmentBranch branch,
  Map<String, double> quantities,
) {
  final lines = <PackLine>[];
  for (final item in branch.items) {
    final qty = (quantities[item.itemCode] ?? 0).floor();
    if (qty <= 0) continue;
    lines.add(
      PackLine(
        itemCode: item.itemCode,
        name: item.displayName,
        size: item.jarSize,
        qty: qty,
      ),
    );
  }
  return lines;
}

/// Which line a failed send was about, when the server said so.
///
/// `submit_transfer` posts every line in one Stock Entry, so a rejection names
/// the offending item in prose and nothing else. Matching that prose back to a
/// row is the difference between "it failed" and "the Lotus line failed" —
/// and the quantities stay on screen either way, so a match is a bonus rather
/// than something the recovery path depends on.
ReplenishmentItem? failedItemFromError(
  String? message,
  ReplenishmentBranch branch,
) {
  final text = (message ?? '').toLowerCase();
  if (text.isEmpty) return null;
  for (final item in branch.items) {
    final code = item.itemCode.toLowerCase();
    if (code.isNotEmpty && text.contains(code)) return item;
  }
  for (final item in branch.items) {
    final name = item.itemName.trim().toLowerCase();
    if (name.length >= 3 && text.contains(name)) return item;
  }
  return null;
}
