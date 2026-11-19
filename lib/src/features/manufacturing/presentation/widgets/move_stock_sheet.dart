import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../../../core/ui/loading_overlay.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/manufacturing_service.dart';
import '../../data/models/material_move_result.dart';
import '../../data/models/stock_alternative.dart';
import '../../state/production_providers.dart';
import 'batch_line_card.dart' show DecimalTextInputFormatter;
import 'production_format.dart';

/// Moves a short component out of the store it is actually sitting in and into
/// the one its recipe draws from.
///
/// The board has always been able to say "4.336 Kg is in Raw Material - J —
/// needs a stock transfer, not a purchase", and that was the end of it: the
/// transfer lived in Desk, which nobody on the floor has open. Saying where the
/// stock is without offering to fetch it is the same dead end as not saying it,
/// one sentence later.
///
/// Returns the server's result, or null when the operator backed out or the
/// move failed. Failure keeps the sheet open with the numbers still typed — no
/// stock has moved, so a retry costs one tap.
Future<MaterialMoveResult?> showMoveStockSheet(
  BuildContext context, {
  required String itemCode,
  required String itemName,
  required String uom,
  required List<StockAlternative> alternatives,
  double? neededQty,
  String? destinationWarehouse,
}) {
  if (alternatives.isEmpty) return Future.value(null);
  return showModalBottomSheet<MaterialMoveResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: MoveStockSheet(
        itemCode: itemCode,
        itemName: itemName,
        uom: uom,
        alternatives: alternatives,
        neededQty: neededQty,
        destinationWarehouse: destinationWarehouse,
      ),
    ),
  );
}

class MoveStockSheet extends ConsumerStatefulWidget {
  const MoveStockSheet({
    super.key,
    required this.itemCode,
    required this.itemName,
    required this.uom,
    required this.alternatives,
    this.neededQty,
    this.destinationWarehouse,
  });

  final String itemCode;
  final String itemName;
  final String uom;

  /// Other stores holding this component, fullest first. Never empty — the
  /// entry point returns early rather than opening a sheet with no source.
  final List<StockAlternative> alternatives;

  /// The shortfall in the recipe's warehouse, when the caller knows it.
  ///
  /// Only a default for the quantity field: the operator may well want to move
  /// the lot, and a batch bigger than the one the board suggested needs more
  /// than the shortfall anyway.
  final double? neededQty;

  /// Left null in the ordinary case — the server resolves the one warehouse the
  /// component is drawn from, and refuses any other. Passed only when the
  /// caller already knows it, so the sheet can name the destination before the
  /// move rather than after.
  final String? destinationWarehouse;

  @override
  ConsumerState<MoveStockSheet> createState() => _MoveStockSheetState();
}

class _MoveStockSheetState extends ConsumerState<MoveStockSheet> {
  late StockAlternative _source;
  late final TextEditingController _qtyCtrl;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _source = widget.alternatives.first;
    _qtyCtrl = TextEditingController(text: trimQty(_defaultQty, decimals: 3));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  /// What to prefill: enough to unblock the batch, but never more than the
  /// chosen store actually holds.
  double get _defaultQty {
    final needed = widget.neededQty;
    if (needed == null || needed <= 0) return _source.availableQty;
    return needed < _source.availableQty ? needed : _source.availableQty;
  }

  double get _qty => _parse(_qtyCtrl.text);

  static double _parse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;

  String? _validationError(BuildContext context) {
    final l10n = context.l10n;
    // Only ever used to disable the button, so it does not render today — but
    // a field label is not a reason, and the next person to surface this text
    // would be showing "Quantity to move" where an explanation belongs.
    if (_qty <= 0) return l10n.productionQtyMustBePositive;
    if (_qty > _source.availableQty + 1e-9) {
      return l10n.productionMoveTooMuch(
        trimQty(_source.availableQty, decimals: 3),
      );
    }
    return null;
  }

