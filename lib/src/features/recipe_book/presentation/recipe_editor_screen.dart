import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/user_error_message.dart';
import '../data/recipe_book_models.dart';
import '../data/recipe_book_service.dart';
import '../domain/recipe_edit_logic.dart';
import '../domain/recipe_scaling.dart';
import '../state/recipe_book_providers.dart';
import 'recipe_book_strings.dart';
import 'widgets/recipe_book_common.dart';
import 'widgets/recipe_edit_widgets.dart';

/// The recipe form: basics, yield, ingredients, jar layers, method and notes
/// in one scrolling page. Answers the saved [RecipeDetail], or null on back.
///
/// Opens one of four ways:
/// * [sop] — edit that version (in place when allowed, else as a new version);
/// * [sop] + [newVersion] — always save as a new version;
/// * [itemCode] — write the first method for a BOM-only item;
/// * neither — a new recipe ([initialCategory] preselects its kind).
class RecipeEditorScreen extends ConsumerStatefulWidget {
  const RecipeEditorScreen({
    super.key,
    this.sop,
    this.itemCode,
    this.newVersion = false,
    this.initialCategory,
  });

  final String? sop;
  final String? itemCode;
  final bool newVersion;
  final String? initialCategory;

  static Route<RecipeDetail> route({
    String? sop,
    String? itemCode,
    bool newVersion = false,
    String? initialCategory,
  }) => MaterialPageRoute<RecipeDetail>(
    settings: const RouteSettings(name: '/recipes/edit'),
    fullscreenDialog: true,
    builder: (_) => RecipeEditorScreen(
      sop: sop,
      itemCode: itemCode,
      newVersion: newVersion,
      initialCategory: initialCategory,
    ),
  );

  @override
  ConsumerState<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends ConsumerState<RecipeEditorScreen> {
  RecipeEditForm? _form;
  Object? _error;

  bool get _blank =>
      (widget.sop == null || widget.sop!.isEmpty) &&
      (widget.itemCode == null || widget.itemCode!.isEmpty);

  @override
  void initState() {
    super.initState();
    if (_blank) {
      _form = RecipeEditForm(category: widget.initialCategory ?? '');
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final form = await ref
          .read(recipeBookServiceProvider)
          .getRecipeForEdit(sop: widget.sop, itemCode: widget.itemCode);
      if (mounted) setState(() => _form = form);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = _form;
    if (form != null) {
      return _EditorForm(form: form, forceNewVersion: widget.newVersion);
    }
    final s = RecipeBookStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.edit)),
      body: _error == null
          ? const Center(child: CircularProgressIndicator())
          : RecipeBookMessage(
              icon: Icons.cloud_off_outlined,
              title: s.recipeLoadFailed,
              body: context.userErrorMessage(_error),
              actionLabel: s.retry,
              onAction: _load,
            ),
    );
  }
}

// ── rows ──────────────────────────────────────────────────────────────────

class _IngRow {
  _IngRow(EditIngredient? i)
    : name = TextEditingController(text: i?.name ?? ''),
      amount = TextEditingController(
        text: i?.amount == null
            ? ''
            : formatDecimal(i!.amount!, maxDecimals: 3),
      ),
      unit = TextEditingController(text: i?.unit ?? 'g'),
      section = TextEditingController(text: i?.section ?? ''),
      note = i?.note,
      itemCode = i?.itemCode,
      showSection = (i?.section ?? '').isNotEmpty;

  final key = UniqueKey();
  final TextEditingController name;
  final TextEditingController amount;
  final TextEditingController unit;
  final TextEditingController section;
  final String? note;
  final String? itemCode;
  bool showSection;

  void dispose() {
    name.dispose();
    amount.dispose();
    unit.dispose();
    section.dispose();
  }
}

