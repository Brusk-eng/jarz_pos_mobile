import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../calendar/state/cairo_time.dart';

/// Pure rules of the founder's approvals list: which post a card is about,
/// when it goes out, how the cards group by day, and the words behind a card.
/// No widgets, so every rule is tested on its own.

/// How long before the slot an approval can still be undone.
const approvalUndoWindow = Duration(minutes: 15);

/// The post the card is about: the earliest dated one.
PostSummary? primaryPost(ApproveCard c) {
  PostSummary? best;
  DateTime? bestAt;
  for (final p in c.posts) {
    final at = CairoTime.parse(p.slotTime);
    if (at == null) continue;
    if (bestAt == null || at.isBefore(bestAt)) {
      best = p;
      bestAt = at;
    }
  }
  return best ?? (c.posts.isEmpty ? null : c.posts.first);
}

/// When the card goes out (Cairo wall time), or null when it has no date.
DateTime? approvalSlot(ApproveCard c) =>
    CairoTime.parse(primaryPost(c)?.slotTime);

/// Where a card sits in the day groups.
enum ApprovalDay { overdue, today, tomorrow, later, noTime }

class ApprovalGroup {
  const ApprovalGroup(this.kind, this.date, this.cards);
  final ApprovalDay kind;

  /// The day, for [ApprovalDay.later] (and today / tomorrow).
  final DateTime? date;
  final List<ApproveCard> cards;
}

/// [cards] ordered by the time they go out and grouped by day: overdue first,
/// then today, tomorrow and each later day; cards without a slot come last.
List<ApprovalGroup> groupApprovals(List<ApproveCard> cards, DateTime now) {
  final sorted = [...cards]
    ..sort((a, b) {
      final x = approvalSlot(a), y = approvalSlot(b);
      if (x == null && y == null) return a.version.id.compareTo(b.version.id);
      if (x == null) return 1;
      if (y == null) return -1;
      final c = x.compareTo(y);
      return c != 0 ? c : a.version.id.compareTo(b.version.id);
    });
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = CairoTime.addDays(today, 1);
  final out = <ApprovalGroup>[];
  final buckets = <String, List<ApproveCard>>{};
  final order = <String>[];
  final kinds = <String, (ApprovalDay, DateTime?)>{};
  for (final c in sorted) {
    final at = approvalSlot(c);
    late final String key;
    late final (ApprovalDay, DateTime?) kind;
    if (at == null) {
      key = 'none';
      kind = (ApprovalDay.noTime, null);
    } else if (at.isBefore(now)) {
      key = 'overdue';
      kind = (ApprovalDay.overdue, null);
    } else {
      final day = DateTime(at.year, at.month, at.day);
      key = CairoTime.date(day);
      kind = (
        CairoTime.sameDay(day, today)
            ? ApprovalDay.today
            : CairoTime.sameDay(day, tomorrow)
            ? ApprovalDay.tomorrow
            : ApprovalDay.later,
        day,
      );
    }
    if (!buckets.containsKey(key)) {
      order.add(key);
      kinds[key] = kind;
    }
    (buckets[key] ??= []).add(c);
  }
  for (final k in order) {
    out.add(ApprovalGroup(kinds[k]!.$1, kinds[k]!.$2, buckets[k]!));
  }
  return out;
}

/// A span split into whole days, hours and minutes (always at least one
/// minute so "in 0 min" is never written).
class ApprovalSpan {
  const ApprovalSpan({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.past,
  });
  final int days;
  final int hours;
  final int minutes;

  /// The slot has passed.
  final bool past;
}

/// The time from [now] to [slot].
ApprovalSpan spanTo(DateTime slot, DateTime now) {
  final diff = slot.difference(now);
  final past = diff.isNegative;
  final total = diff.abs().inMinutes;
  final mins = total < 1 ? 1 : total;
  return ApprovalSpan(
    days: mins ~/ (24 * 60),
    hours: (mins ~/ 60) % 24,
    minutes: mins % 60,
    past: past,
  );
}

/// Whether the approval can still be undone: the slot is more than 15 minutes
/// away. A card with no slot can always be undone.
bool canUndoApproval(ApproveCard c, DateTime now) {
  final at = approvalSlot(c);
  return at == null || at.difference(now) > approvalUndoWindow;
}

/// What a channel is called in words, as the founder says it. [ar] picks
/// Arabic. Flavour of platform: everything is Instagram except TikTok.
String channelWords(PostChannel? ch, PieceFormat format, {required bool ar}) {
  final c = ch ?? _channelOfFormat(format);
  if (ar) {
    return switch (c) {
      PostChannel.feedReel => 'Instagram ريل على الفيد',
      PostChannel.trialReel => 'Instagram ريل تجريبي',
      PostChannel.trialReelFeed => 'Instagram ريل تجريبي ثم الفيد',
      PostChannel.feedStatic => 'Instagram صورة',
      PostChannel.feedCarousel => 'Instagram كاروسيل',
      PostChannel.tikTok => 'TikTok',
      PostChannel.story => 'Instagram ستوري',
      _ => 'Instagram',
    };
  }
  return switch (c) {
    PostChannel.feedReel => 'Instagram feed reel',
    PostChannel.trialReel => 'Instagram trial reel',
    PostChannel.trialReelFeed => 'Instagram trial reel, then feed',
    PostChannel.feedStatic => 'Instagram static',
    PostChannel.feedCarousel => 'Instagram carousel',
    PostChannel.tikTok => 'TikTok',
    PostChannel.story => 'Instagram story',
    _ => 'Instagram',
  };
}

PostChannel _channelOfFormat(PieceFormat f) => switch (f) {
  PieceFormat.reel => PostChannel.feedReel,
  PieceFormat.trial => PostChannel.trialReel,
  PieceFormat.staticValue => PostChannel.feedStatic,
  PieceFormat.carousel => PostChannel.feedCarousel,
  PieceFormat.story => PostChannel.story,
  PieceFormat.unknown => PostChannel.unknown,
};

/// The platform name used in "Approved. Posts by itself ... on Instagram".
String platformWords(PostChannel? ch) =>
    ch == PostChannel.tikTok ? 'TikTok' : 'Instagram';

/// Who puts the post up: the system at the slot, or a person by hand.
({bool byHand, String? name}) whoPosts(PostSummary? p) {
  if (p == null) return (byHand: false, name: null);
  final byHand = p.postingMode == PostingMode.byHand;
  return (byHand: byHand, name: byHand ? p.assignee?.fullName : null);
}

/// The one line of the sell judge's reason: why it sells for a RUN, what stops
/// it for a FIX or a DROP.
String? verdictReason(ApproveCard c) {
  final v = c.version.verdict;
  if (v == null) return null;
  final text = switch (v.verdict) {
    VerdictLabel.rUN => v.why ?? v.stops,
    _ => v.stops ?? v.why,
  };
  final t = text?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

/// The gate lines that failed, in the server's words.
List<String> failedGateLines(ApproveCard c) {
  final lines = <String>[
    for (final k in c.gate.checks)
      if (!k.ok)
        (k.detail == null || k.detail!.trim().isEmpty)
            ? k.label
            : '${k.label}: ${k.detail}',
  ];
  if (lines.isNotEmpty) return lines;
  return [
    for (final f in c.gate.fails)
      if (f.trim().isNotEmpty) f,
  ];
}
