import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/user_error_message.dart';
import '../../printing/receipt/receipt_delivery.dart';
import '../../printing/receipt/receipt_share.dart';
import '../data/tracking_link.dart';
import '../data/tracking_link_repository.dart';
import '../domain/tracking_share_text.dart';

/// Fetches the customer tracking link for [invoiceId] and opens the share
/// sheet: send on WhatsApp (to the customer's chat when a number is known),
/// the OS share sheet, copy the link, and copy the delivery code when the
/// server requires one.
Future<void> shareTrackingLink(
  BuildContext context,
  WidgetRef ref, {
  required String invoiceId,
  String? fallbackPhone,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final repository = ref.read(trackingLinkRepositoryProvider);

  final TrackingLink link;
  try {
    link = await repository.getTrackingLink(invoiceId);
  } catch (e) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          context.userErrorMessage(
            e,
            fallback: l10n.courierLaunchTrackingLinkFailed,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
    return;
  }
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.paddingOf(sheetContext).bottom,
      ),
      child: TrackingLinkSheet(
        link: link,
        phone: link.customerPhone ?? fallbackPhone,
        messenger: messenger,
      ),
    ),
  );
}

/// Body of the tracking-link sheet.
class TrackingLinkSheet extends StatelessWidget {
  const TrackingLinkSheet({
    super.key,
    required this.link,
    required this.messenger,
    this.phone,
  });

  final TrackingLink link;

  /// Messenger of the screen that opened the sheet, so a snackbar outlives it.
  final ScaffoldMessengerState messenger;
  final String? phone;

  static const urlKey = ValueKey('tracking_link_url');
  static const codeKey = ValueKey('tracking_link_code');
  static const copyCodeKey = ValueKey('tracking_link_copy_code');
  static const copyLinkKey = ValueKey('tracking_link_copy_link');
  static const whatsAppKey = ValueKey('tracking_link_whatsapp');
  static const shareKey = ValueKey('tracking_link_share');

  Future<void> _copy(String text, String confirmation) async {
    await Clipboard.setData(ClipboardData(text: text));
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(confirmation)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final text = buildTrackingShareText(link);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.courierLaunchTrackingSheetTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.courierLaunchTrackingSheetHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          // A URL is LTR even in an Arabic UI.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SelectableText(
              link.url,
              key: urlKey,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        if (link.hasCodeToShare) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.courierLaunchTrackingCodeLabel,
                        style: theme.textTheme.labelMedium,
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          link.deliveryCode!,
                          key: codeKey,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      Text(
                        l10n.courierLaunchTrackingCodeHint,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  key: copyCodeKey,
                  onPressed: () => _copy(
                    link.deliveryCode!,
                    l10n.courierLaunchTrackingCodeCopied,
                  ),
                  icon: const Icon(Icons.content_copy, size: 16),
                  label: Text(l10n.courierLaunchTrackingCopyCode),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          key: whatsAppKey,
          onPressed: () async {
            Navigator.of(context).pop();
            await openWhatsAppOrOfferRetry(
              messenger: messenger,
              uri: whatsappReceiptUri(phone, text),
              failureMessage: l10n.invoiceWhatsAppOpenFailed,
              retryLabel: l10n.commonRetry,
            );
          },
          icon: const Icon(Icons.send, size: 18),
          label: Text(l10n.courierLaunchTrackingSendWhatsApp),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: shareKey,
                onPressed: () async {
                  Navigator.of(context).pop();
                  final shared = await shareReceiptContent(text: text);
                  if (!shared) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.invoiceReceiptShareFailed)),
                    );
                  }
                },
                icon: const Icon(Icons.share, size: 18),
                label: Text(l10n.courierLaunchTrackingShareOther),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: copyLinkKey,
                onPressed: () =>
                    _copy(link.url, l10n.courierLaunchTrackingLinkCopied),
                icon: const Icon(Icons.link, size: 18),
                label: Text(l10n.courierLaunchTrackingCopyLink),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
