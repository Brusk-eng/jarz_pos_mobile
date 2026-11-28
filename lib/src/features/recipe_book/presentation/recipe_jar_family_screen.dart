import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/user_error_message.dart';
import '../../../core/network/user_service.dart';
import '../data/recipe_book_models.dart';
import '../domain/jar_family_logic.dart';
import '../domain/recipe_scaling.dart';
import '../domain/recipe_targets.dart';
import '../state/recipe_book_providers.dart';
import 'recipe_layers_editor_screen.dart';
import 'recipe_book_list_screen.dart';
import 'recipe_book_strings.dart';
import 'recipe_detail_screen.dart';
import 'widgets/recipe_book_common.dart';

/// Width of a size column and of the Total column: a phone fits Small,
/// Medium, Large and Total beside a flexible name column.
const double _sizeColWidth = 52;
const double _totalColWidth = 68;

/// One jar flavour, every size side by side: layer weights per jar, packaging,
/// a "Plan a run" calculator and the method of each size.
///
/// Reached through `/recipes/jar:<family>` (see [RecipeDetailScreen]).
class RecipeJarFamilyScreen extends ConsumerStatefulWidget {
  const RecipeJarFamilyScreen({super.key, required this.family, this.title});

  final String family;

  /// Shown in the app bar while the family loads.
  final String? title;

  @override
  ConsumerState<RecipeJarFamilyScreen> createState() =>
      _RecipeJarFamilyScreenState();
}

class _RecipeJarFamilyScreenState extends ConsumerState<RecipeJarFamilyScreen> {
  /// One count field per size, kept across rebuilds.
  final _controllers = <String, TextEditingController>{};
  final _counts = <String, double>{};

