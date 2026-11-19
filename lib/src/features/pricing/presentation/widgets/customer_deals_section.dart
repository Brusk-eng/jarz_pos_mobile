import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../../../core/network/frappe_error_message.dart';
import '../../data/customer_deals_repository.dart';
import '../../data/models/customer_deal_models.dart';

String _money(BuildContext context, num value) =>
    formatCurrency(context, value, currencyCode: 'EGP');

String _day(BuildContext context, DateTime d) =>
    formatDate(context, d, pattern: 'd MMM yyyy');

/// "Special prices": time-limited deals for one B2B customer.
///
/// A deal prices this customer's orders between two dates; outside them the
/// normal price applies again with nothing to undo. Shown on the B2B account
/// screen for a real Customer. Renders nothing while loading or when the
/// caller may not read pricing (or the server predates deals).
class CustomerDealsSection extends ConsumerWidget {
  final String customer;
  final String customerName;

  const CustomerDealsSection({
    super.key,
    required this.customer,
    this.customerName = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(customerDealsProvider(customer));
    return async.maybeWhen(
      data: (data) => _DealsCard(
        data: data,
        customerName: customerName.isNotEmpty
            ? customerName
            : data.customerName,
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _DealsCard extends ConsumerWidget {
  final CustomerDeals data;
  final String customerName;

  const _DealsCard({required this.data, required this.customerName});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref, [
    CustomerDeal? deal,
  ]) async {
    final saved = await CustomerDealSheet.show(
      context,
      data: data,
      customerName: customerName,
      deal: deal,
    );
    if (saved == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final live = data.live;
    final history = data.history;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  color: live.isNotEmpty ? theme.colorScheme.primary : muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dealsTitle,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: muted,
                        ),
                      ),
                      Text(
                        live.isEmpty ? l10n.dealsNone : l10n.dealsSubtitle,
                        style: live.isEmpty
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                if (data.canEdit)
                  TextButton.icon(
                    key: const ValueKey('deals-new'),
                    onPressed: () => _open(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.dealsNew),
                  ),
              ],
            ),
            for (final deal in live)
              _DealTile(
                deal: deal,
                onTap: data.canEdit && deal.editable
                    ? () => _open(context, ref, deal)
                    : null,
              ),
            if (history.isNotEmpty)
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    l10n.dealsHistory(history.length),
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  children: [for (final deal in history) _DealTile(deal: deal)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DealTile extends StatelessWidget {
  final CustomerDeal deal;
  final VoidCallback? onTap;

  const _DealTile({required this.deal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final (label, color) = switch (deal.status) {
      CustomerDealStatus.active => (
        l10n.dealStatusActive,
        Colors.green.shade700,
      ),
      CustomerDealStatus.upcoming => (
        l10n.dealStatusUpcoming,
        theme.colorScheme.primary,
      ),
      CustomerDealStatus.expired => (l10n.dealStatusExpired, muted),
      CustomerDealStatus.cancelled => (l10n.dealStatusCancelled, muted),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(color: color),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_day(context, deal.validFrom)} – ${_day(context, deal.validUpto)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.edit_outlined, size: 18, color: muted),
              ],
            ),
            const SizedBox(height: 4),
            for (final line in deal.items)
              Text(
                '${line.isCategory ? l10n.dealCategoryLabel(line.label) : line.label}: '
                '${line.normalRate != null ? l10n.dealRateVsNormal(_money(context, line.rate), _money(context, line.normalRate!)) : _money(context, line.rate)}',
                style: theme.textTheme.bodySmall,
              ),
            if (deal.notes != null)
              Text(
                deal.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditableLine {
  final String? itemGroup;
  final String? itemCode;
  final String label;
  final double? normalRate;
  final TextEditingController rate;

  _EditableLine({
    this.itemGroup,
    this.itemCode,
    required this.label,
    this.normalRate,
    String initialRate = '',
  }) : rate = TextEditingController(text: initialRate);

  bool get isCategory => itemCode == null;
  String get key => isCategory ? 'g:$itemGroup' : 'i:$itemCode';
}

/// Create a deal, or change an upcoming/running one. Returns the snackbar
/// message on success, null when the user backed out.
class CustomerDealSheet extends ConsumerStatefulWidget {
  final CustomerDeals data;
  final String customerName;
  final CustomerDeal? deal;

  const CustomerDealSheet({
    super.key,
    required this.data,
    required this.customerName,
    this.deal,
  });

  static Future<String?> show(
    BuildContext context, {
    required CustomerDeals data,
    required String customerName,
    CustomerDeal? deal,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: CustomerDealSheet(
          data: data,
          customerName: customerName,
          deal: deal,
        ),
      ),
    );
  }

  @override
  ConsumerState<CustomerDealSheet> createState() => _CustomerDealSheetState();
}

class _CustomerDealSheetState extends ConsumerState<CustomerDealSheet> {
  DateTimeRange? _range;
  final List<_EditableLine> _lines = [];
  late final TextEditingController _notes;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.deal != null;

  /// A running deal that already priced a booked order keeps its start date
  /// and prices (the server enforces it); only the end date can move. Before
  /// its first order it is still free to fix, e.g. a typo seen that morning.
  bool get _startLocked =>
      widget.deal?.status == CustomerDealStatus.active &&
      widget.deal!.hasOrders;
  bool get _pricesLocked => _startLocked;

  /// A deal with orders that already ends today has nothing left to end.
  bool get _canEnd {
    final deal = widget.deal;
    if (deal == null) return false;
    if (!deal.hasOrders) return true;
    return _dateOnly(deal.validUpto).isAfter(_dateOnly(DateTime.now()));
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    final deal = widget.deal;
    _notes = TextEditingController(text: deal?.notes ?? '');
    if (deal != null) {
      _range = DateTimeRange(
        start: _dateOnly(deal.validFrom),
        end: _dateOnly(deal.validUpto),
      );
      for (final line in deal.items) {
        _lines.add(
          _EditableLine(
            itemGroup: line.itemGroup,
            itemCode: line.itemCode,
            label: line.label,
            normalRate:
                line.normalRate ??
                widget.data.normalRateFor(
                  itemCode: line.itemCode,
                  itemGroup: line.itemGroup,
                ),
            initialRate: _plain(line.rate),
          ),
        );
      }
    }
  }

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void dispose() {
    _notes.dispose();
    for (final l in _lines) {
      l.rate.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDates() async {
    final today = _dateOnly(DateTime.now());
    final current = _range;
    final first = _startLocked ? current!.start : today;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: today.add(const Duration(days: 730)),
      initialDateRange: current != null && !current.start.isBefore(first)
          ? current
          : null,
    );
    if (picked == null) return;
    setState(() {
      _error = null;
      _range = _startLocked
          ? DateTimeRange(start: current!.start, end: picked.end)
          : picked;
    });
  }

  Future<void> _addTarget({required bool category}) async {
    final taken = _lines.map((l) => l.key).toSet();
    final options = (category ? widget.data.categories : widget.data.items)
        .where((t) => !taken.contains(t.key))
        .toList();
    final target = await showModalBottomSheet<DealTarget>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TargetPicker(options: options, searchable: !category),
    );
    if (target == null) return;
    setState(() {
      _error = null;
      _lines.add(
        _EditableLine(
          itemGroup: target.itemGroup,
          itemCode: target.itemCode,
          label: target.label,
          normalRate: target.normalRate,
        ),
      );
    });
  }

  String _failure(Object error) {
    final l10n = context.l10n;
    return context.userErrorMessage(
      extractFrappeErrorMessage(error, fallback: l10n.dealSaveFailed),
      fallback: l10n.dealSaveFailed,
    );
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final range = _range;
    if (range == null) {
      setState(() => _error = l10n.dealNeedsDates);
      return;
    }
    if (_lines.isEmpty) {
      setState(() => _error = l10n.dealNeedsLines);
      return;
    }
    final items = <CustomerDealLine>[];
    for (final line in _lines) {
      final rate = double.tryParse(line.rate.text.trim());
      if (rate == null || rate < 0) {
        setState(() => _error = l10n.dealInvalidRate);
        return;
      }
      items.add(
        CustomerDealLine(
          itemGroup: line.itemGroup,
          itemCode: line.itemCode,
          label: line.label,
          rate: rate,
        ),
      );
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(customerDealsRepositoryProvider)
          .saveCustomerDeal(
            customer: widget.data.customer,
            validFrom: range.start,
            validUpto: range.end,
            items: items,
            notes: _notes.text.trim(),
            deal: widget.deal?.name,
          );
      ref.invalidate(customerDealsProvider(widget.data.customer));
      if (!mounted) return;
      Navigator.of(context).pop(l10n.dealSaved);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _failure(error);
      });
    }
  }

  Future<void> _end() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.dealEnd),
        content: Text(l10n.dealEndConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.dealEnd),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ended = await ref
          .read(customerDealsRepositoryProvider)
          .endCustomerDeal(widget.deal!.name);
      ref.invalidate(customerDealsProvider(widget.data.customer));
      if (!mounted) return;
      Navigator.of(context).pop(
        ended.status == CustomerDealStatus.cancelled
            ? l10n.dealCancelled
            : l10n.dealEndsTonight,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _failure(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final range = _range;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _isEdit ? l10n.dealEditTitle : l10n.dealsNew,
              style: theme.textTheme.titleLarge,
            ),
            if (widget.customerName.isNotEmpty)
              Text(
                widget.customerName,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            const SizedBox(height: 4),
            Text(
              l10n.dealHelp,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('deal-dates'),
              onPressed: _busy ? null : _pickDates,
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                range == null
                    ? l10n.dealPickDates
                    : '${_day(context, range.start)} – ${_day(context, range.end)}',
              ),
            ),
            if (_startLocked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.dealStartLocked,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
            const SizedBox(height: 12),
            for (final line in _lines)
              Padding(
                key: ValueKey(line.key),
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          line.isCategory
                              ? l10n.dealCategoryLabel(line.label)
                              : line.label,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: line.rate,
                        enabled: !_busy && !_pricesLocked,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.dealRateLabel,
                          helperText: line.normalRate != null
                              ? l10n.dealNormalPrice(
                                  _money(context, line.normalRate!),
                                )
                              : null,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.commonDelete,
                      onPressed: _busy || _pricesLocked
                          ? null
                          : () {
                              setState(() => _lines.remove(line));
                              // The field still holds the controller until
                              // this frame rebuilds without it.
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => line.rate.dispose(),
                              );
                            },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('deal-add-category'),
                  onPressed: _busy || _pricesLocked
                      ? null
                      : () => _addTarget(category: true),
                  icon: const Icon(Icons.category_outlined, size: 18),
                  label: Text(l10n.dealAddCategory),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('deal-add-item'),
                  onPressed: _busy || _pricesLocked
                      ? null
                      : () => _addTarget(category: false),
                  icon: const Icon(Icons.add_box_outlined, size: 18),
                  label: Text(l10n.dealAddItem),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              enabled: !_busy,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.commonNotesLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('deal-save'),
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
            if (_isEdit && _canEnd)
              TextButton(
                key: const ValueKey('deal-end'),
                onPressed: _busy ? null : _end,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: Text(l10n.dealEnd),
              ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.commonCancel),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetPicker extends StatefulWidget {
  final List<DealTarget> options;
  final bool searchable;

  const _TargetPicker({required this.options, required this.searchable});

  @override
  State<_TargetPicker> createState() => _TargetPickerState();
}

class _TargetPickerState extends State<_TargetPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? widget.options
        : widget.options
              .where(
                (t) =>
                    t.label.toLowerCase().contains(q) ||
                    (t.itemCode ?? '').toLowerCase().contains(q) ||
                    (t.parentGroup ?? '').toLowerCase().contains(q),
              )
              .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          if (widget.searchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.commonSearchItems,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          Expanded(
            child: shown.isEmpty
                ? Center(child: Text(l10n.commonNoItems))
                : ListView.builder(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom,
                    ),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final t = shown[i];
                      final subtitle = [
                        if (t.parentGroup != null) t.parentGroup!,
                        if (t.normalRate != null)
                          l10n.dealNormalPrice(_money(context, t.normalRate!)),
                      ].join(' • ');
                      return ListTile(
                        title: Text(
                          t.isCategory
                              ? l10n.dealCategoryLabel(t.label)
                              : t.label,
                        ),
                        subtitle: subtitle.isEmpty
                            ? null
                            : Text(subtitle, style: theme.textTheme.bodySmall),
                        onTap: () => Navigator.of(context).pop(t),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
