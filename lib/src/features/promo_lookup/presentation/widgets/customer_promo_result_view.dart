import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../../core/utils/order_display_id.dart';
import '../../data/models/promo_lookup_models.dart';
import 'promo_code_parts.dart';

/// Everything the customer search answered: no match, or one card per
/// customer with their codes and past uses.
class CustomerPromoResultView extends StatelessWidget {
  const CustomerPromoResultView({super.key, required this.result});

  final CustomerPromoLookup result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (result.customers.isEmpty) {
      return PromoNotFoundCard(
        // First-strong isolate: an Arabic name or a Latin phone keeps its
        // own direction inside the sentence.
        text: l10n.promoCustomerNoneFound('\u2068${result.query}\u2069'),
      );
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.truncated)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.promoCustomerTruncated,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        for (var i = 0; i < result.customers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CustomerCard(
              key: ValueKey('promoCustomerCard-$i'),
              entry: result.customers[i],
            ),
          ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({super.key, required this.entry});

  final CustomerPromoEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final phone = entry.phone;
    final title = entry.isPhoneOnly
        ? (phone ?? entry.displayName)
        : entry.displayName;

    final lastOrderId = orderDisplayId(null, wooOrderId: entry.lastWooOrderId);
    final lastOrderDate = entry.lastOrderDate == null
        ? null
        : formatDateString(context, entry.lastOrderDate);
    final orderParts = <String>[
      entry.orderCount > 0
          ? l10n.promoCustomerOrderCount(formatCount(context, entry.orderCount))
          : l10n.promoCustomerNoOrders,
      if (lastOrderId.isNotEmpty && lastOrderDate != null)
        l10n.promoCustomerLastOrder(ltrIsolate(lastOrderId), lastOrderDate)
      else if (lastOrderDate != null)
        l10n.promoCustomerLastOrderDate(lastOrderDate)
      else if (lastOrderId.isNotEmpty)
        l10n.promoCustomerLastOrderId(ltrIsolate(lastOrderId)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(
                    entry.isPhoneOnly ? Icons.phone : Icons.person,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textDirection: entry.isPhoneOnly
                            ? TextDirection.ltr
                            : null,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (entry.isPhoneOnly)
                        Text(l10n.promoCustomerPhoneOnly, style: muted)
                      else if (phone != null)
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                phone,
                                textDirection: TextDirection.ltr,
                                style: muted,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 2),
                      Text(orderParts.join(' · '), style: muted),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _SectionTitle(
              icon: Icons.verified_outlined,
              text: l10n.promoCustomerActiveCodes,
              color: Colors.green.shade800,
            ),
            const SizedBox(height: 8),
            if (entry.activeCodes.isEmpty)
              _EmptyLine(
                key: const ValueKey('promoCustomerNoActiveCode'),
                text: l10n.promoCustomerNoActiveCode,
                emphasised: true,
              )
            else
              for (final code in entry.activeCodes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CodeTile(
                    code: code,
                    emphasis: _CodeEmphasis.personal,
                  ),
                ),
            const SizedBox(height: 12),
            _SectionTitle(
              icon: Icons.local_offer_outlined,
              text: l10n.promoCustomerPublicCodes,
            ),
            const SizedBox(height: 8),
            if (entry.publicCodes.isEmpty)
              _EmptyLine(text: l10n.promoCustomerNoPublicCodes)
            else
              for (final code in entry.publicCodes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CodeTile(code: code, emphasis: _CodeEmphasis.public),
                ),
            const SizedBox(height: 12),
            _SectionTitle(
              icon: Icons.history,
              text: l10n.promoCustomerUsedCodes,
            ),
            const SizedBox(height: 4),
            if (entry.usedCodes.isEmpty)
              _EmptyLine(text: l10n.promoCustomerNeverUsed)
            else
              for (final use in entry.usedCodes) _UseRow(use: use),
            if (entry.inactiveCodes.isNotEmpty) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                key: const ValueKey('promoCustomerInactiveCodes'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Icon(
                  Icons.event_busy_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  l10n.promoCustomerInactiveCodes(
                    formatCount(context, entry.inactiveCodes.length),
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                children: [
                  for (final code in entry.inactiveCodes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CodeTile(
                        code: code,
                        emphasis: _CodeEmphasis.inactive,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? theme.colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 20, color: fg),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// "No active personal code", "Never used a promo code".
class _EmptyLine extends StatelessWidget {
  const _EmptyLine({super.key, required this.text, this.emphasised = false});

  final String text;

  /// The answer to the caller's question; shown boxed, not just muted.
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: emphasised ? FontWeight.w600 : null,
    );
    final line = Row(
      children: [
        Icon(
          Icons.remove_circle_outline,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: style)),
      ],
    );
    if (!emphasised) {
      return Padding(padding: const EdgeInsets.only(bottom: 4), child: line);
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: line,
    );
  }
}

enum _CodeEmphasis { personal, public, inactive }

/// One code: big copyable code text, the offer and its conditions.
class _CodeTile extends StatelessWidget {
  const _CodeTile({required this.code, required this.emphasis});

  final PromoLookupResult code;
  final _CodeEmphasis emphasis;

  Future<void> _copy(BuildContext context) async {
    final copied = context.l10n.promoCustomerCodeCopied;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: code.code));
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(copied), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String money(num v) => formatCurrency(context, v);

    final inactive = emphasis == _CodeEmphasis.inactive;
    final (Color? bg, Color border, Color codeColor) = switch (emphasis) {
      _CodeEmphasis.personal => (
        Colors.green.shade50,
        Colors.green.shade400,
        Colors.green.shade900,
      ),
      _CodeEmphasis.public => (
        scheme.surfaceContainerLow,
        scheme.outlineVariant,
        scheme.onSurface,
      ),
      _CodeEmphasis.inactive => (
        null,
        scheme.outlineVariant,
        scheme.onSurfaceVariant,
      ),
    };
    final codeStyle =
        (switch (emphasis) {
          _CodeEmphasis.personal => theme.textTheme.headlineSmall,
          _CodeEmphasis.public => theme.textTheme.titleLarge,
          _CodeEmphasis.inactive => theme.textTheme.titleMedium,
        })?.copyWith(
          fontFamily: 'monospace',
          fontWeight: inactive ? FontWeight.w600 : FontWeight.bold,
          letterSpacing: 1.5,
          color: codeColor,
        );
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final usesLeft = code.usesLeftForCustomer;
    final notes = [
      promoChannelsText(l10n, code.channels),
      '${l10n.promoLookupPickup}: '
          '${code.allowPickup ? l10n.promoLookupAllowed : l10n.promoLookupNotAllowed}',
      code.stackable
          ? l10n.promoLookupStackableYes
          : l10n.promoLookupStackableNo,
    ];
    final scopeText = code.appliesTo == PromoAppliesTo.wholeOrder
        ? null
        : [
            promoAppliesText(l10n, code),
            if (code.scope.isNotEmpty)
              code.scope
                  .map((e) => e.label)
                  .join(l10n.localeName.startsWith('ar') ? '، ' : ', '),
          ].join(': ');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: border,
          width: emphasis == _CodeEmphasis.personal ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    code.code,
                    textDirection: TextDirection.ltr,
                    style: codeStyle,
                  ),
                ),
              ),
              IconButton(
                key: ValueKey('promoCopy-${code.code}'),
                tooltip: l10n.promoCustomerCopyCode,
                visualDensity: inactive ? VisualDensity.compact : null,
                iconSize: inactive ? 18 : 22,
                color: inactive ? scheme.onSurfaceVariant : codeColor,
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copy(context),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (code.status != PromoStatus.active) ...[
                  Wrap(children: [PromoStatusChip(result: code, dense: true)]),
                  const SizedBox(height: 6),
                ],
                if (code.title != null) Text(code.title!, style: muted),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sell_outlined,
                      size: 18,
                      color: inactive ? scheme.onSurfaceVariant : codeColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        promoOfferText(
                          l10n,
                          code,
                          money: money,
                          number: (v) => formatCount(context, v),
                        ),
                        style:
                            (inactive
                                    ? theme.textTheme.bodyMedium
                                    : theme.textTheme.titleSmall)
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: inactive
                                      ? scheme.onSurfaceVariant
                                      : codeColor,
                                ),
                      ),
                    ),
                  ],
                ),
                if (code.description != null) ...[
                  const SizedBox(height: 4),
                  Text(code.description!, style: muted),
                ],
                const SizedBox(height: 4),
                _InfoLine(
                  icon: Icons.shopping_bag_outlined,
                  label: l10n.promoLookupMinOrder,
                  value: promoMinOrderText(l10n, code, money: money),
                ),
                if (scopeText != null)
                  _InfoLine(
                    icon: Icons.category_outlined,
                    label: l10n.promoLookupAppliesTo,
                    value: scopeText,
                  ),
                if (inactive && code.activeFrom != null)
                  _InfoLine(
                    icon: Icons.event_outlined,
                    label: l10n.promoLookupValidFrom,
                    value: formatDateString(context, code.activeFrom),
                  )
                else if (code.status == PromoStatus.notStarted &&
                    code.activeFrom != null)
                  _InfoLine(
                    icon: Icons.event_outlined,
                    value: l10n.promoCustomerStarts(
                      formatDateString(context, code.activeFrom),
                    ),
                  ),
                _InfoLine(
                  icon: Icons.event_available_outlined,
                  value: code.activeTo == null
                      ? l10n.promoLookupNoEndDate
                      : l10n.promoCustomerValidUntil(
                          formatDateString(context, code.activeTo),
                        ),
                ),
                if (!inactive)
                  _InfoLine(
                    icon: Icons.repeat,
                    value: usesLeft == null
                        ? l10n.promoCustomerUsesUnlimited
                        : l10n.promoCustomerUsesLeft(
                            formatCount(context, usesLeft),
                          ),
                  ),
                const SizedBox(height: 4),
                Text(notes.join(' · '), style: muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon, optional "Label: ", value — wraps instead of overflowing.
class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.value, this.label});

  final IconData icon;
  final String? label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: mutedColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (label != null)
                    TextSpan(
                      text: '$label: ',
                      style: TextStyle(color: mutedColor),
                    ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// One past redemption: code, order, date, discount; struck through and
/// tagged when the order was cancelled or the code reversed.
class _UseRow extends StatelessWidget {
  const _UseRow({required this.use});

  final PromoUse use;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final reversed = use.isReversed;
    final orderId = orderDisplayId(use.invoice, wooOrderId: use.wooOrderId);
    final meta = [
      if (orderId.isNotEmpty) ltrIsolate(orderId),
      if (use.date != null) formatDateString(context, use.date),
    ].join(' · ');
    final money = formatCurrency(context, use.discount);
    final discountText = use.orderTotal != null && use.orderTotal! > 0
        ? l10n.promoCustomerUseDiscountOfTotal(
            money,
            formatCurrency(context, use.orderTotal!),
          )
        : l10n.promoCustomerUseDiscount(money);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      use.code,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        decoration: reversed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (reversed)
                      PromoReversedTag(label: l10n.promoCustomerUseCancelled),
                  ],
                ),
                if (meta.isNotEmpty) Text(meta, style: muted),
                Text(discountText, style: muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
