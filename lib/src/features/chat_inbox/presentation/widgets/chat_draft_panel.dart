import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../data/models/chat_models.dart';
import '../chat_bidi.dart';
import '../chat_labels.dart';
import 'chat_add_fact_dialog.dart';
import 'chat_message_actions.dart';

/// The AI draft docked above the composer: text (always editable in place),
/// upsell chip, warnings, the "needs you" reason, and Send / Copy / Reject /
/// Regenerate.
///
/// A complaint draft is locked: Send stays disabled until the text differs
/// from the draft (the server refuses an unchanged complaint reply anyway).
/// A Failed draft shows "draft unavailable — type your reply" and only
/// Regenerate.
///
/// See also [ChatAskAiBar], shown in this panel's place when our message is
/// the newest and no draft is waiting.
class ChatDraftPanel extends StatefulWidget {
  const ChatDraftPanel({
    super.key,
    required this.draft,
    required this.busy,
    required this.onSend,
    required this.onReject,
    required this.onRegenerate,
    this.maxHeight,
    this.canApproveFacts = false,
    this.onAddFact,
  });

  final ChatDraft draft;

  /// The caller may add a fact-conflict line to the approved facts; each
  /// line of the confirm-facts alert then offers "Add to facts".
  final bool canApproveFacts;

  /// "Add to facts" on conflict line [index] (text [line]) was tapped.
  final void Function(int index, String line)? onAddFact;

  /// The most height the panel may take (the thread passes a share of what is
  /// left above the keyboard); its content scrolls beyond that.
  final double? maxHeight;

  /// A draft action is in flight; every button is disabled meanwhile.
  final bool busy;
  final ValueChanged<String> onSend;
  final VoidCallback onReject;
  final VoidCallback onRegenerate;

  @override
  State<ChatDraftPanel> createState() => _ChatDraftPanelState();
}

