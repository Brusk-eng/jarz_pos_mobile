import 'package:flutter/material.dart';

import '../core/theme/studio_tokens.dart';

/// One post can go to two platforms (Instagram and TikTok). The server sends
/// `platforms` and `platform_status`; an older server sends neither, and then
/// everything below answers as it did before (empty list, no marks).
const platformInstagram = 'Instagram';
const platformTikTok = 'TikTok';

/// The platforms a post goes to, never null.
List<String> platformsOf(List<String>? platforms) => platforms ?? const [];

/// True when the post carries the TikTok part as well as Instagram.
bool hasTikTokPart(List<String>? platforms) {
  final list = platformsOf(platforms);
  return list.contains(platformTikTok) && list.length > 1;
}

/// The state of one platform: planned | posted | by hand | failed. A platform
/// the server did not give a state for counts as planned.
String platformState(Map<String, String>? status, String platform) =>
    status?[platform] ?? 'planned';

Color platformStateColor(String state) => switch (state) {
  'posted' => StudioColors.success,
  'by hand' => StudioColors.warning,
  'failed' => StudioColors.danger,
  _ => StudioColors.plumMuted,
};

/// The state in words, per platform.
String platformStateWords(String platform, String state, {required bool ar}) {
  final word = ar
      ? switch (state) {
          'posted' => 'اتنشر',
          'by hand' => 'هتتنشر بإيد حد من الفريق',
          'failed' => 'فشل النشر',
          _ => 'متجدول',
        }
      : switch (state) {
          'posted' => 'posted',
          'by hand' => 'posted by hand',
          'failed' => 'failed',
          _ => 'planned',
        };
  return '$platform: $word';
}

/// Two small platform marks (IG, TikTok) on one item, each coloured by its
/// state. A tap shows each platform's state in words. Draws nothing when the
/// server gave no platforms.
class PlatformMarks extends StatelessWidget {
  const PlatformMarks({
    super.key,
    required this.platforms,
    required this.status,
    required this.ar,
  });

  final List<String>? platforms;
  final Map<String, String>? status;
  final bool ar;

  static String _short(String p) => p == platformInstagram ? 'IG' : p;

  @override
  Widget build(BuildContext context) {
    final list = platformsOf(platforms);
    if (list.isEmpty) return const SizedBox.shrink();
    final words = [
      for (final p in list)
        platformStateWords(p, platformState(status, p), ar: ar),
    ];
    return Semantics(
      label: words.join(', '),
      child: GestureDetector(
        key: const ValueKey('platform-marks'),
        behavior: HitTestBehavior.opaque,
        onTap: () => ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                words.join('\n'),
                key: const ValueKey('platform-marks-words'),
              ),
              duration: const Duration(seconds: 4),
            ),
          ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in list)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: StudioSpacing.xs,
                ),
                child: _Mark(
                  label: _short(p),
                  platform: p,
                  state: platformState(status, p),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({
    required this.label,
    required this.platform,
    required this.state,
  });

  final String label;
  final String platform;
  final String state;

  @override
  Widget build(BuildContext context) {
    final color = platformStateColor(state);
    return Container(
      key: ValueKey('mark-$platform-$state'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(StudioRadii.pill),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
