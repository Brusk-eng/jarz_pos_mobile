import 'package:flutter/widgets.dart';

import '../data/recipe_book_models.dart';

/// English and Arabic for the Recipe Book, picked by the app's locale.
///
/// Feature-local rather than in the `.arb` files: an `.arb` edit forces a
/// full APK, and this feature ships as a Shorebird patch.
class RecipeBookStrings {
  const RecipeBookStrings._(this.isAr);

  static const en = RecipeBookStrings._(false);
  static const ar = RecipeBookStrings._(true);

  static RecipeBookStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

  final bool isAr;

  String _t(String english, String arabic) => isAr ? arabic : english;

  // ── List ──
  String get title => _t('Recipes', 'الوصفات');
  String get searchHint => _t('Search recipes', 'ابحث عن وصفة');
  String get filterAll => _t('All', 'الكل');
  String get filterApproved => _t('Approved', 'معتمدة');
  String get filterTrials => _t('Trials', 'تجارب');
  String get emptyTitle => _t('No recipes yet', 'لا توجد وصفات بعد');
  String get emptyBody => _t(
    'Recipes appear here once an SOP is written for them.',
    'ستظهر الوصفات هنا بمجرد كتابة طريقة عمل لها.',
  );
  String get noMatch => _t('No recipe matches', 'لا توجد وصفة مطابقة');
  String get clearFilters => _t('Clear search', 'مسح البحث');
  String get loadFailed =>
      _t("Couldn't load the recipes", 'تعذر تحميل الوصفات');
  String get recipeLoadFailed =>
      _t("Couldn't load this recipe", 'تعذر تحميل الوصفة');
  String get retry => _t('Retry', 'إعادة المحاولة');
  String get trialInProgress => _t('Trial in progress', 'تجربة جارية');
  String get otherTrack => _t('Other', 'أخرى');
  String get accessDenied => _t(
    'Recipes are open to the production team only.',
    'الوصفات متاحة لفريق الإنتاج فقط.',
  );

  String track(String? track) {
    if (track == null) return otherTrack;
    if (!isAr) return track;
    return switch (track) {
      'Standard line' => 'الخط الأساسي',
      'Cookie jar line' => 'خط برطمانات الكوكيز',
      'Winter warmer' => 'مشروبات الشتاء',
      'Light line' => 'الخط الخفيف',
      _ => track,
    };
  }

  // ── Status ──
  String recipeStatus(String status) => switch (status) {
    RecipeStatus.trial => _t('Trial', 'تجربة'),
    RecipeStatus.retired => _t('Retired', 'متوقفة'),
    _ => _t('Approved', 'معتمدة'),
  };

  String versionStatus(String status) => switch (status) {
    VersionStatus.current => _t('Current', 'الحالية'),
    VersionStatus.previous => _t('Previous', 'سابقة'),
    VersionStatus.trial => _t('Trial', 'تجربة'),
    VersionStatus.retired => _t('Retired', 'متوقفة'),
    _ => status,
  };

  String versionNo(int version) => 'v$version';
  String trialVersion(int version) => _t('Trial v$version', 'تجربة v$version');
  String approvedOn(String date) => _t('approved $date', 'اعتُمدت $date');
  String updatedOn(String date) => _t('updated $date', 'حُدّثت $date');
  String get retiredWord => _t('retired', 'متوقفة');

  // ── Detail ──
  String get versions => _t('Versions', 'الإصدارات');
  String get inProduction => _t('On the board', 'على لوحة الإنتاج');
  String get whatChanged => _t('What changed', 'ما الذي تغيّر');
  String get dismiss => _t('Dismiss', 'إخفاء');
  String get tabIngredients => _t('Ingredients', 'المكونات');
  String get tabMethod => _t('Method', 'الطريقة');
  String get tabNotes => _t('Notes', 'ملاحظات');
  String get equipment => _t('Equipment', 'الأدوات');
  String get notes => _t('Notes', 'ملاحظات');
  String get prepTime => _t('Prep time', 'وقت التحضير');
  String get noIngredients =>
      _t('No ingredients listed', 'لا توجد مكونات مسجلة');
  String get noSteps => _t('No method written yet', 'لم تُكتب الطريقة بعد');
  String get unresolvedNote => _t(
    'Some amounts in the method could not be matched to an ingredient.',
    'بعض الكميات في الطريقة لم تُطابق أي مكون.',
  );

  // ── Scale ──
  String batch(String yieldText) => _t('$yieldText batch', 'دفعة $yieldText');
  String get oneBatch => _t('One batch', 'دفعة واحدة');
  String get reset => _t('Reset', 'إعادة');
  String get scaleHint => _t(
    'Tap any ingredient to scale the recipe to it',
    'اضغط على أي مكون لضبط الوصفة على كميته',
  );
  String howMuch(String name) =>
      _t('How much $name do you have?', 'كم لديك من $name؟');
  String get batchSizeTitle =>
      _t('What batch size do you want?', 'ما حجم الدفعة المطلوب؟');
  String recipeTimes(String factor) => _t('Recipe $factor', 'الوصفة $factor');
  String previewBatch(String yieldText) =>
      _t('batch $yieldText', 'دفعة $yieldText');
  String get apply => _t('Apply', 'تطبيق');
  String get cancel => _t('Cancel', 'إلغاء');
  String get enterAmount =>
      _t('Enter an amount above zero', 'أدخل كمية أكبر من صفر');
  String get scaleTooltip => _t('Scale', 'تغيير الحجم');

  // ── Method ──
  String step(int no) => _t('Step $no', 'الخطوة $no');
  String target(String range) => _t('Target $range', 'المستهدف $range');
  String get hour => _t('h', 'س');
  String get minute => _t('min', 'د');
}