class _StepRow {
  _StepRow(EditStep? st)
    : title = TextEditingController(text: st?.title ?? ''),
      text = TextEditingController(text: st?.text ?? ''),
      minutes = TextEditingController(
        text: st?.durationMins == null
            ? ''
            : formatDecimal(st!.durationMins!, maxDecimals: 2),
      ),
      extra = st?.extra ?? const <String, dynamic>{};

  final key = UniqueKey();
  final TextEditingController title;
  final TextEditingController text;
  final TextEditingController minutes;
  final Map<String, dynamic> extra;

  void dispose() {
    title.dispose();
    text.dispose();
    minutes.dispose();
  }
}

class _LayerRow {
  _LayerRow(RecipeLayer? l)
    : name = TextEditingController(text: l?.layer ?? ''),
      grams = TextEditingController(
        text: l == null ? '' : formatDecimal(l.grams, maxDecimals: 3),
      ),
      note = l?.note;

  final key = UniqueKey();
  final TextEditingController name;
  final TextEditingController grams;
  final String? note;

  void dispose() {
    name.dispose();
    grams.dispose();
  }
}

// ── the form ──────────────────────────────────────────────────────────────

class _EditorForm extends ConsumerStatefulWidget {
  const _EditorForm({required this.form, required this.forceNewVersion});

  final RecipeEditForm form;
  final bool forceNewVersion;

  @override
  ConsumerState<_EditorForm> createState() => _EditorFormState();
}

class _EditorFormState extends ConsumerState<_EditorForm> {
  late final RecipeEditForm _f = widget.form;
  late final bool _isNew = _f.base == null && !_f.hasItem;
  late final bool _firstVersion = _f.base == null && _f.hasItem;

  /// Saving always makes a new version: asked for, or this one cannot change
  /// where it stands.
  late final bool _asNewVersion =
      !_isNew &&
      !_firstVersion &&
      (widget.forceNewVersion ||
          !_f.editableInPlace ||
          _f.stage == RecipeStage.retired);

  late final _title = TextEditingController(text: _f.title);
  final _flavour = TextEditingController();
  late final _yieldQty = TextEditingController(
    text: _f.yieldQty == null
        ? ''
        : formatDecimal(_f.yieldQty!, maxDecimals: 3),
  );
  late final _yieldUom = TextEditingController(text: _f.yieldUom ?? '');
  late final _prep = TextEditingController(
    text: _f.prepTimeMins?.toString() ?? '',
  );
  late final _equipment = TextEditingController(text: _f.equipment);
  late final _notes = TextEditingController(text: _f.notes);

  late String _category = _f.category;
  late String? _track = _f.track;
  String _size = '';

  late final List<_IngRow> _ings = [for (final i in _f.ingredients) _IngRow(i)];
  late final List<_LayerRow> _layers = [
    for (final l in _f.layers) _LayerRow(l),
  ];
  late final List<_StepRow> _steps = [for (final st in _f.steps) _StepRow(st)];

  late final String _initial;
  bool _saving = false;

