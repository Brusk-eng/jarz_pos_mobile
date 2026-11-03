import 'package:jarz_pos/src/core/localization/user_error_message.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/localization/localized_display_mappers.dart';
import '../../../core/localization/localized_formatters.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/utils/order_display_id.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/reason_prompt_dialog.dart';
import '../providers/kanban_provider.dart';

class PaymentReceiptListDialog extends ConsumerStatefulWidget {
  const PaymentReceiptListDialog({super.key});

  @override
  ConsumerState<PaymentReceiptListDialog> createState() => _PaymentReceiptListDialogState();
}

class _PaymentReceiptListDialogState extends ConsumerState<PaymentReceiptListDialog> {
  String? selectedPosProfile;
  // On by default: the popup is opened to clear the receipts still waiting.
  // "Needs action" is Unconfirmed (to confirm) plus Rejected (to re-upload).
  bool needsActionOnly = true;
  static const _needsActionStatuses = ['Unconfirmed', 'Rejected'];
  List<String> posProfiles = [];
  List<Map<String, dynamic>> receipts = [];
  bool loading = true;
  // Bumped per load, so a slower earlier response cannot overwrite a newer one.
  int _loadSeq = 0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final seq = ++_loadSeq;
    setState(() => loading = true);
    final notifier = ref.read(kanbanProvider.notifier);

    // Load accessible POS profiles
    final profiles = await notifier.getAccessiblePOSProfiles();

    // Load receipts. The server's status filter is an exact match, so the
    // needs-action view asks once per status and merges, newest first.
    final List<Map<String, dynamic>> receiptList;
    if (needsActionOnly) {
      final parts = await Future.wait(_needsActionStatuses.map(
        (status) => notifier.listPaymentReceipts(
          posProfile: selectedPosProfile,
          status: status,
        ),
      ));
      receiptList = parts.expand((part) => part).toList()
        ..sort((a, b) => '${b['upload_date'] ?? ''}'
            .compareTo('${a['upload_date'] ?? ''}'));
    } else {
      receiptList = await notifier.listPaymentReceipts(
        posProfile: selectedPosProfile,
      );
    }

