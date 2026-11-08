import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../l10n/app_localizations.dart';
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
  bool _expanded = false;

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

  void _bump(double delta) {
    final current = double.tryParse(_controller.text.trim()) ?? 0;
    final next = (current + delta) < 0 ? 0.0 : current + delta;
    _controller.text = trimQty(next);
    widget.onQtyChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final item = widget.item;

    final cover = item.hasSalesHistory
        ? l10n.replenishmentDaysOfCover(trimQty(item.daysOfCover!, decimals: 1))
        : l10n.replenishmentNoSalesYet;
    final meta = [
      l10n.replenishmentOnHand(qtyWithUom(item.onHand, item.stockUom)),
      l10n.replenishmentPerDay(trimQty(item.sellsPerDay, decimals: 2)),
      cover,
    ].join(' · ');
    final hasDetails = item.stockIsNegative || item.isShort;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: widget.flagged ? theme.colorScheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: hasDetails
                        ? () => setState(() => _expanded = !_expanded)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.displayName,
                                  style: theme.textTheme.titleSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.stockIsNegative) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.report_gmailerrorred,
                                  size: 15,
                                  color: theme.colorScheme.error,
                                ),
                              ],
                              if (item.isShort) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.trending_down,
                                  size: 15,
                                  color: theme.colorScheme.tertiary,
                                ),
                              ],
                              if (hasDetails)
                                Icon(
                                  _expanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 16,
                                  semanticLabel: l10n.replenishmentItemDetails,
                                ),
                            ],
                          ),
                          Text(
                            meta,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: item.stockIsNegative
                                  ? theme.colorScheme.error
                                  : theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _stepper(l10n, theme),
              ],
            ),
            if (_expanded && hasDetails)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      // missing: without it the cap on the quantity looks
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
          ],
        ),
      ),
    );
  }

  Widget _stepper(AppLocalizations l10n, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.replenishmentQtyDecrease,
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: widget.enabled ? () => _bump(-1) : null,
        ),
        SizedBox(
          width: 46,
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            // Centred rather than end-aligned: "end" flips to the left edge
            // under RTL, which puts the digits of a number on the wrong side
            // of their own box.
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: theme.textTheme.titleSmall,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              border: OutlineInputBorder(),
            ),
            onChanged: _onChanged,
          ),
        ),
        IconButton(
          tooltip: l10n.replenishmentQtyIncrease,
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: widget.enabled ? () => _bump(1) : null,
        ),
      ],
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
