import 'package:flutter/widgets.dart';

/// The "counted wrong" shortage fix, in both languages.
///
/// Kept beside the feature rather than in the `.arb` files (the chat inbox
/// does the same): this ships as a Dart-only Shorebird patch, while any
/// `.arb` change forces a full APK, and the shared `.arb` files are edited by
/// several topics at once.
class ShortageFixStrings {
  ShortageFixStrings.of(BuildContext context)
    : _ar = Localizations.localeOf(context).languageCode == 'ar';

  final bool _ar;

  String get button => _ar
      ? 'ضيف الناقص (الجرد كان غلط)'
      : 'Add missing stock (it was counted wrong)';

  String get title => _ar ? 'إضافة المخزون الناقص؟' : 'Add the missing stock?';

  String when(String countAt, String productionAt) => _ar
      ? 'هيتعمل جرد يضيف الكميات دي الساعة $countAt، قبل الإنتاج بدقايق ($productionAt).'
      : 'A stock count will add these at $countAt, a few minutes before the '
            'production at $productionAt.';

  String chosenWhen(String countAt, String productionAt) => _ar
      ? 'هيتعمل جرد يضيف الكميات دي بتاريخ $countAt، قبل الإنتاج ($productionAt).'
      : 'A stock count will add these dated $countAt, before the production '
            'at $productionAt.';

  String get changeDate => _ar ? 'غيّر التاريخ' : 'Change date';

  String get useDefaultDate =>
      _ar ? 'رجّع للتاريخ الأصلي' : 'Back to the default date';

  String laterCount(String item, String at, String name) => _ar
      ? '$item اتجرد تاني $at ($name) بعد التاريخ ده. الجرد ده هيمسح الإضافة: اختار تاريخ بعده.'
      : '$item was counted again at $at ($name), after this date. That count '
            'would erase the addition: choose a date after it.';

  String becomes(String current, String counted) =>
      _ar ? '$current ← $counted' : '$current → $counted';

  String skipped(int count) => _ar
      ? '$count صنف مالهوش مخزن مصدر ومينفعش يتضاف بالطريقة دي.'
      : '$count item(s) have no source warehouse and cannot be added this way.';

  String get confirmCheck => _ar
      ? 'أؤكد إن الجرد كان غلط. ده مش base ما اتعملش، ولا فاتورة شراء ما اتسجلتش.'
      : 'I confirm the stock was counted wrong. It is not a base that was not '
            'produced, and not a purchase invoice that was not entered.';

  String get submit => _ar ? 'ضيف للمخزون' : 'Add to stock';

  String get nothing => _ar
      ? 'مفيش حاجة تتضاف: الخامات مكفية التشغيلة دي.'
      : 'Nothing to add: the materials already cover this batch.';

  String done(String names) => _ar
      ? 'اتضاف الناقص للمخزون ($names). تقدر تبدأ التشغيلات دلوقتي.'
      : 'Missing stock added ($names). You can start the batches now.';
}
