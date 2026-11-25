import 'package:flutter/material.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import 'inbox_strings.dart';
import '../../../shared/studio_toast.dart';

void showStudioNote(BuildContext context, String text) => showStudioToast(text);

DateTime? _wallTime(String? iso) {
  if (iso == null || iso.length < 10) return null;
  final d = DateTime.tryParse(iso.length > 19 ? iso.substring(0, 19) : iso);
  return d;
}

/// "2 days", "5 hours", "12 min" between an ISO time and [now].
String waitedText(InboxStrings s, String? iso, DateTime now) {
  final t = _wallTime(iso);
  if (t == null) return '';
  final diff = now.difference(t);
  if (diff.inMinutes < 2) return s.justNow;
  if (diff.inHours < 1) return s.minutes(diff.inMinutes);
  if (diff.inDays < 1) return s.hours(diff.inHours);
  return s.days(diff.inDays);
}

/// "Thu 26 Nov, 19:00" from an ISO time (the wall time of the string, which
/// is already Cairo time), or "Thu 26 Nov" for a date.
String slotText(InboxStrings s, String? iso) {
  final t = _wallTime(iso);
  if (t == null) return '';
  final hasTime = iso!.length > 10;
  final day = '${s.weekdays[t.weekday - 1]} ${t.day} ${s.months[t.month - 1]}';
  if (!hasTime) return day;
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '$day, $hh:$mm';
}

/// Colour for a note level.
Color levelColor(NoteLevel level) => switch (level) {
  NoteLevel.stop => StudioColors.danger,
  NoteLevel.warn => StudioColors.warning,
  _ => StudioColors.border,
};

/// Small pill used for counts and tags.
class CountPill extends StatelessWidget {
  const CountPill(this.count, {super.key, this.color});
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? StudioColors.berryPink,
        borderRadius: BorderRadius.circular(StudioRadii.pill),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A "what happens next" line shown on cards so no status is a dead end.
class NextStepLine extends StatelessWidget {
  const NextStepLine(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.arrow_forward,
            size: 14,
            color: StudioColors.plumMuted,
          ),
        ),
        const SizedBox(width: StudioSpacing.xs),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
