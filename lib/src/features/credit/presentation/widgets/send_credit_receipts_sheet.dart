import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../../kanban/providers/kanban_provider.dart';
import '../../../printing/pos_printer_provider.dart';
import '../../../printing/pos_printer_service.dart'
    if (dart.library.html) '../../../printing/pos_printer_service_web.dart';
import '../../../printing/printable_invoice_mapper.dart';
import '../../../printing/receipt/receipt_delivery.dart';
import '../../../printing/receipt/receipt_share.dart';
import '../../../printing/receipt/receipt_statement.dart';
import '../../data/credit_repository.dart';
import '../../data/models/credit_models.dart';

/// How the chosen orders go to the customer.
enum CreditSendMode {
  /// One receipt per order — the paper receipt, as sent from the order card.
  individual,

  /// One statement: every chosen order, what is due on each, and the total.
  consolidated,
}

enum _Channel { whatsapp, share }

/// Loads the receipt data of [invoices], in the order given.
typedef CreditReceiptLoader = Future<List<PrintableInvoice>> Function(
  List<CreditInvoice> invoices,
);

/// The shop branch (delivery door) each invoice went to, by invoice name;
/// '' or missing when it is not known.
typedef CreditBranchLoader = Future<Map<String, String>> Function(
  String customer,
  List<CreditInvoice> invoices,
);

/// Sends a credit customer's unpaid orders: each as its own receipt image, or
/// all of them as one consolidated statement image, over WhatsApp (where the
/// cashier picks the chat or group) or the share sheet.
///
/// Every open invoice starts ticked because "send them what they owe" is the
/// common case; unticking is how one old dispute or a just-delivered order
/// is left out.
class SendCreditReceiptsSheet extends ConsumerStatefulWidget {
  /// The Customer record; used to look up which branch each order went to.
  final String customer;
  final String customerName;
  final List<CreditInvoice> invoices;
  final String currency;

  /// Test seam; production loads each invoice's details from the server.
  final CreditReceiptLoader? loadInvoices;

  /// Test seam; production asks the server for each order's shop branch.
  final CreditBranchLoader? loadBranches;

  const SendCreditReceiptsSheet({
    super.key,
    this.customer = '',
    required this.customerName,
    required this.invoices,
    this.currency = '',
    this.loadInvoices,
    this.loadBranches,
  });

  static Future<void> show(
    BuildContext context, {
    String customer = '',
    required String customerName,
    required List<CreditInvoice> invoices,
    String currency = '',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SendCreditReceiptsSheet(
        customer: customer,
        customerName: customerName,
        invoices: invoices,
        currency: currency,
      ),
    );
  }

  @override
  ConsumerState<SendCreditReceiptsSheet> createState() => _SendCreditReceiptsSheetState();
}

class _SendCreditReceiptsSheetState extends ConsumerState<SendCreditReceiptsSheet> {
  late final Set<String> _selected = {for (final i in widget.invoices) i.invoice};
  late CreditSendMode _mode =
      widget.invoices.length > 1 ? CreditSendMode.consolidated : CreditSendMode.individual;
  _Channel? _busy;
  String? _error;

  List<CreditInvoice> get _chosen =>
      widget.invoices.where((i) => _selected.contains(i.invoice)).toList();

  double get _chosenDue => _chosen.fold(0.0, (sum, i) => sum + i.outstandingAmount);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final allSelected = _selected.length == widget.invoices.length;
    final canSend = _selected.isNotEmpty && _busy == null;

