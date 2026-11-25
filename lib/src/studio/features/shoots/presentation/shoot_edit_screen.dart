import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/studio_api.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/how_this_works_sheet.dart';
import '../shoots_strings.dart';
import '../state/on_set_state.dart';
import 'shoot_widgets.dart';

/// `/shoots/new` and `/shoots/:id/edit`: plan a shoot or change its plan
/// (founder and marketing lead). Saving never overwrites someone else's
/// newer edit: the screen then shows their version and asks to save again.
class ShootEditScreen extends ConsumerStatefulWidget {
  const ShootEditScreen({super.key, this.shootId});

  /// Null plans a new shoot.
  final String? shootId;

  @override
  ConsumerState<ShootEditScreen> createState() => _ShootEditScreenState();
}

class _ShootEditScreenState extends ConsumerState<ShootEditScreen> {
  final title = TextEditingController();
  final place = TextEditingController();
  final people = TextEditingController();
  final kit = TextEditingController();
  final notes = TextEditingController();
  String? date;
  String? time;
  ShootStatus? status;
  StudioShoot? original;
  final errors = <String, String>{};
  String? banner;
  var busy = false;
  var ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final id = widget.shootId;
    if (id != null) {
      final c = ref.read(onSetProvider.notifier);
      await c.ensureLoaded();
      var s = ref.read(onSetProvider).shoot(id);
      s ??= await c.openShoot(id);
      _fill(s);
    }
    if (mounted) setState(() => ready = true);
  }

  void _fill(StudioShoot s) {
    original = s;
    title.text = s.title;
    place.text = s.place ?? '';
    people.text = s.people ?? '';
    kit.text = s.kit ?? '';
    notes.text = s.notes ?? '';
    date = s.shootDate;
    time = s.shootTime;
    status = s.status;
  }

  @override
  void dispose() {
    for (final c in [title, place, people, kit, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _nz(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> save() async {
    final t = ShootStrings.of(context);
    errors.clear();
    banner = null;
    if (title.text.trim().isEmpty) {
      setState(() => errors['title'] = t.titleRequired);
      return;
    }
    setState(() => busy = true);
    final c = ref.read(onSetProvider.notifier);
    try {
      final id = widget.shootId;
      if (id == null) {
        final s = await ref
            .read(studioApiProvider)
            .shootsCreate(
              title: title.text.trim(),
              shootDate: date,
              shootTime: time,
              place: _nz(place.text),
              people: _nz(people.text),
              kit: _nz(kit.text),
              notes: _nz(notes.text),
              requestId: _createRequestId,
            );
        await c.remember(s);
        if (!mounted) return;
        context.go('/shoots/${s.id}');
      } else {
        final o = original!;
        final fields = <String, dynamic>{
          if (title.text.trim() != o.title) 'title': title.text.trim(),
          if (date != o.shootDate) 'shoot_date': date,
          if (time != o.shootTime) 'shoot_time': time,
          if ((_nz(place.text) ?? '') != (o.place ?? '')) 'place': place.text.trim(),
          if ((_nz(people.text) ?? '') != (o.people ?? '')) 'people': people.text.trim(),
          if ((_nz(kit.text) ?? '') != (o.kit ?? '')) 'kit': kit.text.trim(),
          if ((_nz(notes.text) ?? '') != (o.notes ?? '')) 'notes': notes.text.trim(),
          if (status != null && status != o.status) 'status': status!.wire,
        };
        if (fields.isNotEmpty) await c.update(id, fields);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(t.saved)));
        context.pop();
      }
    } on StudioStale catch (e) {
      // Someone else saved first: show their version, keep the person's say.
      try {
        final fresh = StudioShoot.fromJson(
          Map<String, dynamic>.from(e.current as Map),
        );
        await c.remember(fresh);
        _fill(fresh);
      } catch (_) {}
      if (mounted) setState(() => banner = t.changedMeanwhile);
    } on StudioValidation catch (e) {
      if (mounted) {
        setState(() {
          if (e.field != null && e.field!.isNotEmpty) {
            errors[e.field!] = e.message;
          } else {
            banner = e.message;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => banner = shootErrorText(t, e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// One key per form, so a retry after a lost answer cannot plan it twice.
  final _createRequestId = newRequestId();

  Future<void> pickDate() async {
    final now = DateTime.now();
    final cur = date == null ? null : DateTime.tryParse(date!);
    final d = await showDatePicker(
      context: context,
      initialDate: cur ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (d != null) {
      setState(
        () => date =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> pickTime() async {
    final parts = time?.split(':');
    final init = parts != null && parts.length >= 2
        ? TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 9,
            minute: int.tryParse(parts[1]) ?? 0,
          )
        : const TimeOfDay(hour: 9, minute: 0);
    final p = await showTimePicker(context: context, initialTime: init);
    if (p != null) {
      setState(
        () => time =
            '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ShootStrings.of(context);
    final isNew = widget.shootId == null;
    Widget text(
      TextEditingController c,
      String label,
      String field, {
      int lines = 1,
      Key? key,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.md),
      child: TextField(
        key: key,
        controller: c,
        minLines: lines,
        maxLines: lines + 2,
        decoration: InputDecoration(
          labelText: label,
          errorText: errors[field],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(isNew ? '/shoots' : '/shoots/${widget.shootId}'),
        ),
        title: Text(isNew ? t.newTitle : t.editTitle),
        actions: [
          IconButton(
            key: const ValueKey('help'),
            icon: const Icon(Icons.help_outline),
            onPressed: () => HowThisWorksSheet.show(
              context,
              title: t.editHelpTitle,
              lines: t.editHelp,
            ),
          ),
        ],
      ),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : ShootPage(
              child: ListView(
                padding: const EdgeInsets.all(StudioSpacing.gutter),
                children: [
                  if (banner != null)
                    Container(
                      key: const ValueKey('edit-banner'),
                      margin: const EdgeInsets.only(bottom: StudioSpacing.md),
                      padding: const EdgeInsets.all(StudioSpacing.md),
                      decoration: BoxDecoration(
                        color: StudioColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(StudioRadii.md),
                      ),
                      child: Text(banner!),
                    ),
                  text(title, t.fieldTitle, 'title', key: const ValueKey('f-title')),
                  Row(
                    children: [
                      Expanded(
                        child: _PickField(
                          key: const ValueKey('f-date'),
                          label: t.fieldDate,
                          value: date == null ? null : t.dateLabel(date, null),
                          hint: t.pickDate,
                          error: errors['shoot_date'],
                          onTap: pickDate,
                          onClear: date == null
                              ? null
                              : () => setState(() => date = null),
                        ),
                      ),
                      const SizedBox(width: StudioSpacing.md),
                      Expanded(
                        child: _PickField(
                          key: const ValueKey('f-time'),
                          label: t.fieldTime,
                          value: time,
                          hint: t.pickTime,
                          error: errors['shoot_time'],
                          onTap: pickTime,
                          onClear: time == null
                              ? null
                              : () => setState(() => time = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: StudioSpacing.md),
                  text(place, t.fieldPlace, 'place', key: const ValueKey('f-place')),
                  text(people, t.fieldPeople, 'people'),
                  text(kit, t.fieldKit, 'kit', lines: 2),
                  text(notes, t.fieldNotes, 'notes', lines: 2),
                  if (!isNew && original != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: StudioSpacing.md),
                      child: DropdownButtonFormField<ShootStatus>(
                        key: const ValueKey('f-status'),
                        isExpanded: true,
        initialValue: status,
                        decoration: InputDecoration(
                          labelText: t.fieldStatus,
                          errorText: errors['status'],
                        ),
                        items: [
                          for (final s in ShootStatus.values)
                            if (s != ShootStatus.unknown)
                              DropdownMenuItem(value: s, child: Text(t.status(s))),
                        ],
                        onChanged: (v) => setState(() => status = v),
                      ),
                    ),
                  const SizedBox(height: StudioSpacing.sm),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      key: const ValueKey('f-save'),
                      onPressed: busy ? null : save,
                      child: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(t.save),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PickField extends StatelessWidget {
  const _PickField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.onClear,
    this.error,
  });
  final String label;
  final String? value;
  final String hint;
  final String? error;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          suffixIcon: onClear == null
              ? const Icon(Icons.expand_more)
              : IconButton(icon: const Icon(Icons.close), onPressed: onClear),
        ),
        child: Text(value ?? hint),
      ),
    );
  }
}
