import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/models/business_reports.dart';
import '../../state/reports_providers.dart';
import '../widgets/kpi_card.dart';
import '../widgets/report_export_button.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/report_section_card.dart';

/// Unit economics (`business_reports.get_unit_economics`): revenue → variable
/// costs → contribution → fixed costs → net profit, break-even, and the
/// per-order picture. Company-wide (no branch filter).
///
/// Four figures are not booked in the ledger and are entered by the owner in
/// the "Owner inputs" sheet: ad spend, extra fixed costs, and the Kashier and
/// Talabat rates the fee/commission estimates use. They are persisted with
/// shared_preferences and written to [unitEconomicsInputsProvider], which is
/// part of the provider key, so saving re-runs the report.
class UnitEconomicsScreen extends ConsumerStatefulWidget {
  const UnitEconomicsScreen({super.key});

  @override
  ConsumerState<UnitEconomicsScreen> createState() =>
      _UnitEconomicsScreenState();
}

class _UnitEconomicsScreenState extends ConsumerState<UnitEconomicsScreen> {
  /// The saved inputs are read once per app run; after that the provider
  /// (not auto-disposed) already holds them.
  static bool _loadedThisRun = false;

  bool _ready = _loadedThisRun;

  @override
  void initState() {
    super.initState();
    if (!_ready) _loadSavedInputs();
  }

  Future<void> _loadSavedInputs() async {
    UnitEconomicsInputs? saved;
    try {
      saved = await _InputsStore.load();
    } catch (e) {
      debugPrint('[UnitEconomics] loading saved inputs failed: $e');
    }
    if (!mounted) return;
    if (saved != null) {
      ref.read(unitEconomicsInputsProvider.notifier).state = saved;
    }
    _loadedThisRun = true;
    setState(() => _ready = true);
  }

  Future<void> _editInputs() async {
    final current = ref.read(unitEconomicsInputsProvider);
    final result = await showModalBottomSheet<UnitEconomicsInputs>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _InputsSheet(initial: current),
    );
    if (result == null || !mounted || result == current) return;
    ref.read(unitEconomicsInputsProvider.notifier).state = result;
    try {
      await _InputsStore.save(result);
    } catch (e) {
      debugPrint('[UnitEconomics] saving inputs failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = l10n.rptUnitEconomicsTitle;

    if (!_ready) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Column(
          children: [
            ReportFilterBar(showBranch: false),
            Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    final q = ref.watch(unitEconomicsQueryProvider);
    final async = ref.watch(unitEconomicsProvider(q));
    final data = async.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.rptUnitEconEditInputs,
            onPressed: _editInputs,
          ),
          ReportExportButton(
            title: title,
            rows: () => _csvRows(context, async.valueOrNull, q.inputs),
          ),
        ],
      ),
      body: Column(
        children: [
          const ReportFilterBar(showBranch: false),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  _settle(ref.refresh(unitEconomicsProvider(q).future)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  final inputsCard = _InputsCard(
                    inputs: q.inputs,
                    applied: data?.fixedCosts,
                    onEdit: _editInputs,
                  );
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 24),
                    children: [
                      inputsCard,
                      ...async.when(
                        skipLoadingOnRefresh: true,
                        loading: () => const [
                          Padding(
                            padding: EdgeInsetsDirectional.all(48),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ],
                        error: (e, _) => [
                          _InlineError(
                            error: e,
                            onRetry: () =>
                                ref.invalidate(unitEconomicsProvider(q)),
                          ),
                        ],
                        data: (d) => _sections(context, d, wide),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sections(BuildContext context, UnitEconomics d, bool wide) {
    final waterfall = _WaterfallCard(data: d);
    final breakEven = _BreakEvenCard(data: d);
    final perOrder = _PerOrderCard(data: d);
    return [
      _Legend(),
      Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
        child: _KpiGrid(data: d),
      ),
      if (d.notes.isNotEmpty) _NotesCard(notes: d.notes),
      if (wide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: waterfall),
            Expanded(
              flex: 2,
              child: Column(children: [breakEven, perOrder]),
            ),
          ],
        )
      else ...[
        waterfall,
        breakEven,
        perOrder,
      ],
      if (d.basis.isNotEmpty) _BasisCard(data: d),
    ];
  }
}

// ── Persistence ───────────────────────────────────────────────────────────

class _InputsStore {
  static const _kAdSpend = 'reports.unit_economics.ad_spend';
  static const _kKashierPct = 'reports.unit_economics.kashier_pct';
  static const _kTalabatPct = 'reports.unit_economics.talabat_pct';
  static const _kExtraFixed = 'reports.unit_economics.extra_fixed';

  static Future<UnitEconomicsInputs> load() async {
    final prefs = await SharedPreferences.getInstance();
    const d = UnitEconomicsInputs();
    // A non-finite saved value (stored before input validation rejected it)
    // would throw on every open; treat it as missing.
    double read(String key, double fallback) {
      final v = prefs.getDouble(key);
      return (v == null || !v.isFinite) ? fallback : v;
    }

    return UnitEconomicsInputs(
      adSpend: read(_kAdSpend, d.adSpend),
      kashierPct: read(_kKashierPct, d.kashierPct),
      talabatPct: read(_kTalabatPct, d.talabatPct),
      extraFixed: read(_kExtraFixed, d.extraFixed),
    );
  }

  static Future<void> save(UnitEconomicsInputs i) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kAdSpend, i.adSpend);
    await prefs.setDouble(_kKashierPct, i.kashierPct);
    await prefs.setDouble(_kTalabatPct, i.talabatPct);
    await prefs.setDouble(_kExtraFixed, i.extraFixed);
  }
}

// ── Formatting helpers ────────────────────────────────────────────────────

/// Awaits a reload for the pull-to-refresh spinner; a failure is rendered by
/// the body, so it is not rethrown into the indicator.
Future<void> _settle(Future<Object?> reload) async {
  try {
    await reload;
  } catch (_) {}
}

String _pct(BuildContext context, double v, {int digits = 1}) =>
    NumberFormat.decimalPercentPattern(
      locale: context.l10n.localeName,
      decimalDigits: digits,
    ).format(v / 100);

String _csvNum(double v) => v.toStringAsFixed(2);

/// Plain editable text for a number: no grouping, no trailing `.0`.
String _plain(double v) {
  if (!v.isFinite) return '0';
  return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
}

/// Parses user input, accepting Arabic-Indic / Persian digits, the Arabic
/// decimal separator and thousands separators. Empty → 0; invalid → null.
double? _parseInput(String raw) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  var s = raw.trim();
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
  }
  s = s
      .replaceAll('٫', '.')
      .replaceAll('٬', '')
      .replaceAll(',', '')
      .replaceAll(' ', '');
  if (s.isEmpty) return 0;
  final n = double.tryParse(s);
  // "Infinity", "NaN" and "1e400" parse; none is a usable amount.
  return (n == null || !n.isFinite) ? null : n;
}

