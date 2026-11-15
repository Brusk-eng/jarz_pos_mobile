import 'package:flutter/material.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../data/models/chat_models.dart';
import '../chat_bidi.dart';
import '../chat_labels.dart';

/// The planted-draft (training check) outcome of a `send_draft`, or null
/// when the draft was a normal one.
enum ChatPlantedOutcome {
  /// Sent as-is: blocked, nothing reached the customer.
  notSent,

  /// Edited and the edit removed the mistake.
  caught,

  /// Edited but the mistake went out: the moderator must correct it.
  missed,
}

ChatPlantedOutcome? chatPlantedOutcome(ChatSendDraftResult result) {
  if (!result.planted) return null;
  if (!result.wasSent) return ChatPlantedOutcome.notSent;
  return result.caught ? ChatPlantedOutcome.caught : ChatPlantedOutcome.missed;
}

/// The dialog text for a training-check outcome. [plantedError] is what was
/// changed ("price 120→150"); the wording drops it when the server did not
/// send it.
String chatPlantedMessage(
  AppLocalizations l10n,
  ChatPlantedOutcome outcome,
  String? plantedError,
) {
  final error = plantedError?.trim() ?? '';
  return switch (outcome) {
    ChatPlantedOutcome.notSent => error.isEmpty
        ? l10n.chatPlantedNotSentNoDetail
        : l10n.chatPlantedNotSent(error),
    ChatPlantedOutcome.caught => error.isEmpty
        ? l10n.chatPlantedCaughtNoDetail
        : l10n.chatPlantedCaught(error),
    ChatPlantedOutcome.missed => error.isEmpty
        ? l10n.chatPlantedMissedNoDetail
        : l10n.chatPlantedMissed(error),
  };
}

Future<void> showChatPlantedDialog(
  BuildContext context, {
  required ChatPlantedOutcome outcome,
  String? plantedError,
  bool realDraftReady = false,
}) {
  final l10n = context.l10n;
  final theme = Theme.of(context);
  final icon = switch (outcome) {
    ChatPlantedOutcome.caught => Icons.verified_outlined,
    ChatPlantedOutcome.notSent => Icons.school_outlined,
    ChatPlantedOutcome.missed => Icons.report_gmailerrorred,
  };
  final color = switch (outcome) {
    ChatPlantedOutcome.caught => Colors.green.shade700,
    ChatPlantedOutcome.notSent => theme.colorScheme.primary,
    ChatPlantedOutcome.missed => theme.colorScheme.error,
  };
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('chat-planted-dialog'),
      icon: Icon(icon, color: color),
      title: Text(l10n.chatPlantedTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(chatPlantedMessage(l10n, outcome, plantedError)),
          if (realDraftReady) ...[
            const SizedBox(height: 12),
            Text(
              l10n.chatPlantedRealDraftReady,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonOk),
        ),
      ],
    ),
  );
}

/// Asks why a draft is rejected. Returns the `reason` to send, or null when
/// cancelled.
Future<String?> showChatRejectSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _RejectSheet(),
  );
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet();

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  ChatRejectReason? _reason;
  final _note = TextEditingController();
  bool _showErrors = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _noteRequired => _reason == ChatRejectReason.other;

  void _submit() {
    final reason = _reason;
    if (reason == null || (_noteRequired && _note.text.trim().isEmpty)) {
      setState(() => _showErrors = true);
      return;
    }
    Navigator.of(context).pop(chatRejectReasonText(reason, _note.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.chatRejectTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reason in ChatRejectReason.values)
                  ChoiceChip(
                    key: ValueKey('chat-reject-${reason.name}'),
                    label: Text(reason.label(l10n)),
                    selected: _reason == reason,
                    onSelected: (_) => setState(() => _reason = reason),
                  ),
              ],
            ),
            if (_showErrors && _reason == null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.chatRejectChooseReason,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('chat-reject-note'),
              controller: _note,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.chatRejectNoteHint,
                border: const OutlineInputBorder(),
                errorText:
                    _showErrors && _noteRequired && _note.text.trim().isEmpty
                        ? l10n.chatRejectNoteRequired
                        : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.commonCancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const ValueKey('chat-reject-confirm'),
                  onPressed: _submit,
                  child: Text(l10n.chatRejectConfirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Instruction for `regenerate_draft`. Returns the hint (possibly empty) or
/// null when cancelled.
///
/// With [requireHint] (our message is the newest, so the AI drafts an extra
/// message from Jarz) the dialog asks what the message should say and the
/// confirm button stays disabled until something is typed.
Future<String?> showChatRegenerateDialog(
  BuildContext context, {
  bool requireHint = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _RegenerateDialog(requireHint: requireHint),
  );
}

class _RegenerateDialog extends StatefulWidget {
  const _RegenerateDialog({this.requireHint = false});

  final bool requireHint;

  @override
  State<_RegenerateDialog> createState() => _RegenerateDialogState();
}

class _RegenerateDialogState extends State<_RegenerateDialog> {
  final _hint = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hint.addListener(_onChanged);
  }

  @override
  void dispose() {
    _hint.removeListener(_onChanged);
    _hint.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Inline bilingual text (no .arb key: an .arb edit forces a full APK).
  String _bi(String en, String ar) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mustHint = widget.requireHint;
    final canConfirm = !mustHint || _hint.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(
        mustHint
            ? _bi('Ask AI for a message', 'اطلب رسالة من الذكاء الاصطناعي')
            : l10n.chatRegenerateTitle,
      ),
      content: TextField(
        key: const ValueKey('chat-regenerate-hint'),
        controller: _hint,
        autofocus: true,
        minLines: mustHint ? 2 : 1,
        maxLines: mustHint ? 4 : 3,
        decoration: InputDecoration(
          labelText: mustHint
              ? _bi('What should the message say?', 'الرسالة تقول إيه؟')
              : l10n.chatRegenerateHintLabel,
          hintText: mustHint
              ? _bi(
                  'e.g. remind them the offer ends today',
                  'مثلاً: فكّره إن العرض بيخلص النهارده',
                )
              : l10n.chatRegenerateHintExample,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const ValueKey('chat-regenerate-confirm'),
          onPressed: canConfirm
              ? () => Navigator.of(context).pop(_hint.text.trim())
              : null,
          child: Text(
            mustHint
                ? _bi('Draft it', 'اكتب المسودة')
                : l10n.chatDraftRegenerate,
          ),
        ),
      ],
    );
  }
}

