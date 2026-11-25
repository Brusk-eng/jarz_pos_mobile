import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/person_text.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../shoots_strings.dart';
import '../state/on_set_state.dart';
import '../state/shoot_list_state.dart';
import 'shoot_widgets.dart';

/// `/shoots`: upcoming and past shoots. Opening it also downloads the shoots
/// to the phone so On set works with no connection.
class ShootsListScreen extends ConsumerStatefulWidget {
  const ShootsListScreen({super.key});

  @override
  ConsumerState<ShootsListScreen> createState() => _ShootsListScreenState();
}

class _ShootsListScreenState extends ConsumerState<ShootsListScreen> {
  @override
  void initState() {
    super.initState();
    Future(() {
      if (mounted) ref.read(onSetProvider.notifier).syncAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ShootStrings.of(context);
    final st = StudioStrings.of(context);
    final value = ref.watch(shootListProvider);
    final canPlan = ref.watch(canPlanShootsProvider);
    final now = ref.watch(shootNowProvider);

    return DefaultTabController(
      length: 2,
      child: Stack(
        children: [
          ViewEditScaffold(
            title: st.screen(StudioScreen.shoots).title,
            screen: StudioScreen.shoots,
            parentRoute: '/more',
            bottom: TabBar(
              tabs: [
                Tab(key: const ValueKey('tab-upcoming'), text: t.tabUpcoming),
                Tab(key: const ValueKey('tab-past'), text: t.tabPast),
              ],
            ),
            body: Column(
              children: [
                const SyncBanner(),
                Expanded(
                  child: StudioAsyncView<PagedStateOf>(
                    value: value.whenData(
                      (p) => PagedStateOf(p.items, p.hasMore, p.loadingMore),
                    ),
                    onRetry: () => ref.invalidate(shootListProvider),
                    isEmpty: (_) => false,
                    empty: StudioEmptyConfig(
                      purpose: t.emptyUpcomingPurpose,
                      firstStep: t.emptyUpcomingFirst,
                    ),
                    builder: (context, data) {
                      final parts = splitShoots(data.items, now);
                      return TabBarView(
                        children: [
                          _ShootTab(
                            key: const ValueKey('list-upcoming'),
                            shoots: parts.upcoming,
                            hasMore: data.hasMore,
                            empty: StudioEmptyConfig(
                              purpose: t.emptyUpcomingPurpose,
                              firstStep: t.emptyUpcomingFirst,
                              icon: Icons.videocam_outlined,
                              actionLabel: canPlan ? t.planShoot : null,
                              onAction: canPlan
                                  ? () => context.push('/shoots/new')
                                  : null,
                            ),
                          ),
                          _ShootTab(
                            key: const ValueKey('list-past'),
                            shoots: parts.past,
                            hasMore: data.hasMore,
                            empty: StudioEmptyConfig(
                              purpose: t.emptyPastPurpose,
                              firstStep: t.emptyPastFirst,
                              icon: Icons.history,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (canPlan)
            PositionedDirectional(
              end: StudioSpacing.gutter,
              bottom: StudioSpacing.gutter,
              child: FloatingActionButton.extended(
                key: const ValueKey('plan-shoot'),
                onPressed: () => context.push('/shoots/new'),
                icon: const Icon(Icons.add),
                label: Text(t.planShoot),
              ),
            ),
        ],
      ),
    );
  }
}

/// The loaded part of the list, as the view needs it.
class PagedStateOf {
  const PagedStateOf(this.items, this.hasMore, this.loadingMore);
  final List<ShootSummary> items;
  final bool hasMore;
  final bool loadingMore;
}

class _ShootTab extends ConsumerWidget {
  const _ShootTab({
    super.key,
    required this.shoots,
    required this.hasMore,
    required this.empty,
  });

  final List<ShootSummary> shoots;
  final bool hasMore;
  final StudioEmptyConfig empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ShootStrings.of(context);
    if (shoots.isEmpty && !hasMore) return StudioEmptyState(config: empty);
    return RefreshIndicator(
      onRefresh: () => ref.read(shootListProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          StudioSpacing.gutter,
          StudioSpacing.md,
          StudioSpacing.gutter,
          96,
        ),
        children: [
          for (final s in shoots)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ShootCard(shoot: s),
              ),
            ),
          if (hasMore)
            Center(
              child: TextButton(
                key: const ValueKey('load-more'),
                onPressed: () =>
                    ref.read(shootListProvider.notifier).loadMore(),
                child: Text(t.loadMore),
              ),
            ),
        ],
      ),
    );
  }
}

class ShootCard extends StatelessWidget {
  const ShootCard({super.key, required this.shoot});
  final ShootSummary shoot;

  @override
  Widget build(BuildContext context) {
    final t = ShootStrings.of(context);
    final theme = Theme.of(context);
    final when = shoot.shootDate == null
        ? t.noDateYet
        : t.dateLabel(shoot.shootDate, shoot.shootTime);
    return Card(
      key: ValueKey('shoot-${shoot.id}'),
      margin: const EdgeInsets.only(bottom: StudioSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(StudioRadii.md),
        onTap: () => context.push('/shoots/${shoot.id}'),
        child: Padding(
          padding: const EdgeInsets.all(StudioSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: PersonText(
                      shoot.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: StudioSpacing.sm),
                  ShootStatusPill(status: shoot.status),
                ],
              ),
              const SizedBox(height: StudioSpacing.xs),
              Text(
                [when, if (shoot.place != null) shoot.place!].join(' · '),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: StudioSpacing.md),
              Wrap(
                spacing: StudioSpacing.lg,
                runSpacing: StudioSpacing.xs,
                children: [
                  Text(
                    t.shotsOf(shoot.nDone, shoot.nShots),
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (shoot.prepTotal > 0)
                    Text(
                      t.prepOf(shoot.prepDone, shoot.prepTotal),
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (shoot.nPieces > 0)
                    Text(
                      t.piecesCount(shoot.nPieces),
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
              for (final need in shoot.needs.take(2))
                Padding(
                  padding: const EdgeInsets.only(top: StudioSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: StudioColors.warning,
                      ),
                      const SizedBox(width: StudioSpacing.xs),
                      Expanded(
                        child: Text(need, style: theme.textTheme.bodySmall),
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
