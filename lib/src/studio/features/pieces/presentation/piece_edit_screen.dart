import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/studio_error.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../data/pieces_repository.dart';
import '../pieces_strings.dart';
import '../state/piece_filters.dart';
import 'piece_form_widgets.dart';
import 'piece_widgets.dart';

/// The edit form of a piece (the pencil). Which parts show depends on the
/// piece's `actions`: `edit` for title, labels and script, `assign` for owner
/// and due date. On STALE the fresh copy is already in the notifier; the
/// person's changes are put on top of it and sent once more.
///
/// The form is built only once the piece has arrived: before that (or when the
/// load failed) the screen shows the loading or error state, never a blank page.
class PieceEditScreen extends ConsumerWidget {
  const PieceEditScreen({super.key, required this.pieceId});

  final String pieceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(pieceProvider(pieceId));
    final t = StudioStrings.of(context);
    final copy = t.screen(StudioScreen.piece);
    final piece = value.valueOrNull;
    if (piece != null) return _PieceEditForm(pieceId: pieceId, piece: piece);
    return ViewEditScaffold(
      title: PiecesStrings.of(context).editTitle,
      body: StudioAsyncView<StudioPiece>(
        value: value,
        onRetry: () => ref.invalidate(pieceProvider(pieceId)),
        isEmpty: (_) => false,
        empty: StudioEmptyConfig(
          purpose: copy.purpose,
          firstStep: copy.firstStep,
        ),
        builder: (context, p) => const SizedBox.shrink(),
      ),
    );
  }
}

class _PieceEditForm extends ConsumerStatefulWidget {
  const _PieceEditForm({required this.pieceId, required this.piece});

  final String pieceId;
  final StudioPiece piece;

  @override
  ConsumerState<_PieceEditForm> createState() => _PieceEditScreenState();
}

class _LineEdit {
  _LineEdit(String t, String line, this.lang)
    : time = TextEditingController(text: t),
      text = TextEditingController(text: line);
  ScriptLang lang;
  final TextEditingController time;
  final TextEditingController text;
  void dispose() {
    time.dispose();
    text.dispose();
  }
}