class _ChatDraftPanelState extends State<ChatDraftPanel> {
  late final TextEditingController _controller;
  final FocusNode _fieldFocus = FocusNode();
  final GlobalKey _fieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.draft.draftText);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatDraftPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.name != widget.draft.name) {
      // A new draft (regenerated, or the real one after a training check):
      // start from its text.
      _controller.text = widget.draft.draftText;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _fieldFocus.dispose();
    super.dispose();
  }

  /// The complaint-lock note was tapped. The draft text box sits at the top
  /// of this scrolling panel and is often out of sight below the facts alert,
  /// so bring it back into view and put the cursor at the end, ready to edit.
  Future<void> _editDraft() async {
    final fieldContext = _fieldKey.currentContext;
    if (fieldContext != null) {
      await Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    if (!mounted) return;
    _fieldFocus.requestFocus();
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _addUpsell() {
    final line = widget.draft.upsellText?.trim() ?? '';
    if (line.isEmpty || _controller.text.contains(line)) return;
    final current = _controller.text.trimRight();
    _controller.text = current.isEmpty ? line : '$current\n$line';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final draft = widget.draft;
    final text = _controller.text;
    final unchanged = draft.isUnchanged(text);
    final complaintLocked = draft.isComplaint && unchanged;
    final canSend = !widget.busy && text.trim().isNotEmpty && !complaintLocked;

    return Material(
      key: const ValueKey('chat-draft-panel'),
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
      child: SafeArea(
        top: false,
        bottom: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: widget.maxHeight ?? double.infinity,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.chatDraftTitle,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (!draft.isFailed && !unchanged)
                        Text(
                          l10n.chatDraftEditedLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      if (widget.busy) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (draft.isFailed) ...[
                    Text(
                      l10n.chatDraftUnavailable,
                      key: const ValueKey('chat-draft-unavailable'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        key: const ValueKey('chat-draft-regenerate'),
                        onPressed: widget.busy ? null : widget.onRegenerate,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.chatDraftRegenerate),
                      ),
                    ),
                  ] else ...[
                    // Always editable in place: no Edit / Done toggle. System
                    // cut / copy / paste / select-all come with the TextField.
                    KeyedSubtree(
                      key: _fieldKey,
                      child: TextField(
                        key: const ValueKey('chat-draft-field'),
                        controller: _controller,
                        focusNode: _fieldFocus,
                        minLines: 3,
                        maxLines: 10,
                        maxLength: 4096,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        textAlign: TextAlign.start,
                        textDirection: chatTextDirection(
                          text,
                          Directionality.of(context),
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                    ),
                    if (draft.upsellLabel != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Tooltip(
                          message: draft.upsellText ?? draft.upsellLabel!,
                          child: ActionChip(
                            key: const ValueKey('chat-draft-upsell'),
                            avatar: const Icon(
                              Icons.add_shopping_cart,
                              size: 18,
                            ),
                            label: Text(
                              l10n.chatDraftUpsell(draft.upsellLabel!),
                            ),
                            onPressed:
                                (draft.upsellText?.trim().isNotEmpty ?? false)
                                ? _addUpsell
                                : null,
                          ),
                        ),
                      ),
                    ],
                    if (draft.factConflicts.isNotEmpty)
                      _FactConflictAlert(
                        conflicts: draft.factConflicts,
                        approved: draft.approvedConflicts,
                        canApprove:
                            widget.canApproveFacts && widget.onAddFact != null,
                        onAdd: widget.onAddFact,
                      ),
                    for (final warning in draft.warnings)
                      _NoteRow(
                        icon: Icons.warning_amber_rounded,
                        color: Colors.orange.shade800,
                        text: warning,
                      ),
                    if (draft.needsHumanReason != null)
                      _NoteRow(
                        icon: Icons.support_agent,
                        color: theme.colorScheme.tertiary,
                        text: l10n.chatDraftNeedsHuman(draft.needsHumanReason!),
                      ),
                    if (complaintLocked)
                      _NoteRow(
                        key: const ValueKey('chat-draft-complaint-lock'),
                        icon: Icons.lock_outline,
                        color: theme.colorScheme.error,
                        text: l10n.chatDraftComplaintLock,
                        // Tapping it jumps to the draft box to edit it.
                        onTap: widget.busy ? null : _editDraft,
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      children: [
                        TextButton.icon(
                          key: const ValueKey('chat-draft-regenerate'),
                          onPressed: widget.busy ? null : widget.onRegenerate,
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.chatDraftRegenerate),
                        ),
                        TextButton.icon(
                          key: const ValueKey('chat-draft-reject'),
                          onPressed: widget.busy ? null : widget.onReject,
                          icon: const Icon(Icons.thumb_down_alt_outlined),
                          label: Text(l10n.chatDraftReject),
                        ),
                        OutlinedButton.icon(
                          key: const ValueKey('chat-draft-copy'),
                          onPressed: text.trim().isEmpty
                              ? null
                              : () => copyChatText(context, text.trim()),
                          icon: const Icon(Icons.copy_outlined),
                          label: Text(chatBi(context, 'Copy', 'نسخ')),
                        ),
                        FilledButton.icon(
                          key: const ValueKey('chat-draft-send'),
                          onPressed: canSend
                              ? () => widget.onSend(text.trim())
                              : null,
                          icon: const Icon(Icons.send),
                          label: Text(l10n.chatDraftSend),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown above the composer when our message is the newest and no draft is
/// waiting: "Ask AI for a message" (opens the required-instruction dialog),
/// or, when the 24-hour reply window is closed, a short note instead, since
/// a free-form message could not be delivered.
class ChatAskAiBar extends StatelessWidget {
  const ChatAskAiBar({
    super.key,
    required this.windowClosed,
    required this.busy,
    required this.onAsk,
  });

  final bool windowClosed;

  /// The ask is in flight: spinner, button disabled.
  final bool busy;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String bi(String en, String arText) => ar ? arText : en;

    return Material(
      key: const ValueKey('chat-ask-ai-bar'),
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.30),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: windowClosed
            ? _NoteRow(
                key: const ValueKey('chat-ask-ai-window-closed'),
                icon: Icons.schedule,
                color: theme.colorScheme.error,
                text: bi(
                  'The 24-hour window is closed, so the AI cannot draft a new '
                  'message. Wait for the customer to write again.',
                  'فترة الـ 24 ساعة خلصت، فالذكاء الاصطناعي مش هيقدر يكتب رسالة '
                      'جديدة. استنى لحد ما العميل يبعت تاني.',
                ),
              )
            : Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const ValueKey('chat-ask-ai'),
                  onPressed: busy ? null : onAsk,
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    bi(
                      'Ask AI for a message',
                      'اطلب رسالة من الذكاء الاصطناعي',
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// The draft did what the moderator asked even where it goes against our
/// approved facts, menu or prices. This box lists each such point so the
/// moderator confirms it is right before sending. It never blocks Send.
///
/// A manager ([canApprove]) can add a line to the approved facts from here;
/// a line already added shows "Added to facts ✓".
class _FactConflictAlert extends StatelessWidget {
  const _FactConflictAlert({
    required this.conflicts,
    this.approved = const <int>[],
    this.canApprove = false,
    this.onAdd,
  });

  final List<String> conflicts;
  final List<int> approved;
  final bool canApprove;
  final void Function(int index, String line)? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final color = Colors.deepOrange.shade800;
    return Container(
      key: const ValueKey('chat-draft-fact-conflicts'),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ar
                      ? 'أكّد المعلومات دي قبل الإرسال'
                      : 'Confirm these facts before sending',
                  style: theme.textTheme.titleSmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            ar
                ? 'الرد اتكتب زي ما طلبت، بس ده مختلف عن المعلومات المعتمدة عندنا:'
                : 'The draft follows your instruction, but it differs from our '
                    'approved facts:',
            style: theme.textTheme.bodySmall,
          ),
          for (final (index, conflict) in conflicts.indexed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: TextStyle(color: color)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ChatBidiText(
                            conflict,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                            ),
                          ),
                        ),
                        ChatFactConflictAction(
                          keyId: '$index',
                          approved: approved.contains(index),
                          canApprove: canApprove,
                          onAdd: onAdd == null
                              ? null
                              : () => onAdd!(index, conflict),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;

  /// When set, the whole row is tappable and ends with an edit icon.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          Icon(Icons.edit_outlined, size: 16, color: color),
        ],
      ],
    );
    if (onTap == null) {
      return Padding(padding: const EdgeInsets.only(top: 4), child: row);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: row,
        ),
      ),
    );
  }
}
