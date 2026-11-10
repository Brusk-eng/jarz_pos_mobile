// Pieces both promo lookup tabs use to describe a code: the offer line, the
// minimum-order / applies-to / channels text, the status chip, label-value
// rows, Latin-safe text, the idle hint and the error note.

import 'package:flutter/material.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../data/models/promo_lookup_models.dart';

/// The offer in one plain line: "10% off the whole order, up to 150 EGP",
/// "50 EGP off the whole order", "Free delivery".
///
/// [money] and [number] are passed in so the line can be built (and tested)
/// without a widget tree.
String promoOfferText(
  AppLocalizations l10n,
  PromoLookupResult result, {
  required String Function(num amount) money,
  required String Function(num value) number,
}) {
  final target = switch (result.appliesTo) {
    PromoAppliesTo.specificItems => l10n.promoLookupTargetItems,
    PromoAppliesTo.itemGroups => l10n.promoLookupTargetGroups,
    _ => l10n.promoLookupTargetWholeOrder,
  };
  switch (result.discountType) {
    case PromoDiscountType.percentage:
      final percent = number(result.discountValue);
      return result.hasCap
          ? l10n.promoLookupOfferPercentCapped(
              percent,
              target,
              money(result.maxDiscountAmount),
            )
          : l10n.promoLookupOfferPercent(percent, target);
    case PromoDiscountType.fixedAmount:
      return l10n.promoLookupOfferFixed(money(result.discountValue), target);
    case PromoDiscountType.freeDelivery:
      return l10n.promoLookupOfferFreeDelivery;
    case PromoDiscountType.unknown:
      return l10n.promoLookupOfferUnknown;
  }
}

/// The localized label for a code's [PromoStatus].
String promoStatusLabel(AppLocalizations l10n, PromoLookupResult result) =>
    switch (result.status) {
      PromoStatus.active => l10n.promoLookupStatusActive,
      PromoStatus.disabled => l10n.promoLookupStatusDisabled,
      PromoStatus.notStarted => l10n.promoLookupStatusNotStarted,
      PromoStatus.expired => l10n.promoLookupStatusExpired,
      PromoStatus.usedUp => l10n.promoLookupStatusUsedUp,
      PromoStatus.unknown => l10n.promoLookupStatusUnknown(result.rawStatus),
    };

/// "No minimum", "300 EGP on the whole order", "300 EGP on eligible items
/// only".
String promoMinOrderText(
  AppLocalizations l10n,
  PromoLookupResult result, {
  required String Function(num amount) money,
}) {
  if (result.minOrderAmount <= 0) return l10n.promoLookupMinNone;
  return result.minOnWholeOrder
      ? l10n.promoLookupMinWholeOrder(money(result.minOrderAmount))
      : l10n.promoLookupMinEligibleOnly(money(result.minOrderAmount));
}

/// "The whole order", "These items", "These categories".
String promoAppliesText(AppLocalizations l10n, PromoLookupResult result) =>
    switch (result.appliesTo) {
      PromoAppliesTo.specificItems => l10n.promoLookupAppliesItems,
      PromoAppliesTo.itemGroups => l10n.promoLookupAppliesGroups,
      _ => l10n.promoLookupAppliesWholeOrder,
    };

/// "All channels", or the channel names joined in the reading language.
String promoChannelsText(AppLocalizations l10n, List<String> channels) =>
    channels.isEmpty
    ? l10n.promoLookupAllChannels
    : channels.join(l10n.localeName.startsWith('ar') ? '، ' : ', ');

/// The code's status as a coloured pill. [dense] for list tiles.
class PromoStatusChip extends StatelessWidget {
  const PromoStatusChip({super.key, required this.result, this.dense = false});

  final PromoLookupResult result;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg, IconData icon) = switch (result.status) {
      PromoStatus.active => (
        Colors.green.shade800,
        Colors.green.shade50,
        Icons.check_circle,
      ),
      PromoStatus.expired || PromoStatus.usedUp => (
        Colors.red.shade800,
        Colors.red.shade50,
        Icons.cancel,
      ),
      _ => (
        Colors.blueGrey.shade700,
        Colors.blueGrey.shade50,
        Icons.pause_circle,
      ),
    };
    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: dense ? 14 : 20),
          SizedBox(width: dense ? 4 : 8),
          Flexible(
            child: Text(
              promoStatusLabel(context.l10n, result),
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: dense ? 12 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small coloured tag ("Reversed", "Cancelled / reversed").
class PromoReversedTag extends StatelessWidget {
  const PromoReversedTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.red.shade800, fontSize: 12),
      ),
    );
  }
}

/// Label on the start side, value filling the rest.
class PromoDetailRow extends StatelessWidget {
  const PromoDetailRow({
    super.key,
    required this.label,
    this.value,
    this.child,
  });

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                child ??
                Text(
                  value ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

/// Codes, order numbers and phones are Latin and must read left to right
/// inside an Arabic sentence too.
class PromoLtrText extends StatelessWidget {
  const PromoLtrText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(text, textDirection: TextDirection.ltr, style: style ?? base),
    );
  }
}

/// Wraps Latin text (an order number, a phone) in a left-to-right isolate so
/// it keeps its shape inside an Arabic sentence ("#21658", not "21658#").
String ltrIsolate(String text) => '\u2066$text\u2069';

/// The idle message under a search form.
class PromoLookupHint extends StatelessWidget {
  const PromoLookupHint({
    super.key,
    required this.text,
    this.icon = Icons.local_offer_outlined,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A failed lookup, in the user's language.
class PromoLookupErrorNote extends StatelessWidget {
  const PromoLookupErrorNote({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card with a search-off icon and one line ("No promo code X", "No
/// customer found for Y").
class PromoNotFoundCard extends StatelessWidget {
  const PromoNotFoundCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.search_off, color: theme.colorScheme.outline, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: theme.textTheme.titleMedium)),
          ],
        ),
      ),
    );
  }
}
