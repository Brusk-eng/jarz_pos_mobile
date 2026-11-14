import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../data/models/basket_rollup.dart';
import 'production_format.dart';
import 'stock_elsewhere_note.dart';

/// The consolidated pick list, and the shortages only it can see.
///
/// A material used by three lines is summed once here. The per-line check
/// measured each line against the same available quantity, so a basket could
/// pass line by line and still be short overall — and the submit loop commits
/// per line, so that was discovered only after real stock had been consumed.
///
/// Collapsed by default so the jar rows stay on screen: the header alone says
/// whether the basket is covered. A shortage is never folded away — the short
/// materials stay listed under the header, because they are what blocks Start.
/// Opened, the card holds two sections, each collapsed again: every flavour
/// together (the pick list the store keeper fills) and each flavour on its own
/// (what goes to one bench).
class BasketPickList extends StatefulWidget {
  const BasketPickList({super.key, required this.rollup});

  final BasketRollup rollup;

  @override
  State<BasketPickList> createState() => _BasketPickListState();
}

class _BasketPickListState extends State<BasketPickList> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rollup = widget.rollup;
    final short = [
      for (final component in rollup.components)
        if (component.isShort) component,
    ];
    final flavours = groupRollupByFlavour(
      rollup.components,
      rollup.subassemblies,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: rollup.hasShortages
            ? scheme.errorContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rollup.hasShortages ? scheme.error : Colors.transparent,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  Icon(
                    rollup.hasShortages
                        ? Icons.warning_amber_rounded
                        : Icons.checklist_rtl,
                    color: rollup.hasShortages
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rollup.hasShortages
                              ? l10n.manufacturingInsufficientInventory
                              : l10n.productionIngredientsTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!rollup.hasShortages)
                          Text(
                            l10n.productionPickListOk,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // What blocks Start stays in sight even while the card is folded.
          if (!_open && short.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Column(
                children: [
                  for (final component in short)
                    _PickListRow(component: component),
                ],
              ),
            ),
          if (_open) ...[
            // Opened because of a shortage, the operator lands on it: the
            // consolidated list (with each transfer action) opens with it.
            _Section(
              title: l10n.productionPickListTitle,
              initiallyExpanded: rollup.hasShortages,
              child: Column(
                children: [
                  for (final component in rollup.components)
                    if (shownInPickList(component))
                      _PickListRow(component: component),
                  // Each phantom sub-assembly as its own bowl: its sugar is
                  // never added to the sugar a jar takes for its coffee.
                  for (final sub in rollup.subassemblies)
                    _SubassemblySection(sub: sub, qty: sub.requiredQty),
                ],
              ),
            ),
            _Section(
              title: l10n.productionIngredientsPerFlavour,
              child: Column(
                children: [
                  for (final flavour in flavours)
                    _Section(
                      // Keyed so an open flavour stays open on its own
                      // name when the list above it changes.
                      key: ValueKey(flavour.name),
                      title: flavour.name,
                      dense: true,
                      child: Column(
                        children: [
                          for (final line in flavour.lines)
                            _FlavourLine(line: line),
                          for (final part in flavour.subassemblies)
                            _SubassemblySection(sub: part.sub, qty: part.qty),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

/// A folded section inside the card, closed until tapped.
class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    this.initiallyExpanded = false,
    required this.child,
    this.dense = false,
  });

  final String title;
  final Widget child;
  final bool dense;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      title: Text(
        title,
        style: (dense ? theme.textTheme.bodyMedium : theme.textTheme.titleSmall)
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      tilePadding: EdgeInsetsDirectional.only(start: dense ? 20 : 12, end: 8),
      childrenPadding: EdgeInsetsDirectional.only(
        start: dense ? 20 : 12,
        end: 12,
        bottom: 4,
      ),
      shape: const Border(),
      collapsedShape: const Border(),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [child],
    );
  }
}

/// One material's share for one flavour.
class FlavourIngredient {
  const FlavourIngredient({required this.component, required this.qty});

  final RollupComponent component;
  final double qty;
}

/// Every material one flavour needs, summed over its sizes.
class FlavourIngredients {
  const FlavourIngredients({
    required this.name,
    required this.lines,
    this.subassemblies = const [],
  });

  final String name;
  final List<FlavourIngredient> lines;

  /// This flavour's share of each sub-assembly bowl.
  final List<({RollupSubassembly sub, double qty})> subassemblies;
}

/// What the pick list prints for a material.
///
/// Its direct share when the server split the sub-assemblies out (the coffee's
/// powder sugar, not the mix's); the whole need on a shortage, because that is
/// what the store has to hold; the whole need from an older server.
double pickListQty(RollupComponent component) {
  final direct = component.directQty;
  if (direct == null || component.isShort) return component.requiredQty;
  return direct;
}

/// A material used only inside a sub-assembly is listed under that bowl, not
/// again on its own, unless it is short.
bool shownInPickList(RollupComponent component) =>
    component.isShort ||
    component.directQty == null ||
    component.directQty! > 1e-9;

final _sizeSuffix = RegExp(
  r'\s+(large|medium|small|mini)$',
  caseSensitive: false,
);

/// "Tiramisu Large" -> "Tiramisu": the flavour a jar size belongs to.
String flavourOfItem(String itemCode) {
  final trimmed = itemCode.trim();
  final flavour = trimmed.replaceFirst(_sizeSuffix, '').trim();
  return flavour.isEmpty ? trimmed : flavour;
}

/// The consolidated roll-up split back out per flavour.
///
/// Every component carries the lines that asked for it, so each line's share
/// lands under its flavour (sizes of one flavour summed). Flavours keep the
/// order they first appear in; materials keep the roll-up's order.
List<FlavourIngredients> groupRollupByFlavour(
  List<RollupComponent> components, [
  List<RollupSubassembly> subassemblies = const [],
]) {
  final order = <String>[];
  final byFlavour = <String, Map<String, double>>{};
  final componentByCode = <String, RollupComponent>{};
  for (final component in components) {
    componentByCode[component.itemCode] = component;
    for (final line in component.contributingLines) {
      final flavour = flavourOfItem(line.itemCode);
      if (!byFlavour.containsKey(flavour)) {
        order.add(flavour);
        byFlavour[flavour] = <String, double>{};
      }
      // The share outside any sub-assembly; the mix's part is listed
      // under the mix below.
      final qty = line.directQty ?? line.requiredQty;
      if (qty <= 1e-9) continue;
      final bucket = byFlavour[flavour]!;
      bucket[component.itemCode] = (bucket[component.itemCode] ?? 0) + qty;
    }
  }
  final subsByFlavour = <String, Map<String, double>>{};
  for (final sub in subassemblies) {
    for (final line in sub.contributingLines) {
      final flavour = flavourOfItem(line.itemCode);
      if (!byFlavour.containsKey(flavour)) {
        order.add(flavour);
        byFlavour[flavour] = <String, double>{};
      }
      final bucket = subsByFlavour.putIfAbsent(flavour, () => {});
      bucket[sub.itemCode] = (bucket[sub.itemCode] ?? 0) + line.requiredQty;
    }
  }
  return [
    for (final flavour in order)
      FlavourIngredients(
        name: flavour,
        lines: [
          for (final component in components)
            if (byFlavour[flavour]!.containsKey(component.itemCode))
              FlavourIngredient(
                component: componentByCode[component.itemCode]!,
                qty: byFlavour[flavour]![component.itemCode]!,
              ),
        ],
        subassemblies: [
          for (final sub in subassemblies)
            if (subsByFlavour[flavour]?[sub.itemCode] case final qty?)
              (sub: sub, qty: qty),
        ],
      ),
  ];
}

class _FlavourLine extends StatelessWidget {
  const _FlavourLine({required this.line});

  final FlavourIngredient line;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final component = line.component;
    final name = component.itemName.isNotEmpty
        ? component.itemName
        : component.itemCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: component.isShort ? scheme.error : null,
                  ),
                ),
              ),
              Text(
                l10n.manufacturingComponentRequired(
                  trimQty(line.qty, decimals: 3),
                  component.uom,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One sub-assembly bowl (Cheesecake Mix), folded: its amount on the
/// heading, what goes into it below.
///
/// Kept apart from the pick list's own rows on purpose: the mix's powder
/// sugar is not the powder sugar a jar takes for its coffee, and summing the
/// two would hide which bowl each one goes into.
class _SubassemblySection extends StatelessWidget {
  const _SubassemblySection({required this.sub, required this.qty});

  final RollupSubassembly sub;

  /// The whole basket's need, or one flavour's share of it.
  final double qty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scale = sub.requiredQty > 0 ? qty / sub.requiredQty : 0.0;
    final name = sub.itemName.isNotEmpty ? sub.itemName : sub.itemCode;
    return _Section(
      key: ValueKey('sub-${sub.itemCode}'),
      title:
          '$name · ${l10n.manufacturingComponentRequired(trimQty(qty, decimals: 3), sub.uom)}',
      dense: true,
      child: Column(
        children: [
          for (final line in sub.madeFrom)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      line.itemName.isNotEmpty ? line.itemName : line.itemCode,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    l10n.manufacturingComponentRequired(
                      trimQty(line.requiredQty * scale, decimals: 3),
                      line.uom,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
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

class _PickListRow extends StatelessWidget {
  const _PickListRow({required this.component});

  final RollupComponent component;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.commonNameWithCode(
                    component.itemName,
                    component.itemCode,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                l10n.manufacturingComponentRequired(
                  trimQty(pickListQty(component), decimals: 3),
                  component.uom,
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          // Wrap rather than Row: available + "shared by N lines" + the
          // shortfall is more than a phone width of text once quantities and
          // UOMs are real, and a Row overflowed by 200px.
          Wrap(
            spacing: 10,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.manufacturingComponentAvailable(
                  trimQty(component.availableQty, decimals: 3),
                  component.uom,
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (component.isSharedAcrossLines)
                Text(
                  l10n.productionSharedAcrossLines(
                    component.contributingLines.length,
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              if (component.isMissingWarehouse)
                Text(
                  l10n.productionNoSourceWarehouse,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else if (component.isShort)
                Text(
                  l10n.productionPickListShort(
                    trimQty(component.missingQty, decimals: 3),
                    component.uom,
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          // Only ever under a line that is already short, and only when the
          // backend looked: the shortage above still blocks Start, this says
          // whether the fix is a transfer or a purchase — and, when it is a
          // transfer, makes it.
          if (component.isShort)
            StockElsewhereNote(
              availableElsewhere: component.availableElsewhere,
              alternatives: component.alternatives,
              uom: component.uom,
              itemCode: component.itemCode,
              itemName: component.itemName,
              // The consolidated shortfall for the whole basket, not one line's
              // — this banner rolls the lines up, and moving one line's share
              // would leave the basket blocked on the same component.
              neededQty: component.missingQty,
              destinationWarehouse: component.sourceWarehouse,
            ),
        ],
      ),
    );
  }
}
