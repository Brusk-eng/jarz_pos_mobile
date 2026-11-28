import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recipe_book_models.dart';
import '../data/recipe_book_service.dart';
import '../domain/recipe_edit_logic.dart';
import '../domain/recipe_scaling.dart';
import '../state/recipe_book_providers.dart';
import 'recipe_book_strings.dart';
import 'widgets/recipe_book_common.dart';
import 'widgets/recipe_edit_widgets.dart';

/// The jar layer grid: a row per layer (name, then grams per jar for every
/// size of the family), drag to reorder (the first row is the bottom of the
/// jar), a live total per size. Answers the [SaveLayersResult] when saved.
class RecipeLayersEditorScreen extends ConsumerStatefulWidget {
  const RecipeLayersEditorScreen({super.key, required this.family});

  final JarFamily family;

  static Route<SaveLayersResult> route(JarFamily family) =>
      MaterialPageRoute<SaveLayersResult>(
        settings: const RouteSettings(name: '/recipes/layers'),
        builder: (_) => RecipeLayersEditorScreen(family: family),
      );

  @override
  ConsumerState<RecipeLayersEditorScreen> createState() =>
      _RecipeLayersEditorScreenState();
}

class _GridRow {
  _GridRow(this.name, this.note, this.grams);

  final key = UniqueKey();
  final TextEditingController name;
  final String? note;
  final Map<String, TextEditingController> grams;

  void dispose() {
    name.dispose();
    for (final c in grams.values) {
      c.dispose();
    }
  }
}

class _RecipeLayersEditorScreenState
    extends ConsumerState<RecipeLayersEditorScreen> {
  late final List<String> _sizes = [
    for (final size in widget.family.sizes) size.size,
  ];
  late final List<_GridRow> _rows;
  late final String _initial;
  bool _saving = false;
  final _trash = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    _rows = [
      for (final r in initialLayerGrid(widget.family.assembly)) _fromRow(r),
    ];
    _initial = _snapshot();
  }

  _GridRow _fromRow(LayerGridRow r) =>
      _GridRow(TextEditingController(text: r.name), r.note, {
        for (final size in _sizes)
          size: TextEditingController(text: r.grams[size] ?? ''),
      });

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    for (final d in _trash) {
      d();
    }
    super.dispose();
  }

  List<LayerGridRow> _grid() => [
    for (final r in _rows)
      LayerGridRow(
        name: r.name.text,
        note: r.note,
        grams: {for (final e in r.grams.entries) e.key: e.value.text},
      ),
  ];

  String _snapshot() => buildLayersPayload(_grid(), _sizes).toString();

  bool get _dirty => _snapshot() != _initial;

  void _addRow() {
    setState(() => _rows.add(_fromRow(LayerGridRow())));
  }

  void _removeRow(int index) {
    setState(() => _trash.add(_rows.removeAt(index).dispose));
  }

  void _reorder(int from, int to) {
    setState(() => _rows.insert(to, _rows.removeAt(from)));
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    final s = RecipeBookStrings.of(context);
    final grid = _grid();
    final issue = validateLayerGrid(grid, _sizes);
    if (issue != null) {
      _snack(s.issueText(issue.name));
      return;
    }
    final touched = layerGridTouchedSizes(grid, _sizes);
    final needsSummary = [
      for (final size in widget.family.sizes)
        if (touched.contains(size.size) && !size.editableInPlace) size,
    ].isNotEmpty;
    var summary = '';
    if (needsSummary) {
      final answer = await showSaveSheet(
        context,
        confirmLabel: s.save,
        askStage: false,
        note: s.layersNewVersionNote,
      );
      if (answer == null || !mounted) return;
      summary = answer.summary;
    }
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(recipeBookServiceProvider)
          .saveJarLayers(
            widget.family.family,
            buildLayersPayload(grid, _sizes),
            changeSummary: summary,
          );
      invalidateRecipeBook(ref);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(recipeErrorText(context, error));
    }
  }

  Future<void> _onBack() async {
    if (!_dirty || await confirmDiscardChanges(context)) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    final totals = layerGridTotals(_grid(), _sizes);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.layersTitle),
          actions: [
            TextButton(
              key: const ValueKey('layers-save'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.save),
            ),
          ],
        ),
        body: RecipeBookWidth(
          child: ReorderableListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            buildDefaultDragHandles: false,
            onReorderItem: _reorder,
            header: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${widget.family.family} · ${s.layersFillOrder}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const ValueKey('layers-add'),
                    onPressed: _addRow,
                    icon: const Icon(Icons.add),
                    label: Text(s.addLayer),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 0, 0),
                  child: Text(
                    s.filledJar,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(48, 6, 12, 6),
                  child: Row(
                    children: [
                      for (final size in _sizes)
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                s.size(size),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                totals[size] == null
                                    ? '—'
                                    : formatGramsNumber(totals[size]!),
                                key: ValueKey('layers-total-$size'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    s.layersFootnote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              for (var i = 0; i < _rows.length; i++)
                _LayerCard(
                  key: _rows[i].key,
                  index: i,
                  row: _rows[i],
                  sizes: _sizes,
                  onChanged: () => setState(() {}),
                  onDelete: () => _removeRow(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayerCard extends StatelessWidget {
  const _LayerCard({
    super.key,
    required this.index,
    required this.row,
    required this.sizes,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final _GridRow row;
  final List<String> sizes;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
        child: Column(
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_handle,
                      semanticLabel: s.dragToReorder,
                    ),
                  ),
                ),
                SizedBox(
                  width: 22,
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Expanded(
                  child: TextField(
                    key: ValueKey('layer-name-$index'),
                    controller: row.name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: s.layerName,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                IconButton(
                  tooltip: s.deleteRow,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(44, 8, 8, 0),
              child: Row(
                children: [
                  for (final size in sizes)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: TextField(
                          key: ValueKey('layer-grams-$index-$size'),
                          controller: row.grams[size],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: s.size(size),
                            suffixText: 'g',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
