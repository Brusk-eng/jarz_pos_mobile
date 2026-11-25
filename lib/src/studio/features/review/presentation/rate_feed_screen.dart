import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../../shared/how_this_works_sheet.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/verdict_badge.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../data/review_repository.dart';
import '../review_strings.dart';
import '../state/rate_feed_state.dart';
import 'review_helpers.dart';
import 'review_sheets.dart';

/// `/inbox/rate`: the versions waiting for my rating, one per page, swiped
/// vertically. The video plays muted on its own; one tap on a number rates it
/// and moves on.
class RateFeedScreen extends ConsumerStatefulWidget {
  const RateFeedScreen({super.key, this.parentRoute = '/inbox/approve'});

  final String parentRoute;

  @override
  ConsumerState<RateFeedScreen> createState() => _RateFeedScreenState();
}

class _RateFeedScreenState extends ConsumerState<RateFeedScreen> {
  late final ProviderContainer _container = ProviderScope.containerOf(
    context,
    listen: false,
  );

  @override
  void initState() {
    super.initState();
    Future(() {
      if (mounted) _container.read(rateFeedControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    // A new visit loads the list again, without what was rated.
    if (_container.read(rateFeedControllerProvider).rated.isNotEmpty) {
      _container.invalidate(toRateProvider);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ReviewStrings.of(context);
    final value = ref.watch(toRateProvider);
    return ViewEditScaffold(
      title: t.feedTitle,
      parentRoute: widget.parentRoute,
      actions: [
        IconButton(
          key: const ValueKey('review-help'),
          tooltip: t.feedHelpTitle,
          icon: const Icon(Icons.help_outline),
          onPressed: () => HowThisWorksSheet.show(
            context,
            title: t.feedHelpTitle,
            lines: t.feedHelp,
          ),
        ),
      ],
      body: StudioAsyncView<PagedState<RateCard>>(
        value: value,
        isEmpty: (s) => feedCards(s.items).isEmpty && !s.hasMore,
        empty: StudioEmptyConfig(
          purpose: t.feedEmptyPurpose,
          firstStep: t.feedEmptyFirstStep,
          icon: Icons.star_outline,
        ),
        onRetry: () => ref.invalidate(toRateProvider),
        builder: (context, s) => _Feed(
          cards: feedCards(s.items),
          hasMore: s.hasMore,
          loadingMore: s.loadingMore,
          parentRoute: widget.parentRoute,
        ),
      ),
    );
  }
}

class _Feed extends ConsumerStatefulWidget {
  const _Feed({
    required this.cards,
    required this.hasMore,
    required this.loadingMore,
    required this.parentRoute,
  });

  final List<RateCard> cards;
  final bool hasMore;
  final bool loadingMore;
  final String parentRoute;

  @override
  ConsumerState<_Feed> createState() => _FeedState();
}

class _FeedState extends ConsumerState<_Feed> {
  final PageController _pc = PageController();
  StudioVideoPool? _pool;
  int _index = 0;
  bool _muted = true;
  bool _loadFailed = false;

  /// A comment written before tapping a number: version id to text.
  final Map<String, String> _drafts = {};

  StudioVideoPool get pool => _pool ??= StudioVideoPool(
    factory: ref.read(studioVideoControllerFactoryProvider),
  );

  @override
  void dispose() {
    _pc.dispose();
    _pool?.dispose();
    super.dispose();
  }

  List<RateCard> get _cards => widget.cards;

  void _onPage(int i) {
    setState(() => _index = i);
    if (widget.hasMore && i >= _cards.length - 2) _loadMore();
  }

  Future<void> _loadMore() async {
    try {
      setState(() => _loadFailed = false);
      await ref.read(toRateProvider.notifier).loadMore();
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  void _next() {
    if (!_pc.hasClients) return;
    _pc.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _rate(RateCard card, int score) async {
    final id = rateCardId(card)!;
    final t = ReviewStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final at = _cards.indexOf(card);
    final comment = _drafts.remove(id);
    final future = ref
        .read(rateFeedControllerProvider.notifier)
        .rateCard(card, score, comment: comment);
    _next();
    final outcome = await future;
    if (!mounted || outcome.ok) return;
    // Taken back: say why and go back to that card.
    if (comment != null) _drafts[id] = comment;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${t.feedRollback(rateCardTitle(card))} ${failureText(context, outcome)}',
          ),
        ),
      );
    if (at >= 0 && _pc.hasClients) {
      _pc.animateToPage(
        at,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _addComment(RateCard card) async {
    final id = rateCardId(card)!;
    final t = ReviewStrings.of(context);
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _DraftCommentSheet(
        initial: _drafts[id] ?? '',
        title: t.feedAddComment,
        hint: t.rateCommentHint,
        save: t.save,
        cancel: t.cancel,
      ),
    );
    if (text == null) return;
    setState(() {
      if (text.trim().isEmpty) {
        _drafts.remove(id);
      } else {
        _drafts[id] = text.trim();
      }
    });
  }

  void _openDetails(RateCard card) {
    // Library items have no version page; their card has no Details link.
    final v = card.version;
    if (v != null) GoRouter.maybeOf(context)?.push('/versions/${v.id}');
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    final rated = ref.watch(rateFeedControllerProvider).rated;
    final t = ReviewStrings.of(context);
    return StudioVideoPoolScope(
      pool: pool,
      child: ColoredBox(
        color: Colors.black,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: PageView.builder(
              key: const ValueKey('rate-feed'),
              scrollDirection: Axis.vertical,
              controller: _pc,
              itemCount: cards.length + 1,
              onPageChanged: _onPage,
              itemBuilder: (context, i) {
                if (i >= cards.length) {
                  return _EndPage(
                    hasMore: widget.hasMore,
                    loading: widget.loadingMore,
                    failed: _loadFailed,
                    onRetry: _loadMore,
                    onBack: () {
                      final r = GoRouter.maybeOf(context);
                      if (r == null) {
                        Navigator.of(context).maybePop();
                      } else if (r.canPop()) {
                        r.pop();
                      } else {
                        r.go(widget.parentRoute);
                      }
                    },
                  );
                }
                final card = cards[i];
                final id = rateCardId(card)!;
                return _CardPage(
                  key: ValueKey('rate-card-$id'),
                  card: card,
                  active: i == _index,
                  near: (i - _index).abs() == 1,
                  muted: _muted,
                  position: t.feedPosition(
                    i + 1,
                    widget.hasMore ? null : cards.length,
                  ),
                  myScore: rated[id],
                  hasDraft: _drafts.containsKey(id),
                  onRate: (s) => _rate(card, s),
                  onSkip: _next,
                  onComment: () => _addComment(card),
                  onDetails: () => _openDetails(card),
                  onToggleMute: () => setState(() => _muted = !_muted),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CardPage extends StatelessWidget {
  const _CardPage({
    super.key,
    required this.card,
    required this.active,
    required this.near,
    required this.muted,
    required this.position,
    required this.myScore,
    required this.hasDraft,
    required this.onRate,
    required this.onSkip,
    required this.onComment,
    required this.onDetails,
    required this.onToggleMute,
  });

  final RateCard card;
  final bool active;
  final bool near;
  final bool muted;
  final String position;
  final int? myScore;
  final bool hasDraft;
  final ValueChanged<int> onRate;
  final VoidCallback onSkip;
  final VoidCallback onComment;
  final VoidCallback onDetails;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    final t = ReviewStrings.of(context);
    final v = card.version;
    final media = rateCardMedia(card);
    final first = media.isEmpty ? null : media.first;
    final verdict = v?.verdict == null ? null : uiVerdict(v!.verdict!.verdict);
    final rated = myScore != null;
    const onVideo = TextStyle(color: Colors.white);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (first == null)
          const SizedBox.shrink()
        else if (first.kind == MediaKind.video)
          StudioVideoPlayer(
            media: first,
            active: active,
            prefetch: near,
            autoplay: true,
            muted: muted,
            showControls: false,
          )
        else
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => openStudioMediaViewer(context, items: media),
            child: StudioThumb(
              media: first,
              fit: BoxFit.contain,
              radius: BorderRadius.zero,
            ),
          ),
        // Dark fades under the controls and behind the counter so the text
        // reads on any picture.
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 72,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC000000)],
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: StudioSpacing.sm,
          start: StudioSpacing.md,
          child: Text(
            position,
            key: const ValueKey('feed-position'),
            style: onVideo,
          ),
        ),
        if (first?.kind == MediaKind.video)
          PositionedDirectional(
            top: 0,
            end: StudioSpacing.xs,
            child: IconButton(
              key: const ValueKey('feed-mute'),
              tooltip: muted ? t.feedSoundOff : t.feedSoundOn,
              color: Colors.white,
              onPressed: onToggleMute,
              icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
            ),
          ),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                StudioSpacing.gutter,
                0,
                StudioSpacing.gutter,
                StudioSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rateCardTitle(card),
                          key: const ValueKey('feed-title'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                      if (verdict != null) ...[
                        const SizedBox(width: StudioSpacing.sm),
                        VerdictBadge(verdict: verdict),
                      ],
                    ],
                  ),
                  if ((v?.ratePrompt ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: StudioSpacing.xs),
                      child: Text(
                        v!.ratePrompt!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: onVideo.copyWith(fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: StudioSpacing.md),
                  if (rated)
                    Container(
                      key: const ValueKey('feed-rated'),
                      padding: const EdgeInsets.all(StudioSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(StudioRadii.sm),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: StudioSpacing.sm),
                          Expanded(
                            child: Text(
                              t.ratedSaved(myScore!, scoreText(t, myScore!)),
                              style: onVideo,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    ScorePicker(
                      selected: null,
                      onSelected: onRate,
                      dark: true,
                      compact: true,
                    ),
                    const SizedBox(height: StudioSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              key: const ValueKey('feed-comment'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              onPressed: onComment,
                              icon: Icon(
                                hasDraft
                                    ? Icons.chat_bubble
                                    : Icons.chat_bubble_outline,
                                size: 18,
                              ),
                              label: Text(
                                hasDraft
                                    ? t.feedCommentAdded
                                    : t.feedAddComment,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('feed-skip'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: onSkip,
                          child: Text(t.feedSkip),
                        ),
                      ],
                    ),
                  ],
                  if (v != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        key: const ValueKey('feed-details'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                        ),
                        onPressed: onDetails,
                        child: Text(t.feedDetails),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EndPage extends StatelessWidget {
  const _EndPage({
    required this.hasMore,
    required this.loading,
    required this.failed,
    required this.onRetry,
    required this.onBack,
  });

  final bool hasMore;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = ReviewStrings.of(context);
    if (hasMore) {
      return Center(
        child: failed
            ? TextButton(
                key: const ValueKey('feed-load-more-retry'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: onRetry,
                child: Text(t.feedLoadMoreFailed),
              )
            : const CircularProgressIndicator(color: Colors.white),
      );
    }
    return Center(
      key: const ValueKey('feed-end'),
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: StudioColors.blushPale,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: StudioColors.berryPink),
            ),
            const SizedBox(height: StudioSpacing.lg),
            Text(
              t.feedEndTitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: StudioSpacing.sm),
            Text(
              t.feedEndBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: StudioSpacing.lg),
            FilledButton(
              key: const ValueKey('feed-end-back'),
              onPressed: onBack,
              child: Text(t.feedBack),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftCommentSheet extends StatefulWidget {
  const _DraftCommentSheet({
    required this.initial,
    required this.title,
    required this.hint,
    required this.save,
    required this.cancel,
  });

  final String initial;
  final String title;
  final String hint;
  final String save;
  final String cancel;

  @override
  State<_DraftCommentSheet> createState() => _DraftCommentSheetState();
}

class _DraftCommentSheetState extends State<_DraftCommentSheet> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.gutter,
            0,
            StudioSpacing.gutter,
            StudioSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: StudioSpacing.md),
              TextField(
                key: const ValueKey('feed-comment-field'),
                controller: _c,
                autofocus: true,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(hintText: widget.hint),
              ),
              const SizedBox(height: StudioSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(widget.cancel),
                    ),
                  ),
                  const SizedBox(width: StudioSpacing.md),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('feed-comment-save'),
                      onPressed: () => Navigator.of(context).pop(_c.text),
                      child: Text(widget.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