  /// The size shown in the layers list when the sizes' layers differ.
  String? _layerSize;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String size) =>
      _controllers.putIfAbsent(size, TextEditingController.new);

  void _setCount(String size, String raw) {
    final value = parseAmount(raw);
    setState(() {
      if (value == null || value <= 0) {
        _counts.remove(size);
      } else {
        _counts[size] = value;
      }
    });
  }

  Future<void> _refresh() =>
      ref.refresh(jarFamilyProvider(widget.family).future);

  Future<void> _editLayers(JarFamily family) async {
    final result = await Navigator.of(
      context,
    ).push(RecipeLayersEditorScreen.route(family));
    if (!mounted || result == null) return;
    final s = RecipeBookStrings.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.created.isEmpty
                ? s.saved
                : s.savedNewVersionFor(result.created),
          ),
        ),
      );
  }

  void _open(String? target, String title) {
    if (target == null) return;
    Navigator.of(context).push(RecipeDetailScreen.route(target, title: title));
  }

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final allowed = ref.watch(canAccessProductionBoardProvider);
    final canPop = Navigator.of(context).canPop();
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

    final async = ref.watch(jarFamilyProvider(widget.family));
    final family = async.valueOrNull;
    final name = family?.family ?? widget.title ?? widget.family;
    final track = family?.track;
    final theme = Theme.of(context);

    Widget body;
    if (family != null) {
      body = _buildFamily(context, family);
    } else if (async.hasError) {
      body = RecipeBookMessage(
        icon: Icons.cloud_off_outlined,
        title: s.jarLoadFailed,
        body: context.userErrorMessage(async.error),
        actionLabel: s.retry,
        onAction: () => ref.invalidate(jarFamilyProvider(widget.family)),
      );
    } else {
      body = const _FamilySkeleton();
    }

    return Scaffold(
      appBar: AppBar(
        leading: leading,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (track != null)
              Text(
                s.track(track),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: body,
    );
  }

  Widget _buildFamily(BuildContext context, JarFamily family) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    final run = computeJarRun(family, _counts);
    final quiet = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final withSop = [
      for (final size in family.sizes)
        if (size.sop != null && size.sop!.isNotEmpty) size,
    ];

    return RecipeBookWidth(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _LayersSection(
              family: family,
              counts: _counts,
              selectedSize: _layerSize,
              onSelectSize: (size) => setState(() => _layerSize = size),
              onEdit: () => _editLayers(family),
            ),
            const SizedBox(height: 22),
            if (family.layers.isEmpty && family.packaging.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(s.noLayers, style: quiet),
              )
            else ...[
              Text(s.ingredientsPerJar, style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              _JarTable(
                family: family,
                run: run,
                onOpenSize: (size) =>
                    _open(recipeTargetForSize(size), family.family),
              ),
            ],
            if (family.packaging.isNotEmpty)
              _PackagingSection(family: family, run: run),
            const SizedBox(height: 20),
            Text(s.planRun, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final size in family.sizes)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: TextField(
                        key: ValueKey('jar-count-${size.size}'),
                        controller: _controllerFor(size.size),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: s.size(size.size),
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) => _setCount(size.size, v),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(s.planRunHint, style: quiet),
            const SizedBox(height: 24),
            Text(s.tabMethod, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            if (withSop.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(s.noWrittenMethod, style: quiet),
              )
            else
              for (final size in withSop)
                InkWell(
                  key: ValueKey('jar-method-${size.size}'),
                  onTap: () => _open(recipeTargetSop(size.sop!), family.family),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.sizeMethod(size.size, size.sopVersion),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        if (size.isTrial) ...[
                          RecipeStatusPill(
                            status: RecipeStatus.trial,
                            label: s.trialPill,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

TextStyle? _numberStyle(BuildContext context, {bool bold = false}) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w600 : null,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// "—" for an amount that does not exist.
const String _none = '—';

/// The prepared layers of a jar in fill order. Aligned sizes share one table
/// (layers down, sizes across, a "Filled jar" total at the foot); sizes whose
/// layers differ get a size switch and one numbered list.
class _LayersSection extends StatelessWidget {
  const _LayersSection({
    required this.family,
    required this.counts,
    required this.selectedSize,
    required this.onSelectSize,
    required this.onEdit,
  });

  final JarFamily family;
  final Map<String, double> counts;
  final String? selectedSize;
  final ValueChanged<String> onSelectSize;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    final quiet = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final assembly = family.assembly;
    final canEdit = family.canEdit;
    return Column(
      key: const ValueKey('jar-layers'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(s.layersPerJar, style: theme.textTheme.titleSmall),
            ),
            if (canEdit && !assembly.isEmpty)
              IconButton(
                key: const ValueKey('jar-layers-edit'),
                tooltip: s.editLayers,
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
          ],
        ),
        if (assembly.isEmpty) ...[
          Text(s.noLayersYet, style: quiet),
          if (canEdit)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const ValueKey('jar-layers-add'),
                onPressed: onEdit,
                child: Text(s.addLayers),
              ),
            ),
        ] else ...[
          const SizedBox(height: 4),
          if (assembly.aligned && assembly.rows.isNotEmpty)
            _alignedTable(context)
          else
            _sizeList(context),
          const SizedBox(height: 4),
          Text(s.layersFillOrder, style: quiet),
        ],
      ],
    );
  }

  Widget _alignedTable(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    final assembly = family.assembly;
    final showTotal = counts.values.any((c) => c > 0);
    final sizes = [for (final size in family.sizes) size.size];
    Widget numberedName(int i, String name) => Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            '${i + 1}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            sentenceCase(name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TableRow(
          label: const SizedBox.shrink(),
          cells: [
            for (final size in sizes)
              Text(
                s.size(size),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
          total: showTotal
              ? Text(
                  s.total,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        const Divider(height: 1),
        for (var i = 0; i < assembly.rows.length; i++)
          _TableRow(
            label: numberedName(i, assembly.rows[i].layer),
            cells: [
              for (final size in sizes)
                _Num(
                  assembly.rows[i].grams[size] == null
                      ? _none
                      : formatGramsNumber(assembly.rows[i].grams[size]!),
                ),
            ],
            total: showTotal
                ? _Num(
                    assemblyRowRunTotal(assembly.rows[i], counts) > 0
                        ? formatWeight(
                            assemblyRowRunTotal(assembly.rows[i], counts),
                          )
                        : _none,
                  )
                : null,
          ),
        const Divider(height: 1),
        _TableRow(
          label: Text(
            s.filledJar,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _numberStyle(context, bold: true),
          ),
          cells: [
            for (final size in sizes)
              _Num(
                assembly.totals[size] == null
                    ? _none
                    : formatGramsNumber(assembly.totals[size]!),
                bold: true,
              ),
          ],
          total: showTotal
              ? _Num(
                  assemblyRunTotal(assembly, counts) > 0
                      ? formatWeight(assemblyRunTotal(assembly, counts))
                      : _none,
                  bold: true,
                )
              : null,
        ),
      ],
    );
  }

  Widget _sizeList(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    final assembly = family.assembly;
    final sizes = assembly.sizes;
    final size = sizes.contains(selectedSize) ? selectedSize! : sizes.first;
    final layers = assembly.bySize[size] ?? const <RecipeLayer>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<String>(
          key: const ValueKey('jar-layers-size'),
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: [
            for (final z in sizes)
              ButtonSegment(value: z, label: Text(s.size(z))),
          ],
          selected: {size},
          onSelectionChanged: (v) => onSelectSize(v.first),
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < layers.length; i++)
          _TableRow(
            label: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${i + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    sentenceCase(layers[i].layer),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            cells: [_Num(formatGramsNumber(layers[i].grams))],
          ),
        const Divider(height: 1),
        _TableRow(
          label: Text(s.filledJar, style: _numberStyle(context, bold: true)),
          cells: [
            _Num(
              assembly.totals[size] == null
                  ? _none
                  : formatGramsNumber(assembly.totals[size]!),
              bold: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// The comparison: layers down, sizes across, a Per jar row at the foot and a
/// Total column once a run is planned.
class _JarTable extends StatelessWidget {
  const _JarTable({
    required this.family,
    required this.run,
    required this.onOpenSize,
  });

  final JarFamily family;
  final JarRunTotals run;
  final ValueChanged<JarSize> onOpenSize;

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    final showTotal = run.hasRun;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TableRow(
          cells: [
            for (final size in family.sizes)
              InkWell(
                key: ValueKey('jar-size-${size.size}'),
                onTap: () => onOpenSize(size),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    s.size(size.size),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
          total: showTotal
              ? Text(
                  s.total,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
          label: const SizedBox.shrink(),
        ),
        const Divider(height: 1),
        for (final layer in family.layers)
          _layerRow(context, layer, family, run, showTotal),
        const Divider(height: 1),
        _TableRow(
          label: Text(
            s.perJar,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _numberStyle(context, bold: true),
          ),
          cells: [
            for (final size in family.sizes)
              _Num(
                jarGramsFor(family, size) == null
                    ? _none
                    : formatGramsNumber(jarGramsFor(family, size)!),
                bold: true,
              ),
          ],
          total: showTotal
              ? _Num(
                  run.totalGrams > 0 ? formatWeight(run.totalGrams) : _none,
                  bold: true,
                )
              : null,
        ),
      ],
    );
  }
}

Widget _layerRow(
  BuildContext context,
  JarLayer layer,
  JarFamily family,
  JarRunTotals run,
  bool showTotal, {
  Map<String, double>? totals,
  bool packaging = false,
}) {
  final plain =
      layer.unit.trim().toLowerCase() == 'g' || isPieceUnit(layer.unit);
  final name = sentenceCase(layer.name);
  final label = plain ? name : '$name · ${displayUnit(layer.unit)}';
  final sums = totals ?? run.layers;
  final total = sums[layer.key] ?? 0;
  // Packaging is counted in whole pieces.
  String amount(double v) => packaging
      ? formatDecimal(v, maxDecimals: 0, grouping: true)
      : formatIngredientAmount(v, layer.unit);
  final theme = Theme.of(context);
  final items = <String>[
    if (packaging)
      for (final size in family.sizes)
        if (layer.items[size.size] != null)
          '${RecipeBookStrings.of(context).size(size.size)} ${layer.items[size.size]}',
  ];
  return _TableRow(
    label: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium,
    ),
    caption: items.isEmpty
        ? null
        : Text(
            items.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
    cells: [
      for (final size in family.sizes)
        _Num(
          layer.perJar[size.size] == null
              ? _none
              : amount(layer.perJar[size.size]!),
        ),
    ],
    total: showTotal
        ? _Num(
            total > 0
                ? (packaging
                      ? amount(total)
                      : formatRunAmount(total, layer.unit))
                : _none,
          )
        : null,
  );
}

/// A table line: a flexible name, then one fixed-width cell per size and an
/// optional Total cell. Right-aligned figures line up in every row. A
/// [caption] sits under the whole line.
class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.cells,
    required this.label,
    this.total,
    this.caption,
  });

  final Widget label;
  final List<Widget> cells;
  final Widget? total;
  final Widget? caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: label),
              for (final cell in cells)
                SizedBox(width: _sizeColWidth, child: cell),
              if (total != null) SizedBox(width: _totalColWidth, child: total),
            ],
          ),
          if (caption != null)
            Padding(padding: const EdgeInsets.only(top: 1), child: caption),
        ],
      ),
    );
  }
}

