import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/recipe_book_models.dart';
import '../../domain/recipe_scaling.dart';
import '../recipe_book_strings.dart';

/// The colour a figure takes when it differs from its ×1 value.
Color recipeScaledColor(BuildContext context) =>
    Theme.of(context).colorScheme.primary;

/// The sticky bar under the recipe header: the factor and the batch it makes,
/// quick factors, and Reset.
class RecipeScaleBar extends StatelessWidget {
  const RecipeScaleBar({
    super.key,
    required this.factor,
    required this.batchYield,
    required this.showHint,
    required this.onFactor,
    required this.onEditBatch,
  });

  final double factor;
  final RecipeYield batchYield;
  final bool showHint;
  final ValueChanged<double> onFactor;

  /// Opens the "batch size" sheet; null when the yield is unknown.
  final VoidCallback? onEditBatch;

  static const _quick = <double>[0.5, 1, 2, 3];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = RecipeBookStrings.of(context);
    final scaled = isScaled(factor);
    final batchText = formatYieldAt(batchYield, factor);
    final label = [
      formatFactor(factor),
      batchText == null ? s.oneBatch : s.batch(batchText),
    ].join(' · ');
    final labelStyle = theme.textTheme.titleSmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      color: scaled ? recipeScaledColor(context) : null,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.scale_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: InkWell(
                    key: const ValueKey('recipe-scale-batch'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: onEditBatch,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style: labelStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onEditBatch != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (scaled)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => onFactor(1),
                  child: Text(s.reset),
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final quick in _quick)
                ChoiceChip(
                  label: Text(formatFactor(quick)),
                  selected: (factor - quick).abs() < 1e-9,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => onFactor(quick),
                ),
            ],
          ),
          if (showHint)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.scaleHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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

/// Asks for an amount in [unit] and answers the factor it implies:
/// `entered ÷ baseAmount`. Used for "how much X do you have?" and for a target
/// batch size. Null when dismissed.
Future<double?> showRecipeScaleSheet(
  BuildContext context, {
  required String title,
  required String unit,
  required double baseAmount,
  required double currentFactor,
  required RecipeYield batchYield,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _RecipeScaleSheet(
      title: title,
      unit: unit,
      baseAmount: baseAmount,
      currentFactor: currentFactor,
      batchYield: batchYield,
    ),
  );
}

class _RecipeScaleSheet extends StatefulWidget {
  const _RecipeScaleSheet({
    required this.title,
    required this.unit,
    required this.baseAmount,
    required this.currentFactor,
    required this.batchYield,
  });

  final String title;
  final String unit;
  final double baseAmount;
  final double currentFactor;
  final RecipeYield batchYield;

  @override
  State<_RecipeScaleSheet> createState() => _RecipeScaleSheetState();
}

class _RecipeScaleSheetState extends State<_RecipeScaleSheet> {
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _factor =>
      factorFromIngredient(parseAmount(_controller.text), widget.baseAmount);

  void _apply() {
    final factor = _factor;
    if (factor == null) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(factor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = RecipeBookStrings.of(context);
    final factor = _factor;
    final current = formatIngredientAmount(
      widget.baseAmount * widget.currentFactor,
      widget.unit,
    );
    String? preview;
    if (factor != null) {
      final batch = formatYieldAt(widget.batchYield, factor);
      preview = [
        s.recipeTimes(formatFactor(factor)),
        if (batch != null) s.previewBatch(batch),
      ].join(' · ');
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('recipe-scale-input'),
                controller: _controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,٫٬]')),
                ],
                textInputAction: TextInputAction.done,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  hintText: current,
                  suffixText: displayUnit(widget.unit),
                  errorText: _showError && factor == null
                      ? s.enterAmount
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _apply(),
              ),
              const SizedBox(height: 10),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: preview == null ? 0 : 1,
                child: Text(
                  preview ?? ' ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: recipeScaledColor(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(s.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('recipe-scale-apply'),
                      onPressed: _apply,
                      child: Text(s.apply),
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
}