String _noteText(BuildContext context, String code) {
  final l10n = context.l10n;
  return switch (code.trim()) {
    'ad_spend_is_owner_input' => l10n.rptUnitEconNoteAdSpendIsOwnerInput,
    'ad_spend_not_entered' => l10n.rptUnitEconNoteAdSpendNotEntered,
    'extra_fixed_is_owner_input' => l10n.rptUnitEconNoteExtraFixedIsOwnerInput,
    'kashier_fees_estimated' => l10n.rptUnitEconNoteKashierFeesEstimated,
    'talabat_commission_estimated' =>
      l10n.rptUnitEconNoteTalabatCommissionEstimated,
    'booked_partner_commission_replaced_by_estimate' =>
      l10n.rptUnitEconNoteBookedPartnerCommissionReplaced,
    'booked_kashier_fees_replaced_by_estimate' =>
      l10n.rptUnitEconNoteBookedKashierFeesReplaced,
    'stock_adjustment_in_other' => l10n.rptUnitEconNoteStockAdjustmentInOther,
    'cogs_incomplete' => l10n.rptUnitEconNoteCogsIncomplete,
    'shipping_expense_incomplete' =>
      l10n.rptUnitEconNoteShippingExpenseIncomplete,
    'recurring_not_fully_posted' =>
      l10n.rptUnitEconNoteRecurringNotFullyPosted,
    'ads_also_booked_in_ledger' => l10n.rptUnitEconNoteAdsAlsoBooked,
    'contribution_not_positive' =>
      l10n.rptUnitEconNoteContributionNotPositive,
    // Unknown code: show it readable rather than hide it.
    final other => other.replaceAll('_', ' '),
  };
}

