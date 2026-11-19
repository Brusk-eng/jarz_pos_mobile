import 'package:jarz_pos/src/core/localization/user_error_message.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/utils/pasted_text.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/item_title_with_arabic.dart';
import '../../data/purchase_request_repository.dart';
import '../../models/purchase_request_models.dart';
import '../../state/purchase_request_notifier.dart';

/// Raise a request. Deliberately the thinnest screen in the feature: search,
/// tap, set a number, send. If asking for stock costs more effort than
/// shouting across the kitchen, nobody uses it and the buying list stays empty.
///
/// The same sheet edits a request nobody has acted on yet ([editing]).
class NewRequestSheet extends ConsumerStatefulWidget {
  /// The request being edited, or null when raising a new one.
  final ItemRequest? editing;

  const NewRequestSheet({super.key, this.editing});

  static Future<ItemRequest?> show(BuildContext context) {
    return showModalBottomSheet<ItemRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewRequestSheet(),
    );
  }

  static Future<ItemRequest?> edit(BuildContext context, ItemRequest request) {
    return showModalBottomSheet<ItemRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewRequestSheet(editing: request),
    );
  }

  @override
  ConsumerState<NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends ConsumerState<NewRequestSheet> {
  final _searchController = TextEditingController();
  final _noteController = TextEditingController();
  final List<DraftRequestLine> _lines = [];

  Timer? _debounce;
  /// Monotonic token that lets a slow response for an older query be discarded.
  /// Without it, results for "ah" can land after "ahmed" and overwrite them.
  int _searchToken = 0;
  List<Map<String, dynamic>> _results = const [];
  bool _searching = false;
  DateTime? _neededBy;

  /// Edit mode only: the item units are still being fetched.
  bool _loadingEdit = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _neededBy = editing.scheduleDate;
      _noteController.text = editing.note ?? '';
      _lines.addAll(editing.items.map(_draftFromLine));
      _loadingEdit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadForEdit());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// A saved line as an editable draft. Until the item's full unit list
  /// arrives, it can at least be kept in the unit it was requested in.
  DraftRequestLine _draftFromLine(RequestLine line) {
    final uom = line.uom.isEmpty ? line.stockUom : line.uom;
    return DraftRequestLine(
      itemCode: line.itemCode,
      itemName: line.itemName,
      uom: uom,
      qty: line.qty,
      uoms: [
        if (line.stockUom.isNotEmpty)
          RequestUomOption(uom: line.stockUom, conversionFactor: 1),
        if (uom != line.stockUom)
          RequestUomOption(uom: uom, conversionFactor: line.conversionFactor),
      ],
    );
  }

  Future<void> _loadForEdit() async {
    final editing = widget.editing!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final result = await ref
          .read(purchaseRequestRepositoryProvider)
          .getRequestForEdit(editing.name);
      if (!mounted) return;
      setState(() {
        _loadingEdit = false;
        for (var i = 0; i < _lines.length; i++) {
          final options = result.uoms[_lines[i].itemCode];
          if (options != null && options.isNotEmpty) {
            _lines[i] = _lines[i].copyWith(uoms: _withUnit(options, _lines[i]));
          }
        }
      });
    } catch (error) {
      if (!mounted) return;
      // Most often a buyer accepted it in the meantime — say so and close
      // rather than let the user edit something the server will refuse.
      messenger.showSnackBar(
        SnackBar(content: Text(context.userErrorMessage(error))),
      );
      navigator.pop();
    }
  }

  /// Keeps the line's current unit selectable even if the Item's conversion
  /// was removed since, so the dropdown never holds a value it cannot show.
  List<RequestUomOption> _withUnit(
    List<RequestUomOption> options,
    DraftRequestLine line,
  ) {
    if (options.any((o) => o.uom == line.uom)) return options;
    return [...options, RequestUomOption(uom: line.uom, conversionFactor: 1)];
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    // One request per keystroke is what the old purchase screen did; 300ms of
    // quiet is the difference between ~20 calls and ~2 for a typed word.
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    final token = ++_searchToken;
    setState(() => _searching = true);
    try {
      final results =
          await ref.read(purchaseRequestRepositoryProvider).searchItems(query);
      if (!mounted || token != _searchToken) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _results = const [];
        _searching = false;
      });
    }
  }

  void _addItem(Map<String, dynamic> item) {
    final code = (item['item_code'] ?? '').toString();
    if (code.isEmpty) return;
    final existing = _lines.indexWhere((l) => l.itemCode == code);
    setState(() {
      if (existing >= 0) {
        // Tapping the same item again bumps the quantity instead of creating a
        // duplicate line the buyer would then have to merge by hand.
        _lines[existing] =
            _lines[existing].copyWith(qty: _lines[existing].qty + 1);
      } else {
        final stockUom = (item['stock_uom'] ?? '').toString();
        var uoms = RequestUomOption.listFromJson(item['uoms']);
        if (uoms.isEmpty && stockUom.isNotEmpty) {
          uoms = [RequestUomOption(uom: stockUom, conversionFactor: 1)];
        }
        _lines.add(DraftRequestLine(
          itemCode: code,
          itemName: (item['item_name'] ?? code).toString(),
          uom: stockUom.isNotEmpty
              ? stockUom
              : (uoms.isNotEmpty ? uoms.first.uom : ''),
          qty: 1,
          uoms: uoms,
        ));
      }
    });
  }

  void _changeQty(int index, double delta) {
    final next = _lines[index].qty + delta;
    setState(() {
      if (next <= 0) {
        _lines.removeAt(index);
      } else {
        _lines[index] = _lines[index].copyWith(qty: next);
      }
    });
  }

  /// A typed quantity. Zero or blank keeps the line (the user is mid-edit) but
  /// blocks sending until it is a real number.
  void _setQty(int index, double qty) {
    if (_lines[index].qty == qty) return;
    setState(() => _lines[index] = _lines[index].copyWith(qty: qty));
  }

  void _setUom(int index, String uom) {
    setState(() => _lines[index] = _lines[index].copyWith(uom: uom));
  }

  void _removeLine(int index) {
    setState(() => _lines.removeAt(index));
  }

  bool get _canSend =>
      _lines.isNotEmpty && _lines.every((l) => l.qty > 0) && !_loadingEdit;

  Future<void> _submit() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final notifier = ref.read(purchaseRequestNotifierProvider.notifier);
    final scheduleDate = _neededBy == null
        ? null
        : DateFormat('yyyy-MM-dd').format(_neededBy!);

    final editing = widget.editing;
    final saved = editing == null
        ? await notifier.submitRequest(
            items: _lines,
            scheduleDate: scheduleDate,
            note: _noteController.text,
          )
        : await notifier.updateRequest(
            name: editing.name,
            items: _lines,
            scheduleDate: scheduleDate,
            note: _noteController.text,
          );

    if (!mounted) return;
    if (saved == null) {
      final error = ref.read(purchaseRequestNotifierProvider).error ?? '';
      messenger.showSnackBar(
        SnackBar(content: Text(context.userErrorMessage(error))),
      );
      // A refused edit often means the request moved on elsewhere (accepted,
      // bought, edited on another phone): refresh the list behind the sheet
      // so its card stops offering Edit.
      if (editing != null) {
        unawaited(ref.read(purchaseRequestNotifierProvider.notifier).load());
      }
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          editing == null
              ? l10n.requestsSubmitted(saved.name)
              : l10n.requestsUpdated(saved.name),
        ),
      ),
    );
    navigator.pop(saved);
  }

  Future<void> _pickNeededBy() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = _neededBy;
    // An edited request can already be overdue; the picker asserts that its
    // initial date is not before firstDate, so widen the range to include it.
    final first =
        (current != null && current.isBefore(today)) ? current : today;
    final yearOut = today.add(const Duration(days: 365));
    final last = (current != null && current.isAfter(yearOut)) ? current : yearOut;
    final picked = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDate: current ?? today.add(const Duration(days: 3)),
    );
    if (picked != null) {
      setState(() => _neededBy = picked);
    }
  }

  String _fmtQty(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isSubmitting =
        ref.watch(purchaseRequestNotifierProvider).isSubmitting;

    return DraggableScrollableSheet(
      initialChildSize: ResponsiveUtils.getCartBottomSheetInitialSize(context),
      minChildSize: ResponsiveUtils.getCartBottomSheetMinSize(context),
      maxChildSize: ResponsiveUtils.getCartBottomSheetMaxSize(context),
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing
                            ? '${l10n.requestsEditTitle} · ${widget.editing!.name}'
                            : l10n.requestsNewTitle,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  // Editing opens on the lines, not the keyboard.
                  autofocus: !_isEditing,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.commonSearchItems,
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              if (_loadingEdit) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 8),
                    if (_lines.isNotEmpty) ...[
                      for (var i = 0; i < _lines.length; i++)
                        _DraftLineTile(
                          key: ValueKey(_lines[i].itemCode),
                          line: _lines[i],
                          onDecrement: () => _changeQty(i, -1),
                          onIncrement: () => _changeQty(i, 1),
                          onQtyTyped: (qty) => _setQty(i, qty),
                          onUomChanged: (uom) => _setUom(i, uom),
                          onRemove: () => _removeLine(i),
                        ),
                      const Divider(height: 24),
                    ],
                    if (_results.isEmpty && _lines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            l10n.requestsNoItemsYet,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    for (final item in _results) _resultTile(context, item),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  12 +
                      MediaQuery.of(context).viewInsets.bottom +
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event_outlined,
                            size: 18, color: theme.colorScheme.outline),
                        const SizedBox(width: 6),
                        Text(l10n.requestsNeededBy),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _pickNeededBy,
                          child: Text(
                            _neededBy == null
                                ? l10n.commonChoose
                                : DateFormat('MMM d').format(_neededBy!),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      minLines: 1,
                      decoration: InputDecoration(
                        labelText: l10n.requestsNoteLabel,
                        hintText: l10n.requestsNoteHint,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: !_canSend || isSubmitting ? null : _submit,
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : Icon(_isEditing ? Icons.save : Icons.send),
                        label: Text(
                          _isEditing
                              ? l10n.requestsSaveChanges
                              : l10n.requestsSubmit,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _resultTile(BuildContext context, Map<String, dynamic> item) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final code = (item['item_code'] ?? '').toString();
    final onHand = (item['on_hand_qty'] is num)
        ? (item['on_hand_qty'] as num).toDouble()
        : 0.0;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: ItemTitleWithArabic(
        title: (item['item_name'] ?? code).toString(),
        arabicName: item['item_name_ar'],
      ),
      subtitle: Text(
        // Showing stock here stops the most common wasteful request: asking
        // for something the branch already has.
        '${item['stock_uom'] ?? ''} · ${l10n.purchaseOnHand(_fmtQty(onHand))}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle),
        color: theme.colorScheme.primary,
        onPressed: () => _addItem(item),
      ),
      onTap: () => _addItem(item),
    );
  }
}

/// One requested line: unit picker, and a quantity that can be typed or
/// stepped with − / +.
///
/// Stateful only to own the quantity field's controller, so typing is not
/// fought by a rebuild re-formatting the text under the cursor.
class _DraftLineTile extends StatefulWidget {
  final DraftRequestLine line;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<double> onQtyTyped;
  final ValueChanged<String> onUomChanged;
  final VoidCallback onRemove;

  const _DraftLineTile({
    super.key,
    required this.line,
    required this.onDecrement,
    required this.onIncrement,
    required this.onQtyTyped,
    required this.onUomChanged,
    required this.onRemove,
  });

  @override
  State<_DraftLineTile> createState() => _DraftLineTileState();
}

class _DraftLineTileState extends State<_DraftLineTile> {
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: _fmt(widget.line.qty));
  }

  @override
  void didUpdateWidget(covariant _DraftLineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // − / + or re-tapping the item changed the number from outside the field.
    // Leave the text alone when it already means this number ("2." is 2).
    if (_parse(_qtyController.text) != widget.line.qty) {
      final text = _fmt(widget.line.qty);
      _qtyController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  static String _fmt(double value) {
    if (value <= 0) return '';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    // Up to 3 decimals, without trailing zeros: 0.25, 1.5.
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static double _parse(String text) => double.tryParse(text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final line = widget.line;
    final invalid = line.qty <= 0;
    final options = line.uoms;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 4, 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.itemName,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis),
                  if (options.length > 1)
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: line.uom,
                        isDense: true,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        hint: Text(l10n.requestsUnit),
                        items: [
                          for (final option in options)
                            DropdownMenuItem(
                              value: option.uom,
                              child: Text(option.uom),
                            ),
                        ],
                        onChanged: (uom) {
                          if (uom != null) widget.onUomChanged(uom);
                        },
                      ),
                    )
                  else
                    Text(line.uom,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: widget.onDecrement,
            ),
            SizedBox(
              width: 64,
              child: TextField(
                controller: _qtyController,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const [_QtyInputFormatter()],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  border: const OutlineInputBorder(),
                  errorText: invalid ? '' : null,
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
                // Tapping selects the number so it can be typed over in one go.
                onTap: () => _qtyController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _qtyController.text.length,
                ),
                onChanged: (text) => widget.onQtyTyped(_parse(text)),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline),
              onPressed: widget.onIncrement,
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: widget.onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

/// Positive decimals only, up to 3 places. Arabic-Indic digits and the Arabic
/// decimal separator (or a comma) are folded to ASCII, so an Arabic keyboard
/// types a number instead of nothing.
class _QtyInputFormatter extends TextInputFormatter {
  const _QtyInputFormatter();

  static final _valid = RegExp(r'^\d{0,6}(\.\d{0,3})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = PastedText.normalizeDigits(newValue.text)
        .replaceAll('٫', '.')
        .replaceAll(',', '.')
        .trim();
    if (!_valid.hasMatch(text)) return oldValue;
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
