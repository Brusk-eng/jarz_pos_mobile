import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/models/base_item.dart';
import '../../data/models/recipe_sheet.dart';
import '../../domain/recipe_text.dart';
import '../../state/base_production_providers.dart';
import '../../state/recipe_sheet_providers.dart';
import 'production_format.dart';

/// Which screen's request a [RecipeSheetSection] follows.
enum _RecipeSheetSource { jars, bases }

/// The recipe for every SOP jar typed on the screen, inline.
///
/// The default constructor watches [recipeSheetProvider], which follows the
/// day's jar draft; [RecipeSheetSection.bases] watches
/// [baseRecipeSheetProvider], which follows the ticked rows on the Bases tab.
/// Renders nothing until something with a recipe is asked for; a thin bar on
/// the first load only (a refresh keeps the previous sheet up, so it does not
/// blink while a count settles); one compact line with Retry when the sheet
/// will not load.
class RecipeSheetSection extends ConsumerWidget {
  const RecipeSheetSection({super.key, this.padding = EdgeInsets.zero})
    : _source = _RecipeSheetSource.jars;

  /// The Bases tab: one sheet per ticked base, its amount read in the base's
  /// stock UOM ("12.5 Kg") rather than as a jar count.
  const RecipeSheetSection.bases({super.key, this.padding = EdgeInsets.zero})
    : _source = _RecipeSheetSource.bases;

  final _RecipeSheetSource _source;

  /// Applied only when something is shown, so an empty section leaves the
  /// screen's spacing exactly as it was.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = _content(context, ref);
    if (child == null) return const SizedBox.shrink();
    return Padding(padding: padding, child: child);
  }

  Widget? _content(BuildContext context, WidgetRef ref) {
    final bases = _source == _RecipeSheetSource.bases;
    // Checked first, synchronously: with nothing to ask for there is not even
    // a frame of progress bar.
    final nothingAsked = bases
        ? ref.watch(baseRecipeSheetLinesProvider).isEmpty
        : ref.watch(recipeSheetJarsProvider).isEmpty;
    if (nothingAsked) return null;

    final sheetProvider = bases ? baseRecipeSheetProvider : recipeSheetProvider;
    final async = ref.watch(sheetProvider);
    final previous = async.hasError ? null : async.valueOrNull;

    if (async.isLoading && (previous == null || previous.isEmpty)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    if (async.hasError && !async.isLoading) {
      return _RecipeSheetError(
        message: context.userErrorMessage(
          async.error,
          fallback: context.l10n.commonError,
        ),
        onRetry: () => ref.invalidate(sheetProvider),
      );
    }

    final response = previous;
    if (response == null || response.isEmpty) return null;

    // A base is measured in its own stock UOM, which the Bases tab has already
    // loaded. A base missing from that list still shows its number, unitless.
    final uomByItem = bases
        ? <String, String>{
            for (final item
                in ref.watch(baseItemsProvider).valueOrNull?.items ??
                    const <BaseItem>[])
              item.itemCode: item.stockUom,
          }
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < response.sheets.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          RecipeSheetCard(
            // Keyed so an open card stays open, and on its own recipe, when
            // a count above adds or drops another sheet.
            key: ValueKey(response.sheets[i].title),
            sheet: response.sheets[i],
            uomByItem: uomByItem,
          ),
        ],
      ],
    );
  }
}

class _RecipeSheetError extends StatelessWidget {
  const _RecipeSheetError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.menu_book_outlined, size: 18, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
        ],
      ),
    );
  }
}

/// One recipe family (e.g. Tiramisu) for every size being made together.
///
/// Read off a kitchen tablet at arm's length, so the numbers are the loudest
/// thing on it: run totals per ingredient, then the method, with each size's
/// per-jar portion on its own line.
///
/// Folded by default to its title and run line, so a screen with several
/// recipes stays a list of headings; a tap opens the ingredients and method.
class RecipeSheetCard extends StatefulWidget {
  const RecipeSheetCard({
    super.key,
    required this.sheet,
    this.uomByItem,
    this.initiallyExpanded = false,
  });

  final RecipeSheet sheet;

  /// Opens the card on first build; the operator folds it from there.
  final bool initiallyExpanded;

  /// Null for a jar sheet: "For 22 jars · 10 × Large".
  ///
  /// Set for a base sheet, where the amounts are weights rather than counts:
  /// each one reads as a quantity in its item's stock UOM ("12.5 Kg"), looked
  /// up here by item code. An item missing from the map shows its number alone.
  final Map<String, String>? uomByItem;

  @override
  State<RecipeSheetCard> createState() => _RecipeSheetCardState();
}

class _RecipeSheetCardState extends State<RecipeSheetCard> {
  late bool _open = widget.initiallyExpanded;

  RecipeSheet get sheet => widget.sheet;
  Map<String, String>? get uomByItem => widget.uomByItem;

