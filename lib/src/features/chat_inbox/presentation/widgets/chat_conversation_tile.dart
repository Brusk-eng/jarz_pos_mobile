import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/localized_formatters.dart';
import '../../data/models/chat_models.dart';
import '../chat_bidi.dart';
import '../chat_labels.dart';
import 'chat_notes_strip.dart' show kChatNoteAccent;

/// One inbox row: channel icon, name, preview, live "waiting N min" (red at
/// [kChatWaitingAlertMinutes]+), complaint badge, open staff-notes badge,
/// draft-ready dot and the unread count.
class ChatConversationTile extends StatelessWidget {
  const ChatConversationTile({
    super.key,
    required this.summary,
    required this.now,
    required this.onTap,
  });

  final ChatConversationSummary summary;

  /// The inbox's ticking clock, so every row's wait label moves together.
  final DateTime now;
  final VoidCallback onTap;

  String _timeLabel(BuildContext context, DateTime? time) {
    if (time == null) return '';
    final sameDay = time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;
    return formatDateTime(
      context,
      time,
      pattern: sameDay ? 'h:mm a' : 'MMM d',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final channelColor = chatChannelColor(summary.channel);
    final waiting = summary.waitingMinutes(now);
    final waitingAlert =
        waiting != null && waiting >= kChatWaitingAlertMinutes;
    final unread = summary.unreadCount;
    // Status Open = the customer is waiting for a reply; the name is bold so
    // it stands out from Answered rows in the Open (not Closed) segment.
    final needsReply = summary.status == ChatStatuses.open;
    final preview = summary.lastMessagePreview ?? '';
    final previewText = summary.lastDirection == 'Outbound' && preview.isNotEmpty
        ? l10n.chatPreviewYou(preview)
        : preview;

    return ListTile(
      key: ValueKey('chat-tile-${summary.name}'),
      onTap: onTap,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            backgroundColor: channelColor.withValues(alpha: 0.15),
            foregroundColor: channelColor,
            child: Icon(
              chatChannelIcon(summary.channel),
              semanticLabel: chatChannelLabel(l10n, summary.channel),
            ),
          ),
          if (summary.hasPendingDraft)
            PositionedDirectional(
              end: -2,
              top: -2,
              child: Tooltip(
                message: l10n.chatDraftReadyTooltip,
                child: Container(
                  key: ValueKey('chat-draft-dot-${summary.name}'),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              summary.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: unread > 0 || needsReply
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
            ),
          ),
          if (_showsCategory(summary.contactCategory)) ...[
            const SizedBox(width: 6),
            KeyedSubtree(
              key: ValueKey('chat-category-chip-${summary.name}'),
              child: _Pill(
                label: chatCategoryLabel(context, summary.contactCategory),
                color: chatCategoryColor(summary.contactCategory),
              ),
            ),
          ],
          if (summary.isComplaint) ...[
            const SizedBox(width: 6),
            _Pill(
              label: l10n.chatComplaintBadge,
              color: theme.colorScheme.error,
            ),
          ],
          if (summary.openNotes > 0) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: chatBi(
                context,
                'Open staff notes: ${formatCount(context, summary.openNotes)}',
                'ملاحظات مفتوحة: ${formatCount(context, summary.openNotes)}',
              ),
              child: Row(
                key: ValueKey('chat-notes-badge-${summary.name}'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sticky_note_2,
                    size: 16,
                    color: kChatNoteAccent,
                  ),
                  if (summary.openNotes > 1)
                    Text(
                      formatCount(context, summary.openNotes),
                      style: const TextStyle(
                        color: kChatNoteAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (previewText.isNotEmpty)
            Text(
              previewText,
              key: ValueKey('chat-preview-${summary.name}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              textDirection: chatTextDirection(
                previewText,
                Directionality.of(context),
              ),
            ),
          if (waiting != null || summary.assignedToName != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Wrap(
                spacing: 8,
                children: [
                  if (waiting != null)
                    Text(
                      l10n.chatWaitingMinutes(formatCount(context, waiting)),
                      key: ValueKey('chat-waiting-${summary.name}'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: waitingAlert
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            waitingAlert ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  if (summary.assignedToName != null)
                    Text(
                      l10n.chatAssignedTo(summary.assignedToName!),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _timeLabel(context, summary.lastMessageTime),
            style: theme.textTheme.bodySmall,
          ),
          if (unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              key: ValueKey('chat-unread-${summary.name}'),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                formatCount(context, unread),
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Supplier, Content Creator and Other get a chip; Customer / blank do not.
bool _showsCategory(String? category) =>
    category == ChatContactCategories.supplier ||
    category == ChatContactCategories.contentCreator ||
    category == ChatContactCategories.other;

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
