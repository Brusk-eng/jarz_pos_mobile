import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/user_error_message.dart';
import '../../../core/network/user_service.dart';
import '../../../core/widgets/app_drawer.dart';
import '../data/recipe_book_models.dart';
import '../domain/recipe_list_logic.dart';
import '../domain/recipe_scaling.dart';
import '../domain/recipe_targets.dart';
import '../state/recipe_book_providers.dart';
import 'recipe_book_strings.dart';
import 'recipe_detail_screen.dart';
import 'recipe_editor_screen.dart';
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

  /// Opens a blank editor (Jars preselected on the Jars chip); a saved recipe
  /// is then opened.
  Future<void> _newRecipe(RecipeFilter filter) async {
    final saved = await Navigator.of(context).push(
      RecipeEditorScreen.route(
        initialCategory: filter == RecipeFilter.jars
            ? RecipeCategory.jars
            : null,
      ),
    );
    if (!mounted || saved == null || saved.name.isEmpty) return;
    Navigator.of(
      context,
    ).push(RecipeDetailScreen.route(saved.name, title: saved.title));
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

    final canEdit = index.valueOrNull?.canEdit ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(s.title)),
      drawer: drawer,
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              key: const ValueKey('recipe-new'),
              onPressed: () => _newRecipe(filter),
              icon: const Icon(Icons.add),
              label: Text(s.newRecipe),
            )
          : null,
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
    final sections = buildRecipeSections(
      data.recipes,
      query: query,
      filter: filter,
    );
    if (sections.isEmpty) {
      return _scrollable(
        RecipeBookMessage(
          icon: Icons.search_off,
          title: s.noMatch,
          actionLabel: s.clearFilters,
          onAction: _clearSearch,
        ),
      );
    }
    // A single category chip already names the section; headers only help
    // when rows from several categories share the screen.
    final showHeaders =
        filter == RecipeFilter.all || filter == RecipeFilter.trials;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          for (final section in sections) ...[
            if (showHeaders)
              _SectionHeader(label: s.category(section.category))
            else
              const SizedBox(height: 8),
            for (final entry in section.entries)
              switch (entry) {
                RecipeRowEntry(:final recipe) => _RecipeRow(
                  recipe: recipe,
                  onTap: () {
                    final target = recipeTargetFor(recipe);
                    if (target == null) return;
                    Navigator.of(context).push(
                      RecipeDetailScreen.route(target, title: recipe.title),
                    );
                  },
                ),
                RecipeFamilyEntry() => _FamilyRow(
                  entry: entry,
                  onTap: () => Navigator.of(context).push(
                    RecipeDetailScreen.route(
                      recipeTargetJar(entry.family),
                      title: entry.family,
                    ),
                  ),
                ),
              },
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
      RecipeFilter.bases: s.chipBases,
      RecipeFilter.fillings: s.chipFillings,
      RecipeFilter.jars: s.filterJars,
      RecipeFilter.trials: s.filterTrials,
    };
    return SizedBox(
      height: 48,
      child: ListView(
        key: const ValueKey('recipe-filter-chips'),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

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

/// The pill on a row: "Trial" for a recipe that is one, "Trial running" when
/// a trial sits alongside an approved version. Approved needs no pill.
class _TrialPill extends StatelessWidget {
  const _TrialPill({required this.running});

  final bool running;

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    return RecipeStatusPill(
      status: RecipeStatus.trial,
      label: running ? s.trialRunning : s.trialPill,
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.pill,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? pill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    sentenceCase(title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (pill != null) ...[const SizedBox(width: 12), pill!],
          ],
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
    final s = RecipeBookStrings.of(context);
    final headline = recipe.headlineVersion;
    return _ListRow(
      title: recipe.title,
      subtitle: headline != null
          ? recipeVersionLine(context, headline)
          : s.ingredientsOnly,
      onTap: onTap,
      pill: recipe.isTrialish
          ? _TrialPill(running: recipe.status != RecipeStatus.trial)
          : null,
    );
  }
}

/// A jar flavour: one row, its sizes as the subtitle.
class _FamilyRow extends StatelessWidget {
  const _FamilyRow({required this.entry, required this.onTap});

  final RecipeFamilyEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final allTrial = entry.members.every((m) => m.status == RecipeStatus.trial);
    return _ListRow(
      title: entry.family,
      subtitle: entry.sizes.map(s.size).join(' · '),
      onTap: onTap,
      pill: entry.isTrialish ? _TrialPill(running: !allTrial) : null,
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