  /// "12.5 Kg": the same `{quantity} {uom}` string the Bases rows use, so no
  /// new translation is needed.
  String _measured(BuildContext context, double qty, String itemCode) {
    final uom = uomByItem?[itemCode] ?? '';
    return context.l10n.basesQtyValue(trimQty(qty, decimals: 3), uom).trim();
  }

  /// The run's amount, then each item in it.
  ///
  /// A base sheet is usually one base under its own name, so it is not
  /// repeated as "12.5 Kg · Fudge Cake" beneath a title that already says so.
  List<InlineSpan> _amountSpans(BuildContext context, TextStyle bold) {
    final l10n = context.l10n;
    if (uomByItem == null) {
      return [
        TextSpan(
          text: l10n.sopForJars(formatRecipeCount(sheet.totalQty)),
          style: bold,
        ),
        for (final item in sheet.items) ...[
          const TextSpan(text: '  ·  '),
          TextSpan(text: '${formatRecipeCount(item.qty)} × ', style: bold),
          TextSpan(text: shortSizeName(item.displayName, sheet.title)),
        ],
      ];
    }

    final leadCode = sheet.items.isEmpty ? '' : sheet.items.first.itemCode;
    final onlyItemIsTitle =
        sheet.items.length == 1 &&
        sheet.items.first.displayName.trim().toLowerCase() ==
            sheet.title.trim().toLowerCase();
    return [
      TextSpan(text: _measured(context, sheet.totalQty, leadCode), style: bold),
      if (!onlyItemIsTitle)
        for (final item in sheet.items) ...[
          const TextSpan(text: '  ·  '),
          TextSpan(
            text: '${_measured(context, item.qty, item.itemCode)} ',
            style: bold,
          ),
          TextSpan(text: shortSizeName(item.displayName, sheet.title)),
        ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    const bold = TextStyle(fontWeight: FontWeight.w700);

    final title = sheet.title.isEmpty
        ? l10n.sopTitle
        : '${sheet.title} · ${l10n.sopTitle}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        color: scheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        _open ? Icons.expand_less : Icons.expand_more,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(children: _amountSpans(context, bold)),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (_open && sheet.ingredients.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ingredient in sheet.ingredients)
                    _IngredientPill(ingredient: ingredient),
                ],
              ),
            ],
            if (_open && sheet.steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 4),
              for (var i = 0; i < sheet.steps.length; i++)
                _StepTile(
                  step: sheet.steps[i],
                  number: sheet.steps[i].stepNo > 0
                      ? sheet.steps[i].stepNo
                      : i + 1,
                  sheetTitle: sheet.title,
                  arabic: arabic,
                ),
            ],
            if (_open && sheet.unresolvedTokens.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.sopUnresolvedTokens(sheet.unresolvedTokens.length),
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IngredientPill extends StatelessWidget {
  const _IngredientPill({required this.ingredient});

  final RecipeSheetIngredient ingredient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final amount = ingredient.display.isNotEmpty
        ? ingredient.display
        : [
            formatRecipeCount(ingredient.qty),
            ingredient.uom,
          ].where((s) => s.isNotEmpty).join(' ');

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${ingredient.displayName}  '),
            TextSpan(
              text: amount,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.step,
    required this.number,
    required this.sheetTitle,
    required this.arabic,
  });

  final RecipeSheetStep step;
  final int number;
  final String sheetTitle;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final body = theme.textTheme.bodyLarge;
    final titleLines = recipeLinesForLocale(step.title, arabic: arabic);
    final textLines = recipeLinesForLocale(step.text, arabic: arabic);
    final perItem = step.perItem ?? const <RecipeSheetStepLine>[];

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: AlignmentDirectional.center,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titleLines.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 3),
                    child: Text(
                      titleLines.join(' · '),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                for (final line in textLines)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 3),
                    child: _RecipeLine(line: line, style: body),
                  ),
                for (final line in perItem)
                  _PerSizeLine(
                    size: shortSizeName(line.displayName, sheetTitle),
                    lines: recipeLinesForLocale(line.text, arabic: arabic),
                    style: body,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One size's portion: the size in bold, then its per-jar figures.
class _PerSizeLine extends StatelessWidget {
  const _PerSizeLine({
    required this.size,
    required this.lines,
    required this.style,
  });

  final String size;
  final List<String> lines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$size: ',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
            for (var i = 0; i < lines.length; i++) ...[
              if (i > 0) const TextSpan(text: '\n'),
              ..._quantitySpans(lines[i]),
            ],
          ],
        ),
        style: style,
      ),
    );
  }
}

class _RecipeLine extends StatelessWidget {
  const _RecipeLine({required this.line, required this.style});

  final String line;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(children: _quantitySpans(line)), style: style);
  }
}

/// [line] with every weight/volume figure in bold.
List<InlineSpan> _quantitySpans(String line) => [
  for (final (text, isQuantity) in splitRecipeQuantities(line))
    TextSpan(
      text: text,
      style: isQuantity ? const TextStyle(fontWeight: FontWeight.w800) : null,
    ),
];