  /// Removed rows: their fields may still be on screen for one frame, so they
  /// are disposed with the form.
  final _trash = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    if (_isNew && _ings.isEmpty && !_f.fromBom) _ings.add(_IngRow(null));
    _initial = _snapshot();
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _flavour,
      _yieldQty,
      _yieldUom,
      _prep,
      _equipment,
      _notes,
    ]) {
      c.dispose();
    }
    for (final r in _ings) {
      r.dispose();
    }
    for (final r in _layers) {
      r.dispose();
    }
    for (final r in _steps) {
      r.dispose();
    }
    for (final d in _trash) {
      d();
    }
    super.dispose();
  }

  bool get _composeJar => _isNew && _category == RecipeCategory.jars;

  RecipeDraft _draft() => RecipeDraft(
    title: _title.text,
    track: _track,
    category: _category,
    flavour: _flavour.text,
    size: _size,
    yieldQty: _yieldQty.text,
    yieldUom: _yieldUom.text,
    prepMins: _prep.text,
    equipment: _equipment.text,
    notes: _notes.text,
    fromBom: _f.fromBom,
    composeJar: _composeJar,
    ingredients: [
      for (final r in _ings)
        IngredientDraft(
          name: r.name.text,
          amount: r.amount.text,
          unit: r.unit.text,
          section: r.section.text,
          note: r.note,
          itemCode: r.itemCode,
        ),
    ],
    layers: [
      for (final r in _layers)
        LayerDraft(layer: r.name.text, grams: r.grams.text, note: r.note),
    ],
    steps: [
      for (final r in _steps)
        StepDraft(
          title: r.title.text,
          text: r.text.text,
          minutes: r.minutes.text,
          extra: r.extra,
        ),
    ],
  );

  String _snapshot() => buildSaveRecipePayload(
    _draft(),
    mode: SaveMode.inPlace,
    stage: RecipeStage.trial,
  ).toString();

  bool get _dirty => _snapshot() != _initial;

  void _refresh() => setState(() {});

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _onBack() async {
    if (!_dirty || await confirmDiscardChanges(context)) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  /// Ingredient names the "Insert amount" picker offers.
  List<String> get _ingredientNames => _f.fromBom
      ? [
          for (final i in _f.ingredients)
            if (i.name.trim().isNotEmpty) i.name.trim(),
        ]
      : [
          for (final r in _ings)
            if (r.name.text.trim().isNotEmpty) r.name.text.trim(),
        ];

  Future<void> _insertAmount(_StepRow row) async {
    final picked = await showInsertAmountSheet(
      context,
      names: _ingredientNames,
      offerPerJar: _category == RecipeCategory.jars,
    );
    if (picked == null || !mounted) return;
    row.text.value = insertAtCursor(row.text.value, picked);
    _refresh();
  }

  Future<void> _save({required bool asNewVersion}) async {
    final s = RecipeBookStrings.of(context);
    final draft = _draft();
    final issue = validateDraft(
      draft,
      requireIngredients: _isNew && !_f.fromBom,
    );
    if (issue != null) {
      _snack(s.issueText(issue.name));
      return;
    }
    var mode = SaveMode.inPlace;
    var stage = _f.stage == RecipeStage.approved
        ? RecipeStage.approved
        : RecipeStage.trial;
    var summary = '';
    if (asNewVersion || _isNew || _firstVersion) {
      mode = SaveMode.newVersion;
      final first = _isNew || _firstVersion;
      final answer = await showSaveSheet(
        context,
        confirmLabel: first ? s.save : s.saveAsVersion(_f.nextVersion),
        askSummary: !first,
        askStage: true,
        initialStage: _firstVersion ? RecipeStage.approved : RecipeStage.trial,
        approvedHint: !first && _f.hasItem
            ? s.replacesOnBoard(_f.version)
            : s.approvedNewHint,
      );
      if (answer == null || !mounted) return;
      stage = answer.stage;
      summary = answer.summary;
    }
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(recipeBookServiceProvider)
          .saveRecipe(
            buildSaveRecipePayload(
              draft,
              mode: mode,
              stage: stage,
              base: _f.base,
              itemCode: _f.itemCode,
              changeSummary: summary,
              tokenMap: _f.tokenMap,
            ),
          );
      invalidateRecipeBook(ref);
      if (!mounted) return;
      if (result.warnings.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(s.warningsTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.warningsBody),
                const SizedBox(height: 8),
                for (final w in result.warnings) Text('• $w'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(s.ok),
              ),
            ],
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(result.recipe);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(recipeErrorText(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final inPlace = !_asNewVersion && !_isNew && !_firstVersion;
    final saveLabel = inPlace || _isNew || _firstVersion
        ? s.save
        : s.saveAsVersion(_f.nextVersion);
    final screenTitle = _isNew
        ? s.newRecipe
        : _firstVersion
        ? s.writeMethod
        : _asNewVersion
        ? s.newVersion
        : s.edit;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(screenTitle),
          actions: [
            if (_saving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              TextButton(
                key: const ValueKey('recipe-save'),
                onPressed: () => _save(asNewVersion: _asNewVersion),
                child: Text(saveLabel),
              ),
            if (inPlace)
              PopupMenuButton<String>(
                key: const ValueKey('recipe-save-menu'),
                enabled: !_saving,
                tooltip: s.moreActions,
                onSelected: (_) => _save(asNewVersion: true),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'new_version',
                    child: Text(s.saveAsNewVersion),
                  ),
                ],
              ),
          ],
        ),
        body: RecipeBookWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _basics(context),
              if (!_f.fromBom) _yield(context),
              _ingredients(context),
              if (_category == RecipeCategory.jars) _layersSection(context),
              _method(context),
              _more(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── sections ──

  Widget _basics(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final tracks = <String>{
      ...?ref.watch(recipeBookIndexProvider).valueOrNull?.tracks,
      if (_track != null && _track!.isNotEmpty) _track!,
    }.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSectionTitle(s.basics),
        if (_composeJar) ...[
          TextField(
            key: const ValueKey('recipe-flavour'),
            controller: _flavour,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: s.fieldFlavour,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(s.fieldSize, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            key: const ValueKey('recipe-size'),
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            segments: [
              for (final size in kJarSizes)
                ButtonSegment(value: size, label: Text(s.size(size))),
            ],
            selected: {if (_size.isNotEmpty) _size},
            onSelectionChanged: (v) =>
                setState(() => _size = v.isEmpty ? '' : v.first),
          ),
        ] else
          TextField(
            key: const ValueKey('recipe-title'),
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: s.fieldTitle,
              border: const OutlineInputBorder(),
            ),
          ),
        const SizedBox(height: 14),
        Text(s.fieldCategory, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final c in RecipeCategory.order)
              ChoiceChip(
                key: ValueKey('recipe-category-$c'),
                label: Text(s.category(c)),
                selected: _category == c,
                showCheckmark: false,
                onSelected: (_) => setState(() => _category = c),
              ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          key: ValueKey('recipe-track-${_track ?? ''}'),
          initialValue: _track,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: s.fieldTrack,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(s.noTrack)),
            for (final t in tracks)
              DropdownMenuItem<String?>(value: t, child: Text(s.track(t))),
          ],
          onChanged: (v) => setState(() => _track = v),
        ),
      ],
    );
  }

  Widget _yield(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSectionTitle(s.yieldTitle),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                key: const ValueKey('recipe-yield-qty'),
                controller: _yieldQty,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: s.fieldQty,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _UnitField(controller: _yieldUom, label: s.fieldUnit),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ingredients(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    if (_f.fromBom) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EditorSectionTitle(s.tabIngredients),
          for (final i in _f.ingredients)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(sentenceCase(i.name))),
                  Text(
                    i.amount == null
                        ? ''
                        : formatIngredientAmount(i.amount!, i.unit),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            s.bomNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSectionTitle(s.tabIngredients),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) => setState(() {
            _ings.insert(to, _ings.removeAt(from));
          }),
          children: [
            for (var i = 0; i < _ings.length; i++)
              _IngredientCard(
                key: _ings[i].key,
                index: i,
                row: _ings[i],
                onChanged: _refresh,
                onDelete: () =>
                    setState(() => _trash.add(_ings.removeAt(i).dispose)),
              ),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('recipe-add-ingredient'),
            onPressed: () => setState(() => _ings.add(_IngRow(null))),
            icon: const Icon(Icons.add),
            label: Text(s.addIngredient),
          ),
        ),
      ],
    );
  }

  Widget _layersSection(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSectionTitle(s.layersPerJar),
        Text(
          s.layersFillOrder,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) => setState(() {
            _layers.insert(to, _layers.removeAt(from));
          }),
          children: [
            for (var i = 0; i < _layers.length; i++)
              Padding(
                key: _layers[i].key,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                    SizedBox(width: 20, child: Text('${i + 1}')),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        key: ValueKey('recipe-layer-name-$i'),
                        controller: _layers[i].name,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: s.layerName,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        key: ValueKey('recipe-layer-grams-$i'),
                        controller: _layers[i].grams,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          suffixText: 'g',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: s.deleteRow,
                      onPressed: () => setState(
                        () => _trash.add(_layers.removeAt(i).dispose),
                      ),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('recipe-add-layer'),
            onPressed: () => setState(() => _layers.add(_LayerRow(null))),
            icon: const Icon(Icons.add),
            label: Text(s.addLayer),
          ),
        ),
      ],
    );
  }

  Widget _method(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSectionTitle(s.methodTitle),
        Text(
          s.placeholderHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) => setState(() {
            _steps.insert(to, _steps.removeAt(from));
          }),
          children: [
            for (var i = 0; i < _steps.length; i++)
              _StepCard(
                key: _steps[i].key,
                index: i,
                row: _steps[i],
                onInsert: () => _insertAmount(_steps[i]),
                onDelete: () =>
                    setState(() => _trash.add(_steps.removeAt(i).dispose)),
              ),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('recipe-add-step'),
            onPressed: () => setState(() => _steps.add(_StepRow(null))),
            icon: const Icon(Icons.add),
            label: Text(s.addStep),
          ),
        ),
      ],
    );
  }

  Widget _more(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('recipe-more'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: Text(
            s.moreSection,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: s.fieldNotes,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _equipment,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: s.fieldEquipment,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prep,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: s.fieldPrepMins,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── cards ─────────────────────────────────────────────────────────────────

/// A unit text field with a menu of the usual units.
class _UnitField extends StatelessWidget {
  const _UnitField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        suffixIcon: PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down),
          padding: EdgeInsets.zero,
          onSelected: (v) => controller.text = v,
          itemBuilder: (_) => [
            for (final u in kEditUnits) PopupMenuItem(value: u, child: Text(u)),
          ],
        ),
      ),
    );
  }
}