/// The linked customer at a glance, or a prompt to link one.
///
/// A linked customer also gets an Unlink action ([onUnlink]), confirmed here
/// before it is called.
Future<void> showChatCustomerCardSheet(
  BuildContext context, {
  required ChatCustomerCard? customer,
  required VoidCallback onLink,
  VoidCallback? onUnlink,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      final theme = Theme.of(sheetContext);
      if (customer == null) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.chatCustomerNotLinked),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onLink();
                },
                icon: const Icon(Icons.link),
                label: Text(l10n.chatActionLinkCustomer),
              ),
            ],
          ),
        );
      }
      final lastOrderDate = chatParseDateTime(customer.lastOrderDate);
      Widget row(String label, String value) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(label, style: theme.textTheme.bodySmall),
                ),
                Expanded(child: Text(value)),
              ],
            ),
          );
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            key: const ValueKey('chat-customer-card'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                child: ChatBidiText(
                  customer.customerName,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (customer.customerName != customer.name)
                Text(customer.name, style: theme.textTheme.bodySmall),
              const Divider(height: 20),
              if (customer.mobileNo != null)
                row(l10n.chatCustomerPhone, customer.mobileNo!),
              if (customer.territory != null)
                row(l10n.chatCustomerTerritory, customer.territory!),
              row(
                l10n.chatCustomerTotalOrders,
                formatCount(sheetContext, customer.totalOrders),
              ),
              if (lastOrderDate != null || customer.lastOrderTotal != null)
                row(
                  l10n.chatCustomerLastOrder,
                  [
                    if (lastOrderDate != null)
                      formatDate(sheetContext, lastOrderDate),
                    if (customer.lastOrderTotal != null)
                      formatCurrency(sheetContext, customer.lastOrderTotal!),
                  ].join(' · '),
                ),
              row(
                l10n.chatCustomerLifetimeValue,
                formatCurrency(sheetContext, customer.lifetimeValue),
              ),
              if (customer.recentItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.chatCustomerRecentItems,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final item in customer.recentItems)
                      Chip(
                        label: Text(item),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onLink();
                },
                icon: const Icon(Icons.link),
                label: Text(l10n.chatActionLinkCustomer),
              ),
              if (onUnlink != null)
                TextButton.icon(
                  key: const ValueKey('chat-customer-unlink'),
                  onPressed: () async {
                    final confirmed = await showChatUnlinkConfirm(
                      sheetContext,
                      customer.customerName,
                    );
                    if (confirmed != true || !sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                    onUnlink();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.link_off),
                  label: Text(chatBi(sheetContext, 'Unlink', 'فك الربط')),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// "Unlink {name} from this chat?" Returns true when confirmed.
Future<bool?> showChatUnlinkConfirm(BuildContext context, String name) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('chat-unlink-dialog'),
      title: Text(chatBi(dialogContext, 'Unlink customer?', 'فك ربط العميل؟')),
      content: Text(
        chatBi(
          dialogContext,
          'This chat will no longer be linked to $name.',
          'المحادثة دي مش هتبقى مربوطة بـ $name.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(dialogContext.l10n.commonCancel),
        ),
        FilledButton(
          key: const ValueKey('chat-unlink-confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(chatBi(dialogContext, 'Unlink', 'فك الربط')),
        ),
      ],
    ),
  );
}

/// Channel + status chips for the thread header subtitle.
String chatThreadSubtitle(
  AppLocalizations l10n,
  ChatConversationSummary summary,
) {
  final parts = <String>[
    chatChannelLabel(l10n, summary.channel),
    chatStatusLabel(l10n, summary.status),
    if (chatIntentLabel(l10n, summary.intent) != null &&
        summary.intent != 'Complaint')
      chatIntentLabel(l10n, summary.intent)!,
    if (summary.assignedToName != null)
      l10n.chatAssignedTo(summary.assignedToName!),
  ];
  return parts.join(' · ');
}

/// The thread header subtitle: the linked customer first, then the channel /
/// status line, then the contact category (marked "AI" when the AI chose it).
String chatThreadSubtitleFull(
  BuildContext context,
  ChatConversationSummary summary,
) {
  final l10n = context.l10n;
  final category = summary.contactCategory;
  final showCategory = category != null && category.isNotEmpty;
  return [
    if (summary.customerName != null) summary.customerName!,
    chatThreadSubtitle(l10n, summary),
    if (showCategory)
      summary.categoryIsAi
          ? '${chatCategoryLabel(context, category)} (AI)'
          : chatCategoryLabel(context, category),
  ].join(' · ');
}