    if (!mounted || seq != _loadSeq) return;
    setState(() {
      posProfiles = profiles;
      receipts = receiptList;
      loading = false;
    });
  }

  Future<void> _uploadImage(String receiptName) async {
    try {
      final l10n = context.l10n;

      // Show source selection
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.receiptSelectImageSource),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(context.l10n.receiptCamera),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(context.l10n.receiptGallery),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Pick image
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      // Convert to base64
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Upload
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.receiptUploading)),
      );

      final result = await ref.read(kanbanProvider.notifier).uploadReceiptImage(
        receiptName: receiptName,
        imageData: base64Image,
        filename: image.name,
      );

      if (!mounted) return;

      if (result != null && result['success'] == true) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.receiptUploadedSuccess)),
        );
        await _loadData(); // Refresh list
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.receiptUploadFailed)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      final errorMessage = context.userErrorMessage(
        e,
        fallback: l10n.receiptUploadFailed,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.userErrorMessage(errorMessage))),
      );
    }
  }

  Future<void> _removeImage(String receiptName) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.receiptRemoveConfirmTitle),
        content: Text(l10n.receiptRemoveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.receiptRemoveImageButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(l10n.receiptRemoving)));

    try {
      final result = await ref.read(kanbanProvider.notifier).removeReceiptImage(
            receiptName: receiptName,
          );

      if (!mounted) return;

      if (result != null && result['success'] == true) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.receiptRemovedSuccess)),
        );
        await _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.receiptRemoveFailed)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = context.userErrorMessage(
        e,
        fallback: l10n.receiptRemoveFailed,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(context.userErrorMessage(errorMessage))),
      );
    }
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.error, color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Turn a receipt down, with the reason the server requires.
  ///
  /// Collected before the call rather than after a failure: the reason IS the
  /// deliverable here -- it is what the branch reads to know what to send
  /// instead.
  Future<void> _rejectReceipt(String receiptName) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    final reason = await promptForReason(
      context,
      title: l10n.receiptRejectTitle,
      hint: l10n.receiptRejectHint,
      confirmLabel: l10n.receiptRejectConfirm,
    );
    if (reason == null || !mounted) return;

    try {
      final result = await ref.read(kanbanProvider.notifier).rejectReceipt(
            receiptName: receiptName,
            reason: reason,
          );
      if (!mounted) return;
      if (result != null && result['success'] == true) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.receiptRejected)),
        );
        await _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.userErrorMessage(e, fallback: l10n.commonError),
          ),
        ),
      );
    }
  }

  Future<void> _confirmReceipt(String receiptName) async {
    try {
      final l10n = context.l10n;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.receiptConfirming)),
      );

      final result = await ref.read(kanbanProvider.notifier).confirmReceipt(
        receiptName: receiptName,
      );

      if (!mounted) return;

      if (result != null && result['success'] == true) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.receiptConfirmedSuccess)),
        );
        await _loadData(); // Refresh list
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.receiptConfirmFailed)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      final errorMessage = context.userErrorMessage(
        e,
        fallback: l10n.receiptConfirmFailed,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.userErrorMessage(errorMessage))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = ResponsiveUtils.getDialogWidth(
      context,
      small: 620,
      medium: 840,
      large: 1100,
    );
    final dialogHeight = ResponsiveUtils.getDialogHeight(
      context,
      phoneFraction: 0.82,
      tabletFraction: 0.8,
      max: 860,
    );
    return Dialog(
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.kanbanPaymentReceipts,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // POS Profile Filter
            if (posProfiles.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: selectedPosProfile,
                decoration: InputDecoration(
                  labelText: context.l10n.receiptFilterByPosProfile,
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(context.l10n.receiptAllProfiles),
                  ),
                  ...posProfiles.map((profile) => DropdownMenuItem<String>(
                        value: profile,
                        child: Text(profile),
                      )),
                ],
                onChanged: (value) {
                  setState(() => selectedPosProfile = value);
                  _loadData();
                },
              ),
            const SizedBox(height: 12),

            // Status Filter
            FilterChip(
              label: Text(_needsActionStatuses
                  .map((status) => localizedStatusLabel(context, status))
                  .join(' / ')),
              selected: needsActionOnly,
              onSelected: (value) {
                setState(() => needsActionOnly = value);
                _loadData();
              },
            ),
            const SizedBox(height: 12),

            // Receipt List
            if (loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (receipts.isEmpty)
              Expanded(
                // A failed load also lands here (the provider returns []), so
                // offer a retry rather than a bare "nothing found".
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.l10n.receiptNoReceiptsFound),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: Text(context.l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: receipts.length,
                  itemBuilder: (context, index) {
                    final receipt = receipts[index];
                    return _buildReceiptCard(receipt);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> receipt) {
    final receiptName = receipt['name'] as String;
    final salesInvoiceName = receipt['sales_invoice'] as String?;
    final salesInvoice = salesInvoiceName == null
        ? context.l10n.commonNotSpecified
        : orderDisplayId(salesInvoiceName, wooOrderId: receipt['woo_order_id']);
    final paymentMethod = receipt['payment_method'] as String? ?? context.l10n.commonNotSpecified;
    final amount = receipt['amount'] as num? ?? 0;
    final status = receipt['status'] as String? ?? 'Unconfirmed';
    final posProfile = receipt['pos_profile'] as String? ?? context.l10n.commonNotSpecified;
    final receiptImageUrl = receipt['receipt_image_url'] as String?;
    final customerName = receipt['customer_name'] as String? ?? context.l10n.commonNotSpecified;
    final uploadedBy = receipt['uploaded_by'] as String?;

    final isConfirmed = status == 'Confirmed';
    final isRejected = status == 'Rejected';
    final rejectionReason = receipt['rejection_reason'] as String?;
    // Confirmed is evidence and Changed is audit history, so both freeze the
    // screenshot. A Rejected one does NOT: a rejection asks the branch for a
    // better screenshot, and gating this on Unconfirmed alone made every
    // rejection a dead end — the row kept its reason and offered no button to
    // act on it. Re-uploading flips the receipt back to Unconfirmed server-side
    // so it re-enters the manager's queue.
    final isEditable = status == 'Unconfirmed' || isRejected;
    final hasImage = receiptImageUrl != null && receiptImageUrl.isNotEmpty;
    final canConfirm = receipt['can_confirm'] == true ||
      receipt['can_confirm'] == 1 ||
      receipt['can_confirm'] == '1';

    // Build full image URL: prepend ERP base URL if path is relative
    String? fullImageUrl;
    if (hasImage) {
      if (receiptImageUrl.startsWith('http')) {
        fullImageUrl = receiptImageUrl;
      } else {
        final base = dotenv.get('ERP_BASE_URL', fallback: '');
        fullImageUrl = '$base$receiptImageUrl';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    salesInvoice,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConfirmed
                        ? Colors.green[100]
                        : isRejected
                            ? Colors.red[100]
                            : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    localizedStatusLabel(context, status),
                    style: TextStyle(
                      color: isConfirmed
                          ? Colors.green[900]
                          : isRejected
                              ? Colors.red[900]
                              : Colors.orange[900],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Invoice details
            Text('${context.l10n.commonCustomerLabel}: $customerName', style: const TextStyle(fontSize: 14)),
            Text('${context.l10n.commonAmountLabel}: ${formatCurrency(context, amount.toDouble())}', style: const TextStyle(fontSize: 14)),
            Text('${context.l10n.commonPaymentLabel}: ${localizedPaymentMethodLabel(context, paymentMethod)}', style: const TextStyle(fontSize: 14)),
            Text('${context.l10n.commonPosProfileLabel}: $posProfile', style: const TextStyle(fontSize: 14)),
            if (uploadedBy != null)
              Text('${context.l10n.commonUploadedByLabel}: $uploadedBy', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (isRejected && (rejectionReason ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${context.l10n.receiptRejectionReason}: $rejectionReason',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 8),

            // Receipt image thumbnail or upload button
            if (hasImage)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _showFullImage(context, fullImageUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        fullImageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (!isConfirmed && canConfirm)
                          ElevatedButton.icon(
                            onPressed: () => _confirmReceipt(receiptName),
                            icon: const Icon(Icons.check, size: 16),
                            label: Text(context.l10n.commonConfirm),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (!isConfirmed && !isRejected && canConfirm)
                          OutlinedButton.icon(
                            onPressed: () => _rejectReceipt(receiptName),
                            icon: const Icon(Icons.block, size: 16),
                            label: Text(context.l10n.receiptReject),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                          ),
                        if (isEditable) ...[
                          OutlinedButton.icon(
                            onPressed: () => _uploadImage(receiptName),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(
                              context.l10n.receiptReplaceImageButton,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _removeImage(receiptName),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: Text(
                              context.l10n.receiptRemoveImageButton,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              )
            else if (isEditable)
              ElevatedButton.icon(
                onPressed: () => _uploadImage(receiptName),
                icon: const Icon(Icons.upload, size: 16),
                label: Text(context.l10n.receiptUploadImageButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