class _PieceEditScreenState extends ConsumerState<_PieceEditForm> {
  late final StudioPiece _orig;
  late final TextEditingController _title;
  late final TextEditingController _titleAr;
  late final TextEditingController _series;
  late final TextEditingController _own;
  late final TextEditingController _adCopy;
  late final TextEditingController _note;
  late final TextEditingController _why;
  late final TextEditingController _opening;
  late final TextEditingController _length;
  late final TextEditingController _screenAr;
  late final TextEditingController _screenEn;
  late final TextEditingController _notes;
  late final List<_LineEdit> _lines;
  Persona? _persona;
  Situation? _situation;
  ContentLayer? _layer;
  PieceUse? _use;
  int? _level;
  late Set<String> _flavours;
  String? _owner;
  String? _due;
  String? _titleError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.piece;
    _orig = p;
    _title = TextEditingController(text: p.title);
    _titleAr = TextEditingController(text: p.titleAr ?? '');
    _series = TextEditingController(text: p.series ?? '');
    _own = TextEditingController(text: p.ownText ?? '');
    _adCopy = TextEditingController(text: p.adCopy ?? '');
    _note = TextEditingController(text: p.note ?? '');
    _why = TextEditingController(text: p.why ?? '');
    _opening = TextEditingController(text: p.script.opening ?? '');
    _length = TextEditingController(text: p.script.length ?? '');
    _screenAr = TextEditingController(text: p.script.screenAr ?? '');
    _screenEn = TextEditingController(text: p.script.screenEn ?? '');
    _notes = TextEditingController(text: p.script.notes ?? '');
    _lines = [
      for (final l in p.script.lines) _LineEdit(l.t ?? '', l.line, l.lang),
    ];
    _persona = p.persona == Persona.unknown ? null : p.persona;
    _situation = p.situation == Situation.unknown ? null : p.situation;
    _layer = p.layer == ContentLayer.unknown ? null : p.layer;
    _use = p.use == PieceUse.unknown ? null : p.use;
    _level = p.level;
    _flavours = {for (final f in p.flavours) f.id};
    _owner = OwnerDropdown.of(p.assignee, p.assigneeTeam);
    _due = p.dueDate;
  }

  @override
  void dispose() {
    for (final c in [
      _title, _titleAr, _series, _own, _adCopy, _note, _why, //
      _opening, _length, _screenAr, _screenEn, _notes,
    ]) {
      c.dispose();
    }
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  /// The fields that differ from the copy the form opened with.
  Map<String, dynamic> _changedFields() {
    final o = _orig;
    final f = <String, dynamic>{};
    void text(String key, TextEditingController c, String? old) {
      if (c.text.trim() != (old ?? '')) f[key] = _nullIfEmpty(c.text);
    }

    text('title', _title, o.title);
    text('title_ar', _titleAr, o.titleAr);
    text('series', _series, o.series);
    text('own_text', _own, o.ownText);
    text('ad_copy', _adCopy, o.adCopy);
    text('note', _note, o.note);
    text('why', _why, o.why);
    if (_persona != (o.persona == Persona.unknown ? null : o.persona)) {
      f['persona'] = _persona?.wire;
    }
    if (_situation != (o.situation == Situation.unknown ? null : o.situation)) {
      f['situation'] = _situation?.wire;
    }
    if (_layer != (o.layer == ContentLayer.unknown ? null : o.layer)) {
      f['layer'] = _layer?.wire;
    }
    if (_use != (o.use == PieceUse.unknown ? null : o.use)) {
      f['use'] = _use?.wire;
    }
    if (_level != o.level) f['level'] = _level;
    final oldFlavours = {for (final x in o.flavours) x.id};
    if (_flavours.length != oldFlavours.length ||
        !_flavours.containsAll(oldFlavours)) {
      f['flavour_ids'] = _flavours.toList();
    }

    final lines = [
      for (final l in _lines)
        if (l.text.text.trim().isNotEmpty)
          {
            'lang': l.lang.wire,
            't': _nullIfEmpty(l.time.text),
            'line': l.text.text.trim(),
          },
    ];
    final oldLines = [
      for (final l in o.script.lines)
        {'lang': l.lang.wire, 't': l.t, 'line': l.line},
    ];
    final scriptChanged =
        _opening.text.trim() != (o.script.opening ?? '') ||
        _length.text.trim() != (o.script.length ?? '') ||
        _screenAr.text.trim() != (o.script.screenAr ?? '') ||
        _screenEn.text.trim() != (o.script.screenEn ?? '') ||
        _notes.text.trim() != (o.script.notes ?? '') ||
        lines.toString() != oldLines.toString();
    if (scriptChanged) {
      f['script'] = {
        'length': _nullIfEmpty(_length.text),
        'opening': _nullIfEmpty(_opening.text),
        'screen_ar': _nullIfEmpty(_screenAr.text),
        'screen_en': _nullIfEmpty(_screenEn.text),
        'block': o.script.block,
        'holds': o.script.holds,
        'notes': _nullIfEmpty(_notes.text),
        'lines': lines,
      };
    }
    return f;
  }

  Future<void> _save() async {
    final s = PiecesStrings.of(context);
    final canEdit = _orig.actions.contains('edit');
    final canAssign = _orig.actions.contains('assign');
    if (canEdit && _title.text.trim().isEmpty) {
      setState(() => _titleError = s.titleNeeded);
      return;
    }
    final fields = canEdit ? _changedFields() : <String, dynamic>{};
    final ownerChanged =
        canAssign &&
        _owner != OwnerDropdown.of(_orig.assignee, _orig.assigneeTeam);
    final dueChanged = canAssign && _due != _orig.dueDate;
    if (fields.isEmpty && !ownerChanged && !dueChanged) {
      showSnack(context, s.noChanges);
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = true;
      _titleError = null;
    });
    final notifier = ref.read(pieceProvider(widget.pieceId).notifier);
    var reapplied = false;

    Future<void> run(Future<void> Function() op) async {
      try {
        await op();
      } on StudioStale {
        // The notifier already holds the fresh piece: send ours on top of it.
        reapplied = true;
        await op();
      }
    }

    try {
      if (fields.isNotEmpty) await run(() => notifier.edit(fields));
      if (ownerChanged || dueChanged) {
        final (assignee, team) = OwnerDropdown.split(_owner);
        await run(
          () => notifier.assign(
            assignee: assignee,
            assigneeTeam: team,
            dueDate: _due,
          ),
        );
      }
      ref.invalidate(pieceBoardProvider);
      ref.invalidate(pieceListProvider);
      if (!mounted) return;
      showSnack(context, reapplied ? s.staleReapplied : s.savedDone);
      Navigator.of(context).pop();
    } on StudioValidation catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e.field == 'title') _titleError = e.message;
      });
      if (e.field != 'title') showSnack(context, s.error(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, s.error(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    final canEdit = _orig.actions.contains('edit');
    final canAssign = _orig.actions.contains('assign');
    return ViewEditScaffold(
      title: s.editTitle,
      actions: [
        TextButton(
          key: const ValueKey('edit-save'),
          onPressed: _saving ? null : _save,
          child: Text(s.save),
        ),
      ],
      body: ListView(
        key: const ValueKey('edit-form'),
        padding: const EdgeInsets.all(StudioSpacing.gutter),
        children: [
          if (canEdit) ...[
            FormText(
              key: const ValueKey('edit-title'),
              controller: _title,
              label: s.fieldTitle,
              errorText: _titleError,
            ),
            FormText(controller: _titleAr, label: s.fieldTitleAr, rtl: true),
            OptionDropdown<Persona>(
              label: s.fieldPersona,
              value: _persona,
              noneLabel: s.none,
              items: [
                for (final p in Persona.values)
                  if (p != Persona.unknown) (p, s.persona(p)),
              ],
              onChanged: (v) => setState(() => _persona = v),
            ),
            OptionDropdown<Situation>(
              label: s.fieldSituation,
              value: _situation,
              noneLabel: s.none,
              items: [
                for (final x in Situation.values)
                  if (x != Situation.unknown) (x, s.situation(x)),
              ],
              onChanged: (v) => setState(() => _situation = v),
            ),
            OptionDropdown<ContentLayer>(
              label: s.fieldLayer,
              value: _layer,
              noneLabel: s.none,
              items: [
                for (final l in ContentLayer.values)
                  if (l != ContentLayer.unknown) (l, s.layer(l)),
              ],
              onChanged: (v) => setState(() => _layer = v),
            ),
            OptionDropdown<int>(
              label: s.fieldLevel,
              value: _level,
              noneLabel: s.none,
              items: [for (var i = 1; i <= 5; i++) (i, '$i')],
              onChanged: (v) => setState(() => _level = v),
            ),
            OptionDropdown<PieceUse>(
              label: s.fieldUse,
              value: _use,
              noneLabel: s.none,
              items: [
                for (final u in PieceUse.values)
                  if (u != PieceUse.unknown) (u, s.use(u)),
              ],
              onChanged: (v) => setState(() => _use = v),
            ),
            FormText(controller: _series, label: s.fieldSeries),
            FlavourChips(
              selected: _flavours,
              onChanged: (v) => setState(() => _flavours = v),
            ),
          ],
          if (canAssign) ...[
            OwnerDropdown(
              value: _owner,
              onChanged: (v) => setState(() => _owner = v),
            ),
            DateField(
              label: s.fieldDue,
              value: _due,
              onChanged: (v) => setState(() => _due = v),
            ),
          ],
          if (canEdit) ...[
            SectionTitle(s.sectionScript),
            FormText(controller: _opening, label: s.opening, maxLines: 3),
            FormText(controller: _length, label: s.length),
            FormText(
              controller: _screenAr,
              label: s.onScreenAr,
              maxLines: 3,
              rtl: true,
            ),
            FormText(controller: _screenEn, label: s.onScreenEn, maxLines: 3),
            for (final (i, l) in _lines.indexed)
              Column(
                key: ValueKey('script-line-$i'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 84,
                        child: FormText(controller: l.time, label: s.lineTime),
                      ),
                      const SizedBox(width: StudioSpacing.sm),
                      Expanded(
                        child: OptionDropdown<ScriptLang>(
                          label: s.lineLang,
                          value: l.lang,
                          items: [
                            for (final x in ScriptLang.values)
                              if (x != ScriptLang.unknown) (x, s.scriptLang(x)),
                          ],
                          onChanged: (v) =>
                              setState(() => l.lang = v ?? l.lang),
                        ),
                      ),
                      IconButton(
                        key: ValueKey('script-line-remove-$i'),
                        tooltip: s.removeLine,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          final gone = _lines[i];
                          setState(() => _lines.removeAt(i));
                          // Dispose after the frame that stops using it.
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => gone.dispose(),
                          );
                        },
                      ),
                    ],
                  ),
                  FormText(
                    controller: l.text,
                    label: s.lineText,
                    maxLines: 4,
                    rtl: l.lang == ScriptLang.ar,
                  ),
                ],
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const ValueKey('script-line-add'),
                icon: const Icon(Icons.add),
                label: Text(s.addLine),
                onPressed: () => setState(
                  () => _lines.add(
                    _LineEdit(
                      '',
                      '',
                      isArabic(context) ? ScriptLang.ar : ScriptLang.en,
                    ),
                  ),
                ),
              ),
            ),
            FormText(controller: _notes, label: s.notes, maxLines: 3),
            FormText(controller: _own, label: s.ownText, maxLines: 3),
            FormText(controller: _adCopy, label: s.adCopy, maxLines: 3),
            FormText(controller: _why, label: s.fieldWhy, maxLines: 3),
            FormText(controller: _note, label: s.fieldNote, maxLines: 3),
          ],
        ],
      ),
    );
  }
}
