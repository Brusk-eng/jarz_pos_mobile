import 'package:flutter/material.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../review_strings.dart';
import 'review_helpers.dart';

/// The media of one version: a video with controls, a picture or a carousel
/// of pictures (one per language), or a story as a strip of frames with the
/// selected frame shown large. Tapping a picture opens the full-screen viewer.
class VersionMediaView extends StatefulWidget {
  const VersionMediaView({
    super.key,
    required this.version,
    this.selectedFrame,
    this.onFrameSelected,
  });

  final PieceVersion version;

  /// Story: the position of the frame shown large (null = the first).
  final int? selectedFrame;
  final ValueChanged<int>? onFrameSelected;

  @override
  State<VersionMediaView> createState() => _VersionMediaViewState();
}

class _VersionMediaViewState extends State<VersionMediaView> {
  final PageController _pc = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  double _ratio(StudioMedia m) =>
      (m.width != null && m.height != null && m.height! > 0)
      ? m.width! / m.height!
      : 4 / 5;

  @override
  Widget build(BuildContext context) {
    final t = ReviewStrings.of(context);
    final v = widget.version;
    final media = versionMedia(v);
    if (media.isEmpty) {
      return Container(
        key: const ValueKey('no-media'),
        height: 160,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(StudioSpacing.lg),
        decoration: BoxDecoration(
          color: StudioColors.blushPale,
          borderRadius: BorderRadius.circular(StudioRadii.md),
        ),
        child: Text(t.noMedia, textAlign: TextAlign.center),
      );
    }
    if (v.frames.isNotEmpty) return _story(context, t, v, media);
    if (media.length == 1) return _single(context, t, media.first, 0, media);
    return _carousel(context, t, v, media);
  }

  /// A box that never grows taller than the screen allows.
  Widget _frame(BuildContext context, double ratio, Widget child) {
    final maxH = (MediaQuery.sizeOf(context).height * 0.6).clamp(280.0, 560.0);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: AspectRatio(
          aspectRatio: ratio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(StudioRadii.md),
            child: ColoredBox(color: Colors.black, child: child),
          ),
        ),
      ),
    );
  }

  Widget _single(
    BuildContext context,
    ReviewStrings t,
    StudioMedia m,
    int index,
    List<StudioMedia> all,
  ) {
    if (m.kind == MediaKind.video) {
      return _frame(
        context,
        _ratio(m),
        StudioVideoPlayer(
          key: ValueKey('player-${m.id}'),
          media: m,
          muted: false,
        ),
      );
    }
    return _frame(
      context,
      _ratio(m),
      Stack(
        fit: StackFit.expand,
        children: [
          StudioThumb(
            key: ValueKey('picture-${m.id}'),
            media: m,
            fit: BoxFit.contain,
            radius: BorderRadius.zero,
          ),
          Positioned.fill(
            child: Semantics(
              button: true,
              label: t.openFullScreen,
              child: GestureDetector(
                key: ValueKey('open-${m.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => openStudioMediaViewer(
                  context,
                  items: all,
                  initialIndex: index,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carousel(
    BuildContext context,
    ReviewStrings t,
    PieceVersion v,
    List<StudioMedia> media,
  ) {
    final files = [...v.files]..sort((a, b) => a.position - b.position);
    final ratio = _ratio(media.first);
    return Column(
      children: [
        _frame(
          context,
          ratio,
          PageView.builder(
            key: const ValueKey('media-pages'),
            controller: _pc,
            itemCount: media.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Stack(
              fit: StackFit.expand,
              children: [
                media[i].kind == MediaKind.video
                    ? StudioVideoPlayer(media: media[i], active: i == _page)
                    : StudioThumb(
                        media: media[i],
                        fit: BoxFit.contain,
                        radius: BorderRadius.zero,
                      ),
                if (media[i].kind != MediaKind.video)
                  Positioned.fill(
                    child: GestureDetector(
                      key: ValueKey('open-${media[i].id}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => openStudioMediaViewer(
                        context,
                        items: media,
                        initialIndex: i,
                      ),
                    ),
                  ),
                if (i < files.length && files[i].lang != null)
                  PositionedDirectional(
                    start: StudioSpacing.sm,
                    top: StudioSpacing.sm,
                    child: _LangTag(
                      text: switch (files[i].lang) {
                        StudioLang.ar => t.langAr,
                        StudioLang.en => t.langEn,
                        _ => '',
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: StudioSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < media.length; i++)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page
                      ? StudioColors.berryPink
                      : StudioColors.border,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _story(
    BuildContext context,
    ReviewStrings t,
    PieceVersion v,
    List<StudioMedia> media,
  ) {
    final frames = [...v.frames]..sort((a, b) => a.position - b.position);
    final shown = frames.firstWhere(
      (f) => f.position == widget.selectedFrame,
      orElse: () => frames.first,
    );
    final shownMedia = shown.asset.media;
    final shownIndex = shownMedia == null ? 0 : media.indexOf(shownMedia);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shownMedia != null)
          _single(
            context,
            t,
            shownMedia,
            shownIndex < 0 ? 0 : shownIndex,
            media,
          ),
        const SizedBox(height: StudioSpacing.md),
        Text(t.storyFrames, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: StudioSpacing.sm),
        SizedBox(
          height: 112,
          child: ListView.separated(
            key: const ValueKey('frame-strip'),
            scrollDirection: Axis.horizontal,
            itemCount: frames.length,
            separatorBuilder: (_, _) => const SizedBox(width: StudioSpacing.sm),
            itemBuilder: (_, i) {
              final f = frames[i];
              final selected = f.position == shown.position;
              return GestureDetector(
                key: ValueKey('frame-${f.position}'),
                onTap: () => widget.onFrameSelected?.call(f.position),
                child: Container(
                  width: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(StudioRadii.sm + 2),
                    border: Border.all(
                      color: selected
                          ? StudioColors.berryPink
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      StudioThumb(media: f.asset.media),
                      PositionedDirectional(
                        start: 4,
                        top: 4,
                        child: _LangTag(text: t.frameLabel(f.position)),
                      ),
                      if (f.status != null && f.status != FrameStatus.unknown)
                        PositionedDirectional(
                          start: 4,
                          bottom: 4,
                          child: _LangTag(
                            text: f.status == FrameStatus.posted
                                ? t.framePosted
                                : t.frameSkipped,
                          ),
                        ),
                      if (f.commentsCount > 0)
                        PositionedDirectional(
                          end: 4,
                          top: 4,
                          child: _LangTag(text: '${f.commentsCount}'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LangTag extends StatelessWidget {
  const _LangTag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: const Color(0xB3000000),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 11),
    ),
  );
}
