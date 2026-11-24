// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/courier_run_progress.dart';
import '../models/kanban_models.dart';
import '../providers/courier_run_progress_provider.dart';
import '../providers/kanban_provider.dart';
import '../../pos/state/pos_notifier.dart';
import '../../pos/domain/models/delivery_slot.dart';
import '../../pos/presentation/utils/amendment_refusal_message.dart';
import '../../pos/data/repositories/pos_repository.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/business_constants.dart';
import '../../../core/network/courier_service.dart';
import '../../../core/network/user_service.dart';
import '../../manager/data/manager_api.dart';
import '../../manager/state/manager_providers.dart';
import 'settlement_preview_dialog.dart';
import 'cancel_order_dialog.dart';
import 'return_order_dialog.dart';
import 'payment_collection_change_dialog.dart';
import 'transfer_proof_logic.dart';
import 'transfer_proof_sheet.dart';
import 'sub_territory_selection_sheet.dart';
import 'custom_shipping_request_dialog.dart';
import 'invoice_notes_sheet.dart';
import '../../geo/presentation/widgets/add_pin_sheet.dart';
import '../../order_timeline/presentation/order_timeline_section.dart';
import '../../tracking/presentation/share_tracking_link.dart';
import '../../printing/pos_printer_provider.dart';
import '../../printing/printable_invoice_mapper.dart';
import '../../printing/receipt/receipt_delivery.dart';
import '../../printing/receipt/receipt_share.dart';
import '../../printing/pos_printer_service.dart'
    if (dart.library.html) '../../printing/pos_printer_service_web.dart';
import '../../pos/order_alert/data/order_alert_service.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/localization/localized_display_mappers.dart';
import '../../../core/localization/localized_formatters.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/user_error_message.dart';
import '../../../core/widgets/customer_shipping_address_dialog.dart';
import '../../../core/repositories/customer_address_repository.dart';
import '../../../core/utils/territory_label.dart';
// Invoice card widget displaying a Sales Invoice within the Kanban board.

class InvoiceCardWidget extends ConsumerStatefulWidget {
  final InvoiceCard invoice;
  final bool isDragging;
  final bool compact;
  const InvoiceCardWidget({
    super.key,
    required this.invoice,
    this.isDragging = false,
    this.compact = false,
  });

  @override
  ConsumerState<InvoiceCardWidget> createState() => _InvoiceCardWidgetState();
}

