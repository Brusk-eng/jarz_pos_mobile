import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/utils/order_display_id.dart';
import '../../data/models/promo_lookup_models.dart';
import 'promo_code_parts.dart';

// The helpers moved to promo_code_parts.dart; re-exported so existing
// imports of this file keep working.
export 'promo_code_parts.dart' show promoOfferText, promoStatusLabel;

/// Everything one lookup answered: not-found, or the code card, its recent
/// uses and the order check.
class PromoLookupResultView extends StatelessWidget {
  const PromoLookupResultView({super.key, required this.result});

  final PromoLookupResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!result.found) {
      return PromoNotFoundCard(
        text: l10n.promoLookupNotFound(result.code.toUpperCase()),
      );
    }
    final check = result.orderCheck;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (check != null) ...[
          _OrderCheckCard(check: check),
          const SizedBox(height: 12),
        ],
        _CodeCard(result: result),
        const SizedBox(height: 12),
        _RecentUsesCard(uses: result.recentUses),
      ],
    );
  }
}

String _money(BuildContext context, num amount) =>
    formatCurrency(context, amount);

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.result});

  final PromoLookupResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    String money(num v) => _money(context, v);
    String yesNo(bool v) => v ? l10n.promoLookupYes : l10n.promoLookupNo;

    final minText = promoMinOrderText(l10n, result, money: money);
    final appliesText = promoAppliesText(l10n, result);

    final usesText = result.isUnlimited
        ? l10n.promoLookupUsesUnlimited(formatCount(context, result.timesUsed))
        : l10n.promoLookupUsesOfLimit(
            formatCount(context, result.timesUsed),
            formatCount(context, result.usageLimit),
          );

    final customerParts = [
      result.customerName ?? result.customer,
    ].whereType<String>().toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  result.code,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                PromoStatusChip(result: result),
              ],
            ),
            if (result.title != null) ...[
              const SizedBox(height: 8),
              Text(result.title!, style: theme.textTheme.titleMedium),
            ],
            if (result.description != null) ...[
              const SizedBox(height: 4),
              Text(
                result.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sell_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      promoOfferText(
                        l10n,
                        result,
                        money: money,
                        number: (v) => formatCount(context, v),
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            PromoDetailRow(label: l10n.promoLookupMinOrder, value: minText),
            PromoDetailRow(
              label: l10n.promoLookupAppliesTo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appliesText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (result.scope.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final entry in result.scope)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: Icon(
                              entry.isItemGroup
                                  ? Icons.category_outlined
                                  : Icons.cookie_outlined,
                              size: 16,
                            ),
                            label: Text(entry.label),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            PromoDetailRow(
              label: l10n.promoLookupValidFrom,
              value: result.activeFrom == null
                  ? l10n.promoLookupNoStartDate
                  : formatDateString(context, result.activeFrom),
            ),
            PromoDetailRow(
              label: l10n.promoLookupValidTo,
              value: result.activeTo == null
                  ? l10n.promoLookupNoEndDate
                  : formatDateString(context, result.activeTo),
            ),
            PromoDetailRow(label: l10n.promoLookupUses, value: usesText),
            if (result.remainingUses != null)
              PromoDetailRow(
                label: l10n.promoLookupRemaining,
                value: l10n.promoLookupRemainingCount(
                  formatCount(context, result.remainingUses!),
                ),
              ),
            PromoDetailRow(
              label: l10n.promoLookupPerCustomer,
              value: result.perCustomerLimit <= 0
                  ? l10n.promoLookupUnlimited
                  : l10n.promoLookupPerCustomerLimit(
                      formatCount(context, result.perCustomerLimit),
                    ),
            ),
            PromoDetailRow(
              label: l10n.promoLookupPickup,
              value: result.allowPickup
                  ? l10n.promoLookupAllowed
                  : l10n.promoLookupNotAllowed,
            ),
            PromoDetailRow(
              label: l10n.promoLookupStackable,
              value: result.stackable
                  ? l10n.promoLookupStackableYes
                  : l10n.promoLookupStackableNo,
            ),
            PromoDetailRow(
              label: l10n.promoLookupChannels,
              value: promoChannelsText(l10n, result.channels),
            ),
            if (result.isLockedToCustomer)
              PromoDetailRow(
                label: l10n.promoLookupLockedCustomer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (customerParts.isNotEmpty)
                      Text(
                        customerParts.first,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (result.customerPhone != null)
                      PromoLtrText(result.customerPhone!),
                  ],
                ),
              ),
            PromoDetailRow(
              label: l10n.promoLookupOnWebsite,
              value: result.onWebsite && result.wooCouponCode != null
                  ? l10n.promoLookupOnWebsiteYes(result.wooCouponCode!)
                  : yesNo(result.onWebsite),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentUsesCard extends StatelessWidget {
  const _RecentUsesCard({required this.uses});

  final List<PromoRecentUse> uses;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.promoLookupRecentUses,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (uses.isEmpty)
              Text(
                l10n.promoLookupNoRecentUses,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final use in uses) _RecentUseRow(use: use),
          ],
        ),
      ),
    );
  }
}