class _IngredientCard extends StatefulWidget {
  const _IngredientCard({
    super.key,
    required this.index,
    required this.row,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final _IngRow row;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  State<_IngredientCard> createState() => _IngredientCardState();
}

class _IngredientCardState extends State<_IngredientCard> {
  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final row = widget.row;
    final i = widget.index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: i,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle),
                ),
              ),
              Expanded(
                child: TextField(
                  key: ValueKey('ing-name-$i'),
                  controller: row.name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: s.fieldName,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                tooltip: s.deleteRow,
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 40, end: 48),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: ValueKey('ing-amount-$i'),
                        controller: row.amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: s.fieldAmount,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _UnitField(
                        controller: row.unit,
                        label: s.fieldUnit,
                      ),
                    ),
                  ],
                ),
                if (row.showSection) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: row.section,
                    decoration: InputDecoration(
                      labelText: s.fieldSection,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ] else
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                      ),
                      onPressed: () => setState(() => row.showSection = true),
                      child: Text('+ ${s.fieldSection}'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    super.key,
    required this.index,
    required this.row,
    required this.onInsert,
    required this.onDelete,
  });

  final int index;
  final _StepRow row;
  final VoidCallback onInsert;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
                SizedBox(width: 22, child: Text('${index + 1}')),
                Expanded(
                  child: TextField(
                    key: ValueKey('step-title-$index'),
                    controller: row.title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: s.stepTitle,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
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
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 0),
              child: TextField(
                key: ValueKey('step-text-$index'),
                controller: row.text,
                minLines: 3,
                maxLines: 10,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: s.stepText,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 0),
              child: Row(
                children: [
                  ActionChip(
                    key: ValueKey('step-insert-$index'),
                    avatar: const Icon(Icons.add_circle_outline, size: 18),
                    label: Text(s.insertAmount),
                    onPressed: onInsert,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 96,
                    child: TextField(
                      controller: row.minutes,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: s.stepMinutes,
                        isDense: true,
                        border: const OutlineInputBorder(),
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
