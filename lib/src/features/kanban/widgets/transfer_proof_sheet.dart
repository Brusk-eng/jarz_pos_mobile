import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/localized_display_mappers.dart';
import '../../../core/localization/localized_formatters.dart';
import '../../../core/localization/user_error_message.dart';
import '../models/kanban_models.dart';
import '../providers/kanban_provider.dart';
import 'transfer_proof_logic.dart';

/// How the transfer-proof step ended. `null` from [TransferProofSheet.show]
/// means the user closed it without changing anything.
enum TransferProofOutcome {
  /// The receipt is Confirmed with a screenshot; the caller pays the invoice.
  confirmed,

  /// Confirmation itself recorded the payment (an "Awaiting Payment" order);
  /// the caller must not pay again.
  confirmedAndRecorded,

  /// The screenshot is attached and a manager has to confirm it.
  awaitingManager,

  /// A confirm-tier user chose not to confirm yet; the receipt stays
  /// Unconfirmed.
  awaitingConfirmation,

  /// Nothing was attached or confirmed, but the sheet found the server's
  /// receipt differs from the card's snapshot (rejected, replaced, Changed,
  /// gone, or a receipt created here whose upload failed). The caller reloads
  /// the board quietly: on the stale card, Pay reopened the sheet into the
  /// same "receipt changed" stop forever.
  receiptStateChanged,
}

/// Collects the customer's transfer screenshot before an InstaPay / Wallet
/// payment, and — for a user in the confirm tier — the explicit "the transfer
/// arrived" confirmation.
///
/// It lives on the root navigator, not inside the card, so a board refresh
/// that rebuilds the card mid-upload cannot tear it down. It never pays the
/// invoice itself: it reports a [TransferProofOutcome] and the card decides.
class TransferProofSheet extends ConsumerStatefulWidget {
  const TransferProofSheet({
    super.key,
    required this.invoice,
    required this.method,
    required this.posProfile,
    required this.canConfirm,
  });

  final InvoiceCard invoice;

  /// Receipt API spelling: `InstaPay` or `Wallet`.
  final String method;
  final String? posProfile;

  /// Client-side mirror of the confirm tier. The server stays the authority.
  final bool canConfirm;

  static Future<TransferProofOutcome?> show(
    BuildContext context, {
    required InvoiceCard invoice,
    required String method,
    required String? posProfile,
    required bool canConfirm,
  }) {
    return showModalBottomSheet<TransferProofOutcome>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Closing must go through [_close] so an upload made here is reported.
      // These two only cover the barrier and the drag; the Android back button
      // is routed through [_close] by the PopScope in build().
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => TransferProofSheet(
        invoice: invoice,
        method: method,
        posProfile: posProfile,
        canConfirm: canConfirm,
      ),
    );
  }

  @override
  ConsumerState<TransferProofSheet> createState() => _TransferProofSheetState();
}

class _TransferProofSheetState extends ConsumerState<TransferProofSheet> {
  final ImagePicker _picker = ImagePicker();

  late TransferReceiptState _receiptState;
  String? _receiptName;
  String? _receiptImageUrl;
  String? _rejectionReason;

  XFile? _pickedImage;
  Uint8List? _pickedBytes;

  bool _busy = false;
  String? _busyLabel;
  String? _error;

  /// A screenshot was attached during THIS visit, so closing the sheet still
  /// has something to report.
  bool _uploadedHere = false;

  /// The receipt state the card showed when the sheet opened.
  late final TransferReceiptState _snapshotState;

  /// The sheet learned the server's receipt is not what the card showed, so a
  /// plain close must still make the card reload (see
  /// [TransferProofOutcome.receiptStateChanged]).
  bool _serverStateChanged = false;

  double get _amount => transferReceiptAmount(widget.invoice);

  @override
  void initState() {
    super.initState();
    _receiptState = transferReceiptStateFor(widget.invoice, widget.method);
    _snapshotState = _receiptState;
    if (_receiptState != TransferReceiptState.none) {
      _receiptName = widget.invoice.paymentReceiptName?.trim();
      _receiptImageUrl = widget.invoice.paymentReceiptImageUrl?.trim();
    }
    if (_receiptState == TransferReceiptState.rejected) {
      _loadRejectionReason();
    }
  }

  /// The card model carries the status but not the reason; the receipt row
  /// does. Best effort: without it the sheet still says "rejected".
  Future<void> _loadRejectionReason() async {
    final name = _receiptName;
    if (name == null || name.isEmpty) return;
    try {
      final row = await _readCurrentReceipt(name, fallbackStatus: 'Rejected');
      // A row that is no longer Rejected (a manager confirmed or replaced it
      // since the board loaded): a close must reload the card.
      if (row != null &&
          transferReceiptStateFromRow(row, widget.method) != _snapshotState) {
        _serverStateChanged = true;
      }
      final reason = (row?['rejection_reason'] ?? '').toString();
      if (!mounted || reason.trim().isEmpty) return;
      setState(() => _rejectionReason = reason.trim());
    } catch (_) {
      // Reason is decoration; the rejected banner is already showing.
    }
  }

