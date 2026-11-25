import '../../data/models/studio_enums.dart';
import '../../data/models/studio_models.dart';

/// Why a chosen ad state goes against the rules for this ad. Never blocks:
/// the dialog says so and asks for a second tap.
sealed class AdRuleWarning {
  const AdRuleWarning();
}

/// Winner or Scaling chosen with fewer purchases than the rule asks.
class WinnerNeedsPurchases extends AdRuleWarning {
  const WinnerNeedsPurchases({required this.have, required this.need});
  final int have;
  final int need;
}

/// Winner or Scaling chosen while the cost per purchase is above the line.
class CostAboveLine extends AdRuleWarning {
  const CostAboveLine({required this.cpa, required this.line});
  final int cpa;
  final int line;
}

/// The purchases the rule asks for before Winner, read from the server's hint
/// line ("... Rule says set Winner when 7 purchases are reached."). Null when
/// the hint does not carry it.
int? winnerPurchasesFromHint(AdHint? hint) {
  final text = hint?.text;
  if (text == null) return null;
  final m = RegExp(
    r'winner\s+(?:when|at|after)\s+(\d+)\s+purchases',
    caseSensitive: false,
  ).firstMatch(text);
  return m == null ? null : int.tryParse(m.group(1)!);
}

/// Compares the state a person picked with what the rules say for [ad]
/// (`again_max_cpp` is the cost-per-purchase line from the rule table, when
/// known). Null when the pick agrees with the rules or the rules are not known.
AdRuleWarning? adStateRuleWarning(
  PaidAd ad,
  AdState? picked, {
  double? maxCostPerPurchase,
}) {
  if (picked != AdState.winner && picked != AdState.inScale) return null;
  final n = ad.numbers;
  if (n == null) return null;
  final need = winnerPurchasesFromHint(ad.hint);
  if (need != null && n.purchases < need) {
    return WinnerNeedsPurchases(have: n.purchases, need: need);
  }
  final cpa = n.cpa;
  if (maxCostPerPurchase != null && cpa != null && cpa > maxCostPerPurchase) {
    return CostAboveLine(cpa: cpa, line: maxCostPerPurchase.round());
  }
  return null;
}
