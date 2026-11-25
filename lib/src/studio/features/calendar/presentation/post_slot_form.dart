import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/studio_error.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../pieces/data/pieces_repository.dart';
import '../../pieces/pieces_strings.dart';
import '../../pieces/presentation/piece_form_widgets.dart';
import '../../pieces/presentation/piece_widgets.dart';
import '../calendar_strings.dart';
import '../data/calendar_repository.dart';
import '../state/cairo_format.dart';
import '../state/cairo_time.dart';

/// What the slot form does.
enum SlotFormMode {
  /// Give a piece a new slot (`calendar.post_set` without a post id).
  create,

  /// Change channel, version, slot, caption or who posts (`post_set`).
  edit,

  /// Only the day and time (`calendar.post_move`).
  move,
}

/// Opens the slot form full screen. Returns true when something was saved.
Future<bool?> showPostSlotForm(
  BuildContext context, {
  SocialPost? post,
  DateTime? initialDate,
  SlotFormMode? mode,
}) {
  return Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      builder: (_) => PostSlotForm(
        post: post,
        initialDate: initialDate,
        mode: mode ?? (post == null ? SlotFormMode.create : SlotFormMode.edit),
      ),
    ),
  );
}

/// Add a post to a slot, change its slot, or move it. A refusal (the flavour
/// is not live that day, a check fails) shows in plain words and nothing is
/// saved.
class PostSlotForm extends ConsumerStatefulWidget {
  const PostSlotForm({
    super.key,
    this.post,
    this.initialDate,
    this.mode = SlotFormMode.create,
  });

  final SocialPost? post;
  final DateTime? initialDate;
  final SlotFormMode mode;

  @override
  ConsumerState<PostSlotForm> createState() => _PostSlotFormState();
}

class _PostSlotFormState extends ConsumerState<PostSlotForm> {
  final _caption = TextEditingController();
  PieceSummary? _piece;
  List<PieceVersion> _versions = const [];
  String? _versionId;
  PostChannel? _channel;
  PostingMode? _mode;
  DateTime? _date;
  TimeOfDay? _time;
  bool _saving = false;
  String? _error;
  List<StudioProblem> _problems = const [];
  String? _pieceError;
  String? _channelError;
  String? _dateError;
  final String _requestId = const Uuid().v4();

