// Display labels, icons and colours for the chat inbox's wire values. The
// wire strings themselves never change; only what the moderator reads does.

import 'package:flutter/material.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';

import '../data/models/chat_models.dart';
import '../state/chat_providers.dart';

/// Minutes of waiting after which the inbox label turns red.
const kChatWaitingAlertMinutes = 10;

String chatChannelLabel(AppLocalizations l10n, String channel) =>
    switch (channel) {
      ChatChannels.whatsApp => l10n.chatChannelWhatsApp,
      ChatChannels.instagram => l10n.chatChannelInstagram,
      ChatChannels.messenger => l10n.chatChannelMessenger,
      ChatChannels.facebookComment => l10n.chatChannelFacebookComment,
      ChatChannels.instagramComment => l10n.chatChannelInstagramComment,
      _ => channel,
    };

IconData chatChannelIcon(String channel) => switch (channel) {
      ChatChannels.whatsApp => Icons.chat,
      ChatChannels.instagram => Icons.camera_alt_outlined,
      ChatChannels.messenger => Icons.messenger_outline,
      ChatChannels.facebookComment => Icons.comment_outlined,
      ChatChannels.instagramComment => Icons.mode_comment_outlined,
      _ => Icons.forum_outlined,
    };

Color chatChannelColor(String channel) => switch (channel) {
      ChatChannels.whatsApp => const Color(0xFF25D366),
      ChatChannels.instagram ||
      ChatChannels.instagramComment =>
        const Color(0xFFC13584),
      ChatChannels.messenger ||
      ChatChannels.facebookComment =>
        const Color(0xFF1877F2),
      _ => Colors.blueGrey,
    };

String chatSegmentLabel(AppLocalizations l10n, ChatInboxSegment segment) =>
    switch (segment) {
      ChatInboxSegment.open => l10n.chatSegmentOpen,
      ChatInboxSegment.mine => l10n.chatSegmentMine,
      ChatInboxSegment.all => l10n.chatSegmentAll,
      ChatInboxSegment.closed => l10n.chatSegmentClosed,
    };

String chatStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      ChatStatuses.open => l10n.chatStatusOpen,
      ChatStatuses.answered => l10n.chatStatusAnswered,
      ChatStatuses.closed => l10n.chatStatusClosed,
      _ => status,
    };

String? chatIntentLabel(AppLocalizations l10n, String? intent) =>
    switch (intent) {
      'Inquiry' => l10n.chatIntentInquiry,
      'Order' => l10n.chatIntentOrder,
      'Complaint' => l10n.chatComplaintBadge,
      'Other' => l10n.chatIntentOther,
      _ => null,
    };

/// The placeholder line shown for a non-text message with no caption.
String chatMessageTypeLabel(AppLocalizations l10n, String messageType) =>
    switch (messageType) {
      'image' => l10n.chatMessageImage,
      'audio' => l10n.chatMessageAudio,
      'video' => l10n.chatMessageVideo,
      'document' => l10n.chatMessageDocument,
      'sticker' => l10n.chatMessageSticker,
      'location' => l10n.chatMessageLocation,
      'reaction' => l10n.chatMessageReaction,
      'template' => l10n.chatMessageTemplate,
      'unsupported' => l10n.chatMessageUnsupported,
      _ => '',
    };

IconData chatMessageTypeIcon(String messageType) => switch (messageType) {
      'image' || 'sticker' => Icons.image_outlined,
      'audio' => Icons.mic_none,
      'video' => Icons.videocam_outlined,
      'document' => Icons.description_outlined,
      'location' => Icons.place_outlined,
      _ => Icons.attach_file,
    };

/// Reject reasons. The value sent to the server is the English wire code
/// (so reports read the same whatever the moderator's language); the label
/// is localized.
enum ChatRejectReason {
  wrongInfo('Wrong information'),
  wrongPrice('Wrong price or number'),
  wrongTone('Wrong tone'),
  offTopic('Does not answer the customer'),
  badSuggestion('Bad upsell suggestion'),
  other('Other');

  const ChatRejectReason(this.wire);
  final String wire;