class _RecentUseRow extends StatelessWidget {
  const _RecentUseRow({required this.use});

  final PromoRecentUse use;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final reversed = use.isReversed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PromoLtrText(
                  orderDisplayId(use.invoice, wooOrderId: use.wooOrderId),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: reversed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (use.customerName != null || use.date != null)
                  Text(
                    [
                      if (use.customerName != null) use.customerName!,
                      if (use.date != null) formatDateString(context, use.date),
                    ].join(' · '),
                    style: muted,
                  ),
              ],
            ),
          ),
          if (reversed) PromoReversedTag(label: l10n.promoLookupUseReversed),
        ],
      ),
    );
  }
}

class _OrderCheckCard extends StatelessWidget {
  const _OrderCheckCard({required this.check});

  final PromoOrderCheck check;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    String money(num v) => _money(context, v);

    final Widget body;
    if (check.hasError) {
      final order = check.order ?? '';
      body = Row(
        children: [
          Icon(
            check.notPermitted ? Icons.lock_outline : Icons.search_off,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              check.orderNotFound
                  ? l10n.promoLookupOrderNotFound(order)
                  : check.notPermitted
                  ? l10n.promoLookupOrderNotPermitted(order)
                  : [check.error!, if (order.isNotEmpty) order].join(' · '),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      );
    } else {
      final accepted = check.accepted;
      final verdictColor = accepted
          ? Colors.green.shade800
          : Colors.red.shade800;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PromoDetailRow(
            label: l10n.promoLookupOrder,
            child: PromoLtrText(
              orderDisplayId(check.invoice, wooOrderId: check.wooOrderId),
            ),
          ),
          if (check.customerName != null)
            PromoDetailRow(
              label: l10n.promoLookupCustomer,
              value: check.customerName,
            ),
          if (check.invoiceStatus.trim().isNotEmpty)
            PromoDetailRow(
              label: l10n.promoLookupOrderStatus,
              value: check.invoiceStatus,
            ),
          PromoDetailRow(
            label: l10n.promoLookupCurrentTotal,
            value: money(check.currentTotal),
          ),
          PromoDetailRow(
            label: l10n.promoLookupCurrentCodes,
            child: check.currentCodes.isEmpty
                ? Text(
                    l10n.promoLookupNoCodes,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final code in check.currentCodes)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(code, textDirection: TextDirection.ltr),
                        ),
                    ],
                  ),
          ),
          if (check.currentPromoDiscount > 0)
            PromoDetailRow(
              label: l10n.promoLookupCurrentPromoDiscount,
              value: money(check.currentPromoDiscount),
            ),
          if (check.deliveryAmount > 0)
            PromoDetailRow(
              label: l10n.promoLookupDelivery,
              value: money(check.deliveryAmount),
            ),
          if (check.waivedDelivery > 0)
            PromoDetailRow(
              label: l10n.promoLookupWaivedDelivery,
              value: money(check.waivedDelivery),
            ),
          const Divider(height: 20),
          Row(
            children: [
              Icon(
                accepted ? Icons.check_circle : Icons.cancel,
                color: verdictColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  accepted
                      ? l10n.promoLookupAccepted
                      : l10n.promoLookupNotAccepted,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: verdictColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (!accepted && check.reason != null) ...[
            const SizedBox(height: 4),
            // The engine's English sentence, shown as-is.
            Text(check.reason!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 8),
          PromoDetailRow(
            label: l10n.promoLookupDiscount,
            value: money(check.discountAmount),
          ),
          if (check.freeDelivery)
            PromoDetailRow(
              label: l10n.promoLookupFreeDelivery,
              value: l10n.promoLookupYes,
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    check.currentCodes.isEmpty
                        ? l10n.promoLookupNewTotal
                        : l10n.promoLookupNewTotalReplacing,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                Text(
                  money(check.newTotal),
                  key: const ValueKey('promoLookupNewTotal'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.promoLookupOrderCheckTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            body,
          ],
        ),
      ),
    );
  }
}
