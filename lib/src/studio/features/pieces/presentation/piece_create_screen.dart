import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/studio_error.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../data/pieces_repository.dart';
import '../pieces_strings.dart';
import '../state/piece_filters.dart';
import 'piece_form_widgets.dart';
import 'piece_widgets.dart';

/// "New piece": a piece always starts at Idea. Pops with the new id.
class PieceCreateScreen extends ConsumerStatefulWidget {
  const PieceCreateScreen({super.key});

  @override
  ConsumerState<PieceCreateScreen> createState() => _PieceCreateScreenState();
}

class _PieceCreateScreenState extends ConsumerState<PieceCreateScreen> {
  final _title = TextEditingController();
  final _titleAr = TextEditingController();
  final _note = TextEditingController();
  PieceFormat? _format;
  Persona? _persona;
  Situation? _situation;
  ContentLayer? _layer;
  Set<String> _flavours = {};
  String? _owner;
  String? _due;
  String? _titleError;
  String? _formatError;
  bool _saving = false;

  // One key per attempt, so a retry after a dropped answer cannot make two.
  final String _requestId = const Uuid().v4();

  @override
  void dispose() {
    _title.dispose();
    _titleAr.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = PiecesStrings.of(context);
    setState(() {
      _titleError = _title.text.trim().isEmpty ? s.titleNeeded : null;
      _formatError = _format == null ? s.formatNeeded : null;
    });
    if (_titleError != null || _formatError != null) return;
    setState(() => _saving = true);
    try {
      final (assignee, _) = OwnerDropdown.split(_owner);
      final piece = await ref
          .read(piecesRepositoryProvider)
          .create(
            title: _title.text.trim(),
            format: _format!.wire,
            titleAr: _titleAr.text.trim().isEmpty ? null : _titleAr.text.trim(),
            persona: _persona?.wire,
            situation: _situation?.wire,
            layer: _layer?.wire,
            flavourIds: _flavours.isEmpty ? null : _flavours.toList(),
            assignee: assignee,
            dueDate: _due,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            requestId: _requestId,
          );
      ref.invalidate(pieceBoardProvider);
      ref.invalidate(pieceListProvider);
      if (!mounted) return;
      showSnack(context, s.createdDone);
      Navigator.of(context).pop(piece.id);
    } on StudioValidation catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e.field == 'title') {
          _titleError = e.message;
        } else if (e.field == 'format') {
          _formatError = e.message;
        } else {
          showSnack(context, s.error(e));
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(context, s.error(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    return ViewEditScaffold(
      title: s.createTitle,
      actions: [
        TextButton(
          key: const ValueKey('create-save'),
          onPressed: _saving ? null : _save,
          child: Text(s.create),
        ),
      ],
      body: ListView(
        key: const ValueKey('create-form'),
        padding: const EdgeInsets.all(StudioSpacing.gutter),
        children: [
          FormText(
            key: const ValueKey('create-title'),
            controller: _title,
            label: s.fieldTitle,
            errorText: _titleError,
          ),
          FormText(controller: _titleAr, label: s.fieldTitleAr, rtl: true),
          OptionDropdown<PieceFormat>(
            key: const ValueKey('create-format'),
            label: s.fieldFormat,
            value: _format,
            errorText: _formatError,
            items: [
              for (final f in PieceFormat.values)
                if (f != PieceFormat.unknown) (f, s.format(f)),
            ],
            onChanged: (v) => setState(() => _format = v),
          ),
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
          FlavourChips(
            selected: _flavours,
            onChanged: (v) => setState(() => _flavours = v),
          ),
          OwnerDropdown(
            allowTeams: false,
            value: _owner,
            onChanged: (v) => setState(() => _owner = v),
          ),
          DateField(
            label: s.fieldDue,
            value: _due,
            onChanged: (v) => setState(() => _due = v),
          ),
          FormText(controller: _note, label: s.fieldNote, maxLines: 4),
        ],
      ),
    );
  }
}
