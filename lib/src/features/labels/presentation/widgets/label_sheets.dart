import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_display_mappers.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../data/labels_repository.dart';
import '../../models/label_models.dart';
import 'label_payment_choice.dart';

/// What [PrintOrderSheet] collects. Ordering happens in SHEETS — the print
/// house sells sheets, not labels.
class PrintOrderRequest {
  final int qtySheets;
  final String? supplier;
  final double? totalCost;
  final String? notes;

  const PrintOrderRequest({
    required this.qtySheets,
    required this.supplier,
    required this.totalCost,
    required this.notes,
  });
}

/// What [RecordBillSheet] collects — the printer's bill for one batch.
class BillRequest {
  final String supplier;
  final double totalCost;
  final String? billNo;

  /// False books the bill as owed to the printer (a payable).
  final bool isPaid;

  /// Where the money came from when [isPaid]: a POS Profile name, `instapay`,
  /// `cash` or `custody:<holder>`. Null when owed.
  final String? paymentOption;

  const BillRequest({
    required this.supplier,
    required this.totalCost,
    required this.billNo,
    this.isPaid = false,
    this.paymentOption,
  });
}

/// What [BoughtBatchSheet] collects: a batch that was already bought AND
/// delivered, recorded in one step (print order + receipt + bill).
class BoughtBatchRequest {
  final int qtySheets;

  /// Labels that actually arrived. Null lets the server default it to what the
  /// sheets hold.
  final int? receivedQty;
  final String supplier;

  /// NET of VAT.
  final double totalCost;
  final String? billNo;

  /// The one "bought / received on" date, sent as both `received_on` and
  /// `bill_date`.
  final DateTime boughtOn;
  final bool isPaid;
  final String? paymentOption;
  final String? notes;

  /// Generated once per sheet, so a retry after a timeout replays the first
  /// attempt server-side instead of buying the batch twice.
  final String clientRequestId;

  const BoughtBatchRequest({
    required this.qtySheets,
    required this.receivedQty,
    required this.supplier,
    required this.totalCost,
    required this.billNo,
    required this.boughtOn,
    required this.isPaid,
    required this.paymentOption,
    required this.notes,
    required this.clientRequestId,
  });
}

/// A fresh idempotency key for one bought-batch submission. Same shape as the
/// Purchase screen's `_newIdempotencyKey`.
String newBoughtBatchRequestId() =>
    'lbl-bought-${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(DateTime.now())}';

/// What [CountSheet] collects.
///
/// Deliberately its own type rather than a reuse of [MovementRequest]: a count
/// is an absolute number that the server turns into a delta, not a movement, and
/// a shared type invites somebody to post it down the movement endpoint.
class CountRequest {
  final int countedQty;
  final String? remarks;

  const CountRequest({required this.countedQty, required this.remarks});
}

/// What [MovementSheet] collects.
class MovementRequest {
  final String movementType;
  final int qty;
  final String? remarks;

  const MovementRequest({
    required this.movementType,
    required this.qty,
    required this.remarks,
  });
}

/// What [LabelPolicySheet] collects.
class LabelPolicyRequest {
  final String labelTitle;
  final bool enabled;

  /// Empty string clears the home location server-side.
  final String storageLocation;
  final double labelsPerUnit;

  /// Zero means "use the size default" (21 Small / 21 Medium / 18 Large).
  final int labelsPerSheet;
  final int defaultPrintSheets;
  final int minStockQty;
  final String notes;

  const LabelPolicyRequest({
    required this.labelTitle,
    required this.enabled,
    required this.storageLocation,
    required this.labelsPerUnit,
    required this.labelsPerSheet,
    required this.defaultPrintSheets,
    required this.minStockQty,
    required this.notes,
  });
}