  String label(AppLocalizations l10n) => switch (this) {
        ChatRejectReason.wrongInfo => l10n.chatRejectReasonWrongInfo,
        ChatRejectReason.wrongPrice => l10n.chatRejectReasonWrongPrice,
        ChatRejectReason.wrongTone => l10n.chatRejectReasonTone,
        ChatRejectReason.offTopic => l10n.chatRejectReasonOffTopic,
        ChatRejectReason.badSuggestion => l10n.chatRejectReasonUpsell,
        ChatRejectReason.other => l10n.chatRejectReasonOther,
      };
}

/// The `reason` string sent to `reject_draft`: the wire code, then the
/// moderator's note when one was written.
String chatRejectReasonText(ChatRejectReason reason, String note) {
  final trimmed = note.trim();
  if (trimmed.isEmpty) return reason.wire;
  return '${reason.wire}: $trimmed';
}

// ─────────────────────────────────────────────────────────────────────────
// Inline bilingual strings (no .arb keys: an .arb edit forces a full APK, and
// these screens ship as a Dart-only Shorebird patch).
// ─────────────────────────────────────────────────────────────────────────

/// [en] or [ar] by the app locale.
String chatBi(BuildContext context, String en, String ar) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

/// A contact category as the moderator reads it ("" for Customer / blank is
/// handled by the callers that hide it).
String chatCategoryLabel(BuildContext context, String? category) =>
    switch (category) {
      ChatContactCategories.supplier => chatBi(context, 'Supplier', 'مورّد'),
      ChatContactCategories.contentCreator => chatBi(
        context,
        'Content creator',
        'صانع محتوى',
      ),
      ChatContactCategories.other => chatBi(context, 'Other', 'أخرى'),
      ChatContactCategories.customer ||
      null ||
      '' => chatBi(context, 'Customer', 'عميل'),
      _ => category,
    };

/// The plural filter-chip wording of a category.
String chatCategoryFilterLabel(BuildContext context, String? category) =>
    switch (category) {
      null => chatBi(context, 'All', 'الكل'),
      ChatContactCategories.customer => chatBi(context, 'Customers', 'عملاء'),
      ChatContactCategories.supplier => chatBi(context, 'Suppliers', 'موردين'),
      ChatContactCategories.contentCreator => chatBi(
        context,
        'Content creators',
        'صنّاع محتوى',
      ),
      ChatContactCategories.other => chatBi(context, 'Other', 'أخرى'),
      _ => category,
    };

Color chatCategoryColor(String? category) => switch (category) {
  ChatContactCategories.supplier => const Color(0xFFB45309),
  ChatContactCategories.contentCreator => const Color(0xFF7C3AED),
  ChatContactCategories.other => Colors.blueGrey,
  _ => Colors.blueGrey,
};

/// Why a customer was suggested, as a short chip label.
String chatSuggestionReasonLabel(BuildContext context, String reason) =>
    switch (reason) {
      ChatSuggestionReasons.phone => chatBi(context, 'Same phone', 'نفس الرقم'),
      ChatSuggestionReasons.typedPhone => chatBi(
        context,
        'Typed this number',
        'كتب الرقم ده',
      ),
      ChatSuggestionReasons.name => chatBi(context, 'Name match', 'الاسم شبه'),
      ChatSuggestionReasons.sameContact => chatBi(
        context,
        'Linked in another chat',
        'مربوط في محادثة تانية',
      ),
      _ => reason,
    };

/// A draft status in the moderator-overrides list.
String chatDraftStatusLabel(BuildContext context, String status) {
  if (status.startsWith('Sent')) return chatBi(context, 'Sent', 'اتبعت');
  return switch (status) {
    ChatDraftStatuses.rejected => chatBi(context, 'Rejected', 'اتّرفض'),
    ChatDraftStatuses.superseded => chatBi(context, 'Replaced', 'اتحلّ مكانه'),
    ChatDraftStatuses.pending => chatBi(context, 'Pending', 'مستني'),
    ChatDraftStatuses.held => chatBi(context, 'Held', 'متوقف'),
    ChatDraftStatuses.blocked => chatBi(context, 'Blocked', 'محظور'),
    ChatDraftStatuses.failed => chatBi(context, 'Failed', 'فشل'),
    _ => status,
  };
}
