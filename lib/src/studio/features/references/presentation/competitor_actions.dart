import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/studio_api_base.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/form_sheet.dart';
import '../../../shared/studio_error_text.dart';
import '../../../shared/studio_toast.dart';
import '../../../shared/studio_tr.dart';
import '../data/references_repository.dart';

/// The competitor writes a person can make (Founder, Lead): add, remove with a
/// reason (and an Undo toast that restores), restore. Each shows its own toast;
/// the lists refresh through `data/write_refresh.dart`.
class CompetitorActions {
  const CompetitorActions._();

  static String? _opt(String? v) => (v == null || v.isEmpty) ? null : v;

  static Future<void> add(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(referencesRepositoryProvider);
    final requestId = newRequestId();
    final done = context.tr('Competitor added.', 'المنافس اتضاف.');
    final ok = await StudioFormSheet.show(
      context,
      title: context.tr('Add a competitor', 'ضيف منافس'),
      intro: context.tr(
        'A name, and the Instagram handle or the Ads Library link.',
        'اسم، ومعاه حساب Instagram أو لينك Ads Library.',
      ),
      submitLabel: context.tr('Add', 'ضيف'),
      fields: [
        SheetField('name', context.tr('Name', 'الاسم'), required: true),
        SheetField(
          'ig',
          context.tr('Instagram handle', 'حساب Instagram'),
          ltr: true,
        ),
        SheetField(
          'adlib',
          context.tr('Ads Library link', 'لينك Ads Library'),
          ltr: true,
          keyboard: TextInputType.url,
        ),
        SheetField(
          'market',
          context.tr('Market (EG if empty)', 'السوق (EG لو سبته فاضي)'),
          ltr: true,
        ),
        SheetField('note', context.tr('Note', 'ملاحظة'), lines: 2),
      ],
      validate: (c, v) => (v['ig'] ?? '').isEmpty && (v['adlib'] ?? '').isEmpty
          ? c.tr(
              'Add the Instagram handle or the Ads Library link.',
              'ضيف حساب Instagram أو لينك Ads Library.',
            )
          : null,
      onSubmit: (v) async {
        await repo.competitorAdd(
          name: v['name']!,
          igHandle: _opt(v['ig']),
          adlibUrl: _opt(v['adlib']),
          market: _opt(v['market']),
          note: _opt(v['note']),
          requestId: requestId,
        );
      },
    );
    if (ok == true) showStudioToast(done);
  }

  static Future<void> remove(
    BuildContext context,
    WidgetRef ref,
    StudioCompetitor c,
  ) async {
    final repo = ref.read(referencesRepositoryProvider);
    final requestId = newRequestId();
    final undoLabel = context.tr('Undo', 'تراجع');
    final removedText = context.tr('${c.name} removed.', '${c.name} اتشال.');
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final ok = await StudioFormSheet.show(
      context,
      title: context.tr('Remove ${c.name}', 'شيل ${c.name}'),
      intro: context.tr(
        'Nothing is deleted: its references stay. You can restore it.',
        'مفيش حاجة بتتمسح: المراجع بتاعته فاضلة. تقدر ترجّعه.',
      ),
      submitLabel: context.tr('Remove', 'شيل'),
      fields: [
        SheetField(
          'reason',
          context.tr('Why (required)', 'ليه (مطلوب)'),
          lines: 2,
          required: true,
        ),
      ],
      validate: (c, v) => (v['reason'] ?? '').length > 300
          ? c.tr('At most 300 characters.', '300 حرف على الأكتر.')
          : null,
      onSubmit: (v) async {
        await repo.competitorRemove(c.key, v['reason']!, requestId: requestId);
      },
    );
    if (ok != true) return;
    showStudioToast(
      removedText,
      duration: const Duration(seconds: 8),
      action: SnackBarAction(
        label: undoLabel,
        onPressed: () async {
          try {
            await repo.competitorRestore(c.key);
          } catch (e) {
            showStudioToast(studioErrorMessage(e, ar: ar));
          }
        },
      ),
    );
  }

  static Future<void> restore(
    BuildContext context,
    WidgetRef ref,
    StudioCompetitor c,
  ) async {
    final text = context.tr('${c.name} is back.', '${c.name} رجع.');
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    try {
      await ref.read(referencesRepositoryProvider).competitorRestore(c.key);
      showStudioToast(text);
    } catch (e) {
      showStudioToast(studioErrorMessage(e, ar: ar));
    }
  }
}
