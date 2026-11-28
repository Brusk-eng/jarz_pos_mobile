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
  String get filterBases => _t('Cakes & biscuits', 'الكيك والبسكويت');
  String get filterFillings => _t('Mixes & fillings', 'الخلطات والحشوات');
  String get filterJars => _t('Jars', 'البرطمانات');

  /// Short chip labels so all five chips fit a phone; sections keep the long names.
  String get chipBases => _t('Cakes', 'الكيك');
  String get chipFillings => _t('Fillings', 'الحشوات');
  String get filterTrials => _t('Trials', 'التجارب');
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
  String get trialPill => _t('Trial', 'تجربة');
  String get trialRunning => _t('Trial running', 'تجربة جارية');
  String get ingredientsOnly => _t(
    'Ingredients · no written method yet',
    'المكونات · لا توجد طريقة مكتوبة بعد',
  );
  String get otherTrack => _t('Other', 'أخرى');
  String get accessDenied => _t(
    'Recipes are open to the production team only.',
    'الوصفات متاحة لفريق الإنتاج فقط.',
  );

  /// A section header on the list: the recipe category.
  String category(String category) => switch (category) {
    RecipeCategory.bases => filterBases,
    RecipeCategory.jars => filterJars,
    _ => filterFillings,
  };

  String size(String size) => switch (size) {
    'Small' => _t('Small', 'صغير'),
    'Medium' => _t('Medium', 'وسط'),
    'Large' => _t('Large', 'كبير'),
    _ => size,
  };

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

  String get noWrittenMethod =>
      _t('No written method yet', 'لا توجد طريقة مكتوبة بعد');

  // ── Jar family ──
  String get jarLoadFailed =>
      _t("Couldn't load these jars", 'تعذر تحميل البرطمانات');
  String get gramsPerJar => _t('Grams per jar', 'جرام لكل برطمان');
  String get ingredientsPerJar => _t('Ingredients per jar', 'مكونات البرطمان');
  String get perJar => _t('Per jar', 'للبرطمان');
  String get total => _t('Total', 'الإجمالي');
  String get packaging => _t('Packaging', 'التغليف');
  String get planRun => _t('Plan a run', 'خطط تشغيلة');
  String get planRunHint =>
      _t('How many jars of each size?', 'كم برطمانًا من كل حجم؟');
  String get noLayers => _t('No layers listed', 'لا توجد طبقات مسجلة');
  String sizeMethod(String size, int? version) =>
      version == null ? this.size(size) : '${this.size(size)} · v$version';

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

  // ── Layers & editing (v3) ──
  String get layersPerJar => _t('Layers per jar', 'طبقات البرطمان');
  String get layersFillOrder =>
      _t('1 = bottom of the jar', '١ = أسفل البرطمان');
  String get filledJar => _t('Filled jar', 'البرطمان المعبأ');
  String get noLayersYet => _t('No layers yet', 'لا توجد طبقات بعد');
  String get addLayers => _t('Add layers', 'أضف طبقات');
  String get editLayers => _t('Edit layers', 'تعديل الطبقات');
  String get layersTitle => _t('Layers', 'الطبقات');
  String get addLayer => _t('Add layer', 'إضافة طبقة');
  String get layerName => _t('Layer', 'الطبقة');
  String get layerGrams => _t('Grams per jar', 'جرام لكل برطمان');
  String get deleteRow => _t('Delete', 'حذف');
  String get dragToReorder => _t('Drag to reorder', 'اسحب لإعادة الترتيب');
  String get layersFootnote => _t(
    'Leave a size empty if it has no such layer.',
    'اترك الحجم فارغًا إذا لم تكن له هذه الطبقة.',
  );
  String get save => _t('Save', 'حفظ');
  String get saved => _t('Saved', 'تم الحفظ');
  String savedNewVersionFor(List<String> sizes) => _t(
    'Saved — new version for ${sizes.map(size).join(', ')}',
    'تم الحفظ — إصدار جديد لـ ${sizes.map(size).join('، ')}',
  );
  String get discardTitle => _t('Discard your changes?', 'تجاهل التغييرات؟');
  String get discardBody =>
      _t('What you typed has not been saved.', 'ما كتبته لم يُحفظ بعد.');
  String get discard => _t('Discard', 'تجاهل');
  String get keepEditing => _t('Keep editing', 'متابعة التعديل');
  String get whatChangedQ => _t('What changed?', 'ما الذي تغيّر؟');
  String get whatChangedHint => _t(
    'A short note for the team, e.g. "less sugar"',
    'ملاحظة قصيرة للفريق، مثل "سكر أقل"',
  );
  String get whatChangedRequired => _t(
    'Say what changed, so the team knows why',
    'اكتب ما الذي تغيّر ليعرف الفريق السبب',
  );
  String get layersNewVersionNote => _t(
    'Sizes already used in production get a new version.',
    'الأحجام المستخدمة في الإنتاج يُحفظ لها إصدار جديد.',
  );

  // Editor
  String get edit => _t('Edit', 'تعديل');
  String get writeMethod => _t('Write the method', 'اكتب الطريقة');
  String get newRecipe => _t('New recipe', 'وصفة جديدة');
  String get newVersion => _t('New version', 'إصدار جديد');
  String get approve => _t('Approve', 'اعتماد');
  String get retire => _t('Retire', 'إيقاف');
  String get backToTrial => _t('Back to trial', 'العودة للتجربة');
  String get moreActions => _t('More', 'المزيد');
  String saveAsVersion(int v) => _t('Save as v$v', 'حفظ كإصدار v$v');
  String get saveAsNewVersion => _t('Save as new version', 'حفظ كإصدار جديد');
  String get basics => _t('Basics', 'الأساسيات');
  String get fieldTitle => _t('Title', 'الاسم');
  String get fieldCategory => _t('Kind', 'النوع');
  String get fieldTrack => _t('Track', 'الخط');
  String get noTrack => _t('None', 'بدون');
  String get fieldFlavour => _t('Flavour', 'النكهة');
  String get fieldSize => _t('Size', 'الحجم');
  String get yieldTitle => _t('Yield', 'الناتج');
  String get fieldQty => _t('Quantity', 'الكمية');
  String get fieldUnit => _t('Unit', 'الوحدة');
  String get fieldAmount => _t('Amount', 'الكمية');
  String get fieldName => _t('Name', 'الاسم');
  String get fieldSection => _t('Section (optional)', 'القسم (اختياري)');
  String get addIngredient => _t('Add ingredient', 'إضافة مكون');
  String get bomNote => _t(
    'Amounts come from the BOM (change them in Desk)',
    'الكميات من قائمة المواد (غيّرها من Desk)',
  );
  String get methodTitle => _t('Method', 'الطريقة');
  String get addStep => _t('Add step', 'إضافة خطوة');
  String get stepTitle => _t('Step title', 'عنوان الخطوة');
  String get stepText => _t('What to do', 'ما المطلوب');
  String get stepMinutes => _t('Minutes', 'دقائق');
  String get insertAmount => _t('Insert amount', 'إدراج كمية');
  String get placeholderHint => _t(
    'Write [Flour] where an amount belongs. It scales with the batch.',
    'اكتب [الدقيق] مكان الكمية. وتتغير مع حجم الدفعة.',
  );
  String get pickIngredient => _t('Pick an ingredient', 'اختر مكونًا');
  String get perJarOption => _t('Per jar', 'لكل برطمان');
  String get timesOption => _t('Times', 'ضعف');
  String get noIngredientsToInsert =>
      _t('Add an ingredient first', 'أضف مكونًا أولًا');
  String get moreSection => _t('More', 'المزيد');
  String get fieldEquipment => _t('Equipment', 'الأدوات');
  String get fieldNotes => _t('Notes', 'ملاحظات');
  String get fieldPrepMins => _t('Prep time (minutes)', 'وقت التحضير (دقائق)');
  String get saveStageTitle => _t('Save as', 'الحفظ كـ');
  String get stageTrial => _t('Trial', 'تجربة');
  String get stageApproved => _t('Approved', 'معتمدة');
  String get stageTrialHint => _t(
    'Try it first. Production keeps the current method.',
    'جرّبها أولًا. يستمر الإنتاج بالطريقة الحالية.',
  );
  String replacesOnBoard(int v) => _t(
    'Replaces v$v on the Production Board',
    'تحل محل v$v على لوحة الإنتاج',
  );
  String get approvedNewHint =>
      _t('Becomes the approved recipe', 'تصبح الوصفة المعتمدة');
  String get warningsTitle => _t('Saved, with notes', 'تم الحفظ مع ملاحظات');
  String get warningsBody => _t(
    'These placeholders did not match an ingredient and stay as typed:',
    'هذه العناصر لم تطابق أي مكون وبقيت كما كُتبت:',
  );
  String get ok => _t('OK', 'حسنًا');

  /// The sentence for a [DraftIssue] name.
  String issueText(String code) => switch (code) {
    'titleMissing' => _t('Give the recipe a name', 'اكتب اسم الوصفة'),
    'flavourMissing' => _t('Enter the flavour', 'اكتب النكهة'),
    'sizeMissing' => _t('Pick a size', 'اختر الحجم'),
    'ingredientNameMissing' => _t(
      'An ingredient has no name',
      'يوجد مكون بلا اسم',
    ),
    'amountInvalid' => _t(
      'Every ingredient needs an amount above zero',
      'كل مكون يحتاج كمية أكبر من صفر',
    ),
    'noIngredients' => _t(
      'Add at least one ingredient',
      'أضف مكونًا واحدًا على الأقل',
    ),
    'yieldInvalid' => _t(
      'The yield must be above zero',
      'يجب أن يكون الناتج أكبر من صفر',
    ),
    'layerNameMissing' => _t('A layer has no name', 'توجد طبقة بلا اسم'),
    'layerGramsInvalid' => _t(
      'Layer weights must be numbers above zero',
      'أوزان الطبقات يجب أن تكون أرقامًا أكبر من صفر',
    ),
    _ => code,
  };

  // Stage changes
  String approveBody(int v, {int? replacing, required bool hasItem}) {
    if (!hasItem) {
      return _t(
        'v$v becomes the approved version.',
        'يصبح v$v الإصدار المعتمد.',
      );
    }
    return replacing == null
        ? _t(
            'v$v becomes the method on the Production Board.',
            'يصبح v$v هو الطريقة على لوحة الإنتاج.',
          )
        : _t(
            'v$v becomes the method on the Production Board, replacing v$replacing.',
            'يصبح v$v هو الطريقة على لوحة الإنتاج ويحل محل v$replacing.',
          );
  }

  String get approveWithBom =>
      _t('Approve with BOM amounts', 'اعتماد بكميات BOM');
  String retireBody(int v) => _t(
    'v$v will no longer be offered as a method.',
    'لن يُعرض v$v كطريقة بعد الآن.',
  );
  String backToTrialBody(int v) =>
      _t('v$v goes back to a trial.', 'يعود v$v إلى تجربة.');
  String get stageChanged => _t('Updated', 'تم التحديث');
}
