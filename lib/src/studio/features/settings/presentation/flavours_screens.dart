import '../../../data/api/studio_api_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../shell/more_common.dart';
import '../../shell/more_strings.dart';
import '../settings_strings.dart';
import '../state/settings_state.dart';

({Color fg, Color bg}) _statusColors(FlavourStatus s) => switch (s) {
  FlavourStatus.live => (
    fg: const Color(0xFF1F6B4A),
    bg: const Color(0xFFD7EFE2),
  ),
  FlavourStatus.paused => (
    fg: StudioColors.plumMuted,
    bg: const Color(0xFFF2EFF3),
  ),
  FlavourStatus.seasonal => (
    fg: const Color(0xFF7A5A12),
    bg: const Color(0xFFF5E8CC),
  ),
  FlavourStatus.coming => (
    fg: const Color(0xFF5A3E85),
    bg: const Color(0xFFE7DDF5),
  ),
  _ => (fg: StudioColors.deepPlum, bg: StudioColors.softBlush),
};

/// Every flavor with its marketing status and dates.
class FlavoursScreen extends ConsumerWidget {
  const FlavoursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = SettingsStrings.of(context);
    final value = ref.watch(flavoursListProvider);
    return ViewEditScaffold(
      title: t.flavoursTitle,
      parentRoute: '/more/settings',
      actions: [
        moreHelpAction(
          context,
          title: t.flavoursHelpTitle,
          lines: t.flavoursHelp,
        ),
      ],
      body: MoreBody(
        child: StudioAsyncView<List<StudioFlavour>>(
          value: value,
          onRetry: () => ref.invalidate(flavoursListProvider),
          empty: StudioEmptyConfig(
            purpose: t.flavoursEmptyPurpose,
            firstStep: t.flavoursEmptyFirstStep,
            icon: Icons.icecream_outlined,
          ),
          builder: (context, items) => ListView(
            key: const ValueKey('flavours-list'),
            padding: const EdgeInsets.only(bottom: StudioSpacing.xxl),
            children: [
              for (final f in items)
                MoreCard(
                  key: ValueKey('flavour-${f.id}'),
                  onTap: () => context.go('/more/settings/flavours/${f.id}'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.name,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            _Dates(f: f),
                          ],
                        ),
                      ),
                      MorePill(
                        t.statusLabel(f.status),
                        foreground: _statusColors(f.status).fg,
                        background: _statusColors(f.status).bg,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dates extends StatelessWidget {
  const _Dates({required this.f});

  final StudioFlavour f;

  @override
  Widget build(BuildContext context) {
    final t = SettingsStrings.of(context);
    final m = MoreStrings.of(context);
    if (f.availableFrom == null && f.availableTo == null) {
      return const SizedBox.shrink();
    }
    return Text(
      [
        if (f.availableFrom != null) m.date(f.availableFrom),
        if (f.availableTo != null) '${t.until} ${m.date(f.availableTo)}',
      ].join(' '),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

/// One flavor. The pencil edits its marketing status and dates; the prices
/// are read live from ERPNext and never typed.
class FlavourScreen extends ConsumerWidget {
  const FlavourScreen({super.key, required this.flavourId});

  final String flavourId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = SettingsStrings.of(context);
    final value = ref.watch(flavoursListProvider);
    final flavour = value.valueOrNull
        ?.where((f) => f.id == flavourId)
        .firstOrNull;

    return ViewEditScaffold(
      title: flavour?.name ?? t.flavourTitle,
      parentRoute: '/more/settings/flavours',
      onEdit: flavour != null && flavour.actions.contains('edit')
          ? () => _edit(context, ref, flavour)
          : null,
      actions: [
        moreHelpAction(
          context,
          title: t.flavoursHelpTitle,
          lines: t.flavoursHelp,
        ),
      ],
      body: MoreBody(
        child: StudioAsyncView<List<StudioFlavour>>(
          value: value,
          onRetry: () => ref.invalidate(flavoursListProvider),
          empty: StudioEmptyConfig(
            purpose: t.flavoursEmptyPurpose,
            firstStep: t.flavoursEmptyFirstStep,
          ),
          isEmpty: (items) => !items.any((f) => f.id == flavourId),
          builder: (context, items) =>
              _FlavourBody(f: items.firstWhere((f) => f.id == flavourId)),
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    StudioFlavour f,
  ) async {
    final result = await showDialog<_FlavourEdit>(
      context: context,
      builder: (_) => _EditDialog(f: f),
    );
    if (result == null || !context.mounted) return;
    final t = SettingsStrings.of(context);
    final m = MoreStrings.of(context);
    List<CheckRow> warnings = const [];
    try {
      warnings = await ref
          .read(flavoursListProvider.notifier)
          .change(
            f,
            status: result.status,
            availableFrom: result.from,
            availableTo: result.to,
            note: result.note,
          );
      showMoreSnack(t.flavourSaved);
    } catch (e) {
      showMoreSnack(moreErrorText(m, e));
      return;
    }
    if (warnings.isNotEmpty && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const ValueKey('flavour-warnings'),
          title: Text(t.flavourWarningsTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.flavourWarningsIntro),
              const SizedBox(height: StudioSpacing.sm),
              for (final w in warnings)
                Padding(
                  padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
                  child: Text('• ${w.message}'),
                ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(m.close),
            ),
          ],
        ),
      );
    }
  }
}

class _FlavourBody extends StatelessWidget {
  const _FlavourBody({required this.f});

  final StudioFlavour f;

  @override
  Widget build(BuildContext context) {
    final t = SettingsStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);
    final colors = _statusColors(f.status);
    String price(int? v) => v == null ? t.priceUnknown : m.egp(v);
    return ListView(
      key: const ValueKey('flavour-body'),
      padding: const EdgeInsets.only(bottom: StudioSpacing.xxl),
      children: [
        MoreCard(
          padding: const EdgeInsets.all(StudioSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MorePill(
                t.statusLabel(f.status),
                key: const ValueKey('flavour-status'),
                foreground: colors.fg,
                background: colors.bg,
              ),
              const SizedBox(height: StudioSpacing.md),
              LabeledValue(
                t.availableFrom,
                f.availableFrom == null ? t.notSet : m.date(f.availableFrom),
              ),
              LabeledValue(
                t.availableTo,
                f.availableTo == null ? t.notSet : m.date(f.availableTo),
              ),
            ],
          ),
        ),
        SectionLabel(t.prices),
        MoreCard(
          child: Column(
            children: [
              LabeledValue(t.priceMedium, price(f.prices?.medium)),
              LabeledValue(t.priceLarge, price(f.prices?.large)),
            ],
          ),
        ),
        if (f.note != null && f.note!.isNotEmpty) ...[
          SectionLabel(t.flavourNote),
          MoreCard(
            key: const ValueKey('flavour-note'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: StudioSpacing.sm),
                Expanded(
                  child: Text(f.note!, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FlavourEdit {
  const _FlavourEdit({this.status, this.from, this.to, this.note});

  final FlavourStatus? status;
  final String? from;
  final String? to;
  final String? note;
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.f});

  final StudioFlavour f;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late FlavourStatus _status = widget.f.status;
  late String? _from = widget.f.availableFrom;
  late String? _to = widget.f.availableTo;
  late final _note = TextEditingController(text: widget.f.note ?? '');

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(bool from) async {
    final cur = DateTime.tryParse((from ? _from : _to) ?? '') ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: cur,
      firstDate: DateTime(2025),
      lastDate: DateTime(2031),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = isoDate(picked);
      } else {
        _to = isoDate(picked);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = SettingsStrings.of(context);
    final m = MoreStrings.of(context);
    return AlertDialog(
      key: const ValueKey('flavour-dialog'),
      title: Text(t.editFlavour),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.statusField, style: Theme.of(context).textTheme.labelLarge),
            Wrap(
              spacing: StudioSpacing.sm,
              children: [
                for (final s in const [
                  FlavourStatus.live,
                  FlavourStatus.paused,
                  FlavourStatus.seasonal,
                  FlavourStatus.coming,
                ])
                  ChoiceChip(
                    key: ValueKey('flavour-status-${s.wire}'),
                    label: Text(t.statusLabel(s)),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
              ],
            ),
            const SizedBox(height: StudioSpacing.md),
            OutlinedButton.icon(
              key: const ValueKey('flavour-from'),
              icon: const Icon(Icons.event),
              label: Text(
                '${t.availableFrom}: ${_from == null ? t.notSet : m.date(_from)}',
              ),
              onPressed: () => _pick(true),
            ),
            if (_from != null)
              TextButton(
                key: const ValueKey('flavour-from-clear'),
                onPressed: () => setState(() => _from = null),
                child: Text(t.clearDate),
              ),
            OutlinedButton.icon(
              key: const ValueKey('flavour-to'),
              icon: const Icon(Icons.event),
              label: Text(
                '${t.availableTo}: ${_to == null ? t.notSet : m.date(_to)}',
              ),
              onPressed: () => _pick(false),
            ),
            if (_to != null)
              TextButton(
                key: const ValueKey('flavour-to-clear'),
                onPressed: () => setState(() => _to = null),
                child: Text(t.clearDate),
              ),
            TextField(
              key: const ValueKey('flavour-note-field'),
              controller: _note,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(labelText: t.flavourNote),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(m.cancel),
        ),
        FilledButton(
          key: const ValueKey('flavour-save'),
          onPressed: () => Navigator.of(context).pop(
            _FlavourEdit(
              status: _status,
              // An empty date clears it: an explicit null, not an empty string.
              from: _from ?? studioClear,
              to: _to ?? studioClear,
              note: _note.text.trim(),
            ),
          ),
          child: Text(m.save),
        ),
      ],
    );
  }
}
