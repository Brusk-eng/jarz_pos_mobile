import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../data/models/production_suggestion.dart';
import '../../state/plan_board_providers.dart';
import 'production_format.dart';
import 'status_chip.dart';
import 'stock_elsewhere_note.dart';

/// One jar on the merged Plan tab: what the board knows, and what to make.
///
/// The figures were on one tab and the field on another, so deciding a quantity
/// meant remembering a cover number from a screen you had to leave. They are one
/// row now, and the row's arithmetic is still entirely the server's — nobody
/// divides jars by a BOM yield here.
///
/// The suggestion is an OFFER, never a default. A quantity nobody typed must not
/// reach a submit: that already cost this feature a day where 50 were planned,
/// 42 were made, and one un-edited tap booked 50.
class PlanJarRow extends StatefulWidget {
  const PlanJarRow({
    super.key,
    required this.row,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onUseSuggestion,
    this.invalidText,
    this.onInvalidTextChanged,
    this.plannedToday,
    this.onUsePlanned,
    this.isShort = false,
  });

  final PlanRow row;

  /// Jars planned for this flavour. Zero renders as an empty field: a typed 0
  /// and nothing typed at all mean the same thing here, and a field full of
  /// zeroes reads as a form somebody already filled in.
  final int quantity;

  final ValueChanged<int> onQuantityChanged;

  /// Fills the field with the board's suggestion. One tap, visible result.
  final VoidCallback onUseSuggestion;

  /// What the field holds when that is not a whole jar count, or null.
  ///
  /// Kept outside this row, which a scroll, a filter or a tab switch disposes,
  /// so the red entry is still on screen when the row comes back.
  ///
  /// An entry here queues NOTHING. Keeping the last valid number behind a red
  /// field was tried and reviewed out: that number is invisible to every other
  /// reader of the queue — the Today screen, a restart restoring the basket
  /// from Hive — and each of them posted it. The price is that a stray "."
  /// drops the row's line, and with it any alternative material chosen on it;
  /// the material panel shows that plainly and it is one tap to re-pick.
  final String? invalidText;

  /// Reports a new [invalidText], or null once the field is a whole number.
  final ValueChanged<String?>? onInvalidTextChanged;

  /// What the plan already filed for this day says about this flavour, when it
  /// says anything.
  ///
  /// Shown BESIDE the field and never inside it. A saved plan is a target, not
  /// a quantity somebody just typed: poured into the field it would also be
  /// queued, and a run started this morning could then be started again by
  /// re-opening the tab. One tap adopts it, which is the point at which it
  /// becomes an instruction.
  final int? plannedToday;
  final VoidCallback? onUsePlanned;

  /// The consolidated pick list flagged a material this row needs. Only the
  /// roll-up can see it — a material shared by three rows passes every row on
  /// its own and still leaves the day short.
  final bool isShort;

  @override
  State<PlanJarRow> createState() => _PlanJarRowState();
}