/// Notes that point at a data problem (vs. a plain "this is an estimate").
bool _isWarningNote(String code) => const {
      'ad_spend_not_entered',
      'cogs_incomplete',
      'shipping_expense_incomplete',
      'recurring_not_fully_posted',
      'ads_also_booked_in_ledger',
      'contribution_not_positive',
    }.contains(code.trim());

List<List<String>> _csvRows(
  BuildContext context,
  UnitEconomics? d,
  UnitEconomicsInputs inputs,
) {
  final l10n = context.l10n;
  if (d == null) return const [];
  final rows = <List<String>>[
    [l10n.rptUnitEconMetric, l10n.rptUnitEconValue],
    [l10n.rptUnitEconRevenue, _csvNum(d.revenue)],
    [l10n.reportKpiOrders, '${d.orders}'],
    [l10n.reportKpiAov, _csvNum(d.avgOrderValue)],
    [l10n.rptUnitEconCogs, _csvNum(d.variableCosts.cogs)],
    [l10n.rptUnitEconShippingNet, _csvNum(d.variableCosts.shippingNet)],
    [
      '${l10n.rptUnitEconKashierFees} (${l10n.rptUnitEconBadgeEstimate})',
      _csvNum(d.variableCosts.kashierFees),
    ],
    [
      '${l10n.rptUnitEconTalabatCommission} (${l10n.rptUnitEconBadgeEstimate})',
      _csvNum(d.variableCosts.talabatCommission),
    ],
    [l10n.rptUnitEconVariableTotal, _csvNum(d.variableCosts.total)],
    [l10n.rptUnitEconContribution, _csvNum(d.contribution)],
    [l10n.rptUnitEconContributionMargin, d.contributionMarginPct.toStringAsFixed(2)],
    [l10n.rptUnitEconRecurring, _csvNum(d.fixedCosts.recurring)],
    [l10n.rptUnitEconOtherExpenses, _csvNum(d.fixedCosts.other)],
    [
      '${l10n.rptUnitEconAdSpend} (${l10n.rptUnitEconBadgeOwnerInput})',
      _csvNum(d.fixedCosts.adSpend),
    ],
    [
      '${l10n.rptUnitEconExtraFixed} (${l10n.rptUnitEconBadgeOwnerInput})',
      _csvNum(d.fixedCosts.extraFixed),
    ],
    [l10n.rptUnitEconFixedTotal, _csvNum(d.fixedCosts.total)],
    [l10n.rptUnitEconNetProfit, _csvNum(d.netProfit)],
    [
      l10n.rptUnitEconBreakEvenRevenue,
      d.breakEvenRevenue == null ? '' : _csvNum(d.breakEvenRevenue!),
    ],
    [l10n.rptUnitEconBreakEvenOrders, d.breakEvenOrders?.toString() ?? ''],
    [
      l10n.rptUnitEconGap,
      d.gapToBreakEven == null ? '' : _csvNum(d.gapToBreakEven!),
    ],
    [
      '${l10n.rptUnitEconPerOrderTitle}: ${l10n.rptUnitEconRevenue}',
      _csvNum(d.perOrder.revenue),
    ],
    [
      '${l10n.rptUnitEconPerOrderTitle}: ${l10n.rptUnitEconCogs}',
      _csvNum(d.perOrder.cogs),
    ],
    [
      '${l10n.rptUnitEconPerOrderTitle}: ${l10n.rptUnitEconShipping}',
      _csvNum(d.perOrder.shipping),
    ],
    [
      '${l10n.rptUnitEconPerOrderTitle}: ${l10n.rptUnitEconFees}',
      _csvNum(d.perOrder.fees),
    ],
    [
      '${l10n.rptUnitEconPerOrderTitle}: ${l10n.rptUnitEconContribution}',
      _csvNum(d.perOrder.contribution),
    ],
    [
      '${l10n.rptUnitEconInputsTitle}: ${l10n.rptUnitEconAdSpend}',
      _csvNum(inputs.adSpend),
    ],
    [
      '${l10n.rptUnitEconInputsTitle}: ${l10n.rptUnitEconKashierPct}',
      _plain(inputs.kashierPct),
    ],
    [
      '${l10n.rptUnitEconInputsTitle}: ${l10n.rptUnitEconTalabatPct}',
      _plain(inputs.talabatPct),
    ],
    [
      '${l10n.rptUnitEconInputsTitle}: ${l10n.rptUnitEconExtraFixed}',
      _csvNum(inputs.extraFixed),
    ],
    for (final n in d.notes)
      [l10n.rptUnitEconNotesTitle, _noteText(context, n)],
  ];
  return rows;
}

