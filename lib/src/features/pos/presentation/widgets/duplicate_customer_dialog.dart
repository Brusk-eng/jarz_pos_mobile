import 'package:flutter/material.dart';

import '../../data/models/customer_duplicate_models.dart';
import '../../domain/customer_name_rules.dart';

// ─────────────────────────────────────────────────────────────────────────
// Inline bilingual strings, DELIBERATELY not .arb keys: an .arb edit forces a
// full APK release, while this warning ships as a Dart-only Shorebird patch.
// Arabic is first-class here (the staff UI runs in Arabic).
// ─────────────────────────────────────────────────────────────────────────

String _bi(BuildContext context, String en, String ar) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

/// Message for a name with no Arabic or Latin letter ("...", "-", "123").
String customerNameNoLetterMessage(BuildContext context) => _bi(
  context,
  'Enter a real name: letters, not only symbols or numbers',
  'اكتب اسم حقيقي: حروف، مش رموز أو أرقام بس',
);

/// Form validator for the customer-name field of every "new customer" form.
/// [requiredMessage] is the form's existing "name is required" text.
String? validateCustomerNameField(
  BuildContext context,
  String? value, {
  required String requiredMessage,
}) {
  switch (customerNameProblem(value)) {
    case CustomerNameProblem.empty:
      return requiredMessage;
    case CustomerNameProblem.noLetter:
      return customerNameNoLetterMessage(context);
    case null:
      return null;
  }
}

/// What the user chose in [DuplicateCustomerDialog].
enum DuplicateCustomerAction { useExisting, createNew, cancel }

class DuplicateCustomerDecision {
  const DuplicateCustomerDecision._(this.action, [this.match]);

  const DuplicateCustomerDecision.useExisting(CustomerDuplicateMatch match)
    : this._(DuplicateCustomerAction.useExisting, match);
  static const createNew = DuplicateCustomerDecision._(
    DuplicateCustomerAction.createNew,
  );
  static const cancel = DuplicateCustomerDecision._(
    DuplicateCustomerAction.cancel,
  );

  final DuplicateCustomerAction action;

  /// Set only for [DuplicateCustomerAction.useExisting].
  final CustomerDuplicateMatch? match;
}

/// Shows the "this customer may already exist" warning. Dismissing it (back
/// button, tap outside) counts as [DuplicateCustomerDecision.cancel].
///
/// [allowUseExisting] false hides the per-match "Use this customer" button for
/// a caller that has no way to switch to an existing customer.
Future<DuplicateCustomerDecision> showDuplicateCustomerDialog(
  BuildContext context, {
  required List<CustomerDuplicateMatch> matches,
  bool allowUseExisting = true,
}) async {
  final result = await showDialog<DuplicateCustomerDecision>(
    context: context,
    builder: (_) => DuplicateCustomerDialog(
      matches: matches,
      allowUseExisting: allowUseExisting,
    ),
  );
  return result ?? DuplicateCustomerDecision.cancel;
}

class DuplicateCustomerDialog extends StatelessWidget {
  const DuplicateCustomerDialog({
    super.key,
    required this.matches,
    this.allowUseExisting = true,
  });

  final List<CustomerDuplicateMatch> matches;
  final bool allowUseExisting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      key: const ValueKey('dup-customer-dialog'),
      // Scrollable so a long list (or a phone in landscape) never overflows.
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      icon: Icon(Icons.people_alt_outlined, color: theme.colorScheme.tertiary),
      title: Text(
        _bi(
          context,
          'This customer may already exist',
          'العميل ده ممكن يكون موجود قبل كده',
        ),
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _bi(
                context,
                'Check these customers before creating a new one.',
                'راجع العملاء دول قبل ما تعمل عميل جديد.',
              ),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            for (final match in matches)
              _MatchCard(match: match, allowUseExisting: allowUseExisting),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('dup-customer-cancel'),
          onPressed: () =>
              Navigator.of(context).pop(DuplicateCustomerDecision.cancel),
          child: Text(_bi(context, 'Cancel', 'إلغاء')),
        ),
        OutlinedButton(
          key: const ValueKey('dup-customer-create-anyway'),
          onPressed: () =>
              Navigator.of(context).pop(DuplicateCustomerDecision.createNew),
          child: Text(_bi(context, 'Create new anyway', 'اعمل عميل جديد برضه')),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.allowUseExisting});

  final CustomerDuplicateMatch match;
  final bool allowUseExisting;

  String _reasonLabel(BuildContext context, String reason) {
    switch (reason) {
      case CustomerDuplicateReason.phone:
        return _bi(context, 'Same phone', 'نفس رقم الموبايل');
      case CustomerDuplicateReason.secondaryPhone:
        return _bi(context, 'Same second phone', 'نفس الرقم التاني');
      case CustomerDuplicateReason.address:
        return _bi(context, 'Same address', 'نفس العنوان');
      case CustomerDuplicateReason.name:
        return _bi(context, 'Same name', 'نفس الاسم');
      default:
        return reason;
    }
  }

  String _ordersLine(BuildContext context) {
    final count = match.orderCount;
    if (count <= 0) {
      return _bi(context, 'No orders yet', 'مفيش طلبات لسه');
    }
    final last = match.lastOrderDate;
    final en = count == 1 ? '1 order' : '$count orders';
    final ar = '$count طلب';
    if (last == null) return _bi(context, en, ar);
    return _bi(context, '$en · last $last', '$ar · آخر طلب $last');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final address = match.displayAddress;
    return Card(
      key: ValueKey('dup-customer-match-${match.name}'),
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              match.customerName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (match.mobileNo != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: muted?.color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      match.mobileNo!,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            if (address != null) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: muted?.color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(_ordersLine(context), style: muted),
            if (match.reasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final reason in match.reasons)
                    Chip(
                      key: ValueKey(
                        'dup-customer-reason-${match.name}-$reason',
                      ),
                      label: Text(_reasonLabel(context, reason)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelStyle: theme.textTheme.labelSmall,
                      backgroundColor: theme.colorScheme.tertiaryContainer,
                      side: BorderSide.none,
                    ),
                ],
              ),
            ],
            if (allowUseExisting) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  key: ValueKey('dup-customer-use-${match.name}'),
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(DuplicateCustomerDecision.useExisting(match)),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(
                    _bi(context, 'Use this customer', 'استخدم العميل ده'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
