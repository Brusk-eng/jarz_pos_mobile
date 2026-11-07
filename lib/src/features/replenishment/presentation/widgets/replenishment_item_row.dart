import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../data/models/branch_replenishment.dart';
import 'replenishment_format.dart';

/// One item on the van, with the three figures that justify the quantity.
///
/// The quantity is editable because the suggestion is an estimate and the
/// person loading the van can see the van: a screen that only offers "send the
/// computed number" gets overridden on paper, which is how the factory ended
/// up never transferring anything at all.
class ReplenishmentItemRow extends StatefulWidget {
  const ReplenishmentItemRow({
    super.key,
    required this.item,
    required this.initialQty,
    required this.onQtyChanged,
    this.enabled = true,
    this.flagged = false,
  });

  final ReplenishmentItem item;

  /// Read once, at construction. The caller re-keys the row when the plan is
  /// re-fetched, which is what makes a refreshed figure reach the field —
  /// pushing it in on every rebuild would fight the person typing.
  final double initialQty;
  final ValueChanged<double> onQtyChanged;
  final bool enabled;

  /// Whether the last failed send named this line.
  final bool flagged;

  @override
  State<ReplenishmentItemRow> createState() => _ReplenishmentItemRowState();
}

class _ReplenishmentItemRowState extends State<ReplenishmentItemRow> {
  late final TextEditingController _controller = TextEditingController(
    text: trimQty(widget.initialQty),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    // An empty field is zero, not an error: clearing a line is how somebody
    // says "not this one today", and it must not block the Send button.
    final text = raw.trim();
    if (text.isEmpty) {
      widget.onQtyChanged(0);
      return;
    }
    final parsed = double.tryParse(text);
    if (parsed == null) return;
    widget.onQtyChanged(parsed < 0 ? 0 : parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final item = widget.item;

    final cover = item.hasSalesHistory
        ? l10n.replenishmentDaysOfCover(trimQty(item.daysOfCover!, decimals: 1))
        : l10n.replenishmentNoSalesYet;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: widget.flagged ? theme.colorScheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Wrap, not Row: at 360 dp three metrics plus a unit do not
                  // fit on one line, and truncating the daily rate would remove
                  // the only justification the row gives for its quantity.
                  Wrap(
                    spacing: 10,
                    runSpacing: 2,
                    children: [
                      _Metric(
                        text: l10n.replenishmentOnHand(
                          qtyWithUom(item.onHand, item.stockUom),
                        ),
                        emphasis: item.stockIsNegative,
                      ),
                      _Metric(
                        text: l10n.replenishmentPerDay(
                          trimQty(item.sellsPerDay, decimals: 2),
                        ),
                      ),
                      _Metric(text: cover),
                    ],
                  ),
                  if (item.stockIsNegative)
                    _Note(
                      icon: Icons.report_gmailerrorred,
                      text: l10n.replenishmentNegativeStock,
                      color: theme.colorScheme.error,
                    ),
                  if (item.isShort) ...[
                    _Note(
                      icon: Icons.trending_down,
                      text: l10n.replenishmentShortBy(
                        qtyWithUom(item.shortBy, item.stockUom),
                      ),
                      color: theme.colorScheme.tertiary,
                    ),
                    // Which other branch could cover the gap.
                    for (final move in item.moveIn)
                      if (move.qty > 0)
                        _Note(
                          icon: Icons.swap_horiz,
                          text: l10n.replenishmentMoveCanSpare(
                            move.displayFrom,
                            trimQty(move.qty.toDouble()),
                          ),
                          color: theme.colorScheme.tertiary,
                        ),
                    // What the factory actually holds, next to what is
                    // missing: without it the cap on the quantity above looks
                    // arbitrary, and somebody re-types the full suggestion.
                    _Note(
                      icon: Icons.warehouse_outlined,
                      text: l10n.replenishmentFactoryHas(
                        qtyWithUom(item.availableAtSource, item.stockUom),
                      ),
                      color: theme.colorScheme.tertiary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 84,
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                // Centred rather than end-aligned: "end" flips to the left edge
                // under RTL, which puts the digits of a number on the wrong
                // side of their own box.
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.replenishmentQtyLabel,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: _onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.text, this.emphasis = false});

  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: emphasis
            ? theme.colorScheme.error
            : theme.textTheme.bodySmall?.color,
        fontWeight: emphasis ? FontWeight.w700 : null,
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
