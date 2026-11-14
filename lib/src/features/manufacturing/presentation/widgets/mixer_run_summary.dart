import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../data/models/daily_plan.dart';

/// The answer the morning screen owes the floor: how many mixes, and how to
/// split them.
///
/// Pinned rather than scrolled to, because it changes on every jar entered and
/// is the only reason this screen exists. Each run carries its quality — a plan
/// that quietly schedules the sizes the mixer handles badly would look
/// identical to a good one otherwise.
///
/// Folded by default to one line (jars, and the run split in short) under a
/// grab handle: swipe up, or tap, to open the full split; swipe down to fold it
/// again. The jar list above gets the screen back while the floor types.
class MixerRunSummary extends StatefulWidget {
  const MixerRunSummary({
    super.key,
    required this.preview,
    required this.calculating,
    required this.mixUom,
    required this.totalJars,
    this.onSave,
    this.onCheckMaterials,
    this.onCancelPlan,
    this.showActions = true,
    this.totalLabel,
    this.emptyHint,
    this.initiallyExpanded = false,
  });

  final DailyPlanPreview? preview;
  final bool calculating;
  final String mixUom;
  final int totalJars;
  final VoidCallback? onSave;
  final VoidCallback? onCheckMaterials;

  /// Calls off a plan that was already saved for this day. Null when there is
  /// nothing saved yet -- there is no plan to call off before one exists.
  final VoidCallback? onCancelPlan;

  /// Whether this bar carries its own buttons.
  ///
  /// False on the Today screen, which owns one primary action for the whole
  /// day and must not sit above three greyed-out buttons for actions it does
  /// not offer. The split itself -- the only reason this widget exists -- is
  /// identical either way, which is why it is reused rather than re-drawn.
  final bool showActions;

  /// The two lines whose tense differs between the screens sharing this bar.
  ///
  /// The Daily tab is a morning intention, so "jars planned" and "how many jars
  /// you plan to fill" are right there. The Today screen books what came out of
  /// the oven, and a bar reading "plan to fill" under a field labelled "how many
  /// jars came out" is exactly the kind of contradiction that made the old board
  /// hard to trust. Null keeps the morning wording.
  final String? totalLabel;
  final String? emptyHint;

  /// Opens the panel on first build; the operator folds it from there.
  final bool initiallyExpanded;

  @override
  State<MixerRunSummary> createState() => _MixerRunSummaryState();

  /// Trims the trailing zeros a Float carries so "2" does not read as "2.000".
  static String _fmt(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    final text = value.toStringAsFixed(3);
    return text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _MixerRunSummaryState extends State<MixerRunSummary> {
  late bool _open = widget.initiallyExpanded;

  void _set(bool open) {
    if (open != _open) setState(() => _open = open);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -80) {
      _set(true);
    } else if (velocity > 80) {
      _set(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final data = widget.preview;
    final hasShortages =
        data?.materials != null && data!.materials!.shortages.isNotEmpty;
    final runsInShort = data == null || data.runs.isEmpty
        ? null
        : data.runs.map((run) => MixerRunSummary._fmt(run.size)).join(' + ');

    // A hairline, not an elevation. This bar is pinned at the bottom of a
    // column rather than floating over the list, so `elevation: 8` had nothing
    // to cast onto and the shadow rendered as a hard black strip the full
    // width of the screen — visible on both the Plan tab and Today, in the
    // goldens and on a device. A top border says "different surface" without
    // pretending the bar is lifted off anything.
    return Material(
      color: scheme.surfaceContainerHigh,
      shape: Border(top: BorderSide(color: scheme.outlineVariant)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The grab area: swipe up to open, down to fold, tap to toggle.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _set(!_open),
                  onVerticalDragEnd: _onDragEnd,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: scheme.outline.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.totalLabel ??
                                    l10n.dailyPlanTotalJars(widget.totalJars),
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                            if (widget.calculating)
                              const Padding(
                                padding: EdgeInsetsDirectional.only(end: 8),
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            if (!_open && hasShortages)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 6,
                                ),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  size: 18,
                                  color: scheme.error,
                                ),
                              ),
                            if (!_open && runsInShort != null)
                              Text(
                                runsInShort,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                              ),
                            Icon(
                              _open ? Icons.expand_more : Icons.expand_less,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_open) ...[
                  const SizedBox(height: 8),
                  if (data == null)
                    Text(
                      widget.emptyHint ?? l10n.dailyPlanEnterQuantities,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  else ...[
                    Text(
                      l10n.dailyPlanMixTotal(
                        MixerRunSummary._fmt(data.totalMixQty),
                        widget.mixUom,
                        MixerRunSummary._fmt(data.requiredBatches),
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    if (data.runs.isEmpty)
                      Text(
                        l10n.dailyPlanNoRuns,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final run in data.runs) _RunChip(run: run),
                        ],
                      ),
                    if (data.overproductionBatches > 0.001) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.dailyPlanSpareMix(
                          MixerRunSummary._fmt(data.overproductionBatches),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.tertiary,
                        ),
                      ),
                    ],
                    if (data.materials?.unavailable == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.dailyPlanMaterialsUnavailable,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ] else if (hasShortages) ...[
                      const SizedBox(height: 8),
                      _ShortageList(shortages: data.materials!.shortages),
                    ],
                  ],
                ],
                if (widget.showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onCheckMaterials,
                          icon: const Icon(
                            Icons.inventory_2_outlined,
                            size: 18,
                          ),
                          label: Text(l10n.dailyPlanCheckMaterials),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: widget.onSave,
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: Text(l10n.dailyPlanSave),
                        ),
                      ),
                    ],
                  ),
                ],
                if (widget.showActions && widget.onCancelPlan != null)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: widget.onCancelPlan,
                      icon: const Icon(Icons.event_busy_outlined, size: 18),
                      label: Text(l10n.productionPlanCancel),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RunChip extends StatelessWidget {
  const _RunChip({required this.run});

  final MixerRun run;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final (colour, label) = switch (run.quality) {
      RunQuality.preferred => (scheme.primary, l10n.dailyPlanRunPreferred),
      RunQuality.acceptable => (scheme.tertiary, l10n.dailyPlanRunAcceptable),
      RunQuality.poor => (scheme.error, l10n.dailyPlanRunPoor),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colour.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MixerRunSummary._fmt(run.size),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colour,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colour),
          ),
        ],
      ),
    );
  }
}

class _ShortageList extends StatelessWidget {
  const _ShortageList({required this.shortages});

  final List<MaterialShortage> shortages;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dailyPlanShortages(shortages.length),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Only the worst few: the roll-up can list dozens of components and this
        // bar has to stay a summary.
        for (final shortage in shortages.take(3))
          Text(
            l10n.dailyPlanShortageLine(
              shortage.itemName.isNotEmpty
                  ? shortage.itemName
                  : shortage.itemCode,
              MixerRunSummary._fmt(shortage.missingQty),
              shortage.uom,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (shortages.length > 3)
          Text(
            l10n.dailyPlanShortagesMore(shortages.length - 3),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }
}
