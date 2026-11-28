import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/user_error_message.dart';
import '../../../core/network/user_service.dart';
import '../data/recipe_book_models.dart';
import '../data/recipe_book_service.dart';
import '../domain/recipe_edit_logic.dart';
import '../domain/recipe_scaling.dart';
import '../domain/recipe_targets.dart';
import '../state/recipe_book_providers.dart';
import 'recipe_book_list_screen.dart';
import 'recipe_editor_screen.dart';
import 'recipe_jar_family_screen.dart';
import 'recipe_book_strings.dart';
import 'widgets/recipe_book_common.dart';
import 'widgets/recipe_edit_widgets.dart';
import 'widgets/recipe_content_widgets.dart';
import 'widgets/recipe_scale_widgets.dart';

enum _RecipeTab { ingredients, method, notes }

/// What the `/recipes/:sop` route builds. [sop] is the route parameter: a SOP
/// name, `item:<item_code>` for a recipe with no SOP, or `jar:<family>` for a
/// jar family; this screen sends each to the screen that shows it.
///
/// The router entry is unchanged: the single parameter carries the target.
class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.sop, this.title});

  final String sop;

  /// Shown in the app bar while the recipe loads.
  final String? title;

  static Route<void> route(String sop, {String? title}) =>
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/recipes/$sop'),
        builder: (_) => RecipeDetailScreen(sop: sop, title: title),
      );

  @override
  Widget build(BuildContext context) {
    final target = normalizeRecipeTarget(sop);
    final family = jarFamilyOfTarget(target);
    if (family != null) {
      return RecipeJarFamilyScreen(family: family, title: title);
    }
    return _RecipeScreen(target: target, title: title);
  }
}

/// One recipe: header, a sticky scale bar, then Ingredients | Method | Notes.
///
/// [target] is the version opened first (a SOP name, or `item:<code>` for a
/// BOM-only recipe); the version sheet switches in place. The factor is kept
/// per recipe key (not per version) for the app session.
class _RecipeScreen extends ConsumerStatefulWidget {
  const _RecipeScreen({required this.target, this.title});

  final String target;
  final String? title;