class _Num extends StatelessWidget {
  const _Num(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.end,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: _numberStyle(context, bold: bold),
  );
}

/// Jar, lid and label: collapsed, so the main table stays about the food.
class _PackagingSection extends StatelessWidget {
  const _PackagingSection({required this.family, required this.run});

  final JarFamily family;
  final JarRunTotals run;

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const ValueKey('jar-packaging'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(s.packaging, style: theme.textTheme.titleSmall),
        children: [
          for (final piece in family.packaging)
            _layerRow(
              context,
              piece,
              family,
              run,
              run.hasRun,
              totals: run.packaging,
              packaging: true,
            ),
        ],
      ),
    );
  }
}

class _FamilySkeleton extends StatelessWidget {
  const _FamilySkeleton();

  @override
  Widget build(BuildContext context) {
    return RecipeBookWidth(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const RecipeSkeletonBar(width: 90, height: 10),
          const SizedBox(height: 16),
          for (var i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  RecipeSkeletonBar(width: 90.0 + (i % 3) * 30),
                  const Spacer(),
                  const RecipeSkeletonBar(width: 40),
                  const SizedBox(width: 12),
                  const RecipeSkeletonBar(width: 40),
                  const SizedBox(width: 12),
                  const RecipeSkeletonBar(width: 40),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
