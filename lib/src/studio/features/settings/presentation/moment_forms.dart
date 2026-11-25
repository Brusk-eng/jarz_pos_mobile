import '../../../shared/studio_chips.dart';
import '../../../shared/studio_pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/api/studio_api_base.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/form_sheet.dart';
import '../../../shared/person_text.dart';
import '../../../shared/studio_error_text.dart';
import '../../../shared/studio_toast.dart';
import '../../../shared/studio_tr.dart';
import '../../calendar/state/cairo_format.dart';
import '../../calendar/state/cairo_time.dart';
import '../data/settings_repository.dart';

/// Create, edit and move a moment (a launch, a Hero window, a budget step)
/// with `settings.moment_set` (Founder and Lead). Moving never fails: the
/// warnings it causes (pinned posts that follow, checks) come back in
/// [MomentSetResult.warnings] and are shown as the server worded them.
class MomentForms {
  const MomentForms._();

  static const _kinds = [
    MomentKind.launch,
    MomentKind.heroWindow,
    MomentKind.budgetStep,
  ];

  static String kindName(BuildContext c, MomentKind k) => switch (k) {
    MomentKind.launch => c.tr('Launch', 'إطلاق'),
    MomentKind.heroWindow => c.tr('Hero window', 'نافذة Hero'),
    MomentKind.budgetStep => c.tr('Budget step', 'خطوة ميزانية'),
    MomentKind.unknown => '',
  };

  static Widget _dateButton(
    BuildContext context,
    Map<String, String> values,
    VoidCallback rebuild,
    String key,
    String label, {
    bool required = false,
  }) {
    final value = values[key] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
      child: OutlinedButton.icon(
        key: ValueKey('moment-$key'),
        icon: const Icon(Icons.calendar_month, size: 18),
        label: Text(
          value.isEmpty
              ? (required
                    ? '$label * ${context.tr('(required)', '(مطلوب)')}'
                    : label)
              : '$label: ${CairoFormat.isoDay(value, context.isAr)}',
        ),
        onPressed: () async {
          final start = CairoTime.parse(value) ?? DateTime.now();
          final picked = await showStudioDatePicker(
            context: context,
            initialDate: start,
            firstDate: DateTime(2025),
            lastDate: DateTime(2029),
          );
          if (picked != null) {
            values[key] = CairoTime.date(picked);
            rebuild();
          }
        },
      ),
    );
  }

  /// The warnings a moment write brought back, as the server worded them.
  static Future<void> showWarnings(
    BuildContext context,
    List<CheckRow> warnings,
  ) async {
    if (warnings.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        key: const ValueKey('moment-warnings'),
        title: Text(c.tr('Saved. Check these:', 'اتحفظ. راجع دول:')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final w in warnings)
                Padding(
                  padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
                  child: PersonText(w.message),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(c.tr('Got it', 'تمام')),
          ),
        ],
      ),
    );
  }

  /// A new moment ([mo] null) or an edit of [mo].
  static Future<void> edit(
    BuildContext context,
    WidgetRef ref, {
    StudioMoment? mo,
  }) async {
    final repo = ref.read(settingsRepositoryProvider);
    final requestId = newRequestId();
    final saved = context.tr('Moment saved.', 'الموعد اتحفظ.');
    List<CheckRow> warnings = const [];
    String? opt(String? v) => (v == null || v.isEmpty) ? null : v;
    final ok = await StudioFormSheet.show(
      context,
      title: mo == null
          ? context.tr('New moment', 'موعد جديد')
          : context.tr('Edit ${mo.title}', 'عدّل ${mo.title}'),
      submitLabel: context.tr('Save', 'احفظ'),
      initialValues: {
        'kind': (mo?.kind ?? MomentKind.launch).wire,
        'date': mo?.date ?? '',
        'end_date': mo?.endDate ?? '',
      },
      fields: [
        SheetField(
          'title',
          context.tr('Title', 'العنوان'),
          required: true,
          initial: mo?.title ?? '',
        ),
        SheetField(
          'note',
          context.tr('Note', 'ملاحظة'),
          lines: 2,
          initial: mo?.note ?? '',
        ),
      ],
      validate: (c, v) => (v['date'] ?? '').isEmpty
          ? c.tr('Pick the date.', 'اختار التاريخ.')
          : null,
      extra: (c, values, rebuild) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mo == null)
            Padding(
              padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
              child: Wrap(
                spacing: StudioSpacing.sm,
                children: [
                  for (final k in _kinds)
                    StudioChoiceChip(
                      key: ValueKey('moment-kind-${k.wire}'),
                      label: Text(kindName(c, k)),
                      selected: values['kind'] == k.wire,
                      onSelected: (_) {
                        values['kind'] = k.wire;
                        rebuild();
                      },
                    ),
                ],
              ),
            ),
          _dateButton(
            c,
            values,
            rebuild,
            'date',
            c.tr('Date', 'التاريخ'),
            required: true,
          ),
          _dateButton(
            c,
            values,
            rebuild,
            'end_date',
            c.tr('Until (optional)', 'لحد (اختياري)'),
          ),
        ],
      ),
      onSubmit: (v) async {
        final r = await repo.momentSet(
          momentId: mo?.id,
          kind: mo == null ? v['kind'] : null,
          title: v['title'],
          date: opt(v['date']),
          endDate: opt(v['end_date']),
          note: v['note'],
          baseModified: mo?.modified,
          requestId: requestId,
        );
        warnings = r.warnings;
      },
    );
    if (ok == true) {
      showStudioToast(saved);
      if (context.mounted) await showWarnings(context, warnings);
    }
  }

  /// "Move this moment": a new date; pinned posts follow, warnings come back.
  static Future<void> move(
    BuildContext context,
    WidgetRef ref,
    StudioMoment mo,
  ) async {
    final repo = ref.read(settingsRepositoryProvider);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final saved = context.tr('Moment moved.', 'الموعد اتنقل.');
    final start =
        CairoTime.parse(mo.effectiveDate ?? mo.date) ?? DateTime.now();
    final picked = await showStudioDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(2025),
      lastDate: DateTime(2029),
      helpText: context.tr('Move ${mo.title} to', 'انقل ${mo.title} ل'),
    );
    if (picked == null || !context.mounted) return;
    try {
      final r = await repo.momentSet(
        momentId: mo.id,
        date: CairoTime.date(picked),
        baseModified: mo.modified,
        requestId: newRequestId(),
      );
      showStudioToast(saved);
      if (context.mounted) await showWarnings(context, r.warnings);
    } catch (e) {
      showStudioToast(
        studioErrorMessage(e, ar: ar),
        duration: studioErrorToastDuration,
      );
    }
  }
}
