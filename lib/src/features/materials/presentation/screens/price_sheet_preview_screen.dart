import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/models/price_sheet.dart';
import '../../state/materials_notifier.dart';
import '../widgets/zoomable_sheet_page.dart';

/// A generated price sheet exactly as one recipient would receive it: the
/// rendered page(s), who it was prepared for, and until when any special
/// prices hold.
///
/// With no reference it is the template's default rendering — what a manager
/// sees while editing the template.
class PriceSheetPreviewScreen extends ConsumerWidget {
  const PriceSheetPreviewScreen({
    super.key,
    required this.material,
    this.title,
    this.referenceDoctype,
    this.referenceName,
  });

  final String material;
  final String? title;
  final String? referenceDoctype;
  final String? referenceName;

  PriceSheetPreviewRequest get _request => (
    material: material,
    referenceDoctype: referenceDoctype,
    referenceName: referenceName,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final preview = ref.watch(priceSheetPreviewProvider(_request));
    final pdfUrl = preview.valueOrNull?.pdfUrl ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          (title?.trim().isNotEmpty ?? false)
              ? title!.trim()
              : l10n.priceSheetPreviewTitle,
        ),
        actions: [
          if (pdfUrl.isNotEmpty)
            IconButton(
              tooltip: l10n.priceSheetOpenPdf,
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _openPdf(pdfUrl),
            ),
          IconButton(
            tooltip: l10n.materialsRetry,
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(priceSheetPreviewProvider(_request)),
          ),
        ],
      ),
      body: preview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.userErrorMessage(error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(priceSheetPreviewProvider(_request)),
                  child: Text(l10n.materialsRetry),
                ),
              ],
            ),
          ),
        ),
        data: (value) => _PreviewBody(preview: value),
      ),
    );
  }

  /// Same launch order as the send sheet's WhatsApp link: external app first,
  /// never gated on `canLaunchUrl` (false on Android 11+ without `<queries>`).
  Future<void> _openPdf(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Fall through to the default mode.
    }
    try {
      await launchUrl(uri);
    } catch (_) {
      // No handler; nothing else to try.
    }
  }
}

class _PreviewBody extends StatefulWidget {
  const _PreviewBody({required this.preview});

  final PriceSheetPreview preview;

  @override
  State<_PreviewBody> createState() => _PreviewBodyState();
}

class _PreviewBodyState extends State<_PreviewBody> {
  /// While a page is zoomed the pager must not steal horizontal pans.
  bool _zoomed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sheet = widget.preview.sheet;
    final pages = widget.preview.pages;
    final locale = Localizations.localeOf(context).toString();

    String formatDate(DateTime? date, String? raw) {
      if (date == null) return raw?.trim() ?? '';
      return DateFormat.yMMMd(locale).format(date);
    }

    final customer = sheet.customerName?.trim() ?? '';
    final dealUntil = formatDate(sheet.dealUntilDate, sheet.dealUntil);
    final asOf = formatDate(sheet.asOfDate, sheet.asOf);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer.isNotEmpty)
                Text(
                  l10n.priceSheetPreparedFor(customer),
                  key: const ValueKey('price-sheet-prepared-for'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (dealUntil.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.priceSheetDealUntil(dealUntil),
                          key: const ValueKey('price-sheet-deal-until'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (asOf.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.priceSheetAsOf(asOf),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: pages.isEmpty
              ? Center(child: Text(l10n.priceSheetNoPages))
              : PageView.builder(
                  physics: _zoomed
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  itemCount: pages.length,
                  itemBuilder: (context, index) => ZoomableSheetPage(
                    page: pages[index],
                    onZoomChanged: (zoomed) {
                      if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                    },
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            l10n.priceSheetPinchHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