  void _setQty(double value) {
    _qtyCtrl.text = trimQty(value, decimals: 3);
    _qtyCtrl.selection = TextSelection.collapsed(offset: _qtyCtrl.text.length);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final error = _validationError(context);
    final destination = widget.destinationWarehouse ?? '';
    final needed = widget.neededQty;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.getDialogWidth(
              context,
              small: 520,
              medium: 560,
              large: 620,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.productionMoveTitle(
                  widget.itemName.isEmpty ? widget.itemCode : widget.itemName,
                ),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.productionMoveHint,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),

              // Where it goes. Fixed by the recipe, so it is stated rather than
              // offered: this sheet exists to make one specific move easy, not
              // to become a general stock-transfer screen on the floor role.
              if (destination.isNotEmpty)
                _FixedRow(
                  label: l10n.productionMoveToLabel,
                  value: destination,
                  icon: Icons.warehouse_outlined,
                ),

              const SizedBox(height: 10),
              Text(
                l10n.productionMoveFromLabel,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              // One store is the overwhelmingly common case; a list of one
              // radio button is a decision nobody has to make.
              if (widget.alternatives.length == 1)
                _FixedRow(
                  label: '',
                  value: _source.warehouse,
                  trailing: l10n.productionMoveAvailable(
                    trimQty(_source.availableQty, decimals: 3),
                  ),
                  icon: Icons.inventory_2_outlined,
                )
              else
                RadioGroup<String>(
                  groupValue: _source.warehouse,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _source = widget.alternatives.firstWhere(
                        (alternative) => alternative.warehouse == value,
                        orElse: () => _source,
                      );
                    });
                    // The typed quantity was bounded by the old store, so it is
                    // re-derived rather than carried across: leaving it would
                    // show a number this store cannot supply.
                    _setQty(_defaultQty);
                  },
                  child: Column(
                    children: [
                      for (final alternative in widget.alternatives)
                        RadioListTile<String>(
                          value: alternative.warehouse,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(alternative.warehouse),
                          subtitle: Text(
                            l10n.productionMoveAvailable(
                              trimQty(alternative.availableQty, decimals: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 14),
              TextField(
                controller: _qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  const DecimalTextInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: l10n.productionMoveQtyLabel,
                  suffixText: widget.uom.isEmpty ? null : widget.uom,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (needed != null && needed > 0 && needed <= _source.availableQty)
                    ActionChip(
                      label: Text(
                        l10n.productionMoveNeededChip(
                          trimQty(needed, decimals: 3),
                        ),
                      ),
                      onPressed: () => _setQty(needed),
                    ),
                  ActionChip(
                    label: Text(
                      l10n.productionMoveAllChip(
                        trimQty(_source.availableQty, decimals: 3),
                      ),
                    ),
                    onPressed: () => _setQty(_source.availableQty),
                  ),
                ],
              ),

              if (_submitError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _submitError!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.error),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: error != null ? null : _submit,
                      child: Text(l10n.productionMoveConfirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final service = ref.read(manufacturingServiceProvider);

    setState(() => _submitError = null);
    ref.read(loadingOverlayProvider.notifier).show(l10n.productionSubmitting);

    MaterialMoveResult result;
    try {
      result = await service.transferMaterialForProduction(
        itemCode: widget.itemCode,
        fromWarehouse: _source.warehouse,
        qty: _qty,
        toWarehouse: widget.destinationWarehouse,
      );
    } catch (error) {
      if (!mounted) return;
      ref.read(loadingOverlayProvider.notifier).hide();
      // Kept in the sheet rather than thrown at a snackbar behind it: the
      // server's refusal is the only thing that says which number to change.
      setState(() {
        _submitError = context.userErrorMessage(
          error,
          fallback: l10n.commonError,
        );
      });
      return;
    }
    // Guarded before touching ref: the sheet can be dismissed mid-request, and
    // reading a disposed WidgetRef throws.
    if (!mounted) return;
    ref.read(loadingOverlayProvider.notifier).hide();

    // The stock the board is measured against just moved, so every view built
    // on it is stale. The server drops its own cache on the same call.
    ref.invalidate(productionSuggestionsProvider);
    ref.invalidate(basketRollupProvider);

    navigator.pop(result);
  }
}

/// A label/value row for something the operator is being told, not asked.
class _FixedRow extends StatelessWidget {
  const _FixedRow({
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              // Warehouse names are data, not copy: they stay unlocalised, and
              // in an Arabic sentence they are direction-isolated or the bidi
              // algorithm drags the trailing " - J" to the front.
              Directionality.of(context) == TextDirection.rtl
                  ? isolateLtr(value)
                  : value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
