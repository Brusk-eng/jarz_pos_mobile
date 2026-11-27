import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/user_error_message.dart';
import '../../../core/network/user_service.dart';
import '../../../core/widgets/app_drawer.dart';
import '../data/recipe_book_models.dart';
import '../domain/recipe_scaling.dart';
import '../state/recipe_book_providers.dart';
import 'recipe_book_strings.dart';
import 'recipe_detail_screen.dart';
import 'widgets/recipe_book_common.dart';

/// Every recipe and its SOP: approved, previous and trial versions.
///
/// Reachable two ways: the `/recipes` route (drawer, deep link; [showDrawer]
/// true) and a plain [route] pushed from the Production Board's app bar, so
/// the feature itself never depends on a router entry.
class RecipeBookListScreen extends ConsumerStatefulWidget {
  const RecipeBookListScreen({super.key, this.showDrawer = false});

  /// True when this is a top-level destination with nothing to go back to.
  final bool showDrawer;

  static Route<void> route({bool showDrawer = false}) =>
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/recipes'),
        builder: (_) => RecipeBookListScreen(showDrawer: showDrawer),
      );

  @override
  ConsumerState<RecipeBookListScreen> createState() =>
      _RecipeBookListScreenState();
}

class _RecipeBookListScreenState extends ConsumerState<RecipeBookListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() => ref.refresh(recipeBookIndexProvider.future);

  void _clearSearch() {
    _searchController.clear();
    ref.read(recipeBookQueryProvider.notifier).state = '';
    ref.read(recipeBookFilterProvider.notifier).state = RecipeFilter.all;
  }

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final allowed = ref.watch(canAccessProductionBoardProvider);
    final drawer = widget.showDrawer ? const AppDrawer() : null;
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: Text(s.title)),
        drawer: drawer,
        body: Center(
          child: RecipeBookMessage(
            icon: Icons.lock_outline,
            title: s.accessDenied,
          ),
        ),
      );
    }

    final index = ref.watch(recipeBookIndexProvider);
    final query = ref.watch(recipeBookQueryProvider);
    final filter = ref.watch(recipeBookFilterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.title)),
      drawer: drawer,
      body: RecipeBookWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: s.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).deleteButtonTooltip,
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(recipeBookQueryProvider.notifier).state =
                                '';
                          },
                        ),
                  isDense: true,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) =>
                    ref.read(recipeBookQueryProvider.notifier).state = value,
              ),
            ),
            _FilterChips(
              selected: filter,
              onSelected: (f) =>
                  ref.read(recipeBookFilterProvider.notifier).state = f,
            ),
            Expanded(
              child: index.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                loading: () => const _ListSkeleton(),
                error: (error, _) => _scrollable(
                  RecipeBookMessage(
                    icon: Icons.cloud_off_outlined,
                    title: s.loadFailed,
                    body: context.userErrorMessage(error),
                    actionLabel: s.retry,
                    onAction: () => ref.invalidate(recipeBookIndexProvider),
                  ),
                ),
                data: (data) => _buildList(context, data, query, filter),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wraps a message so pull to refresh still works on it.
  Widget _scrollable(Widget child) => RefreshIndicator(
    onRefresh: _refresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [child],
    ),
  );

  Widget _buildList(
    BuildContext context,
    RecipeBookIndex data,
    String query,
    RecipeFilter filter,
  ) {
    final s = RecipeBookStrings.of(context);
    if (data.recipes.isEmpty) {
      return _scrollable(
        RecipeBookMessage(
          icon: Icons.menu_book_outlined,
          title: s.emptyTitle,
          body: s.emptyBody,
        ),
      );
    }
    final visible = filterRecipes(data.recipes, query: query, filter: filter);
    if (visible.isEmpty) {
      return _scrollable(
        RecipeBookMessage(
          icon: Icons.search_off,
          title: s.noMatch,
          actionLabel: s.clearFilters,
          onAction: _clearSearch,
        ),
      );
    }
    final groups = groupRecipesByTrack(visible, data.tracks);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final group in groups) ...[
            _TrackHeader(label: s.track(group.track)),
            for (final recipe in group.recipes)
              _RecipeRow(
                recipe: recipe,
                onTap: () {
                  final sop = recipe.openSop;
                  if (sop.isEmpty) return;
                  Navigator.of(
                    context,
                  ).push(RecipeDetailScreen.route(sop, title: recipe.title));
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final RecipeFilter selected;
  final ValueChanged<RecipeFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final labels = {
      RecipeFilter.all: s.filterAll,
      RecipeFilter.approved: s.filterApproved,
      RecipeFilter.trials: s.filterTrials,
    };
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          for (final entry in labels.entries)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: selected == entry.key,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onSelected(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrackHeader extends StatelessWidget {
  const _TrackHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecipeRow extends StatelessWidget {
  const _RecipeRow({required this.recipe, required this.onTap});

  final RecipeSummary recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = RecipeBookStrings.of(context);
    final headline = recipe.headlineVersion;
    final quiet = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final trialColor = recipeStatusColors(
      context,
      RecipeStatus.trial,
    ).foreground;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (headline != null) ...[
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: recipeVersionLine(context, headline)),
                          if (recipe.hasTrial)
                            TextSpan(
                              text: ' · ${s.trialInProgress}',
                              style: TextStyle(color: trialColor),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: quiet,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            RecipeStatusPill(status: recipe.status),
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      children: [
        const RecipeSkeletonBar(width: 90, height: 10),
        const SizedBox(height: 14),
        for (var i = 0; i < 7; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RecipeSkeletonBar(width: 120.0 + (i % 3) * 40),
                      const SizedBox(height: 8),
                      const RecipeSkeletonBar(width: 110, height: 9),
                    ],
                  ),
                ),
                const RecipeSkeletonBar(width: 56, height: 18),
              ],
            ),
          ),
      ],
    );
  }
}
