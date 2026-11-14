import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../data/models/chat_models.dart';

/// The AI draft docked above the composer: text (editable), upsell chip,
/// warnings, the "needs you" reason, and Send / Edit / Reject / Regenerate.
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
  });

  final ChatDraft draft;

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
  bool _editing = false;

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
      // start from its text, out of edit mode.
      _controller.text = widget.draft.draftText;
      _editing = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _addUpsell() {
    final line = widget.draft.upsellText?.trim() ?? '';
    if (line.isEmpty || _controller.text.contains(line)) return;
    final current = _controller.text.trimRight();
    _controller.text = current.isEmpty ? line : '$current\n$line';
    setState(() => _editing = true);
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: _editing
                      ? TextField(
                          key: const ValueKey('chat-draft-field'),
                          controller: _controller,
                          minLines: 2,
                          maxLines: 6,
                          maxLength: 4096,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                        )
                      : SingleChildScrollView(
                          child: SelectableText(
                            text,
                            key: const ValueKey('chat-draft-text'),
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
                        avatar: const Icon(Icons.add_shopping_cart, size: 18),
                        label: Text(l10n.chatDraftUpsell(draft.upsellLabel!)),
                        onPressed: (draft.upsellText?.trim().isNotEmpty ?? false)
                            ? _addUpsell
                            : null,
                      ),
                    ),
                  ),
                ],
                if (draft.factConflicts.isNotEmpty)
                  _FactConflictAlert(conflicts: draft.factConflicts),
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
                      key: const ValueKey('chat-draft-edit'),
                      onPressed: widget.busy
                          ? null
                          : () => setState(() => _editing = !_editing),
                      icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
                      label: Text(
                        _editing ? l10n.commonDone : l10n.chatDraftEdit,
                      ),
                    ),
                    FilledButton.icon(
                      key: const ValueKey('chat-draft-send'),
                      onPressed:
                          canSend ? () => widget.onSend(text.trim()) : null,
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
class _FactConflictAlert extends StatelessWidget {
  const _FactConflictAlert({required this.conflicts});

  final List<String> conflicts;

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
          for (final conflict in conflicts)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: TextStyle(color: color)),
                  Expanded(
                    child: Text(
                      conflict,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
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
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
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
        ],
      ),
    );
  }
}
