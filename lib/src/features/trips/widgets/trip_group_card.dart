import 'package:jarz_pos/src/core/localization/user_error_message.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/localized_formatters.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../kanban/models/kanban_models.dart';
import '../../kanban/widgets/invoice_card_widget.dart';
import '../../../core/utils/territory_label.dart';

/// Collapsible card that groups trip invoices in a kanban column.
class TripGroupCard extends StatefulWidget {
  final String tripName;
  final String courierDisplayName;
  final bool isDoubleShipping;
  final List<InvoiceCard> invoices;
  final Future<void> Function(String tripName)? onMarkDelivered;
  final Future<void> Function(String tripName)? onSendForDelivery;

  const TripGroupCard({
    super.key,
    required this.tripName,
    required this.courierDisplayName,
    this.isDoubleShipping = false,
    required this.invoices,
    this.onMarkDelivered,
    this.onSendForDelivery,
  });

  @override
  State<TripGroupCard> createState() => _TripGroupCardState();
}

class _TripGroupCardState extends State<TripGroupCard> {
  bool _expanded = false;
  bool _actionInProgress = false;

  double get _totalAmount =>
      widget.invoices.fold(0.0, (sum, inv) => sum + inv.grandTotal);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.indigo.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          // Collapsed header
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.local_shipping, size: 18, color: Colors.indigo[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tripName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[800],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.courierDisplayName} · ${l10n.tripsOrdersCount(widget.invoices.length)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isDoubleShipping) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber[700]!),
                      ),
                      child: Text(
                        '2×',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber[800]),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    formatCurrency(context, _totalAmount),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          // Expanded invoice list
          if (_expanded) ...[
            const Divider(height: 1),
            ...widget.invoices.map((inv) => _buildInvoiceRow(inv)),
            if (widget.onSendForDelivery != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _actionInProgress ? null : _handleSendForDelivery,
                    icon: _actionInProgress
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 18),
                    label: Text(_actionInProgress ? context.l10n.tripsSending : context.l10n.tripsSendForDeliveryTitle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            ],
            if (widget.onMarkDelivered != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _actionInProgress ? null : _handleMarkDelivered,
                    icon: _actionInProgress
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle, size: 18),
                    label: Text(_actionInProgress ? context.l10n.tripsMarking : context.l10n.tripsMarkAsDeliveredButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(InvoiceCard inv) {
    return InkWell(
      onTap: () => _showInvoiceDetails(inv),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inv.customerName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    territoryLabel(
                      nameAr: inv.territoryNameAr,
                      display: inv.subTerritoryDisplay ?? inv.territoryDisplay,
                      raw: inv.subTerritory ?? inv.territory,
                    ),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              formatCurrency(context, inv.grandTotal),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.green),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showInvoiceDetails(InvoiceCard inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: ResponsiveUtils.getCartBottomSheetInitialSize(context),
        minChildSize: ResponsiveUtils.getCartBottomSheetMinSize(context),
        maxChildSize: ResponsiveUtils.getCartBottomSheetMaxSize(context),
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    8,
                    0,
                    8,
                    MediaQuery.paddingOf(ctx).bottom,
                  ),
                  child: InvoiceCardWidget(invoice: inv),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSendForDelivery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tripsSendForDeliveryTitle),
        content: Text(context.l10n.tripsSendForDeliveryContent(widget.invoices.length, widget.courierDisplayName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.commonConfirm)),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _actionInProgress = true);
    try {
      await widget.onSendForDelivery!(widget.tripName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.userErrorMessage(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _handleMarkDelivered() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tripsMarkTripAsDeliveredTitle),
        content: Text(context.l10n.tripsMarkTripAsDeliveredContent(widget.tripName, widget.invoices.length)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.commonCancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(context.l10n.commonConfirm, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _actionInProgress = true);
    try {
      await widget.onMarkDelivered!(widget.tripName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.tripsTripMarkedAsDelivered(widget.tripName)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.userErrorMessage(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }
}
