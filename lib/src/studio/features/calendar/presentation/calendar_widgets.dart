import '../../../shared/person_name.dart';
import 'package:flutter/material.dart';
import '../../../shared/person_text.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_status_colors.dart' as theme;
import '../../../core/theme/studio_theme.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../pieces/pieces_strings.dart';
import '../../pieces/presentation/piece_widgets.dart';
import '../state/cairo_format.dart';
import '../state/cairo_time.dart';

/// A small icon per channel. The channel name is always written next to it.
IconData channelIcon(PostChannel? c) => switch (c) {
  PostChannel.feedReel => Icons.movie_outlined,
  PostChannel.trialReel => Icons.science_outlined,
  PostChannel.trialReelFeed => Icons.fast_forward_outlined,
  PostChannel.feedStatic => Icons.image_outlined,
  PostChannel.feedCarousel => Icons.view_carousel_outlined,
  PostChannel.tikTok => Icons.music_note_outlined,
  PostChannel.story => Icons.auto_stories_outlined,
  _ => Icons.event_outlined,
};

/// The status of a post as a coloured pill with its plain word.
class PostStatusChip extends StatelessWidget {
  const PostStatusChip({super.key, required this.status});

  final PostStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = theme.postStatusColors[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StudioSpacing.md,
        vertical: StudioSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(StudioRadii.pill),
      ),
      child: Text(
        PiecesStrings.of(context).postStatus(status),
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: colors.foreground),
      ),
    );
  }
}

/// One post in a day: channel icon, time, thumbnail, title, status and what it
/// waits on. Tapping opens the post.
class PostTile extends StatelessWidget {
  const PostTile({super.key, required this.post, this.showDate = false});

  final PostSummary post;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    final textTheme = Theme.of(context).textTheme;
    final when = CairoTime.parse(post.slotTime);
    final ar = isArabic(context);
    final stop = post.level == NoteLevel.stop;
    return Card(
      margin: const EdgeInsets.only(bottom: StudioSpacing.sm),
      child: InkWell(
        key: ValueKey('post-tile-${post.id}'),
        borderRadius: BorderRadius.circular(StudioRadii.md),
        onTap: () => context.push('/calendar/post/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.all(StudioSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudioThumb(
                media: post.thumb,
                width: 44,
                height: 56,
                radius: BorderRadius.circular(StudioRadii.sm),
              ),
              const SizedBox(width: StudioSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          channelIcon(post.channel),
                          size: 16,
                          color: StudioColors.plumMuted,
                        ),
                        const SizedBox(width: StudioSpacing.xs),
                        Flexible(
                          child: Text(
                            [
                              if (post.channel != null)
                                s.channel(post.channel!),
                              if (when != null) CairoTime.time(when),
                            ].where((x) => x.isNotEmpty).join(' · '),
                            style: StudioTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: StudioSpacing.xxs),
                    PersonText(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: StudioSpacing.xs),
                    Wrap(
                      spacing: StudioSpacing.sm,
                      runSpacing: StudioSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PostStatusChip(status: post.status),
                        if (showDate && when != null)
                          Text(
                            CairoFormat.dayMonth(when, ar),
                            style: StudioTextStyles.caption,
                          ),
                      ],
                    ),
                    if (post.waitsOn != null && post.waitsOn!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: StudioSpacing.xs),
                        child: Text(
                          s.waitingOn(personName(post.waitsOn)),
                          style: textTheme.bodySmall?.copyWith(
                            color: stop
                                ? StudioColors.danger
                                : StudioColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