// ---------------------------------------------------------------------------
// Shared chrome
// ---------------------------------------------------------------------------
class _SheetScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> fields;
  final Widget action;

  const _SheetScaffold({
    required this.title,
    this.subtitle,
    required this.fields,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(title, style: theme.textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 16),
            ...fields,
            const SizedBox(height: 20),
            action,
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String label, {String? helper, String? suffix}) {
  return InputDecoration(
    labelText: label,
    helperText: helper,
    helperMaxLines: 3,
    suffixText: suffix,
    border: const OutlineInputBorder(),
    isDense: true,
  );
}

final _digits = [FilteringTextInputFormatter.digitsOnly];

int _parseInt(TextEditingController controller, {int fallback = 0}) {
  return int.tryParse(controller.text.trim()) ?? fallback;
}

double? _parseCost(TextEditingController controller) {
  final value = double.tryParse(controller.text.trim());
  return (value == null || value <= 0) ? null : value;
}

// ---------------------------------------------------------------------------
// Print supplier picker
// ---------------------------------------------------------------------------
/// Searchable supplier field backed by `get_print_suppliers`. Selecting a
/// result locks it in; typing again clears the selection and searches anew.
class SupplierField extends ConsumerStatefulWidget {
  final String? initialSupplier;
  final ValueChanged<LabelSupplierOption?> onChanged;

  /// Defaults to the localized "Print supplier (optional)" when omitted.
  final String? label;

  const SupplierField({
    super.key,
    required this.onChanged,
    this.initialSupplier,
    this.label,
  });

  @override
  ConsumerState<SupplierField> createState() => _SupplierFieldState();
}

class _SupplierFieldState extends ConsumerState<SupplierField> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<LabelSupplierOption> _results = const [];
  LabelSupplierOption? _selected;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSupplier?.trim();
    if (initial != null && initial.isNotEmpty) {
      _selected = LabelSupplierOption(name: initial, supplierName: initial);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    try {
      final results =
          await ref.read(labelsRepositoryProvider).searchPrintSuppliers(query);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _select(LabelSupplierOption? option) {
    setState(() {
      _selected = option;
      _results = const [];
      _controller.clear();
    });
    widget.onChanged(option);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final fieldLabel =
        widget.label ?? context.l10n.labelSheetSupplierOptional;
    if (selected != null) {
      return InputDecorator(
        decoration: _fieldDecoration(fieldLabel),
        child: Row(
          children: [
            const Icon(Icons.factory_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selected.supplierName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: () => _select(null),
              child: const Icon(Icons.clear, size: 18),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          decoration: _fieldDecoration(fieldLabel).copyWith(
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: _onChanged,
        ),
        if (_results.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 170),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final option = _results[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.factory_outlined, size: 18),
                  title: Text(option.supplierName),
                  onTap: () => _select(option),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Physical count
// ---------------------------------------------------------------------------
class CountSheet extends StatefulWidget {
  final CustomerLabel label;

  const CountSheet({super.key, required this.label});

  @override
  State<CountSheet> createState() => _CountSheetState();
}

class _CountSheetState extends State<CountSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.label.onHandQty}');
  final _remarksController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final counted = int.tryParse(_controller.text.trim());
    final delta = counted == null ? null : counted - widget.label.onHandQty;

    return _SheetScaffold(
      title: l10n.labelSheetCountTitle,
      subtitle: l10n.labelSheetCountSubtitle,
      fields: [
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: _digits,
          decoration: _fieldDecoration(
            l10n.labelSheetCountedQty,
            helper: l10n.labelSheetSystemShows(widget.label.onHandQty),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (delta != null && delta != 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                delta > 0 ? Icons.trending_up : Icons.trending_down,
                size: 18,
                color: delta > 0
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFB3261E),
              ),
              const SizedBox(width: 6),
              Text(
                delta > 0
                    ? l10n.labelSheetDeltaMore(delta)
                    : l10n.labelSheetDeltaFewer(delta.abs()),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _remarksController,
          decoration: _fieldDecoration(l10n.labelSheetNoteOptional),
        ),
      ],
      action: FilledButton(
        onPressed: counted == null
            ? null
            : () => Navigator.of(context).pop(
                  CountRequest(
                    countedQty: counted,
                    remarks: _remarksController.text.trim().isEmpty
                        ? null
                        : _remarksController.text.trim(),
                  ),
                ),
        child: Text(l10n.labelSheetSaveCount),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Send a batch to the printer (in sheets)
// ---------------------------------------------------------------------------
class PrintOrderSheet extends ConsumerStatefulWidget {
  final CustomerLabel label;

  const PrintOrderSheet({super.key, required this.label});

  @override
  ConsumerState<PrintOrderSheet> createState() => _PrintOrderSheetState();
}

class _PrintOrderSheetState extends ConsumerState<PrintOrderSheet> {
  late final TextEditingController _sheetsController = TextEditingController(
    text:
        '${widget.label.suggestedPrintSheets > 0 ? widget.label.suggestedPrintSheets : widget.label.defaultPrintSheets}',
  );
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  LabelSupplierOption? _supplier;

  @override
  void dispose() {
    _sheetsController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final label = widget.label;
    final sheets = int.tryParse(_sheetsController.text.trim()) ?? 0;
    final labels = label.labelsForSheets(sheets);

    return _SheetScaffold(
      title: l10n.labelSheetOrderTitle,
      subtitle: '${label.customerName} · ${label.labelTitle}'
          '${label.size == null ? '' : ' · ${label.size}'}',
      fields: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_available, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label.expectedReadyIfOrderedToday == null
                      ? l10n.labelSheetLeadPlain(
                          label.leadDaysMin,
                          label.leadDaysMax,
                          label.restDay,
                        )
                      : l10n.labelSheetLeadReady(
                          _dmy(context, label.expectedReadyIfOrderedToday!),
                          label.leadDaysMin,
                          label.leadDaysMax,
                          label.restDay,
                        ),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _sheetsController,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: _digits,
          decoration: _fieldDecoration(
            l10n.labelSheetSheetsToPrint,
            helper: label.suggestedPrintSheets > 0
                ? l10n.labelSheetSuggestedSheets(label.suggestedPrintSheets)
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (sheets > 0 && labels > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.grid_on, size: 16),
              const SizedBox(width: 6),
              Text(
                l10n.labelSheetSheetsEquals(
                  l10n.labelCardSheetsCount(sheets),
                  l10n.labelCardLabelsCount(labels),
                ),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        SupplierField(
          initialSupplier: null,
          onChanged: (option) => setState(() => _supplier = option),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _costController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration(
            l10n.labelSheetNetCostOptional,
            helper: l10n.labelSheetNetCostQuoteHelper,
            suffix: currencySymbol(context),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: _fieldDecoration(l10n.labelSheetNotesOptional),
        ),
      ],
      action: FilledButton.icon(
        onPressed: sheets <= 0
            ? null
            : () => Navigator.of(context).pop(
                  PrintOrderRequest(
                    qtySheets: sheets,
                    supplier: _supplier?.name,
                    totalCost: _parseCost(_costController),
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                  ),
                ),
        icon: const Icon(Icons.local_printshop),
        label: Text(l10n.labelSheetSendToPrinter),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick order: record what was already ordered for one customer, all
// flavours and branches in one go
// ---------------------------------------------------------------------------
/// What [QuickOrderSheet] collects: sheets per label (one label = one flavour
/// at one branch), plus the details shared by every resulting print order.
class QuickOrderRequest {
  final Map<String, int> sheetsByLabel;
  final String? supplier;

  /// `yyyy-MM-dd`; null means today on the server.
  final String? requestedOn;
  final String? notes;

  const QuickOrderRequest({
    required this.sheetsByLabel,
    required this.supplier,
    required this.requestedOn,
    required this.notes,
  });

  int get totalSheets => sheetsByLabel.values.fold(0, (a, b) => a + b);
}

/// One customer, every flavour, a stepper each. The branch is picked for the
/// user when there is only one; with several, every branch starts selected and
/// a flavour's count goes to each selected branch that carries it.
class QuickOrderSheet extends StatefulWidget {
  final String customerName;
  final List<CustomerLabel> labels;

  const QuickOrderSheet({
    super.key,
    required this.customerName,
    required this.labels,
  });

  @override
  State<QuickOrderSheet> createState() => _QuickOrderSheetState();
}

class _QuickOrderSheetState extends State<QuickOrderSheet> {
  late final List<String?> _branches = {
    for (final label in widget.labels) label.storageLocation,
  }.toList();
  late final Set<String?> _selected = {..._branches};
  final Map<String, int> _counts = {};
  final _notesController = TextEditingController();
  LabelSupplierOption? _supplier;
  DateTime _orderedOn = DateTime.now();
  bool _showMore = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Flavours in board order, one entry per item across branches.
  List<_QuickFlavour> get _flavours {
    final byKey = <String, _QuickFlavour>{};
    for (final label in widget.labels) {
      final key = label.item ?? label.labelTitle;
      byKey.putIfAbsent(key, () => _QuickFlavour(key, label)).labels.add(label);
    }
    return byKey.values.toList();
  }

  List<CustomerLabel> _targets(_QuickFlavour flavour) => flavour.labels
      .where((label) => _selected.contains(label.storageLocation))
      .toList();

  Map<String, int> _sheetsByLabel() {
    final result = <String, int>{};
    for (final flavour in _flavours) {
      final count = _counts[flavour.key] ?? 0;
      if (count <= 0) continue;
      for (final label in _targets(flavour)) {
        result[label.name] = count;
      }
    }
    return result;
  }

  void _fillSuggested() {
    setState(() {
      for (final flavour in _flavours) {
        final targets = _targets(flavour);
        if (targets.isEmpty) continue;
        final suggested = targets
            .map((l) => l.suggestedPrintSheets > 0
                ? l.suggestedPrintSheets
                : l.defaultPrintSheets)
            .reduce((a, b) => a > b ? a : b);
        _counts[flavour.key] = suggested;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _orderedOn,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now,
    );
    if (picked != null) setState(() => _orderedOn = picked);
  }

  String _branchName(String? warehouse) =>
      warehouse == null ? '—' : labelLocationName(warehouse);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final sheetsByLabel = _sheetsByLabel();
    final total = sheetsByLabel.values.fold(0, (a, b) => a + b);
    final multiBranch = _branches.length > 1;

    return _SheetScaffold(
      title: l10n.labelQuickOrderTitle,
      subtitle: widget.customerName,
      fields: [
        // Where the labels go.
        Text(
          multiBranch
              ? l10n.labelQuickOrderBranches
              : l10n.labelQuickOrderBranch,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        if (!multiBranch)
          Row(
            children: [
              Icon(Icons.place, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                _branchName(_branches.first),
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final branch in _branches)
                FilterChip(
                  avatar: const Icon(Icons.place_outlined, size: 16),
                  label: Text(_branchName(branch)),
                  selected: _selected.contains(branch),
                  onSelected: (on) => setState(() {
                    if (on) {
                      _selected.add(branch);
                    } else if (_selected.length > 1) {
                      _selected.remove(branch);
                    }
                  }),
                ),
            ],
          ),
        const SizedBox(height: 14),
        // What was ordered.
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.labelQuickOrderFlavours,
                style: theme.textTheme.labelLarge,
              ),
            ),
            TextButton.icon(
              onPressed: _fillSuggested,
              icon: const Icon(Icons.auto_fix_high, size: 16),
              label: Text(l10n.labelQuickOrderFillSuggested),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        for (final flavour in _flavours)
          _QuickFlavourRow(
            flavour: flavour,
            count: _counts[flavour.key] ?? 0,
            branchCount: multiBranch ? _targets(flavour).length : 1,
            onChanged: (value) =>
                setState(() => _counts[flavour.key] = value),
          ),
        const SizedBox(height: 10),
        // When.
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: _fieldDecoration(l10n.labelQuickOrderOrderedOn)
                .copyWith(prefixIcon: const Icon(Icons.event, size: 20)),
            child: Text(
              DateFormat('EEE d MMM', l10n.localeName).format(_orderedOn),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(() => _showMore = !_showMore),
            icon: Icon(_showMore ? Icons.expand_less : Icons.expand_more),
            label: Text(l10n.labelQuickOrderMore),
          ),
        ),
        if (_showMore) ...[
          SupplierField(
            onChanged: (option) => setState(() => _supplier = option),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: _fieldDecoration(l10n.labelSheetNotesOptional),
          ),
        ],
      ],
      action: FilledButton.icon(
        onPressed: total <= 0
            ? null
            : () => Navigator.of(context).pop(
                  QuickOrderRequest(
                    sheetsByLabel: sheetsByLabel,
                    supplier: _supplier?.name,
                    requestedOn: DateFormat('yyyy-MM-dd').format(_orderedOn),
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                  ),
                ),
        icon: const Icon(Icons.check),
        label: Text(l10n.labelQuickOrderSubmit(total)),
      ),
    );
  }
}

class _QuickFlavour {
  final String key;
  final CustomerLabel sample;
  final List<CustomerLabel> labels = [];

  _QuickFlavour(this.key, this.sample);
}

class _QuickFlavourRow extends StatelessWidget {
  final _QuickFlavour flavour;
  final int count;
  final int branchCount;
  final ValueChanged<int> onChanged;

  const _QuickFlavourRow({
    required this.flavour,
    required this.count,
    required this.branchCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final sample = flavour.sample;
    final active = count > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        sample.labelTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: active ? FontWeight.w700 : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (sample.size != null) ...[
                      const SizedBox(width: 6),
                      _SizePill(size: sample.size!),
                    ],
                  ],
                ),
                if (active && branchCount > 1)
                  Text(
                    l10n.labelQuickOrderTimesBranches(branchCount),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  )
                else if (branchCount == 0)
                  Text(
                    l10n.labelQuickOrderNotAtBranch,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: count > 0 ? () => onChanged(count - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: active ? theme.colorScheme.primary : null,
              ),
            ),
          ),
          IconButton(
            onPressed: branchCount == 0 ? null : () => onChanged(count + 1),
            icon: const Icon(Icons.add_circle),
            color: theme.colorScheme.primary,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Mirrors LabelSizeChip without importing the card widget into the sheets.
class _SizePill extends StatelessWidget {
  final String size;

  const _SizePill({required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        size,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Receive a batch back
// ---------------------------------------------------------------------------
class ReceiveBatchSheet extends StatefulWidget {
  final LabelPrintOrder order;

  const ReceiveBatchSheet({super.key, required this.order});

  @override
  State<ReceiveBatchSheet> createState() => _ReceiveBatchSheetState();
}

class _ReceiveBatchSheetState extends State<ReceiveBatchSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.order.qty}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final order = widget.order;
    final received = int.tryParse(_controller.text.trim()) ?? 0;
    final ordered = order.qtySheets > 0
        ? '${l10n.labelCardSheetsCount(order.qtySheets)} · ${l10n.labelCardLabelsCount(order.qty)}'
        : l10n.labelCardLabelsCount(order.qty);
    return _SheetScaffold(
      title: l10n.labelSheetReceiveTitle,
      subtitle: l10n.labelSheetReceiveSubtitle(order.name, ordered),
      fields: [
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: _digits,
          decoration: _fieldDecoration(
            l10n.labelSheetLabelsReceived,
            helper: l10n.labelSheetReceivedHelper,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
      action: FilledButton.icon(
        onPressed: received <= 0 ? null : () => Navigator.of(context).pop(received),
        icon: const Icon(Icons.inventory_2),
        label: Text(l10n.labelSheetAddToStock),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Record the printer's bill
// ---------------------------------------------------------------------------
class RecordBillSheet extends StatefulWidget {
  final LabelPrintOrder order;

  const RecordBillSheet({super.key, required this.order});

  @override
  State<RecordBillSheet> createState() => _RecordBillSheetState();
}

class _RecordBillSheetState extends State<RecordBillSheet> {
  late final TextEditingController _costController = TextEditingController(
    text: widget.order.totalCost > 0
        ? widget.order.totalCost.toStringAsFixed(
            widget.order.totalCost == widget.order.totalCost.roundToDouble()
                ? 0
                : 2)
        : '',
  );
  final _billNoController = TextEditingController();
  LabelSupplierOption? _supplier;
  LabelPaymentSelection _payment = const LabelPaymentSelection.owed();

  @override
  void initState() {
    super.initState();
    final existing = widget.order.supplier;
    if (existing != null && existing.isNotEmpty) {
      _supplier = LabelSupplierOption(name: existing, supplierName: existing);
    }
  }

  @override
  void dispose() {
    _costController.dispose();
    _billNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final order = widget.order;
    final cost = _parseCost(_costController);
    final ordered = order.qtySheets > 0
        ? l10n.labelCardSheetsCount(order.qtySheets)
        : l10n.labelCardLabelsCount(order.qty);

    return _SheetScaffold(
      title: l10n.labelSheetBillTitle,
      subtitle: l10n.labelSheetBillSubtitle(order.name, ordered),
      fields: [
        SupplierField(
          initialSupplier: order.supplier,
          label: l10n.labelSheetPrintSupplier,
          onChanged: (option) => setState(() => _supplier = option),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _costController,
          autofocus: order.totalCost <= 0,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration(
            l10n.labelSheetNetCost,
            helper: l10n.labelSheetNetCostBillHelper,
            suffix: currencySymbol(context),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _billNoController,
          decoration: _fieldDecoration(l10n.labelSheetBillNoOptional),
        ),
        const SizedBox(height: 12),
        LabelPaymentChoiceField(
          value: _payment,
          amount: cost ?? 0,
          onChanged: (value) => setState(() => _payment = value),
        ),
      ],
      action: FilledButton.icon(
        onPressed: (_supplier == null ||
                cost == null ||
                _payment.isShort(cost))
            ? null
            : () => Navigator.of(context).pop(
                  BillRequest(
                    supplier: _supplier!.name,
                    totalCost: cost,
                    billNo: _billNoController.text.trim().isEmpty
                        ? null
                        : _billNoController.text.trim(),
                    isPaid: _payment.isPaid,
                    paymentOption: _payment.isPaid ? _payment.option : null,
                  ),
                ),
        icon: const Icon(Icons.receipt_long),
        label: Text(l10n.labelSheetRecordBill),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bought & received: order + receipt + bill in one form
// ---------------------------------------------------------------------------
/// For a batch that was already bought and delivered: what used to take
/// create order -> receive -> bill is one form and one server call.
class BoughtBatchSheet extends StatefulWidget {
  final CustomerLabel label;

  /// Pre-selects the printer, typically the one the last batch came from.
  final String? initialSupplier;

  /// Reuse the key of an attempt that failed (e.g. a timeout), so a retry
  /// replays it rather than buying twice. Null generates a fresh one.
  final String? clientRequestId;

  const BoughtBatchSheet({
    super.key,
    required this.label,
    this.initialSupplier,
    this.clientRequestId,
  });

  @override
  State<BoughtBatchSheet> createState() => _BoughtBatchSheetState();
}

class _BoughtBatchSheetState extends State<BoughtBatchSheet> {
  /// Fixed for the life of the sheet: one sheet, one purchase.
  late final String _requestId =
      widget.clientRequestId ?? newBoughtBatchRequestId();

  late final TextEditingController _sheetsController = TextEditingController(
    text: '${_initialSheets(widget.label)}',
  );
  late final TextEditingController _receivedController = TextEditingController(
    text: _labelsText(
        widget.label.labelsForSheets(_initialSheets(widget.label))),
  );
  final _costController = TextEditingController();
  final _billNoController = TextEditingController();
  final _notesController = TextEditingController();
  LabelSupplierOption? _supplier;
  LabelPaymentSelection _payment = const LabelPaymentSelection.owed();
  DateTime _boughtOn = DateUtils.dateOnly(DateTime.now());

  /// Once the user types a received count it is theirs: changing the sheets
  /// no longer overwrites it.
  bool _receivedEdited = false;

  static int _initialSheets(CustomerLabel label) =>
      label.defaultPrintSheets > 0 ? label.defaultPrintSheets : 1;

  static String _labelsText(int labels) => labels > 0 ? '$labels' : '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSupplier?.trim();
    if (initial != null && initial.isNotEmpty) {
      _supplier = LabelSupplierOption(name: initial, supplierName: initial);
    }
  }

  @override
  void dispose() {
    _sheetsController.dispose();
    _receivedController.dispose();
    _costController.dispose();
    _billNoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _sheets => int.tryParse(_sheetsController.text.trim()) ?? 0;

  void _onSheetsChanged() {
    setState(() {
      if (!_receivedEdited) {
        _receivedController.text =
            _labelsText(widget.label.labelsForSheets(_sheets));
      }
    });
  }

  void _stepSheets(int delta) {
    final next = _sheets + delta;
    if (next < 1) return;
    _sheetsController.text = '$next';
    _onSheetsChanged();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _boughtOn,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
    );
    if (picked != null) setState(() => _boughtOn = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final label = widget.label;
    final sheets = _sheets;
    final sheetLabels = label.labelsForSheets(sheets);
    final received = int.tryParse(_receivedController.text.trim());
    final cost = _parseCost(_costController);
    final canSave = sheets > 0 &&
        _supplier != null &&
        cost != null &&
        !_payment.isShort(cost);

    return _SheetScaffold(
      title: l10n.labelSheetBoughtTitle,
      subtitle: l10n.labelSheetBoughtSubtitle(
        '${label.customerName} · ${label.labelTitle}'
        '${label.size == null ? '' : ' · ${label.size}'}',
      ),
      fields: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('bought-sheets-minus'),
              onPressed: sheets > 1 ? () => _stepSheets(-1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Expanded(
              child: TextField(
                key: const ValueKey('bought-sheets'),
                controller: _sheetsController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: _digits,
                decoration: _fieldDecoration(l10n.labelSheetSheetsBought),
                onChanged: (_) => _onSheetsChanged(),
              ),
            ),
            IconButton(
              key: const ValueKey('bought-sheets-plus'),
              onPressed: () => _stepSheets(1),
              icon: const Icon(Icons.add_circle),
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        if (sheets > 0 && sheetLabels > 0) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.grid_on, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.labelSheetSheetsEquals(
                    l10n.labelCardSheetsCount(sheets),
                    l10n.labelCardLabelsCount(sheetLabels),
                  ),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('bought-received'),
          controller: _receivedController,
          keyboardType: TextInputType.number,
          inputFormatters: _digits,
          decoration: _fieldDecoration(
            l10n.labelSheetLabelsReceived,
            helper: l10n.labelSheetBoughtReceivedHelper,
          ),
          onChanged: (_) => setState(() => _receivedEdited = true),
        ),
        const SizedBox(height: 12),
        SupplierField(
          initialSupplier: widget.initialSupplier,
          label: l10n.labelSheetPrintSupplier,
          onChanged: (option) => setState(() => _supplier = option),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('bought-cost'),
          controller: _costController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration(
            l10n.labelSheetNetCost,
            helper: l10n.labelSheetNetCostBillHelper,
            suffix: currencySymbol(context),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _billNoController,
          decoration: _fieldDecoration(l10n.labelSheetBillNoOptional),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: _fieldDecoration(l10n.labelSheetBoughtOn)
                .copyWith(prefixIcon: const Icon(Icons.event, size: 20)),
            child: Text(
              DateFormat('EEE d MMM yyyy', l10n.localeName).format(_boughtOn),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: _fieldDecoration(l10n.labelSheetNotesOptional),
        ),
        const SizedBox(height: 12),
        LabelPaymentChoiceField(
          value: _payment,
          amount: cost ?? 0,
          onChanged: (value) => setState(() => _payment = value),
        ),
      ],
      action: FilledButton.icon(
        key: const ValueKey('bought-save'),
        onPressed: !canSave
            ? null
            : () => Navigator.of(context).pop(
                  BoughtBatchRequest(
                    qtySheets: sheets,
                    receivedQty:
                        (received != null && received > 0) ? received : null,
                    supplier: _supplier!.name,
                    totalCost: cost,
                    billNo: _billNoController.text.trim().isEmpty
                        ? null
                        : _billNoController.text.trim(),
                    boughtOn: _boughtOn,
                    isPaid: _payment.isPaid,
                    paymentOption: _payment.isPaid ? _payment.option : null,
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                    clientRequestId: _requestId,
                  ),
                ),
        icon: const Icon(Icons.inventory_2),
        label: Text(l10n.labelSheetRecordBought),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Manual ledger entry
// ---------------------------------------------------------------------------
class MovementSheet extends StatefulWidget {
  final CustomerLabel label;

  const MovementSheet({super.key, required this.label});

  @override
  State<MovementSheet> createState() => _MovementSheetState();
}

class _MovementSheetState extends State<MovementSheet> {
  final _qtyController = TextEditingController();
  final _remarksController = TextEditingController();
  String _type = 'Consumed';

  static const _types = <String>[
    'Consumed',
    'Print Received',
    'Scrapped',
    'Adjustment',
  ];

  @override
  void dispose() {
    _qtyController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    final isAdjustment = _type == 'Adjustment';

    return _SheetScaffold(
      title: l10n.labelSheetMovementTitle,
      subtitle: '${widget.label.customerName} · ${widget.label.labelTitle}',
      fields: [
        DropdownButtonFormField<String>(
          initialValue: _type,
          isExpanded: true,
          decoration: _fieldDecoration(l10n.labelSheetWhatHappened),
          items: _types
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(localizedLabelMovementType(context, type)),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _type = value ?? _type),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _qtyController,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(signed: isAdjustment),
          inputFormatters: isAdjustment
              ? [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))]
              : _digits,
          decoration: _fieldDecoration(
            l10n.labelSheetQuantity,
            helper: isAdjustment
                ? l10n.labelSheetAdjustmentHelper
                : l10n.labelSheetQtyHelper,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _remarksController,
          decoration: _fieldDecoration(l10n.labelSheetNoteOptional),
        ),
      ],
      action: FilledButton(
        onPressed: qty == 0
            ? null
            : () => Navigator.of(context).pop(
                  MovementRequest(
                    movementType: _type,
                    qty: qty,
                    remarks: _remarksController.text.trim().isEmpty
                        ? null
                        : _remarksController.text.trim(),
                  ),
                ),
        child: Text(l10n.labelDetailActionRecord),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit the label's policy
// ---------------------------------------------------------------------------
class LabelPolicySheet extends ConsumerStatefulWidget {
  final CustomerLabel label;

  const LabelPolicySheet({super.key, required this.label});

  @override
  ConsumerState<LabelPolicySheet> createState() => _LabelPolicySheetState();
}

class _LabelPolicySheetState extends ConsumerState<LabelPolicySheet> {
  late final TextEditingController _titleController =
      TextEditingController(text: widget.label.labelTitle);
  late final TextEditingController _perUnitController = TextEditingController(
      text: widget.label.labelsPerUnit.toStringAsFixed(
          widget.label.labelsPerUnit == widget.label.labelsPerUnit.roundToDouble()
              ? 0
              : 2));
  late final TextEditingController _minStockController =
      TextEditingController(text: '${widget.label.minStockQty}');
  late final TextEditingController _sheetsController =
      TextEditingController(text: '${widget.label.defaultPrintSheets}');
  late final TextEditingController _perSheetController =
      TextEditingController(text: '${widget.label.labelsPerSheet}');
  late final TextEditingController _notesController =
      TextEditingController(text: widget.label.notes ?? '');

  late bool _enabled = widget.label.enabled;
  late String? _location = widget.label.storageLocation;

  @override
  void dispose() {
    _titleController.dispose();
    _perUnitController.dispose();
    _minStockController.dispose();
    _sheetsController.dispose();
    _perSheetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locations = ref.watch(labelStorageLocationsProvider);

    return _SheetScaffold(
      title: l10n.labelDetailSettingsTooltip,
      subtitle: '${widget.label.customerName}'
          '${widget.label.size == null ? '' : ' · ${widget.label.size}'}',
      fields: [
        TextField(
          controller: _titleController,
          decoration: _fieldDecoration(l10n.labelSheetLabelName),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _enabled,
          onChanged: (value) => setState(() => _enabled = value),
          title: Text(l10n.labelSheetActive),
          subtitle: Text(l10n.labelSheetActiveHelp),
        ),
        const SizedBox(height: 8),
        locations.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
          data: (options) {
            final known = options.map((o) => o.name).toSet();
            return DropdownButtonFormField<String?>(
              initialValue:
                  (_location != null && known.contains(_location)) ||
                          _location == null
                      ? _location
                      : null,
              isExpanded: true,
              decoration: _fieldDecoration(
                l10n.labelDetailPolicyStoredAt,
                helper: l10n.labelSheetStoredAtHelper,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.labelDetailPolicyNotSet),
                ),
                ...options.map(
                  (option) => DropdownMenuItem<String?>(
                    value: option.name,
                    child: Text(option.label, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _location = value),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minStockController,
                keyboardType: TextInputType.number,
                inputFormatters: _digits,
                decoration: _fieldDecoration(l10n.labelDetailPolicyMinStock),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _sheetsController,
                keyboardType: TextInputType.number,
                inputFormatters: _digits,
                decoration:
                    _fieldDecoration(l10n.labelSheetUsualBatchSheets),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _perSheetController,
                keyboardType: TextInputType.number,
                inputFormatters: _digits,
                decoration: _fieldDecoration(
                  l10n.labelDetailPolicyLabelsPerSheet,
                  helper: l10n.labelSheetLabelsPerSheetHelper,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _perUnitController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _fieldDecoration(
                  l10n.labelDetailPolicyLabelsPerJar,
                  helper: l10n.labelSheetLabelsPerJarHelper,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: _fieldDecoration(l10n.commonNotesLabel),
        ),
      ],
      action: FilledButton(
        onPressed: () => Navigator.of(context).pop(
          LabelPolicyRequest(
            labelTitle: _titleController.text.trim().isEmpty
                ? widget.label.labelTitle
                : _titleController.text.trim(),
            enabled: _enabled,
            // An empty string clears the home location server-side.
            storageLocation: _location ?? '',
            labelsPerUnit:
                double.tryParse(_perUnitController.text.trim()) ?? 1,
            labelsPerSheet: _parseInt(_perSheetController),
            defaultPrintSheets: _parseInt(_sheetsController),
            minStockQty: _parseInt(_minStockController),
            notes: _notesController.text.trim(),
          ),
        ),
        child: Text(l10n.commonSave),
      ),
    );
  }
}

String _dmy(BuildContext context, DateTime date) {
  return DateFormat('d MMM', context.l10n.localeName).format(date);
}