class _PlanJarRowState extends State<PlanJarRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.invalidText ?? _textFor(widget.quantity),
    );
  }

  @override
  void didUpdateWidget(covariant PlanJarRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_invalid) {
      // The field holds an entry that is not a jar count, and it queues
      // nothing — the model is 0 BECAUSE of it, so that 0 must not wipe what
      // was typed. Only a real number written from outside ("Use 60", Fill
      // the day) replaces the entry.
      if (widget.quantity > 0 && widget.quantity != oldWidget.quantity) {
        _write(_textFor(widget.quantity));
        final report = widget.onInvalidTextChanged;
        // After the frame: this runs inside the parent's build.
        WidgetsBinding.instance.addPostFrameCallback((_) => report?.call(null));
      }
      return;
    }

    // The entry was dropped from outside (Clear, Cancel plan) while the field
    // still shows it. Once somebody has typed over it there is nothing to undo.
    if (oldWidget.invalidText != null &&
        _controller.text == oldWidget.invalidText) {
      _write(_textFor(widget.quantity));
      return;
    }

    // Only when the model moved and disagrees with what is on screen: rewriting
    // the field on every rebuild would fight the keyboard and move the caret to
    // the end mid-word. This is how the field catches up with "Use 60" and with
    // "Fill the day", which write the model and nothing else.
    if (widget.quantity == oldWidget.quantity) return;
    final shown = int.tryParse(_controller.text) ?? 0;
    if (shown != widget.quantity) _write(_textFor(widget.quantity));
  }

  void _write(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _textFor(int quantity) => quantity > 0 ? '$quantity' : '';

  /// The field holds something that is not a whole jar count.
  ///
  /// A decimal point is let INTO the field on purpose. The old digits-only
  /// filter dropped it silently, so the 1.360 Kg a strawberry mix needed was
  /// typed as "1.360" and read as 1360 jars. Refusing the keystroke would do
  /// the same thing one digit later; showing the field as wrong is the only
  /// version that tells anybody.
  bool get _invalid => widget.invalidText != null;

  static final _wholeNumber = RegExp(r'^[0-9]+$');

  void _onChanged(String text) {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty && !_wholeNumber.hasMatch(trimmed)) {
      widget.onInvalidTextChanged?.call(text);
      widget.onQuantityChanged(0);
      return;
    }
    if (_invalid) widget.onInvalidTextChanged?.call(null);
    widget.onQuantityChanged(int.tryParse(trimmed) ?? 0);
  }

  /// The figures, the code and the full offer are one tap away rather than on
  /// every row. Dozens of these stack up on a phone, and the two numbers a
  /// quantity is actually decided from are cover and what is on hand.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final row = widget.row;
    final suggestion = row.suggestion;

    // Tight vertical padding (owner, 2026-11-14: "the whole card smaller").
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 2, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (suggestion != null) ...[
                      const SizedBox(height: 2),
                      // The offer sits beside the figures rather than under
                      // them: on its own line it cost a whole row per product
                      // for one chip. Expanded, so the figures ellipsize
                      // instead of shoving the chip off a 360 dp Arabic screen.
                      Row(
                        children: [
                          // Flexible, and the chip is NOT: a Row measures its
                          // inflexible children first, so the figures get what
                          // the chip does not need. Both flexible and they
                          // split the column in half, which truncated "-18 on
                          // hand" to "-18 on ..." beside a chip with room to
                          // spare.
                          Flexible(child: _StockLine(suggestion: suggestion)),
                          if (!_expanded &&
                              widget.quantity <= 0 &&
                              suggestion.suggestedBatches > 0) ...[
                            const SizedBox(width: 8),
                            _OfferChip(
                              row: row,
                              suggestion: suggestion,
                              onUse: widget.onUseSuggestion,
                            ),
                          ],
                        ],
                      ),
                    ],
                    // Kept on the closed row on purpose: it is the roll-up's
                    // verdict, it is why Start batches will refuse, and only the
                    // consolidated check can see it.
                    if (_invalid) ...[
                      const SizedBox(height: 4),
                      _InlineWarning(
                        icon: Icons.error_outline,
                        text: l10n.productionPlanWholeJarsOnly,
                        color: scheme.error,
                      ),
                    ],
                    if (widget.isShort) ...[
                      const SizedBox(height: 4),
                      _InlineWarning(
                        icon: Icons.warning_amber_rounded,
                        text: l10n.manufacturingInsufficientInventory,
                        color: scheme.error,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (suggestion != null)
                    ProductionStatusChip(
                      status: suggestion.status,
                      compact: true,
                    ),
                  const SizedBox(height: 4),
                  // 72 dp holds four digits at a phone's text size; the old
                  // 104 dp mostly held empty border. Height stays a 40 dp
                  // touch target.
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9.,٫]')),
                      ],
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(),
                        // The hint carries the unit rather than a floating
                        // label: the Arabic word is longer than this field and
                        // a label would clip, while a hint ellipsizes and gets
                        // out of the way the moment a digit is typed.
                        hintText: l10n.productionPlanQty,
                        // The border only: the sentence is too long for a
                        // 72 dp field and sits under the name instead.
                        errorText: _invalid ? '' : null,
                        errorStyle: const TextStyle(height: 0, fontSize: 0),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 9,
                        ),
                        constraints: const BoxConstraints(minHeight: 40),
                      ),
                      onChanged: _onChanged,
                    ),
                  ),
                  if (widget.plannedToday case final planned?)
                    if (planned > 0 && planned != widget.quantity)
                      TextButton(
                        onPressed: widget.onUsePlanned,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.productionPlannedToday(planned),
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                ],
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                tooltip: l10n.productionRowDetails,
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: scheme.outline,
                ),
              ),
            ],
          ),

          // Open, the offer becomes the whole panel: what caps it, and where
          // the missing material is sitting. Closed, it is the chip above.
          if (_expanded &&
              suggestion != null &&
              suggestion.suggestedBatches > 0) ...[
            const SizedBox(height: 10),
            _SuggestionOffer(
              row: row,
              suggestion: suggestion,
              onUse: widget.onUseSuggestion,
            ),
          ],

          if (_expanded) ...[
            const SizedBox(height: 10),
            _RowDetails(row: row),
            if (suggestion != null && suggestion.stockIsNegative) ...[
              const SizedBox(height: 8),
              _InlineWarning(
                icon: Icons.error_outline,
                // The suggestion ignores the hole on purpose, so the row has to
                // say the stock figure cannot be trusted.
                text: l10n.productionNegativeStock,
                color: scheme.error,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// "0 d · -18 on hand" — the two figures a quantity is decided from.
///
/// Everything else the board knows is real and still reachable behind the
/// caret; it just does not earn a third of the screen on every row.
class _StockLine extends StatelessWidget {
  const _StockLine({required this.suggestion});

  final ProductionSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final cover = suggestion.daysOfCover;
    final negative = suggestion.stockIsNegative;
    // A counting hole beats the cover verdict for colour: every figure on the
    // row was computed as though the hole were zero, so the line is saying
    // something less trustworthy than "critical".
    final colour = negative
        ? scheme.error
        : switch (suggestion.status) {
            ProductionStatus.critical => scheme.error,
            ProductionStatus.low => scheme.tertiary,
            _ => scheme.onSurfaceVariant,
          };
    final coverText = cover == null
        ? l10n.productionCoverUnknown
        : l10n.productionCoverDays(trimQty(cover));

    return Row(
      children: [
        // One Text, not three: three could not ellipsize between themselves,
        // and no caller looking for the line could match any one of them.
        Flexible(
          child: Text(
            '$coverText · '
            '${l10n.productionOnHandValue(trimQty(suggestion.onHand))}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colour,
              fontWeight: negative ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        // A negative Bin is a counting error, not stock owed, and every figure
        // beside it was computed as though the hole were zero. The mark is what
        // stops it reading as an ordinary small number.
        if (negative) ...[
          const SizedBox(width: 4),
          Icon(Icons.error_outline, size: 14, color: scheme.error),
        ],
      ],
    );
  }
}

/// The one-tap offer, reduced to a chip for the closed row.
///
/// A blocked row says so rather than offering a number it cannot make; the
/// reason, and where the material is, live in the panel behind the caret.
class _OfferChip extends StatelessWidget {
  const _OfferChip({
    required this.row,
    required this.suggestion,
    required this.onUse,
  });

  final PlanRow row;
  final ProductionSuggestion suggestion;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (suggestion.achievableBatches <= 0) {
      // Shrink-wrapped and capped rather than an _InlineWarning: this sits as
      // an inflexible child of a Row, so it is handed unbounded width and an
      // Expanded inside it would fail to lay out at all.
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.block, size: 15, color: scheme.error),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Text(
              l10n.manufacturingInsufficientInventory,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final offer = row.suggestedJars;
    if (offer <= 0) return const SizedBox.shrink();

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ActionChip(
        visualDensity: VisualDensity.compact,
        label: Text(l10n.productionUseSuggestion(offer)),
        // A capped offer keeps its own colour, so a smaller-than-suggested
        // number never looks like the full one.
        backgroundColor: suggestion.isCappedByMaterials
            ? scheme.tertiaryContainer
            : null,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: suggestion.isCappedByMaterials
              ? scheme.onTertiaryContainer
              : null,
        ),
        onPressed: onUse,
      ),
    );
  }
}

/// Everything the row knows that is not needed to pick a number.
class _RowDetails extends StatelessWidget {
  const _RowDetails({required this.row});

  final PlanRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final suggestion = row.suggestion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 2,
          children: [
            // Most items here are named by their code, so printing both just
            // renders the same string twice.
            if (row.itemCode != row.itemName)
              Text(
                row.itemCode,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            if (row.jarsPerBatch != null)
              Text(
                // The number the floor already knows by heart. Showing it is
                // how they spot a BOM that has drifted.
                l10n.dailyPlanPerBatch(row.jarsPerBatch!.round()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else if (row.inTemplate)
              Text(
                l10n.dailyPlanNoMix,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        if (suggestion != null) ...[
          const SizedBox(height: 8),
          _Figures(suggestion: suggestion),
        ],
      ],
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// On hand, sells per day, cover, trend — every one of them already computed.
class _Figures extends StatelessWidget {
  const _Figures({required this.suggestion});

  final ProductionSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final cover = suggestion.daysOfCover;
    final coverColor = switch (suggestion.status) {
      ProductionStatus.critical => scheme.error,
      ProductionStatus.low => scheme.tertiary,
      _ => null,
    };

    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        ProductionStat(
          label: l10n.productionOnHand,
          value: trimQty(suggestion.onHand),
          emphasis: suggestion.stockIsNegative ? scheme.error : null,
        ),
        ProductionStat(
          label: l10n.productionSellsPerDay,
          value: trimQty(suggestion.effectiveVelocity),
        ),
        ProductionStat(
          label: l10n.productionCover,
          value: cover == null
              ? l10n.productionCoverUnknown
              : l10n.productionCoverDays(trimQty(cover)),
          emphasis: coverColor,
        ),
        if ((suggestion.velocityTrend ?? '').isNotEmpty)
          ProductionStat(
            label: l10n.productionTrend,
            value: suggestion.velocityTrend!,
          ),
      ],
    );
  }
}

/// "Make 5 batches · 60 Nos to reach 10 days cover", and the tap that fills it
/// in.
class _SuggestionOffer extends StatelessWidget {
  const _SuggestionOffer({
    required this.row,
    required this.suggestion,
    required this.onUse,
  });

  final PlanRow row;
  final ProductionSuggestion suggestion;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final achievable = suggestion.achievableBatches;
    final capped = suggestion.isCappedByMaterials;
    final blocked = achievable <= 0;
    final offer = row.suggestedJars;

    // A shortage names the component that caused it and offers the achievable
    // number, rather than presenting a red wall with no way forward.
    final limiter = suggestion.limitingComponent;
    final limiterLabel = limiter == null
        ? ''
        : (limiter.itemName.isEmpty ? limiter.itemCode : limiter.itemName);

    final why = capped && limiter != null
        ? l10n.productionCappedBy(
            achievable,
            limiterLabel,
            suggestion.suggestedBatches,
          )
        : l10n.productionReachCover(suggestion.targetDays);

    // A blocked line must not headline "Make 6 batches" over a subtitle saying
    // it is capped at zero — the two read as a contradiction.
    final headline = blocked
        ? (limiter == null
              ? l10n.manufacturingInsufficientInventory
              : (limiter.isMissingWarehouse
                    ? l10n.productionNoSourceWarehouse
                    : l10n.productionCannotStart(limiterLabel)))
        : (suggestion.bomQty == 1
              // One BOM makes one unit, so "5 batches · 5 Nos" is the same
              // number printed twice.
              ? l10n.productionMakeUnits(
                  trimQty(achievable * suggestion.bomQty),
                  suggestion.stockUom,
                )
              : l10n.productionMakeBatches(
                  achievable,
                  trimQty(achievable * suggestion.bomQty),
                  suggestion.stockUom,
                ));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: capped
            ? scheme.tertiaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      // Wrap rather than Row: the Arabic headline runs long and the offer
      // button beside it overflows a 360 dp screen.
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: blocked ? scheme.error : null,
                  ),
                ),
                if (!blocked)
                  Text(
                    why,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                // The backend only fills these for an item that cannot make a
                // single batch, so this lands on the blocked row. Filling the
                // field does not authorize production: the footer still checks
                // the consolidated stock before Start batches.
                if (limiter != null)
                  StockElsewhereNote(
                    availableElsewhere: limiter.availableElsewhere,
                    alternatives: limiter.alternatives,
                    uom: limiter.uom,
                    itemCode: limiter.itemCode,
                    itemName: limiter.itemName,
                    // One batch's worth of shortfall: what it takes to stop
                    // this row saying "Cannot start". The sheet offers "move
                    // all" beside it for the operator who wants the lot.
                    neededQty: limiter.requiredQty - limiter.availableQty,
                    destinationWarehouse: limiter.sourceWarehouse,
                  ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: offer <= 0 ? null : onUse,
            child: Text(l10n.productionUseSuggestion(offer)),
          ),
        ],
      ),
    );
  }
}