  /// The server's current row for receipt [name], or null when there is no
  /// current receipt (gone, another branch, or the read failed).
  ///
  /// Reads just that receipt with `get_payment_receipt`. A server that predates
  /// it ([ReceiptLookupFailure.methodMissing]) is served by the old path: the
  /// branch's whole receipt list, optionally narrowed by [fallbackStatus]. A
  /// not-found or permission answer is a real answer and never falls back.
  Future<Map<String, dynamic>?> _readCurrentReceipt(
    String name, {
    String? fallbackStatus,
  }) async {
    final notifier = ref.read(kanbanProvider.notifier);
    try {
      return await notifier.getPaymentReceipt(receiptName: name);
    } catch (error) {
      if (classifyReceiptLookupError(error) !=
          ReceiptLookupFailure.methodMissing) {
        return null;
      }
    }
    if (!mounted) return null;
    final profile = widget.posProfile?.trim();
    final rows = await notifier.listPaymentReceipts(
      posProfile: (profile == null || profile.isEmpty) ? null : profile,
      status: fallbackStatus,
    );
    return findReceiptRow(rows, name);
  }

  bool get _hasPickedImage => (_pickedBytes?.isNotEmpty ?? false);

  bool get _canUseExistingProof => canContinueWithExistingProof(_receiptState);

  bool get _needsPosProfile =>
      (_receiptName ?? '').isEmpty &&
      (widget.posProfile?.trim().isEmpty ?? true);

