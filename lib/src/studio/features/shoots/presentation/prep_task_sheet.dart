import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/person_text.dart';

import '../../../data/api/studio_api_base.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/form_sheet.dart';
import '../../../shared/studio_toast.dart';
import '../../../shared/studio_tr.dart';
import '../../calendar/state/cairo_time.dart';
import '../../settings/data/settings_repository.dart';
import '../../today/data/today_repository.dart';
import '../state/on_set_state.dart';

/// "Add a prep task" on the Shoot screen (Founder and Lead): the text, who
/// does it and how many days before the shoot. It is a Today task of kind
/// `prep` tied to the shoot (`today.task_create`), so the prep list that the
/// kitchen reads gets the new row.
Future<void> showPrepTaskSheet(
  BuildContext context,
  WidgetRef ref,
  StudioShoot shoot,
) async {
  final repo = ref.read(todayRepositoryProvider);
  final requestId = newRequestId();
  final done = context.tr('Prep task added.', 'مهمة التحضير اتضافت.');
  final shootDay = CairoTime.parse(shoot.shootDate);
  StudioTask? created;
  final ok = await StudioFormSheet.show(
    context,
    title: context.tr('Add a prep task', 'ضيف مهمة تحضير'),
    submitLabel: context.tr('Add', 'ضيف'),
    initialValues: const {'days': '1'},
    fields: [
      SheetField(
        'text',
        context.tr('What to prepare', 'إيه اللي يتحضّر'),
        required: true,
        lines: 2,
      ),
    ],
    validate: (c, v) {
      final n = int.tryParse(v['days'] ?? '');
      if (n == null || n < 0 || n > 60) {
        return c.tr(
          'Days before the shoot: a number from 0 to 60.',
          'الأيام قبل التصوير: رقم من 0 لـ 60.',
        );
      }
      return null;
    },
    extra: (c, values, rebuild) => _PrepExtra(values: values, rebuild: rebuild),
    onSubmit: (v) async {
      final days = int.parse(v['days']!);
      final due = shootDay == null
          ? null
          : CairoTime.date(CairoTime.addDays(shootDay, -days));
      final who = v['who'] ?? '';
      created = await repo.create(
        text: v['text']!,
        kind: 'prep',
        shootId: shoot.id,
        assignee: who.isEmpty ? null : who,
        due: due,
        requestId: requestId,
      );
    },
  );
  if (ok == true) {
    final t = created;
    if (t != null) {
      await ref.read(onSetProvider.notifier).addPrep(shoot.id, t);
    }
    showStudioToast(done);
  }
}

class _PrepExtra extends ConsumerWidget {
  const _PrepExtra({required this.values, required this.rebuild});

  final Map<String, String> values;
  final VoidCallback rebuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider).valueOrNull ?? const [];
    final who = values['who'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: const ValueKey('prep-who'),
          initialValue: who,
          decoration: InputDecoration(
            labelText: context.tr('Who does it', 'مين هيعملها'),
          ),
          items: [
            DropdownMenuItem(
              value: '',
              child: Text(context.tr('Nobody yet', 'لسه مفيش')),
            ),
            for (final p in people.where((p) => p.enabled))
              DropdownMenuItem(value: p.key, child: PersonText(p.fullName)),
          ],
          onChanged: (v) {
            values['who'] = v ?? '';
            rebuild();
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('prep-days'),
          initialValue: values['days'],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.tr(
              'Days before the shoot',
              'كام يوم قبل التصوير',
            ),
          ),
          onChanged: (v) => values['days'] = v.trim(),
        ),
      ],
    );
  }
}
