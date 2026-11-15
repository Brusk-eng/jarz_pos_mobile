import 'package:flutter/material.dart';

import '../../data/models/chat_models.dart';
import '../chat_bidi.dart';
import '../chat_labels.dart';

/// The slim strip under the app bar of an UNLINKED chat.
///
/// With a [suggestion] ("looks like Ahmed · 010… · 4 orders") it offers a
/// one-tap Link and "Not them" (dismissed for the session); without one it
/// says the chat is not linked and offers "Find or add".
class ChatLinkBanner extends StatelessWidget {
  const ChatLinkBanner({
    super.key,
    required this.suggestion,
    required this.busy,
    required this.onLink,
    required this.onDismiss,
    required this.onFind,
  });

  final ChatCustomerCandidate? suggestion;
  final bool busy;
  final VoidCallback onLink;
  final VoidCallback onDismiss;
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestion = this.suggestion;
    final color = theme.colorScheme.tertiaryContainer;
    final onColor = theme.colorScheme.onTertiaryContainer;

    final Widget label;
    final List<Widget> actions;
    if (suggestion != null) {
      final orders = suggestion.totalOrders;
      final text = chatBi(
        context,
        'Looks like ${suggestion.customerName}'
            '${suggestion.mobileNo == null ? '' : ' · ${suggestion.mobileNo}'}'
            ' · $orders ${orders == 1 ? 'order' : 'orders'}',
        'شكله ${suggestion.customerName}'
            '${suggestion.mobileNo == null ? '' : ' · ${suggestion.mobileNo}'}'
            ' · $orders ${orders == 1 ? 'طلب' : 'طلبات'}',
      );
      label = Text(
        text,
        key: const ValueKey('chat-link-banner-text'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textDirection: chatTextDirection(text, Directionality.of(context)),
        style: theme.textTheme.bodyMedium?.copyWith(color: onColor),
      );
      actions = [
        FilledButton(
          key: const ValueKey('chat-link-banner-link'),
          onPressed: busy ? null : onLink,
          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          child: Text(chatBi(context, 'Link', 'اربط')),
        ),
        TextButton(
          key: const ValueKey('chat-link-banner-dismiss'),
          onPressed: busy ? null : onDismiss,
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          child: Text(chatBi(context, 'Not them', 'مش هو')),
        ),
      ];
    } else {
      label = Text(
        chatBi(context, 'Not linked to a customer', 'مش مربوطة بعميل'),
        key: const ValueKey('chat-link-banner-text'),
        style: theme.textTheme.bodyMedium?.copyWith(color: onColor),
      );
      actions = [
        TextButton(
          key: const ValueKey('chat-link-banner-find'),
          onPressed: busy ? null : onFind,
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          child: Text(chatBi(context, 'Find or add', 'دوّر أو أضف')),
        ),
      ];
    }

    return Material(
      key: const ValueKey('chat-link-banner'),
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.person_search_outlined, size: 18, color: onColor),
            const SizedBox(width: 8),
            Expanded(child: label),
            const SizedBox(width: 4),
            ...actions,
          ],
        ),
      ),
    );
  }
}