// ── Small shared widgets ──────────────────────────────────────────────────

enum _BadgeKind { estimate, ownerInput }

class _Badge extends StatelessWidget {
  final _BadgeKind kind;
  const _Badge(this.kind);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (text, color) = switch (kind) {
      _BadgeKind.estimate => (
          l10n.rptUnitEconBadgeEstimate,
          Colors.orange.shade800,
        ),
      _BadgeKind.ownerInput => (
          l10n.rptUnitEconBadgeOwnerInput,
          theme.colorScheme.tertiary,
        ),
    };
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  const _InlineError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            l10n.reportError,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            context.userErrorMessage(error),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.reportsRetry),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const _Badge(_BadgeKind.estimate),
          const _Badge(_BadgeKind.ownerInput),
          Text(
            context.l10n.rptUnitEconLegend,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Owner inputs ──────────────────────────────────────────────────────────

class _InputsCard extends StatelessWidget {
  final UnitEconomicsInputs inputs;

  /// What the server applied (to spot a difference with the input).
  final UnitEconomicsFixedCosts? applied;
  final VoidCallback onEdit;

  const _InputsCard({
    required this.inputs,
    required this.applied,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    Widget row(String label, String value, {String? hint}) => Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    if (hint != null)
                      Text(
                        hint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );

    String? appliedHint(double input, double? server) {
      if (server == null || (server - input).abs() < 0.005) return null;
      return l10n.rptUnitEconAppliedAmount(formatCurrency(context, server));
    }

    return ReportSectionCard(
      title: l10n.rptUnitEconInputsTitle,
      subtitle: l10n.rptUnitEconInputsSubtitle,
      trailing: TextButton.icon(
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(l10n.rptUnitEconEditInputs),
      ),
      child: Column(
        children: [
          row(
            l10n.rptUnitEconAdSpend,
            formatCurrency(context, inputs.adSpend),
            hint: appliedHint(inputs.adSpend, applied?.adSpend),
          ),
          row(
            l10n.rptUnitEconExtraFixed,
            formatCurrency(context, inputs.extraFixed),
            hint: appliedHint(inputs.extraFixed, applied?.extraFixed),
          ),
          row(l10n.rptUnitEconKashierPct, _pct(context, inputs.kashierPct)),
          row(l10n.rptUnitEconTalabatPct, _pct(context, inputs.talabatPct)),
        ],
      ),
    );
  }
}

class _InputsSheet extends StatefulWidget {
  final UnitEconomicsInputs initial;
  const _InputsSheet({required this.initial});

  @override
  State<_InputsSheet> createState() => _InputsSheetState();
}

class _InputsSheetState extends State<_InputsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ad;
  late final TextEditingController _kashier;
  late final TextEditingController _talabat;
  late final TextEditingController _extra;

  @override
  void initState() {
    super.initState();
    _ad = TextEditingController(text: _plain(widget.initial.adSpend));
    _kashier = TextEditingController(text: _plain(widget.initial.kashierPct));
    _talabat = TextEditingController(text: _plain(widget.initial.talabatPct));
    _extra = TextEditingController(text: _plain(widget.initial.extraFixed));
  }

  @override
  void dispose() {
    _ad.dispose();
    _kashier.dispose();
    _talabat.dispose();
    _extra.dispose();
    super.dispose();
  }

  void _resetDefaults() {
    const d = UnitEconomicsInputs();
    setState(() {
      _ad.text = _plain(d.adSpend);
      _kashier.text = _plain(d.kashierPct);
      _talabat.text = _plain(d.talabatPct);
      _extra.text = _plain(d.extraFixed);
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      UnitEconomicsInputs(
        adSpend: _parseInput(_ad.text) ?? 0,
        kashierPct: _parseInput(_kashier.text) ?? 0,
        talabatPct: _parseInput(_talabat.text) ?? 0,
        extraFixed: _parseInput(_extra.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    String? amountValidator(String? v) {
      final n = _parseInput(v ?? '');
      if (n == null || n < 0) return l10n.rptUnitEconInvalidNumber;
      return null;
    }

    String? pctValidator(String? v) {
      final n = _parseInput(v ?? '');
      if (n == null || n < 0 || n > 100) return l10n.rptUnitEconInvalidPct;
      return null;
    }

    Widget field(
      TextEditingController c,
      String label,
      String help,
      String? Function(String?) validator, {
      String? prefix,
      String? suffix,
    }) =>
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 12),
          child: TextFormField(
            controller: c,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: label,
              helperText: help,
              helperMaxLines: 2,
              prefixText: prefix,
              suffixText: suffix,
              border: const OutlineInputBorder(),
            ),
            validator: validator,
          ),
        );

    final symbol = '${currencySymbol(context)} ';
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: 16,
        end: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.rptUnitEconInputsTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.rptUnitEconInputsSubtitle,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                field(
                  _ad,
                  l10n.rptUnitEconAdSpend,
                  l10n.rptUnitEconAdSpendHelp,
                  amountValidator,
                  prefix: symbol,
                ),
                field(
                  _extra,
                  l10n.rptUnitEconExtraFixed,
                  l10n.rptUnitEconExtraFixedHelp,
                  amountValidator,
                  prefix: symbol,
                ),
                field(
                  _kashier,
                  l10n.rptUnitEconKashierPct,
                  l10n.rptUnitEconKashierPctHelp,
                  pctValidator,
                  suffix: '%',
                ),
                field(
                  _talabat,
                  l10n.rptUnitEconTalabatPct,
                  l10n.rptUnitEconTalabatPctHelp,
                  pctValidator,
                  suffix: '%',
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _resetDefaults,
                      child: Text(l10n.rptUnitEconResetDefaults),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.commonCancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _save,
                      child: Text(l10n.commonSave),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── KPIs ──────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final UnitEconomics data;
  const _KpiGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profitColor =
        data.netProfit < 0 ? theme.colorScheme.error : Colors.green.shade700;

    final tiles = [
      KpiCard(
        label: l10n.rptUnitEconRevenue,
        value: formatCurrency(context, data.revenue),
        icon: Icons.payments_outlined,
      ),
      KpiCard(
        label: l10n.reportKpiOrders,
        value: formatCount(context, data.orders),
        icon: Icons.receipt_long_outlined,
        color: theme.colorScheme.tertiary,
      ),
      KpiCard(
        label: l10n.reportKpiAov,
        value: formatCurrency(context, data.avgOrderValue),
        icon: Icons.shopping_cart_outlined,
        color: theme.colorScheme.secondary,
      ),
      KpiCard(
        label: l10n.rptUnitEconContributionMargin,
        value: _pct(context, data.contributionMarginPct),
        icon: Icons.percent,
        color: data.contributionMarginPct <= 0
            ? theme.colorScheme.error
            : Colors.teal.shade700,
        delta: l10n.rptUnitEconBadgeEstimate,
        deltaColor: Colors.orange.shade800,
      ),
      KpiCard(
        label: l10n.rptUnitEconNetProfit,
        value: formatCurrency(context, data.netProfit),
        icon: data.netProfit < 0 ? Icons.trending_down : Icons.trending_up,
        color: profitColor,
        delta: l10n.rptUnitEconBadgeEstimate,
        deltaColor: Colors.orange.shade800,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 1100 ? 5 : (w >= 600 ? 3 : 2);
        const spacing = 8.0;
        final cardWidth = (w - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final t in tiles) SizedBox(width: cardWidth, child: t),
          ],
        );
      },
    );
  }
}

// ── Notes ─────────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  final List<String> notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ReportSectionCard(
      title: context.l10n.rptUnitEconNotesTitle,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final n in notes)
            Builder(
              builder: (context) {
                final warn = _isWarningNote(n);
                final color = warn
                    ? Colors.orange.shade800
                    : theme.colorScheme.primary;
                return Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        warn ? Icons.warning_amber_rounded : Icons.info_outline,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _noteText(context, n),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Waterfall ─────────────────────────────────────────────────────────────

enum _StepKind { total, cost }

class _Step {
  final String label;
  final double from;
  final double to;
  final _StepKind kind;
  final _BadgeKind? badge;

  const _Step(this.label, this.from, this.to, this.kind, {this.badge});

  /// Signed change shown next to the label.
  double get amount => kind == _StepKind.total ? to : to - from;
}

class _WaterfallCard extends StatelessWidget {
  final UnitEconomics data;
  const _WaterfallCard({required this.data});

  List<_Step> _steps(BuildContext context) {
    final l10n = context.l10n;
    final v = data.variableCosts;
    final f = data.fixedCosts;
    final steps = <_Step>[];
    var running = data.revenue;
    steps.add(_Step(l10n.rptUnitEconRevenue, 0, running, _StepKind.total));
    void cost(String label, double c, {_BadgeKind? badge}) {
      steps.add(_Step(label, running, running - c, _StepKind.cost, badge: badge));
      running -= c;
    }

    cost(l10n.rptUnitEconCogs, v.cogs);
    cost(l10n.rptUnitEconShippingNet, v.shippingNet);
    cost(l10n.rptUnitEconKashierFees, v.kashierFees, badge: _BadgeKind.estimate);
    cost(
      l10n.rptUnitEconTalabatCommission,
      v.talabatCommission,
      badge: _BadgeKind.estimate,
    );
    // Subtotals use the server's figure (it is authoritative on rounding).
    running = data.contribution;
    steps.add(_Step(l10n.rptUnitEconContribution, 0, running, _StepKind.total));
    cost(l10n.rptUnitEconRecurring, f.recurring);
    cost(l10n.rptUnitEconOtherExpenses, f.other);
    cost(l10n.rptUnitEconAdSpend, f.adSpend, badge: _BadgeKind.ownerInput);
    cost(l10n.rptUnitEconExtraFixed, f.extraFixed, badge: _BadgeKind.ownerInput);
    running = data.netProfit;
    steps.add(_Step(l10n.rptUnitEconNetProfit, 0, running, _StepKind.total));
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _steps(context);
    var lo = 0.0;
    var hi = 0.0;
    for (final s in steps) {
      for (final p in [s.from, s.to]) {
        if (p < lo) lo = p;
        if (p > hi) hi = p;
      }
    }
    if (hi - lo <= 0) hi = lo + 1;

    final dir = Directionality.of(context);
    final green = Colors.green.shade600;
    final red = theme.colorScheme.error;

    return ReportSectionCard(
      title: context.l10n.rptUnitEconWaterfallTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final s in steps)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          s.label,
                          overflow: TextOverflow.ellipsis,
                          style: s.kind == _StepKind.total
                              ? theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)
                              : theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (s.badge != null) ...[
                        const SizedBox(width: 6),
                        _Badge(s.badge!),
                      ],
                      const Spacer(),
                      Text(
                        formatCurrency(context, s.amount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: s.kind == _StepKind.total
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: s.kind == _StepKind.total
                              ? (s.amount < 0 ? red : null)
                              : (s.amount > 0 ? green : null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 10,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final w = c.maxWidth;
                        double x(double v) => (v - lo) / (hi - lo) * w;
                        final a = s.from < s.to ? s.from : s.to;
                        final b = s.from < s.to ? s.to : s.from;
                        final start = x(a);
                        final width = (x(b) - start).clamp(2.0, w);
                        final Color color;
                        if (s.kind == _StepKind.total) {
                          color = s.to < 0 ? red : theme.colorScheme.primary;
                        } else {
                          color = s.to > s.from
                              ? green
                              : red.withValues(alpha: 0.75);
                        }
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            if (lo < 0)
                              Positioned.directional(
                                textDirection: dir,
                                start: x(0),
                                top: 0,
                                bottom: 0,
                                width: 1,
                                child: Container(color: theme.colorScheme.outline),
                              ),
                            Positioned.directional(
                              textDirection: dir,
                              start: start.clamp(0.0, w),
                              top: 0,
                              bottom: 0,
                              width: width,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Break-even ────────────────────────────────────────────────────────────

class _BreakEvenCard extends StatelessWidget {
  final UnitEconomics data;
  const _BreakEvenCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final be = data.breakEvenRevenue;

    if (be == null || be <= 0) {
      return ReportSectionCard(
        title: l10n.rptUnitEconBreakEvenTitle,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.rptUnitEconNoBreakEven,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    final progress = (data.revenue / be).clamp(0.0, 1.0);
    final gap = data.gapToBreakEven ?? (be - data.revenue);
    final past = gap <= 0;
    final barColor = past ? Colors.green.shade600 : Colors.orange.shade700;

    Widget line(String label, String value, {Color? color}) => Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        );

    return ReportSectionCard(
      title: l10n.rptUnitEconBreakEvenTitle,
      trailing: const _Badge(_BadgeKind.estimate),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(l10n.rptUnitEconBreakEvenRevenue, formatCurrency(context, be)),
          if (data.breakEvenOrders != null)
            line(
              l10n.rptUnitEconBreakEvenOrders,
              formatCount(context, data.breakEvenOrders!),
            ),
          past
              ? line(
                  l10n.rptUnitEconGap,
                  l10n.rptUnitEconPastBreakEven(formatCurrency(context, -gap)),
                  color: Colors.green.shade700,
                )
              : line(
                  l10n.rptUnitEconGap,
                  formatCurrency(context, gap),
                  color: Colors.orange.shade800,
                ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              color: barColor,
              backgroundColor: barColor.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.rptUnitEconProgress(_pct(context, progress * 100, digits: 0)),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Per order ─────────────────────────────────────────────────────────────

class _PerOrderCard extends StatelessWidget {
  final UnitEconomics data;
  const _PerOrderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final p = data.perOrder;

    final segments = [
      (l10n.rptUnitEconCogs, p.cogs, Colors.brown.shade400),
      (l10n.rptUnitEconShipping, p.shipping, Colors.blueGrey.shade400),
      (l10n.rptUnitEconFees, p.fees, Colors.orange.shade600),
      (l10n.rptUnitEconContribution, p.contribution, Colors.green.shade600),
    ];
    final canStack =
        p.revenue > 0 && segments.every((s) => s.$2 >= 0);

    Widget line(String label, double v, {bool bold = false, _BadgeKind? badge}) =>
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: bold
                      ? theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold)
                      : theme.textTheme.bodyMedium,
                ),
              ),
              if (badge != null) ...[const SizedBox(width: 6), _Badge(badge)],
              const Spacer(),
              Text(
                formatCurrency(context, v),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: bold && v < 0 ? theme.colorScheme.error : null,
                ),
              ),
            ],
          ),
        );

    return ReportSectionCard(
      title: l10n.rptUnitEconPerOrderTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canStack) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 16,
                child: Row(
                  children: [
                    for (final s in segments)
                      if (s.$2 > 0)
                        Expanded(
                          flex: (s.$2 / p.revenue * 1000).round().clamp(1, 1000),
                          child: Container(color: s.$3),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final s in segments)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.$3,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(s.$1, style: theme.textTheme.labelSmall),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          line(l10n.rptUnitEconRevenue, p.revenue, bold: true),
          line(l10n.rptUnitEconCogs, p.cogs),
          line(l10n.rptUnitEconShipping, p.shipping),
          line(l10n.rptUnitEconFees, p.fees, badge: _BadgeKind.estimate),
          const Divider(height: 12),
          line(l10n.rptUnitEconContribution, p.contribution, bold: true),
        ],
      ),
    );
  }
}

// ── Calculation basis ─────────────────────────────────────────────────────

class _BasisCard extends StatelessWidget {
  final UnitEconomics data;
  const _BasisCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    // (key, label, kind) — kind: m = money, c = count, p = percent.
    final spec = <(String, String, String)>[
      ('kashier_receipts', l10n.rptUnitEconBasisKashierReceipts, 'm'),
      ('talabat_sales', l10n.rptUnitEconBasisTalabatSales, 'm'),
      ('talabat_orders', l10n.rptUnitEconBasisTalabatOrders, 'c'),
      ('shipping_income', l10n.rptUnitEconBasisShippingIncome, 'm'),
      ('shipping_expense', l10n.rptUnitEconBasisShippingExpense, 'm'),
      ('stock_adjustment', l10n.rptUnitEconBasisStockAdjustment, 'm'),
      (
        'booked_partner_commission',
        l10n.rptUnitEconBasisBookedPartnerCommission,
        'm',
      ),
      ('booked_kashier_fees', l10n.rptUnitEconBasisBookedKashierFees, 'm'),
      ('recurring_due', l10n.rptUnitEconBasisRecurringDue, 'm'),
      ('cogs_coverage_pct', l10n.rptUnitEconBasisCogsCoverage, 'p'),
      ('ledger_net_profit', l10n.rptUnitEconBasisLedgerNetProfit, 'm'),
    ];

    final rows = <Widget>[];
    for (final (key, label, kind) in spec) {
      final v = data.basisValue(key);
      if (v == null) continue;
      final text = switch (kind) {
        'c' => formatCount(context, v),
        'p' => _pct(context, v),
        _ => formatCurrency(context, v),
      };
      rows.add(
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              Text(
                text,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          l10n.rptUnitEconBasisTitle,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          l10n.rptUnitEconBasisSubtitle,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        childrenPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
        children: rows,
      ),
    );
  }
}
