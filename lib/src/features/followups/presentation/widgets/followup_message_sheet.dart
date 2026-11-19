import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../data/models/followup_models.dart';
import 'followup_results_common.dart';

const String _timePattern = 'MMM d • h:mm a';

/// Everything about one sent message: the replies in full, every order that
/// followed, the code and why a send failed.
///
/// [onShowCustomer] is called with the customer's name when the manager asks
/// for all messages to the same customer; the caller applies the filter.
Future<void> showFollowupMessageSheet(
  BuildContext context, {
  required FollowupSentItem item,
  required String currency,
  required ValueChanged<String> onShowCustomer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (sheetContext) => _MessageSheet(
      item: item,
      currency: currency,
      onShowCustomer: (name) {
        Navigator.of(sheetContext).pop();
        onShowCustomer(name);
      },
    ),
  );
}

class _MessageSheet extends StatelessWidget {
  const _MessageSheet({
    required this.item,
    required this.currency,
    required this.onShowCustomer,
  });

  final FollowupSentItem item;
  final String currency;
  final ValueChanged<String> onShowCustomer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final extraReplies = item.replyCount - item.replies.length;

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(
        20,
        0,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
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
                      item.customerName.isEmpty
                          ? item.customer
                          : item.customerName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (item.phone.isNotEmpty)
                      followupPhoneText(
                        context,
                        item.phone,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        followupResultsStepLabel(context, item.step),
                        formatDateString(
                          context,
                          item.sentAt,
                          pattern: _timePattern,
                        ),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ResultsPill(
                label: followupWaStatusLabel(context, item.waStatus),
                color: followupWaStatusColor(theme, item.waStatus),
              ),
            ],
          ),
          if (item.error.isNotEmpty) ...[
            heading(l10n.followupResultsSheetError),
            Text(item.error, style: TextStyle(color: scheme.error)),
          ],
          if (item.hasCode) ...[
            heading(l10n.followupResultsSheetCode),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SelectableText(
                  item.offerCode,
                  textDirection: TextDirection.ltr,
                  style: tabularFigures(
                    theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (item.tier.isNotEmpty)
                  ResultsPill(
                    label: followupTierLabel(context, item.tier),
                    color: scheme.secondary,
                  ),
                if (item.codeStatus.isNotEmpty)
                  ResultsPill(
                    label: followupCodeStatusLabel(context, item.codeStatus),
                    color: followupCodeStatusColor(theme, item.codeStatus),
                    icon: item.codeUsed ? Icons.check_circle_outline : null,
                  ),
              ],
            ),
            if (item.codeDiscount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.followupResultsSheetDiscount(
                    followupMoneyText(
                      context,
                      item.codeDiscount,
                      currency: currency,
                    ),
                  ),
                  style: tabularFigures(theme.textTheme.bodyMedium),
                ),
              ),
          ],
          heading(l10n.followupResultsSheetReplies),
          if (item.replies.isEmpty && !item.replied)
            Text(
              l10n.followupResultsSheetNoReplies,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          for (final r in item.replies) FollowupReplyBubble(reply: r),
          if (extraReplies > 0)
            Text(
              l10n.followupResultsSheetMoreReplies(
                formatCount(context, extraReplies),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          heading(l10n.followupResultsSheetOrders),
          if (item.orders.isEmpty)
            Text(
              l10n.followupResultsSheetNoOrders,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          for (final o in item.orders)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: FollowupOrderLine(order: o, currency: currency),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => onShowCustomer(
                item.customerName.isEmpty ? item.customer : item.customerName,
              ),
              icon: const Icon(Icons.search),
              label: Text(l10n.followupResultsSheetAllMessages),
            ),
          ),
        ],
      ),
    );
  }
}

/// One inbound message as a chat bubble, with its time and a Stop flag.
class FollowupReplyBubble extends StatelessWidget {
  const FollowupReplyBubble({super.key, required this.reply});

  final FollowupSentReply reply;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = reply.isStop
        ? scheme.errorContainer
        : scheme.secondaryContainer;
    final onColor = reply.isStop
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reply.isStop)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block, size: 14, color: onColor),
                    const SizedBox(width: 4),
                    Text(
                      l10n.followupResultsStopReply,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: onColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              followupReplyText(context, reply),
              style: theme.textTheme.bodyMedium?.copyWith(color: onColor),
            ),
            const SizedBox(height: 2),
            Text(
              formatDateString(context, reply.at, pattern: _timePattern),
              style: theme.textTheme.labelSmall?.copyWith(
                color: onColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An order as one line: number, time, amount, and the used-code mark.
class FollowupOrderLine extends StatelessWidget {
  const FollowupOrderLine({
    super.key,
    required this.order,
    required this.currency,
  });

  final FollowupSentOrder order;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    order.wooOrderId.isNotEmpty
                        ? l10n.followupsWooOrder(order.wooOrderId)
                        : order.invoice,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (order.usedCode)
                    ResultsPill(
                      label: l10n.followupResultsOutcomeUsedCode,
                      color: Colors.green.shade700,
                      icon: Icons.check_circle_outline,
                    ),
                ],
              ),
              Text(
                formatDateString(context, order.at, pattern: _timePattern),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          followupMoneyText(context, order.grandTotal, currency: currency),
          textDirection: TextDirection.ltr,
          style: tabularFigures(
            theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