  Future<void> _pickImage() async {
    if (_busy) return;
    final l10n = context.l10n;
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.receiptSelectImageSource),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.receiptCamera),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.receiptGallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final image = await _picker.pickImage(source: source);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      // A zero-byte pick (revoked permission, unreadable cloud/HEIC asset)
      // would be refused by the upload chokepoint anyway; say so now.
      if (bytes.isEmpty) {
        setState(() => _error = l10n.receiptImageEmpty);
        return;
      }
      setState(() {
        _pickedImage = image;
        _pickedBytes = bytes;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userErrorMessageFor(l10n, error));
    }
  }

  /// Ensures the receipt row exists, then attaches the picked screenshot.
  Future<bool> _sendPickedImage() async {
    final l10n = context.l10n;
    final notifier = ref.read(kanbanProvider.notifier);
    final image = _pickedImage;
    final bytes = _pickedBytes;
    if (image == null || bytes == null || bytes.isEmpty) return false;

    setState(() {
      _busy = true;
      _busyLabel = l10n.transferProofSending;
      _error = null;
    });
    var createdHere = false;
    try {
      var receiptName = (_receiptName ?? '').trim();
      if (receiptName.isEmpty) {
        final posProfile = widget.posProfile?.trim() ?? '';
        if (posProfile.isEmpty) {
          throw Exception(l10n.invoiceSelectPosFirst);
        }
        final created = await notifier.createPaymentReceipt(
          salesInvoice: widget.invoice.name,
          paymentMethod: widget.method,
          amount: _amount,
          posProfile: posProfile,
        );
        receiptName = (created?['receipt_name'] ?? '').toString().trim();
        if (created == null ||
            created['success'] != true ||
            receiptName.isEmpty) {
          throw Exception(
            (created?['message']?.toString().trim().isNotEmpty ?? false)
                ? created!['message'].toString()
                : l10n.commonError,
          );
        }
        createdHere = true;
        if (!mounted) return false;
        setState(() => _receiptName = receiptName);
      }

      final uploaded = await notifier.uploadReceiptImage(
        receiptName: receiptName,
        imageData: base64Encode(bytes),
        filename: image.name,
      );
      if (!mounted) return false;
      setState(() {
        _receiptImageUrl = (uploaded?['file_url'] ?? '').toString().trim();
        final status = (uploaded?['status'] ?? 'Unconfirmed')
            .toString()
            .trim()
            .toLowerCase();
        _receiptState = status == 'confirmed'
            ? TransferReceiptState.confirmed
            : TransferReceiptState.uploadedUnconfirmed;
        _rejectionReason = null;
        _pickedImage = null;
        _pickedBytes = null;
        _uploadedHere = true;
        _busy = false;
        _busyLabel = null;
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      var message = userErrorMessageFor(
        l10n,
        error,
        fallback: l10n.receiptUploadFailed,
      );
      final existingName = (_receiptName ?? '').trim();
      if (createdHere) {
        // The board does not know the receipt made a moment ago.
        _serverStateChanged = true;
      } else if (existingName.isNotEmpty) {
        // The server refuses a screenshot on a receipt that is already
        // Confirmed or was Changed since the board loaded. Look, so a close
        // reloads the card instead of reopening this sheet on the old snapshot.
        // Only a row the server actually returned counts: a failed read (the
        // upload may have failed for want of a network too) must not turn the
        // real error into "receipt changed".
        setState(() => _busyLabel = l10n.transferProofChecking);
        final row = await _readCurrentReceipt(existingName);
        if (!mounted) return false;
        final fresh = transferReceiptStateFromRow(row, widget.method);
        if (row != null && fresh != _snapshotState) {
          _serverStateChanged = true;
          _receiptState = fresh;
          message = l10n.transferProofReceiptChanged;
        }
      }
      setState(() {
        _busy = false;
        _busyLabel = null;
        _error = message;
      });
      return false;
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_hasPickedImage) {
      final ok = await _sendPickedImage();
      if (!ok || !mounted) return;
    } else if (!_canUseExistingProof) {
      return;
    }
    await _afterProofAttached();
  }

  /// Re-reads the receipt before a confirm made off proof that was NOT attached
  /// in this visit. Returns false when the sheet must stop and show why.
  ///
  /// The sheet opens from the card's board snapshot. If a manager rejected or
  /// replaced the screenshot since, confirming would still go through — the
  /// server allows confirming a Rejected receipt — and for an Awaiting Payment
  /// order that posts the money.
  Future<bool> _refreshReceiptState() async {
    final l10n = context.l10n;
    final name = (_receiptName ?? '').trim();
    if (name.isEmpty) return false;
    setState(() {
      _busy = true;
      _busyLabel = l10n.transferProofChecking;
      _error = null;
    });
    final row = await _readCurrentReceipt(name);
    if (!mounted) return false;
    final fresh = transferReceiptStateFromRow(row, widget.method);
    if (fresh != _snapshotState) _serverStateChanged = true;
    setState(() {
      _busy = false;
      _busyLabel = null;
      _receiptState = fresh;
      final url = (row?['receipt_image_url'] ?? '').toString().trim();
      if (url.isNotEmpty) _receiptImageUrl = url;
      final reason = (row?['rejection_reason'] ?? '').toString().trim();
      _rejectionReason = reason.isEmpty ? null : reason;
      // A rejection shows its own banner; anything else that stops the flow
      // (receipt changed, image gone, read failed) says so here.
      if (fresh != TransferReceiptState.rejected &&
          fresh != TransferReceiptState.uploadedUnconfirmed &&
          fresh != TransferReceiptState.confirmed) {
        _error = l10n.transferProofReceiptChanged;
      }
    });
    return fresh == TransferReceiptState.uploadedUnconfirmed ||
        fresh == TransferReceiptState.confirmed;
  }

  Future<void> _afterProofAttached() async {
    final navigator = Navigator.of(context);
    if (!_uploadedHere) {
      final current = await _refreshReceiptState();
      if (!current || !mounted) return;
    }
    if (_receiptState == TransferReceiptState.confirmed) {
      navigator.pop(TransferProofOutcome.confirmed);
      return;
    }
    switch (transferProofNextStep(canConfirm: widget.canConfirm)) {
      case TransferProofNextStep.awaitManager:
        navigator.pop(TransferProofOutcome.awaitingManager);
        return;
      case TransferProofNextStep.askToConfirmThenPay:
        break;
    }

    final l10n = context.l10n;
    final amountText = formatCurrency(context, _amount);
    // Busy while the question is up, so a second Continue cannot start a
    // second flow. The Navigator absorbs a pointer double tap for one frame
    // after the push, but a keyboard or accessibility activation still reached
    // [_submit]: it opened a second dialog and confirmed twice, and the first
    // flow's `navigator.pop(outcome)` then closed that second `bool` dialog
    // instead of the sheet. No label, so no progress bar behind the dialog.
    setState(() {
      _busy = true;
      _busyLabel = null;
      _error = null;
    });
    bool? arrived;
    try {
      arrived = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.transferProofConfirmTitle),
          content: Text(l10n.transferProofConfirmBody(amountText)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.transferProofConfirmNo),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: Text(l10n.transferProofConfirmYes),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (arrived != true) {
      navigator.pop(TransferProofOutcome.awaitingConfirmation);
      return;
    }

    final receiptName = (_receiptName ?? '').trim();
    setState(() {
      _busy = true;
      _busyLabel = l10n.transferProofConfirming;
      _error = null;
    });
    try {
      final result = await ref
          .read(kanbanProvider.notifier)
          .confirmReceipt(receiptName: receiptName);
      if (!mounted) return;
      if (result == null || result['success'] != true) {
        throw Exception(l10n.receiptConfirmFailed);
      }
      navigator.pop(
        confirmRecordsPayment(result)
            ? TransferProofOutcome.confirmedAndRecorded
            : TransferProofOutcome.confirmed,
      );
    } catch (error) {
      if (!mounted) return;
      if (isPermissionRefusal(error)) {
        navigator.pop(TransferProofOutcome.awaitingManager);
        return;
      }
      setState(() {
        _busy = false;
        _busyLabel = null;
        _error = userErrorMessageFor(
          l10n,
          error,
          fallback: l10n.receiptConfirmFailed,
        );
      });
    }
  }

  void _close() {
    if (_busy) return;
    if (!_uploadedHere) {
      // Nothing attached here. If the sheet nonetheless found the receipt
      // changed on the server, say so, so the card reloads; otherwise `null`.
      Navigator.of(context).pop(
        _serverStateChanged ? TransferProofOutcome.receiptStateChanged : null,
      );
      return;
    }
    Navigator.of(context).pop(
      widget.canConfirm
          ? TransferProofOutcome.awaitingConfirmation
          : TransferProofOutcome.awaitingManager,
    );
  }

  String? _resolveReceiptUrl(String? rawUrl) {
    final value = (rawUrl ?? '').trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final baseUrl = dotenv.get('ERP_BASE_URL', fallback: '').trim();
    if (baseUrl.isEmpty) return null;
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = value.startsWith('/') ? value : '/$value';
    return '$normalizedBase$normalizedPath';
  }

  Future<void> _previewExisting() async {
    final resolved = _resolveReceiptUrl(_receiptImageUrl);
    if (resolved == null) return;
    final uri = Uri.tryParse(resolved);
    if (uri == null) return;
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final methodLabel = localizedPaymentMethodLabel(context, widget.method);
    final hasExistingImage = (_receiptImageUrl ?? '').trim().isNotEmpty;

    String? primaryLabel;
    if (_hasPickedImage) {
      primaryLabel = l10n.transferProofSend;
    } else if (_canUseExistingProof) {
      primaryLabel = l10n.transferProofContinue;
    }
    final canSubmit =
        primaryLabel != null &&
        !_busy &&
        !(_hasPickedImage && _needsPosProfile);

    // Back goes through [_close] like the Close button: ignored while a request
    // is in flight, and otherwise reporting an upload made here. Without this
    // the Android back button closed the sheet mid-upload with `null`, and the
    // card returned silently with no message and no board refresh.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.transferProofTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.commonClose,
                      onPressed: _busy ? null : _close,
                    ),
                  ],
                ),
                Text(
                  l10n.transferProofIntro,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  label: l10n.transferProofMethodLabel,
                  value: methodLabel,
                ),
                const SizedBox(height: 6),
                _InfoLine(
                  label: l10n.transferProofAmountLabel,
                  value: formatCurrency(context, _amount),
                  emphasize: true,
                ),
                const SizedBox(height: 12),
                if (_receiptState == TransferReceiptState.rejected)
                  _Banner(
                    color: Colors.red,
                    icon: Icons.block,
                    text: (_rejectionReason ?? '').isEmpty
                        ? l10n.transferProofRejected
                        : l10n.transferProofRejectedReason(_rejectionReason!),
                  )
                else if (_canUseExistingProof && !_hasPickedImage)
                  _Banner(
                    color: Colors.green,
                    icon: Icons.verified_outlined,
                    text: l10n.transferProofAlreadyUploaded,
                  ),
                if (_needsPosProfile) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.invoiceSelectPosFirst,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (_hasPickedImage) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.transferProofImageSelected,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _pickedBytes!,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pickImage,
                      icon: Icon(
                        _hasPickedImage || hasExistingImage
                            ? Icons.refresh
                            : Icons.add_a_photo_outlined,
                      ),
                      label: Text(
                        _hasPickedImage || _canUseExistingProof
                            ? l10n.receiptReplaceImageButton
                            : l10n.transferProofAttach,
                      ),
                    ),
                    if (hasExistingImage && !_hasPickedImage)
                      TextButton.icon(
                        onPressed: _busy ? null : _previewExisting,
                        icon: const Icon(Icons.open_in_new),
                        label: Text(l10n.commonPreview),
                      ),
                  ],
                ),
                // Only a request shows progress; the busy hold while the confirm
                // question is open has no label and draws nothing here.
                if (_busy && _busyLabel != null) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 6),
                  Text(_busyLabel!, style: theme.textTheme.bodySmall),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _busy ? null : _close,
                      child: Text(l10n.commonCancel),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: canSubmit ? _submit : null,
                        icon: const Icon(Icons.check, size: 16),
                        label: Text(primaryLabel ?? l10n.transferProofSend),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: emphasize ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.icon, required this.text});

  final MaterialColor color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color[800], fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