  @override
  ConsumerState<_RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<_RecipeScreen> {
  late String _sop = widget.target;
  _RecipeTab _tab = _RecipeTab.ingredients;

  /// The last recipe shown, kept on screen while another version loads.
  RecipeDetail? _last;

  /// The provider behind [target]: by item for `item:<code>`, else by SOP.
  FutureProvider<RecipeDetail> _provider(String target) {
    final item = itemOfTarget(target);
    return item != null
        ? recipeByItemProvider(item)
        : recipeDetailProvider(target);
  }

  Future<void> _refresh() => ref.refresh(_provider(_sop).future);

  Future<void> _pickVersion(RecipeDetail detail) async {
    final picked = await showRecipeVersionsSheet(
      context,
      versions: detail.versions,
      selected: detail.name,
    );
    if (!mounted || picked == null || picked == _sop) return;
    setState(() => _sop = picked);
  }

  Future<void> _scaleByIngredient(
    RecipeDetail detail,
    RecipeIngredient ingredient,
    double factor,
  ) async {
    if (ingredient.amount <= 0) return;
    final s = RecipeBookStrings.of(context);
    final picked = await showRecipeScaleSheet(
      context,
      title: s.howMuch(ingredient.name),
      unit: ingredient.unit,
      baseAmount: ingredient.amount,
      currentFactor: factor,
      batchYield: detail.batchYield,
    );
    if (!mounted || picked == null) return;
    setRecipeScale(ref, detail.key, picked);
  }

  Future<void> _scaleByBatch(RecipeDetail detail, double factor) async {
    final amount = detail.batchYield.amount;
    if (amount == null || amount <= 0) return;
    final s = RecipeBookStrings.of(context);
    final picked = await showRecipeScaleSheet(
      context,
      title: s.batchSizeTitle,
      unit: detail.batchYield.unit,
      baseAmount: amount,
      currentFactor: factor,
      batchYield: detail.batchYield,
    );
    if (!mounted || picked == null) return;
    setRecipeScale(ref, detail.key, picked);
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Opens the editor; a saved version becomes the one shown.
  Future<void> _openEditor(
    RecipeDetail detail, {
    bool newVersion = false,
  }) async {
    final item = itemOfTarget(_sop) ?? detail.itemCode;
    final saved = await Navigator.of(context).push(
      detail.isBomOnly
          ? RecipeEditorScreen.route(itemCode: item)
          : RecipeEditorScreen.route(sop: detail.name, newVersion: newVersion),
    );
    if (!mounted || saved == null) return;
    if (saved.name.isNotEmpty && saved.name != _sop) {
      setState(() => _sop = saved.name);
    }
    _snack(RecipeBookStrings.of(context).saved);
  }

  /// The version currently on the Production Board, other than [detail].
  int? _replacedVersion(RecipeDetail detail) {
    for (final v in detail.versions) {
      if (v.status == VersionStatus.current && v.name != detail.name) {
        return v.version;
      }
    }
    return null;
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final s = RecipeBookStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  /// The server refuses an approval when a trial has its own amounts but the
  /// item has a BOM, and says so; that one can be retried with the BOM.
  bool _isBomRefusal(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('bom') && text.contains('approve');
  }

  Future<void> _changeStage(RecipeDetail detail, String stage) async {
    final s = RecipeBookStrings.of(context);
    final service = ref.read(recipeBookServiceProvider);
    final v = detail.version;
    final (title, body, action) = switch (stage) {
      RecipeStage.approved => (
        s.approve,
        s.approveBody(
          v,
          replacing: _replacedVersion(detail),
          hasItem: detail.itemCode != null,
        ),
        s.approve,
      ),
      RecipeStage.retired => (s.retire, s.retireBody(v), s.retire),
      _ => (s.backToTrial, s.backToTrialBody(v), s.backToTrial),
    };
    if (!await _confirm(title, body, action) || !mounted) return;
    var useBom = false;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await service.setRecipeStage(detail.name, stage, useBom: useBom);
        invalidateRecipeBook(ref);
        if (mounted) _snack(s.stageChanged);
        return;
      } catch (error) {
        if (!mounted) return;
        final message = recipeErrorText(context, error);
        if (stage == RecipeStage.approved && !useBom && _isBomRefusal(error)) {
          if (!await _confirm(title, message, s.approveWithBom) || !mounted) {
            return;
          }
          useBom = true;
          continue;
        }
        _snack(message);
        return;
      }
    }
  }

  List<Widget> _editActions(RecipeDetail? detail) {
    if (detail == null || !detail.canEdit) return const [];
    final s = RecipeBookStrings.of(context);
    final stage = detail.stage;
    final bomOnly = detail.isBomOnly;
    return [
      IconButton(
        key: const ValueKey('recipe-edit'),
        tooltip: bomOnly ? s.writeMethod : s.edit,
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => _openEditor(detail),
      ),
      if (!bomOnly)
        PopupMenuButton<String>(
          key: const ValueKey('recipe-menu'),
          tooltip: s.moreActions,
          onSelected: (v) => switch (v) {
            'new_version' => _openEditor(detail, newVersion: true),
            _ => _changeStage(detail, v),
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'new_version', child: Text(s.newVersion)),
            if (stage == RecipeStage.trial)
              PopupMenuItem(
                value: RecipeStage.approved,
                child: Text(s.approve),
              ),
            if (stage != RecipeStage.retired)
              PopupMenuItem(value: RecipeStage.retired, child: Text(s.retire)),
            if (stage != RecipeStage.trial && !detail.usedInProduction)
              PopupMenuItem(
                value: RecipeStage.trial,
                child: Text(s.backToTrial),
              ),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final allowed = ref.watch(canAccessProductionBoardProvider);
    final canPop = Navigator.of(context).canPop();
    // Reached by a deep link with nothing behind it: offer the list instead
    // of leaving the user stranded.
    final leading = canPop
        ? null
        : IconButton(
            tooltip: s.title,
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.of(
              context,
            ).pushReplacement(RecipeBookListScreen.route(showDrawer: true)),
          );

    if (!allowed) {
      return Scaffold(
        appBar: AppBar(leading: leading, title: Text(s.title)),
        body: Center(
          child: RecipeBookMessage(
            icon: Icons.lock_outline,
            title: s.accessDenied,
          ),
        ),
      );
    }

    final async = ref.watch(_provider(_sop));
    final detail = async.valueOrNull ?? _last;
    if (async.hasValue) _last = async.value;
    final loadingOther = async.isLoading && detail != null;

    Widget body;
    if (detail != null) {
      body = _buildRecipe(context, detail, loadingOther);
    } else if (async.hasError) {
      body = RecipeBookMessage(
        icon: Icons.cloud_off_outlined,
        title: s.recipeLoadFailed,
        body: context.userErrorMessage(async.error),
        actionLabel: s.retry,
        onAction: () => ref.invalidate(_provider(_sop)),
      );
    } else {
      body = const _DetailSkeleton();
    }

    final title = detail?.title ?? widget.title ?? s.title;
    return Scaffold(
      appBar: AppBar(
        leading: leading,
        actions: _editActions(detail),
        // A long name gets two lines at the smaller size rather than an
        // ellipsis: the title is the only place the recipe is named.
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: title.length > 24
              ? Theme.of(context).textTheme.titleMedium
              : null,
        ),
      ),
      body: body,
    );
  }

  Widget _buildRecipe(
    BuildContext context,
    RecipeDetail detail,
    bool loadingOther,
  ) {
    final theme = Theme.of(context);
    final s = RecipeBookStrings.of(context);
    final factor = ref.watch(recipeScaleProvider(detail.key));
    final hintDone = ref.watch(recipeScaleHintDoneProvider);
    final dismissed = ref.watch(recipeChangeNoteDismissedProvider);
    final bomOnly = detail.isBomOnly;
    final tabs = <_RecipeTab>[
      _RecipeTab.ingredients,
      if (!bomOnly) _RecipeTab.method,
      if (detail.hasNotes) _RecipeTab.notes,
    ];
    final tab = tabs.contains(_tab) ? _tab : _RecipeTab.ingredients;
    final summary = detail.changeSummary;
    final showSummary =
        !bomOnly && summary != null && !dismissed.contains(detail.name);

    Widget content = switch (tab) {
      _RecipeTab.ingredients => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecipeIngredientsList(
            ingredients: detail.ingredients,
            factor: factor,
            onTapIngredient: (i) => _scaleByIngredient(detail, i, factor),
          ),
          if (bomOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Text(
                s.noWrittenMethod,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (bomOnly && detail.canEdit)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonalIcon(
                  key: const ValueKey('recipe-write-method'),
                  onPressed: () => _openEditor(detail),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(s.writeMethod),
                ),
              ),
            ),
        ],
      ),
      _RecipeTab.method => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (detail.layers.isNotEmpty) _DetailLayers(layers: detail.layers),
          RecipeStepsList(
            steps: detail.steps,
            factor: factor,
            unresolvedTokens: detail.unresolvedTokens,
          ),
        ],
      ),
      _RecipeTab.notes => RecipeNotesView(detail: detail),
    };

    return RecipeBookWidth(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (loadingOther) const LinearProgressIndicator(minHeight: 2),
                  if (!bomOnly)
                    _Header(
                      detail: detail,
                      onVersions: detail.versions.length > 1
                          ? () => _pickVersion(detail)
                          : null,
                    ),
                  if (showSummary)
                    _WhatChangedCard(
                      summary: summary,
                      onDismiss: () {
                        ref
                            .read(recipeChangeNoteDismissedProvider.notifier)
                            .state = {
                          ...dismissed,
                          detail.name,
                        };
                      },
                    ),
                ],
              ),
            ),
            PinnedHeaderSliver(
              child: Material(
                color: theme.colorScheme.surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RecipeScaleBar(
                      factor: factor,
                      batchYield: detail.batchYield,
                      showHint: !hintDone && detail.ingredients.isNotEmpty,
                      onFactor: (f) => setRecipeScale(ref, detail.key, f),
                      onEditBatch: detail.batchYield.isKnown
                          ? () => _scaleByBatch(detail, factor)
                          : null,
                    ),
                    if (tabs.length > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                        child: SegmentedButton<_RecipeTab>(
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                          segments: [
                            for (final t in tabs)
                              ButtonSegment(
                                value: t,
                                label: Text(switch (t) {
                                  _RecipeTab.ingredients => s.tabIngredients,
                                  _RecipeTab.method => s.tabMethod,
                                  _RecipeTab.notes => s.tabNotes,
                                }),
                              ),
                          ],
                          selected: {tab},
                          onSelectionChanged: (set) =>
                              setState(() => _tab = set.first),
                        ),
                      ),
                    const Divider(height: 1),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: content),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

/// A jar recipe's layers, bottom first: number, name, grams per jar.
class _DetailLayers extends StatelessWidget {
  const _DetailLayers({required this.layers});

  final List<RecipeLayer> layers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = RecipeBookStrings.of(context);
    final total = layers.fold<double>(0, (a, l) => a + l.grams);
    final quiet = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final number = theme.textTheme.bodyMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      key: const ValueKey('recipe-layers'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.layersPerJar, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          for (var i = 0; i < layers.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 22, child: Text('${i + 1}', style: quiet)),
                  Expanded(child: Text(sentenceCase(layers[i].layer))),
                  Text(formatGrams(layers[i].grams), style: number),
                ],
              ),
            ),
          const Divider(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.filledJar,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatGrams(total),
                style: number?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(s.layersFillOrder, style: quiet),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail, required this.onVersions});

  final RecipeDetail detail;
  final VoidCallback? onVersions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = RecipeBookStrings.of(context);
    final versionLabel =
        '${s.versionNo(detail.version)} · ${s.versionStatus(detail.status)}';
    final pillStatus = switch (detail.status) {
      VersionStatus.trial => RecipeStatus.trial,
      VersionStatus.retired => RecipeStatus.retired,
      _ => RecipeStatus.approved,
    };
    return Padding(
      // The title itself sits in the app bar, where it stays visible while
      // the method scrolls; repeating it here only crowded the page.
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RecipeStatusPill(status: pillStatus),
              OutlinedButton(
                key: const ValueKey('recipe-version-button'),
                onPressed: onVersions,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(versionLabel),
                    if (onVersions != null)
                      const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
              if (detail.inProduction)
                Text(
                  s.inProduction,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhatChangedCard extends StatelessWidget {
  const _WhatChangedCard({required this.summary, required this.onDismiss});

  final String summary;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = RecipeBookStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Material(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  size: 16,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${s.whatChanged}: ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: summary),
                    ],
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              IconButton(
                tooltip: s.dismiss,
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return RecipeBookWidth(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const RecipeSkeletonBar(width: 200, height: 22),
          const SizedBox(height: 12),
          const Row(
            children: [
              RecipeSkeletonBar(width: 64, height: 18),
              SizedBox(width: 8),
              RecipeSkeletonBar(width: 110, height: 28),
            ],
          ),
          const SizedBox(height: 24),
          const RecipeSkeletonBar(width: double.infinity, height: 36),
          const SizedBox(height: 20),
          for (var i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  RecipeSkeletonBar(width: 100.0 + (i % 3) * 30),
                  const Spacer(),
                  const RecipeSkeletonBar(width: 60),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