class _InvoiceCardWidgetState extends ConsumerState<InvoiceCardWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isAccepting = false; // Track acceptance state for optimistic UI
  late AppLocalizations _errorLocalizations;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _errorLocalizations = context.l10n;
  }

  String _formatErrorMessage(Object error, {required String fallback}) {
    return userErrorMessageFor(_errorLocalizations, error, fallback: fallback);
  }

  String _withActionPrefix(String action, Object error, {String? fallback}) {
    final message = _formatErrorMessage(error, fallback: fallback ?? action);
    return message == action ? action : '$action: $message';
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(InvoiceCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset accepting state if the invoice changes or acceptance status changes
    if (oldWidget.invoice.id != widget.invoice.id ||
        oldWidget.invoice.acceptanceStatus != widget.invoice.acceptanceStatus) {
      if (_isAccepting) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  String? _resolvePaymentReceiptUrl(String? rawUrl) {
    final value = (rawUrl ?? '').trim();
    if (value.isEmpty) {
      return null;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final baseUrl = dotenv.get('ERP_BASE_URL', fallback: '').trim();
    if (baseUrl.isEmpty) {
      return null;
    }
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = value.startsWith('/') ? value : '/$value';
    return '$normalizedBase$normalizedPath';
  }

  Future<void> _openPaymentReceipt(String? rawUrl) async {
    final resolvedUrl = _resolvePaymentReceiptUrl(rawUrl);
    if (resolvedUrl == null) {
      return;
    }
    final uri = Uri.tryParse(resolvedUrl);
    if (uri == null) {
      return;
    }
    await launchUrl(uri);
  }

  /// Accent used for every "this card has notes" affordance (card wash, card
  /// border, body preview strip) so they read as one signal.
  static const Color _noteAccentColor = Color(0xFFB26A00); // amber 900-ish

  /// Note preview strip shown on the card body. Renders the latest note's text
  /// when the backend supplied it, and otherwise degrades to a count-only
  /// prompt (older payloads / pre-`latest_note` backends). Tapping opens the
  /// existing notes sheet.
  Widget _buildNotePreviewStrip(BuildContext context, bool transitioning) {
    final l10n = context.l10n;
    final preview = widget.invoice.latestNotePreview;
    final count = widget.invoice.noteCount;

    return InkWell(
      onTap: transitioning ? null : () => _openInvoiceNotes(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _noteAccentColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          // Uniform border ONLY. A non-uniform Border (a heavier left side)
          // combined with a borderRadius throws a debug-only paint assertion
          // ("A borderRadius can only be given on borders with uniform
          // colors"), which stops the strip's inner content painting under
          // `flutter test`. The thick amber left accent is rendered below as a
          // standalone full-height bar instead of a heavier left BorderSide.
          border: Border.all(color: _noteAccentColor.withValues(alpha: 0.25)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Leading accent bar — reads like a sticky note without needing a
              // new icon glyph. A standalone full-height bar (not a Border side)
              // so the strip keeps a uniform border and can round its corners.
              Container(width: 3, color: _noteAccentColor),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reuses the glyph already on this card — do not swap for a
                      // new icon, it would break the production Shorebird patch.
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 1),
                        child: Icon(
                          Icons.comment_outlined,
                          size: ResponsiveUtils.getIconSize(context, small: 12, medium: 13, large: 14),
                          color: _noteAccentColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              count > 1
                                  ? l10n.invoiceLatestNoteLabelWithCount(count)
                                  : l10n.invoiceLatestNoteLabel,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 10),
                                fontWeight: FontWeight.w700,
                                color: _noteAccentColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              preview ?? l10n.invoiceLatestNoteTapToRead,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                                height: 1.25,
                                color: Colors.black87,
                                fontStyle: preview == null ? FontStyle.italic : FontStyle.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentReceiptPreview(BuildContext context) {
    final resolvedUrl = _resolvePaymentReceiptUrl(widget.invoice.paymentReceiptImageUrl);
    if (resolvedUrl == null) {
      return const SizedBox.shrink();
    }

    final receiptMethod = localizedPaymentMethodLabel(
      context,
      widget.invoice.paymentReceiptMethod,
    );
    final receiptStatus = localizedStatusLabel(
      context,
      widget.invoice.paymentReceiptStatus ?? 'Unconfirmed',
    );

    return InkWell(
      onTap: () => _openPaymentReceipt(widget.invoice.paymentReceiptImageUrl),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
          color: Colors.blueGrey.withValues(alpha: 0.04),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                resolvedUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[200],
                  child: const Icon(Icons.receipt_long_outlined),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receiptMethod,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    receiptStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => _openPaymentReceipt(widget.invoice.paymentReceiptImageUrl),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(context.l10n.commonPreview),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printInvoice(BuildContext context) async {
    final l10n = context.l10n;
    final printer = ref.read(posPrinterServiceProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invoicePreparingReceipt), duration: const Duration(seconds: 1)));
    final inv = await _buildPrintableInvoice(context);
    // If not connected attempt reconnect to last saved printer silently
    if (!printer.isConnected && !printer.isClassicConnected) {
      final ok = await printer.connectLastSaved();
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invoicePrinterNotConnectedHint)));
        return;
      }
    }
    final res = await printer.printInvoice(inv);
    if (!mounted) return; // avoid using context after async gap
    switch (res) {
      case PrintResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invoicePrintedSuccessfully)),
        );
        break;
      case PrintResult.disconnected:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invoicePrinterDisconnected)),);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userErrorMessageFor(_errorLocalizations, res, fallback: l10n.printerStatusError))),);
    }
  }

  /// Sends the receipt as the printed image, captioned.
  ///
  /// The image is the paper receipt pixel for pixel, so what the customer
  /// sees and what the courier hands over agree. [toWhatsApp] opens WhatsApp's
  /// own chat list so the cashier picks the chat or group; with [toCustomer]
  /// it opens the customer's number instead. Otherwise the OS share sheet.
  /// Only a failed render falls back to the text receipt.
  Future<void> _sendReceipt(
    BuildContext context, {
    required bool toWhatsApp,
    bool toCustomer = false,
  }) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final printer = ref.read(posPrinterServiceProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.invoicePreparingReceipt), duration: const Duration(seconds: 1)));
    final inv = await _buildPrintableInvoice(context);
    final branding = await printer.receiptBranding();

    final files = <ReceiptImage>[];
    try {
      files.add(receiptImageFile(await printer.renderReceiptPng(inv), 'receipt-${receiptOrderLabel(inv)}'));
    } catch (e) {
      debugPrint('[InvoiceCard] receipt image render failed, sending text: $e');
    }
    await deliverReceipt(
      messenger: messenger,
      files: files,
      caption: receiptShareCaption(inv, branding),
      text: buildReceiptShareText(inv, branding),
      toWhatsApp: toWhatsApp,
      whatsappPhone: toCustomer ? _customerPhone(inv) : null,
      failureMessage: toWhatsApp ? l10n.invoiceWhatsAppOpenFailed : l10n.invoiceReceiptShareFailed,
      retryLabel: l10n.commonRetry,
      imageReadyMessage: l10n.invoiceReceiptImageReady,
      sendLabel: l10n.invoiceReceiptSendAction,
    );
  }

  String? _customerPhone([PrintableInvoice? inv]) =>
      (inv?.customerPhone ?? '').trim().isNotEmpty ? inv!.customerPhone : widget.invoice.customerPhone;

  Future<PrintableInvoice> _buildPrintableInvoice(BuildContext context) async {
    final l10n = context.l10n;
    InvoiceCard? details;
    try {
      // invoiceDetailsProvider caches for the life of the session, so a receipt built
      // from it would keep printing the payment method and paid state the invoice had
      // the first time this card was opened. Refetch: the board card next to it is
      // patched on every transition, and the two must not disagree on paper.
      ref.invalidate(invoiceDetailsProvider(widget.invoice.id));
      details = await ref.read(invoiceDetailsProvider(widget.invoice.id).future);
    } catch (_) {}
    return buildPrintableInvoiceFromCards(
      source: widget.invoice,
      details: details,
      fallbackItemLabel: l10n.invoiceItemsCount(details?.itemsCount ?? widget.invoice.itemsCount),
    );
  }

  Future<void> _acceptOrder(BuildContext context) async {
    final l10n = context.l10n;
    // Set optimistic state immediately
    setState(() {
      _isAccepting = true;
    });

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(l10n.invoiceAcceptOrderTitle),
          ],
        ),
        content: Text(
          l10n.invoiceAcceptOrderQuestion(
            _displayId(widget.invoice),
            widget.invoice.customerName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.check),
            label: Text(l10n.invoiceAcceptAction),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    // The dialog can outlive the card (board rebuild, websocket refresh), so
    // the State has to be re-checked before `setState` or any `ref` use.
    if (!mounted) return;
    if (confirmed != true) {
      // Reset if user cancels
      setState(() {
        _isAccepting = false;
      });
      return;
    }

    // Call the acknowledgment API
    try {
      final orderAlertService = ref.read(orderAlertServiceProvider);
      await orderAlertService.acknowledgeInvoice(widget.invoice.id);

      // `mounted`, not `context.mounted`: what has to be alive for the
      // `ref.read` below is this ConsumerState, and reading `ref` after the
      // widget is disposed throws "Cannot use ref after the widget was
      // disposed".
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(l10n.invoiceOrderAccepted(_displayId(widget.invoice))),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 2),
        ),
      );

      // Refresh the kanban board to update the UI
      ref.read(kanbanProvider.notifier).loadInvoices();
    } catch (e) {
      // The guard belongs ABOVE the setState, not below it. Inverted, a card
      // disposed mid-await threw "setState() called after dispose()" from
      // inside a catch block — nothing could handle it, so it went fatal.
      if (!mounted) return;

      // Reset state on error
      setState(() {
        _isAccepting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  userErrorMessageFor(_errorLocalizations, _formatErrorMessage(e, fallback: l10n.commonError)),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _displayId(InvoiceCard invoice) => invoice.displayId;

  /// The delivery area shown on the card, resolved with the app-wide
  /// Arabic-first precedence so a card and the sheet it opens never disagree
  /// about where an order is going. Empty when the invoice carries no
  /// territory at all.
  String get _areaLabel => territoryLabel(
        nameAr: widget.invoice.territoryNameAr,
        display: widget.invoice.territoryDisplay,
        raw: widget.invoice.territory,
      );

  @override
  Widget build(BuildContext context) {
    final transitioning = ref.watch(kanbanProvider.select((s) => s.transitioningInvoices.contains(widget.invoice.id)));
    final card = _buildCard(transitioning);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 140),
      opacity: widget.isDragging ? 0.92 : (transitioning ? 0.55 : 1),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: widget.isDragging ? 1.02 : 1,
        child: Stack(
          children: [
            card,
            if (transitioning)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(bool transitioning) {
    final l10n = context.l10n;

    // Courier run progress for the run THIS card belongs to. Null whenever the
    // card is not a stop on anyone's run (a pickup, an unassigned order, or one
    // still in preparation), which is what keeps the badge off the vast majority
    // of cards on the board.
    final runProgress = widget.invoice.isCourierRunStop
        ? ref.watch(courierRunProgressProvider).forInvoice(widget.invoice)
        : null;
    final showMissedBadge = widget.invoice.hasOpenDeliveryFailure;

    // Show settlement only when backend indicates there is an unsettled courier transaction
    final hasUnsettled = widget.invoice.hasUnsettledCourierTxn;
    final hasPartner = (widget.invoice.salesPartner ?? '').isNotEmpty;
    final requiresAcceptance = widget.invoice.requiresAcceptance;
    final trailingWidgets = <Widget>[];
    
    // Responsive sizes
    final iconSize = ResponsiveUtils.getIconSize(context, small: 14, medium: 16, large: 18);
    final buttonIconSize = ResponsiveUtils.getIconSize(context, small: 12, medium: 14, large: 16);
    final buttonPadding = ResponsiveUtils.getButtonPadding(context,
      small: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      medium: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      large: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
    final buttonFontSize = ResponsiveUtils.getResponsiveFontSize(context, 12);

    // Add prominent acceptance button if pending (not already accepted or accepting)
    if (requiresAcceptance && !widget.invoice.isAccepted && !_isAccepting) {
      trailingWidgets.add(
        Tooltip(
          message: l10n.invoiceAcceptOrderTitle,
          child: Container(
            margin: const EdgeInsetsDirectional.only(end: 4),
            child: ElevatedButton.icon(
              onPressed: transitioning ? null : () => _acceptOrder(context),
              icon: Icon(Icons.check_circle, size: buttonIconSize),
              label: Text(l10n.invoiceAcceptAction, style: TextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: buttonPadding,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (widget.invoice.isPickup) {
      trailingWidgets.add(
        Container(
          margin: const EdgeInsetsDirectional.only(end: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.7)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.store_mall_directory, size: 12, color: Colors.indigo),
              const SizedBox(width: 4),
              Text(l10n.posCartPickupChip, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.indigo)),
            ],
          ),
        ),
      );
    }

    if (hasPartner) {
      trailingWidgets.add(
        Tooltip(
          message: l10n.systemStatusSalesPartnerFallback,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 2),
            child: Icon(
              Icons.handshake,
              size: iconSize,
              color: Colors.deepPurple,
            ),
          ),
        ),
      );
    }

    // The icon is the "there are notes — open them" affordance and follows the
    // combined signal, so note text alone keeps the entry point on the card.
    // The count badge is the one piece that genuinely needs a real count: it is
    // rendered only when noteCount > 0, so a broken/absent count drops the badge
    // rather than painting a misleading "0" over a card that demonstrably has
    // notes. Icon-without-badge degrades to "notes exist, quantity unknown",
    // which is exactly what we know in that case.
    if (widget.invoice.hasNoteSignal) {
      final noteCount = widget.invoice.noteCount;
      trailingWidgets.add(
        Tooltip(
          message: l10n.invoiceNotesTooltip,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.comment_outlined, size: iconSize),
                padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, small: 4, medium: 5, large: 6)),
                constraints: BoxConstraints(
                  minWidth: ResponsiveUtils.getIconSize(context, small: 32, medium: 34, large: 36),
                  minHeight: ResponsiveUtils.getIconSize(context, small: 32, medium: 34, large: 36),
                ),
                splashRadius: ResponsiveUtils.getIconSize(context, small: 16, medium: 18, large: 20),
                onPressed: transitioning ? null : () => _openInvoiceNotes(context),
              ),
              if (noteCount > 0)
                PositionedDirectional(
                  top: 2,
                  end: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      noteCount > 9 ? '9+' : noteCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final canShowPay = !hasPartner && widget.invoice.effectiveStatus.toLowerCase() != InvoiceStatus.paidLower && !hasUnsettled;
    if (canShowPay) {
      trailingWidgets.add(
        Tooltip(
          message: l10n.settlementPayAmount,
          child: IconButton(
            icon: Icon(Icons.payment, size: iconSize),
            padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, small: 4, medium: 5, large: 6)),
            constraints: BoxConstraints(
              minWidth: ResponsiveUtils.getIconSize(context, small: 32, medium: 34, large: 36),
              minHeight: ResponsiveUtils.getIconSize(context, small: 32, medium: 34, large: 36),
            ),
            splashRadius: ResponsiveUtils.getIconSize(context, small: 16, medium: 18, large: 20),
            onPressed: transitioning ? null : () => _payInvoice(context),
          ),
        ),
      );
    }

    // Removed "Out for Delivery" icon - functionality available elsewhere
    // final canShowDelivery = !_isPostOutForDelivery(widget.invoice.status);
    // if (canShowDelivery) {
    //   trailingWidgets.add(
    //     Tooltip(
    //       message: 'Delivery',
    //       child: IconButton(
    //         icon: Icon(Icons.local_shipping, size: iconSize),
    //         ...
    //       ),
    //     ),
    //   );
    // }

    // Preview Receipt and Print moved to three-dot menu for compactness

    // Add three-dot menu for additional actions
    // Line manager *or above* — a JARZ Manager and the admin tier hold every
    // line-manager capability, matching the backend's ROLES.LINE_MANAGER_TIER.
    final canActAsLineManager = ref.watch(canActAsLineManagerProvider);
    final managerAccessAsync = ref.watch(managerAccessProvider);
    final canManageCollectionChange = managerAccessAsync.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );
    final canShowCollectionChange = _canShowCollectionChangeAction(
      canManageCollectionChange,
    );
    
    trailingWidgets.add(
      Tooltip(
        message: l10n.invoiceMoreOptions,
        child: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: iconSize),
          padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, small: 4, medium: 5, large: 6)),
          constraints: BoxConstraints(
            minWidth: ResponsiveUtils.getIconSize(context, small: 32, medium: 34, large: 36),
            minHeight: ResponsiveUtils.getIconSize(context, small: 32, medium: 34, large: 36),
          ),
          splashRadius: ResponsiveUtils.getIconSize(context, small: 16, medium: 18, large: 20),
          enabled: !transitioning,
          onSelected: (value) async {
            if (value == 'add_note') {
              await _openInvoiceNotes(context);
            } else if (value == 'edit_address') {
              await _editCustomerAddress(context);
            } else if (value == 'add_pin') {
              await _addPin(context);
            } else if (value == 'share_tracking_link') {
              await _shareTrackingLink(context);
            } else if (value == 'print') {
              await _printInvoice(context);
            } else if (value == 'share_receipt') {
              await _sendReceipt(context, toWhatsApp: false);
            } else if (value == 'whatsapp_receipt') {
              await _sendReceipt(context, toWhatsApp: true);
            } else if (value == 'whatsapp_receipt_customer') {
              await _sendReceipt(context, toWhatsApp: true, toCustomer: true);
            } else if (value == 'transfer_order') {
              await _transferOrder(context);
            } else if (value == 'change_delivery_slot') {
              await _changeDeliverySlot(context);
            } else if (value == 'edit_invoice') {
              await _openAmendmentDraft(context);
            } else if (value == 'set_delivery_income') {
              await _setDeliveryIncome(context);
            } else if (value == 'cancel_order') {
              await _cancelOrder(context);
            } else if (value == 'return_order') {
              await _returnOrder(context);
            } else if (value == 'change_collection_method') {
              await _changeCollectionMethod(context);
            } else if (value == 'request_custom_shipping') {
              await _requestCustomShipping(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'add_note',
              child: Row(
                children: [
                  const Icon(Icons.comment_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.invoiceAddNote),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit_address',
              child: Row(
                children: [
                  const Icon(Icons.edit_location, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.invoiceEditCustomerAddress),
                ],
              ),
            ),
            if (widget.invoice.needsLocationPin)
              PopupMenuItem(
                value: 'add_pin',
                child: Row(
                  children: [
                    const Icon(Icons.pin_drop_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.courierLaunchPinAddAction),
                  ],
                ),
              ),
            if (_canShareTrackingLink)
              PopupMenuItem(
                value: 'share_tracking_link',
                child: Row(
                  children: [
                    const Icon(Icons.share_location, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.courierLaunchTrackingShare),
                  ],
                ),
              ),
            if (widget.invoice.canChangeDeliverySlot)
              PopupMenuItem(
                value: 'change_delivery_slot',
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.invoiceChangeDeliverySlot),
                  ],
                ),
              ),
            if (widget.invoice.canAmend)
              PopupMenuItem(
                value: 'edit_invoice',
                child: Row(
                  children: [
                    const Icon(Icons.edit_note, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.invoiceEditInvoice),
                  ],
                ),
              ),
            if (widget.invoice.canAmend)
              PopupMenuItem(
                value: 'set_delivery_income',
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(context.l10n.kanbanSetDeliveryIncome),
                  ],
                ),
              ),
            if (canShowCollectionChange)
              PopupMenuItem(
                value: 'change_collection_method',
                child: Row(
                  children: [
                    const Icon(Icons.sync_alt, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.invoiceChangeCollectionMethod),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  const Icon(Icons.print, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.commonPrint),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'whatsapp_receipt',
              child: Row(
                children: [
                  const Icon(Icons.chat_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.invoiceSendReceiptWhatsApp),
                ],
              ),
            ),
            // Straight to the customer's own chat, for a number the phone has
            // no chat with yet. Android only: a browser cannot attach the
            // image to a chosen number, so web keeps the other two entries.
            if (!kIsWeb && whatsappMsisdn(_customerPhone()).isNotEmpty)
              PopupMenuItem(
                value: 'whatsapp_receipt_customer',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.invoiceSendReceiptWhatsAppCustomer),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'share_receipt',
              child: Row(
                children: [
                  const Icon(Icons.share, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.invoiceShareReceipt),
                ],
              ),
            ),
            if (widget.invoice.canTransferOrder)
              PopupMenuItem(
                value: 'transfer_order',
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.invoiceTransferOrder),
                  ],
                ),
              ),
            if (canActAsLineManager && widget.invoice.canReturn)
                PopupMenuItem(
                  value: 'return_order',
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_return_outlined,
                          size: 18, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      Text(l10n.returnOrderTitle),
                    ],
                  ),
                ),
            if (canActAsLineManager && widget.invoice.canCancel)
                PopupMenuItem(
                  value: 'cancel_order',
                  enabled: !widget.invoice.hasPartialPayment,
                  child: Row(
                    children: [
                      Icon(Icons.cancel_presentation, size: 18, color: widget.invoice.hasPartialPayment ? Colors.grey : Colors.redAccent),
                      const SizedBox(width: 8),
                      Text(widget.invoice.hasPartialPayment ? l10n.invoiceCancelOrderSettleFirst : l10n.cancelOrderTitle),
                    ],
                  ),
                ),
              if (!widget.invoice.isPickup)
                PopupMenuItem(
                  value: 'request_custom_shipping',
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping, size: 18, color: Colors.deepOrange[700]),
                      const SizedBox(width: 8),
                      Text(l10n.kanbanRequestCustomShipping),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );

    // Removed "Settle Courier" icon - functionality available elsewhere
    // if (hasUnsettled) {
    //   trailingWidgets.add(
    //     Tooltip(
    //       message: 'Settle Courier',
    //       child: IconButton(
    //         icon: const Icon(Icons.handshake, size: 18, color: Colors.teal),
    //         ...
    //       ),
    //     ),
    //   );
    // }

    trailingWidgets.add(
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 4),
        child: AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
    if (widget.compact) {
      final fontSize = ResponsiveUtils.getResponsiveFontSize(context, 15);
      final titleFontSize = ResponsiveUtils.getResponsiveFontSize(context, 14);
      final padding = ResponsiveUtils.getCardPadding(context, 
        small: const EdgeInsets.all(8),
        medium: const EdgeInsets.all(10),
        large: const EdgeInsets.all(12),
      );
      
      return Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.blueAccent.withValues(alpha: 0.7),
            width: 2,
          ),
        ),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _displayId(widget.invoice),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.invoice.customerName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: titleFontSize * 0.85),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${widget.invoice.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Cards carrying notes get an amber wash + border so they are spottable from
    // across the board. Accepted / dragging treatments still win — this is the
    // lowest-priority accent. Follows the same combined signal as the preview
    // strip so a card with note text is flagged even with a broken count.
    final hasNoteSignal = widget.invoice.hasNoteSignal;
    final isAcceptedTreatment = widget.invoice.isAccepted || _isAccepting;

    Color borderColor;
    double borderWidth;
    if (isAcceptedTreatment) {
      borderColor = Colors.green[600]!;
      borderWidth = 2;
    } else if (widget.isDragging) {
      borderColor = Colors.blue;
      borderWidth = 2;
    } else if (hasNoteSignal) {
      borderColor = _noteAccentColor;
      borderWidth = 2;
    } else {
      borderColor = Colors.grey[300]!;
      borderWidth = 1;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: widget.isDragging ? 8 : 2,
        shadowColor: widget.isDragging ? Colors.blue.withValues(alpha: 0.3) : null,
        // Note cards get an amber wash so they are spottable from across the
        // board. It MUST stay opaque: passing the accent at low alpha straight
        // to Card.color made the whole card surface ~94% transparent, letting
        // the column gradient bleed through and dimming the card so its text was
        // hard to read. Blend the low-alpha accent over the theme card color so
        // the wash is preserved but the card renders at full opacity.
        color: hasNoteSignal
            ? Color.alphaBlend(
                _noteAccentColor.withValues(alpha: 0.06),
                Theme.of(context).cardColor,
              )
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            InkWell(
              onTap: _toggleExpansion,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                padding: ResponsiveUtils.getCardPadding(context,
                  small: const EdgeInsets.all(12),
                  medium: const EdgeInsets.all(14),
                  large: const EdgeInsets.all(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.invoice.hasUnsettledCourierTxn)
                          Container(
                            width: ResponsiveUtils.getIconSize(context, small: 8, medium: 9, large: 10),
                            height: ResponsiveUtils.getIconSize(context, small: 8, medium: 9, large: 10),
                            margin: EdgeInsetsDirectional.only(end: 6, top: ResponsiveUtils.getSpacing(context, small: 3, medium: 3.5, large: 4)),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepOrange.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: Text(
                            _displayId(widget.invoice),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (trailingWidgets.isNotEmpty) SizedBox(width: ResponsiveUtils.getSpacing(context, small: 6, medium: 7, large: 8)),
                        if (trailingWidgets.isNotEmpty)
                          Flexible(
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Wrap(
                                spacing: ResponsiveUtils.getSpacing(context, small: 2, medium: 3, large: 4),
                                runSpacing: ResponsiveUtils.getSpacing(context, small: 2, medium: 3, large: 4),
                                crossAxisAlignment: WrapCrossAlignment.center,
                                alignment: WrapAlignment.end,
                                children: trailingWidgets,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.getSpacing(context, small: 6, medium: 7, large: 8)),

                    // Customer and amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.invoiceCustomerLabel,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                widget.invoice.customerName,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // Delivery area on every card. Dispatchers group and
                              // hand out orders by area, and until now that meant
                              // opening each card: the sub-territory chip below only
                              // renders for territories that HAVE sub-territories,
                              // so most cards showed no location at all.
                              if (_areaLabel.isNotEmpty) ...[
                                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 1, medium: 1.5, large: 2)),
                                Row(
                                  children: [
                                    Icon(Icons.place_outlined, size: 11, color: Colors.grey[700]),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        _areaLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if ((widget.invoice.phone ?? widget.invoice.customerPhone ?? '').isNotEmpty) ...[
                                SizedBox(height: ResponsiveUtils.getSpacing(context, small: 1, medium: 1.5, large: 2)),
                                GestureDetector(
                                  onTap: () {
                                    final phone = widget.invoice.phone ?? widget.invoice.customerPhone;
                                    if (phone != null && phone.isNotEmpty) {
                                      _showPhoneOptions(context, phone);
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Icon(Icons.phone, size: 11, color: Colors.blue[700]),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          (widget.invoice.phone ?? widget.invoice.customerPhone)!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue[700],
                                            decoration: TextDecoration.underline,
                                          ),
                                          overflow: TextOverflow.visible,
                                          softWrap: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Payment method badge – only show when NOT fully paid
                              if (!widget.invoice.isFullyPaid && widget.invoice.effectiveCollectionMethod != null) ...[
                                const SizedBox(height: 4),
                                _buildPaymentMethodBadge(widget.invoice.effectiveCollectionMethod!),
                              ],
                              // Awaiting InstaPay confirmation badge (online order
                              // out for delivery, transfer not yet confirmed)
                              if (widget.invoice.isAwaitingOnlinePayment) ...[
                                const SizedBox(height: 4),
                                _buildAwaitingInstapayBadge(),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              l10n.posTotalLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              formatCurrency(context, widget.invoice.total),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            // Hide shipping expense line for Sales Partner invoices per new rule
                            if ((widget.invoice.salesPartner == null || widget.invoice.salesPartner!.isEmpty) && widget.invoice.shippingExpenseDisplay > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.invoiceShippingExpenseShort,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    formatCurrency(context, widget.invoice.shippingExpenseDisplay),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Date and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: widget.invoice.isFullyPaid && widget.invoice.actualPaymentMethod != null && widget.invoice.actualPaymentMethod!.isNotEmpty
                            ? _buildPaymentMethodBadge(widget.invoice.actualPaymentMethod!)
                            : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              widget.invoice.effectiveStatus,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            localizedStatusLabel(context, widget.invoice.effectiveStatus),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(widget.invoice.effectiveStatus),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ),
                        const SizedBox(width: 6),
                        // Show delivery slot label if available; fallback to posting date
                        Flexible(
                          child: Builder(builder: (context) {
                            final label = (widget.invoice.deliveryDateTimeLabel).trim();
                            final show = label.isNotEmpty;
                            return Text(
                              show ? label : widget.invoice.postingDateHumanized,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            );
                          }),
                        ),
                      ],
                    ),

                    // Latest note preview, on the card body so staff can read it
                    // without opening the notes sheet. Gated on the combined
                    // signal: note text alone is enough to draw this, even if
                    // the count is broken or absent.
                    if (widget.invoice.hasNoteSignal) ...[
                      const SizedBox(height: 8),
                      _buildNotePreviewStrip(context, transitioning),
                    ],

                    if (widget.invoice.hasUploadedPaymentReceipt)
                      _buildPaymentReceiptPreview(context),

                    // Sub-territory chip
                    if (widget.invoice.hasSubTerritories) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: transitioning ? null : () => _showSubTerritorySheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.invoice.subTerritory != null && widget.invoice.subTerritory!.isNotEmpty
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.invoice.subTerritory != null && widget.invoice.subTerritory!.isNotEmpty
                                  ? Colors.blue.withValues(alpha: 0.5)
                                  : Colors.orange.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.invoice.subTerritory != null && widget.invoice.subTerritory!.isNotEmpty
                                    ? Icons.location_on
                                    : Icons.location_searching,
                                size: 12,
                                color: widget.invoice.subTerritory != null && widget.invoice.subTerritory!.isNotEmpty
                                    ? Colors.blue
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.invoice.subTerritory != null && widget.invoice.subTerritory!.isNotEmpty
                                    ? (widget.invoice.subTerritoryDisplay ?? widget.invoice.subTerritory!)
                                    : context.l10n.subTerritorySelectTitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: widget.invoice.subTerritory != null && widget.invoice.subTerritory!.isNotEmpty
                                      ? Colors.blue
                                      : Colors.orange[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Map-pin state. Sits above the shipping/return badges
                    // because it is the one thing that has to be true *before*
                    // the order is dragged to Out for Delivery.
                    if (widget.invoice.showsLocationPinBadge) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _buildLocationPinBadge(transitioning),
                      ),
                    ],

                    // Courier run progress + this stop's own outcome. Directly
                    // below the pin because the two together are the whole
                    // "where is this delivery?" story: can the courier find it,
                    // and how far through the run are they.
                    if (runProgress != null || showMissedBadge) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (runProgress != null)
                              _buildCourierRunBadge(runProgress),
                            if (showMissedBadge) _buildDeliveryMissedBadge(),
                          ],
                        ),
                      ),
                    ],

                    // Custom shipping status badge
                    if (widget.invoice.shippingOverrideStatus != null &&
                        widget.invoice.shippingOverrideStatus!.isNotEmpty &&
                        widget.invoice.shippingOverrideStatus != 'null') ...[
                      const SizedBox(height: 4),
                      _buildShippingOverrideBadge(widget.invoice.shippingOverrideStatus!, widget.invoice.shippingOverride),
                    ],

                    // Return badge — matters most for a PARTIALLY returned order
                    // still sitting in an active column, where nothing else on
                    // the board says a credit note has been posted.
                    if (widget.invoice.hasReturn) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _buildReturnStatusBadge(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Expandable content
            SizeTransition(
              sizeFactor: _animation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.invoice.isPickup && widget.invoice.address.isNotEmpty) ...[
                      Text(
                        context.l10n.invoiceDeliveryAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.invoice.address,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (widget.invoice.items.isNotEmpty) ...[
                      Text(
                        context.l10n.invoiceItems,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.invoice.items.map(
                        (item) => _buildItemRow(item),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Courier launch: pin / tracking-link actions and the
                    // delivery timeline (role-gated, fetched only once the
                    // card is open).
                    if (_isExpanded && !widget.invoice.isPickup) ...[
                      _buildDeliveryActionsRow(),
                      if (ref.watch(canViewLiveCourierMapProvider))
                        OrderTimelineSection(invoiceId: widget.invoice.name),
                    ],

                    // Invoice totals
                    _buildTotalsSection(),

                    const SizedBox(height: 12),

                    // (Action buttons moved to header; keep spacing alignment placeholder)
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(InvoiceItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.itemName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'x${item.quantity.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatCurrency(context, item.amount),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    final hasPartner = (widget.invoice.salesPartner ?? '').isNotEmpty;
    final children = <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.l10n.invoiceNetTotal, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          Text(formatCurrency(context, widget.invoice.netTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
      const SizedBox(height: 4),
    ];
    if (!hasPartner && !widget.invoice.isPickup) {
      children.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.invoiceShippingIncome, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            Text(formatCurrency(context, widget.invoice.shippingIncomeDisplay), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      );
      children.add(const SizedBox(height: 4));
      children.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.invoiceShippingExpense, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            Text(formatCurrency(context, widget.invoice.shippingExpenseDisplay), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
    children.addAll([
      const Divider(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.l10n.invoiceGrandTotal, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(formatCurrency(context, widget.invoice.total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    ]);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case InvoiceStatus.draftLower:
        return Colors.grey;
      case 'submitted':
        return Colors.blue;
      case InvoiceStatus.paidLower:
        return Colors.green;
      case InvoiceStatus.cancelledLower:
        return Colors.red;
      case DeliveryStatus.returned:
      case 'credit note issued':
        return Colors.deepOrange;
      case 'overdue':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ignore: unused_element
  bool _isPostOutForDelivery(String status) {
    final s = status.toLowerCase();
    // Recognize states at or beyond the delivery dispatch stage
    return s == 'out for delivery' ||
        s == 'out_for_delivery' ||
        s.contains('out for delivery') ||
        s.contains('out_for_delivery') ||
        s == 'delivered' ||
        s == 'completed' ||
        s == 'returned';
  }

  void _payInvoice(BuildContext context) async {
    // New rule: allow payment in any state except already Paid or Cancelled
    final statusLower = widget.invoice.status.toLowerCase();
    if (statusLower == InvoiceStatus.paidLower || statusLower == InvoiceStatus.cancelledLower) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.invoiceAlreadyStatus(widget.invoice.status)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    final method = await _showPaymentMethodSheet(context);
    if (!mounted || !context.mounted || method == null) return;
    await _submitPayment(method); // TODO back-end integration
  }

  Future<String?> _showPaymentMethodSheet(BuildContext context) async {
    String? selected = PaymentModes.cash;
    // Kashier: an order taken as Cash that the customer then paid through a
    // Kashier payment link (order 17783). Branch staff cannot see the Kashier
    // dashboard, so only the line-manager tier is offered it -- and the
    // backend (`pay_invoice`, mode "Kashier") enforces the same gate.
    final canRecordKashier = ref.read(canActAsLineManagerProvider);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payment, size: 20),
                      const SizedBox(width: 8),
                      Text(context.l10n.invoiceSelectPaymentMethod,
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _paymentOptionTile(
                    title: context.l10n.paymentMethodInstapay,
                    value: 'InstaPay',
                    groupValue: selected,
                    onChanged: (v) => setModalState(() => selected = v),
                    icon: Icons.account_balance,
                  ),
                  _paymentOptionTile(
                    title: context.l10n.invoiceWallet,
                    value: 'Wallet',
                    groupValue: selected,
                    onChanged: (v) => setModalState(() => selected = v),
                    icon: Icons.account_balance_wallet,
                  ),
                  _paymentOptionTile(
                    title: context.l10n.paymentMethodCash,
                    value: PaymentModes.cash,
                    groupValue: selected,
                    onChanged: (v) => setModalState(() => selected = v),
                    icon: Icons.payments_outlined,
                  ),
                  if (canRecordKashier)
                    _paymentOptionTile(
                      // Brand name, shown untranslated like "Kashier Card"
                      // everywhere else in the app.
                      title: 'Kashier',
                      value: 'Kashier',
                      groupValue: selected,
                      onChanged: (v) => setModalState(() => selected = v),
                      icon: Icons.credit_card,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(context.l10n.commonCancel),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(ctx).pop(selected),
                        icon: const Icon(Icons.check, size: 16),
                        label: Text(context.l10n.invoiceSubmit),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _paymentOptionTile({
    required String title,
    required String value,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.green : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
          color: selected ? Colors.green.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? Colors.green : Colors.grey[600]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.green[800] : Colors.black87,
                ),
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? Colors.green : Colors.grey[600],
              size: 20,
            )
          ],
        ),
      ),
    );
  }

  Future<void> _submitPayment(String method) async {
    if (!mounted) return;
    // Read the localisations ONCE, up front, exactly as `_acceptOrder` does.
    //
    // `context.l10n` is `AppLocalizations.of(context)!`. Once the card leaves
    // the tree — a board rebuild after payment, a websocket refresh, a drag —
    // `Localizations.of` returns null and that `!` throws. The outer catch
    // below did this on the failure path, so the throw happened *inside* a
    // catch block: nothing above it could handle it, it reached
    // `PlatformDispatcher.onError`, and a failed payment became a fatal crash.
    // Hoisting removes the post-await dependency on `context` entirely, which
    // is stronger than sprinkling `context.mounted` at each use.
    final l10n = context.l10n;
    // Resolve KanbanNotifier
    final container = ProviderScope.containerOf(context, listen: false);
    final notifier = container.read(kanbanProvider.notifier);
    final posState = container.read(posNotifierProvider);
    final messenger = ScaffoldMessenger.of(context);

    if (method.toLowerCase() == PaymentModes.cashLower) {
      final String? posProfile = posState.selectedProfile?['name'];
      if (posProfile == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.invoiceNoPosProfileCash)),
        );
        return;
      }
      await _payAndReport(
        method: method,
        posProfile: posProfile,
        l10n: l10n,
        notifier: notifier,
        messenger: messenger,
      );
      return;
    }

    // InstaPay / Wallet. `pay_invoice` refuses these until a POS Payment
    // Receipt for the invoice is Confirmed AND carries the customer's transfer
    // screenshot. The card used to pay first and create the receipt only after
    // a success that could never come — a dead end on every order. The proof
    // now comes first; paying happens only once a manager has confirmed it.
    final receiptMethod = transferReceiptMethod(method);
    if (receiptMethod == null ||
        transferPaymentStepFor(widget.invoice, receiptMethod) ==
            TransferPaymentStep.payDirectly) {
      await _payAndReport(
        method: method,
        posProfile: null,
        l10n: l10n,
        notifier: notifier,
        messenger: messenger,
      );
      return;
    }

    final canConfirm = container.read(canActAsLineManagerProvider);
    final outcome = await TransferProofSheet.show(
      context,
      invoice: widget.invoice,
      method: receiptMethod,
      posProfile: transferReceiptPosProfile(
        widget.invoice,
        posState.selectedProfile?['name']?.toString(),
      ),
      canConfirm: canConfirm,
    );
    switch (outcome) {
      case null:
        return;
      case TransferProofOutcome.confirmed:
        await _payAndReport(
          method: method,
          posProfile: null,
          l10n: l10n,
          notifier: notifier,
          messenger: messenger,
        );
        return;
      case TransferProofOutcome.confirmedAndRecorded:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.receiptConfirmedSuccess),
            backgroundColor: Colors.green[700],
          ),
        );
        try {
          await notifier.loadInvoices();
        } catch (_) {
          // The realtime refresh will catch up; the payment is recorded.
        }
        return;
      case TransferProofOutcome.awaitingManager:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.transferProofAwaitingManager(
              receiptMethod == 'Wallet' ? l10n.invoiceWallet : l10n.paymentMethodInstapay,
            )),
            duration: const Duration(seconds: 6),
          ),
        );
        _refreshBoardQuietly(notifier);
        return;
      case TransferProofOutcome.awaitingConfirmation:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.transferProofAwaitingConfirmation),
            duration: const Duration(seconds: 6),
          ),
        );
        _refreshBoardQuietly(notifier);
        return;
      case TransferProofOutcome.receiptStateChanged:
        // The sheet already told the user why it stopped; a snackbar here
        // would repeat it. Reload only, so the next Pay sees the real receipt.
        _refreshBoardQuietly(notifier);
        return;
    }
  }

  /// Picks up the new receipt state so the next Pay press sees it.
  void _refreshBoardQuietly(KanbanNotifier notifier) {
    notifier.loadInvoices().catchError((_) {});
  }

  /// Calls `pay_invoice` and reports the result. Uses only references hoisted
  /// by the caller, never `context`, so it is safe after the card is disposed.
  Future<void> _payAndReport({
    required String method,
    required String? posProfile,
    required AppLocalizations l10n,
    required KanbanNotifier notifier,
    required ScaffoldMessengerState messenger,
  }) async {
    try {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.invoiceProcessingPayment(method))),
      );
      final result = await notifier.payInvoice(
        invoiceId: widget.invoice.name,
        paymentMode: method,
        posProfile: posProfile,
      );
      // Replace the "processing" note instead of queueing behind it, so the
      // outcome (and especially a refusal's reason) shows at once.
      messenger.hideCurrentSnackBar();
      if (result != null && result['success'] == true) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.invoicePaymentSuccess('${result['payment_entry']}'))),
        );
        // The collect-cash dialog for a cash payment is opened by
        // `notifier.payInvoice` through the shared, once-per-invoice gate. A
        // second dialog here stacked on top of it.
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.invoicePaymentFailed)),
        );
        _refreshBoardQuietly(notifier);
      }
    } catch (e) {
      // The server's reason, not a bare "Payment failed": the notifier now
      // rethrows instead of swallowing, and a missing confirmed transfer
      // receipt maps to its own localized instruction.
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(paymentFailureMessage(l10n, e)),
          duration: const Duration(seconds: 6),
        ),
      );
      // `payInvoice` reloads the board only on success. After the proof sheet
      // confirmed the receipt, a refusal here (no open shift, say) leaves the
      // receipt Confirmed and the invoice unpaid; on the stale card Pay
      // reopened the sheet, and a new screenshot was refused because a
      // Confirmed receipt is no longer editable. Reloaded, Pay goes straight
      // to `pay_invoice`.
      _refreshBoardQuietly(notifier);
    }
  }

  bool _canShowCollectionChangeAction(bool hasManagerAccess) {
    // Gated on the CUSTOMER still owing, not on the courier's row being unsettled.
    // Those are different questions, and the courier one answered this wrongly in both
    // directions: an unpaid online-intent order still owes its full grand total after a
    // shift close settles the courier's freight row, and a COD order switched to an
    // online method owes nothing while its shipping leg stays unsettled. Three orders
    // went unreachable on production on 2026-09-01 for the first reason -- the backend
    // would have served them; the card simply stopped offering the action.
    if (!hasManagerAccess ||
        !widget.invoice.hasUnsettledCustomerAmount ||
        widget.invoice.isPickup ||
        widget.invoice.isReturn ||
        (widget.invoice.salesPartner?.trim().isNotEmpty ?? false)) {
      return false;
    }

    final status = widget.invoice.status.trim().toLowerCase();
    return status.contains(DeliveryStatus.outForDelivery) ||
        status.contains(DeliveryStatus.outForDeliverySnake) ||
        status.contains(DeliveryStatus.delivered);
  }

  Future<void> _changeCollectionMethod(BuildContext context) async {
    final posState = ref.read(posNotifierProvider);
    final notifier = ref.read(kanbanProvider.notifier);
    final posProfile =
        (widget.invoice.posProfile ?? posState.selectedProfile?['name'])
            ?.toString();

    final request = await PaymentCollectionChangeDialog.show(
      context,
      invoice: widget.invoice,
      posProfile: posProfile,
    );
    if (request == null || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    if (posProfile == null || posProfile.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.invoiceSelectPosFirst)),
      );
      return;
    }

    try {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.invoiceChangingCollectionMethod)),
      );
      final result = await ref
          .read(courierServiceProvider)
          .changePaymentCollectionMethod(
            invoiceName: widget.invoice.name,
            newMethod: request.method,
            posProfile: posProfile,
            partyType: widget.invoice.courierPartyType,
            party: widget.invoice.courierParty,
            receiptName: request.receiptName,
            referenceNo: request.referenceNo,
            notes: request.notes,
            idempotencyToken: const Uuid().v4(),
          );

      if (!context.mounted) {
        return;
      }

      if (result['success'] == true) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.invoiceCollectionMethodChanged(
                localizedPaymentMethodLabel(context, request.method),
              ),
            ),
          ),
        );
        try {
          await notifier.refreshSingle(widget.invoice.name);
        } catch (_) {
          await notifier.loadInvoices();
        }
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.invoiceDeliveryFailed)),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final errorMessage = userErrorMessageFor(_errorLocalizations,
        error,
        fallback: context.l10n.invoiceDeliveryFailed,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            userErrorMessageFor(_errorLocalizations, errorMessage),
          ),
        ),
      );
    }
  }

  // ignore: unused_element
  Future<void> _handleOutForDelivery(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final notifier = container.read(kanbanProvider.notifier);
    final posState = container.read(posNotifierProvider);
    final messenger = ScaffoldMessenger.of(context);

    // Fast-path for Sales Partner invoices:
    // 1. If already paid + has Sales Partner -> direct state change (legacy fast path retained)
    // 2. NEW: If UNPAID + has Sales Partner -> auto create cash Payment Entry & OFD via backend endpoint (skip courier UI completely)
    final hasPartner = ((widget.invoice.salesPartner ?? '').isNotEmpty);
    final isPaid = (widget.invoice.status).toString().toLowerCase() == InvoiceStatus.paidLower || (widget.invoice.effectiveStatus).toString().toLowerCase() == InvoiceStatus.paidLower;
    final posProfileName = posState.selectedProfile?['name'];

    if (hasPartner) {
      final statusLower = (widget.invoice.status).toString().toLowerCase();
      final effLower = (widget.invoice.effectiveStatus).toString().toLowerCase();
      final isUnpaid = statusLower == 'unpaid' || effLower == 'unpaid' || statusLower == 'overdue' || effLower == 'overdue' || statusLower.contains('part') || effLower.contains('part');
      if (isUnpaid) {
        if (posProfileName == null) {
          messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceSelectPosFirst)));
          return;
        }
        messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceCollectingCashPartner)));
        try {
          // We don't have a direct method: call raw endpoint via notifier/apiService if available
          final raw = await container.read(kanbanProvider.notifier).callBackend(
            ApiEndpoints.salesPartnerUnpaidOutForDelivery,
            data: {
              'invoice_name': widget.invoice.name,
              'pos_profile': posProfileName,
              'mode_of_payment': PaymentModes.cash,
            },
          );
          if ((raw['success'] == true) || (raw['message']?['success'] == true)) {
            messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceCashCollectedOfd)));
            await notifier.refreshSingle(widget.invoice.name);
          } else {
            final errorMessage = _formatErrorMessage(
              raw['message'] ?? raw,
              fallback: context.l10n.invoiceDeliveryFailed,
            );
            messenger.showSnackBar(
              SnackBar(content: Text(userErrorMessageFor(_errorLocalizations, errorMessage))),
            );
          }
        } catch (e) {
          final errorMessage = userErrorMessageFor(_errorLocalizations,
            e,
            fallback: context.l10n.invoiceDeliveryFailed,
          );
          messenger.showSnackBar(
            SnackBar(content: Text(userErrorMessageFor(_errorLocalizations, errorMessage))),
          );
        }
        return;
      } else if (isPaid) {
        try {
          await notifier.updateInvoiceState(widget.invoice.name, 'Out For Delivery');
          messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceSentOfd)));
        } catch (e) {
          final errorMessage = userErrorMessageFor(_errorLocalizations,
            e,
            fallback: context.l10n.invoiceDeliveryFailed,
          );
          messenger.showSnackBar(
            SnackBar(content: Text(userErrorMessageFor(_errorLocalizations, errorMessage))),
          );
        }
        return;
      }
    }

    final result = await _showCourierSettlementDialog(context, hideSettleLater: true);
    if (result == null) return; // cancelled
    final courier = result['courier'] as String?;
    final courierDisplay = result['courier_display'] as String?;
    String? partyType = result['party_type'] as String?;
    String? party = result['party'] as String?;
    final mode = (result['mode'] ?? 'pay_now').toString();
    final posProfile = posState.selectedProfile?['name'];
    if (posProfile == null) {
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceSelectPosFirst)));
      return;
    }

    final courierLabel = courierDisplay?.isNotEmpty == true
        ? courierDisplay!
        : ((courier != null && courier.isNotEmpty) ? courier : 'UNKNOWN');

    if (mode == SettlementModes.later) {
      try {
        final courierService = ref.read(courierServiceProvider);
        final preview = await courierService.generateSettlementPreview(
          invoice: widget.invoice.name,
          partyType: partyType,
          party: party,
          mode: SettlementModes.later,
          recentPaymentSeconds: 30,
        );
        final previewPartyType = (preview['party_type'] ?? '').toString().trim();
        final previewParty = (preview['party'] ?? '').toString().trim();
        partyType = (partyType?.trim().isNotEmpty ?? false) ? partyType!.trim() : (previewPartyType.isNotEmpty ? previewPartyType : null);
        party = (party?.trim().isNotEmpty ?? false) ? party!.trim() : (previewParty.isNotEmpty ? previewParty : null);
        final token = (preview['preview_token'] ?? preview['token'] ?? '').toString();
        if (partyType == null || party == null || token.isEmpty) {
          messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceSettleLaterMissingParty)));
          return;
        }
        final res = await courierService.confirmSettlement(
          invoice: widget.invoice.name,
          previewToken: token,
          mode: SettlementModes.later,
          posProfile: posProfile,
          partyType: partyType,
          party: party,
          courier: courierLabel,
        );
        if (res['success'] == true) {
          messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceMarkedSettleLater)));
          try {
            await notifier.refreshSingle(widget.invoice.name);
          } catch (_) {}
        } else {
          messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceSettleLaterFailed)));
        }
      } catch (e) {
        final errorMessage = userErrorMessageFor(_errorLocalizations,
          e,
          fallback: context.l10n.invoiceSettleLaterFailed,
        );
        messenger.showSnackBar(
          SnackBar(content: Text(userErrorMessageFor(_errorLocalizations, errorMessage))),
        );
      }
      return;
    }

    // For pay_now flows always use preview -> confirm so backend handles paid/unpaid logic uniformly
    if (mode == SettlementModes.payNow) {
      try {
        final courierService = ref.read(courierServiceProvider);
        final preview = await courierService.generateSettlementPreview(
          invoice: widget.invoice.name,
          partyType: partyType,
          party: party,
          mode: mode,
          recentPaymentSeconds: 30,
        );
        final previewPartyType = (preview['party_type'] ?? '').toString().trim();
        final previewParty = (preview['party'] ?? '').toString().trim();
        partyType = (partyType?.trim().isNotEmpty ?? false) ? partyType!.trim() : (previewPartyType.isNotEmpty ? previewPartyType : null);
        party = (party?.trim().isNotEmpty ?? false) ? party!.trim() : (previewParty.isNotEmpty ? previewParty : null);
        if (partyType == null || party == null) {
          messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceSettlementMissingParty)));
          return;
        }
        if (!mounted) return;
        final confirmation = await showSettlementConfirmDialog(
          context,
          preview,
          invoice: widget.invoice.name,
          territory: territoryLabel(
            nameAr: widget.invoice.territoryNameAr,
            display: widget.invoice.territoryDisplay,
            raw: widget.invoice.territory,
          ),
          orderFallback: widget.invoice.grandTotal,
          shippingFallback: widget.invoice.shippingExpenseDisplay.toDouble(),
        );
        if (confirmation?.confirmed != true) return;
        final token = (preview['preview_token'] ?? preview['token'] ?? '').toString();
        if (token.isEmpty) {
          messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoicePreviewExpired)));
          return;
        }
        messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceConfirmingSettlement)));
        final res = await courierService.confirmSettlement(
          invoice: widget.invoice.name,
          previewToken: token,
          mode: mode,
          posProfile: posProfile,
          partyType: partyType,
          party: party,
          paymentMode: PaymentModes.cash,
          courier: courierLabel,
          partnerFee: confirmation?.partnerFee,
        );
        if (res['success'] == true) {
          messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceSettlementConfirmed)));
          try {
            await notifier.refreshSingle(widget.invoice.name);
          } catch (_) {}
        } else {
          messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceSettlementFailed)));
        }
      } catch (e) {
        final errorMessage = userErrorMessageFor(_errorLocalizations,
          e,
          fallback: context.l10n.invoiceSettlementFailed,
        );
        messenger.showSnackBar(
          SnackBar(content: Text(userErrorMessageFor(_errorLocalizations, errorMessage))),
        );
      }
      return;
    }

    try {
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceProcessingDelivery)));
      final res = await notifier.outForDeliveryUnified(
        invoiceId: widget.invoice.name,
        courier: courier ?? 'UNKNOWN',
        mode: mode,
        posProfile: posProfile,
        partyType: partyType,
        party: party,
        courierDisplay: courierDisplay,
      );
      if (res != null && res['success'] == true) {
        messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceUpdated)));
      } else {
        messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceDeliveryFailed)));
      }
    } catch (e) {
      final errorMessage = userErrorMessageFor(_errorLocalizations,
        e,
        fallback: context.l10n.invoiceDeliveryFailed,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(userErrorMessageFor(_errorLocalizations, errorMessage))),
      );
    }
  }

  Future<Map<String, dynamic>?> _showCourierSettlementDialog(BuildContext context, {bool hideSettleLater = true}) async {
    String? courier;
    String? partyType;
    String? party;
    String mode = OutForDeliverySettlement.defaultMode;
    bool loading = true;
    List<Map<String, String>> couriers = [];
    bool creating = false;
    String newPartyType = 'Supplier'; // Default to Supplier (Employee has validation issues on staging)
    bool isPartnerCourier = false;
    String? selectedDeliveryPartner;
    List<Map<String, String>> deliveryPartners = [];

    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();

    final container = ProviderScope.containerOf(context, listen: false);
    final posState = container.read(posNotifierProvider);
    final invoicePosProfile = (widget.invoice.posProfile ?? '').trim();
    final effectiveProfile = invoicePosProfile.isNotEmpty
        ? invoicePosProfile
        : posState.selectedProfile?['name']?.toString();
    final currentProfile = effectiveProfile != null
        ? posState.profiles.cast<Map<String, dynamic>?>().firstWhere(
            (profile) => profile?['name'] == effectiveProfile,
            orElse: () => posState.selectedProfile,
          )
        : posState.selectedProfile;
    final allowDeliveryPartner = currentProfile?['allow_delivery_partner'] == true;
    try {
      couriers = await container.read(kanbanProvider.notifier).getCouriers(posProfile: effectiveProfile);
      if (effectiveProfile != null) {
        couriers = couriers.where((c) => c['branch'] == effectiveProfile).toList();
      }
    } catch (_) {}
    loading = false;
    if (!context.mounted) return null;

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(context.l10n.commonCourierLabel),
            content: SizedBox(
              width: ResponsiveUtils.getDialogWidth(context, small: 350, medium: 480, large: 640),
              child: loading
                  ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.invoice.status.toLowerCase() == 'unpaid')
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                border: Border.all(color: Colors.amber.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline, size: 18, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      context.l10n.invoiceUnpaidWarning,
                                      style: const TextStyle(fontSize: 12, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!creating) ...[
                            if (couriers.isEmpty) ...[
                              const Icon(Icons.local_shipping_outlined, size: 48, color: Colors.orange),
                              const SizedBox(height: 12),
                              Text(context.l10n.kanbanNoCouriersAvailable, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text(context.l10n.kanbanCreateCourierHint, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                              const SizedBox(height: 16),
                            ] else ...[
                              LayoutBuilder(
                                builder: (ctx, constraints) {
                                  final isWide = constraints.maxWidth > 560;
                                  final crossAxisCount = isWide ? 3 : 2;
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: couriers.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      mainAxisExtent: 76, // fixed height: CircleAvatar(r:18)=36 + 12+12 padding + 2 text lines
                                    ),
                                    itemBuilder: (ctx, i) {
                                      final c = couriers[i];
                                      final selected = courier == c['party'];
                                      return InkWell(
                                        onTap: () => setState(() {
                                          courier = c['party'];
                                          partyType = c['party_type'];
                                          party = c['party'];
                                        }),
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: selected ? Colors.blue : Colors.grey[300]!,
                                              width: selected ? 2 : 1,
                                            ),
                                            color: selected ? Colors.blue.withValues(alpha: 0.06) : Colors.white,
                                            boxShadow: [
                                              if (selected)
                                                BoxShadow(
                                                  color: Colors.blue.withValues(alpha: 0.15),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor: selected ? Colors.blue : Colors.grey[200],
                                                child: Icon(Icons.person, color: selected ? Colors.white : Colors.grey[600]),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      c['display_name'] ?? c['party']!,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: selected ? Colors.blue[800] : Colors.black87,
                                                      ),
                                                    ),
                                                    if (c['delivery_partner'] != null && c['delivery_partner']!.isNotEmpty)
                                                      Text(
                                                        '🤝 ${c['delivery_partner']}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(fontSize: 10, color: Colors.deepPurple[600], fontWeight: FontWeight.w500),
                                                      )
                                                    else if (c['party_type'] != null)
                                                      Text(
                                                        c['party_type']!,
                                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: Text(context.l10n.kanbanNewCourier),
                                onPressed: () => setState(() => creating = true),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: firstNameController,
                                    decoration: InputDecoration(labelText: context.l10n.kanbanFirstName),
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: lastNameController,
                                    decoration: InputDecoration(labelText: context.l10n.kanbanLastName),
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: phoneController,
                              decoration: InputDecoration(labelText: context.l10n.kanbanPhone),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: newPartyType,
                              decoration: InputDecoration(labelText: context.l10n.kanbanType),
                              items: [
                                DropdownMenuItem(value: 'Employee', child: Text(context.l10n.kanbanEmployee)),
                                DropdownMenuItem(value: 'Supplier', child: Text(context.l10n.kanbanSupplier)),
                              ],
                              onChanged: (v) => setState(() => newPartyType = v ?? 'Employee'),
                            ),
                            if (allowDeliveryPartner) ...[
                              const SizedBox(height: 8),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                              title: Text(context.l10n.kanbanDeliveryPartnerCourier),
                                subtitle: Text(context.l10n.kanbanDeliveryPartnerCourierSubtitle, style: const TextStyle(fontSize: 12)),
                                value: isPartnerCourier,
                                onChanged: (v) async {
                                  setState(() => isPartnerCourier = v);
                                  if (v && deliveryPartners.isEmpty) {
                                    try {
                                      deliveryPartners = await container.read(kanbanProvider.notifier).getDeliveryPartnersList();
                                      setState(() {});
                                    } catch (_) {}
                                  }
                                  if (!v) {
                                    setState(() => selectedDeliveryPartner = null);
                                  }
                                },
                              ),
                              if (isPartnerCourier) ...[
                                if (deliveryPartners.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                  )
                                else
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedDeliveryPartner,
                                    decoration: InputDecoration(
                                        labelText: context
                                            .l10n.kanbanDeliveryPartnerField),
                                    items: deliveryPartners.map((dp) => DropdownMenuItem(
                                      value: dp['name'],
                                      child: Text(dp['partner_name'] ?? dp['name'] ?? ''),
                                    )).toList(),
                                    onChanged: (v) => setState(() => selectedDeliveryPartner = v),
                                  ),
                              ],
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: loading ? null : () => setState(() => creating = false),
                                  child: Text(context.l10n.kanbanBack),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: loading
                                      ? null
                                      : () async {
                                          final firstName = firstNameController.text.trim();
                                          final lastName = lastNameController.text.trim();
                                          final phone = phoneController.text.trim();
                                          if (firstName.isEmpty || lastName.isEmpty) return;
                                          setState(() => loading = true);
                                          try {
                                            final created = await container.read(kanbanProvider.notifier).createDeliveryParty(
                                              partyType: newPartyType,
                                              firstName: firstName,
                                              lastName: lastName,
                                              phone: phone,
                                              posProfile: effectiveProfile,
                                              deliveryPartner: isPartnerCourier ? selectedDeliveryPartner : null,
                                            );
                                            if (created != null) {
                                              couriers = [...couriers, created];
                                              courier = created['party'];
                                              partyType = created['party_type'];
                                              party = created['party'];
                                              creating = false;
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              final errorMessage = _formatErrorMessage(
                                                e,
                                                fallback: context.l10n.commonError,
                                              );
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(userErrorMessageFor(_errorLocalizations, errorMessage))),
                                              );
                                            }
                                          } finally {
                                            setState(() => loading = false);
                                          }
                                        },
                                  icon: const Icon(Icons.check),
                                  label: Text(context.l10n.commonSave),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (OutForDeliverySettlement.showModePicker) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(context.l10n.kanbanMode, style: Theme.of(context).textTheme.titleSmall),
                            ),
                            RadioGroup<String>(
                              groupValue: mode,
                              onChanged: (v) => setState(() => mode = v ?? mode),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RadioListTile<String>(
                                    title: Text(context.l10n.kanbanPayNowCash),
                                    value: SettlementModes.payNow,
                                    dense: true,
                                  ),
                                  if (!hideSettleLater)
                                    RadioListTile<String>(
                                      title: Text(context.l10n.kanbanSettleLater),
                                      subtitle: Text(context.l10n.kanbanSettleLaterSubtitle),
                                      value: SettlementModes.later,
                                      dense: true,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.l10n.commonCancel),
              ),
              if (!creating)
                ElevatedButton(
                  onPressed: courier == null || loading
                      ? null
                      : () => Navigator.pop(ctx, {
                            'courier': courier,
                            'mode': mode,
                            'party_type': partyType,
                            'party': party,
                            'courier_display': couriers.firstWhere(
                              (e) => e['party'] == courier,
                              orElse: () => const {},
                            )['display_name'],
                          }),
                  child: Text(context.l10n.commonConfirm),
                )
              else
                const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }

  // ignore: unused_element
  Future<void> _settleCourierTransaction(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final posProfile = ref.read(posNotifierProvider).selectedProfile?['name'];
    // Treat blank strings from model as null so we can adopt backend preview values
    String? partyType = (widget.invoice.courierPartyType?.trim().isEmpty ?? true)
        ? null
        : widget.invoice.courierPartyType;
    String? party = (widget.invoice.courierParty?.trim().isEmpty ?? true)
        ? null
        : widget.invoice.courierParty;
    if (posProfile == null) {
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceSelectPosFirst)));
      return;
    }

    try {
      // 1. Fetch settlement preview (signed net amount logic)
      final courierService = ref.read(courierServiceProvider);
      // Fallback: if invoice missing party info try preview without filters first to derive existing CT party
      Map<String, dynamic> preview;
      try {
        preview = await courierService.getSettlementPreview(
          invoice: widget.invoice.name,
          partyType: partyType,
          party: party,
        );
      } catch (_) {
        preview = await courierService.getSettlementPreview(invoice: widget.invoice.name);
      }
      // Adopt party derived by backend if we passed blanks / nulls
      if (partyType == null || partyType.trim().isEmpty) {
        final pv = (preview['party_type'] ?? '').toString().trim();
        if (pv.isNotEmpty) partyType = pv;
      }
      if (party == null || party.trim().isEmpty) {
        final pv = (preview['party'] ?? '').toString().trim();
        if (pv.isNotEmpty) party = pv;
      }
      // Validate we now have party identifiers (backend endpoints require them)
      if (partyType == null || partyType.isEmpty || party == null || party.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceCannotSettleParty)));
        return;
      }
      if (!context.mounted) return;

      // 2. Show confirmation dialog with collect / pay details (shared helper)
      final confirmation = await showSettlementConfirmDialog(
        context,
        preview,
        invoice: widget.invoice.name,
        territory: territoryLabel(
          nameAr: widget.invoice.territoryNameAr,
          display: widget.invoice.territoryDisplay,
          raw: widget.invoice.territory,
        ),
        orderFallback: widget.invoice.grandTotal, // use invoice total when preview omits
        shippingFallback: (widget.invoice.shippingExpenseDisplay).toDouble(),
      );
      if (confirmation?.confirmed != true) return; // user cancelled

      // 3. Determine which backend endpoint based on net amount sign
      final netRaw = preview['net_amount'];
      final net = (netRaw is num) ? netRaw.toDouble() : double.tryParse(netRaw?.toString() ?? '0') ?? 0.0;

      final notifier = ref.read(kanbanProvider.notifier);
      Map<String, dynamic>? res;

      if (net > 0) {
        // Branch collects from courier (courier collected payment from customer)
        res = await notifier.settleCourierCollectedPayment(
          invoiceId: widget.invoice.name,
          posProfile: posProfile,
          partyType: partyType,
          party: party,
        );
      } else if (net < 0) {
        // Branch pays courier shipping expense
        res = await notifier.settleSingleInvoicePaid(
          invoiceId: widget.invoice.name,
          posProfile: posProfile,
          partyType: partyType,
          party: party,
        );
      } else {
        messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceNothingToSettle)));
        return;
      }

  if (!context.mounted) return;
      if (res != null && (res['success'] == true || res['journal_entry'] != null)) {
        messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceSettlementComplete)));
        try {
          await ref.read(kanbanProvider.notifier).loadInvoices();
        } catch (_) {}
      } else {
        messenger.showSnackBar(SnackBar(content: Text(context.l10n.invoiceSettlementFailed)));
      }
    } catch (e) {
      final errorMessage = userErrorMessageFor(_errorLocalizations,
        e,
        fallback: context.l10n.invoiceSettlementFailed,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(userErrorMessageFor(_errorLocalizations, errorMessage))),
      );
    }
  }

  /// Build payment method badge with color coding
  Widget _buildPaymentMethodBadge(String paymentMethod) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (paymentMethod) {
      case PaymentModes.cash:
        bgColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        icon = Icons.attach_money;
        break;
      case 'Instapay':
        bgColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        icon = Icons.account_balance;
        break;
      case 'Mobile Wallet':
        bgColor = Colors.purple[50]!;
        textColor = Colors.purple[700]!;
        icon = Icons.phone_android;
        break;
      // A delivery partner collected online on our behalf. Deliberately NOT the
      // green cash styling: the whole point of the fix behind this case is that
      // these orders must not read as cash at a glance.
      case 'Online':
        bgColor = Colors.teal[50]!;
        textColor = Colors.teal[700]!;
        icon = Icons.language;
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        icon = Icons.payment;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 4),
          Text(
            localizedPaymentMethodLabel(context, paymentMethod),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge shown on InstaPay-on-delivery orders that are out for delivery but
  /// still awaiting the manager's bank-transfer confirmation. Reuses the
  /// [_buildPaymentMethodBadge] visual style with an amber "awaiting" accent.
  Widget _buildAwaitingInstapayBadge() {
    final bgColor = Colors.amber[50]!;
    final textColor = Colors.amber[900]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_top, size: 10, color: textColor),
          const SizedBox(width: 4),
          Text(
            context.l10n.instapayAwaitingBadge,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingOverrideBadge(String status, double? amount) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'Pending':
        bgColor = Colors.orange[50]!;
        textColor = Colors.orange[800]!;
        icon = Icons.hourglass_top;
        label = context.l10n.customShippingBadgePending;
        break;
      case 'Approved':
        bgColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        label = amount != null
            ? context.l10n.customShippingBadgeAmount(formatCurrency(context, amount))
            : context.l10n.customShippingBadgeApproved;
        break;
      case 'Rejected':
        bgColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        label = context.l10n.customShippingBadgeRejected;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }

  /// Badge for an order with a posted credit note against it.
  ///
  /// A fully returned order already lives in the terminal "Returned" column, so
  /// the column itself carries that message; this badge earns its keep on the
  /// PARTIALLY returned card that is still sitting in an active column and
  /// otherwise looks like an ordinary order. Same shape/typography as
  /// [_buildShippingOverrideBadge] so the card keeps one badge language.
  Widget _buildReturnStatusBadge() {
    final invoice = widget.invoice;
    if (!invoice.hasReturn) return const SizedBox.shrink();

    final isFull = invoice.isFullyReturned;
    final bgColor = isFull ? Colors.red[50]! : Colors.orange[50]!;
    final textColor = isFull ? Colors.red[700]! : Colors.orange[800]!;
    // One icon for both states, deliberately. Full vs partial is already carried
    // by the background colour, the text colour and the label itself, so a
    // filled/outlined variant adds no information — but Icons.assignment_return
    // is used nowhere else in the app, and pulling a new glyph into the
    // tree-shaken MaterialIcons font changes an asset. That makes the Shorebird
    // production patch fail with UnpatchableChangeException and forces a full
    // APK that every staff member has to install by hand (it did exactly that on
    // 2026-08-03). Not worth it for a redundant icon weight.
    const icon = Icons.assignment_return_outlined;

    final amount = invoice.returnedAmount;
    final String label;
    if (amount > 0) {
      final money = formatCurrency(context, amount);
      label = isFull
          ? context.l10n.returnBadgeFullAmount(money)
          : context.l10n.returnBadgePartialAmount(money);
    } else {
      label = isFull
          ? context.l10n.returnBadgeFull
          : context.l10n.returnBadgePartial;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Pinned" / "No map pin" chip.
  ///
  /// The missing state is the one that matters: a courier sent out with no
  /// coordinates has nothing but a free-text address to work from. Tapping it
  /// opens the same address dialog as the menu action, so the fix is one tap
  /// from the card rather than buried behind the overflow menu. When the card
  /// carries a Maps URL ([InvoiceCard.mapsUrl]), tap opens the pin in Google
  /// Maps instead and long-press opens the address dialog.
  ///
  /// Both icons (`location_on`, `location_searching`) are already used by the
  /// sub-territory chip on this card. That is deliberate — pulling a new glyph into
  /// the tree-shaken MaterialIcons font changes an asset, which makes the
  /// Shorebird production patch fail with UnpatchableChangeException and forces
  /// a full APK install for everyone.
  ///
  /// When the backend flags the pin ([InvoiceCard.hasPinWarning]) the chip
  /// turns amber with the `wrong_location_outlined` glyph (already in the font
  /// via the attendance screens, so still patchable) and the tooltip explains
  /// each flag. With no Maps URL a warning chip's tap only reveals that
  /// tooltip; long-press still opens the address editor.
  Widget _buildLocationPinBadge(bool transitioning) {
    final invoice = widget.invoice;
    final pinned = invoice.hasLocationPin;
    final warning = invoice.hasPinWarning;

    final color = warning
        ? Colors.amber[900]!
        : (pinned ? Colors.green[700]! : Colors.orange[800]!);
    final label = pinned
        ? context.l10n.kanbanPinBadgePinned
        : context.l10n.kanbanPinBadgeMissing;
    final tooltip = warning
        ? _pinWarningMessage(invoice.pinFlags)
        : pinned
            ? context.l10n.kanbanPinBadgePinnedTooltip
            : context.l10n.kanbanPinBadgeMissingTooltip;
    final icon = warning
        ? Icons.wrong_location_outlined
        : (pinned ? Icons.location_on : Icons.location_searching);

    // With a Maps URL, tap navigates and long-press edits the address. The
    // tooltip's own long-press trigger is switched off in that case so it
    // cannot compete with the edit gesture. A warning chip without a Maps URL
    // shows its tooltip on tap (nothing to navigate to) and edits on
    // long-press.
    final mapsUrl = invoice.mapsUrl;
    final hasMapsUrl = mapsUrl != null;
    final warningOnly = warning && !hasMapsUrl;

    return Tooltip(
      key: _pinTooltipKey,
      message: tooltip,
      triggerMode:
          hasMapsUrl || warningOnly ? TooltipTriggerMode.manual : null,
      child: GestureDetector(
        onTap: transitioning
            ? null
            : hasMapsUrl
                ? () => _openMapsUrl(mapsUrl)
                : warningOnly
                    ? () => _pinTooltipKey.currentState?.ensureTooltipVisible()
                    : pinned
                        ? () => _editCustomerAddress(context)
                        : () => _addPin(context),
        onLongPress: transitioning || !(hasMapsUrl || warningOnly)
            ? null
            : () => _editCustomerAddress(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 11,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final GlobalKey<TooltipState> _pinTooltipKey = GlobalKey<TooltipState>();

  /// Human text for the backend's `pin_flag` tokens, one line per flag.
  ///
  /// Inline Arabic/English rather than new `.arb` keys: an `.arb` edit forces a
  /// full APK, and this has to ship as a Shorebird patch.
  String _pinWarningMessage(List<String> flags) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String describe(String flag) {
      switch (flag) {
        case InvoiceCard.pinFlagOutsideArea:
          return arabic
              ? 'الدبوس خارج منطقة التوصيل المختارة'
              : 'Pin outside the chosen delivery area';
        case InvoiceCard.pinFlagAreaMismatch:
          return arabic
              ? 'الدبوس لا يطابق المنطقة المختارة'
              : "Pin doesn't match the chosen area";
        case InvoiceCard.pinFlagOutsideEgypt:
          return arabic
              ? 'الدبوس خارج مصر — تم تجاهل الموقع'
              : 'Pin is outside Egypt — location ignored';
        case InvoiceCard.pinFlagPinRemoved:
          return arabic
              ? 'العميل حذف الدبوس — لا يوجد موقع لهذا الطلب'
              : 'Customer removed the pin — no location for this order';
        default:
          return arabic ? 'تحذير على الدبوس: $flag' : 'Pin warning: $flag';
      }
    }

    return flags.map(describe).join('\n');
  }

  /// Opens the pin in the Google Maps app (or the browser). A failed launch is
  /// swallowed: nothing destructive should follow a tap on a status chip.
  Future<void> _openMapsUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No Maps app / browser available — leave the card as it is.
    }
  }

  /// Courier run progress — "Stop 3 · 7/12 delivered".
  ///
  /// Lets a dispatcher read how far a courier has got without phoning them. The
  /// counts come from the board itself (see [courierRunProgressProvider]), so the
  /// badge can never disagree with the cards around it.
  ///
  /// Icons are reused from glyphs already in this app's tree-shaken
  /// MaterialIcons font (`local_shipping` and `error_outline` are each used in
  /// 20+ places). Pulling in a NEW glyph changes an asset, which makes the
  /// Shorebird production patch fail with UnpatchableChangeException and forces a
  /// full APK install on every device — see the same note on the pin badge above.
  Widget _buildCourierRunBadge(CourierRunProgress progress) {
    final l10n = context.l10n;
    final invoice = widget.invoice;

    final color = progress.isComplete
        ? Colors.green[700]!
        : (progress.hasFailures ? Colors.orange[800]! : Colors.indigo[700]!);

    final parts = <String>[];
    final stopNumber = invoice.stopNumber;
    // Sequencing is optional by contract (§2: 0 = unsequenced). An unsequenced
    // run simply omits this and still reports progress.
    if (stopNumber != null) {
      parts.add(l10n.kanbanRunStopLabel(stopNumber));
    }
    parts.add(
      l10n.kanbanRunProgressLabel(progress.delivered, progress.total),
    );
    if (progress.hasFailures) {
      parts.add(l10n.kanbanRunFailedLabel(progress.failed));
    }

    return Tooltip(
      message: progress.hasFailures
          ? l10n.kanbanRunFailedTooltip(progress.failed)
          : l10n.kanbanRunProgressTooltip(
              progress.courierLabel,
              progress.delivered,
              progress.total,
            ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              parts.join(' · '),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// This specific stop was attempted and not delivered.
  ///
  /// A failed delivery deliberately does NOT change the invoice state
  /// (COURIER_CONTRACTS §5 invariant 4), so the card stays in Out for Delivery
  /// and nothing else on the board would say the attempt was missed.
  Widget _buildDeliveryMissedBadge() {
    final l10n = context.l10n;
    final color = Colors.deepOrange[700]!;
    final attempts = widget.invoice.deliveryAttemptNo ?? 1;

    return Tooltip(
      message: l10n.kanbanRunAttemptFailedTooltip(attempts < 1 ? 1 : attempts),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              l10n.kanbanRunAttemptFailedLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSubTerritorySheet(BuildContext context) async {
    final service = ref.read(kanbanServiceProvider);
    final territory = widget.invoice.territory;
    if (territory.isEmpty) return;

    try {
      final subTerritories = await service.getSubTerritories(territory);
      if (!context.mounted) return;

      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SubTerritorySelectionSheet(
          territory: territory,
          subTerritories: subTerritories,
          currentSelection: widget.invoice.subTerritory,
        ),
      );

      if (selected != null && selected.isNotEmpty && context.mounted) {
        await service.setInvoiceSubTerritory(widget.invoice.id, selected);
        // Refresh invoices to get updated data
        ref.read(kanbanProvider.notifier).loadInvoices();
      }
    } catch (e) {
      if (context.mounted) {
        final errorMessage = _withActionPrefix(
          context.l10n.subTerritoryLoadFailed,
          e,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userErrorMessageFor(_errorLocalizations, errorMessage))),
        );
      }
    }
  }

  Future<void> _requestCustomShipping(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => CustomShippingRequestDialog(
        invoiceName: widget.invoice.id,
        currentShippingExpense: widget.invoice.shippingExpenseDisplay,
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      final service = ref.read(kanbanServiceProvider);
      await service.requestCustomShipping(
        invoiceName: widget.invoice.id,
        amount: result['amount'] as double,
        reason: result['reason'] as String,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.kanbanCustomShippingSubmitted)),
        );
        ref.read(kanbanProvider.notifier).loadInvoices();
      }
    } catch (e) {
      if (context.mounted) {
        final errorMessage = _formatErrorMessage(
          e,
          fallback: context.l10n.commonError,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userErrorMessageFor(_errorLocalizations, errorMessage))),
        );
      }
    }
  }

  Future<void> _openAmendmentDraft(BuildContext context) async {
    try {
      final details = await ref.read(invoiceDetailsProvider(widget.invoice.id).future);
      if (!context.mounted) return;

      if (details == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.invoiceEditInvoiceFailed)),
        );
        return;
      }

      if (!details.canAmend) {
        final message = (details.amendmentBlockReason ?? '').trim().isNotEmpty
            ? userErrorMessageFor(_errorLocalizations, details.amendmentBlockReason, fallback: context.l10n.invoiceAmendmentUnavailable)
            : context.l10n.invoiceAmendmentUnavailable;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }

      context.push(
        AppRoutes.pos,
        extra: {
          'mode': 'amendment_draft',
          'invoice': details.toJson(),
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      final message = _withActionPrefix(
        context.l10n.invoiceEditInvoiceFailed,
        e,
        fallback: context.l10n.invoiceEditInvoiceFailed,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: context.l10n.commonRetry,
            onPressed: () => _openAmendmentDraft(context),
          ),
        ),
      );
    }
  }

  Future<void> _setDeliveryIncome(BuildContext context) async {
    if (!widget.invoice.canAmend) return;

    final controller = TextEditingController(
      text: widget.invoice.customDeliveryIncome != null
          ? widget.invoice.customDeliveryIncome!.toStringAsFixed(2)
          : '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.kanbanSetDeliveryIncome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.kanbanDeliveryIncomeHelp,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: context.l10n.kanbanDeliveryIncomeField,
                prefixText: currencySymbol(context),
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.kanbanFilterApply),
          ),
        ],
      ),
    );
    // Capture text before disposing
    final raw = controller.text.trim();
    controller.dispose();

    if (confirmed != true || !context.mounted) return;

    // Parse the typed value (empty = revert to territory default = null on backend)
    double? incomeOverride;
    if (raw.isNotEmpty) {
      incomeOverride = double.tryParse(raw);
      if (incomeOverride == null || incomeOverride < 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.kanbanInvalidAmount)),
          );
        }
        return;
      }
    }

    // Load detailed invoice to get the items for cart reconstruction
    try {
      final details = await ref.read(invoiceDetailsProvider(widget.invoice.id).future);
      if (!context.mounted) return;

      if (details == null || !details.canAmend) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              details?.amendmentBlockReason?.isNotEmpty == true
                  ? details!.amendmentBlockReason!
                  : 'This order cannot be amended',
            ),
          ),
        );
        return;
      }

      // Bundle orders are supported: the backend rebuilds the cart from the
      // invoice rows, so no client-side reconstruction is needed here.

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.kanbanUpdatingDeliveryIncome),
          duration: const Duration(seconds: 30),
        ),
      );

      final service = ref.read(kanbanServiceProvider);
      final result = await service.setDeliveryIncomeAmendment(
        invoice: details,
        customDeliveryIncome: incomeOverride,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              incomeOverride != null
                  ? context.l10n.kanbanDeliveryIncomeUpdated(
                      formatCurrency(context, incomeOverride))
                  : context.l10n.kanbanDeliveryIncomeReset,
            ),
          ),
        );
        // Refresh the Kanban board so the card re-targets the new invoice
        ref.read(kanbanProvider.notifier).loadInvoices();
      } else {
        // `success: false` carries the server's reason (`error`). Show it as
        // written: the generic presenter reduced most refusals to "something
        // went wrong", and in Arabic dropped every English one.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              amendmentRefusalMessageFor(_errorLocalizations, result['error']),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userErrorMessageFor(_errorLocalizations, e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// A tracking link only makes sense for a delivery order that is still
  /// alive (not cancelled / returned).
  bool get _canShareTrackingLink {
    final invoice = widget.invoice;
    if (invoice.isPickup) return false;
    final status = invoice.status.trim().toLowerCase();
    return status != InvoiceStatus.cancelledLower && !status.contains('return');
  }

  Widget _buildDeliveryActionsRow() {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (widget.invoice.needsLocationPin)
            OutlinedButton.icon(
              key: const ValueKey('invoice_card_add_pin'),
              onPressed: () => _addPin(context),
              icon: const Icon(Icons.pin_drop_outlined, size: 16),
              label: Text(l10n.courierLaunchPinAddAction),
            ),
          if (_canShareTrackingLink)
            OutlinedButton.icon(
              key: const ValueKey('invoice_card_share_tracking'),
              onPressed: () => _shareTrackingLink(context),
              icon: const Icon(Icons.share_location, size: 16),
              label: Text(l10n.courierLaunchTrackingShare),
            ),
        ],
      ),
    );
  }

  /// "Add pin": resolve the order's shipping address, open the paste-a-link /
  /// pick-on-map sheet, and refresh the card so the badge turns green.
  Future<void> _addPin(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(kanbanServiceProvider);

    String addressName;
    try {
      final book = await service.getCustomerShippingAddresses(
        customer: widget.invoice.customer,
        invoice: widget.invoice.name,
      );
      addressName = book['selected_address_name']?.toString().trim() ?? '';
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _formatErrorMessage(
              e,
              fallback: l10n.customerShippingAddressLoadFailed,
            ),
          ),
        ),
      );
      return;
    }
    if (!context.mounted) return;
    if (addressName.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.courierLaunchPinNoAddress)),
      );
      return;
    }

    final saved = await showAddPinSheet(context, addressName: addressName);
    if (!saved || !mounted) return;
    await ref.read(kanbanProvider.notifier).refreshSingle(widget.invoice.name);
  }

  Future<void> _shareTrackingLink(BuildContext context) {
    return shareTrackingLink(
      context,
      ref,
      invoiceId: widget.invoice.name,
      fallbackPhone: widget.invoice.customerPhone,
    );
  }

  Future<void> _openInvoiceNotes(BuildContext context) async {
    await InvoiceNotesSheet.show(
      context,
      invoice: widget.invoice,
    );
  }

  /// Edit customer address dialog
  Future<void> _editCustomerAddress(BuildContext context) async {
    final service = ref.read(kanbanServiceProvider);
    final addressRepo = ref.read(customerAddressRepositoryProvider);

    Map<String, dynamic> addressBook;
    List<Map<String, dynamic>> territories;
    try {
      final results = await Future.wait([
        service.getCustomerShippingAddresses(
          customer: widget.invoice.customer,
          invoice: widget.invoice.name,
        ),
        addressRepo.getTerritories(),
      ]);
      addressBook = results[0] as Map<String, dynamic>;
      territories = (results[1] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (!context.mounted) return;
      final errorMessage = _formatErrorMessage(
        e,
        fallback: context.l10n.customerShippingAddressLoadFailed,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userErrorMessageFor(_errorLocalizations, errorMessage))),
      );
      return;
    }

    if (!context.mounted) return;

    final addresses = (addressBook['addresses'] as List? ?? const [])
        .whereType<Map>()
        .map((address) => Map<String, dynamic>.from(address))
        .toList();

    final result = await CustomerShippingAddressDialog.show(
      context,
      customerName: widget.invoice.customerName,
      customer: widget.invoice.customer,
      addresses: addresses,
      territories: territories,
      initialSelectedAddressName:
          addressBook['selected_address_name']?.toString() ?? '',
      initialPhone: addressBook['default_phone']?.toString() ??
          widget.invoice.customerPhone ??
          '',
      repository: addressRepo,
      title: context.l10n.invoiceEditAddress,
    );

    if (result == null || !context.mounted) return;

    // Show loading indicator
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(context.l10n.invoiceUpdatingAddress),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      // Step 1: Save/link the address (or create new) on the customer.
      final saveResult = await service.saveCustomerShippingAddress(
        customer: widget.invoice.customer,
        phone: result['phone'] ?? '',
        invoice: widget.invoice.name,
        addressName: result['address_name'],
        address: result['address'],
        // Forward the territory the user picked so a brand-new address is
        // stamped with the chosen territory (not the customer's old default).
        territory: result['territory'],
        // Maps link + resolved pin, present only when staff touched the link
        // field in the dialog.
        locationLink: result['location_link'],
        latitude: double.tryParse(result['latitude'] ?? ''),
        longitude: double.tryParse(result['longitude'] ?? ''),
        geoSource: result['geo_source'],
      );

      // Step 2: If we have a resolved address_name, recompute shipping on the
      // submitted invoice (territory change detection + expense update).
      // The backend returns the resolved/created address under
      // `selected_address_name`; a brand-new address has no `address_name` in
      // the dialog result, so relying on that key skipped the recompute and
      // left the invoice on its old territory/shipping cost.
      final resolvedAddressName = (saveResult['selected_address_name'] ??
              result['address_name'])
          ?.toString();

      if (resolvedAddressName != null && resolvedAddressName.isNotEmpty) {
        try {
          final changeResult = await service.changeInvoiceShippingAddress(
            invoiceName: widget.invoice.name,
            addressName: resolvedAddressName,
          );

          messenger.clearSnackBars();

          final territoryChanged = changeResult['territory_changed'] == true;
          if (territoryChanged) {
            final oldExpense =
                (changeResult['old_expense'] ?? 0).toString();
            final newExpense =
                (changeResult['new_expense'] ?? 0).toString();
            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.invoiceAddressUpdatedWithShipping(
                          oldExpense,
                          newExpense,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green[700],
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (changeResult['territory_resolved'] == false) {
            // The address saved, but its city maps to no Territory — so the
            // shipping cost was NOT recomputed and the courier would settle at
            // the old rate. Say so rather than showing a plain success tick.
            final city = (changeResult['unresolved_city'] ?? '').toString();
            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.kanbanAddressNoTerritory(city),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange[800],
                duration: const Duration(seconds: 7),
              ),
            );
          } else {
            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(context.l10n.invoiceAddressUpdated),
                  ],
                ),
                backgroundColor: Colors.green[600],
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (changeError) {
          // changeInvoiceShippingAddress failed (e.g. mutation blocked).
          messenger.clearSnackBars();
          final errMsg = _formatErrorMessage(
            changeError,
            fallback: context.l10n.invoiceAddressUpdateFailed,
          );
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(userErrorMessageFor(_errorLocalizations, errMsg))),
                ],
              ),
              backgroundColor: Colors.red[600],
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(context.l10n.invoiceAddressUpdated),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 3),
          ),
        );
      }

      await ref.read(kanbanProvider.notifier).refreshSingle(widget.invoice.name);
    } catch (e) {
      messenger.clearSnackBars();
      final errorMessage = _formatErrorMessage(
        e,
        fallback: context.l10n.invoiceAddressUpdateFailed,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      userErrorMessageFor(_errorLocalizations, errorMessage))),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Show dialog with options to call or copy phone number
  Future<void> _showPhoneOptions(BuildContext context, String phoneNumber) async {
    // Remove any whitespace or formatting to get clean number
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.phone, color: Colors.blue),
            const SizedBox(width: 8),
            Text(context.l10n.invoicePhoneNumber),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the phone number (non-selectable, non-trimmed)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      phoneNumber, // Display original format with spaces
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              // Copy to clipboard
              await Clipboard.setData(ClipboardData(text: cleanNumber));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(context.l10n.invoiceCopiedNumber(cleanNumber)),
                      ],
                    ),
                    backgroundColor: Colors.green[600],
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: Text(context.l10n.invoiceCopy),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[700],
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              // Launch phone dialer
              final uri = Uri(scheme: 'tel', path: cleanNumber);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(context.l10n.invoiceCannotCall),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.call),
            label: Text(context.l10n.invoiceCall),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  // Transfer order to another branch / Kanban profile.
  /// Post-dispatch return: preview on the server, confirm, then submit.
  ///
  /// The preview is fetched rather than derived locally because only the server
  /// knows how much of each line was already returned, where the customer's
  /// money currently sits, and whether a cash refund is possible right now.
  Future<void> _returnOrder(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(kanbanProvider.notifier);

    final preview = await notifier.loadReturnPreview(widget.invoice.id);
    if (!mounted) return;

    if (preview == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.returnOrderPreviewFailed)),
      );
      return;
    }

    if (preview['can_return'] != true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            preview['return_block_reason']?.toString() ??
                l10n.returnOrderNotAvailable,
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final request = await ReturnOrderDialog.show(context, preview: preview);
    if (request == null || !mounted) return;

    messenger.showSnackBar(
      SnackBar(content: Text(l10n.returnOrderProcessing)),
    );

    final result = await notifier.submitInvoiceReturn(
      invoiceId: widget.invoice.id,
      lines: request.lines,
      reason: request.reason,
      returnType: request.returnType,
      refundMode: request.refundMode,
      payCourierForTrip: request.payCourierForTrip,
      goodsCondition: request.goodsCondition,
      notes: request.notes,
    );
    if (!mounted) return;

    if (result == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.returnOrderFailed)),
      );
      return;
    }

    final creditNote = result['credit_note']?.toString() ?? '';
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          creditNote.isEmpty
              ? l10n.returnOrderSuccess
              : l10n.returnOrderSuccessWithCn(creditNote),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context) async {
    if (widget.invoice.hasPartialPayment) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.invoiceSettleBeforeCancel),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final result = await showDialog<CancelOrderResult>(
      context: context,
      builder: (ctx) => CancelOrderDialog(invoice: widget.invoice),
    );

    if (result == null) {
      return;
    }

    final notifier = ref.read(kanbanProvider.notifier);
    final response = await notifier.cancelInvoice(
      invoiceId: widget.invoice.id,
      reason: result.reason,
      notes: result.notes,
    );

    if (!mounted) {
      return;
    }

    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.invoiceCancelFailed),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final creditNote = (response['credit_note'] ?? response['creditNote'])?.toString();
    final message = (creditNote != null && creditNote.isNotEmpty)
        ? context.l10n.invoiceCancelledWithCn(creditNote)
        : context.l10n.invoiceCancelledSuccess;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Transfer order to another branch / Kanban profile.
  Future<void> _transferOrder(BuildContext context) async {
    if (!widget.invoice.canTransferOrder) return;

    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(kanbanProvider.notifier);

    try {
      // Use the invoice's effective branch so submitted invoices follow custom_kanban_profile.
      final selectedProfile = ref.read(posNotifierProvider).selectedProfile;
      final currentBranch = widget.invoice.posProfile ?? selectedProfile?['name']?.toString();
      if (currentBranch == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.invoiceNoPosProfile),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Fetch available target branches from the dedicated lightweight endpoint.
      final managerApi = ref.read(managerApiProvider);
      final branches = await managerApi.getTransferTargetBranches();

      if (!context.mounted) return;

      // Show dialog to select the target branch.
      String? selected = branches.any((branch) => branch.name == currentBranch)
          ? currentBranch
          : null;
      
      final picked = await showDialog<String>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: Text(context.l10n.invoiceAssignBranch),
              content: SizedBox(
                width: ResponsiveUtils.getDialogWidth(
                  ctx,
                  small: 400,
                  medium: 460,
                  large: 520,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show current invoice info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${context.l10n.commonCustomerLabel}: ${widget.invoice.customerName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.invoiceInvoiceLabel(widget.invoice.name),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Branch selection with ListTiles (same as manager dashboard)
                    for (final b in branches)
                      ListTile(
                        title: Text(b.title),
                        trailing: selected == b.name ? const Icon(Icons.check) : null,
                        onTap: () => setState(() {
                          selected = b.name;
                        }),
                      ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Info message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.invoiceTransferInfo,
                              style: const TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  child: Text(context.l10n.commonSave),
                ),
              ],
            ),
          );
        },
      );

      if (!context.mounted || picked == null || picked == currentBranch) return;

      // Show loading indicator
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(context.l10n.invoiceTransferring),
            ],
          ),
          duration: const Duration(hours: 1),
        ),
      );

      // Call backend to transfer
      final success = await notifier.transferInvoice(
        invoiceId: widget.invoice.name,
        newBranch: picked,
      );

      messenger.clearSnackBars();

      if (!context.mounted) return;

      if (success) {
        final targetBranchTitle = branches
            .firstWhere(
              (branch) => branch.name == picked,
              orElse: () => TransferTargetBranch(
                name: picked,
                title: picked,
              ),
            )
            .title;

        // Refresh the active board and any cached manager order lists in this session.
        ref.invalidate(kanbanProvider);
        ref.invalidate(managerOrdersProvider);
        
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.invoiceTransferSuccess(targetBranchTitle),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Get error from provider state
        final errorMessage = ref.read(kanbanProvider).error ?? context.l10n.invoiceTransferFailed;
        
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(userErrorMessageFor(_errorLocalizations, errorMessage)),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      messenger.clearSnackBars();
      final rawErrorMessage = _formatErrorMessage(
        e,
        fallback: context.l10n.invoiceTransferFailed,
      );
      final errorMessage = switch (rawErrorMessage) {
        'Failed to load transfer branches' => context.l10n.managerTransferBranchesLoadFailed,
        'Failed to transfer branch' => context.l10n.invoiceTransferFailed,
        _ => rawErrorMessage,
      };
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(userErrorMessageFor(_errorLocalizations, errorMessage))),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Change delivery slot for the order
  Future<void> _changeDeliverySlot(BuildContext context) async {
    if (!widget.invoice.canChangeDeliverySlot) return;

    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(kanbanProvider.notifier);

    try {
      // Get the POS profile from the invoice (not from ID parsing)
      final kanbanProfile = widget.invoice.posProfile;
      
      if (kanbanProfile == null || kanbanProfile.isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.invoiceCannotDetermineProfile),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Fetch delivery slots for the kanban profile
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(context.l10n.invoiceLoadingSlots),
            ],
          ),
          duration: const Duration(hours: 1),
        ),
      );

      final posRepository = ref.read(posRepositoryProvider);
      final slots = await posRepository.getDeliverySlots(kanbanProfile);

      messenger.clearSnackBars();

      if (!context.mounted) return;

      if (slots.isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.invoiceNoSlots),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Find current slot based on invoice data
      // The order's own slot, only when it is still on offer. It used to fall
      // back to slots.first, which is now the slot running right now: the dialog
      // then claimed that as the order's slot and refused to save it as "no
      // change" - exactly the slot a late order is most likely moved to.
      DeliverySlot? currentSlot;
      if (widget.invoice.deliveryDate != null && widget.invoice.deliveryTimeFrom != null) {
        final currentDateTime = '${widget.invoice.deliveryDate}T${widget.invoice.deliveryTimeFrom}';
        for (final slot in slots) {
          if (slot.datetime == currentDateTime) {
            currentSlot = slot;
            break;
          }
        }
      }

      // Show dialog to select new delivery slot (same pattern as manager dashboard)
      DeliverySlot? selectedSlot =
          currentSlot ?? DeliverySlot.pickDefault(slots) ?? slots.first;
      
      final picked = await showDialog<DeliverySlot>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: Text(context.l10n.invoiceChangeSlot),
              content: SizedBox(
                width: ResponsiveUtils.getDialogWidth(
                  ctx,
                  small: 400,
                  medium: 460,
                  large: 520,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show current invoice info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.invoiceCustomerName(widget.invoice.customerName),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.invoiceInvoiceLabel(widget.invoice.name),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (currentSlot != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.invoiceCurrentSlot(currentSlot.label),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Slot selection with ListTiles grouped by day
                    Expanded(
                      child: _buildSlotList(slots, selectedSlot, (slot) {
                        setState(() {
                          selectedSlot = slot;
                        });
                      }),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Info message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.invoiceSlotUpdateInfo,
                              style: const TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, selectedSlot),
                  child: Text(context.l10n.commonSave),
                ),
              ],
            ),
          );
        },
      );

      if (!context.mounted || picked == null) return;

      // Check if slot changed
      if (currentSlot != null && picked.datetime == currentSlot.datetime) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.invoiceNoChanges),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // Show loading indicator
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(context.l10n.invoiceUpdatingSlot),
            ],
          ),
          duration: const Duration(hours: 1),
        ),
      );

      // Length of the slot the operator just picked. Reusing the invoice's old
      // duration stretched a 60-minute slot to whatever the previous one was —
      // a move onto the anchored 12:00 AM - 01:00 AM slot came out as 90
      // minutes, ending after the branch had closed.
      int durationSeconds = 7200; // default 2 hours
      final pickedStart = DateTime.tryParse(picked.datetime);
      final pickedEnd = DateTime.tryParse(picked.endDatetime);
      if (pickedStart != null &&
          pickedEnd != null &&
          pickedEnd.isAfter(pickedStart)) {
        durationSeconds = pickedEnd.difference(pickedStart).inSeconds;
      } else if (widget.invoice.deliveryDuration != null) {
        if (widget.invoice.deliveryDuration is int) {
          durationSeconds = widget.invoice.deliveryDuration as int;
        } else if (widget.invoice.deliveryDuration is String) {
          // Parse HH:MM:SS format
          final parts = (widget.invoice.deliveryDuration as String).split(':');
          if (parts.length == 3) {
            durationSeconds = int.parse(parts[0]) * 3600 + 
                             int.parse(parts[1]) * 60 + 
                             int.parse(parts[2]);
          }
        }
      }

      // Call backend to update delivery slot
      final success = await notifier.updateDeliverySlot(
        invoiceId: widget.invoice.name,
        deliveryDate: picked.date,
        deliveryTimeFrom: picked.time,
        deliveryDuration: durationSeconds,
        deliverySlotLabel: picked.label,
      );

      messenger.clearSnackBars();

      if (!context.mounted) return;

      if (success) {
        // Refresh the kanban board
        ref.invalidate(kanbanProvider);
        
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.invoiceSlotUpdated(picked.label),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Get error from provider state
        final errorMessage = ref.read(kanbanProvider).error ?? context.l10n.invoiceSlotUpdateFailed;
        
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(userErrorMessageFor(_errorLocalizations, errorMessage)),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      messenger.clearSnackBars();
      final errorMessage = _formatErrorMessage(
        e,
        fallback: context.l10n.invoiceDeliveryFailed,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      userErrorMessageFor(_errorLocalizations, errorMessage))),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildSlotList(List<DeliverySlot> slots, DeliverySlot? selectedSlot, Function(DeliverySlot) onTap) {
    // Group slots by day
    Map<String, List<DeliverySlot>> slotsByDay = {};
    for (final slot in slots) {
      slotsByDay.putIfAbsent(slot.dayLabel, () => []).add(slot);
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: slotsByDay.keys.length,
      itemBuilder: (context, index) {
        final dayLabel = slotsByDay.keys.elementAt(index);
        final daySlots = slotsByDay[dayLabel]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                dayLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            ...daySlots.map((slot) => ListTile(
              title: Text(
                slot.timeLabel,
                style: TextStyle(
                  fontWeight: selectedSlot?.datetime == slot.datetime ? FontWeight.w600 : FontWeight.normal,
                  color: selectedSlot?.datetime == slot.datetime ? Theme.of(context).primaryColor : null,
                ),
              ),
              trailing: selectedSlot?.datetime == slot.datetime
                  ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                  : slot.isCurrent
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        context.l10n.statusInProgress,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[800],
                        ),
                      ),
                    )
                  : slot.isDefault
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    )
                  : null,
              onTap: () => onTap(slot),
            )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// End of InvoiceCardWidget state class
