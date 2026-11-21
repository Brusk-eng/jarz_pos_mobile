import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/materials_repository.dart';
import '../../data/models/price_sheet.dart';
import '../../state/materials_notifier.dart';

/// Edits the template behind a generated price sheet: the heading, which
/// price list fills it, the size columns, the flavour rows, the terms and the
/// footer. Prices themselves are never typed here — they come from the price
/// list (and the recipient's running deal) when the sheet is sent.
///
/// Read-only for anyone without full manager pricing access; the server
/// enforces the same gate on save.
class PriceSheetTemplateScreen extends ConsumerStatefulWidget {
  const PriceSheetTemplateScreen({super.key, required this.material});

  final String material;

  @override
  ConsumerState<PriceSheetTemplateScreen> createState() =>
      _PriceSheetTemplateScreenState();
}

class _RowDraft {
  _RowDraft({required this.flavour, String label = '', this.enabled = true})
    : label = TextEditingController(text: label);

  final String flavour;
  final TextEditingController label;
  bool enabled;
}

class _PriceSheetTemplateScreenState
    extends ConsumerState<PriceSheetTemplateScreen> {
  final _heading = TextEditingController();
  final _footer = TextEditingController();
  final List<_RowDraft> _rows = [];
  final List<TextEditingController> _terms = [];
  final List<String> _sizes = [];

  PriceSheetTemplate? _base;
  String? _priceList;
  bool _showDeals = true;
  bool _isDefault = false;
  bool _saving = false;

  /// Bumped on every seed so the price-list dropdown (which only reads its
  /// initial value) is rebuilt with the server's copy after a save.
  int _seedGeneration = 0;

  @override
  void dispose() {
    _heading.dispose();
    _footer.dispose();
    _disposeDrafts();
    super.dispose();
  }

  void _disposeDrafts() {
    for (final row in _rows) {
      row.label.dispose();
    }
    for (final term in _terms) {
      term.dispose();
    }
  }

  void _seed(PriceSheetTemplate template) {
    // The old controllers may still be attached to fields in the tree being
    // replaced; dispose them once this frame has swapped them out.
    final stale = <TextEditingController>[
      for (final row in _rows) row.label,
      ..._terms,
    ];
    if (stale.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final controller in stale) {
          controller.dispose();
        }
      });
    }
    _rows
      ..clear()
      ..addAll([
        for (final row in template.rows)
          _RowDraft(
            flavour: row.flavour,
            label: row.label,
            enabled: row.enabled,
          ),
      ]);
    _terms
      ..clear()
      ..addAll([
        for (final line in template.sheetTerms)
          TextEditingController(text: line),
      ]);
    _sizes
      ..clear()
      ..addAll(template.sheetSizes);
    _heading.text = template.sheetHeading;
    _footer.text = template.sheetFooter;
    _priceList = template.sheetPriceList;
    _showDeals = template.sheetShowDeals;
    _isDefault = template.isDefault;
    _base = template;
    _seedGeneration++;
  }

  /// The template as currently edited.
  PriceSheetTemplate _draft(PriceSheetTemplate base) => base.copyWith(
    sheetHeading: _heading.text,
    sheetFooter: _footer.text,
    sheetPriceList: _priceList,
    sheetSizes: List<String>.of(_sizes),
    sheetShowDeals: _showDeals,
    isDefault: _isDefault,
    sheetTerms: [for (final term in _terms) term.text],
    rows: [
      for (final row in _rows)
        PriceSheetTemplateRow(
          flavour: row.flavour,
          label: row.label.text,
          enabled: row.enabled,
        ),
    ],
  );

  Future<void> _save() async {
    final base = _base;
    if (base == null || _saving) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    // The server validates the same rules; checking here saves a round trip
    // and says which one in the rep's language.
    if (_sizes.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.priceSheetNeedSize)));
      return;
    }
    if (!_rows.any((r) => r.enabled)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.priceSheetNeedRow)));
      return;
    }

    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(materialsRepositoryProvider)
          .savePriceSheetTemplate(
            material: widget.material,
            template: _draft(base),
          );
      // "Selected by default" changes what the send sheet ticks.
      ref.invalidate(materialLibraryProvider);
      if (!mounted) return;
      setState(() {
        _seed(saved);
        _saving = false;
      });
      messenger.showSnackBar(SnackBar(content: Text(l10n.priceSheetSaved)));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text(context.userErrorMessage(error))),
      );
    }
  }

  void _openPreview() {
    context.push(
      Uri(
        path: AppRoutes.priceSheetPreview,
        queryParameters: {'material': widget.material},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(priceSheetTemplateProvider(widget.material));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.priceSheetTemplateTitle),
        actions: [
          IconButton(
            key: const ValueKey('price-sheet-preview'),
            tooltip: l10n.materialsPreview,
            icon: const Icon(Icons.visibility),
            onPressed: _openPreview,
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.userErrorMessage(error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(
                    priceSheetTemplateProvider(widget.material),
                  ),
                  child: Text(l10n.materialsRetry),
                ),
              ],
            ),
          ),
        ),
        data: (template) {
          if (_base == null) _seed(template);
          return _body(context, _base!);
        },
      ),
    );
  }

  Widget _body(BuildContext context, PriceSheetTemplate template) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final editable = template.canEdit && !_saving;

    // A price list the server no longer offers stays selectable, so opening
    // the editor never silently changes the saved value.
    final priceLists = <String>[
      ...template.priceLists,
      if (_priceList != null && !template.priceLists.contains(_priceList))
        _priceList!,
    ];
    final sizeChoices = <String>[
      ..._sizes,
      for (final size in template.availableSizes)
        if (!_sizes.contains(size)) size,
    ];
    final taken = _rows.map((r) => r.flavour.trim().toLowerCase()).toSet();
    final addable = [
      for (final flavour in template.availableFlavours)
        if (!taken.contains(flavour.trim().toLowerCase())) flavour,
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (!template.canEdit) ...[
                _Notice(text: l10n.priceSheetReadOnly),
                const SizedBox(height: 12),
              ],
              TextField(
                key: const ValueKey('price-sheet-heading'),
                controller: _heading,
                enabled: editable,
                decoration: InputDecoration(
                  labelText: l10n.priceSheetHeadingLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                key: ValueKey('price-sheet-price-list-$_seedGeneration'),
                initialValue: _priceList,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.priceSheetPriceListLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.priceSheetEachCustomerList),
                  ),
                  for (final list in priceLists)
                    DropdownMenuItem<String?>(value: list, child: Text(list)),
                ],
                onChanged: editable
                    ? (value) => setState(() => _priceList = value)
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.priceSheetSizesLabel,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final size in sizeChoices)
                    FilterChip(
                      key: ValueKey('price-sheet-size-$size'),
                      showCheckmark: false,
                      selected: _sizes.contains(size),
                      avatar: _sizes.contains(size)
                          ? CircleAvatar(
                              child: Text('${_sizes.indexOf(size) + 1}'),
                            )
                          : null,
                      label: Text(size),
                      onSelected: editable
                          ? (on) => setState(() {
                              if (on) {
                                if (!_sizes.contains(size)) _sizes.add(size);
                              } else {
                                _sizes.remove(size);
                              }
                            })
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                key: const ValueKey('price-sheet-show-deals'),
                contentPadding: EdgeInsets.zero,
                value: _showDeals,
                onChanged: editable
                    ? (value) => setState(() => _showDeals = value)
                    : null,
                title: Text(l10n.priceSheetShowDealsLabel),
                subtitle: Text(l10n.priceSheetShowDealsHint),
              ),
              const Divider(height: 28),
              Text(
                l10n.priceSheetFlavoursLabel,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              for (var i = 0; i < _rows.length; i++)
                _FlavourRow(
                  key: ValueKey('price-sheet-row-${_rows[i].flavour}'),
                  draft: _rows[i],
                  editable: editable,
                  canMoveUp: i > 0,
                  canMoveDown: i < _rows.length - 1,
                  onMoveUp: () => setState(() {
                    final row = _rows.removeAt(i);
                    _rows.insert(i - 1, row);
                  }),
                  onMoveDown: () => setState(() {
                    final row = _rows.removeAt(i);
                    _rows.insert(i + 1, row);
                  }),
                  onRemove: () => setState(() {
                    _rows.removeAt(i).label.dispose();
                  }),
                  onEnabled: (value) =>
                      setState(() => _rows[i].enabled = value),
                ),
              if (editable && addable.isNotEmpty)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: PopupMenuButton<String>(
                    key: const ValueKey('price-sheet-add-flavour'),
                    onSelected: (flavour) =>
                        setState(() => _rows.add(_RowDraft(flavour: flavour))),
                    itemBuilder: (_) => [
                      for (final flavour in addable)
                        PopupMenuItem<String>(
                          value: flavour,
                          child: Text(flavour),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.priceSheetAddFlavour,
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const Divider(height: 28),
              Text(
                l10n.priceSheetTermsLabel,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(l10n.priceSheetTermsHint, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              for (var i = 0; i < _terms.length; i++)
                _TermField(
                  key: ObjectKey(_terms[i]),
                  index: i,
                  controller: _terms[i],
                  editable: editable,
                  canMoveUp: i > 0,
                  canMoveDown: i < _terms.length - 1,
                  onMoveUp: () => setState(() {
                    final term = _terms.removeAt(i);
                    _terms.insert(i - 1, term);
                  }),
                  onMoveDown: () => setState(() {
                    final term = _terms.removeAt(i);
                    _terms.insert(i + 1, term);
                  }),
                  onRemove: () => setState(() {
                    _terms.removeAt(i).dispose();
                  }),
                ),
              if (editable)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const ValueKey('price-sheet-add-term'),
                    onPressed: () =>
                        setState(() => _terms.add(TextEditingController())),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.priceSheetAddTerm),
                  ),
                ),
              const Divider(height: 28),
              TextField(
                key: const ValueKey('price-sheet-footer'),
                controller: _footer,
                enabled: editable,
                decoration: InputDecoration(
                  labelText: l10n.priceSheetFooterLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                key: const ValueKey('price-sheet-default'),
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged: editable
                    ? (value) => setState(() => _isDefault = value)
                    : null,
                title: Text(l10n.priceSheetDefaultLabel),
                subtitle: Text(l10n.priceSheetDefaultHint),
              ),
            ],
          ),
        ),
        if (template.canEdit)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('price-sheet-save'),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(l10n.priceSheetSave),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FlavourRow extends StatelessWidget {
  const _FlavourRow({
    super.key,
    required this.draft,
    required this.editable,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onEnabled,
  });

  final _RowDraft draft;
  final bool editable;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final ValueChanged<bool> onEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: draft.label,
              enabled: editable,
              decoration: InputDecoration(
                isDense: true,
                labelText: draft.flavour,
                hintText: l10n.priceSheetRowLabelHint,
                border: const OutlineInputBorder(),
              ),
              style: draft.enabled
                  ? null
                  : TextStyle(color: theme.disabledColor),
            ),
          ),
          Switch(value: draft.enabled, onChanged: editable ? onEnabled : null),
          if (editable) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.priceSheetMoveUp,
              icon: const Icon(Icons.arrow_upward, size: 18),
              onPressed: canMoveUp ? onMoveUp : null,
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.priceSheetMoveDown,
              icon: const Icon(Icons.arrow_downward, size: 18),
              onPressed: canMoveDown ? onMoveDown : null,
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.priceSheetRemove,
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}

/// One term line. Always right-to-left: the terms are Arabic whatever the
/// app's language, exactly as they print on the sheet.
class _TermField extends StatelessWidget {
  const _TermField({
    super.key,
    required this.index,
    required this.controller,
    required this.editable,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final int index;
  final TextEditingController controller;
  final bool editable;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              key: ValueKey('price-sheet-term-$index'),
              controller: controller,
              enabled: editable,
              minLines: 1,
              maxLines: 4,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (editable) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.priceSheetMoveUp,
              icon: const Icon(Icons.arrow_upward, size: 18),
              onPressed: canMoveUp ? onMoveUp : null,
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.priceSheetMoveDown,
              icon: const Icon(Icons.arrow_downward, size: 18),
              onPressed: canMoveDown ? onMoveDown : null,
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.priceSheetRemove,
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