  bool get _isCreate => widget.mode == SlotFormMode.create;
  bool get _isMove => widget.mode == SlotFormMode.move;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    if (p != null) {
      _caption.text = p.caption ?? '';
      _channel = p.channel;
      _mode = p.postingMode;
      _versionId = p.versionId;
      final d = CairoTime.parse(p.slotTime);
      if (d != null) {
        _date = DateTime(d.year, d.month, d.day);
        _time = TimeOfDay(hour: d.hour, minute: d.minute);
      }
      if (p.piece != null) _loadVersions(p.piece!.id);
    } else if (widget.initialDate != null) {
      final d = widget.initialDate!;
      _date = DateTime(d.year, d.month, d.day);
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _loadVersions(String pieceId) async {
    try {
      final full = await ref.read(piecesRepositoryProvider).get(pieceId);
      if (!mounted) return;
      final versions = [...full.versions.where((v) => !v.hidden)]
        ..sort((a, b) => b.versionNo.compareTo(a.versionNo));
      setState(() {
        _versions = versions;
        _versionId ??= versions
            .where((v) => v.reviewOutcome == ReviewOutcome.approved)
            .followedBy(versions.where((v) => v.isCurrent))
            .map((v) => v.id)
            .firstOrNull;
        if (_versionId != null && !versions.any((v) => v.id == _versionId)) {
          _versionId = versions.isEmpty ? null : versions.first.id;
        }
      });
    } catch (_) {
      // The version list stays empty; the server still checks the write.
    }
  }

  PostChannel? _channelFor(PieceFormat f) => switch (f) {
    PieceFormat.reel => PostChannel.feedReel,
    PieceFormat.trial => PostChannel.trialReel,
    PieceFormat.staticValue => PostChannel.feedStatic,
    PieceFormat.carousel => PostChannel.feedCarousel,
    PieceFormat.story => PostChannel.story,
    PieceFormat.unknown => null,
  };

  Future<void> _pickPiece() async {
    final picked = await showModalBottomSheet<PieceSummary>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => const _PiecePicker(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _piece = picked;
      _versionId = null;
      _versions = const [];
      _pieceError = null;
      _channel ??= _channelFor(picked.format);
    });
    await _loadVersions(picked.id);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 13, minute: 0),
    );
    if (t != null) setState(() => _time = t);
  }

  Future<void> _save() async {
    final c = CalendarStrings.of(context);
    setState(() {
      _error = null;
      _problems = const [];
      _pieceError = _isCreate && _piece == null ? c.pieceNeeded : null;
      _channelError = !_isMove && _channel == null ? c.channelNeeded : null;
      _dateError = _date == null || _time == null ? c.dateNeeded : null;
    });
    if (_pieceError != null || _channelError != null || _dateError != null) {
      return;
    }
    final slot = CairoTime.wire(
      DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
        _time!.hour,
        _time!.minute,
      ),
    );
    setState(() => _saving = true);
    final repo = ref.read(calendarRepositoryProvider);
    try {
      final PostResult result;
      if (_isMove) {
        result = await repo.postMove(
          widget.post!.id,
          slot,
          baseModified: widget.post!.modified,
          requestId: _requestId,
        );
      } else {
        result = await repo.postSet(
          postId: widget.post?.id,
          pieceId: _isCreate ? _piece!.id : widget.post?.piece?.id,
          versionId: _versionId,
          channel: _channel?.wire,
          slotTime: slot,
          caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
          postingMode: _mode?.wire,
          baseModified: widget.post?.modified,
          requestId: _requestId,
        );
      }
      ref.invalidate(calendarRangeProvider);
      ref.invalidate(postDriftProvider);
      ref.invalidate(postChecksProvider);
      if (!mounted) return;
      final warn = result.warnings.map((w) => w.message).join('\n');
      showSnack(context, warn.isEmpty ? c.slotSaved : '${c.slotSaved}\n$warn');
      Navigator.of(context).pop(true);
    } on StudioGateFailed catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _problems = e.problems;
        if (e.problems.isEmpty) _error = e.message;
      });
    } on StudioValidation catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        switch (e.field) {
          case 'piece_id':
            _pieceError = e.message;
          case 'channel':
            _channelError = e.message;
          case 'slot_time':
            _dateError = e.message;
          default:
            _error = e.message;
        }
      });
    } on StudioStale catch (e) {
      if (!mounted) return;
      showSnack(context, c.error(e));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = c.error(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    final names = PiecesStrings.of(context);
    final ar = isArabic(context);
    final title = switch (widget.mode) {
      SlotFormMode.create => c.formCreateTitle,
      SlotFormMode.edit => c.formEditTitle,
      SlotFormMode.move => c.formMoveTitle,
    };
    final pieceTitleText = _isCreate
        ? (_piece == null ? null : pieceTitle(context, _piece!))
        : widget.post?.piece?.title ?? widget.post?.title;

    return ViewEditScaffold(
      title: title,
      actions: [
        TextButton(
          key: const ValueKey('slot-save'),
          onPressed: _saving ? null : _save,
          child: Text(c.saveSlot),
        ),
      ],
      body: ListView(
        key: const ValueKey('slot-form'),
        padding: const EdgeInsets.all(StudioSpacing.gutter),
        children: [
          if (_problems.isNotEmpty || _error != null)
            Container(
              key: const ValueKey('slot-problems'),
              margin: const EdgeInsets.only(bottom: StudioSpacing.lg),
              padding: const EdgeInsets.all(StudioSpacing.md),
              decoration: BoxDecoration(
                color: StudioColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(StudioRadii.md),
                border: Border.all(
                  color: StudioColors.danger.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_problems.isNotEmpty) ...[
                    Text(
                      c.problemsHeading,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: StudioSpacing.sm),
                    ProblemChecklist(problems: _problems),
                  ] else
                    Text(_error!),
                ],
              ),
            ),
          // Piece.
          Padding(
            padding: const EdgeInsets.only(bottom: StudioSpacing.md),
            child: _isCreate
                ? OutlinedButton.icon(
                    key: const ValueKey('slot-piece'),
                    icon: const Icon(Icons.search),
                    onPressed: _pickPiece,
                    label: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        pieceTitleText == null
                            ? '${c.fieldPiece}: ${c.pickPiece}'
                            : '${c.fieldPiece}: $pieceTitleText',
                      ),
                    ),
                  )
                : InputDecorator(
                    decoration: InputDecoration(labelText: c.fieldPiece),
                    child: Text(pieceTitleText ?? ''),
                  ),
          ),
          if (_pieceError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: StudioSpacing.md),
              child: Text(
                _pieceError!,
                key: const ValueKey('slot-piece-error'),
                style: const TextStyle(color: StudioColors.danger),
              ),
            ),
          if (!_isMove && _versions.isNotEmpty)
            OptionDropdown<String>(
              key: const ValueKey('slot-version'),
              label: c.fieldVersion,
              value: _versionId,
              items: [
                for (final v in _versions)
                  (
                    v.id,
                    '${names.versionNo(v.versionNo)} · ${names.reviewOutcome(v.reviewOutcome)}',
                  ),
              ],
              onChanged: (v) => setState(() => _versionId = v),
            ),
          if (!_isMove)
            OptionDropdown<PostChannel>(
              key: const ValueKey('slot-channel'),
              label: c.fieldChannel,
              value: _channel,
              errorText: _channelError,
              items: [
                for (final ch in PostChannel.values)
                  if (ch != PostChannel.unknown) (ch, names.channel(ch)),
              ],
              onChanged: (v) => setState(() => _channel = v),
            ),
          // Day and time.
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('slot-date'),
                  icon: const Icon(Icons.event_outlined),
                  onPressed: _pickDate,
                  label: Text(
                    _date == null ? c.fieldDate : CairoFormat.full(_date!, ar),
                  ),
                ),
              ),
              const SizedBox(width: StudioSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('slot-time'),
                  icon: const Icon(Icons.schedule),
                  onPressed: _pickTime,
                  label: Text(
                    _time == null
                        ? c.fieldTime
                        : CairoTime.time(
                            DateTime(0, 1, 1, _time!.hour, _time!.minute),
                          ),
                  ),
                ),
              ),
            ],
          ),
          if (_dateError != null)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.xs),
              child: Text(
                _dateError!,
                key: const ValueKey('slot-date-error'),
                style: const TextStyle(color: StudioColors.danger),
              ),
            ),
          const SizedBox(height: StudioSpacing.md),
          if (!_isMove) ...[
            OptionDropdown<PostingMode>(
              key: const ValueKey('slot-mode'),
              label: c.fieldMode,
              value: _mode,
              noneLabel: c.names.none,
              items: [
                for (final m in PostingMode.values)
                  if (m != PostingMode.unknown) (m, names.postingMode(m)),
              ],
              onChanged: (v) => setState(() => _mode = v),
            ),
            FormText(
              key: const ValueKey('slot-caption'),
              controller: _caption,
              label: c.fieldCaption,
              maxLines: 8,
            ),
          ],
        ],
      ),
    );
  }
}

