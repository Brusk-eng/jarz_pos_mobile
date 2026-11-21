import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../data/stock_handover_models.dart';
import 'handover_carton_plan.dart';
import 'handover_format.dart';

/// One handover: who → who, who declared it and when, its lines, and the
/// actions the server says this user may take on it.
class StockHandoverCard extends StatelessWidget {
  const StockHandoverCard({
    super.key,
    required this.handover,
    this.onConfirm,
    this.onChange,
    this.onReject,
    this.onCancel,
    this.busy = false,
    this.handled = false,
    this.highlight = false,
  });

  final StockHandover handover;
  final VoidCallback? onConfirm;
  final VoidCallback? onChange;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final bool busy;

  /// An action on this card already succeeded and the refreshed list has not
  /// arrived yet: keep the actions hidden so it cannot be answered twice.
  final bool handled;

  /// Draw it as the thing waiting for this user.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final h = handover;
    final showRespond = h.isPending && h.canRespond && !handled;
    final showCancel = h.isPending && h.canCancel && !handled;
    // A "sent out" batch is matched by a manager as a whole; the only single
    // action on it is to reject it.
    final rejectOnly = h.isDispatch;
    final proposedByOther = h.lastProposedByName.isNotEmpty &&
        h.lastProposedByName != h.declaredByName;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: highlight ? 2 : 0,
      color: highlight
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlight
            ? BorderSide(color: theme.colorScheme.primary, width: 1.2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    h.isDispatch
                        ? l10n.stockHandoverDispatchTitle(h.fromLabel)
                        : l10n.stockHandoverRoute(
                            h.isUnsourced
                                ? l10n.stockHandoverUnknownSenderLabel
                                : h.fromLabel,
                            h.toLabel,
                          ),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                _StatusChip(handover: h),
              ],
            ),
            const SizedBox(height: 4),
            if (h.declaredByName.isNotEmpty)
              Text(
                l10n.stockHandoverDeclaredBy(
                  h.declaredByName,
                  handoverTime(context, h.declaredAt),
                ),
                style: theme.textTheme.bodySmall,
              ),
            if (h.changed && proposedByOther)
              Text(
                l10n.stockHandoverChangedBy(
                  h.lastProposedByName,
                  handoverTime(context, h.lastProposedAt),
                ),
                style: theme.textTheme.bodySmall,
              ),
            // Sends, unsourced receipts and receipts in the transit pool all
            // wait for a manager to match them, not for a branch.
            if (h.isPending &&
                (h.isDispatch || h.inGroup || h.isUnsourced || h.awaitsManager))
              Text(
                h.isDispatch
                    ? l10n.stockHandoverDispatchWaiting
                    : l10n.stockHandoverGroupWaiting,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              )
            else if (h.isPending && h.awaitingLabel.isNotEmpty && !showRespond)
              Text(
                l10n.stockHandoverAwaiting(h.awaitingLabel),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            const Divider(height: 16),
            // Only while it waits to be received: the recent list stays compact.
            if (h.cartonPlan != null && h.isPending) ...[
              HandoverCartonPlanCard(
                handoverName: h.name,
                plan: h.cartonPlan!,
              ),
              const Divider(height: 16),
            ],
            for (final line in h.items) _LineRow(line: line, showDeclared: h.changed),
            if (h.isRejected && (h.rejectReason ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.stockHandoverReason(h.rejectReason!),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            if (h.isConfirmed && (h.stockEntry ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.stockHandoverEntry(handoverLtr(h.stockEntry!)),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
            if (showRespond || showCancel) ...[
              const SizedBox(height: 8),
              if (busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    if (showCancel)
                      TextButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.close),
                        label: Text(l10n.stockHandoverCancel),
                      ),
                    if (showRespond) ...[
                      TextButton.icon(
                        onPressed: onReject,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        icon: const Icon(Icons.block),
                        label: Text(l10n.stockHandoverReject),
                      ),
                      if (!rejectOnly) ...[
                        OutlinedButton.icon(
                          onPressed: onChange,
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(l10n.stockHandoverChange),
                        ),
                        FilledButton.icon(
                          onPressed: onConfirm,
                          icon: const Icon(Icons.check),
                          label: Text(l10n.stockHandoverConfirm),
                        ),
                      ],
                    ],
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.showDeclared});

  final StockHandoverLine line;
  final bool showDeclared;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final differs = showDeclared && line.isChanged;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              line.itemName,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (differs) ...[
            Text(
              handoverQty(line.declaredQty),
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            handoverQty(line.qty),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: differs ? theme.colorScheme.tertiary : null,
            ),
          ),
          if (line.stockUom.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              line.stockUom,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.handover});

  final StockHandover handover;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final h = handover;
    final (String label, Color color) = switch (h.status) {
      'Confirmed' => (l10n.stockHandoverStatusConfirmed, Colors.green.shade700),
      'Rejected' => (l10n.stockHandoverStatusRejected, theme.colorScheme.error),
      'Cancelled' => (l10n.stockHandoverStatusCancelled, theme.colorScheme.outline),
      _ => h.changed
          ? (l10n.stockHandoverChangedBadge, theme.colorScheme.tertiary)
          : (l10n.stockHandoverStatusPending, Colors.orange.shade800),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