    // The sheet is drawn edge to edge, so without this the WhatsApp / Share
    // row sits under the phone's navigation bar and cannot be seen or tapped.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.creditSendToCustomer, style: theme.textTheme.titleLarge),
            if (widget.customerName.isNotEmpty)
              Text(widget.customerName, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
            const SizedBox(height: 12),
            SegmentedButton<CreditSendMode>(
              segments: [
                ButtonSegment(
                  value: CreditSendMode.individual,
                  label: Text(l10n.creditSendModeIndividual),
                ),
                ButtonSegment(
                  value: CreditSendMode.consolidated,
                  label: Text(l10n.creditSendModeConsolidated),
                ),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: _busy != null ? null : (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 6),
            Text(
              _mode == CreditSendMode.individual
                  ? l10n.creditSendModeIndividualHint
                  : l10n.creditSendModeConsolidatedHint,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: allSelected,
              title: Text(l10n.creditSendSelectAll),
              subtitle: Text(l10n.creditSendSelectedCount(_selected.length, widget.invoices.length)),
              onChanged: _busy != null
                  ? null
                  : (v) => setState(() {
                        _selected
                          ..clear()
                          ..addAll(v == true ? widget.invoices.map((i) => i.invoice) : const <String>[]);
                      }),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final invoice in widget.invoices)
                    CheckboxListTile(
                      key: ValueKey('credit-send-${invoice.invoice}'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _selected.contains(invoice.invoice),
                      title: Text(invoice.displayId),
                      subtitle: Text(formatDateString(context, invoice.postingDate)),
                      secondary: Text(
                        formatCurrency(context, invoice.outstandingAmount, currencyCode: _currencyOf(invoice)),
                        style: theme.textTheme.titleSmall,
                      ),
                      onChanged: _busy != null
                          ? null
                          : (v) => setState(() {
                                v == true ? _selected.add(invoice.invoice) : _selected.remove(invoice.invoice);
                              }),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              l10n.creditSendTotalDue(formatCurrency(context, _chosenDue, currencyCode: widget.currency)),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: _busy == _Channel.whatsapp ? const _Spinner() : const Icon(Icons.chat_outlined),
                    label: Text(l10n.creditSendWhatsApp),
                    onPressed: canSend ? () => _send(_Channel.whatsapp) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: _busy == _Channel.share ? const _Spinner() : const Icon(Icons.share),
                    label: Text(l10n.creditSendShare),
                    onPressed: canSend ? () => _send(_Channel.share) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _currencyOf(CreditInvoice invoice) =>
      invoice.currency.isNotEmpty ? invoice.currency : widget.currency;

  Future<void> _send(_Channel channel) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final printer = ref.read(posPrinterServiceProvider);
    final chosen = _chosen;
    final mode = _mode;
    setState(() {
      _busy = channel;
      _error = null;
    });

    final List<PrintableInvoice> printables;
    try {
      printables = await (widget.loadInvoices ?? _loadFromServer)(chosen);
      if (printables.length != chosen.length) {
        throw StateError('Loaded ${printables.length} of ${chosen.length} orders');
      }
    } catch (e) {
      debugPrint('[SendCreditReceipts] load failed: $e');
      if (mounted) {
        setState(() {
          _busy = null;
          _error = l10n.creditSendLoadFailed;
        });
      }
      return;
    }
    // Closing the sheet while the orders load is how a cashier changes their
    // mind; nothing goes out after that.
    if (!mounted) return;

    final branding = await printer.receiptBranding();
    final customer = widget.customerName.isNotEmpty ? widget.customerName : printables.first.customer;

    final String text;
    final String caption;
    final files = <ReceiptImage>[];
    if (mode == CreditSendMode.individual) {
      text = printables.length == 1
          ? buildReceiptShareText(printables.first, branding)
          : buildReceiptsBundleText(printables, branding);
      caption = printables.length == 1
          ? receiptShareCaption(printables.first, branding)
          : '${branding.header} — $customer (${printables.length})';
      try {
        for (final inv in printables) {
          files.add(receiptImageFile(await printer.renderReceiptPng(inv), 'receipt-${receiptOrderLabel(inv)}'));
        }
      } catch (e) {
        debugPrint('[SendCreditReceipts] receipt render failed, sending text: $e');
        files.clear();
      }
    } else {
      // A shop with several branches gets its statement grouped by branch.
      // Without the branches (older server, network) it is still sent, flat.
      final branches = await _branchesOf(chosen);
      if (!mounted) return;
      final statement = PrintableStatement(
        customer: customer,
        date: DateTime.now(),
        entries: [
          for (var i = 0; i < printables.length; i++)
            StatementEntry(
              invoice: printables[i],
              outstanding: chosen[i].outstandingAmount,
              branch: branches[chosen[i].invoice] ?? '',
            ),
        ],
      );
      text = buildStatementShareText(statement, branding);
      caption = '$statementTitle — $customer';
      try {
        files.add(receiptImageFile(await printer.renderStatementPng(statement), 'statement-${statement.dateLabel.replaceAll('/', '-')}'));
      } catch (e) {
        debugPrint('[SendCreditReceipts] statement render failed, sending text: $e');
      }
    }

    // Rendering is awaited too, so the same check again right before sending.
    if (!mounted) return;
    navigator.pop();
    // No number on WhatsApp: a shop is usually reached through a group, so
    // WhatsApp opens its own chat list and the cashier picks the chat.
    await deliverReceipt(
      messenger: messenger,
      files: files,
      caption: caption,
      text: text,
      toWhatsApp: channel == _Channel.whatsapp,
      failureMessage: channel == _Channel.whatsapp ? l10n.invoiceWhatsAppOpenFailed : l10n.invoiceReceiptShareFailed,
      retryLabel: l10n.commonRetry,
      imageReadyMessage: l10n.invoiceReceiptImageReady,
      sendLabel: l10n.invoiceReceiptSendAction,
    );
  }

  Future<Map<String, String>> _branchesOf(List<CreditInvoice> invoices) async {
    try {
      final loader = widget.loadBranches;
      if (loader != null) return await loader(widget.customer, invoices);
      if (widget.customer.isEmpty) return const {};
      return await ref.read(creditRepositoryProvider).getInvoiceShopBranches(
            customer: widget.customer,
            invoices: invoices.map((i) => i.invoice).toList(),
          );
    } catch (e) {
      debugPrint('[SendCreditReceipts] branch lookup failed, statement stays flat: $e');
      return const {};
    }
  }

  /// Each order's full details — lines, shipping, delivery slot — the same
  /// payload the order card prints from. Four at a time: a shop with a dozen
  /// open orders should not wait on a dozen round trips in a row.
  Future<List<PrintableInvoice>> _loadFromServer(List<CreditInvoice> invoices) async {
    final service = ref.read(kanbanServiceProvider);
    final l10n = context.l10n;
    final out = <PrintableInvoice>[];
    for (var start = 0; start < invoices.length; start += 4) {
      final batch = invoices.skip(start).take(4);
      final details = await Future.wait(batch.map((i) => service.getInvoiceDetails(i.invoice)));
      for (final card in details) {
        out.add(
          buildPrintableInvoiceFromCards(
            source: card,
            details: card,
            fallbackItemLabel: l10n.invoiceItemsCount(card.itemsCount),
          ),
        );
      }
    }
    return out;
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
}