/// A sheet to find a piece: approved ones first, or search by title or old
/// number.
class _PiecePicker extends ConsumerStatefulWidget {
  const _PiecePicker();

  @override
  ConsumerState<_PiecePicker> createState() => _PiecePickerState();
}

class _PiecePickerState extends ConsumerState<_PiecePicker> {
  final _q = TextEditingController();
  late Future<PieceSummaryPage> _results = _search('');

  Future<PieceSummaryPage> _search(String q) => ref
      .read(piecesRepositoryProvider)
      .list(
        stage: q.isEmpty ? PieceStage.approved.wire : null,
        q: q.isEmpty ? null : q,
      );

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = CalendarStrings.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StudioSpacing.gutter,
                ),
                child: TextField(
                  key: const ValueKey('picker-search'),
                  controller: _q,
                  decoration: InputDecoration(
                    hintText: c.searchPieces,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                  ),
                  onSubmitted: (v) =>
                      setState(() => _results = _search(v.trim())),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(StudioSpacing.sm),
                child: Text(
                  c.approvedPieces,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: FutureBuilder<PieceSummaryPage>(
                  future: _results,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          PiecesStrings.of(context).error(snap.error!),
                        ),
                      );
                    }
                    final items = snap.data!.items;
                    return ListView(
                      children: [
                        for (final p in items)
                          ListTile(
                            key: ValueKey('picker-${p.id}'),
                            title: Text(pieceTitle(context, p)),
                            subtitle: Text(stageName(context, p.stage)),
                            onTap: () => Navigator.of(context).pop(p),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
