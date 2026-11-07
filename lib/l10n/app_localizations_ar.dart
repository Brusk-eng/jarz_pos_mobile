// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'جارز لنقاط البيع';

  @override
  String get drawerHeaderTitle => 'جارز لنقاط البيع';

  @override
  String get drawerHeaderSubtitle => 'منصة نقاط البيع المحمولة';

  @override
  String get menuB2bMode => 'وضع الأعمال (B2B)';

  @override
  String get drawerGroupPosSales => 'المبيعات والطلبات';

  @override
  String get drawerGroupCrm => 'B2B والتسعير';

  @override
  String get drawerGroupDelivery => 'التوصيل والمناديب';

  @override
  String get drawerGroupFinance => 'المالية والمصروفات';

  @override
  String get drawerGroupPurchasing => 'المخزون والمشتريات';

  @override
  String get drawerGroupManagement => 'لوحات التحكم والتقارير';

  @override
  String get drawerGroupProduction => 'الإنتاج';

  @override
  String get drawerGroupTeam => 'الفريق والورديات';

  @override
  String get menuPriceLists => 'قوائم الأسعار';

  @override
  String get menuPointOfSale => 'نقطة البيع';

  @override
  String get menuSalesKanban => 'لوحة المبيعات';

  @override
  String get menuExpenses => 'المصروفات';

  @override
  String get escalationSectionTitle =>
      'متأخرة — غير مؤكدة بعد تجاوز الحد المسموح';

  @override
  String get escalationBadge => 'متأخرة';

  @override
  String escalationThresholdBreached(int hours) {
    return 'تجاوز حد $hours ساعة';
  }

  @override
  String escalationOutForDeliveryDuration(Object duration) {
    return 'خارج للتوصيل منذ $duration';
  }

  @override
  String get escalationBranchLabel => 'الفرع';

  @override
  String get escalationAlreadyNotified => 'تم إشعار المدير بالفعل';

  @override
  String get escalationNotYetNotified => 'لم يتم الإشعار بعد';

  @override
  String get escalationLoadFailed => 'تعذر تحميل الطلبات المتأخرة';

  @override
  String get warehouseAlignTitle => 'مطابقة المخازن';

  @override
  String get warehouseAlignSubtitle => 'فواتير خرج مخزونها من الفرع الخطأ';

  @override
  String get warehouseAlignWatchlistBanner =>
      'قائمة مراقبة للقراءة فقط — عالج الفروقات من سطح المكتب، لا يوجد إجراء إصلاح هنا';

  @override
  String get warehouseAlignEmpty => 'لا توجد فروقات في المخازن';

  @override
  String get warehouseAlignExpectedLabel => 'المتوقع';

  @override
  String get warehouseAlignActualLabel => 'الفعلي';

  @override
  String get warehouseAlignBranchFilterLabel => 'الفرع';

  @override
  String get warehouseAlignBranchFilterAll => 'كل الفروع';

  @override
  String get menuCourierBalances => 'أرصدة المندوبين';

  @override
  String get menuManagerDashboard => 'لوحة تحكم المدير';

  @override
  String get managerMenuTooltip => 'القائمة';

  @override
  String get managerDashboardTitle => 'لوحة تحكم المدير';

  @override
  String get managerRecentOrders => 'أحدث الطلبات';

  @override
  String get managerNoRecentOrders => 'لا توجد طلبات حديثة';

  @override
  String get managerBranchBalances => 'أرصدة الفروع';

  @override
  String get managerSwitchProfileTip =>
      'معلومة: يمكنك تغيير ملف نقطة البيع من ترويسة شاشة نقطة البيع أو لوحة المبيعات.';

  @override
  String get managerSwitchProfile => 'تبديل الملف';

  @override
  String get managerTotalCash => 'إجمالي النقدية';

  @override
  String get managerAll => 'الكل';

  @override
  String get managerFilterByState => 'تصفية حسب الحالة:';

  @override
  String get managerChangeBranch => 'تغيير الفرع';

  @override
  String get managerAssignToBranch => 'إسناد إلى فرع';

  @override
  String get managerBranchUpdated => 'تم تحديث الفرع';

  @override
  String managerBranchUpdateFailed(Object error) {
    return 'فشل: $error';
  }

  @override
  String get menuPurchaseInvoice => 'فواتير الشراء';

  @override
  String get menuAbout => 'حول التطبيق';

  @override
  String get aboutTitle => 'حول التطبيق';

  @override
  String get aboutAppSection => 'التطبيق';

  @override
  String get aboutReleaseSection => 'الإصدار';

  @override
  String get aboutShorebirdSection => 'Shorebird';

  @override
  String get aboutAppName => 'اسم التطبيق';

  @override
  String get aboutPackageName => 'اسم الحزمة';

  @override
  String get aboutPlatform => 'المنصة';

  @override
  String get aboutEnvironment => 'البيئة';

  @override
  String get aboutBuildName => 'اسم البناء';

  @override
  String get aboutBuildNumber => 'رقم البناء';

  @override
  String get aboutReleaseId => 'معرّف الإصدار';

  @override
  String get aboutReleaseDist => 'توزيع الإصدار';

  @override
  String get aboutPatchNumber => 'رقم التصحيح';

  @override
  String get aboutPatchStatus => 'حالة التصحيح';

  @override
  String get aboutLastChecked => 'آخر فحص';

  @override
  String get aboutNotAvailable => 'غير متوفر';

  @override
  String get aboutPatchNotInstalled => 'الإصدار الأساسي فقط';

  @override
  String get aboutPatchUnavailable => 'غير متاح على هذه المنصة';

  @override
  String get aboutPatchStatusUpToDate => 'محدّث';

  @override
  String get aboutPatchStatusUpdateAvailable => 'يوجد تحديث';

  @override
  String get aboutPatchStatusRestartRequired => 'إعادة التشغيل مطلوبة';

  @override
  String get aboutPatchStatusUnavailable => 'غير متاح';

  @override
  String get aboutPatchStatusUnknown => 'غير معروف';

  @override
  String get aboutPatchStatusUnknownDetail => 'خطأ في فحص التحديث';

  @override
  String get aboutRefresh => 'تحديث';

  @override
  String get aboutCopyDiagnostics => 'نسخ معلومات التشخيص';

  @override
  String get aboutCopiedDiagnostics => 'تم نسخ معلومات التشخيص';

  @override
  String get aboutRetry => 'إعادة المحاولة';

  @override
  String aboutError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String get menuManufacturing => 'التصنيع';

  @override
  String get menuStockTransfer => 'تحويل المخزون';

  @override
  String get wooSyncMenuTitle => 'مزامنة ووكومرس';

  @override
  String get wooSyncNotPermittedTitle => 'غير مصرح به';

  @override
  String get wooSyncNotPermittedBody =>
      'يلزم دور مشغّل مزامنة ووكومرس لفتح هذه الشاشة.';

  @override
  String get wooSyncRefresh => 'تحديث';

  @override
  String get wooSyncBreakerOpenTitle => 'المزامنة الصادرة متوقفة';

  @override
  String get wooSyncBreakerOpenBody =>
      'توقف قاطع الدائرة بعد فشل متكرر في الدفع إلى ووكومرس. كل عملية دفع صادرة متوقفة حتى يُزال هذا التوقف.';

  @override
  String wooSyncBreakerOpenUntil(Object time) {
    return 'متوقف حتى $time';
  }

  @override
  String wooSyncBreakerFailureCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حالات فشل مؤخرًا',
      one: 'فشل واحد مؤخرًا',
    );
    return '$_temp0';
  }

  @override
  String get wooSyncBreakerClosedTitle => 'المزامنة الصادرة سليمة';

  @override
  String get wooSyncBreakerClosedBody =>
      'قاطع الدائرة الصادر مغلق. عمليات الدفع إلى ووكومرس تسير بشكل طبيعي.';

  @override
  String get wooSyncBacklogTitle => 'الأعمال المتراكمة';

  @override
  String get wooSyncBacklogPending => 'قيد الانتظار';

  @override
  String get wooSyncBacklogRetryScheduled => 'مجدولة لإعادة المحاولة';

  @override
  String get wooSyncBacklogProcessing => 'قيد المعالجة';

  @override
  String get wooSyncBacklogNeedsAttention => 'بحاجة إلى انتباه';

  @override
  String get wooSyncBacklogDueNow => 'مستحقة الآن';

  @override
  String wooSyncBacklogOldestDue(Object time) {
    return 'أقدم استحقاق $time';
  }

  @override
  String get wooSyncBacklogExpiredProcessing => 'عالقة في المعالجة';

  @override
  String get wooSyncSearchHint =>
      'ابحث بمعرف الحدث أو المصدر أو الفاتورة أو السبب...';

  @override
  String get wooSyncFilterAttentionOnly => 'بحاجة إلى انتباه';

  @override
  String get wooSyncFilterAllEvents => 'كل الأحداث';

  @override
  String get wooSyncFilterStatusLabel => 'الحالة';

  @override
  String get wooSyncFilterDirectionLabel => 'الاتجاه';

  @override
  String get wooSyncFilterReviewStateLabel => 'حالة المراجعة';

  @override
  String get wooSyncFilterAny => 'أي';

  @override
  String get wooSyncClearFilters => 'مسح الفلاتر';

  @override
  String get wooSyncEventsEmpty => 'لا توجد أحداث مزامنة مطابقة لهذه الفلاتر.';

  @override
  String wooSyncEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حدث',
      one: 'حدث واحد',
    );
    return '$_temp0';
  }

  @override
  String get wooSyncEventRetry => 'إعادة المحاولة';

  @override
  String get wooSyncEventProcessNow => 'معالجة الآن';

  @override
  String get wooSyncEventSetReviewState => 'حالة المراجعة';

  @override
  String get wooSyncEventPushInvoice => 'دفع إلى ووكومرس';

  @override
  String wooSyncEventLocalInvoiceLabel(Object name) {
    return 'الفاتورة $name';
  }

  @override
  String wooSyncEventAttempt(Object count, Object max) {
    return 'المحاولة $count من $max';
  }

  @override
  String wooSyncEventLastError(Object error) {
    return 'آخر خطأ: $error';
  }

  @override
  String wooSyncEventReviewReason(Object reason) {
    return 'سبب المراجعة: $reason';
  }

  @override
  String get wooSyncSelectAll => 'تحديد الكل';

  @override
  String get wooSyncClearSelection => 'إلغاء التحديد';

  @override
  String wooSyncSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تحديد $count',
      one: 'تم تحديد 1',
    );
    return '$_temp0';
  }

  @override
  String get wooSyncBulkRetry => 'إعادة محاولة المحدد';

  @override
  String get wooSyncBulkSetReviewState => 'تعيين حالة المراجعة';

  @override
  String wooSyncBulkLimitExceeded(int limit, int count) {
    return 'تقتصر الإجراءات الجماعية على $limit حدثًا في المرة الواحدة؛ تم تحديد $count. قلّص التحديد وحاول مجددًا.';
  }

  @override
  String get wooSyncRunWorker => 'تشغيل العامل الآن';

  @override
  String get wooSyncRunWorkerConfirmTitle => 'تشغيل عامل المزامنة الآن؟';

  @override
  String get wooSyncRunWorkerConfirmBody =>
      'سيؤدي هذا إلى معالجة كل حدث مزامنة مستحق فورًا في كامل المتجر، وليس فقط ما هو معروض هنا.';

  @override
  String get wooSyncClearBreaker => 'إزالة قاطع التوقف الصادر';

  @override
  String get wooSyncClearBreakerConfirmTitle => 'إزالة قاطع الدائرة الصادر؟';

  @override
  String get wooSyncClearBreakerConfirmBody =>
      'سيؤدي هذا إلى استئناف كل عملية دفع صادرة متوقفة فورًا. لا تفعل هذا إلا بعد التأكد من انتهاء انقطاع ووكومرس الذي تسبب في هذا التوقف.';

  @override
  String get wooSyncConfirm => 'تأكيد';

  @override
  String get wooSyncCancel => 'إلغاء';

  @override
  String wooSyncRetryQueued(Object name) {
    return 'تم جدولة إعادة المحاولة لـ $name';
  }

  @override
  String wooSyncProcessedNow(Object name) {
    return 'تمت معالجة $name';
  }

  @override
  String get wooSyncReviewStateSaved => 'تم تحديث حالة المراجعة';

  @override
  String wooSyncBulkRetryDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت إعادة محاولة $count حدث',
      one: 'تمت إعادة محاولة حدث واحد',
    );
    return '$_temp0';
  }

  @override
  String wooSyncBulkReviewStateDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تحديث $count حدث',
      one: 'تم تحديث حدث واحد',
    );
    return '$_temp0';
  }

  @override
  String get wooSyncWorkerRunDone => 'اكتمل تشغيل العامل';

  @override
  String wooSyncBreakerCleared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت إزالة القاطع، تم تحرير $count حدث',
      one: 'تمت إزالة القاطع، تم تحرير حدث واحد',
      zero: 'تمت إزالة القاطع',
    );
    return '$_temp0';
  }

  @override
  String wooSyncInvoicePushed(Object name) {
    return 'تم دفع $name إلى ووكومرس';
  }

  @override
  String get wooSyncReviewStateDialogTitle => 'تعيين حالة المراجعة';

  @override
  String get wooSyncReviewStateNotesLabel => 'ملاحظات (اختياري)';

  @override
  String get wooSyncStatusPending => 'قيد الانتظار';

  @override
  String get wooSyncStatusProcessing => 'قيد المعالجة';

  @override
  String get wooSyncStatusSucceeded => 'تم بنجاح';

  @override
  String get wooSyncStatusRetryScheduled => 'مجدولة لإعادة المحاولة';

  @override
  String get wooSyncStatusSkipped => 'تم التخطي';

  @override
  String get wooSyncStatusSuperseded => 'تم الاستبدال';

  @override
  String get wooSyncStatusFailed => 'فشل';

  @override
  String get wooSyncStatusNeedsReview => 'بحاجة إلى مراجعة';

  @override
  String get wooSyncStatusDeadLetter => 'رسالة ميتة';

  @override
  String get wooSyncDirectionInbound => 'وارد';

  @override
  String get wooSyncDirectionOutbound => 'صادر';

  @override
  String get wooSyncReviewStateOpen => 'مفتوحة';

  @override
  String get wooSyncReviewStateInvestigating => 'قيد التحقيق';

  @override
  String get wooSyncReviewStateResolved => 'تم الحل';

  @override
  String get wooSyncReviewStateIgnored => 'تم التجاهل';

  @override
  String get wooDuplicatesMenuTitle => 'العملاء المكررون';

  @override
  String get wooDuplicatesIntro =>
      'أرقام الهواتف هذه تطابقت مع أكثر من عميل، لكن لا شيء هنا كان واضحًا بما يكفي للدمج تلقائيًا.';

  @override
  String get wooDuplicatesReadOnlyBanner =>
      'فرز للقراءة فقط. دمج العملاء المكررين مقتصر على المسؤول ويتم في نظام Desk، وليس هنا.';

  @override
  String get wooDuplicatesEmpty =>
      'لا توجد مجموعات عملاء مكررة بحاجة إلى مراجعة الآن.';

  @override
  String wooDuplicatesGroupSize(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عملاء',
      one: 'عميل واحد',
    );
    return '$_temp0';
  }

  @override
  String wooDuplicatesGroupReason(Object reason) {
    return 'سبب عدم الدمج التلقائي: $reason';
  }

  @override
  String wooDuplicatesCandidateInvoices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فاتورة',
      one: 'فاتورة واحدة',
    );
    return '$_temp0';
  }

  @override
  String wooDuplicatesCandidateSubmitted(int count) {
    return '$count معتمدة';
  }

  @override
  String wooDuplicatesCandidateRevenue(Object amount) {
    return 'الإيراد $amount';
  }

  @override
  String wooDuplicatesCandidateCreated(Object date) {
    return 'أُنشئ في $date';
  }

  @override
  String get wooDuplicatesCandidateDisabled => 'معطّل';

  @override
  String get wooDuplicatesCandidateActive => 'نشط';

  @override
  String wooDuplicatesCandidateWooId(Object id) {
    return 'معرف ووكومرس $id';
  }

  @override
  String get wooDuplicatesCandidateNoWooId => 'لا يوجد معرف ووكومرس';

  @override
  String get menuCashTransfer => 'تحويل النقدية';

  @override
  String get unsettleAlreadyReversedLabel => 'تم التراجع عنها بالفعل';

  @override
  String unsettleReversalEntryLabel(String entry) {
    return 'تم التراجع بواسطة $entry';
  }

  @override
  String get unsettleEntryPointTooltip => 'التراجع عن تسوية';

  @override
  String get unsettleHistoryTitle => 'التراجع عن تسوية';

  @override
  String get unsettleHistorySearchHint => 'ابحث بالمندوب أو الطرف أو رقم القيد';

  @override
  String get unsettleHistoryEmpty => 'لا توجد تسويات لهذا الفرع.';

  @override
  String unsettleRecordJournalEntry(Object entry) {
    return 'قيد اليومية: $entry';
  }

  @override
  String unsettleRecordInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count معاملات',
      one: 'معاملة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get unsettleModeCollect => 'تحصيل من المندوب';

  @override
  String get unsettleModePay => 'دفع للمندوب';

  @override
  String get unsettleModeBulk => 'تسوية شاملة';

  @override
  String get unsettleModeSettleNow => 'تمت التسوية فورًا';

  @override
  String get unsettleModeSettleLater => 'تمت التسوية لاحقًا';

  @override
  String get unsettleModeGeneric => 'تسوية';

  @override
  String get unsettleDialogTitle => 'التراجع عن التسوية';

  @override
  String get unsettlePreviewLoading => 'جارٍ تحميل معاينة التراجع…';

  @override
  String get unsettlePreviewErrorTitle => 'تعذّر تحميل معاينة التراجع';

  @override
  String get unsettleRefreshAndRetry => 'تحديث المعاينة والمحاولة مجددًا';

  @override
  String unsettleOriginalEntryLabel(Object entry) {
    return 'التسوية الأصلية: $entry';
  }

  @override
  String unsettlePartyLabel(Object party) {
    return 'الطرف: $party';
  }

  @override
  String unsettleBranchLabel(Object branch) {
    return 'الفرع: $branch';
  }

  @override
  String unsettlePostingDateLabel(Object date) {
    return 'تاريخ الترحيل الأصلي: $date';
  }

  @override
  String unsettleNetAmountLabel(Object amount) {
    return 'الصافي: $amount';
  }

  @override
  String get unsettleWillReopenSectionTitle =>
      'المعاملات التي ستعود غير مسوّاة';

  @override
  String get unsettleAccountLinesSectionTitle => 'بنود الحسابات التي ستنعكس';

  @override
  String unsettleTransactionLineSubtitle(Object city, Object amount) {
    return '$city • $amount';
  }

  @override
  String unsettleAccountLineSubtitle(Object debit, Object credit) {
    return 'مدين $debit / دائن $credit';
  }

  @override
  String get unsettleNoBreakdownAvailable =>
      'لم يُرجع الخادم تفصيلاً على مستوى البنود لهذه المعاينة. الإجماليات أعلاه لا تزال دقيقة.';

  @override
  String get unsettleAuditTrailNotice =>
      'سيتم ترحيل قيد يومية جديد معاكس. التسوية الأصلية لا تُلغى أبدًا — يبقى القيدان معًا في سجل المراجعة.';

  @override
  String get unsettleAckCheckboxLabel =>
      'أتفهّم أن هذا يعكس حركة مالية حقيقية ولا يمكن التراجع عنه من هنا.';

  @override
  String get unsettleReasonFieldLabel => 'السبب (اختياري)';

  @override
  String get unsettleReasonFieldHint => 'مثال: تمت التسوية من خزينة فرع خاطئ';

  @override
  String get unsettleConfirmButton => 'التراجع عن التسوية';

  @override
  String get unsettleCommitting => 'جارٍ ترحيل قيد التراجع…';

  @override
  String get unsettleSuccessTitle => 'تم التراجع عن التسوية';

  @override
  String unsettleSuccessBody(Object entry) {
    return 'تم ترحيل قيد اليومية المعاكس $entry. عادت المعاملات المتأثرة إلى غير مسوّاة.';
  }

  @override
  String get unsettleCommitErrorTitle => 'تعذّر التراجع عن التسوية';

  @override
  String get unsettleAccessRestricted =>
      'التراجع عن التسوية متاح للمديرين ومديري الخط فقط.';

  @override
  String get partnerSettlementMenuTitle => 'تسويات الشركاء';

  @override
  String get partnerSettlementTabDelivery => 'شركاء التوصيل';

  @override
  String get partnerSettlementTabSales => 'شركاء المبيعات';

  @override
  String get partnerSettlementRefreshTooltip => 'تحديث';

  @override
  String get partnerSettlementDeliveryEmptyBalances =>
      'لا توجد رسوم غير مفوترة لشركاء التوصيل.';

  @override
  String partnerSettlementTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رحلة',
      one: 'رحلة واحدة',
    );
    return '$_temp0';
  }

  @override
  String partnerSettlementOldestSince(Object date) {
    return 'الأقدم: $date';
  }

  @override
  String get partnerSettlementReviewAndSettle => 'مراجعة وتسوية';

  @override
  String partnerSettlementTripsTitle(Object partner) {
    return '$partner — الرحلات غير المسواة';
  }

  @override
  String get partnerSettlementTripsEmpty =>
      'لا توجد رحلات غير مسواة لهذا الشريك.';

  @override
  String get partnerSettlementSelectAll => 'تحديد الكل';

  @override
  String get partnerSettlementDeselectAll => 'إلغاء تحديد الكل';

  @override
  String partnerSettlementSelectedOfTotal(int selected, int total) {
    return 'تم تحديد $selected من $total';
  }

  @override
  String get partnerSettlementUnselectedWarning =>
      'الرحلات غير المحددة تبقى غير مفوترة وتظهر مرة أخرى الأسبوع القادم.';

  @override
  String partnerSettlementTripInvoiceLabel(Object invoice) {
    return 'الفاتورة: $invoice';
  }

  @override
  String get partnerSettlementTripNoInvoice => 'لا يوجد رقم فاتورة';

  @override
  String get partnerSettlementExtraChargesTitle => 'رسوم إضافية';

  @override
  String get partnerSettlementExtraChargesHint =>
      'رسوم ثابتة لم تُحتسب لكل طلب — اشتراك، وقت انتظار، أو رسوم رحلة مرتجعة.';

  @override
  String get partnerSettlementAddCharge => 'إضافة رسوم';

  @override
  String get partnerSettlementChargeLabel => 'الوصف';

  @override
  String get partnerSettlementChargeAmount => 'المبلغ';

  @override
  String get partnerSettlementNoCharges => 'لم تتم إضافة أي رسوم إضافية.';

  @override
  String get partnerSettlementRemoveCharge => 'إزالة الرسوم';

  @override
  String get partnerSettlementFeesSubtotal => 'رسوم الرحلات';

  @override
  String get partnerSettlementChargesSubtotal => 'الرسوم الإضافية';

  @override
  String get partnerSettlementGrandTotal => 'الإجمالي المراد تحويله';

  @override
  String get partnerSettlementBankAccountOptional => 'الحساب البنكي (اختياري)';

  @override
  String get partnerSettlementSettleButton => 'تسوية';

  @override
  String get partnerSettlementConfirmTitle => 'تأكيد التحويل البنكي';

  @override
  String get partnerSettlementConfirmMessage =>
      'سيتم نشر تحويل بنكي فعلي. راجع الإجماليات قبل المتابعة.';

  @override
  String partnerSettlementConfirmTripsLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رحلة متفق عليها',
      one: 'رحلة واحدة متفق عليها',
      zero: 'لا توجد رحلات محددة',
    );
    return '$_temp0';
  }

  @override
  String partnerSettlementConfirmChargesLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رسوم إضافية',
      one: 'رسم إضافي واحد',
      zero: 'لا توجد رسوم إضافية',
    );
    return '$_temp0';
  }

  @override
  String get partnerSettlementNothingToSettle =>
      'لا يوجد شيء محدد — حدد رحلة واحدة على الأقل أو أضف رسومًا.';

  @override
  String partnerSettlementSettledMessage(Object journalEntry) {
    return 'تمت التسوية. القيد اليومي $journalEntry.';
  }

  @override
  String get partnerSettlementSalesEmptyBalances =>
      'لا توجد عمولات غير مسواة لشركاء المبيعات.';

  @override
  String partnerSettlementOrderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب',
      one: 'طلب واحد',
    );
    return '$_temp0';
  }

  @override
  String partnerSettlementOnlineCashSplit(Object online, Object cash) {
    return 'أونلاين $online • نقدي $cash';
  }

  @override
  String get partnerSettlementCommissionLabel => 'العمولة';

  @override
  String get partnerSettlementVatLabel => 'ضريبة القيمة المضافة';

  @override
  String get partnerSettlementFeeTotalLabel => 'إجمالي الرسوم';

  @override
  String get partnerSettlementSettleCommissionButton => 'تسوية العمولة';

  @override
  String get partnerSettlementSalesConfirmTitle => 'تأكيد تسوية العمولة';

  @override
  String get partnerSettlementSalesConfirmMessage =>
      'سيتم نشر قيد اعتراف بالعمولة وضريبة القيمة المضافة. راجع الإجماليات قبل المتابعة.';

  @override
  String get partnerSettlementSalesNothingToSettle =>
      'لا توجد معاملات غير مسواة لهذا الشريك.';

  @override
  String get cashTransferFromAccount => 'من حساب';

  @override
  String get cashTransferToAccount => 'إلى حساب';

  @override
  String get cashTransferPostingToday => 'الترحيل: اليوم';

  @override
  String cashTransferPostingDate(Object date) {
    return 'الترحيل: $date';
  }

  @override
  String get cashTransferRemarkOptional => 'ملاحظة (اختياري)';

  @override
  String get cashTransferFrom => 'من';

  @override
  String get cashTransferTo => 'إلى';

  @override
  String get cashTransferAccountsMustDiffer => 'يجب أن يكون الحسابان مختلفين';

  @override
  String get cashTransferSelectAccount => 'اختر الحساب';

  @override
  String cashTransferBefore(Object amount) {
    return 'قبل: $amount';
  }

  @override
  String cashTransferAfter(Object amount) {
    return 'بعد: $amount';
  }

  @override
  String get cashTransferNoAccountsFound => 'لا توجد حسابات';

  @override
  String cashTransferJournalEntry(Object entry) {
    return 'قيد اليومية: $entry';
  }

  @override
  String cashTransferFailed(Object error) {
    return 'فشل: $error';
  }

  @override
  String get postingDateConfirmationTitle => 'تأكيد تاريخ الترحيل';

  @override
  String get postingDateConfirmationMessage =>
      'يرجى تأكيد تاريخ الترحيل قبل الإرسال.';

  @override
  String postingDateConfirmationDate(Object date) {
    return 'تاريخ الترحيل: $date';
  }

  @override
  String get postingDateConfirmationDates => 'تواريخ الترحيل:';

  @override
  String postingDateTimeConfirmationDate(Object dateTime) {
    return 'تاريخ ووقت الترحيل: $dateTime';
  }

  @override
  String get postingDateTimeConfirmationDates => 'تواريخ وأوقات الترحيل:';

  @override
  String get postingDatePickerHelp => 'اختر تاريخ الترحيل';

  @override
  String get postingTimePickerHelp => 'اختر وقت الترحيل';

  @override
  String get menuInventoryCount => 'جرد المخزون';

  @override
  String get courierLaunchPinCardTitle => 'موقع التوصيل';

  @override
  String get courierLaunchPinCardMissing =>
      'هذا العنوان ليس عليه موقع بعد. الصق رابط الموقع أو حدد النقطة على الخريطة ليصل المندوب إلى الباب.';

  @override
  String get courierLaunchPinCardRequired =>
      'لا يمكن إنشاء طلب التوصيل قبل تحديد موقع العنوان على الخريطة.';

  @override
  String get courierLaunchPinCardPinned => 'العنوان عليه موقع على الخريطة';

  @override
  String get courierLaunchPinCardChecking => 'جارٍ فحص موقع العنوان…';

  @override
  String get courierLaunchPinAddAction => 'إضافة موقع';

  @override
  String get courierLaunchPinSave => 'حفظ الموقع';

  @override
  String get courierLaunchPinRequiredRefusal =>
      'عنوان التوصيل يحتاج موقعاً على الخريطة. أضف الموقع ثم أنشئ الطلب مرة أخرى.';

  @override
  String get courierLaunchPinSheetTitle => 'إضافة موقع على الخريطة';

  @override
  String get courierLaunchPinSheetHint =>
      'الصق رابط خرائط جوجل أو حدد النقطة على الخريطة.';

  @override
  String courierLaunchPinPicked(Object coords) {
    return 'تم تحديد النقطة $coords';
  }

  @override
  String get courierLaunchPinSaved => 'تم حفظ الموقع.';

  @override
  String get courierLaunchPinKept =>
      'العنوان عليه موقع أدق بالفعل، لذلك تم الإبقاء عليه.';

  @override
  String get courierLaunchPinSaveFailed => 'تعذر حفظ الموقع.';

  @override
  String get courierLaunchPinNoAddress =>
      'لا يوجد عنوان توصيل لهذا الطلب لإضافة موقع له.';

  @override
  String get courierLaunchTrackingShare => 'مشاركة رابط التتبع';

  @override
  String get courierLaunchTrackingSheetTitle => 'رابط التتبع';

  @override
  String get courierLaunchTrackingSheetHint =>
      'يتابع العميل طلبه لحظة بلحظة من هذا الرابط.';

  @override
  String get courierLaunchTrackingCodeLabel => 'كود الاستلام';

  @override
  String get courierLaunchTrackingCodeHint =>
      'يعطي العميل هذا الكود للمندوب عند التسليم.';

  @override
  String get courierLaunchTrackingCopyCode => 'نسخ الكود';

  @override
  String get courierLaunchTrackingCodeCopied => 'تم نسخ الكود.';

  @override
  String get courierLaunchTrackingCopyLink => 'نسخ الرابط';

  @override
  String get courierLaunchTrackingLinkCopied => 'تم نسخ الرابط.';

  @override
  String get courierLaunchTrackingSendWhatsApp => 'إرسال عبر واتساب';

  @override
  String get courierLaunchTrackingShareOther => 'مشاركة…';

  @override
  String get courierLaunchTrackingLinkFailed => 'تعذر الحصول على رابط التتبع.';

  @override
  String get courierLaunchTimelineTitle => 'الجدول الزمني للتوصيل';

  @override
  String courierLaunchTimelineCourier(Object name) {
    return 'المندوب: $name';
  }

  @override
  String get courierLaunchTimelineStages => 'الوقت لكل مرحلة';

  @override
  String courierLaunchTimelineTotal(Object minutes) {
    return 'الإجمالي $minutes دقيقة';
  }

  @override
  String courierLaunchTimelineMinutes(Object minutes) {
    return '$minutes دقيقة';
  }

  @override
  String courierLaunchTimelineTarget(Object minutes) {
    return 'المستهدف $minutes دقيقة';
  }

  @override
  String get courierLaunchTimelineOver => 'تجاوز المستهدف';

  @override
  String get courierLaunchTimelineMapTitle => 'أماكن الأحداث';

  @override
  String get courierLaunchEventCreated => 'إنشاء الطلب';

  @override
  String get courierLaunchEventAccepted => 'تم القبول';

  @override
  String get courierLaunchEventInProgress => 'قيد التحضير';

  @override
  String get courierLaunchEventOutForDelivery => 'خرج للتوصيل';

  @override
  String get courierLaunchEventLeftBranch => 'غادر الفرع';

  @override
  String get courierLaunchEventLegStarted => 'بدأ التوجه للعميل';

  @override
  String get courierLaunchEventArrived => 'وصل إلى العميل';

  @override
  String get courierLaunchEventDelivered => 'تم التسليم';

  @override
  String get courierLaunchEventFailed => 'فشل التسليم';

  @override
  String get courierLaunchEventBackAtBranch => 'عاد إلى الفرع';

  @override
  String get courierLaunchSegmentPrep => 'التحضير';

  @override
  String get courierLaunchSegmentDispatchWait => 'انتظار الخروج';

  @override
  String get courierLaunchSegmentTravel => 'الطريق';

  @override
  String get courierLaunchSegmentAtDoor => 'عند الباب';

  @override
  String get courierLaunchSegmentReturn => 'العودة للفرع';

  @override
  String get addressPinTitle => 'تصحيح موقع التوصيل';

  @override
  String get addressPinCurrentPin => 'الموقع الحالي';

  @override
  String get addressPinNoPinYet => 'لم يتم تحديد موقع بعد';

  @override
  String get addressPinProposeNew => 'اقتراح موقع جديد';

  @override
  String get addressPinPickOnMap => 'تحديد على الخريطة';

  @override
  String get addressPinUseThisPoint => 'استخدام هذه النقطة';

  @override
  String get addressPinPreviewChanges => 'معاينة التغيير';

  @override
  String get addressPinWillUpdate => 'سيتم تحديث الموقع.';

  @override
  String get addressPinWillKeepExisting =>
      'تم الاحتفاظ بالموقع الحالي — فهو يملك ثقة مساوية أو أعلى بالفعل.';

  @override
  String addressPinMovedBy(Object meters) {
    return 'سينتقل الموقع حوالي $meters م عن موضعه الحالي.';
  }

  @override
  String get addressPinPermissionNote =>
      'فقط مدير الخط يمكنه اعتماد تصحيح الموقع.';

  @override
  String get addressPinCommit => 'حفظ التصحيح';

  @override
  String get addressPinNoteLabel => 'ما الخطأ؟ (اختياري)';

  @override
  String get addressPinSaveSuccessAccepted => 'تم تحديث الموقع.';

  @override
  String get addressPinSaveSuccessRejected =>
      'تم الاحتفاظ بالموقع الحالي — فهو يملك ثقة مساوية أو أعلى بالفعل.';

  @override
  String get addressPinFixTooltip => 'تصحيح موقع التوصيل';

  @override
  String get addressPinDryRunFailed => 'تعذرت معاينة هذا التغيير.';

  @override
  String addressPinSourceLabel(Object source) {
    return 'المصدر: $source';
  }

  @override
  String addressPinConfidenceLabel(int rank) {
    return 'درجة الثقة: $rank';
  }

  @override
  String addressPinAccuracyLabel(Object meters) {
    return 'الدقة حوالي $meters م';
  }

  @override
  String get addressPinAccuracyUnknown => 'الدقة غير معروفة';

  @override
  String addressPinVerifiedOn(Object date) {
    return 'تم التحقق في $date';
  }

  @override
  String get addressPinStoredLinkLabel => 'الرابط الأصلي الملصق';

  @override
  String get addressPinSourceTerritoryCentroid => 'مركز المنطقة (احتياطي)';

  @override
  String get addressPinSourcePosLink => 'رابط ملصق عند إنشاء الطلب';

  @override
  String get addressPinSourceCustomerPin => 'موقع مشارك من العميل';

  @override
  String get addressPinSourceCourierWeb => 'تسجيل دخول المندوب (ويب)';

  @override
  String get addressPinSourceCourierVerified => 'تسجيل دخول المندوب (موثّق)';

  @override
  String get addressPinSourceManualOverride => 'تصحيح يدوي';

  @override
  String get addressPinSourceUnknown => 'غير معروف';

  @override
  String get rosterBulkSelectHint =>
      'اضغط على الأيام لتحديدها. الضغط على يوم في صف شخص آخر يبدأ تحديداً جديداً له.';

  @override
  String rosterBulkSelectionCount(int count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تحديد $count أيام لـ $name',
      one: 'تم تحديد يوم واحد لـ $name',
    );
    return '$_temp0';
  }

  @override
  String get rosterBulkAssignShift => 'تعيين وردية للجميع';

  @override
  String get rosterBulkMarkOff => 'تعليم الجميع إجازة';

  @override
  String get rosterBulkClearOff => 'إلغاء الإجازة (الكل)';

  @override
  String get rosterBulkCancelSelection => 'إلغاء التحديد';

  @override
  String rosterBulkConfirmOffTitle(int count) {
    return 'تعليم $count أيام كإجازة؟';
  }

  @override
  String rosterBulkConfirmOffBody(Object name) {
    return 'لن يتمكن $name من تسجيل الحضور في هذه الأيام حتى تتم جدولته مرة أخرى.';
  }

  @override
  String get rosterBulkApplying => 'جارٍ التطبيق…';

  @override
  String get rosterBulkPartialFailureTitle => 'تعذر تحديث بعض الأيام';

  @override
  String rosterBulkPartialFailureBody(int applied, int total) {
    return 'تم تطبيق $applied من $total.';
  }

  @override
  String get rosterBulkAllFailed => 'تعذر تحديث أي من الأيام المحددة.';

  @override
  String rosterBulkSuccess(int count) {
    return 'تم تحديث $count يوم.';
  }

  @override
  String get rosterBulkViewFailures => 'عرض التفاصيل';

  @override
  String get inventoryCountOfflineUsingCache =>
      'غير متصل: سيتم استخدام البيانات المخزنة';

  @override
  String inventoryCountConfirmAllBeforeSubmit(int remaining) {
    return 'يرجى تأكيد جميع الأصناف قبل الإرسال ($remaining متبقي)';
  }

  @override
  String get inventoryCountConfirmAtLeastOne =>
      'أكد صنفًا واحدًا على الأقل قبل الإرسال';

  @override
  String inventoryCountSubmitted(Object result) {
    return 'تم الإرسال: $result';
  }

  @override
  String get inventoryCountNoDifferences => 'لا توجد فروقات';

  @override
  String get inventoryCountUncategorized => 'غير مصنف';

  @override
  String get inventoryCountManagerAccessRequired =>
      'هذه الشاشة متاحة للمدير فقط';

  @override
  String get inventoryCountSelectWarehouse => 'اختر المخزن';

  @override
  String get inventoryCountEnforceAll => 'إلزام تأكيد الكل';

  @override
  String inventoryCountConfirmedProgress(int confirmed, int total) {
    return 'تم تأكيد $confirmed / $total';
  }

  @override
  String get inventoryCountClearAllEnteredData => 'مسح كل البيانات المدخلة';

  @override
  String get inventoryCountAllEnteredDataCleared =>
      'تم مسح كل البيانات المدخلة';

  @override
  String inventoryCountCurrentAmount(Object amount, Object uom) {
    return 'الحالي: $amount $uom';
  }

  @override
  String get inventoryCountDecrease => 'تقليل';

  @override
  String get inventoryCountCount => 'العدد';

  @override
  String get inventoryCountIncrease => 'زيادة';

  @override
  String inventoryCountValuation(Object amount, Object uom) {
    return 'التقييم: $amount / $uom';
  }

  @override
  String get inventoryCountDeltaLabel => 'الفرق: ';

  @override
  String get inventoryCountSubmitCount => 'إرسال الجرد';

  @override
  String get inventoryCountSetupStep => 'الإعداد';

  @override
  String get inventoryCountBlindEntryStep => 'إدخال الكميات';

  @override
  String get inventoryCountReviewStep => 'مراجعة الفروقات';

  @override
  String get inventoryCountSpotCount => 'جرد جزئي';

  @override
  String get inventoryCountSpotCountDescription =>
      'أرسل فقط الأصناف التي قمت بعدّها.';

  @override
  String get inventoryCountFullWarehouseCountDescription =>
      'يجب عد كل الأصناف المحملة قبل الإرسال النهائي.';

  @override
  String get inventoryCountWarehouseLabel => 'المخزن';

  @override
  String get inventoryCountPostingDateLabel => 'تاريخ الترحيل';

  @override
  String get inventoryCountCountModeLabel => 'نوع الجرد';

  @override
  String get inventoryCountContinueCount => 'متابعة الجرد';

  @override
  String get inventoryCountStartCount => 'بدء الجرد';

  @override
  String get inventoryCountBackToSetup => 'العودة إلى الإعداد';

  @override
  String get inventoryCountReviewButton => 'مراجعة الفروقات';

  @override
  String get inventoryCountBackToCounting => 'العودة إلى العد';

  @override
  String inventoryCountFilteredItems(int visible, int total) {
    return '$visible من $total صنف';
  }

  @override
  String get inventoryCountCountedStatus => 'تم العد';

  @override
  String get inventoryCountPendingStatus => 'قيد الانتظار';

  @override
  String get inventoryCountClearEntry => 'مسح الإدخال';

  @override
  String get inventoryCountSummaryCountedItems => 'الأصناف المعدودة';

  @override
  String get inventoryCountSummaryChangedItems => 'الأصناف المتغيرة';

  @override
  String get inventoryCountSummaryMissingItems => 'الأصناف غير المعدودة';

  @override
  String get inventoryCountReviewDiscrepancies => 'الفروقات';

  @override
  String get inventoryCountReviewNoCountedItems => 'لم يتم عد أي صنف بعد.';

  @override
  String get inventoryCountReviewNoDiscrepancies => 'لا توجد فروقات حتى الآن.';

  @override
  String get inventoryCountReviewUnchanged => 'الأصناف المعدودة بدون فرق';

  @override
  String get inventoryCountReviewMissing => 'الأصناف غير المعدودة';

  @override
  String inventoryCountCountedAmount(Object amount, Object uom) {
    return 'المعدود: $amount $uom';
  }

  @override
  String inventoryCountStockEquivalent(Object amount, Object uom) {
    return 'المعادِل بالمخزون: $amount $uom';
  }

  @override
  String get inventoryCountMissingItemNote => 'لم يتم عد هذا الصنف بعد';

  @override
  String get inventoryCountBatchTracked => 'يتتبع بالدفعات';

  @override
  String get inventoryCountSerialTracked => 'يتتبع بالأرقام التسلسلية';

  @override
  String get menuEndShift => 'إنهاء الشيفت';

  @override
  String get menuHome => 'الرئيسية';

  @override
  String get menuSettings => 'الإعدادات';

  @override
  String get menuLogout => 'تسجيل الخروج';

  @override
  String get menuLanguage => 'اللغة';

  @override
  String get menuLanguageEnglish => 'الإنجليزية';

  @override
  String get menuLanguageArabic => 'العربية';

  @override
  String menuSelectedLanguage(Object language) {
    return 'اللغة الحالية: $language';
  }

  @override
  String menuConfirmLanguage(Object language) {
    return 'هل تريد تغيير اللغة إلى $language؟';
  }

  @override
  String get commonConfirm => 'تأكيد';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonAdd => 'إضافة';

  @override
  String get commonChoose => 'اختر';

  @override
  String get commonSearchItems => 'ابحث عن الأصناف';

  @override
  String get commonSearchSuppliers => 'ابحث عن الموردين';

  @override
  String get commonNoItems => 'لا يوجد أصناف';

  @override
  String get commonNoSuppliers => 'لا يوجد موردون';

  @override
  String get commonQtyLabel => 'الكمية:';

  @override
  String get commonRateLabel => 'السعر:';

  @override
  String commonAmountValue(Object amount) {
    return 'المبلغ: $amount';
  }

  @override
  String commonTotalValue(Object amount) {
    return 'الإجمالي: $amount';
  }

  @override
  String commonNameWithCode(Object code, Object name) {
    return '$name ($code)';
  }

  @override
  String get commonUomLabel => 'الوحدة:';

  @override
  String commonUomValue(Object uom) {
    return 'الوحدة: $uom';
  }

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonOk => 'حسناً';

  @override
  String get commonOnline => 'متصل';

  @override
  String get commonOffline => 'غير متصل';

  @override
  String get commonError => 'خطأ';

  @override
  String commonErrorWithDetails(Object details) {
    return 'خطأ: $details';
  }

  @override
  String get userErrorOffline =>
      'تعذّر الاتصال بالخادم. راجع اتصالك وحالة العملية قبل المحاولة مرة أخرى.';

  @override
  String get userErrorTimeout =>
      'استغرق الطلب وقتًا طويلًا. تحقّق من حالة العملية قبل المحاولة مرة أخرى.';

  @override
  String get userErrorCertificate => 'تعذّر تأمين الاتصال بالخادم.';

  @override
  String get userErrorCancelled => 'تم إلغاء الطلب.';

  @override
  String get userErrorUnauthorized => 'انتهت الجلسة. سجّل الدخول مرة أخرى.';

  @override
  String get userErrorForbidden => 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';

  @override
  String get userErrorNotFound => 'العنصر المطلوب غير موجود.';

  @override
  String get userErrorConflict =>
      'تتعارض العملية مع بيانات موجودة. حدّث البيانات وراجع حالة العملية قبل المتابعة.';

  @override
  String get userErrorRateLimited =>
      'توجد محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.';

  @override
  String get userErrorServer =>
      'حدثت مشكلة في الخادم. راجع حالة العملية قبل الإرسال مرة أخرى.';

  @override
  String get userErrorUnexpected => 'حدث خطأ غير متوقع.';

  @override
  String get userErrorValidationFallback =>
      'راجِع البيانات المدخلة وحاول مرة أخرى.';

  @override
  String get userErrorDraftLimit =>
      'وصلت إلى الحد الأقصى للمسودات. احذف مسودة غير مستخدمة قبل إنشاء أخرى.';

  @override
  String get userErrorReopenOrder =>
      'بيانات الطلب ناقصة أو قديمة. أغلق الطلب وافتحه مرة أخرى لإعادة تحميل الأصناف.';

  @override
  String get userErrorShippingAddress =>
      'عنوان الشحن لم يعد متاحًا. اختر عنوانًا صالحًا لهذا العميل.';

  @override
  String get userErrorInsufficientStock =>
      'المخزون غير كافٍ. راجع الكمية المتاحة أو تواصل مع الفرع.';

  @override
  String get userErrorShiftRequired =>
      'يجب وجود وردية مفتوحة. راجع حالة ورديتك قبل المتابعة.';

  @override
  String get userErrorAlreadyProcessed =>
      'تم تنفيذ هذه العملية بالفعل. راجع حالة الطلب قبل الإرسال مرة أخرى.';

  @override
  String get userErrorTransferReceiptRequired =>
      'الدفع بإنستاباي أو المحفظة محتاج إيصال تحويل متأكد. ارفع صورة تحويل العميل على الطلب ده وخلي المدير يأكدها، وبعدين ادفع تاني.';

  @override
  String get userErrorRequiredFields => 'أكمل البيانات المطلوبة قبل المتابعة.';

  @override
  String get userErrorScreenFailed =>
      'تعذّر عرض هذه الصفحة. أغلقها وافتحها مرة أخرى.';

  @override
  String get commonSubmit => 'إرسال';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonCustomerLabel => 'العميل';

  @override
  String get commonPosProfileLabel => 'ملف نقطة البيع';

  @override
  String get commonTotalLabel => 'الإجمالي';

  @override
  String get commonAmountLabel => 'المبلغ';

  @override
  String get commonDateLabel => 'التاريخ';

  @override
  String get commonCourierLabel => 'الساعي';

  @override
  String get commonDeliveryLabel => 'التوصيل';

  @override
  String get commonItemsLabel => 'الأصناف';

  @override
  String get commonItemLabel => 'صنف';

  @override
  String get commonNotesLabel => 'ملاحظات';

  @override
  String get commonPaymentLabel => 'الدفع';

  @override
  String get commonOutstandingLabel => 'المتبقي';

  @override
  String get commonUploadedByLabel => 'تم الرفع بواسطة';

  @override
  String get commonReasonLabel => 'السبب';

  @override
  String get ofdShortageDialogTitle => 'اعتماد عجز المخزون قبل الإرسال';

  @override
  String get ofdShortageDialogMessage =>
      'هذه الأصناف بها عجز في مخزن التسليم. أضف سببًا للمتابعة إلى حالة خارج للتوصيل.';

  @override
  String ofdShortageLine(
    String item,
    String required,
    String available,
    String warehouse,
  ) {
    return '$item: المطلوب $required، المتاح $available، المخزن $warehouse';
  }

  @override
  String get ofdShortageReasonHint => 'اشرح لماذا يجب متابعة الإرسال رغم العجز';

  @override
  String get ofdShortageReasonRequired => 'أدخل سبب العجز للمتابعة';

  @override
  String get ofdShortageApprove => 'اعتماد والمتابعة';

  @override
  String get commonNotSpecified => 'غير محدد';

  @override
  String get commonWalkIn => 'عميل مباشر';

  @override
  String get commonScheduled => 'مجدول';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonNew => 'جديد';

  @override
  String get commonPreview => 'معاينة';

  @override
  String commonByUser(Object user) {
    return 'بواسطة $user';
  }

  @override
  String commonQtyWithUom(Object uom) {
    return 'الكمية ($uom)';
  }

  @override
  String orderAlertTitle(Object invoiceId) {
    return 'طلب جديد: $invoiceId';
  }

  @override
  String get orderAlertNoLineItems => 'لا توجد بنود';

  @override
  String orderAlertMoreItems(Object count) {
    return '+$count صنف إضافي';
  }

  @override
  String get orderAlertMuteAlarm => 'كتم التنبيه';

  @override
  String get orderAlertUnmuteAlarm => 'إلغاء كتم التنبيه';

  @override
  String get orderAlertAccepting => 'جارٍ القبول...';

  @override
  String get orderAlertAcceptOrder => 'قبول الطلب';

  @override
  String get posDraftDeleteTitle => 'حذف المسودة';

  @override
  String posDraftDeleteBody(Object label) {
    return 'هل تريد حذف \"$label\"؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String posDraftLimitReached(Object max) {
    return 'تم الوصول إلى الحد الأقصى للمسودات ($max). احذف مسودة لإنشاء مسودة جديدة.';
  }

  @override
  String get expensesTitle => 'المصروفات';

  @override
  String get expensesRefreshTooltip => 'تحديث';

  @override
  String get expensesNewExpense => 'مصروف جديد';

  @override
  String get expensesRecorded => 'تم تسجيل المصروف';

  @override
  String get expensesSubmitted => 'تم إرسال المصروف لاعتماد المدير';

  @override
  String get expensesMonthLabel => 'الشهر';

  @override
  String get expensesMonthCurrent => 'الشهر الحالي';

  @override
  String get expensesEmptyTitle => 'لا توجد مصروفات مسجلة لهذا الشهر.';

  @override
  String get expensesEmptyManagerBody =>
      'استخدم زر مصروف جديد لتسجيل مصروفات الفريق.';

  @override
  String get expensesEmptyStaffBody =>
      'أرسل الطلب وسيقوم المدير بمراجعته قريبًا.';

  @override
  String get expensesFiltersClear => 'مسح الفلاتر';

  @override
  String get expensesFiltersTitle => 'تصفية حسب طريقة الدفع';

  @override
  String get expensesFiltersEmpty => 'لا يوجد مصادر دفع متاحة';

  @override
  String get expensesSummaryTotal => 'الإجمالي';

  @override
  String get expensesSummaryApproved => 'المعتمدة';

  @override
  String get expensesSummaryPending => 'قيد الاعتماد';

  @override
  String expensesSummaryReceipts(Object count) {
    return '$count إثبات';
  }

  @override
  String expensesSummaryPendingAmount(Object amount, Object count) {
    return '$count | $amount';
  }

  @override
  String get expensesReasonLabel => 'سبب الصرف (حساب مصروفات غير مباشرة)';

  @override
  String get expensesPayFromLabel => 'الدفع من';

  @override
  String get expensesAmountLabel => 'القيمة';

  @override
  String get expensesAmountHint => 'أدخل القيمة';

  @override
  String get expensesAmountInvalid => 'من فضلك أدخل قيمة صحيحة';

  @override
  String get expensesDateLabel => 'تاريخ المصروف';

  @override
  String get expensesReasonRequired => 'اختر سببًا';

  @override
  String get expensesPaymentSourceRequired => 'اختر مصدر الدفع';

  @override
  String get expensesRemarksLabel => 'ملاحظات (اختياري)';

  @override
  String get expensesSubmitManager => 'تسجيل المصروف';

  @override
  String get expensesSubmitStaff => 'إرسال للاعتماد';

  @override
  String get expensesNoOptions =>
      'لا يمكن إنشاء مصروف قبل تفعيل حساب السبب وجهة الدفع.';

  @override
  String get expensesApprove => 'اعتماد';

  @override
  String get expensesPendingStatus => 'قيد الاعتماد';

  @override
  String get expensesApprovedStatus => 'معتمد';

  @override
  String get expensesDraftStatus => 'مسودة';

  @override
  String get expensesJournalEntry => 'قيد اليومية';

  @override
  String get expensesPosProfile => 'ملف نقطة البيع';

  @override
  String get expensesPayingAccount => 'حساب الدفع';

  @override
  String get expensesReasonAccount => 'حساب المصروف';

  @override
  String get expensesTimelineTitle => 'الخط الزمني';

  @override
  String get expensesTimelineEmpty => 'لا يوجد سجل زمني';

  @override
  String get expensesPullToRefresh => 'اسحب للتحديث';

  @override
  String languageChanged(Object language) {
    return 'تم تغيير اللغة إلى $language.';
  }

  @override
  String get purchaseTitle => 'فاتورة شراء';

  @override
  String get purchaseSupplierSectionTitle => 'المورد';

  @override
  String get purchaseTapToPickSupplier => 'اضغط لاختيار المورد';

  @override
  String get purchaseItemsSectionTitle => 'الأصناف';

  @override
  String get purchaseShippingLabel => 'الشحن (مصاريف الشحن والمناولة):';

  @override
  String get purchaseSubmit => 'إنشاء فاتورة شراء';

  @override
  String get purchaseSelectSupplier => 'اختر المورد';

  @override
  String get purchaseRecent => 'الأحدث';

  @override
  String get purchaseSupplierDisabledSuffix => ' (معطل)';

  @override
  String get purchaseNoItemsInCart => 'لا توجد أصناف في السلة';

  @override
  String purchaseCreated(Object invoice) {
    return 'تم إنشاء فاتورة الشراء: $invoice';
  }

  @override
  String purchaseSubmitFailed(Object error) {
    return 'فشل إنشاء الفاتورة: $error';
  }

  @override
  String get purchaseSelectPayment => 'اختر مصدر الدفع';

  @override
  String get purchasePaymentProfileSubtitle =>
      'استخدم حساب النقد المرتبط باسم ملف نقطة البيع';

  @override
  String get purchasePaymentInstapayTitle => 'إنستا باي (بنك)';

  @override
  String get purchasePaymentInstapaySubtitle =>
      'استخدم الحساب البنكي المرتبط بإنستا باي';

  @override
  String get purchasePaymentCashTitle => 'نقدي';

  @override
  String get purchasePaymentCashSubtitle =>
      'استخدم حساب النقد الافتراضي للشركة';

  @override
  String get posProfileSelectionTitle => 'اختر ملف نقطة البيع';

  @override
  String get posProfileSelectionErrorTitle => 'تعذّر تحميل ملفات نقاط البيع';

  @override
  String get posProfileSelectionNoProfilesTitle =>
      'لا توجد ملفات نقاط بيع متاحة';

  @override
  String get posProfileSelectionNoProfilesBody =>
      'تواصل مع المسؤول لإسناد ملف نقطة بيع لك';

  @override
  String get posProfileSelectionUnknownProfile => 'ملف غير معروف';

  @override
  String posProfileSelectionWarehouseLabel(Object warehouse) {
    return 'المخزن: $warehouse';
  }

  @override
  String get posProfileSelectionPrompt => 'اختر ملف نقطة البيع:';

  @override
  String get posProfileSelectionCycleHint => 'اختر ملف نقطة البيع';

  @override
  String get posProfileSelectionShortFallback => 'نقطة بيع';

  @override
  String get shiftStartTitle => 'بدء الشيفت';

  @override
  String get shiftEndTitle => 'إنهاء الشيفت';

  @override
  String get shiftNoActive => 'لا يوجد شيفت مفتوح.';

  @override
  String get shiftBackToPos => 'العودة لنقطة البيع';

  @override
  String get shiftOpeningPrompt => 'قم بعدّ نقدية البداية ثم أدخلها:';

  @override
  String shiftPosProfile(Object profile) {
    return 'ملف نقطة البيع: $profile';
  }

  @override
  String shiftAccount(Object account) {
    return 'الحساب: $account';
  }

  @override
  String shiftSystemBalance(Object amount) {
    return 'الرصيد بالنظام: $amount';
  }

  @override
  String get shiftConfirmedOpeningAmount => 'رصيد البداية المؤكد';

  @override
  String get shiftCountedOpeningAmount => 'النقدية المعدودة عند البداية';

  @override
  String shiftDifferenceAmount(Object amount) {
    return 'الفرق: $amount';
  }

  @override
  String get shiftClosingPrompt => 'قم بعدّ نقدية الإغلاق ثم أدخلها:';

  @override
  String get shiftClosingAmountLabel => 'رصيد الإغلاق';

  @override
  String get shiftCountedClosingAmount => 'النقدية المعدودة عند الإغلاق';

  @override
  String get shiftBlindCountHint => 'قم بعدّ النقدية في الدرج ثم أدخل المبلغ.';

  @override
  String get shiftNoClosingPaymentMethodsTitle =>
      'تعذر إظهار حقل إدخال النقدية';

  @override
  String get shiftNoClosingPaymentMethodsBody =>
      'لا توجد وسيلة دفع متاحة لإغلاق هذا الشيفت. أعد فتح الشيفت أو تواصل مع الدعم.';

  @override
  String get shiftCashCountRequired => 'أدخل مبلغ النقدية المعدودة.';

  @override
  String get shiftCashCountInvalid => 'أدخل مبلغ نقدية صحيح.';

  @override
  String get shiftCashCountNegative => 'لا يمكن أن تكون قيمة النقدية سالبة.';

  @override
  String shiftExpectedAmount(Object amount) {
    return 'المتوقع: $amount';
  }

  @override
  String shiftLoadActiveFailed(Object error) {
    return 'تعذر تحميل الشيفت النشط: $error';
  }

  @override
  String get shiftSummaryLoadFailed => 'تعذر تحميل ملخص الشيفت.';

  @override
  String shiftLabel(Object shift) {
    return 'الشيفت: $shift';
  }

  @override
  String get shiftUnexpectedStartResponse =>
      'استجابة غير متوقعة من الخادم أثناء بدء الشيفت.';

  @override
  String get shiftUnexpectedSummaryResponse =>
      'استجابة غير متوقعة من الخادم أثناء تحميل ملخص الشيفت.';

  @override
  String get shiftUnexpectedEndResponse =>
      'استجابة غير متوقعة من الخادم أثناء إنهاء الشيفت.';

  @override
  String get shiftCourierBlockTitle => 'سوِّ أرصدة المندوبين قبل إنهاء الشيفت';

  @override
  String shiftCourierBlockBody(
    int transactions,
    int couriers,
    int invoices,
    Object profile,
  ) {
    return 'لا يزال هذا الشيفت يحتوي على $transactions حركة مندوب غير مسواة تخص $couriers مندوبًا عبر $invoices فاتورة على ملف نقطة البيع $profile.';
  }

  @override
  String get shiftCourierBlockHint =>
      'افتح أرصدة المندوبين، سوِّ ما يزال معلقًا، ثم ارجع لإكمال إنهاء الشيفت.';

  @override
  String get shiftCourierReviewButton => 'مراجعة وتسوية المندوبين';

  @override
  String shiftCourierBlockPartySummary(
    Object name,
    int transactions,
    int invoices,
  ) {
    return '$name: عدد $transactions حركة على $invoices فاتورة';
  }

  @override
  String shiftCourierBlockNetBalance(Object amount) {
    return 'صافي الرصيد: $amount';
  }

  @override
  String shiftCourierBlockMore(int count) {
    return '+$count مندوب إضافي';
  }

  @override
  String shiftOutflows(Object amount) {
    return 'المصروفات الخارجة: $amount';
  }

  @override
  String shiftNetMovement(Object amount) {
    return 'صافي الحركة: $amount';
  }

  @override
  String get shiftAccountMovements => 'حركات الحساب';

  @override
  String get shiftOther => 'أخرى';

  @override
  String shiftSubtotal(Object amount) {
    return 'الإجمالي الفرعي: $amount';
  }

  @override
  String shiftInvoices(Object count) {
    return 'الفواتير: $count';
  }

  @override
  String shiftGrandTotal(Object amount) {
    return 'إجمالي المبيعات: $amount';
  }

  @override
  String get shiftStartButton => 'بدء الشيفت';

  @override
  String get shiftEndButton => 'إنهاء الشيفت';

  @override
  String get shiftEndedSuccess => 'تم إنهاء الشيفت بنجاح.';

  @override
  String get shiftStatusActive => 'شيفت مفتوح';

  @override
  String shiftStartedAt(Object time) {
    return 'بدأ في $time';
  }

  @override
  String shiftProfileMismatch(Object activeProfile, Object selectedProfile) {
    return 'الشيفت المفتوح على $activeProfile بينما الملف المختار هو $selectedProfile.';
  }

  @override
  String get shiftAlreadyOpenByAnotherTitle => 'الشيفت مفتوح بالفعل';

  @override
  String shiftAlreadyOpenByAnotherBody(Object branch, Object user) {
    return 'نقطة البيع \"$branch\" بها شيفت مفتوح بدأه $user. يجب إغلاق هذا الشيفت أولاً.';
  }

  @override
  String get shiftRefresh => 'تحديث';

  @override
  String get shiftLogout => 'تسجيل الخروج';

  @override
  String get shiftSwitchToActiveProfile => 'التبديل لملف الشيفت المفتوح';

  @override
  String shiftOpenOnOtherProfile(Object otherProfile, Object shiftName) {
    return 'لديك شيفت مفتوح ($shiftName) على ملف \"$otherProfile\". أغلق هذا الشيفت أولاً قبل بدء شيفت جديد هنا.';
  }

  @override
  String get shiftGoToEnd => 'اذهب إلى إنهاء الشيفت';

  @override
  String get shiftAccountBalance => 'رصيد الحساب';

  @override
  String get shiftDifference => 'الفرق';

  @override
  String get shiftSalesInvoices => 'فواتير المبيعات';

  @override
  String get shiftNoDeliveryStatus => 'بدون حالة';

  @override
  String get shiftClosedSummaryTitle => 'ملخص الشيفت';

  @override
  String get shiftClosingEntry => 'قيد الإغلاق';

  @override
  String get shiftJournalCreated => 'تم تسجيل الفرق النقدي';

  @override
  String get posCartTitle => 'سلة المشتريات';

  @override
  String posCartHeader(Object count) {
    return 'السلة ($count)';
  }

  @override
  String get posCartClear => 'إفراغ السلة';

  @override
  String get posCartEmptyTitle => 'السلة فارغة';

  @override
  String get posCartEmptyBody => 'أضف أصنافًا للبدء';

  @override
  String get posCustomerUnselect => 'إزالة العميل';

  @override
  String get posCustomerAdd => 'إضافة عميل';

  @override
  String posCustomerDeliveryIncomeValue(Object amount) {
    return 'إيراد التوصيل: $amount';
  }

  @override
  String get posUnknownCustomer => 'عميل غير معروف';

  @override
  String get posCartPickupTitle => 'استلام من الفرع (بدون رسوم توصيل)';

  @override
  String get posCartPickupDescription => 'سيستلم العميل الطلب من الفرع.';

  @override
  String get posCartDeliveryDescription =>
      'سيوصل الطلب للعميل في الوقت المحدد.';

  @override
  String get posCartPickupChip => 'استلام';

  @override
  String get posCartPricingTitle => 'تسعير المدير';

  @override
  String get posCartPriceListLabel => 'قائمة الأسعار';

  @override
  String get posCartPriceListHint =>
      'استخدم القائمة الافتراضية للفرع أو اختر قائمة تانية متاحة للطلب ده.';

  @override
  String get posCartPriceListSetByPurpose => 'بتتحدد حسب غرض الطلب.';

  @override
  String get posCartPriceListAfterCustomer =>
      'هتتحدد من قائمة أسعار العميل بعد ما تختاره.';

  @override
  String get posPurposePriceListUpdated =>
      'الأسعار اتحدّثت عشان تناسب غرض الطلب. راجع السلة وبعدين أكّد الطلب تاني.';

  @override
  String get posPurposePriceListUnavailable =>
      'مقدرناش نطبّق قائمة الأسعار الخاصة بغرض الطلب ده. اختار العميل أو غيّر غرض الطلب.';

  @override
  String get posCartPriceListDefaultChip => 'افتراضي';

  @override
  String get posCartOrderPurposeLabel => 'غرض الطلب';

  @override
  String get posCartOrderPurposeHint =>
      'طبّق سياسة تجارية أو اترك الطلب عاديًا.';

  @override
  String get posCartOrderPurposeStandard => 'عادي';

  @override
  String get posCartOrderPurposeWaivesShipping => 'تم إعفاء إيراد الشحن';

  @override
  String get posCartOrderPurposeNoCourier => 'بدون مصروف مندوب';

  @override
  String get posCartOrderPurposeReasonLabel => 'السبب (اختياري)';

  @override
  String get posCartOrderPurposeReasonHint =>
      'أضف ملاحظة توضّح سبب تطبيق هذا الغرض.';

  @override
  String get posCartZeroShippingTitle => 'بدون إيراد شحن';

  @override
  String get posCartZeroShippingDescription =>
      'لا تضف إيراد الشحن على هذا الطلب.';

  @override
  String get posCartZeroShippingPriceListDefault =>
      'مفعّل تلقائيًا لهذه القائمة السعرية.';

  @override
  String get posCartZeroShippingManagedByPickup =>
      'الاستلام من الفرع يلغي رسوم التوصيل بالفعل.';

  @override
  String get posCartZeroShippingManagedByPartner =>
      'طلبات شريك البيع تلغي إيراد الشحن بالفعل.';

  @override
  String get posSubtotalLabel => 'الإجمالي الفرعي:';

  @override
  String get posDeliveryLabel => 'التوصيل:';

  @override
  String get posTotalLabel => 'الإجمالي:';

  @override
  String get posCheckoutButton => 'إتمام الطلب';

  @override
  String get posCheckoutStockExceedTitle => 'الأصناف تتجاوز المخزون المتاح';

  @override
  String get posCheckoutStockExceedMessage =>
      'الأصناف التالية في السلة تتجاوز المخزون الحالي في النظام. يمكن إنشاء الطلب، لكن التنفيذ قد يحتاج مخزونًا واردًا أو تصحيح جرد.';

  @override
  String posCheckoutStockExceedLine(
    String item,
    String requested,
    String available,
  ) {
    return '$item: المطلوب $requested، المتاح $available';
  }

  @override
  String get posCheckoutProceedAnyway => 'متابعة الطلب';

  @override
  String get posTerritoryMismatchTitle => 'عدم تطابق الفرع';

  @override
  String get posTerritoryMismatchBody => 'منطقة العميل مرتبطة بفرع POS مختلف.';

  @override
  String posTerritoryMismatchUseSelected(String profile) {
    return 'الاستمرار بالفرع المحدد: $profile';
  }

  @override
  String posTerritoryMismatchUseTerritory(String profile) {
    return 'التحويل لفرع المنطقة: $profile';
  }

  @override
  String posTerritoryMismatchNoTerritory(String profile) {
    return 'لا يوجد فرع مرتبط بالمنطقة — الاستمرار بالفرع المحدد: $profile';
  }

  @override
  String get posTerritoryMismatchCancel => 'إلغاء';

  @override
  String get posTerritoryMismatchConfirm => 'متابعة';

  @override
  String get posAmendmentDraftButton => 'إرسال التعديل';

  @override
  String get posOperationalInfoTitle => 'معلومات تشغيلية';

  @override
  String get posDeliveryExpenseLabel => 'تكلفة التوصيل:';

  @override
  String posDeliveryCostTo(Object territory) {
    return 'تكلفة التوصيل إلى $territory';
  }

  @override
  String get posDeliveryCostGeneric => 'تكلفة التوصيل';

  @override
  String get posUnknownItem => 'صنف غير معروف';

  @override
  String get posCartEditBundle => 'تعديل الباقة';

  @override
  String get posCartItemPricingDialogTitle => 'تعديل تسعير السطر';

  @override
  String posCartItemPricingBaseRate(String amount) {
    return 'سعر الكتالوج الحالي: $amount';
  }

  @override
  String get posCartItemPricingCustomRateLabel => 'سعر وحدة مخصص';

  @override
  String get posCartItemPricingDiscountAmountLabel => 'قيمة الخصم';

  @override
  String get posCartItemPricingDiscountPercentLabel => 'نسبة الخصم';

  @override
  String get posCartItemPricingDiscountHint =>
      'استخدم قيمة الخصم أو نسبة الخصم فقط، وليس الاثنين معًا.';

  @override
  String get posCartItemPricingReset => 'إلغاء التسعير';

  @override
  String get posCartItemPricingSave => 'تطبيق';

  @override
  String posCartItemCustomPriceApplied(String amount) {
    return 'سعر مخصص $amount';
  }

  @override
  String posCartItemDiscountAmountApplied(String amount) {
    return 'خصم $amount';
  }

  @override
  String posCartItemDiscountPercentApplied(String amount) {
    return 'خصم $amount%';
  }

  @override
  String get posCartItemPricingInvalidNumber => 'أدخل رقمًا صالحًا.';

  @override
  String get posCartItemPricingInvalidCustomRate =>
      'يجب أن يكون السعر المخصص صفرًا أو أكثر.';

  @override
  String get posCartItemPricingInvalidDiscountAmount =>
      'يجب أن تكون قيمة الخصم صفرًا أو أكثر.';

  @override
  String get posCartItemPricingInvalidDiscountPercent =>
      'يجب أن تكون نسبة الخصم بين 0 و100.';

  @override
  String get posCartItemPricingChooseSingleDiscount =>
      'استخدم قيمة الخصم أو نسبة الخصم فقط، وليس الاثنين معًا.';

  @override
  String get posCartItemPricingDiscountTooHigh =>
      'لا يمكن أن تتجاوز قيمة الخصم سعر الوحدة الفعلي.';

  @override
  String get posCartClearTitle => 'إفراغ السلة';

  @override
  String get posCartClearMessage =>
      'هل أنت متأكد من حذف جميع الأصناف من السلة؟';

  @override
  String get posCartClearConfirm => 'إفراغ';

  @override
  String get posDeliverySelectSlot => 'من فضلك اختر وقت التوصيل';

  @override
  String get posDeliveryDialogTitle => 'اختر وقت التوصيل';

  @override
  String get posDeliveryLoadFailed => 'فشل تحميل مواعيد التوصيل';

  @override
  String get posDeliveryEmptyTitle => 'لا توجد مواعيد توصيل متاحة';

  @override
  String get posDeliveryEmptyBody => 'برجاء مراجعة جدول مواعيد ملف نقطة البيع';

  @override
  String get posDeliveryDefaultChip => 'التالي';

  @override
  String get posDeliveryLoading => 'جارٍ تحميل مواعيد التوصيل...';

  @override
  String get posDeliveryFieldLabel => 'وقت التوصيل';

  @override
  String get posDeliveryErrorLabel => 'خطأ في تحميل المواعيد';

  @override
  String get posDeliveryNoSlotsLabel => 'لا توجد مواعيد متاحة';

  @override
  String get posDeliverySelectPrompt => 'اختر وقت التوصيل';

  @override
  String get posSalesPartnerPaymentTitle => 'دفع شريك المبيعات';

  @override
  String get posSalesPartnerPaymentDescription =>
      'اختر طريقة دفع شريك المبيعات لهذا الطلب.';

  @override
  String get posSalesPartnerPaymentCash => 'نقدًا (يُحصّل الآن)';

  @override
  String get posSalesPartnerPaymentOnline => 'أونلاين (تم الدفع بالفعل)';

  @override
  String get posCheckoutSuccess => 'تم إرسال الطلب بنجاح!';

  @override
  String posCheckoutFailed(Object error) {
    return 'فشل إرسال الطلب: $error';
  }

  @override
  String get posBundleContentsTitle => 'محتوى الباقة:';

  @override
  String get posBundleUpdated => 'تم تحديث الباقة بنجاح!';

  @override
  String get printerStatusBle => 'الطابعة: بلوتوث LE';

  @override
  String get printerStatusClassic => 'الطابعة: بلوتوث كلاسيكي';

  @override
  String get printerStatusConnecting => 'الطابعة: جاري الاتصال…';

  @override
  String get printerStatusError => 'خطأ في الطابعة';

  @override
  String get printerStatusDisconnected => 'الطابعة: غير متصلة';

  @override
  String get printerSelectTitle => 'اختيار الطابعة';

  @override
  String get printerCompatibilityTooltip => 'إعدادات توافق الطابعة';

  @override
  String get printerCompatibilityTitle => 'التوافق';

  @override
  String get printerCompatibilitySubtitle =>
      'الإعدادات الآمنة تُبقي الإيصالات العادية كنص وتستخدم الرسم النقطي فقط عند الحاجة.';

  @override
  String get printerCompatibilitySaved => 'تم حفظ إعدادات توافق الطابعة';

  @override
  String get printerCompatibilityReset => 'استعادة الإعدادات الافتراضية';

  @override
  String get printerDiagnosticsTitle => 'التشخيص';

  @override
  String printerDiagnosticsAdapter(Object state) {
    return 'المحول: $state';
  }

  @override
  String printerDiagnosticsScan(Object status) {
    return 'صلاحية الفحص: $status';
  }

  @override
  String printerDiagnosticsConnect(Object status) {
    return 'صلاحية الاتصال: $status';
  }

  @override
  String printerDiagnosticsLocation(Object status) {
    return 'صلاحية الموقع: $status';
  }

  @override
  String get printerDeviceIdLabel => 'معرّف الجهاز (MAC / Identifier)';

  @override
  String get printerConnectById => 'اتصال بالمعرّف';

  @override
  String get printerConnectingById => 'جارٍ الاتصال بالمعرّف...';

  @override
  String get printerConnecting => 'جارٍ الاتصال...';

  @override
  String get printerConnected => 'تم توصيل الطابعة';

  @override
  String get printerConnectionFailed => 'فشل الاتصال';

  @override
  String get printerForgetSavedTooltip => 'نسيان الطابعة المحفوظة';

  @override
  String get printerForgotSaved => 'تم نسيان الطابعة المحفوظة';

  @override
  String get printerRescanTooltip => 'إعادة الفحص';

  @override
  String get printerReconnecting => 'جارٍ إعادة الاتصال...';

  @override
  String get printerReconnected => 'تمت إعادة الاتصال';

  @override
  String get printerReconnectFailed => 'فشلت إعادة الاتصال';

  @override
  String get printerReconnect => 'إعادة الاتصال';

  @override
  String printerConnectedTo(Object name) {
    return 'متصل: $name';
  }

  @override
  String get printerTestPrint => 'طباعة تجريبية';

  @override
  String get printerTestSent => 'تم إرسال الطباعة التجريبية';

  @override
  String printerTestFailed(Object error) {
    return 'فشل الاختبار: $error';
  }

  @override
  String get printerBleDevices => 'أجهزة BLE';

  @override
  String get printerRescanBleTooltip => 'إعادة فحص BLE';

  @override
  String get printerNoBleDevices => 'لم يتم العثور على أجهزة BLE.';

  @override
  String get printerUnknownName => 'طابعة غير معروفة';

  @override
  String get printerConnect => 'اتصال';

  @override
  String get printerClassicDevices => 'أجهزة Classic المقترنة';

  @override
  String get printerPaperSizeLabel => 'مقاس الورق';

  @override
  String get printerPaper58mm => '58 مم';

  @override
  String get printerPaper80mm => '80 مم';

  @override
  String get printerPrintLogo => 'طباعة الشعار';

  @override
  String get printerPrintLogoHint =>
      'عطّل هذا أولًا إذا ظهرت رموز غير مفهومة أعلى الإيصال.';

  @override
  String get printerRasterizeArabic => 'تحويل النص العربي إلى صورة';

  @override
  String get printerRasterizeArabicHint =>
      'مطلوب للطابعات التي لا تدعم العربية مباشرة.';

  @override
  String get printerRasterizeStyledText => 'تحويل النص المنسق إلى صورة';

  @override
  String get printerRasterizeStyledTextHint =>
      'فعّل هذا فقط إذا كانت الطابعة تدعم النص النقطي بثبات.';

  @override
  String get printerRasterWidthLabel => 'عرض الصورة النقطية (بكسل)';

  @override
  String get printerCodeTableLabel => 'جدول الترميز';

  @override
  String get printerBleChunkSizeLabel => 'حجم حزمة BLE';

  @override
  String get printerBleChunkDelayLabel => 'مهلة حزمة BLE (مللي ثانية)';

  @override
  String get printerClassicChunkSizeLabel => 'حجم حزمة Classic';

  @override
  String get printerClassicChunkDelayLabel => 'مهلة حزمة Classic (مللي ثانية)';

  @override
  String get printerClassicTailDelayLabel => 'مهلة نهاية Classic (مللي ثانية)';

  @override
  String get printerRefreshClassicTooltip => 'تحديث قائمة Classic';

  @override
  String get printerNoClassicDevices =>
      'لا توجد طابعات Classic مقترنة. تأكد من إقران الطابعة من إعدادات البلوتوث بالنظام وتفعيل الموقع (Android 8).';

  @override
  String printerClassicMacConnected(Object mac) {
    return '$mac  (Classic)';
  }

  @override
  String get printerDisconnect => 'قطع الاتصال';

  @override
  String get printerConnectingClassic => 'جارٍ الاتصال (Classic)...';

  @override
  String printerLastSavedNotAdvertising(Object id) {
    return 'آخر طابعة محفوظة: $id\nهي غير مرئية الآن عبر البث، ويمكنك محاولة إعادة الاتصال.';
  }

  @override
  String get branchFilterTitle => 'تصفية الفروع';

  @override
  String get branchFilterAllBranches => 'جميع الفروع';

  @override
  String get branchFilterApply => 'تطبيق';

  @override
  String get websocketCollectCashTitle => 'تحصيل النقدية';

  @override
  String get websocketCollectCashMessage =>
      'حصّل كامل قيمة الطلب الآن من مندوب المبيعات.';

  @override
  String websocketInvoiceLabel(Object invoice) {
    return 'الفاتورة: $invoice';
  }

  @override
  String get systemStatusChecking => 'جاري الفحص...';

  @override
  String get systemStatusRealtime => 'تحديث فوري';

  @override
  String get systemStatusNoRealtime => 'بدون تحديث فوري';

  @override
  String get systemStatusSynced => 'تمت المزامنة';

  @override
  String systemStatusPendingCount(Object count) {
    return '$count قيد المزامنة';
  }

  @override
  String get systemStatusCouriers => 'المندوبون';

  @override
  String systemStatusCourierCount(Object count) {
    return '$count مندوب';
  }

  @override
  String get systemStatusPartnerChip => 'شريك';

  @override
  String get systemStatusSalesPartnerFallback => 'شريك المبيعات';

  @override
  String get systemStatusSyncComplete => 'تمت المزامنة وتحديث بيانات المندوبين';

  @override
  String get systemStatusForceSyncTooltip => 'تنفيذ مزامنة فورية';

  @override
  String get courierBalancesTitle => 'أرصدة المندوبين';

  @override
  String get courierBalancesEmpty => 'لا يوجد مندوبون.';

  @override
  String get courierBalancesSettledLabel => 'مُسوى';

  @override
  String get courierBalancesPayCourierLabel => 'سدد للمندوب';

  @override
  String get courierBalancesCourierPaysUsLabel => 'المندوب يسدد لنا';

  @override
  String courierBalancesDetailsTitle(Object courier) {
    return 'التفاصيل – $courier';
  }

  @override
  String courierBalancesCityOrderLine(
    Object city,
    Object order,
    Object shipping,
  ) {
    return 'المدينة: $city\nالطلب: $order • الشحن: $shipping';
  }

  @override
  String get courierBalancesNetLabel => 'الصافي';

  @override
  String get courierSettlementComplete => 'اكتملت التسوية';

  @override
  String get courierSettlementFailed => 'فشلت التسوية';

  @override
  String get courierSettleButton => 'تسوية';

  @override
  String courierPayCourierAmount(Object amount) {
    return 'سداد للمندوب $amount';
  }

  @override
  String courierCollectAmount(Object amount) {
    return 'تحصيل $amount';
  }

  @override
  String courierSettleAllInvoicesQuestion(int count) {
    return 'تسوية كل الفواتير ($count) لهذا المندوب؟';
  }

  @override
  String get courierSettled => 'تمت التسوية';

  @override
  String get courierSettleAllButton => 'تسوية الكل';

  @override
  String courierSettleAllDialogTitle(Object action, Object total) {
    return '$action - الإجمالي $total';
  }

  @override
  String courierSettleAllWillSettle(int count) {
    return 'سيتم تسوية عدد $count فاتورة.';
  }

  @override
  String get courierInvoicesLabel => 'الفواتير:';

  @override
  String get courierSettleAllCollectInfo =>
      'سيتم تحصيل صافي المبلغ من المندوب.';

  @override
  String get courierSettleAllPayInfo => 'سيتم سداد صافي المبلغ للمندوب الآن.';

  @override
  String courierSettleAllComplete(int success, int failed) {
    return 'اكتملت تسوية الكل: $success ناجح، $failed فشل';
  }

  @override
  String get courierBalancesPreviewTooltip => 'معاينة التسوية';

  @override
  String courierBalancesPreviewFailed(Object error) {
    return 'فشل تحميل معاينة التسوية: $error';
  }

  @override
  String get settlementTitleCollectFromCourier => 'تحصيل من المندوب';

  @override
  String get settlementTitlePayCourier => 'سداد للمندوب';

  @override
  String get settlementTitleCourierSettlement => 'تسوية المندوب';

  @override
  String get settlementStatusUnpaid => 'غير مدفوع';

  @override
  String get settlementStatusPaid => 'مدفوع';

  @override
  String get settlementPaidNoteRecent =>
      ' (دُفع للتو، ويتم التعامل معه كغير مدفوع)';

  @override
  String get settlementPaidNoteAfterOfd => ' (بعد الخروج للتسليم)';

  @override
  String get settlementPaidNoteAfterOfdUnpaid =>
      ' (دُفع بعد الخروج للتسليم ويُعامل كغير مدفوع)';

  @override
  String settlementInvoiceStatus(Object status, Object note) {
    return 'حالة الفاتورة: $status$note';
  }

  @override
  String get settlementOnlineUnconfirmedNote =>
      'العميل هيدفع أونلاين — المندوب محصلش أي فلوس. اللي بيتسوّى هنا هو مصاريف الشحن بس.';

  @override
  String get settlementCollectFormula => 'تحصيل (الطلب - الشحن):';

  @override
  String get settlementPayFormula => 'سداد للمندوب (الطلب - الشحن):';

  @override
  String get settlementNetToCollect => 'الصافي للتحصيل';

  @override
  String get settlementPayAmount => 'قيمة السداد';

  @override
  String get settlementNothingToSettle => 'لا يوجد مبلغ للتحصيل أو السداد.';

  @override
  String settlementOrderLabel(Object amount) {
    return 'الطلب: $amount';
  }

  @override
  String settlementShippingLabel(Object amount) {
    return 'الشحن: $amount';
  }

  @override
  String settlementTerritoryLabel(Object territory) {
    return 'المنطقة: $territory';
  }

  @override
  String get cancelOrderTitle => 'إلغاء الطلب';

  @override
  String cancelOrderInvoiceLabel(Object invoice) {
    return 'الفاتورة: $invoice';
  }

  @override
  String cancelOrderTotalLabel(Object amount) {
    return 'الإجمالي: $amount';
  }

  @override
  String cancelOrderOutstandingLabel(Object amount) {
    return 'المتبقي: $amount';
  }

  @override
  String get cancelOrderPartialPaymentWarning =>
      'هذه الفاتورة تحتوي على دفعة جزئية. يرجى تسوية الدفعة أو ردها قبل الإلغاء.';

  @override
  String get cancelOrderReasonLabel => 'سبب الإلغاء';

  @override
  String get cancelOrderSelectReasonValidation => 'اختر سببًا للمتابعة';

  @override
  String get cancelOrderProvideReasonValidation => 'يرجى إدخال السبب';

  @override
  String get cancelOrderCustomReasonLabel => 'سبب مخصص';

  @override
  String get cancelOrderDescribeReasonValidation => 'يرجى وصف سبب الإلغاء';

  @override
  String get cancelOrderAdditionalNotesOptional => 'ملاحظات إضافية (اختياري)';

  @override
  String get cancelOrderCreditNoteInfo =>
      'الدفعة اللي على الطلب ده هتترجع. سلّم الفلوس للعميل قبل ما تأكد.';

  @override
  String get cancelOrderConfirmButton => 'تأكيد الإلغاء';

  @override
  String get invoicePreparingReceipt => 'جاري تجهيز الإيصال...';

  @override
  String invoiceItemsCount(int count) {
    return 'الأصناف ($count)';
  }

  @override
  String get invoicePrinterNotConnectedHint =>
      'الطابعة غير متصلة. افتح شاشة اختيار الطابعة من القائمة.';

  @override
  String get invoiceShareReceipt => 'مشاركة الإيصال';

  @override
  String get invoiceSendReceiptWhatsApp => 'إرسال عبر واتساب';

  @override
  String get invoiceSendReceiptWhatsAppCustomer => 'واتساب على رقم العميل';

  @override
  String get invoiceReceiptImageReady =>
      'صورة الإيصال جاهزة — دوس إرسال عشان تشاركها';

  @override
  String get invoiceReceiptSendAction => 'إرسال';

  @override
  String get invoiceReceiptShareFailed => 'تعذّر مشاركة الإيصال';

  @override
  String get invoiceWhatsAppOpenFailed => 'تعذّر فتح واتساب';

  @override
  String get invoicePrintedSuccessfully => 'تمت الطباعة بنجاح';

  @override
  String get invoicePrinterDisconnected => 'تم فصل الطابعة';

  @override
  String invoicePrintFailed(Object result) {
    return 'فشلت الطباعة: $result';
  }

  @override
  String get invoiceAcceptOrderTitle => 'قبول الطلب';

  @override
  String invoiceAcceptOrderQuestion(Object invoice, Object customer) {
    return 'قبول الطلب $invoice للعميل $customer؟';
  }

  @override
  String get invoiceAcceptAction => 'قبول';

  @override
  String invoiceOrderAccepted(Object invoice) {
    return 'تم قبول الطلب $invoice!';
  }

  @override
  String invoiceAcceptFailed(Object error) {
    return 'فشل قبول الطلب: $error';
  }

  @override
  String get invoiceMoreOptions => 'خيارات إضافية';

  @override
  String get invoiceAddNote => 'الملاحظات';

  @override
  String get invoiceNotesTitle => 'ملاحظات الفاتورة';

  @override
  String get invoiceNotesTooltip => 'عرض ملاحظات الفاتورة';

  @override
  String get invoiceNotesHint => 'أضف ملاحظة تشغيلية لهذه الفاتورة';

  @override
  String get invoiceNotesEmpty => 'لا توجد ملاحظات لهذه الفاتورة بعد.';

  @override
  String get invoiceLatestNoteLabel => 'آخر ملاحظة';

  @override
  String invoiceLatestNoteLabelWithCount(Object count) {
    return 'آخر ملاحظة (من $count)';
  }

  @override
  String get invoiceLatestNoteTapToRead => 'اضغط تقرأ ملاحظات الطلب';

  @override
  String get invoiceAddingNote => 'جارٍ الإضافة...';

  @override
  String get invoiceNoteAdded => 'تمت إضافة الملاحظة';

  @override
  String invoiceNotesLoadFailed(Object error) {
    return 'تعذر تحميل ملاحظات الفاتورة: $error';
  }

  @override
  String invoiceNoteAddFailed(Object error) {
    return 'تعذر إضافة الملاحظة: $error';
  }

  @override
  String get invoiceEditInvoice => 'تعديل الفاتورة';

  @override
  String get invoiceEditInvoiceFailed =>
      'تعذر فتح مسودة تعديل الفاتورة. حاول مرة أخرى.';

  @override
  String get invoiceAmendmentUnavailable =>
      'تعديل الفاتورة غير متاح لهذا الطلب.';

  @override
  String get invoiceEditCustomerAddress => 'تعديل عنوان العميل';

  @override
  String get invoiceChangeDeliverySlot => 'تغيير موعد التوصيل';

  @override
  String get invoiceTransferOrder => 'تحويل الطلب';

  @override
  String get invoiceCancelOrderSettleFirst =>
      'إلغاء الطلب (يجب تسوية المدفوعات أولًا)';

  @override
  String get invoiceCustomerLabel => 'العميل';

  @override
  String get invoiceShippingExpenseShort => 'مصروف الشحن:';

  @override
  String get manufacturingTitle => 'التصنيع';

  @override
  String get manufacturingManagersOnly => 'للمدراء فقط';

  @override
  String get manufacturingRecentWorkOrdersTooltip => 'أوامر العمل الأخيرة';

  @override
  String get manufacturingSearchDefaultBom =>
      'ابحث عن الأصناف ذات الـ BOM الافتراضي';

  @override
  String manufacturingWorkOrdersTitle(Object count) {
    return 'أوامر العمل ($count)';
  }

  @override
  String get manufacturingSubmitAll => 'إرسال الكل';

  @override
  String get manufacturingNoItemsSelected => 'لا توجد أصناف محددة';

  @override
  String get manufacturingNoItemsFound => 'لا يوجد أصناف';

  @override
  String manufacturingBomDescription(Object bom, Object quantity, Object uom) {
    return 'BOM: $bom • ناتج $quantity $uom';
  }

  @override
  String get manufacturingBomLabel => 'BOM x';

  @override
  String get manufacturingRequiredItems => 'الأصناف المطلوبة';

  @override
  String get manufacturingNothingToSubmit => 'لا يوجد ما يتم إرساله.';

  @override
  String get manufacturingSubmittingWorkOrders => 'جاري إنشاء أوامر العمل...';

  @override
  String manufacturingSubmitFailed(Object error) {
    return 'فشل الإرسال: $error';
  }

  @override
  String get manufacturingSubmitAllSuccess => 'تم الإرسال بنجاح';

  @override
  String manufacturingSubmitAllResult(Object success, Object total) {
    return 'تمت معالجة $total بند. الناجحة: $success';
  }

  @override
  String get manufacturingQuantityMustBePositive =>
      'يجب أن تكون الكمية أكبر من صفر';

  @override
  String get manufacturingSubmittingSingleWorkOrder =>
      'جاري إنشاء أمر العمل...';

  @override
  String get manufacturingSubmitResult => 'تم الإرسال';

  @override
  String manufacturingSubmitStatus(Object status) {
    return 'الحالة: $status';
  }

  @override
  String manufacturingSubmitWorkOrder(Object workOrder) {
    return ' • رقم الأمر: $workOrder';
  }

  @override
  String manufacturingLoadFailed(Object error) {
    return 'فشل التحميل: $error';
  }

  @override
  String get manufacturingRecentWorkOrdersTitle => 'أوامر العمل الأخيرة';

  @override
  String get manufacturingNoWorkOrders => 'لا توجد أوامر عمل';

  @override
  String manufacturingRecentWorkOrderTitle(Object name, Object status) {
    return '$name • $status';
  }

  @override
  String manufacturingRecentWorkOrderSubtitle(
    Object bom,
    Object item,
    Object quantity,
  ) {
    return '$item • $quantity • $bom';
  }

  @override
  String manufacturingComponentAvailable(Object quantity, Object uom) {
    return 'المتوفر: $quantity $uom';
  }

  @override
  String get manufacturingInsufficientInventory => 'المخزون غير كافٍ';

  @override
  String get manufacturingSubmissionBlocked =>
      'تم إيقاف الإرسال حتى يتم حل العجز.';

  @override
  String manufacturingLineShortageSummary(Object components, Object item) {
    return '$item: $components';
  }

  @override
  String manufacturingComponentRequired(Object quantity, Object uom) {
    return 'المطلوب: $quantity $uom';
  }

  @override
  String manufacturingComponentMissing(Object quantity, Object uom) {
    return 'العجز: $quantity $uom';
  }

  @override
  String get menuProductionBoard => 'لوحة الإنتاج';

  @override
  String get productionBoardTitle => 'لوحة الإنتاج';

  @override
  String get productionTabPlan => 'الخطة';

  @override
  String get dailyPlanNoItems =>
      'لا توجد أصناف قابلة للتعبئة لها قائمة مكونات افتراضية.';

  @override
  String get dailyPlanNoMix => 'بدون خليط تشيز كيك';

  @override
  String dailyPlanPerBatch(int count) {
    return '$count للتشغيلة';
  }

  @override
  String dailyPlanTotalJars(int count) {
    return '$count برطمان مخطط';
  }

  @override
  String get dailyPlanEnterQuantities => 'اكتب عدد البرطمانات اللي هتعبيها.';

  @override
  String dailyPlanMixTotal(String qty, String uom, String batches) {
    return '$qty $uom خليط = $batches تشغيلة';
  }

  @override
  String get dailyPlanNoRuns => 'العجان مش متظبط، فمش هينفع نحسب التقسيم.';

  @override
  String get dailyPlanRunPreferred => 'مظبوط';

  @override
  String get dailyPlanRunAcceptable => 'زيادة شوية';

  @override
  String get dailyPlanRunPoor => 'مش بيخلط كويس';

  @override
  String dailyPlanSpareMix(String batches) {
    return '$batches تشغيلة خليط زيادة بسبب التقريب.';
  }

  @override
  String get dailyPlanCheckMaterials => 'راجع المخزون';

  @override
  String get dailyPlanSave => 'احفظ الخطة';

  @override
  String dailyPlanSaved(String name) {
    return 'الخطة $name اتحفظت.';
  }

  @override
  String dailyPlanShortages(int count) {
    return '$count خامات ناقصة';
  }

  @override
  String dailyPlanShortageLine(String item, String qty, String uom) {
    return '$item: ناقص $qty $uom';
  }

  @override
  String dailyPlanShortagesMore(int count) {
    return 'و$count كمان';
  }

  @override
  String get dailyPlanMaterialsUnavailable =>
      'مش قادرين نراجع المخزون للخطة دي.';

  @override
  String dailyPlanBomIssues(int count) {
    return '$count قائمة مكونات محتاجة مراجعة عشان إجمالي الخليط يبقى صح';
  }

  @override
  String get dailyPlanBomIssuesTitle =>
      'مشاكل قوائم المكونات المؤثرة على الخطة';

  @override
  String get productionAccessDenied => 'مطلوب صلاحية الإنتاج';

  @override
  String get productionSearchHint => 'دوّر على صنف له BOM';

  @override
  String get productionFilterAll => 'الكل';

  @override
  String get productionStatusCritical => 'حرج';

  @override
  String get productionStatusLow => 'قليل';

  @override
  String get productionStatusOk => 'مغطى';

  @override
  String get productionStatusOverstocked => 'زيادة';

  @override
  String get productionStatusNoVelocity => 'مفيش بيانات بيع';

  @override
  String get productionOnHand => 'المتاح';

  @override
  String productionOnHandValue(Object quantity) {
    return '$quantity في المخزن';
  }

  @override
  String get productionRowDetails => 'التفاصيل';

  @override
  String get productionMoreActions => 'إجراءات أخرى';

  @override
  String productionFilterCount(String label, int count) {
    return '$label $count';
  }

  @override
  String get productionSellsPerDay => 'بيبيع / يوم';

  @override
  String get productionCover => 'التغطية';

  @override
  String productionCoverDays(Object days) {
    return '$days يوم';
  }

  @override
  String get productionCoverUnknown => '—';

  @override
  String get productionTrend => 'الاتجاه';

  @override
  String productionMakeBatches(Object batches, Object units, Object uom) {
    return 'اعمل $batches تشغيلة · $units $uom';
  }

  @override
  String productionReachCover(Object days) {
    return 'علشان توصل لتغطية $days يوم';
  }

  @override
  String productionCappedBy(Object capped, Object limiter, Object wanted) {
    return 'الحد $capped — $limiter ناقص (المطلوب $wanted)';
  }

  @override
  String productionSeasonApplied(Object name, Object value) {
    return 'موسم $name: ×$value';
  }

  @override
  String get productionFillTheDay => 'املأ اليوم';

  @override
  String productionFillTheDaySkipped(Object skipped) {
    return '$skipped اتخطّت — مفيش خامات';
  }

  @override
  String get productionFillTheDayNothing => 'مفيش حاجة تتضاف';

  @override
  String get productionPlanQty => 'برطمانات';

  @override
  String get productionPlanWholeJarsOnly =>
      'عدد برطمانات صحيح بس. المخلوطات والكيك بتتسجل من تبويب الأساسات.';

  @override
  String productionUseSuggestion(Object units) {
    return 'خُد $units';
  }

  @override
  String productionPlannedToday(Object count) {
    return 'المخطط $count';
  }

  @override
  String get productionStartBatches => 'ابدأ التشغيلات';

  @override
  String get productionPlanVsStart =>
      '«احفظ الخطة» بتسجّل الهدف بس. «ابدأ التشغيلات» بتحرّك المخزون.';

  @override
  String get productionOtherItems => 'أصناف تانية';

  @override
  String productionFillTheDayFilled(Object items, Object jars) {
    return 'اتملى $items صنف · $jars برطمان';
  }

  @override
  String get productionPlanNothingQueued =>
      'مفيش حاجة تبدأ لسه — اكتب كمية أو استخدم الاقتراح';

  @override
  String get productionNoSuggestions => 'مفيش حاجة محتاجة إنتاج';

  @override
  String get productionVelocityNever =>
      'معدل البيع لسه ماتحسبش — الاقتراحات هتفضل فاضية لحد ما يشتغل';

  @override
  String productionVelocityUpdated(Object when) {
    return 'المعدل اتحدّث $when';
  }

  @override
  String productionBelowCover(Object count) {
    return '$count صنف تحت التغطية';
  }

  @override
  String get productionPostingDate => 'تاريخ الإنتاج';

  @override
  String get productionClearBasket => 'مسح';

  @override
  String get productionBatchesLabel => 'تشغيلات';

  @override
  String get productionPickListTitle => 'قائمة الصرف المجمّعة';

  @override
  String productionPickListShort(Object quantity, Object uom) {
    return 'ناقص $quantity $uom';
  }

  @override
  String get productionPickListOk => 'كل الخامات متوفرة';

  @override
  String productionSharedAcrossLines(Object count) {
    return 'مشترك بين $count بند';
  }

  @override
  String get productionSubmitting => 'بيتبعت…';

  @override
  String get productionScaleToFit => 'قلّل للمتاح من الخامات';

  @override
  String productionTargetDays(Object days) {
    return 'الهدف $days يوم';
  }

  @override
  String get productionNoSourceWarehouse => 'مفيش مخزن مصدر متظبّط';

  @override
  String productionStockElsewhere(Object quantity, Object warehouse) {
    return '$quantity موجودة في $warehouse — محتاجة تحويل مخزني مش شراء';
  }

  @override
  String productionStockElsewhereMore(
    Object count,
    Object quantity,
    Object warehouse,
  ) {
    return '$quantity موجودة في $warehouse و$count مخزن كمان — محتاجة تحويل مخزني مش شراء';
  }

  @override
  String get productionStockNowhere =>
      'مفيش منها في أي مخزن تاني — لازم تتشترى';

  @override
  String get productionMoveStock => 'حوّل المخزون';

  @override
  String productionMoveTitle(Object item) {
    return 'تحويل $item';
  }

  @override
  String get productionMoveFromLabel => 'من';

  @override
  String get productionMoveToLabel => 'إلى';

  @override
  String get productionMoveQtyLabel => 'الكمية اللي هتتحوّل';

  @override
  String productionMoveNeededChip(Object quantity) {
    return 'المطلوب ($quantity)';
  }

  @override
  String productionMoveAllChip(Object quantity) {
    return 'الكل ($quantity)';
  }

  @override
  String productionMoveAvailable(Object quantity) {
    return '$quantity هنا';
  }

  @override
  String get productionMoveConfirm => 'حوّل';

  @override
  String productionMoved(Object quantity, Object warehouse) {
    return 'اتحوّل $quantity إلى $warehouse';
  }

  @override
  String productionMoveTooMuch(Object quantity) {
    return 'مفيش غير $quantity في المخزن ده';
  }

  @override
  String get productionMoveHint =>
      'بيحرّك المخزون بين مخازنك انت. مفيش حاجة بتتشترى ولا بتتصرف.';

  @override
  String get productionMoveNoDestination =>
      'مفيش مخزن متظبّط للصنف ده، فمفيش مكان نحوّله ليه';

  @override
  String productionBackDateWindow(Object days) {
    return 'لحد $days يوم ورا';
  }

  @override
  String get productionBackDateTodayOnly => 'النهارده بس';

  @override
  String get productionRecordingPastDate => 'بتسجّل إنتاج بتاريخ قديم';

  @override
  String get productionNegativeStock => 'الرصيد بالسالب — اعمل جرد للصنف ده';

  @override
  String productionMakeUnits(Object units, Object uom) {
    return 'اعمل $units $uom';
  }

  @override
  String productionCannotStart(Object limiter) {
    return 'مش هيبدأ — $limiter ناقص';
  }

  @override
  String productionBatchTotals(Object batches, Object units) {
    return '$batches تشغيلة · $units وحدة';
  }

  @override
  String get productionTabRunning => 'شغال';

  @override
  String get productionStart => 'ابدأ التشغيلة';

  @override
  String get productionQuickProduce => 'إنتاج سريع';

  @override
  String get productionFinish => 'إنهاء';

  @override
  String get productionFinishTitle => 'إنهاء التشغيلة';

  @override
  String get productionActualQty => 'الكمية الفعلية';

  @override
  String get productionScrapQty => 'الهالك';

  @override
  String get productionBatchNotes => 'ملاحظات';

  @override
  String productionActualExceedsPlanned(Object planned) {
    return 'أكتر من المخطط $planned';
  }

  @override
  String get productionQtyMustBePositive => 'اكتب اللي طلع فعلاً';

  @override
  String get productionRunningEmpty => 'مفيش تشغيلات شغالة';

  @override
  String productionRunningSince(Object when, Object who) {
    return 'بدأت $when بواسطة $who';
  }

  @override
  String productionElapsed(Object hours, Object minutes) {
    return '$hoursس $minutesد';
  }

  @override
  String productionElapsedMinutes(Object minutes) {
    return '$minutes دقيقة';
  }

  @override
  String productionPlannedVsProduced(Object planned, Object produced) {
    return '$planned مخطط · $produced منتَج';
  }

  @override
  String productionWipLeftover(Object quantity, Object uom) {
    return 'متبقي $quantity $uom تحت التشغيل';
  }

  @override
  String get productionReturnToStore => 'رجّع للمخزن';

  @override
  String get productionReturnedToStore => 'الخامات رجعت للمخزن';

  @override
  String get productionCostTitle => 'تكلفة التشغيلة';

  @override
  String get productionMaterialCost => 'الخامات';

  @override
  String get productionCostPerUnit => 'للوحدة';

  @override
  String get productionStandardCost => 'المعياري';

  @override
  String get productionVariance => 'الفرق';

  @override
  String productionVarianceOver(Object percent) {
    return '$percent% أعلى من المعياري';
  }

  @override
  String productionVarianceUnder(Object percent) {
    return '$percent% أقل من المعياري';
  }

  @override
  String get productionCostUnavailable => 'مفيش تكلفة لسه — مفيش إنتاج';

  @override
  String get productionPrintBatchSheet => 'اطبع ورقة التشغيلة';

  @override
  String get productionBackDateNotAllowed => 'مش مسموح تسجّل إنتاج بتاريخ قديم';

  @override
  String productionStarted(Object workOrder) {
    return 'التشغيلة بدأت · $workOrder';
  }

  @override
  String productionFinished(Object quantity, Object uom) {
    return 'التشغيلة خلصت · $quantity $uom';
  }

  @override
  String get productionNotStartedYet => 'التشغيلة دي ماابتدتش أصلاً';

  @override
  String get productionTabBases => 'الأساسات';

  @override
  String get basesHeaderHint =>
      'الأساسات مش بتتباع، فالخطة عمرها ما هتقترحها. اختار واحد وحدد عايز تعجن كام تشغيلة.';

  @override
  String get basesEmpty => 'مفيش أساسات متظبّطة';

  @override
  String get productionTodayTitle => 'النهاردة';

  @override
  String get productionTodaySubtitle => 'اللي طالع من المطبخ النهاردة';

  @override
  String get productionTodayAdvancedBoard => 'اللوحة الكاملة';

  @override
  String productionTodayOpenBatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تشغيلة لسة مفتوحة',
      few: '$count تشغيلات لسة مفتوحة',
      two: 'تشغيلتين لسة مفتوحين',
      one: 'تشغيلة واحدة لسة مفتوحة',
    );
    return '$_temp0';
  }

  @override
  String productionReturnLeftover(String qty, String uom) {
    return 'رجّع $qty $uom الفاضلين للمخزن';
  }

  @override
  String get productionReturnLeftoverHint =>
      'سيبها فاضية لو لسه في كمية جاية من نفس التشغيلة.';

  @override
  String get productionWipReturnFailed =>
      'التشغيلة اتسجلت، بس الخامات الفاضلة مرجعتش. لسه في التشغيل.';

  @override
  String get productionWipWentHome => 'الخامات الفاضلة رجعت للمخزن.';

  @override
  String productionTodayTotalJars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count برطمان اتسجّل',
      few: '$count برطمانات اتسجّلوا',
      two: 'برطمانين اتسجّلوا',
      one: 'برطمان واحد اتسجّل',
    );
    return '$_temp0';
  }

  @override
  String get productionTodayEnterQuantities => 'اكتب كام طلع من الفرن.';

  @override
  String get productionTodayBasesSection => 'الأساسات';

  @override
  String get productionTodayBasesHint => 'كام تشغيلة طلعت';

  @override
  String get productionTodayJarsSection => 'البرطمانات';

  @override
  String get productionTodayJarsHint => 'كام برطمان طلع';

  @override
  String productionTodayNeededToday(String batches) {
    return 'محتاجين النهاردة: $batches';
  }

  @override
  String productionTodayInFreezer(String batches) {
    return 'في الفريزر: $batches';
  }

  @override
  String productionTodayBlockedBy(String item) {
    return '$item مش مكفّي لتشغيلة';
  }

  @override
  String get productionTodayBlocked => 'الخامات مش هتكفّي تشغيلة';

  @override
  String get productionTodayFieldBatches => 'تشغيلة';

  @override
  String get productionTodayFieldJars => 'برطمان';

  @override
  String get productionTodayMake => 'سجّل الإنتاج';

  @override
  String get productionTodaySaveForLater => 'احفظ لبعدين';

  @override
  String get productionTodayPlanSavedShort => 'اتحفظ لبعدين';

  @override
  String productionTodayProduced(int produced, int total) {
    return 'اتسجّل $produced من $total';
  }

  @override
  String get productionTodayNothingProduced => 'مفيش حاجة اتسجّلت';

  @override
  String productionTodayPlannedTarget(String jars) {
    return 'هدف النهاردة: $jars';
  }

  @override
  String productionTodayBasesNotLoaded(String items) {
    return 'مفيش حاجة اتسجّلت. قايمة الأساسات مش محمّلة، فـ $items ماعرفناش نطابقه على صنف. حدّث واكتبه تاني.';
  }

  @override
  String get productionTodayJarsSkipped =>
      'البرطمانات ماتسجلتش — الأساسات لازم تطلع الأول.';

  @override
  String get productionTodayPlanSaveFailed =>
      'الإنتاج اتسجّل. خطة اليوم هي اللي ما اتحفظتش.';

  @override
  String get productionPlanNotSaved => 'خطة اليوم ما اتحفظتش.';

  @override
  String basesSummaryShort(Object count) {
    return '$count أقل من اللي البرطمانات محتاجاه';
  }

  @override
  String basesSummaryBlocked(Object count) {
    return '$count متوقف — مفيش خامات';
  }

  @override
  String basesBatchYield(Object quantity, Object uom) {
    return 'التشغيلة الواحدة = $quantity $uom';
  }

  @override
  String get basesInFreezer => 'في الفريزر';

  @override
  String basesBatchesValue(Object batches) {
    return '$batches تشغيلة';
  }

  @override
  String basesQtyValue(Object quantity, Object uom) {
    return '$quantity $uom';
  }

  @override
  String get basesCanMakeNow => 'ينفع دلوقتي';

  @override
  String basesDemandHint(Object needed, Object onHand) {
    return 'الخطة محتاجة $needed تشغيلة · عندك $onHand';
  }

  @override
  String basesDemandDriver(Object driver) {
    return 'من $driver';
  }

  @override
  String basesUseBatches(Object batches) {
    return 'خُد $batches';
  }

  @override
  String get basesRunSizes => 'أحجام العجّان';

  @override
  String get basesRunSizeOff =>
      'مش من أحجام العجّان المعتادة — راجع قبل ما تعجن';

  @override
  String basesMakes(Object quantity, Object uom) {
    return 'هيطلع $quantity $uom';
  }

  @override
  String get basesConsumes => 'هياخد من الخامات';

  @override
  String basesEstimatedCost(Object amount) {
    return 'تكلفة الخامات تقريباً $amount';
  }

  @override
  String get basesChecking => 'بيراجع الخامات…';

  @override
  String basesPreviewFailed(Object reason) {
    return 'مش قادر يراجع الخامات — $reason';
  }

  @override
  String basesShortage(Object component, Object quantity, Object uom) {
    return '$component ناقص $quantity $uom';
  }

  @override
  String basesReduceTo(Object batches) {
    return 'قلّلها لـ $batches';
  }

  @override
  String get basesNothingPossible => 'الخامات مش كفاية ولا لنص تشغيلة';

  @override
  String get basesUsedPerDay => 'بيتصرف / يوم';

  @override
  String basesQtyPerDay(Object quantity, Object uom) {
    return '$quantity $uom/يوم';
  }

  @override
  String basesCoverSuggestion(Object batches, Object days) {
    return 'اعمل $batches تشغيلة علشان توصل لتغطية $days يوم';
  }

  @override
  String get basesNoConsumption =>
      'لسه محدش سحب من الأساس ده — مش هينفع نحسب التغطية';

  @override
  String basesInStoreValue(Object quantity, Object uom) {
    return '$quantity $uom في المخزن';
  }

  @override
  String get basesGroupMixes => 'المخلوطات';

  @override
  String get basesGroupMixesHint =>
      'بتتعمل بالكيلو — اكتب عدد البرطمانات أو الوزن';

  @override
  String get basesGroupBatches => 'الكيك والبسكويت';

  @override
  String get basesGroupBatchesHint => 'بتتعمل دفعات — بتتحسب بالبيض';

  @override
  String get basesJarsToFill => 'البرطمانات اللي هتتعبّى';

  @override
  String basesPerJar(Object quantity, Object uom) {
    return '$quantity $uom للبرطمان';
  }

  @override
  String basesJarNeedShort(String needed, String uom, String gap) {
    return 'البرطمانات دي عايزة $needed $uom — ناقص $gap عن اللي في المخزن';
  }

  @override
  String basesJarNeedCovered(Object needed, Object uom) {
    return 'البرطمانات دي عايزة $needed $uom — والمخزن مغطيها';
  }

  @override
  String get basesMakeLabel => 'اعمل';

  @override
  String basesUseQty(Object quantity, Object uom) {
    return 'اعمل $quantity $uom';
  }

  @override
  String basesCountedValue(Object count, Object unit) {
    return '$count $unit';
  }

  @override
  String basesCountedPerBatch(Object count, Object unit) {
    return 'الدفعة الواحدة = $count $unit';
  }

  @override
  String basesCountedAndBatches(String count, String unit, String batches) {
    return '$count $unit · $batches دفعة';
  }

  @override
  String basesReduceToQty(Object quantity, Object uom) {
    return 'اعمل $quantity $uom بدالها';
  }

  @override
  String get basesNothingToMake => 'لسه مفيش حاجة محددة تتعمل';

  @override
  String basesMakeMixes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اعمل $count مخلوطات',
      one: 'اعمل مخلوط',
    );
    return '$_temp0';
  }

  @override
  String basesStartBatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ابدأ $count دفعات',
      one: 'ابدأ دفعة',
    );
    return '$_temp0';
  }

  @override
  String basesMakeBoth(int mixes, int batches) {
    return 'اعمل $mixes مخلوط · وابدأ $batches دفعة';
  }

  @override
  String basesSelectedShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ناقصهم خام — شيل علامتهم وكمّل الباقي',
      one: 'واحد ناقصه خام — شيل علامته وكمّل الباقي',
    );
    return '$_temp0';
  }

  @override
  String basesSelectedEmpty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لسه مفيهمش كمية',
      one: 'واحد لسه مفيهوش كمية',
    );
    return '$_temp0';
  }

  @override
  String get basesMixedNote =>
      'المخلوطات بتتسجل خلاص · الدفعات بتروح لـ شغال تتقفل';

  @override
  String get basesCatalogueStale =>
      'قائمة الأساسات اتغيرت — اسحب لتحديثها وحاول تاني';

  @override
  String basesReportMade(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اتعملوا $count مخلوطات',
      one: 'اتعمل مخلوط',
    );
    return '$_temp0';
  }

  @override
  String basesReportStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بدأوا $count دفعات — اقفلهم من شغال',
      one: 'بدأت دفعة — اقفلها من شغال',
    );
    return '$_temp0';
  }

  @override
  String basesReportFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فشلوا',
      one: 'واحد فشل',
    );
    return '$_temp0';
  }

  @override
  String get sopTitle => 'تعليمات التشغيل';

  @override
  String get sopViewSop => 'شوف التعليمات';

  @override
  String get sopNoSopForItem => 'مفيش تعليمات للصنف ده';

  @override
  String sopStepOf(Object current, Object total) {
    return 'خطوة $current من $total';
  }

  @override
  String get sopNext => 'التالي';

  @override
  String get sopPrevious => 'السابق';

  @override
  String get sopConfirmStep => 'تم';

  @override
  String get sopCaptureNumber => 'اكتب القراءة';

  @override
  String get sopCaptureTemperature => 'اكتب درجة الحرارة';

  @override
  String get sopCapturePhoto => 'صوّر';

  @override
  String get sopCaptureRequired => 'سجّل ده قبل ما تكمّل';

  @override
  String sopCaptureOutOfRange(Object from, Object to) {
    return 'المسموح من $from لـ $to';
  }

  @override
  String sopDurationMins(Object minutes) {
    return '$minutes دقيقة';
  }

  @override
  String sopTotalDuration(Object minutes) {
    return 'حوالي $minutes دقيقة إجمالاً';
  }

  @override
  String sopScaledFor(Object batches) {
    return 'محسوبة لـ $batches تشغيلة';
  }

  @override
  String sopForJars(Object count) {
    return 'لـ $count برطمان';
  }

  @override
  String get sopEquipment => 'المعدات';

  @override
  String sopExpectedYield(Object percent) {
    return 'الناتج المتوقع $percent%';
  }

  @override
  String sopVersionLabel(Object version) {
    return 'إصدار $version';
  }

  @override
  String get sopFinishExecution => 'إنهاء التعليمات';

  @override
  String get sopExitConfirm => 'هتسيب التعليمات؟ مكانك مش هيتحفظ.';

  @override
  String sopUnresolvedTokens(Object count) {
    return '$count مرجع في التعليمات مش متعرَّف';
  }

  @override
  String get sopPhotoCaptured => 'الصورة اتسجلت';

  @override
  String get sopCameraPermissionDenied => 'محتاج إذن الكاميرا عشان تصوّر';

  @override
  String get sopPhotoEmpty => 'تعذّرت قراءة الصورة. صوّرها تاني.';

  @override
  String get sopImageUnavailable =>
      'الصورة مش متاحة — يمكن ماعندكش صلاحية ليها';

  @override
  String get stockTransferTitle => 'تحويل مخزون';

  @override
  String get stockTransferManagersOnly => 'للمدراء فقط';

  @override
  String stockTransferLinesTitle(Object count) {
    return 'بنود التحويل ($count)';
  }

  @override
  String stockTransferPostingChip(Object date) {
    return 'الترحيل: $date';
  }

  @override
  String get stockTransferSubmit => 'إرسال';

  @override
  String get stockTransferProfilesMustDiffer =>
      'يجب أن يكون المصدر والوجهة مختلفين';

  @override
  String get stockTransferProfileLabelSource => 'المصدر';

  @override
  String get stockTransferProfileLabelTarget => 'الوجهة';

  @override
  String get stockTransferProfilePlaceholder => 'اختر ملف نقطة البيع';

  @override
  String stockTransferProfileOption(Object profile, Object warehouse) {
    return '$profile • $warehouse';
  }

  @override
  String get stockTransferProfileWarehouseFallback => 'بدون مخزن';

  @override
  String get stockTransferSelectBranches => 'اختر فروع المصدر والوجهة';

  @override
  String get stockTransferSameProfile =>
      'لا يمكن أن يكون المصدر والوجهة متطابقين';

  @override
  String stockTransferAvailability(Object source, Object target) {
    return 'المصدر: $source • الوجهة: $target';
  }

  @override
  String stockTransferReservedSource(Object reservedSource) {
    return ' • محجوز مصدر: $reservedSource';
  }

  @override
  String stockTransferReservedTarget(Object reservedTarget) {
    return ' • محجوز وجهة: $reservedTarget';
  }

  @override
  String get stockTransferPosTag => ' • نقطة بيع';

  @override
  String get stockTransferPostingToday => 'تاريخ الترحيل: اليوم';

  @override
  String stockTransferPostingDate(Object date) {
    return 'تاريخ الترحيل: $date';
  }

  @override
  String get stockTransferUseToday => 'استخدم اليوم';

  @override
  String get stockTransferNoLines => 'لا يوجد بنود';

  @override
  String stockTransferBeforeBase(Object source, Object target) {
    return 'قبل — المصدر: $source • الوجهة: $target';
  }

  @override
  String stockTransferAfterBase(Object source, Object target) {
    return 'بعد  — المصدر: $source • الوجهة: $target';
  }

  @override
  String stockTransferTransferCreated(Object stockEntry) {
    return 'تم إنشاء التحويل: $stockEntry';
  }

  @override
  String stockTransferSubmitFailed(Object error) {
    return 'فشل: $error';
  }

  @override
  String stockTransferBulkAddFailed(Object error) {
    return 'فشل الإضافة الجماعية: $error';
  }

  @override
  String get stockTransferQuickQuantity => 'كمية سريعة';

  @override
  String get stockTransferQuantityPerItem => 'الكمية لكل صنف';

  @override
  String get stockTransferItemGroup => 'مجموعة الأصناف';

  @override
  String get stockTransferAllGroups => 'كل المجموعات';

  @override
  String get stockTransferAddAll => 'إضافة الكل';

  @override
  String get stockTransferAddGroup => 'إضافة المجموعة';

  @override
  String get commonClear => 'مسح';

  @override
  String get commonPaste => 'لصق';

  @override
  String get commonDismiss => 'تجاهل';

  @override
  String get commonSave => 'حفظ';

  @override
  String get paymentMethodSelectTitle => 'اختر طريقة الدفع';

  @override
  String get paymentMethodCash => 'نقدي';

  @override
  String get paymentMethodCard => 'بطاقة';

  @override
  String get paymentMethodInstapay => 'إنستاباي';

  @override
  String get paymentMethodMobileWallet => 'محفظة إلكترونية';

  @override
  String get paymentMethodSettleLater => 'سداد لاحق';

  @override
  String get paymentMethodOnline => 'دفع إلكتروني';

  @override
  String get checkoutTotal => 'الإجمالي:';

  @override
  String get checkoutPay => 'ادفع';

  @override
  String get checkoutSelectProfileFirst => 'اختر ملف نقطة البيع أولاً';

  @override
  String get checkoutOrderSuccess => 'تم إتمام الطلب بنجاح!';

  @override
  String checkoutFailed(Object error) {
    return 'فشل الدفع: $error';
  }

  @override
  String get salesPartnerTitle => 'شريك المبيعات';

  @override
  String get salesPartnerSearchHint => 'بحث عن شريك';

  @override
  String get salesPartnerNotFound => 'لا يوجد شركاء';

  @override
  String get itemGridBundles => 'حزم';

  @override
  String get itemGridAll => 'الكل';

  @override
  String get itemGridUncategorized => 'بدون تصنيف';

  @override
  String get itemGridSelectCustomerWarning => 'يرجى اختيار عميل أولاً';

  @override
  String get itemGridNoItemsFound => 'لم يتم العثور على أصناف';

  @override
  String get itemGridNoItemsAvailable => 'لا توجد أصناف متاحة';

  @override
  String get itemGridTryDifferentCategory => 'جرّب تصنيفاً مختلفاً';

  @override
  String get itemGridItemsWillAppear => 'ستظهر الأصناف هنا';

  @override
  String get itemGridFreeDelivery => 'توصيل مجاني';

  @override
  String itemGridBundlesCount(Object count) {
    return '$count حزم';
  }

  @override
  String itemGridItemsCount(Object count) {
    return '$count أصناف';
  }

  @override
  String itemGridInCart(Object count) {
    return 'في السلة: $count';
  }

  @override
  String get itemGridAddedToCart => 'تمت الإضافة إلى السلة';

  @override
  String get itemGridSelectCustomerFirst => 'اختر عميلاً أولاً';

  @override
  String get itemGridOutOfStock => 'نفدت الكمية';

  @override
  String get itemGridCannotAdd => 'لا يمكن إضافة الصنف';

  @override
  String get kanbanFilterTitle => 'الفلاتر';

  @override
  String kanbanFilterActiveCount(Object count) {
    return '$count نشط';
  }

  @override
  String get kanbanFilterClearAll => 'مسح الكل';

  @override
  String get kanbanFilterSearch => 'بحث';

  @override
  String get kanbanFilterSearchHint => 'رقم الطلب أو العميل أو التليفون';

  @override
  String kanbanFilterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب مطابق',
      few: '$count طلبات مطابقة',
      two: 'طلبان مطابقان',
      one: 'طلب واحد مطابق',
      zero: 'مفيش طلبات مطابقة',
    );
    return '$_temp0';
  }

  @override
  String get kanbanFilterDone => 'تم';

  @override
  String get kanbanFilterDateToday => 'النهاردة';

  @override
  String get kanbanFilterDateLast7Days => 'آخر ٧ أيام';

  @override
  String get kanbanFilterDateLast30Days => 'آخر ٣٠ يوم';

  @override
  String get kanbanFilterDateThisMonth => 'الشهر ده';

  @override
  String get kanbanFilterDateCustom => 'نطاق مخصص…';

  @override
  String get kanbanFilterAllCustomers => 'كل العملاء';

  @override
  String get kanbanFilterAllStatuses => 'كل الحالات';

  @override
  String get kanbanFilterDateRange => 'نطاق التاريخ';

  @override
  String get kanbanFilterFromDate => 'من تاريخ';

  @override
  String get kanbanFilterToDate => 'إلى تاريخ';

  @override
  String get kanbanFilterAllDates => 'كل التواريخ';

  @override
  String get kanbanFilterAmountRange => 'نطاق المبلغ';

  @override
  String get kanbanFilterMinAmount => 'الحد الأدنى';

  @override
  String get kanbanFilterMaxAmount => 'الحد الأقصى';

  @override
  String get kanbanFilterAllAmounts => 'كل المبالغ';

  @override
  String get kanbanFilterActiveLabel => 'الفلاتر النشطة:';

  @override
  String get kanbanFilterByBranches => 'تصفية حسب الفروع';

  @override
  String get kanbanFilterCustomerTitle => 'العميل';

  @override
  String get kanbanFilterCustomerName => 'اسم العميل';

  @override
  String get kanbanFilterCustomerHint => 'أدخل اسم العميل';

  @override
  String get kanbanFilterStatusTitle => 'الحالة';

  @override
  String get kanbanFilterFromAmount => 'من مبلغ';

  @override
  String get kanbanFilterToAmount => 'إلى مبلغ';

  @override
  String get kanbanFilterApply => 'تطبيق';

  @override
  String get kanbanRefreshOrders => 'تحديث الطلبات';

  @override
  String get kanbanOrdersRefreshed => 'تم تحديث الطلبات';

  @override
  String get kanbanHideFilters => 'إخفاء الفلاتر';

  @override
  String get kanbanShowFilters => 'إظهار الفلاتر';

  @override
  String get kanbanMoreActions => 'المزيد';

  @override
  String get kanbanMenu => 'القائمة';

  @override
  String get kanbanMenuReceipts => 'إيصالات الدفع';

  @override
  String get kanbanMenuPrinters => 'الطابعات';

  @override
  String get kanbanMenuCouriers => 'أرصدة المناديب';

  @override
  String get kanbanMenuProfile => 'الملف الشخصي';

  @override
  String get kanbanMenuPos => 'نقطة البيع';

  @override
  String get kanbanPaymentReceipts => 'إيصالات الدفع';

  @override
  String get kanbanCourierBalances => 'أرصدة المناديب';

  @override
  String get kanbanUserProfile => 'الملف الشخصي';

  @override
  String get kanbanOpenPos => 'فتح نقطة البيع';

  @override
  String get kanbanTitleShort => 'كانبان';

  @override
  String get kanbanTitleFull => 'كانبان المبيعات';

  @override
  String get kanbanPrinterBle => 'BLE';

  @override
  String get kanbanPrinterClassic => 'كلاسيك';

  @override
  String get kanbanPrinterConnecting => 'جارٍ الاتصال...';

  @override
  String get kanbanPrinterNotConnected => 'غير متصل';

  @override
  String get kanbanErrorLoadingData => 'خطأ في تحميل البيانات';

  @override
  String get kanbanNoColumnsConfigured => 'لم يتم تكوين أعمدة';

  @override
  String get kanbanEnsureStateField => 'تأكد من تكوين حقل الحالة بشكل صحيح.';

  @override
  String get kanbanSelectPosProfileFirst => 'اختر ملف نقطة البيع أولاً';

  @override
  String get kanbanSelectPosProfile => 'اختر ملف نقطة البيع';

  @override
  String get kanbanNoPosProfiles => 'لا توجد ملفات نقطة بيع متاحة';

  @override
  String kanbanWarehouse(Object warehouse) {
    return 'المستودع: $warehouse';
  }

  @override
  String get kanbanCourierAndMode => 'المندوب والطريقة';

  @override
  String get kanbanNoCouriersAvailable => 'لا يوجد مناديب';

  @override
  String get kanbanCreateCourierHint => 'أنشئ مندوباً للمتابعة.';

  @override
  String get kanbanNewCourier => 'مندوب جديد';

  @override
  String get kanbanFirstName => 'الاسم الأول';

  @override
  String get kanbanLastName => 'اسم العائلة';

  @override
  String get kanbanPhone => 'الهاتف';

  @override
  String get kanbanType => 'النوع';

  @override
  String get kanbanEmployee => 'موظف';

  @override
  String get kanbanSupplier => 'مورّد';

  @override
  String get kanbanBack => 'رجوع';

  @override
  String kanbanCreateFailed(Object error) {
    return 'فشل الإنشاء: $error';
  }

  @override
  String get kanbanMode => 'الطريقة';

  @override
  String get kanbanPayNowCash => 'ادفع الآن (نقدي)';

  @override
  String get kanbanSettleLater => 'تسوية لاحقاً';

  @override
  String get kanbanSettleLaterSubtitle => 'المندوب يسوي مع الفرع لاحقاً';

  @override
  String get kanbanContinue => 'متابعة';

  @override
  String get kanbanSettleLaterMissingParty =>
      'فشلت التسوية اللاحقة: طرف المندوب مفقود.';

  @override
  String get kanbanSettleLaterPreviewExpired =>
      'التسوية اللاحقة: انتهت صلاحية المعاينة. أعد المحاولة.';

  @override
  String get kanbanSettleLaterFailed => 'فشلت التسوية اللاحقة';

  @override
  String get kanbanMarkedSettleLater => 'تم التحديد للتسوية لاحقاً';

  @override
  String kanbanSettleLaterError(Object error) {
    return 'خطأ في التسوية اللاحقة: $error';
  }

  @override
  String get kanbanSettlementMissingParty => 'فشلت التسوية: طرف المندوب مفقود.';

  @override
  String get kanbanPreviewExpired => 'انتهت صلاحية المعاينة. أعد المحاولة.';

  @override
  String get kanbanConfirmingSettlement => 'جارٍ تأكيد التسوية...';

  @override
  String get kanbanSettlementFailed => 'فشلت التسوية';

  @override
  String get kanbanSettlementConfirmed => 'تم تأكيد التسوية';

  @override
  String kanbanSettlementError(Object error) {
    return 'خطأ في التسوية: $error';
  }

  @override
  String kanbanPreviewFailed(Object error) {
    return 'فشلت المعاينة: $error';
  }

  @override
  String get kanbanPickupNoSettlement => 'طلبات الاستلام لا تحتاج تسوية';

  @override
  String get kanbanCannotMoveBackward => 'لا يمكن التراجع للخلف';

  @override
  String get kanbanCancelViaMenuOnly =>
      'مش هينفع تلغي الطلب بالسحب. افتح قائمة الكارت واختار \"إلغاء الطلب\".';

  @override
  String get kanbanReturnViaMenuOnly =>
      'مش هينفع ترجّع الطلب بالسحب. افتح قائمة الكارت واختار \"مرتجع الطلب\".';

  @override
  String get kanbanFullyReturnedLocked =>
      'الطلب ده اترجع بالكامل ومش هينفع يتحرك تاني.';

  @override
  String get kanbanPinBadgePinned => 'الموقع متحدد';

  @override
  String get kanbanPinBadgePinnedTooltip =>
      'العنوان ده عليه إحداثيات على الخريطة';

  @override
  String get kanbanPinBadgeMissing => 'مفيش موقع';

  @override
  String get kanbanPinBadgeMissingTooltip =>
      'لسه مفيش موقع على الخريطة — ضيف رابط الموقع قبل الخروج للتوصيل';

  @override
  String get kanbanMoveOneStage => 'يمكن التقدم مرحلة واحدة فقط';

  @override
  String get kanbanAllBranches => 'كل الفروع';

  @override
  String kanbanBranchCount(Object count) {
    return '$count فروع';
  }

  @override
  String get kanbanLoadingBranches => 'جارٍ تحميل الفروع...';

  @override
  String get kanbanTapToRefreshBalance => 'اضغط لتحديث الرصيد';

  @override
  String get kanbanPressBackAgain => 'اضغط رجوع مرة أخرى للخروج';

  @override
  String get invoiceDeliveryAddress => 'عنوان التوصيل';

  @override
  String get invoiceItems => 'الأصناف';

  @override
  String get invoiceNetTotal => 'الإجمالي الصافي';

  @override
  String get invoiceShippingIncome => 'إيراد الشحن';

  @override
  String get invoiceShippingExpense => 'مصاريف الشحن';

  @override
  String get invoiceGrandTotal => 'الإجمالي الكلي';

  @override
  String invoiceAlreadyStatus(Object status) {
    return 'الفاتورة بالفعل $status';
  }

  @override
  String get invoiceSelectPaymentMethod => 'اختر طريقة الدفع';

  @override
  String get invoiceWallet => 'محفظة';

  @override
  String get invoiceSubmit => 'إرسال';

  @override
  String get invoiceNoPosProfileCash =>
      'لم يتم اختيار ملف نقطة بيع للدفع النقدي';

  @override
  String invoiceProcessingPayment(Object method) {
    return 'جارٍ معالجة دفع $method...';
  }

  @override
  String invoicePaymentSuccess(Object entry) {
    return 'تم الدفع بنجاح ($entry)';
  }

  @override
  String get invoiceReceiptAmountWarning =>
      'تحذير: تعذر الحصول على مبلغ الدفع للإيصال';

  @override
  String get invoiceReceiptNoPosProfile =>
      'تحذير: لم يتم العثور على ملف نقطة بيع - لم يتم إنشاء الإيصال. يرجى اختيار ملف نقطة بيع.';

  @override
  String invoiceReceiptCreated(Object receipt) {
    return 'تم إنشاء إيصال الدفع ($receipt) - يرجى رفع صورة الإيصال من الرأس';
  }

  @override
  String invoiceReceiptReturnedWarning(Object message) {
    return 'تحذير: إنشاء الإيصال أرجع: $message';
  }

  @override
  String invoiceReceiptCreationFailed(Object error) {
    return 'تحذير: فشل إنشاء الإيصال: $error';
  }

  @override
  String get invoicePaymentFailed => 'فشل الدفع';

  @override
  String get transferProofTitle => 'صورة التحويل';

  @override
  String get transferProofIntro =>
      'الدفع بإنستاباي أو المحفظة مبيتسجلش غير بعد ما المدير يأكد صورة تحويل العميل.';

  @override
  String get transferProofAmountLabel => 'المبلغ المطلوب دفعه';

  @override
  String get transferProofMethodLabel => 'طريقة الدفع';

  @override
  String get transferProofAlreadyUploaded =>
      'فيه صورة مرفوعة بالفعل ومستنية التأكيد. تقدر تكمل بيها أو تستبدلها.';

  @override
  String get transferProofRejected =>
      'الصورة اللي فاتت اترفضت. ارفع صورة جديدة.';

  @override
  String get transferProofChecking => 'بنراجع الإيصال…';

  @override
  String get transferProofReceiptChanged =>
      'الإيصال ده اتغير من ساعة ما اللوحة اتحملت. اقفل ودوس دفع تاني.';

  @override
  String transferProofRejectedReason(String reason) {
    return 'الصورة اللي فاتت اترفضت: $reason. ارفع صورة جديدة.';
  }

  @override
  String get transferProofAttach => 'إرفاق صورة التحويل';

  @override
  String get transferProofImageSelected => 'تم اختيار صورة جديدة';

  @override
  String get transferProofSend => 'إرسال الصورة';

  @override
  String get transferProofContinue => 'كمّل بالصورة دي';

  @override
  String get transferProofSending => 'جارٍ إرسال الصورة...';

  @override
  String get transferProofConfirming => 'جارٍ تأكيد التحويل...';

  @override
  String get transferProofConfirmTitle => 'التحويل وصل؟';

  @override
  String transferProofConfirmBody(String amount) {
    return 'افتح حساب الشركة في البنك واتأكد إن تحويل $amount وصل. أكّد بس لو شايفه.';
  }

  @override
  String get transferProofConfirmYes => 'أيوه وصل، أكّد وادفع';

  @override
  String get transferProofConfirmNo => 'لسه';

  @override
  String transferProofAwaitingManager(String method) {
    return 'الصورة اتبعتت. لازم المدير يأكدها من إيصالات الدفع، وبعدين دوس دفع واختار $method تاني.';
  }

  @override
  String get transferProofAwaitingConfirmation =>
      'الصورة اتحفظت. الإيصال مستني التأكيد، ولسه مفيش دفع اتسجل. دوس دفع تاني بعد ما التحويل يتأكد.';

  @override
  String invoicePaymentError(Object error) {
    return 'خطأ في الدفع: $error';
  }

  @override
  String get invoiceCollectCashTitle => 'تحصيل النقد';

  @override
  String invoiceCollectCashBody(Object amount, Object invoiceId) {
    return 'يرجى التحصيل من العميل:\n\nالمبلغ الإجمالي: $amount جنيه\n\nيشمل:\n• أصناف الطلب\n• رسوم الشحن\n\nفاتورة: $invoiceId';
  }

  @override
  String get invoiceSelectPosFirst => 'اختر ملف نقطة البيع أولاً';

  @override
  String get invoiceChangeCollectionMethod => 'تغيير طريقة التحصيل';

  @override
  String get invoiceRequestedPaymentMethod => 'الطريقة المطلوبة';

  @override
  String get invoiceActualCollectionMethod => 'التحصيل الفعلي';

  @override
  String get invoiceCollectionReferenceLabel => 'رقم المرجع';

  @override
  String get invoiceCollectionReferenceRequired =>
      'التحصيل الإلكتروني يتطلب رقم مرجع.';

  @override
  String get invoiceCollectionCashAtBranchNotice =>
      'مندوب التوصيل لهذا الطلب أغلق حسابه بالفعل، لذلك يُسجل هذا المبلغ كنقدية مُستلمة في الفرع وسيُطلب في جرد الدرج القادم.';

  @override
  String get invoiceChangingCollectionMethod => 'جارٍ تغيير طريقة التحصيل...';

  @override
  String invoiceCollectionMethodChanged(Object method) {
    return 'تم تغيير طريقة التحصيل إلى $method';
  }

  @override
  String invoiceCollectionMethodChangeError(Object error) {
    return 'خطأ في تغيير طريقة التحصيل: $error';
  }

  @override
  String get invoiceCollectingCashPartner =>
      'جارٍ تحصيل النقد والإرسال (شريك مبيعات)...';

  @override
  String get invoiceCashCollectedOfd => 'تم تحصيل النقد وإرسال الطلب للتوصيل';

  @override
  String invoiceOfdFailed(Object error) {
    return 'فشل: $error';
  }

  @override
  String invoiceOfdError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String get invoiceSentOfd => 'تم الإرسال للتوصيل (سيتم إنشاء إذن التسليم)';

  @override
  String invoiceActionFailed(Object error) {
    return 'فشل الإجراء: $error';
  }

  @override
  String get invoiceSettleLaterMissingParty =>
      'فشلت التسوية اللاحقة: طرف المندوب مفقود.';

  @override
  String get invoiceMarkedSettleLater => 'تم التحديد للتسوية لاحقاً';

  @override
  String get invoiceSettleLaterFailed => 'فشلت التسوية اللاحقة';

  @override
  String invoiceSettleLaterError(Object error) {
    return 'خطأ في التسوية اللاحقة: $error';
  }

  @override
  String get invoiceSettlementMissingParty =>
      'فشلت التسوية: طرف المندوب مفقود.';

  @override
  String get invoicePreviewExpired => 'انتهت صلاحية المعاينة. أعد المحاولة.';

  @override
  String get invoiceConfirmingSettlement => 'جارٍ تأكيد التسوية...';

  @override
  String get invoiceSettlementConfirmed => 'تم تأكيد التسوية';

  @override
  String get invoiceSettlementFailed => 'فشلت التسوية';

  @override
  String invoiceSettlementError(Object error) {
    return 'خطأ في التسوية: $error';
  }

  @override
  String get invoiceProcessingDelivery => 'جارٍ معالجة التوصيل...';

  @override
  String get invoiceUpdated => 'تم التحديث';

  @override
  String get customerShippingAddressTitle => 'اختر عنوان الشحن';

  @override
  String get customerShippingAddressSubtitle =>
      'اختر عنوان شحن محفوظًا أو أضف عنوانًا جديدًا لهذا العميل.';

  @override
  String get customerShippingAddressSavedTab => 'العناوين المحفوظة';

  @override
  String get customerShippingAddressNewTab => 'إضافة عنوان جديد';

  @override
  String get customerShippingAddressEmpty => 'لا توجد عناوين شحن محفوظة بعد.';

  @override
  String get customerShippingAddressSelectRequired =>
      'اختر عنوان شحن أو أضف عنوانًا جديدًا.';

  @override
  String get customerShippingAddressLoadFailed => 'فشل تحميل عناوين الشحن.';

  @override
  String get customerShippingAddressEditTab => 'تعديل العنوان';

  @override
  String get customerShippingAddressEditTitle => 'تعديل عنوان الشحن';

  @override
  String get customerShippingAddressDeleteConfirm =>
      'حذف هذا العنوان؟ لا يمكن التراجع عن هذا.';

  @override
  String get customerShippingAddressDeleteSuccess => 'تم حذف العنوان.';

  @override
  String get customerShippingAddressDeleteFailed => 'فشل حذف العنوان.';

  @override
  String get customerShippingAddressUpdateSuccess => 'تم تحديث العنوان.';

  @override
  String get customerShippingAddressUpdateFailed => 'فشل تحديث العنوان.';

  @override
  String get customerShippingAddressLine1Label => 'سطر العنوان 1';

  @override
  String get customerShippingAddressLine2Label => 'سطر العنوان 2 (اختياري)';

  @override
  String get customerShippingAddressTerritoryLabel => 'المنطقة';

  @override
  String get customerShippingAddressPincodeLabel => 'الرمز البريدي (اختياري)';

  @override
  String get customerShippingAddressTerritoryRequired => 'يرجى اختيار المنطقة.';

  @override
  String get customerShippingAddressLine1Required => 'سطر العنوان 1 مطلوب.';

  @override
  String get customerShippingAddressBranchNameLabel => 'اسم فرع التوصيل';

  @override
  String get customerShippingAddressBranchNameRequired =>
      'أدخل اسم فرع التوصيل.';

  @override
  String get customerShippingAddressTerritoryMissing =>
      'عدّل الفرع واختار منطقة التوصيل قبل ما تعمل الطلب.';

  @override
  String get posAmendmentDraftTitle => 'مسودة تعديل الفاتورة';

  @override
  String get posAmendmentDraftMessage =>
      'راجع التغييرات بعناية ثم أرسل التعديل لاستبدال الفاتورة الأصلية.';

  @override
  String get posAmendmentCheckoutBlocked =>
      'إرسال التعديل غير متاح لهذه المسودة. ارجع إلى الطلب وافتح التعديل مرة أخرى.';

  @override
  String get invoiceDeliveryFailed => 'فشل إجراء التوصيل';

  @override
  String invoiceDeliveryError(Object error) {
    return 'خطأ: $error';
  }

  @override
  String get invoiceDeliveryTitle => 'التوصيل';

  @override
  String get invoiceUnpaidWarning =>
      'الفاتورة غير مدفوعة. اختر تحصيل المندوب للنقد الآن لتسجيل دفعة نقدية قبل تحديد خارج للتوصيل.';

  @override
  String get invoiceCannotSettleParty =>
      'لا يمكن التسوية: لم يتم تحديد طرف المندوب. عيّن مندوباً أو أعد المحاولة.';

  @override
  String get invoiceNothingToSettle => 'لا يوجد شيء للتسوية';

  @override
  String get invoiceSettlementComplete => 'اكتملت التسوية';

  @override
  String get invoiceEditAddress => 'تعديل عنوان العميل';

  @override
  String get invoicePhoneNumber => 'رقم الهاتف';

  @override
  String get invoiceDeliveryAddressLabel => 'عنوان التوصيل';

  @override
  String get invoiceAddressHelper => 'أدخل عنوان التوصيل الكامل';

  @override
  String get invoiceAddressUpdateInfo =>
      'سيتم تحديث العنوان ورقم الهاتف الافتراضي للعميل.';

  @override
  String get invoiceAddressEmpty => 'العنوان لا يمكن أن يكون فارغاً';

  @override
  String get invoiceUpdatingAddress => 'جارٍ تحديث عنوان العميل...';

  @override
  String get invoiceAddressUpdated => 'تم تحديث عنوان العميل بنجاح';

  @override
  String invoiceAddressUpdatedWithShipping(
    Object oldExpense,
    Object newExpense,
  ) {
    return 'تم تحديث العنوان. الشحن: $oldExpense ← $newExpense ج.م';
  }

  @override
  String get invoiceAddressUpdateFailed => 'فشل تحديث العنوان';

  @override
  String invoiceCopiedNumber(Object number) {
    return 'تم النسخ: $number';
  }

  @override
  String get invoiceCopy => 'نسخ';

  @override
  String get invoiceCannotCall => 'تعذر إجراء المكالمة';

  @override
  String get invoiceCall => 'اتصال';

  @override
  String get invoiceSettleBeforeCancel =>
      'قم بتسوية أو استرداد المدفوعات الجزئية قبل إلغاء هذا الطلب.';

  @override
  String get invoiceCancelFailed => 'فشل إلغاء الطلب. يرجى المحاولة مرة أخرى.';

  @override
  String invoiceCancelledWithCn(Object creditNote) {
    return 'تم إلغاء الطلب. تم إنشاء إشعار دائن $creditNote.';
  }

  @override
  String get invoiceCancelledSuccess => 'تم إلغاء الطلب بنجاح.';

  @override
  String get invoiceNoPosProfile => 'لم يتم اختيار ملف نقطة بيع';

  @override
  String get invoiceAssignBranch => 'تعيين إلى فرع';

  @override
  String invoiceCustomerName(Object name) {
    return 'العميل: $name';
  }

  @override
  String invoiceInvoiceLabel(Object name) {
    return 'الفاتورة: $name';
  }

  @override
  String get invoiceTransferInfo =>
      'سيتم نقل الطلب إلى الفرع المحدد وإعادة تعيينه إلى حالة مستلم.';

  @override
  String get invoiceTransferring => 'جارٍ نقل الطلب...';

  @override
  String invoiceTransferSuccess(Object branch) {
    return 'تم نقل الطلب بنجاح إلى $branch';
  }

  @override
  String get invoiceTransferFailed => 'فشل النقل. يرجى المحاولة مرة أخرى.';

  @override
  String get invoiceCannotDetermineProfile =>
      'تعذر تحديد ملف نقطة البيع لهذه الفاتورة';

  @override
  String get invoiceLoadingSlots => 'جارٍ تحميل مواعيد التوصيل...';

  @override
  String get invoiceNoSlots => 'لا توجد مواعيد توصيل متاحة لهذا الفرع';

  @override
  String get invoiceChangeSlot => 'تغيير موعد التوصيل';

  @override
  String invoiceCurrentSlot(Object slot) {
    return 'الحالي: $slot';
  }

  @override
  String get invoiceSlotUpdateInfo => 'سيتم تحديث موعد التوصيل لهذا الطلب.';

  @override
  String get invoiceNoChanges => 'لم يتم إجراء تغييرات';

  @override
  String get invoiceUpdatingSlot => 'جارٍ تحديث موعد التوصيل...';

  @override
  String invoiceSlotUpdated(Object slot) {
    return 'تم تحديث موعد التوصيل إلى $slot';
  }

  @override
  String get invoiceSlotUpdateFailed => 'فشل تحديث موعد التوصيل';

  @override
  String get tripsDeliveryTripsTitle => 'رحلات التوصيل';

  @override
  String get tripsActiveTab => 'نشطة';

  @override
  String get tripsCompletedTab => 'مكتملة';

  @override
  String get tripsCreateTripTitle => 'إنشاء رحلة توصيل';

  @override
  String get tripsCreateTripButton => 'إنشاء رحلة';

  @override
  String tripsCreateTripFailed(Object error) {
    return 'فشل إنشاء الرحلة: $error';
  }

  @override
  String get tripsOrdersLabel => 'الطلبات';

  @override
  String get tripsTotalAmount => 'إجمالي المبلغ';

  @override
  String get tripsTotalShipping => 'إجمالي الشحن';

  @override
  String tripsSameTerritory(Object territory) {
    return 'نفس المنطقة: $territory';
  }

  @override
  String get tripsSelectCourier => 'اختر الساعي';

  @override
  String get tripsNoTrips => 'لا توجد رحلات';

  @override
  String tripsOrdersCount(Object count) {
    return '$count طلب';
  }

  @override
  String get tripsDoubleShippingLabel => 'شحن مضاعف';

  @override
  String get tripsNotesLabel => 'ملاحظات';

  @override
  String get tripsMarkTripAsDeliveredTitle => 'تعليم الرحلة كمسلمة';

  @override
  String tripsMarkTripAsDeliveredContent(Object tripName, Object count) {
    return 'تعليم \"$tripName\" مع $count طلبات كمسلمة؟';
  }

  @override
  String tripsTripMarkedAsDelivered(Object tripName) {
    return 'تم تعليم $tripName كمسلمة';
  }

  @override
  String tripsFailed(Object error) {
    return 'فشل: $error';
  }

  @override
  String get tripsSendForDeliveryTitle => 'إرسال للتوصيل';

  @override
  String tripsSendForDeliveryContent(Object count, Object courierName) {
    return 'إرسال $count طلبات للتوصيل؟\n\nالساعي: $courierName';
  }

  @override
  String get tripsSentForDeliverySuccess => 'تم إرسال الرحلة للتوصيل';

  @override
  String get tripsMarkAsDeliveredButton => 'تعليم كمسلمة';

  @override
  String tripsMarkAllAsDeliveredContent(Object count) {
    return 'تعليم جميع $count طلبات كمسلمة؟\n\nسيؤدي ذلك إلى إتمام الرحلة.';
  }

  @override
  String get tripsTripMarkedSuccess => 'تم تعليم الرحلة كمسلمة';

  @override
  String get tripsSending => 'جارٍ الإرسال...';

  @override
  String get tripsMarking => 'جارٍ التعليم...';

  @override
  String tripsSubTerritoryRequired(Object invoices) {
    return 'يرجى اختيار منطقة فرعية للطلبات التالية قبل إنشاء رحلة: $invoices';
  }

  @override
  String tripsInvoicesCount(Object count) {
    return 'الفواتير ($count)';
  }

  @override
  String get subTerritorySelectTitle => 'اختر المنطقة الفرعية';

  @override
  String subTerritoryForTerritory(Object territory) {
    return 'لـ $territory';
  }

  @override
  String get subTerritoryNoResults => 'لم يتم العثور على مناطق فرعية';

  @override
  String get subTerritoryLoadFailed => 'تعذر تحميل المناطق الفرعية';

  @override
  String get customShippingBadgePending => 'الشحن المخصص قيد الانتظار';

  @override
  String get customShippingBadgeApproved => 'تمت الموافقة على الشحن المخصص';

  @override
  String customShippingBadgeAmount(Object amount) {
    return 'شحن مخصص $amount';
  }

  @override
  String get customShippingBadgeRejected => 'تم رفض الشحن المخصص';

  @override
  String get returnBadgeFull => 'مرتجع بالكامل';

  @override
  String get returnBadgePartial => 'مرتجع جزئي';

  @override
  String returnBadgeFullAmount(Object amount) {
    return 'مرتجع بالكامل $amount';
  }

  @override
  String returnBadgePartialAmount(Object amount) {
    return 'مرتجع جزئي $amount';
  }

  @override
  String get receiptSelectImageSource => 'اختر مصدر الصورة';

  @override
  String get receiptCamera => 'الكاميرا';

  @override
  String get receiptGallery => 'المعرض';

  @override
  String get receiptUploading => 'جارٍ رفع صورة الإيصال...';

  @override
  String get receiptUploadedSuccess => 'تم رفع صورة الإيصال بنجاح';

  @override
  String get receiptUploadFailed => 'فشل رفع صورة الإيصال';

  @override
  String get receiptImageEmpty =>
      'تعذّرت قراءة هذه الصورة. حاول مرة أخرى أو اختر صورة أخرى.';

  @override
  String receiptUploadError(Object error) {
    return 'خطأ في رفع الصورة: $error';
  }

  @override
  String get receiptConfirming => 'جارٍ تأكيد الإيصال...';

  @override
  String get receiptConfirmedSuccess => 'تم تأكيد الإيصال بنجاح';

  @override
  String get receiptConfirmFailed => 'فشل تأكيد الإيصال';

  @override
  String receiptConfirmError(Object error) {
    return 'خطأ في تأكيد الإيصال: $error';
  }

  @override
  String get receiptAllProfiles => 'جميع الملفات الشخصية';

  @override
  String get receiptFilterByPosProfile => 'تصفية حسب ملف نقطة البيع';

  @override
  String get receiptNoReceiptsFound => 'لا توجد إيصالات دفع';

  @override
  String get receiptUploadImageButton => 'رفع صورة الإيصال';

  @override
  String get receiptReplaceImageButton => 'استبدال الصورة';

  @override
  String get receiptRemoveImageButton => 'حذف الصورة';

  @override
  String get receiptRemoveConfirmTitle => 'حذف صورة الإيصال؟';

  @override
  String get receiptRemoveConfirmBody =>
      'سيتم حذف الصورة المرفوعة، ويمكنك رفع صورة جديدة بعد ذلك.';

  @override
  String get receiptRemoving => 'جارٍ حذف صورة الإيصال...';

  @override
  String get receiptRemovedSuccess => 'تم حذف صورة الإيصال';

  @override
  String get receiptRemoveFailed => 'فشل حذف صورة الإيصال';

  @override
  String receiptRemoveError(Object error) {
    return 'خطأ في حذف الصورة: $error';
  }

  @override
  String get receiptPreviewTitle => 'معاينة الإيصال';

  @override
  String get receiptPreviewButton => 'معاينة الإيصال';

  @override
  String get commonPrint => 'طباعة';

  @override
  String get statusCreated => 'تم الإنشاء';

  @override
  String get statusOutForDelivery => 'خارج للتوصيل';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusDelivered => 'تم التسليم';

  @override
  String get statusReturn => 'مرتجع';

  @override
  String get statusReturned => 'مرتجع بالكامل';

  @override
  String get statusReturnedToSender => 'تم الإرجاع إلى المرسل';

  @override
  String get statusPaid => 'مدفوع';

  @override
  String get statusUnpaid => 'غير مدفوع';

  @override
  String get statusOverdue => 'متأخر';

  @override
  String get statusCancelled => 'ملغي';

  @override
  String get statusConfirmed => 'مؤكد';

  @override
  String get statusUnconfirmed => 'غير مؤكد';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusPendingApproval => 'قيد الاعتماد';

  @override
  String get statusApproved => 'معتمد';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get statusDraft => 'مسودة';

  @override
  String get kanbanNoInvoices => 'مفيش فواتير';

  @override
  String get kanbanTripCreatedSuccess => 'تم إنشاء رحلة التوصيل بنجاح';

  @override
  String kanbanPartOfTripWarning(Object tripName) {
    return 'هذا الطلب جزء من رحلة $tripName. أرسل الرحلة كاملة للتوصيل من شاشة الرحلات.';
  }

  @override
  String get kanbanOfdAwaitingInstapay => 'خرج للتوصيل — في انتظار إنستاباي';

  @override
  String kanbanOfdAwaitingInstapayWithCourier(Object courier) {
    return 'خرج للتوصيل مع $courier — في انتظار إنستاباي';
  }

  @override
  String get kanbanDeliveryPartnerCourier => 'ساعي شريك التوصيل';

  @override
  String get kanbanDeliveryPartnerCourierSubtitle =>
      'هذا الساعي تابع لشريك توصيل';

  @override
  String get kanbanRequestCustomShipping => 'طلب شحن مخصص';

  @override
  String get customShippingCurrentShipping => 'الشحن الحالي';

  @override
  String get customShippingRequestedAmount => 'المبلغ المطلوب';

  @override
  String get customShippingReasonHint => 'لماذا تحتاج إلى شحن مخصص...';

  @override
  String get customShippingAmountRequired => 'المبلغ مطلوب';

  @override
  String get customShippingAmountInvalid => 'أدخل مبلغًا موجبًا صحيحًا';

  @override
  String get customShippingReasonRequired =>
      'يرجى كتابة سبب واضح (10 أحرف على الأقل)';

  @override
  String get customShippingSubmitRequest => 'إرسال الطلب';

  @override
  String get kanbanCustomShippingSubmitted => 'تم تقديم طلب الشحن المخصص';

  @override
  String kanbanCustomShippingFailed(Object error) {
    return 'فشل تقديم الطلب: $error';
  }

  @override
  String get settlementPartnerDeliveryTitle => 'تسوية شريك التوصيل';

  @override
  String get settlementPartnerInfoTitle => 'معلومات تسوية الشريك';

  @override
  String settlementPartnerLabel(Object name) {
    return 'الشريك: $name';
  }

  @override
  String get settlementPartnerCollectFull => 'استلم كامل مبلغ الطلب من الساعي:';

  @override
  String get settlementPartnerOnlinePaid =>
      'مدفوع إلكترونياً — لا يوجد تبادل نقدي مع الساعي';

  @override
  String get settlementPartnerCollectFullChip => 'استلام (المبلغ الكامل)';

  @override
  String get settlementNoExchange => 'لا يوجد تبادل نقدي';

  @override
  String settlementPartnerFeeTracked(Object amount) {
    return 'رسوم الشريك (محسوبة): $amount';
  }

  @override
  String get settlementPartnerCollectedFull =>
      'تم تحصيل مبلغ الطلب كاملاً من السائق';

  @override
  String get settlementPartnerFullAmountChip => 'المبلغ الكامل';

  @override
  String get settlementPartnerOnlinePaidInfo => 'دفع إلكتروني — لا تبادل نقدي';

  @override
  String get managerPendingCustomShipping => 'طلبات الشحن المخصص المعلقة';

  @override
  String get managerNoPendingRequests => 'لا توجد طلبات معلقة';

  @override
  String managerReasonLabel(Object reason) {
    return 'السبب: $reason';
  }

  @override
  String get managerCustomShippingApproved => 'تمت الموافقة على الشحن المخصص';

  @override
  String managerApproveFailed(Object error) {
    return 'فشلت الموافقة: $error';
  }

  @override
  String get managerRejectCustomShippingTitle => 'رفض الشحن المخصص';

  @override
  String get managerReject => 'رفض';

  @override
  String get managerCustomShippingRejected => 'تم رفض الشحن المخصص';

  @override
  String managerRejectFailed(Object error) {
    return 'فشل الرفض: $error';
  }

  @override
  String get managerRejectReasonHint => 'سبب الرفض (اختياري)';

  @override
  String get managerPendingCustomShippingLoadFailed =>
      'فشل تحميل طلبات الشحن المخصص المعلقة';

  @override
  String get managerTransferBranchesLoadFailed => 'فشل تحميل فروع التحويل';

  @override
  String get managerApproveDefaultError => 'تعذر اعتماد الطلب.';

  @override
  String get managerRejectDefaultError => 'تعذر رفض الطلب.';

  @override
  String get purchaseNoInvoicesYet => 'لا توجد فواتير شراء بعد';

  @override
  String get purchaseReorderFromSupplier => 'إعادة نفس الطلب';

  @override
  String get purchaseHistoryTitle => 'سجل المشتريات';

  @override
  String get posCreateCustomer => 'إنشاء عميل';

  @override
  String get posCustomerCreatedSuccess => 'تم إنشاء العميل بنجاح!';

  @override
  String get settingsUserProfileTitle => 'الملف الشخصي';

  @override
  String get settingsRolesTitle => 'الأدوار';

  @override
  String get settingsNoRolesAssigned => 'لا توجد أدوار مخصصة';

  @override
  String get settingsNotificationSettings => 'إعدادات الإشعارات';

  @override
  String get settingsNoAlarmSounds => 'لا توجد أصوات تنبيه متاحة';

  @override
  String get settingsAlarmSoundLabel => 'صوت التنبيه';

  @override
  String settingsFailedToLoadAlarmSounds(Object error) {
    return 'فشل تحميل أصوات التنبيه: $error';
  }

  @override
  String settingsAlarmSoundChanged(Object title) {
    return 'تم تغيير صوت التنبيه إلى $title';
  }

  @override
  String settingsAlarmSoundUnavailable(Object title) {
    return 'لا يمكن استخدام $title على هذا الجهاز. سيتم الإبقاء على صوت التنبيه الافتراضي.';
  }

  @override
  String settingsCustomAlarmSoundSet(Object title) {
    return 'تم تعيين صوت التنبيه المخصص: $title';
  }

  @override
  String get settingsNoFileSelected => 'لم يتم اختيار ملف';

  @override
  String get settingsBrowseCustomSoundFile => 'استعراض ملف صوت مخصص';

  @override
  String get settingsCustomSoundTitle => 'الصوت المخصص';

  @override
  String itemGridStockLimitReached(Object stockQty) {
    return 'تم الوصول لحد المخزون. المتوفر $stockQty فقط.';
  }

  @override
  String get menuDeliveryTrips => 'رحلات التوصيل';

  @override
  String get authLoginTitle => 'تسجيل الدخول';

  @override
  String get printingPrintersTitle => 'الطابعات';

  @override
  String get printingUseBitmapReceipt => 'استخدام الإيصال النقطي الجديد';

  @override
  String get printingUseBitmapReceiptHint =>
      'يعرض الإيصال الكامل كصورة ويساعد في حل مشاكل العربية والبيانات الناقصة والنص غير المقروء.';

  @override
  String kanbanOrdersSelectedCount(int count) {
    return '$count طلبات محددة';
  }

  @override
  String get loginModeDialogTitle => 'اختر وضع الدخول';

  @override
  String get loginModeLineManager => 'مدير خط';

  @override
  String get loginModeLineManagerDesc =>
      'تخطي فتح الوردية — إدارة العمليات مباشرة';

  @override
  String get loginModeEmployee => 'موظف';

  @override
  String get loginModeEmployeeDesc => 'فتح وردية قبل بدء العمل';

  @override
  String get customerSearchHint => 'بحث بالاسم أو رقم الهاتف';

  @override
  String get customerSearchStartTyping =>
      'ابدأ بكتابة الاسم أو رقم الهاتف للبحث عن عميل';

  @override
  String get customerSearchNoResults => 'لا يوجد عملاء مطابقون';

  @override
  String get customerSearchByPhone => '...بحث برقم الهاتف';

  @override
  String get customerSearchByName => '...بحث باسم العميل';

  @override
  String get quickAddCustomerTitle => 'إضافة عميل سريع';

  @override
  String get quickAddCustomerTap => 'اضغط لإنشاء عميل جديد';

  @override
  String get customerNameLabel => 'اسم العميل *';

  @override
  String get customerNameRequired => 'اسم العميل مطلوب';

  @override
  String get customerTypeLabel => 'نوع العميل';

  @override
  String get customerTypeIndividual => 'فرد';

  @override
  String get customerTypeCompany => 'شركة';

  @override
  String get customerGroupLabel => 'مجموعة العميل';

  @override
  String get customerGroupRequired => 'يرجى اختيار مجموعة العميل';

  @override
  String get mobileNumberLabel => 'رقم الهاتف *';

  @override
  String get mobileNumberRequired => 'رقم الهاتف مطلوب';

  @override
  String get secondaryPhoneLabel => 'هاتف ثانوي (اختياري)';

  @override
  String get secondaryPhoneHint => 'رقم تواصل إضافي';

  @override
  String get locationLinkLabel => 'رابط الموقع (اختياري)';

  @override
  String get locationLinkHint => 'رابط خرائط جوجل، إلخ.';

  @override
  String get locationLinkFieldLabel => 'رابط الموقع';

  @override
  String get locationLinkPasteHint =>
      'الصق رابط خرائط جوجل أو 30.0444, 31.2357';

  @override
  String get locationLinkChecking => 'بنراجع الموقع…';

  @override
  String get locationLinkConfirmed => 'الموقع اتأكد';

  @override
  String get locationLinkUnconfirmed => 'الموقع لسه ما اتأكدش';

  @override
  String get locationLinkClear => 'امسح رابط الموقع';

  @override
  String get locationLinkRetry => 'راجع تاني';

  @override
  String locationLinkDistanceKm(Object value) {
    return '$value كم من الفرع';
  }

  @override
  String locationLinkDistanceMeters(Object value) {
    return '$value متر من الفرع';
  }

  @override
  String get locationLinkErrorUnrecognized =>
      'ده مش شكل رابط خرائط. الصق رابط من خرائط جوجل أو إحداثيات زي 30.0444, 31.2357.';

  @override
  String get locationLinkErrorUnresolved =>
      'مقدرناش نطلع موقع من الرابط ده. افتحه في الخرائط وشيره تاني والصق الرابط الجديد.';

  @override
  String get locationLinkErrorOutsideArea =>
      'الموقع ده برة مصر، فمينفعش يكون عنوان توصيل. راجع الرابط.';

  @override
  String get locationLinkErrorPlaceLink =>
      'الرابط ده لمحل أو مكان، مش دبوس. افتح الخرائط، دوس مطوّل على مكان العميل بالظبط لحد ما يظهر دبوس، شير الدبوس ده والصق الرابط الجديد.';

  @override
  String locationLinkErrorTooFar(Object distance) {
    return 'النقطة دي $distance — بعيدة أوي على إنها عنوان توصيل. راجع الرابط.';
  }

  @override
  String get locationLinkErrorNetwork => 'مقدرناش نراجع الموقع. جرب تاني.';

  @override
  String get detailedAddressRequired => 'العنوان التفصيلي *';

  @override
  String get detailedAddressOptional => 'العنوان التفصيلي (اختياري)';

  @override
  String get addressOptionalPartner => 'اختياري عند اختيار شريك مبيعات';

  @override
  String get addressRequired => 'العنوان مطلوب';

  @override
  String get territoryLabel => 'المنطقة *';

  @override
  String get territorySelectRequired => 'يرجى اختيار منطقة';

  @override
  String get territoryLoadFailed => 'فشل تحميل المناطق';

  @override
  String get unknownTerritory => 'منطقة غير معروفة';

  @override
  String get customerCreateFailed => 'فشل إنشاء العميل';

  @override
  String get authUsernameLabel => 'اسم المستخدم';

  @override
  String get authPasswordLabel => 'كلمة المرور';

  @override
  String get authShowPassword => 'إظهار كلمة المرور';

  @override
  String get authHidePassword => 'إخفاء كلمة المرور';

  @override
  String get authInvalidCredentials => 'بيانات الاعتماد غير صحيحة';

  @override
  String get authCannotReachServer =>
      'تعذر الوصول إلى الخادم. تحقق من شبكة Wi-Fi أو الـ VPN وعنوان الخادم ثم حاول مرة أخرى.';

  @override
  String get authConnectionFailed =>
      'فشل الاتصال. يرجى التحقق من الشبكة وتوفر الخادم.';

  @override
  String get authLoginFailed => 'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.';

  @override
  String get menuReports => 'التقارير';

  @override
  String get velocityReportTileTitle => 'تنبيهات إعادة الطلب والسرعة';

  @override
  String get velocityReportTileSubtitle =>
      'تنبيهات إعادة التخزين من تتبع سرعة المبيعات الأسبوعي';

  @override
  String get velocityReportTitle => 'تنبيهات إعادة الطلب والسرعة';

  @override
  String get velocityReportSummaryCritical => 'حرج';

  @override
  String get velocityReportSummaryWatch => 'قائمة المراقبة';

  @override
  String get velocityReportSummarySlow => 'بطيئة الحركة';

  @override
  String get velocityReportSummaryOverstock => 'فائض مخزون';

  @override
  String get velocityReportDetailTitle => 'تفاصيل السرعة';

  @override
  String get velocityReportRecalculateAction => 'إعادة الحساب الآن';

  @override
  String get velocityReportRecalculateConfirmTitle => 'إعادة حساب السرعة الآن؟';

  @override
  String get velocityReportRecalculateConfirmBody =>
      'سيؤدي هذا إلى إعادة حساب سرعة المبيعات لكل صنف مخزون، وقد يستغرق بعض الوقت. المهمة الأسبوعية تُحدّث هذه البيانات تلقائيًا بالفعل.';

  @override
  String velocityReportRecalculateSuccess(int count) {
    return 'تم تحديث السرعة لـ $count صنف';
  }

  @override
  String get velocityReportRecalculateError =>
      'تعذّرت إعادة حساب السرعة. حاول مرة أخرى.';

  @override
  String get segmentReportTileTitle => 'شرائح العملاء (RFM)';

  @override
  String get segmentReportTileSubtitle =>
      'تصنيف الحداثة والتكرار والقيمة من المهمة الليلية';

  @override
  String get segmentReportTitle => 'شرائح العملاء';

  @override
  String get segmentReportColumnCount => 'العملاء';

  @override
  String get segmentReportTotalCustomers => 'إجمالي العملاء';

  @override
  String get segmentReportRecalculateAction => 'إعادة الحساب الآن';

  @override
  String get segmentReportRecalculateConfirmTitle => 'إعادة حساب الشرائح الآن؟';

  @override
  String get segmentReportRecalculateConfirmBody =>
      'سيؤدي هذا إلى إعادة حساب شرائح RFM لكل عميل، مع تخطي العملاء المثبّتين. المهمة الليلية تُحدّث هذه البيانات تلقائيًا بالفعل.';

  @override
  String segmentReportRecalculateSuccess(int updated) {
    return 'تم تحديث الشرائح لـ $updated عميل';
  }

  @override
  String get segmentReportRecalculateError =>
      'تعذّرت إعادة حساب الشرائح. حاول مرة أخرى.';

  @override
  String segmentReportCustomersTitle(Object segment) {
    return 'عملاء شريحة $segment';
  }

  @override
  String get segmentReportCopyAll => 'نسخ الكل';

  @override
  String get segmentReportCopied => 'تم النسخ إلى الحافظة';

  @override
  String get segmentReportExportEmpty => 'لا يوجد عملاء في هذه الشريحة';

  @override
  String get segmentReportPin => 'تثبيت الشريحة';

  @override
  String get segmentReportUnpin => 'إلغاء تثبيت الشريحة';

  @override
  String segmentReportPinConfirmBody(Object customer) {
    return 'تثبيت شريحة $customer حتى تتوقف عن التغيير في عملية إعادة الحساب القادمة؟';
  }

  @override
  String segmentReportUnpinConfirmBody(Object customer) {
    return 'إلغاء تثبيت $customer حتى تُحسب شريحته تلقائيًا مرة أخرى؟';
  }

  @override
  String get segmentReportOverrideSuccess => 'تم تحديث الشريحة';

  @override
  String get segmentReportOverrideError =>
      'تعذّر تحديث الشريحة. حاول مرة أخرى.';

  @override
  String get reportsTitle => 'التقارير';

  @override
  String get reportsFinalProducts => 'المنتجات النهائية';

  @override
  String get reportsFinalProductsDesc =>
      'جرد المخزون حسب المستودع للأصناف الصغيرة والمتوسطة والكبيرة';

  @override
  String get reportsMaterials => 'المواد والمستهلكات';

  @override
  String get reportsMaterialsDesc =>
      'المواد الخام والتجميعات الفرعية والمستهلكات';

  @override
  String get reportsRawMaterials => 'المواد الخام';

  @override
  String get reportsSubAssemblies => 'التجميعات الفرعية';

  @override
  String get reportsConsumables => 'المستهلكات';

  @override
  String get reportsItemName => 'الصنف';

  @override
  String get reportsItemGroup => 'المجموعة';

  @override
  String get reportsTotal => 'الإجمالي';

  @override
  String get reportsNoData => 'لا توجد بيانات';

  @override
  String get reportsRetry => 'إعادة المحاولة';

  @override
  String get reportsComingSoon => 'قريباً';

  @override
  String get reportsFrom => 'من';

  @override
  String get reportsTo => 'إلى';

  @override
  String get reportsRangeThisMonth => 'هذا الشهر';

  @override
  String get reportsRangeLast30Days => 'آخر 30 يوماً';

  @override
  String get reportsRangeLast90Days => 'آخر 90 يوماً';

  @override
  String get reportShippingTitle => 'تحليلات الشحن';

  @override
  String get reportShippingSubtitle =>
      'تكلفة التوصيل وتسويات المندوبين وأرباح الشحن';

  @override
  String get reportInventoryTitle => 'ذكاء المخزون';

  @override
  String get reportInventorySubtitle =>
      'سرعة دوران المخزون والأصناف الحرجة والأكثر حركة';

  @override
  String get reportProductTitle => 'تحليلات المنتجات';

  @override
  String get reportProductSubtitle =>
      'الإيرادات والربح الإجمالي والأكثر مبيعاً حسب المنتج';

  @override
  String get reportCustomerTitle => 'تحليلات العملاء';

  @override
  String get reportCustomerSubtitle =>
      'الشرائح والاحتفاظ والعملاء المعرضون للخطر';

  @override
  String get reportExecutiveTitle => 'النظرة التنفيذية';

  @override
  String get reportExecutiveSubtitle => 'أهم مؤشرات الأداء عبر النشاط بالكامل';

  @override
  String get reportB2bTitle => 'مبيعات وعملاء الجملة';

  @override
  String get reportB2bSubtitle => 'إيرادات الجملة وخط الأنابيب وصحة العملاء';

  @override
  String get reportNoData => 'لا توجد بيانات لهذه الفترة';

  @override
  String get reportError => 'تعذّر تحميل التقرير';

  @override
  String get reportAlerts => 'التنبيهات';

  @override
  String get reportShipKpiTotalOrders => 'إجمالي الطلبات';

  @override
  String get reportShipKpiDeliveryOrders => 'طلبات التوصيل';

  @override
  String get reportShipKpiPickupOrders => 'طلبات الاستلام';

  @override
  String get reportShipKpiExpense => 'مصروف الشحن';

  @override
  String get reportShipKpiIncome => 'إيراد التوصيل';

  @override
  String get reportShipKpiNetPl => 'صافي الربح/الخسارة';

  @override
  String get reportShipKpiAvgCost => 'متوسط التكلفة لكل طلب';

  @override
  String get reportShipKpiPendingOverrides => 'التعديلات المعلقة';

  @override
  String get reportShipKpiUnsettled => 'غير مسوّى';

  @override
  String get reportCostByTerritory => 'التكلفة حسب المنطقة';

  @override
  String get reportCostBySubTerritory => 'التكلفة حسب المنطقة الفرعية';

  @override
  String get reportCostByBranch => 'التكلفة حسب الفرع';

  @override
  String get reportCostByCourier => 'التكلفة حسب المندوب';

  @override
  String get reportShippingOverrides => 'تعديلات الشحن';

  @override
  String get reportDoubleShipping => 'أثر ازدواج الشحن';

  @override
  String get reportDailyTrend => 'الاتجاه اليومي';

  @override
  String get reportPickupVsDelivery => 'الاستلام مقابل التوصيل';

  @override
  String get reportUnsettledBalances => 'أرصدة المندوبين غير المسوّاة';

  @override
  String get reportPickupDeliveryTrend => 'اتجاه الاستلام / التوصيل';

  @override
  String get reportInvKpiStockItems => 'أصناف المخزون';

  @override
  String get reportInvKpiCritical => 'حرجة';

  @override
  String get reportInvKpiWatch => 'قائمة المراقبة';

  @override
  String get reportInvKpiSlow => 'بطيئة الحركة';

  @override
  String get reportInvKpiOverstock => 'مخزون زائد';

  @override
  String get reportInvKpiStockValue => 'قيمة المخزون';

  @override
  String get reportStockVelocity => 'سرعة دوران المخزون';

  @override
  String get reportTopMovers => 'الأكثر حركة';

  @override
  String get reportRestockAlerts => 'تنبيهات إعادة التخزين';

  @override
  String get reportCriticalItems => 'حرجة';

  @override
  String get reportWatchList => 'قائمة المراقبة';

  @override
  String get reportSlowMovers => 'بطيئة الحركة';

  @override
  String get reportOverstocked => 'مخزون زائد';

  @override
  String get reportTopSellers => 'الأكثر مبيعاً';

  @override
  String get reportKpiTotalRevenue => 'إجمالي الإيرادات';

  @override
  String get reportKpiTotalOrders => 'إجمالي الطلبات';

  @override
  String get reportKpiGrossProfit => 'إجمالي الربح';

  @override
  String get reportKpiGrossMargin => 'هامش الربح الإجمالي';

  @override
  String get reportKpiAov => 'متوسط قيمة الطلب';

  @override
  String get reportKpiBestSeller => 'الأكثر مبيعاً';

  @override
  String get reportKpiTopTerritory => 'أعلى منطقة';

  @override
  String get reportRevenueByType => 'الإيرادات حسب النوع';

  @override
  String get reportTopProducts => 'أفضل المنتجات';

  @override
  String get reportByTerritory => 'حسب المنطقة';

  @override
  String get reportRevenueTrend => 'اتجاه الإيرادات';

  @override
  String get reportBundleComposition => 'تكوين الباقات';

  @override
  String get reportKpiTotalCustomers => 'إجمالي العملاء';

  @override
  String get reportKpiActive => 'نشط';

  @override
  String get reportKpiNew => 'جديد';

  @override
  String get reportKpiRepeatRate => 'معدل تكرار الشراء';

  @override
  String get reportKpiChampions => 'العملاء المميزون';

  @override
  String get reportKpiAtRisk => 'معرضون للخطر';

  @override
  String get reportKpiLost => 'مفقودون';

  @override
  String get reportSegmentDistribution => 'توزيع الشرائح';

  @override
  String get reportSegmentDetail => 'تفاصيل الشريحة';

  @override
  String get reportTopCustomers => 'أفضل العملاء';

  @override
  String get reportAtRiskWinBack => 'المعرضون للخطر / الاستعادة';

  @override
  String get reportNewCustomerAcquisition => 'اكتساب عملاء جدد';

  @override
  String get reportKpiRevenue => 'الإيرادات';

  @override
  String get reportKpiOrders => 'الطلبات';

  @override
  String get reportKpiNetShippingPl => 'صافي ربح/خسارة الشحن';

  @override
  String get reportKpiCustomers => 'العملاء';

  @override
  String get reportKpiCriticalStock => 'المخزون الحرج';

  @override
  String get reportProductMix => 'مزيج المنتجات';

  @override
  String get reportCustomerSegments => 'شرائح العملاء';

  @override
  String get reportTopTerritories => 'أعلى المناطق';

  @override
  String get reportKpiB2bRevenue => 'إيرادات الجملة';

  @override
  String get reportKpiB2bOrders => 'طلبات الجملة';

  @override
  String get reportKpiActiveClients => 'العملاء النشطون';

  @override
  String get reportKpiNewClients => 'عملاء جدد';

  @override
  String get reportKpiReorderDue => 'إعادة الطلب مستحقة';

  @override
  String get reportSalesPipeline => 'خط أنابيب المبيعات';

  @override
  String get reportTopClients => 'أفضل العملاء';

  @override
  String get reportRevenueByPolicy => 'الإيرادات حسب السياسة التجارية';

  @override
  String get reportClientsByGroup => 'العملاء حسب المجموعة';

  @override
  String get reportReorderDue => 'إعادة الطلب مستحقة';

  @override
  String get reportAtRiskClients => 'العملاء المعرضون للخطر';

  @override
  String get reportConversion => 'التحويل';

  @override
  String get menuMasterOrders => 'جميع الطلبات';

  @override
  String get masterOrdersTitle => 'جميع الطلبات';

  @override
  String get masterOrdersSearchHint => 'بحث برقم الطلب أو العميل...';

  @override
  String get masterOrdersNoResults => 'لا توجد طلبات';

  @override
  String get masterOrdersClearFilters => 'مسح الفلاتر';

  @override
  String masterOrdersResultCount(int count) {
    return '$count طلب';
  }

  @override
  String get masterOrdersFilterStatus => 'الحالة';

  @override
  String get masterOrdersFilterBranch => 'الفرع';

  @override
  String get masterOrdersFilterPayment => 'الدفع';

  @override
  String get masterOrdersFilterDate => 'نطاق التاريخ';

  @override
  String get masterOrdersFilterDateFrom => 'من';

  @override
  String get masterOrdersFilterDateTo => 'إلى';

  @override
  String get masterOrdersOutstanding => 'المتبقي';

  @override
  String get masterOrdersCurrency => 'ج.م';

  @override
  String get menuShiftMonitor => 'متابعة الشيفتات';

  @override
  String get shiftMonitorTitle => 'متابعة شيفتات نقاط البيع';

  @override
  String get shiftMonitorAccessRequired => 'يلزم صلاحية مدير';

  @override
  String get shiftMonitorAccessDeniedBody =>
      'هذه الصفحة متاحة لأدوار JARZ Manager وما فوق فقط.';

  @override
  String get shiftMonitorFiltersTitle => 'الفلاتر';

  @override
  String get shiftMonitorToday => 'اليوم';

  @override
  String get shiftMonitorLast7Days => 'آخر 7 أيام';

  @override
  String get shiftMonitorCustomRange => 'فترة مخصصة';

  @override
  String get shiftMonitorPickDateRange => 'اختر الفترة';

  @override
  String shiftMonitorDateRangeValue(Object from, Object to) {
    return '$from إلى $to';
  }

  @override
  String get shiftMonitorProfileFilter => 'ملف نقطة البيع';

  @override
  String get shiftMonitorStatusFilter => 'الحالة';

  @override
  String get shiftMonitorStatusAll => 'الكل';

  @override
  String get shiftMonitorStatusOpen => 'مفتوح';

  @override
  String get shiftMonitorStatusClosed => 'مغلق';

  @override
  String get shiftMonitorNoData => 'لا توجد شيفتات للفلاتر المحددة.';

  @override
  String get shiftMonitorOpenCount => 'الشيفتات المفتوحة';

  @override
  String get shiftMonitorClosedCount => 'الشيفتات المغلقة';

  @override
  String get shiftMonitorDiscrepancyCount => 'حالات الفرق';

  @override
  String get shiftMonitorDiscrepancyTotal => 'إجمالي الفروق';

  @override
  String shiftMonitorLatestStart(Object value) {
    return 'آخر بداية: $value';
  }

  @override
  String shiftMonitorShiftCount(Object count) {
    return '$count شيفت';
  }

  @override
  String get shiftMonitorOpenedAt => 'وقت الفتح';

  @override
  String get shiftMonitorOpenedBy => 'تم الفتح بواسطة';

  @override
  String get shiftMonitorClosedAt => 'وقت الإغلاق';

  @override
  String get shiftMonitorClosedBy => 'تم الإغلاق بواسطة';

  @override
  String get shiftMonitorCashAccount => 'الحساب النقدي';

  @override
  String get shiftMonitorOpeningCash => 'نقدية البداية';

  @override
  String get shiftMonitorExpectedClosingCash => 'إقفال متوقع';

  @override
  String get shiftMonitorActualClosingCash => 'إقفال فعلي';

  @override
  String get shiftMonitorDifference => 'الفرق';

  @override
  String get shiftMonitorDifferenceSurplus => 'زيادة';

  @override
  String get shiftMonitorDifferenceShortage => 'عجز';

  @override
  String get shiftMonitorNoDiscrepancy => 'لا يوجد فرق';

  @override
  String get shorebirdUpdateBannerMessage =>
      'يتوفر إصدار جديد — أغلق التطبيق تمامًا ثم أعد فتحه لتطبيقه.';

  @override
  String get aboutRestartInstruction =>
      'أغلق التطبيق تماماً وأعد فتحه لتطبيق التحديث المُنزَّل.';

  @override
  String get aboutPatchPending => 'التصحيح المُعلَّق (بعد إعادة التشغيل)';

  @override
  String get menuLeads => 'العملاء المحتملون';

  @override
  String get leadFieldEmail => 'البريد الإلكتروني';

  @override
  String get leadFieldSource => 'المصدر';

  @override
  String get leadFieldTerritory => 'المنطقة';

  @override
  String get leadB2bStage => 'مرحلة B2B';

  @override
  String get leadFitScore => 'درجة الملاءمة';

  @override
  String get b2bMoveTo => 'نقل إلى';

  @override
  String get shiftMonitorForceCloseAction => 'إقفال هذه الوردية';

  @override
  String shiftMonitorForceCloseTitle(String user) {
    return 'إقفال وردية $user';
  }

  @override
  String shiftMonitorForceCloseIntro(String user, String branch) {
    return 'أنت تقوم بإقفال وردية فتحها $user في $branch. أدخل النقدية المعدودة فعليًا في الدرج — أي فرق هيتسجل في حساب العجز/الزيادة، زي الإقفال العادي بالظبط.';
  }

  @override
  String get shiftMonitorForceCloseReasonLabel => 'السبب (مطلوب)';

  @override
  String get shiftMonitorForceCloseReasonHint =>
      'مثلاً: الموظف مشي من غير ما يقفل';

  @override
  String get shiftMonitorForceCloseReasonRequired =>
      'من فضلك اكتب سبب إقفال وردية شخص تاني.';

  @override
  String shiftMonitorForceCloseCountLabel(String mode) {
    return 'المبلغ المعدود — $mode';
  }

  @override
  String shiftMonitorForceCloseCountRequired(String mode) {
    return 'أدخل المبلغ المعدود لـ $mode.';
  }

  @override
  String shiftMonitorForceCloseExpected(String amount) {
    return 'المتوقع من النظام: $amount';
  }

  @override
  String shiftMonitorForceCloseCourierWarning(int transactions, int invoices) {
    return 'الفرع لسه عنده $transactions معاملة مندوب غير مسواة على $invoices طلب. هتفضل مفتوحة بعد الإقفال ولازم تتسوى.';
  }

  @override
  String get shiftMonitorForceCloseCourierAck => 'أنا فاهم وعايز أقفل برضه';

  @override
  String get shiftMonitorForceCloseConfirm => 'إقفال الوردية';

  @override
  String get shiftMonitorForceCloseSuccess => 'تم إقفال الوردية.';

  @override
  String get returnOrderTitle => 'مرتجع الطلب';

  @override
  String get returnOrderLinesLabel => 'الأصناف الراجعة';

  @override
  String returnOrderLineAvailable(String qty) {
    return 'تقدر ترجّع لحد $qty';
  }

  @override
  String returnOrderLineAvailableAfterPrior(String qty, String returned) {
    return 'تقدر ترجّع لحد $qty (اترجع قبل كده $returned)';
  }

  @override
  String get returnOrderLineFullyReturned => 'اترجع بالكامل';

  @override
  String get returnOrderCreditAmountLabel => 'هيتحسب للعميل';

  @override
  String get returnOrderFullNotice =>
      'الطلب راجع بالكامل. البضاعة هترجع للفرع والطلب هيتحسب كله للعميل.';

  @override
  String get returnOrderPartialNotice =>
      'جزء من الطلب راجع. الأصناف المختارة بس هي اللي هتترجع للمخزن وتتحسب للعميل.';

  @override
  String get returnOrderTypeLabel => 'نوع المرتجع';

  @override
  String get returnTypeCustomerReturn => 'العميل رجّع الطلب';

  @override
  String get returnTypeFailedDelivery => 'التوصيل فشل';

  @override
  String get returnTypeDamaged => 'تالف';

  @override
  String get returnTypeWrongItem => 'صنف غلط';

  @override
  String get returnOrderReasonLabel => 'السبب';

  @override
  String get returnOrderReasonRequired => 'من فضلك اكتب سبب رجوع الطلب';

  @override
  String get returnOrderNotesOptional => 'ملاحظات إضافية (اختياري)';

  @override
  String get returnOrderPayCourierTitle => 'ادفع للمندوب أجر الرحلة دي';

  @override
  String get returnOrderPayCourierYes => 'المندوب هياخد أجر التوصيل بتاعه.';

  @override
  String get returnOrderPayCourierNo => 'أجر التوصيل هيتشال من حساب المندوب.';

  @override
  String get returnOrderRefundLabel => 'الفلوس اللي اتحصلت';

  @override
  String get returnOrderRefundCredit => 'تفضل رصيد للعميل';

  @override
  String get returnOrderRefundNow => 'ارجع الفلوس دلوقتي';

  @override
  String get returnOrderRefundUnavailable => 'مفيش فلوس متحصلة عشان تترد.';

  @override
  String get returnOrderConfirmButton => 'تأكيد المرتجع';

  @override
  String get returnOrderProcessing => 'بنعمل المرتجع…';

  @override
  String get returnOrderPreviewFailed => 'مقدرناش نحمّل تفاصيل المرتجع.';

  @override
  String get returnOrderNotAvailable => 'الطلب ده مينفعش يترجع.';

  @override
  String get returnOrderFailed => 'المرتجع ماتمّش.';

  @override
  String get returnOrderSuccess => 'تم المرتجع.';

  @override
  String returnOrderSuccessWithCn(String creditNote) {
    return 'تم المرتجع. اتعمل إشعار دائن $creditNote.';
  }

  @override
  String get menuItemRequests => 'طلبات الأصناف';

  @override
  String get requestsTitle => 'طلبات الأصناف';

  @override
  String get requestsFilterOpen => 'المفتوحة';

  @override
  String get requestsFilterMine => 'طلباتي';

  @override
  String get requestsFilterAll => 'الكل';

  @override
  String get requestsEmptyOpen => 'مفيش حاجة مطلوبة دلوقتي';

  @override
  String get requestsEmptyMine => 'لسه ماطلبتش حاجة';

  @override
  String get requestsEmptyAll => 'مفيش طلبات';

  @override
  String get requestsEmptyHint => 'دوس + عشان تطلب حاجة قربت تخلص.';

  @override
  String get requestsNewTitle => 'اطلب أصناف';

  @override
  String get requestsAddItems => 'ضيف أصناف';

  @override
  String get requestsNeededBy => 'محتاجها قبل';

  @override
  String get requestsNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get requestsNoteHint => 'الماركة، المقاس، الاستعجال';

  @override
  String get requestsSubmit => 'ابعت الطلب';

  @override
  String requestsSubmitted(Object name) {
    return 'الطلب $name اتبعت';
  }

  @override
  String requestsSubmitFailed(Object error) {
    return 'الطلب مابعتش: $error';
  }

  @override
  String get requestsNoItemsYet => 'لسه مفيش أصناف';

  @override
  String requestsItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أصناف',
      one: 'صنف واحد',
    );
    return '$_temp0';
  }

  @override
  String requestsRequestedBy(Object name) {
    return 'من $name';
  }

  @override
  String get requestsOverdue => 'متأخر';

  @override
  String get requestsStatusPending => 'مستني';

  @override
  String get requestsStatusPartiallyReceived => 'اتشرى جزء';

  @override
  String get requestsStatusReceived => 'اتشرى';

  @override
  String get requestsStatusStopped => 'مرفوض';

  @override
  String get requestsStatusCancelled => 'ملغي';

  @override
  String get requestsStatusOrdered => 'اتطلب';

  @override
  String get requestsReject => 'ارفض';

  @override
  String get requestsRejectTitle => 'ترفض الطلب ده؟';

  @override
  String get requestsRejectReason => 'السبب (اختياري)';

  @override
  String get requestsRejected => 'الطلب اترفض';

  @override
  String get requestsEdit => 'تعديل';

  @override
  String get requestsEditTitle => 'تعديل الطلب';

  @override
  String get requestsSaveChanges => 'احفظ التعديلات';

  @override
  String requestsUpdated(Object name) {
    return 'الطلب $name اتعدّل';
  }

  @override
  String get requestsUnit => 'الوحدة';

  @override
  String get requestsReopen => 'افتحه تاني';

  @override
  String get requestsReopened => 'الطلب اتفتح تاني';

  @override
  String get requestsAccept => 'قبول';

  @override
  String get requestsAccepted => 'الطلب اتقبل — صاحب الطلب هيشوف ده';

  @override
  String requestsAcceptedBy(Object name) {
    return 'اتقبل من $name';
  }

  @override
  String get requestsAwaitingAcceptance => 'لسه متقبلش';

  @override
  String get purchaseReorderReplaceTitle => 'تستبدل السلة الحالية؟';

  @override
  String purchaseReorderReplaceBody(Object invoice) {
    return 'السلة فيها أصناف. إعادة الطلب هتستبدلها بأصناف $invoice.';
  }

  @override
  String get purchaseReorderReplace => 'استبدال';

  @override
  String purchaseReorderFilled(Object invoice) {
    return 'اتملت من $invoice — راجع وبعدين أكّد';
  }

  @override
  String get purchaseReorderNothing => 'الفاتورة دي مفيهاش أصناف لإعادة الطلب';

  @override
  String requestsLineProgress(Object received, Object requested, Object uom) {
    return '$received من $requested $uom';
  }

  @override
  String get requestsBranchLabel => 'الفرع';

  @override
  String get purchaseFromRequests => 'من الطلبات';

  @override
  String get purchaseFromRequestsTitle => 'اشتري الأصناف المطلوبة';

  @override
  String get purchaseFromRequestsEmpty => 'مفيش طلبات مفتوحة';

  @override
  String get purchaseFromRequestsHint =>
      'الكميات متملية بالباقي المطلوب. غيّر اللي انت عايزه قبل الإضافة.';

  @override
  String purchaseRequestedQty(Object qty) {
    return 'مطلوب $qty';
  }

  @override
  String purchaseBuyingLess(Object requested, Object buying) {
    return 'مطلوب $requested، هتشتري $buying';
  }

  @override
  String purchaseOnHand(Object qty) {
    return 'المتاح $qty';
  }

  @override
  String purchaseLastPaid(Object rate) {
    return 'آخر سعر $rate';
  }

  @override
  String purchaseAddSelected(Object count) {
    return 'ضيف $count للسلة';
  }

  @override
  String purchaseNeededBy(Object date) {
    return 'محتاجها $date';
  }

  @override
  String get purchaseRequestSources => 'طلبها';

  @override
  String get purchaseUrgent => 'مستعجل';

  @override
  String get purchasePaymentCredit => 'على الحساب (تدفع بعدين)';

  @override
  String get purchasePaymentCreditSubtitle => 'هيفضل رصيد مستحق للمورد';

  @override
  String get purchaseBillNoLabel => 'رقم فاتورة المورد';

  @override
  String get purchaseBillNoHint => 'من فاتورة المورد نفسها';

  @override
  String get purchaseBillDateLabel => 'تاريخ الفاتورة';

  @override
  String get purchaseTaxesLabel => 'الضرايب';

  @override
  String get purchaseTaxesNone => 'بدون ضريبة';

  @override
  String get purchaseNoVat => 'بدون ضريبة قيمة مضافة';

  @override
  String purchaseVatValue(Object amount) {
    return 'ض.ق.م: $amount';
  }

  @override
  String purchaseNetTotalValue(Object amount) {
    return 'الصافي: $amount';
  }

  @override
  String get purchaseNewSupplier => 'مورد جديد';

  @override
  String get purchaseNewSupplierName => 'اسم المورد';

  @override
  String get purchaseNewSupplierGroup => 'مجموعة المورد';

  @override
  String get purchaseNewSupplierPhone => 'التليفون (اختياري)';

  @override
  String purchaseSupplierCreated(Object name) {
    return 'المورد $name اتعمل';
  }

  @override
  String get purchaseSubmitting => 'بيعمل الشراء';

  @override
  String get purchaseOutstandingLabel => 'المستحق';

  @override
  String get purchasePayNow => 'ادفع دلوقتي';

  @override
  String purchasePaid(Object entry) {
    return 'الدفع اتسجل ($entry)';
  }

  @override
  String get purchaseReturnAction => 'مرتجع للمورد';

  @override
  String get purchaseReturnTitle => 'مرتجع للمورد';

  @override
  String get purchaseReturnReason => 'السبب';

  @override
  String get purchaseReturnQtyLabel => 'كمية المرتجع';

  @override
  String get purchaseReturnSubmit => 'اعمل المرتجع';

  @override
  String purchaseReturned(Object name) {
    return 'المرتجع $name اتعمل';
  }

  @override
  String get purchaseHistoryFilterSupplier => 'المورد';

  @override
  String get purchaseHistoryFilterStatus => 'الحالة';

  @override
  String get purchaseHistoryFilterAll => 'الكل';

  @override
  String get purchaseHistoryFilterClear => 'امسح الفلاتر';

  @override
  String get purchaseHistorySearchHint => 'رقم الفاتورة أو فاتورة المورد';

  @override
  String purchaseItemsInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أصناف',
      one: 'صنف واحد',
    );
    return '$_temp0';
  }

  @override
  String kanbanRunProgressLabel(int delivered, int total) {
    return '$delivered/$total اتسلّم';
  }

  @override
  String kanbanRunProgressTooltip(String courier, int delivered, int total) {
    return '$courier: سلّم $delivered من $total محطة على البورد';
  }

  @override
  String get kanbanRunProgressComplete => 'خلّص الخط';

  @override
  String kanbanRunStopLabel(int sequence) {
    return 'محطة $sequence';
  }

  @override
  String kanbanRunFailedLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محطات فاتوا',
      one: 'محطة فاتت',
    );
    return '$_temp0';
  }

  @override
  String kanbanRunFailedTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محطات اتجرب يوصلهم ومحصلش تسليم',
      one: 'محطة واحدة اتجرب يوصلها ومحصلش تسليم',
    );
    return '$_temp0';
  }

  @override
  String get kanbanRunAttemptFailedLabel => 'التسليم فات';

  @override
  String kanbanRunAttemptFailedTooltip(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: '$attempts مرات',
      one: 'مرة',
    );
    return 'المحطة دي اتجرب فيها $_temp0 ولسه مش متسلمة';
  }

  @override
  String get menuLiveCourierMap => 'خريطة المندوبين لايف';

  @override
  String get fleetTitle => 'خريطة المندوبين لايف';

  @override
  String get fleetRefreshTooltip => 'حدّث دلوقتي';

  @override
  String fleetUpdatedAgo(String ago) {
    return 'اتحدّث $ago';
  }

  @override
  String get fleetUpdating => 'بيحدّث…';

  @override
  String fleetCouriersOnMap(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مندوبين على الخريطة',
      one: 'مندوب واحد على الخريطة',
    );
    return '$_temp0';
  }

  @override
  String get fleetRefreshFailed =>
      'التحديث فشل — المواقع اللي شايفها بتقدم وبتبقى أقدم';

  @override
  String get fleetLegendTitle => 'كل نقطة عمرها قد إيه';

  @override
  String fleetLegendFresh(int minutes) {
    return 'جديدة · أقل من $minutes دقيقة';
  }

  @override
  String fleetLegendAgeing(int from, int to) {
    return 'بتقدم · من $from لـ $to دقيقة';
  }

  @override
  String fleetLegendStale(int minutes) {
    return 'قديمة · أكتر من $minutes دقيقة، متعتمدش عليها';
  }

  @override
  String get fleetFreshnessFresh => 'جديدة';

  @override
  String get fleetFreshnessAgeing => 'بتقدم';

  @override
  String get fleetFreshnessStale => 'قديمة';

  @override
  String get fleetStaleWarning =>
      'فيه مندوبين مبعتوش موقعهم من مدة — اتأكد قبل ما تبعتلهم طلب';

  @override
  String get fleetAgeJustNow => 'دلوقتي';

  @override
  String fleetAgeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'من $minutes دقيقة',
      one: 'من دقيقة',
    );
    return '$_temp0';
  }

  @override
  String fleetAgeHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'من $hours ساعة',
      one: 'من ساعة',
    );
    return '$_temp0';
  }

  @override
  String fleetAgeDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'من $days يوم',
      one: 'من يوم',
    );
    return '$_temp0';
  }

  @override
  String get fleetAgeUnknown => 'من غير وقت';

  @override
  String get fleetAgeShortNow => 'دلوقتي';

  @override
  String fleetAgeShortMinutes(int minutes) {
    return '$minutes د';
  }

  @override
  String fleetAgeShortHours(int hours) {
    return '$hours س';
  }

  @override
  String fleetAgeShortDays(int days) {
    return '$days ي';
  }

  @override
  String get fleetBranchLabel => 'الفرع';

  @override
  String get fleetBranchUnknown => 'من غير فرع';

  @override
  String get fleetLastFixLabel => 'آخر موقع';

  @override
  String get fleetAccuracyLabel => 'الدقة';

  @override
  String fleetAccuracyValue(String meters) {
    return '±$meters متر';
  }

  @override
  String get fleetAccuracyUnknown => 'مش متبعتة';

  @override
  String get fleetEmptyNoCouriersTitle => 'مفيش مندوبين على الشيفت';

  @override
  String get fleetEmptyNoCouriersBody =>
      'محدش داخل على أبليكيشن المندوبين دلوقتي، يعني مفيش حاجة نتابعها. المواقع هتظهر هنا أول ما مندوب يبدأ شيفته.';

  @override
  String get fleetEmptyNoPositionsTitle => 'على الشيفت بس لسه مبعتوش موقع';

  @override
  String get fleetEmptyNoPositionsBody =>
      'المندوبين دول داخلين بس تليفوناتهم مبعتتش موقع. اتأكد إن أبليكيشن المندوب واخد إذن الموقع وإن فيه شبكة.';

  @override
  String fleetEmptyNoPositionsNames(String names) {
    return 'مستنيين: $names';
  }

  @override
  String fleetUnlocatedBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مندوبين على الشيفت مبعتوش موقع',
      one: 'مندوب واحد على الشيفت مبعتش موقع',
    );
    return '$_temp0';
  }

  @override
  String get fleetForbiddenTitle => 'للمشرفين بس';

  @override
  String get fleetForbiddenBody =>
      'مواقع المندوبين اللايف متاحة للمديرين والمشرفين بس. إعادة المحاولة مش هتفرق — كلّم مدير يفتحلك الشاشة دي.';

  @override
  String get fleetErrorTitle => 'مش قادر يجيب مواقع المندوبين';

  @override
  String get labelsTitle => 'ليبلات العملاء';

  @override
  String get labelsHelpTooltip => 'الشاشة دي بتشتغل إزاي';

  @override
  String get labelsRefreshTooltip => 'تحديث';

  @override
  String get labelsSetUpCustomer => 'ضيف عميل';

  @override
  String get labelsSetupNothingNew => 'مفيش حاجة جديدة نتابعها';

  @override
  String labelsSetupTrackingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بنتابع دلوقتي $count نكهات',
      one: 'بنتابع دلوقتي نكهة واحدة',
    );
    return '$_temp0';
  }

  @override
  String labelsSetupSkippedSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' ($count كانوا متتابعين قبل كده)',
      one: ' (واحدة كانت متتابعة قبل كده)',
    );
    return '$_temp0';
  }

  @override
  String labelsPrintOrderSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فرخ اتبعتوا للمطبعة',
      one: 'فرخ واحد اتبعت للمطبعة',
    );
    return '$_temp0';
  }

  @override
  String labelsPrintOrderDueBack(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فرخ اتطلبوا — مفروض يرجعوا $date',
      one: 'فرخ واحد اتطلب — مفروض يرجع $date',
    );
    return '$_temp0';
  }

  @override
  String get labelsHelpTitle => 'متابعة الليبلات بتشتغل إزاي';

  @override
  String get labelsHelpRows =>
      'كل نكهة ليها تصميم ليبل خاص بيها، وكل نكهة بتتتابع في سطر لوحدها لكل فرع الليبلات متخزنة فيه، فالعميل اللي بيتخدم من فرعين بيبقى ليه سطر في كل فرع. JARZ بتطبع كل الليبلات، والليبلات بتتخصم من المخزن لوحدها أول ما فاتورة العميل تتعمل.';

  @override
  String labelsHelpSheets(Object small, Object medium, Object large) {
    return 'الطباعة بتتطلب بالفرخ — $small ليبل سمول أو $medium ليبل ميديم أو $large ليبل لارج في الفرخ.';
  }

  @override
  String labelsHelpLeadTime(
    Object min,
    Object max,
    String restDay,
    Object buffer,
  ) {
    return 'الطباعة بتاخد من $min لـ $max يوم شغل من غير $restDay، فالليبل بيتعلّم \"اطبع دلوقتي\" أول ما الرصيد اللي فاضل ميكفيش المدة دي — و\"اطبع قريب\" قبلها بـ $buffer يوم.';
  }

  @override
  String get labelsHelpQuiet =>
      'أول ما الدفعة تروح المطبعة الليبل بيسكت وبيوريك تاريخ رجوعه بدل التنبيه، عشان نفس النقص ميتقالش عليك كل يوم الصبح.';

  @override
  String get labelsHelpAlertsOff =>
      'التنبيهات اليومية مقفولة حاليًا من إعدادات Jarz POS.';

  @override
  String get labelsHelpGotIt => 'تمام';

  @override
  String labelsSummaryUrgent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ليبل لازم يروحوا المطبعة دلوقتي',
      one: 'ليبل واحد لازم يروح المطبعة دلوقتي',
    );
    return '$_temp0';
  }

  @override
  String labelsSummarySoon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ليبل محتاجين طباعة قريب',
      one: 'ليبل واحد محتاج طباعة قريب',
    );
    return '$_temp0';
  }

  @override
  String get labelsSummaryNothing => 'مفيش حاجة محتاجة طباعة';

  @override
  String labelsSummaryLeadTime(Object min, Object max, String restDay) {
    return 'الطباعة بتاخد من $min لـ $max يوم شغل · من غير $restDay';
  }

  @override
  String labelsSummaryReadySuffix(String date) {
    return ' · اطلب النهارده، يجهز $date';
  }

  @override
  String get labelsFilterNeedsPrinting => 'محتاج طباعة';

  @override
  String get labelsFilterAll => 'الكل';

  @override
  String get labelsFilterAtPrinter => 'في المطبعة';

  @override
  String labelsFilterWithCount(String text, int count) {
    return '$text ($count)';
  }

  @override
  String get labelsAllLocations => 'كل الأماكن';

  @override
  String get labelsSearchHint => 'دوّر على عميل أو نكهة';

  @override
  String get labelsEmptyNoneTitle => 'لسه مفيش ليبلات متتابعة';

  @override
  String get labelsEmptyNoneBody =>
      'ضيف عملاء الجملة اللي JARZ بتطبعلهم ليبل البرطمانات — ليبل لكل نكهة. بعد كده الرصيد بينزل لوحده مع كل فاتورة ليهم.';

  @override
  String get labelsEmptyEnoughCover => 'كل الليبلات رصيدها مكفي';

  @override
  String get labelsEmptyNoMatch => 'مفيش حاجة مطابقة للفلتر ده';

  @override
  String get labelsShowAll => 'وريني كل الليبلات';

  @override
  String get labelStatusOutOfStock => 'خلصان';

  @override
  String get labelStatusOutOfStockWhy =>
      'مفيش ليبلات خالص. العميل ده مش هينفع يتعبّى.';

  @override
  String get labelStatusPrintNow => 'اطبع دلوقتي';

  @override
  String labelStatusPrintNowWhy(int days) {
    return 'الرصيد هيخلص قبل ما دفعة جديدة توصل ($days يوم شغل).';
  }

  @override
  String get labelStatusPrintSoon => 'اطبع قريب';

  @override
  String get labelStatusPrintSoonWhy =>
      'قرّبنا على النقطة اللي مفيش بعدها رجوع.';

  @override
  String get labelStatusAtPrinter => 'في المطبعة';

  @override
  String get labelStatusAtPrinterWhy => 'فيه دفعة جاية بالفعل.';

  @override
  String get labelStatusOk => 'تمام';

  @override
  String get labelStatusOkWhy => 'الرصيد مريح.';

  @override
  String get labelStatusUnknown => 'غير معروف';

  @override
  String get labelStatusNotTracked => 'مش متتابع';

  @override
  String get labelStatusNotTrackedWhy => 'الليبل ده متقفل، فمفيش حاجة بتتحسب.';

  @override
  String labelCardFlavours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نكهات',
      one: 'نكهة واحدة',
    );
    return '$_temp0';
  }

  @override
  String labelCardNeedPrintingSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' · $count محتاجين طباعة',
      one: ' · واحدة محتاجة طباعة',
    );
    return '$_temp0';
  }

  @override
  String get labelCardCustomerActions => 'إجراءات العميل';

  @override
  String get labelCardNotTracked => 'متقفل، مش بيتحسب';

  @override
  String get labelCardAddFlavour => 'ضيف نكهة';

  @override
  String get labelCardOnHand => 'بالمخزن';

  @override
  String get labelCardOfCover => 'تغطية';

  @override
  String labelCardOrderSheets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اطلب $count فرخ',
      one: 'اطلب فرخ واحد',
    );
    return '$_temp0';
  }

  @override
  String get labelCardOrderBatch => 'اطلب دفعة';

  @override
  String get labelCardCoverOver99 => '‏99+ يوم';

  @override
  String labelCardCoverDays(String days) {
    return '$days يوم';
  }

  @override
  String get labelCardCoverNone => '—';

  @override
  String labelCardSheetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فرخ',
      one: 'فرخ واحد',
    );
    return '$_temp0';
  }

  @override
  String labelCardLabelsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ليبل',
      one: 'ليبل واحد',
    );
    return '$_temp0';
  }

  @override
  String labelCardAtPrinter(String what) {
    return '$what في المطبعة';
  }

  @override
  String labelCardOverdueSince(String what, String date) {
    return '$what متأخرين في المطبعة من $date';
  }

  @override
  String labelCardDueBack(String what, String date) {
    return '$what مفروض يرجعوا $date';
  }

  @override
  String labelCardRunsOutAround(String date) {
    return 'هيخلص حوالي $date';
  }

  @override
  String get labelCardNoUsage => 'لسه مفيش استهلاك مسجّل';

  @override
  String labelCardOrderAhead(int days) {
    return 'اطلب قبلها بـ $days يوم شغل';
  }

  @override
  String get labelPrintStatusRequested => 'متطلبة';

  @override
  String get labelPrintStatusPrinting => 'بتتطبع';

  @override
  String get labelPrintStatusReady => 'جاهزة';

  @override
  String get labelPrintStatusReceived => 'اتستلمت';

  @override
  String get labelPrintStatusCancelled => 'ملغية';

  @override
  String get labelMovementConsumed => 'اتستخدمت على برطمانات';

  @override
  String get labelMovementPrintReceived => 'اتستلمت من المطبعة';

  @override
  String get labelMovementScrapped => 'تلفت أو اترمت';

  @override
  String get labelMovementAdjustment => 'تصحيح (+/-)';

  @override
  String get labelDetailFallbackTitle => 'ليبل';

  @override
  String get labelDetailSettingsTooltip => 'إعدادات الليبل';

  @override
  String labelDetailLoadFailed(String error) {
    return 'مش قادر يفتح الليبل ده.\n$error';
  }

  @override
  String labelDetailSentToPrinter(String what) {
    return '$what اتبعتوا للمطبعة';
  }

  @override
  String get labelDetailCountSaved => 'الجرد اتحفظ';

  @override
  String get labelDetailMovementRecorded => 'الحركة اتسجّلت';

  @override
  String labelDetailReceivedAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ليبل اتضافوا للمخزن',
      one: 'ليبل واحد اتضاف للمخزن',
    );
    return '$_temp0';
  }

  @override
  String labelDetailBatchMarked(String status) {
    return 'الدفعة اتعلّمت $status';
  }

  @override
  String get labelDetailBillRecorded =>
      'الفاتورة اتسجّلت — واتعملت فاتورة شراء';

  @override
  String get labelDetailSettingsSaved => 'الإعدادات اتحفظت';

  @override
  String labelDetailStoredAt(String location) {
    return 'متخزّن في $location';
  }

  @override
  String get labelDetailLabelsOnHand => 'ليبل بالمخزن';

  @override
  String get labelDetailDaysOfCover => 'أيام التغطية';

  @override
  String get labelDetailUnknownValue => 'مش معروف';

  @override
  String get labelDetailUsedPerDay => 'الاستهلاك اليومي';

  @override
  String get labelDetailRunsOut => 'هيخلص';

  @override
  String labelDetailUsedInDays(int days) {
    return 'اتستهلك في $days يوم';
  }

  @override
  String get labelDetailStockValue => 'قيمة المخزون';

  @override
  String get labelDetailAvgCost => 'متوسط تكلفة الليبل';

  @override
  String get labelDetailRetired =>
      'الليبل ده متوقف. رجّعه من إعدادات الليبل عشان العد يكمّل.';

  @override
  String get labelDetailActionOrder => 'اطلب';

  @override
  String get labelDetailActionCount => 'جرد';

  @override
  String get labelDetailActionRecord => 'سجّل';

  @override
  String get labelDetailSectionBatches => 'دفعات الطباعة';

  @override
  String labelDetailOrderedOn(String date) {
    return 'اتطلبت $date';
  }

  @override
  String labelDetailOverdueSince(String date) {
    return 'متأخرة من $date';
  }

  @override
  String labelDetailDueOn(String date) {
    return 'موعدها $date';
  }

  @override
  String labelDetailReceivedOn(String date) {
    return 'اتستلمت $date';
  }

  @override
  String labelDetailReceivedOnQty(String date, int qty) {
    return 'اتستلمت $date ($qty)';
  }

  @override
  String get labelDetailReceiveIntoStock => 'استلام للمخزن';

  @override
  String get labelDetailMarkPrinting => 'علّمها بتتطبع';

  @override
  String get labelDetailMarkReady => 'علّمها جاهزة';

  @override
  String get labelDetailRecordBill => 'سجّل فاتورة المطبعة';

  @override
  String get labelDetailCancelBatch => 'إلغاء الدفعة';

  @override
  String get labelDetailBilled => 'متفوترة';

  @override
  String labelDetailBilledWithInvoice(String invoice) {
    return 'متفوترة · $invoice';
  }

  @override
  String get labelDetailUnbilled => 'مش متفوترة';

  @override
  String labelDetailUnbilledQuoted(String amount) {
    return 'مش متفوترة · عرض سعر $amount';
  }

  @override
  String get labelDetailPolicyFlavour => 'النكهة';

  @override
  String get labelDetailPolicySize => 'المقاس';

  @override
  String get labelDetailPolicyStoredAt => 'مكان التخزين';

  @override
  String get labelDetailPolicyNotSet => 'مش متحدد';

  @override
  String get labelDetailPolicyMinStock => 'الحد الأدنى للمخزون';

  @override
  String get labelDetailPolicyUsualBatch => 'دفعة الطباعة المعتادة';

  @override
  String get labelDetailPolicyLabelsPerSheet => 'ليبل في الفرخ';

  @override
  String get labelDetailPolicyLabelsPerJar => 'ليبل في البرطمان';

  @override
  String get labelDetailPolicyLeadTime => 'مدة الطباعة';

  @override
  String labelDetailPolicyLeadTimeValue(
    Object min,
    Object max,
    String restDay,
  ) {
    return 'من $min لـ $max يوم شغل (من غير $restDay)';
  }

  @override
  String get labelDetailPolicyLastCounted => 'آخر جرد';

  @override
  String get labelDetailPolicyLastMovement => 'آخر حركة';

  @override
  String get labelDetailSectionSetup => 'الإعداد';

  @override
  String get labelDetailSectionHistory => 'السجل';

  @override
  String get labelDetailHistoryEmpty =>
      'لسه مفيش حاجة متسجّلة. الليبلات بتتخصم لوحدها مع كل فاتورة للعميل ده.';

  @override
  String get labelDetailAutoPosted => 'اتسجّلت أوتوماتيك من الفاتورة';

  @override
  String get labelSheetSupplierOptional => 'مورّد الطباعة (اختياري)';

  @override
  String get labelSheetPrintSupplier => 'مورّد الطباعة';

  @override
  String get labelSheetCountTitle => 'جرد الليبلات';

  @override
  String get labelSheetCountSubtitle =>
      'اكتب اللي موجود فعلًا على الرف. الفرق بيتسجّل في السجل، فالليبل اللي بيقل على طول بيبان كسلسلة تصحيحات مش بيضيع في الساكت.';

  @override
  String get labelSheetCountedQty => 'الكمية المعدودة';

  @override
  String labelSheetSystemShows(int qty) {
    return 'النظام مسجّل حاليًا $qty.';
  }

  @override
  String labelSheetDeltaMore(int count) {
    return '$count أكتر من المسجّل';
  }

  @override
  String labelSheetDeltaFewer(int count) {
    return '$count أقل من المسجّل';
  }

  @override
  String get labelSheetNoteOptional => 'ملاحظة (اختياري)';

  @override
  String get labelSheetNotesOptional => 'ملاحظات (اختياري)';

  @override
  String get labelSheetSaveCount => 'احفظ الجرد';

  @override
  String get labelSheetOrderTitle => 'اطلب دفعة طباعة';

  @override
  String labelSheetLeadPlain(Object min, Object max, String restDay) {
    return 'الطباعة بتاخد من $min لـ $max يوم شغل (من غير $restDay).';
  }

  @override
  String labelSheetLeadReady(
    String date,
    Object min,
    Object max,
    String restDay,
  ) {
    return 'لو اتطلبت النهارده هتجهز حوالي $date — من $min لـ $max يوم شغل، من غير $restDay.';
  }

  @override
  String get labelSheetSheetsToPrint => 'عدد الفروخ للطباعة';

  @override
  String labelSheetSuggestedSheets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'المقترح $count فرخ، على أساس الاستهلاك الحالي والدفعة المعتادة.',
      one: 'المقترح فرخ واحد، على أساس الاستهلاك الحالي والدفعة المعتادة.',
    );
    return '$_temp0';
  }

  @override
  String labelSheetSheetsEquals(String sheets, String labels) {
    return '$sheets = $labels';
  }

  @override
  String get labelSheetNetCostOptional => 'التكلفة الصافية (اختياري)';

  @override
  String get labelSheetNetCostQuoteHelper =>
      'السعر اللي المطبعة قالته على الدفعة، قبل الضريبة. الفاتورة نفسها بتتسجّل أول ما توصل.';

  @override
  String get labelSheetSendToPrinter => 'ابعت للمطبعة';

  @override
  String get labelSheetReceiveTitle => 'استلام دفعة';

  @override
  String labelSheetReceiveSubtitle(String name, String ordered) {
    return '$name · المطلوب $ordered';
  }

  @override
  String get labelSheetLabelsReceived => 'الليبلات المستلمة';

  @override
  String get labelSheetReceivedHelper =>
      'عدّل الرقم لو المطبعة سلّمت ناقص. العدد ده بس هو اللي هيتضاف للمخزن.';

  @override
  String get labelSheetAddToStock => 'ضيف للمخزن';

  @override
  String get labelSheetBillTitle => 'سجّل فاتورة المطبعة';

  @override
  String labelSheetBillSubtitle(String name, String ordered) {
    return '$name · $ordered. ده بيعمل فاتورة شراء للمورّد، فالدفعة بتتسجّل في الدفاتر بتكلفتها الحقيقية.';
  }

  @override
  String get labelSheetNetCost => 'التكلفة الصافية';

  @override
  String get labelSheetNetCostBillHelper =>
      'المبلغ اللي المطبعة حاسبته على الدفعة دي، قبل الضريبة.';

  @override
  String get labelSheetBillNoOptional => 'رقم فاتورة المورّد (اختياري)';

  @override
  String get labelSheetRecordBill => 'سجّل الفاتورة';

  @override
  String get labelSheetMovementTitle => 'سجّل حركة';

  @override
  String get labelSheetWhatHappened => 'اللي حصل';

  @override
  String get labelSheetQuantity => 'الكمية';

  @override
  String get labelSheetAdjustmentHelper => 'حط علامة ناقص عشان تقلّل المخزون.';

  @override
  String get labelSheetQtyHelper =>
      'اكتب رقم عادي — الاتجاه بيتحدد من نوع الحركة.';

  @override
  String get labelSheetLabelName => 'اسم الليبل';

  @override
  String get labelSheetActive => 'شغّال';

  @override
  String get labelSheetActiveHelp => 'اقفله عشان توقف تصميم مابقاش بيتستخدم.';

  @override
  String get labelSheetStoredAtHelper =>
      'الفرع أو المصنع اللي الليبل ده متخزّن فيه فعلًا.';

  @override
  String get labelSheetUsualBatchSheets => 'الدفعة المعتادة (فروخ)';

  @override
  String get labelSheetLabelsPerSheetHelper =>
      'سيبها 0 عشان تاخد الافتراضي حسب المقاس: 21 سمول، 21 ميديم، 18 لارج.';

  @override
  String get labelSheetLabelsPerJarHelper => 'عادةً 1.';

  @override
  String get labelWizardTitle => 'إعداد ليبلات العميل';

  @override
  String get labelWizardStartTracking => 'ابدأ المتابعة';

  @override
  String get labelWizardContinue => 'كمّل';

  @override
  String get labelWizardBack => 'رجوع';

  @override
  String get labelWizardStepCustomer => 'العميل';

  @override
  String get labelWizardStepFlavours => 'النكهات';

  @override
  String labelWizardPickedCount(int count) {
    return 'متختار $count';
  }

  @override
  String get labelWizardStepLocation => 'مكان تخزين الليبلات';

  @override
  String get labelWizardStepConfirm => 'تأكيد';

  @override
  String get labelWizardChange => 'غيّر';

  @override
  String labelWizardCustomerPriceList(String customer, String priceList) {
    return '$customer · قائمة الأسعار: $priceList';
  }

  @override
  String get labelWizardSearchCustomers => 'دوّر على عملاء';

  @override
  String get labelWizardSearching => 'بيدوّر…';

  @override
  String get labelWizardNoCustomers => 'مفيش عملاء شركات مطابقين.';

  @override
  String labelWizardPriceList(String priceList) {
    return 'قائمة الأسعار: $priceList';
  }

  @override
  String labelWizardFlavoursLoadFailed(String error) {
    return 'مش قادر يجيب النكهات.\n$error';
  }

  @override
  String get labelWizardPickCustomerFirst => 'اختار عميل الأول.';

  @override
  String get labelWizardNoFlavours =>
      'مفيش نكهات للعميل ده — لا حاجة في قائمة أسعاره ولا طلبات سابقة.';

  @override
  String get labelWizardSizeOther => 'أخرى';

  @override
  String get labelWizardFlavourHelp =>
      'علّم على كل نكهة عايز تتابعها في الفرع اللي هتختاره في الخطوة الجاية. النكهة المتتابعة في فرع تاني تقدر تعلّم عليها تاني. واكتب اللي موجود على الرف دلوقتي عشان محدش يبدأ خلصان.';

  @override
  String get labelWizardAlreadyTracked => 'متتابعة بالفعل';

  @override
  String labelWizardTrackedAt(String locations) {
    return 'متتابعة في $locations';
  }

  @override
  String labelWizardAlreadyAtLocation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نكهات من اللي اخترتها متتابعة بالفعل في الفرع ده وهتتساب.',
      one: 'نكهة واحدة من اللي اخترتها متتابعة بالفعل في الفرع ده وهتتساب.',
    );
    return '$_temp0';
  }

  @override
  String get labelWizardOnPriceList => 'في قائمة الأسعار';

  @override
  String get labelWizardOrderedBefore => 'اتطلبت قبل كده';

  @override
  String get labelWizardLabelsInStock => 'الليبلات الموجودة دلوقتي';

  @override
  String get labelWizardLocationsLoadFailed =>
      'مش قادر يجيب الأماكن — تقدر تحدد مكان لكل ليبل بعدين.';

  @override
  String get labelWizardStoredAtHelper =>
      'الفرع أو المصنع اللي الليبلات دي متخزّنة فيه فعلًا.';

  @override
  String get labelWizardUsualBatchSheets => 'دفعة الطباعة المعتادة (فروخ)';

  @override
  String get labelWizardUsualBatchHelper =>
      'بتتطبق على كل النكهات، وتقدر تغيّرها لكل ليبل بعدين.';

  @override
  String get labelWizardConfirmPriceList => 'قائمة الأسعار';

  @override
  String get labelWizardConfirmUsualBatch => 'الدفعة المعتادة';

  @override
  String get labelWizardSafeToRerun =>
      'النكهة المتتابعة بالفعل في الفرع اللي اخترته مش بتتلمس، ولو اخترت فرع تاني بتتضاف ليبلات الفرع ده. تقدر تعيد ده في أي وقت من غير قلق.';

  @override
  String labelCardAtPrinterSuffix(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: ' · $n عند المطبعة',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String get labelCardRecordOrder => 'سجّل طلب';

  @override
  String get labelsExpandAll => 'افتح الكل';

  @override
  String get labelsCollapseAll => 'اقفل الكل';

  @override
  String get labelQuickOrderTitle => 'سجّل طلب طباعة';

  @override
  String get labelQuickOrderBranch => 'رايح على';

  @override
  String get labelQuickOrderBranches => 'رايح على (دوس للتغيير)';

  @override
  String get labelQuickOrderFlavours => 'الشيتات المطلوبة';

  @override
  String labelQuickOrderTimesBranches(int n) {
    return '× $n فروع';
  }

  @override
  String get labelQuickOrderNotAtBranch => 'مش موجودة في الفرع المختار';

  @override
  String get labelQuickOrderFillSuggested => 'املا المقترح';

  @override
  String get labelQuickOrderOrderedOn => 'اتطلب يوم';

  @override
  String get labelQuickOrderMore => 'المورد والملاحظات';

  @override
  String labelQuickOrderSubmit(int n) {
    return 'سجّل الطلب · $n شيت';
  }

  @override
  String labelsQuickOrderRecorded(int count, int sheets) {
    return 'اتسجل $count طلب طباعة · $sheets شيت';
  }

  @override
  String labelsQuickOrderFailedSuffix(int n) {
    return ' · $n فشل';
  }

  @override
  String get labelDetailActionBought => 'تم الشراء والاستلام';

  @override
  String labelDetailBoughtRecorded(int count, String invoice) {
    return 'اتسجل $count ليبل، فاتورة $invoice';
  }

  @override
  String get labelSheetBoughtTitle => 'تم الشراء والاستلام';

  @override
  String labelSheetBoughtSubtitle(String name) {
    return '$name. لدفعة اتشرت واتسلمت خلاص: بتضيفها للمخزن وبتسجّل فاتورة المطبعة في خطوة واحدة.';
  }

  @override
  String get labelSheetSheetsBought => 'الشيتات المشتراة';

  @override
  String get labelSheetBoughtReceivedHelper =>
      'محسوبة من عدد الشيتات. غيّرها لو المطبعة سلّمت ناقص.';

  @override
  String get labelSheetBoughtOn => 'اتشرت / اتسلمت يوم';

  @override
  String get labelSheetRecordBought => 'ضيف للمخزن وسجّل الفاتورة';

  @override
  String get labelSheetPaymentHeading => 'الدفع';

  @override
  String get labelSheetPaymentOwed => 'على حساب المورد (ندفع بعدين)';

  @override
  String get labelSheetPaymentOwedSubtitle =>
      'الفاتورة بتفضل مفتوحة كمستحق للمطبعة';

  @override
  String get labelSheetPaymentPaid => 'اتدفعت دلوقتي';

  @override
  String labelSheetPaymentPaidFrom(String source) {
    return 'اتدفعت من $source';
  }

  @override
  String get labelSheetPaymentPickSource => 'اختار الفلوس اتدفعت منين';

  @override
  String get labelSheetPaymentChange => 'غيّر مصدر الدفع';

  @override
  String labelDetailBoughtAlreadyRecorded(String invoice) {
    return 'الشراء ده اتسجل قبل كده (فاتورة $invoice)';
  }

  @override
  String get labelDetailBoughtAlreadyRecordedNoBill =>
      'الشراء ده اتسجل قبل كده';

  @override
  String labelSheetBoughtBeforeCount(String date) {
    return 'الليبلات اللي اتسلمت قبل آخر جرد ($date) غالبًا محسوبة فيه — تسجيلها هيضيفها تاني.';
  }

  @override
  String get b2bStageLead => 'عميل محتمل';

  @override
  String get b2bStageQualify => 'تأهيل';

  @override
  String get b2bStageSample => 'عينة';

  @override
  String get b2bStageApproved => 'موافقة';

  @override
  String get b2bStageTrial => 'تجربة';

  @override
  String get b2bStageCheckup => 'متابعة';

  @override
  String get b2bStageActive => 'نشط';

  @override
  String get b2bStageLostOnHold => 'خسران/معلّق';

  @override
  String get leadsTitle => 'العملاء المحتملين';

  @override
  String get leadsMapTitle => 'خريطة العملاء المحتملين';

  @override
  String get leadsMapViewTooltip => 'عرض الخريطة';

  @override
  String get leadsListViewTooltip => 'عرض القايمة';

  @override
  String get leadsRefreshTooltip => 'تحديث';

  @override
  String get leadsAddLead => 'ضيف عميل محتمل';

  @override
  String get leadsStatShowing => 'المعروض';

  @override
  String get leadsStatTierA => 'الفئة A';

  @override
  String get leadsStatBranches => 'الفروع';

  @override
  String get leadsSearchHint => 'دوّر على عميل محتمل…';

  @override
  String get leadsAdvancedFilters => 'فلاتر متقدمة';

  @override
  String get leadsEmptyFiltered => 'مفيش عملاء محتملين مطابقين للفلاتر دي';

  @override
  String leadsDistanceMetres(String value) {
    return '$value م';
  }

  @override
  String leadsDistanceKm(String value) {
    return '$value كم';
  }

  @override
  String get leadsLocationServicesOff =>
      'خدمات الموقع مقفولة. شغّلها من إعدادات الجهاز.';

  @override
  String get leadsLocationBlocked => 'إذن الموقع محظور للتطبيق ده.';

  @override
  String get leadsLocationDenied => 'إذن الموقع اترفض.';

  @override
  String get leadsLocationNoFix => 'مش قادر يحدد موقعك. جرّب تاني وإنت برّه.';

  @override
  String get leadsLocationSettings => 'الإعدادات';

  @override
  String leadsOnMapCount(int count) {
    return '$count على الخريطة';
  }

  @override
  String leadsOnMapWithStages(int count, String stages) {
    return '$count على الخريطة  ·  $stages';
  }

  @override
  String leadsStageSummaryCount(int count) {
    return '$count مراحل';
  }

  @override
  String get leadsHideLegend => 'اخفي المفتاح';

  @override
  String get leadsCategoryLegend => 'مفتاح التصنيفات';

  @override
  String get leadsShowMyLocation => 'وريني موقعي';

  @override
  String leadsBranchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فروع',
      one: 'فرع واحد',
    );
    return '$_temp0';
  }

  @override
  String leadsDistanceAway(String distance) {
    return 'على بعد $distance (خط مستقيم)';
  }

  @override
  String leadsFilterActiveCount(int count) {
    return '$count مفعّلين';
  }

  @override
  String get leadsFilterPipelineStage => 'مرحلة المسار';

  @override
  String get leadsFilterRatingRange => 'نطاق التقييم';

  @override
  String leadsFilterMinReviews(int count) {
    return 'أقل عدد تقييمات: $count';
  }

  @override
  String get leadsFilterMinBranches => 'أقل عدد فروع';

  @override
  String get leadsFilterHasSahel => 'عنده فروع في الساحل';

  @override
  String get leadsFilterSpecialtyOnly => 'سبيشالتي بس';

  @override
  String get leadsFilterTakeawayOnly => 'تيك أواي مؤكد';

  @override
  String get leadsFilterTalabat => 'طلبات';

  @override
  String get leadsFilterTalabatOn => 'على طلبات';

  @override
  String get leadsFilterTalabatOff => 'مش على طلبات';

  @override
  String get leadsTalabatBadge => 'طلبات';

  @override
  String get leadsTalabatRatingFromGoogle =>
      'التقييم من جوجل — مفيش تقييم على طلبات لسه';

  @override
  String get leadsTalabatUnrated => 'موجود على طلبات، لسه من غير تقييم';

  @override
  String get leadsFilterHasPhone => 'عنده تليفون';

  @override
  String get leadsFilterHasInstagram => 'عنده إنستجرام';

  @override
  String get leadsFilterHasWebsite => 'عنده موقع';

  @override
  String get leadsFilterShowNotSuitable => 'وريني غير المناسبين';

  @override
  String get leadsFilterPriceBand => 'شريحة السعر';

  @override
  String get leadsFilterClearAll => 'امسح الكل';

  @override
  String leadsAreaClearCount(int count) {
    return 'امسح ($count)';
  }

  @override
  String get leadsAreaSearchHint => 'دوّر على مناطق';

  @override
  String leadsAreaNoMatch(String query) {
    return 'مفيش منطقة مطابقة لـ \"$query\"';
  }

  @override
  String get leadsAreaAll => 'كل المناطق';

  @override
  String leadsAreaSelectedCount(int count) {
    return '$count مناطق';
  }

  @override
  String leadsMergeConfirmTitle(int count, String survivor) {
    return 'تدمج $count في \"$survivor\"؟';
  }

  @override
  String leadsMergeConfirmBody(String survivor) {
    return 'فروعهم ومناطقهم وأي بيانات ناقصة عند \"$survivor\" هتتنقل ليه. العملاء المدموجين هيفضلوا محفوظين للمراجعة بس هيخرجوا من الكتالوج ومن بورد المسار.';
  }

  @override
  String leadsMergeFailed(String error) {
    return 'الدمج فشل: $error';
  }

  @override
  String get leadsMergeTitle => 'دمج المكرر';

  @override
  String leadsMergeSubtitle(String name) {
    return 'ادمج سجلات تانية لنفس البراند في \"$name\".';
  }

  @override
  String get leadsMergeSearchHint =>
      'دوّر بالاسم، أو سيبها فاضية عشان تشوف اقتراحات';

  @override
  String leadsMergeAction(int count) {
    return 'ادمج $count';
  }

  @override
  String get leadsMergeNoDuplicates =>
      'مفيش مكرر محتمل. دوّر بالاسم لو تعرف واحد.';

  @override
  String get leadsMergeNoMatch => 'مفيش عملاء محتملين مطابقين للبحث ده.';

  @override
  String get leadsMergedSuccess => 'العملاء المحتملين اتدمجوا';

  @override
  String get leadsAllStages => 'كل المراحل';

  @override
  String get leadsFilterTitle => 'الفلاتر';

  @override
  String get leadsFilterAreas => 'المناطق';

  @override
  String get leadsFilterAny => 'أي';

  @override
  String get leadsFilterAll => 'الكل';

  @override
  String get leadsFilterDone => 'تمام';

  @override
  String get leadDetailTitle => 'عميل محتمل';

  @override
  String get leadDetailEdit => 'عدّل العميل المحتمل';

  @override
  String leadDetailBranchesCount(int count) {
    return 'الفروع ($count)';
  }

  @override
  String get leadDetailStatusNotes => 'الحالة والملاحظات';

  @override
  String get leadDetailStatusField => 'الحالة';

  @override
  String get leadDetailCategoryField => 'التصنيف';

  @override
  String get leadDetailCategoryNone => 'بدون';

  @override
  String get leadDetailUpdated => 'العميل المحتمل اتحدّث';

  @override
  String leadDetailFailed(String error) {
    return 'فشل: $error';
  }

  @override
  String get leadDetailFitScoreUpdated => 'درجة الملاءمة اتحدّثت';

  @override
  String leadDetailScoreOutOf(int score) {
    return '$score / 100';
  }

  @override
  String leadDetailStageUpdated(String stage) {
    return 'المرحلة اتغيّرت لـ $stage';
  }

  @override
  String get leadDetailReasonTitle => 'السبب';

  @override
  String get leadDetailReasonHint => 'ليه ده خسران / معلّق؟';

  @override
  String get leadDetailNotSuitable => 'غير مناسب';

  @override
  String leadDetailByWhom(String user) {
    return 'بواسطة $user';
  }

  @override
  String leadDetailOnDate(String date) {
    return 'بتاريخ $date';
  }

  @override
  String get leadDetailMarkedNotSuitable => 'اتعلّم غير مناسب';

  @override
  String get leadDetailRestoreTitle => 'ترجّع العميل المحتمل؟';

  @override
  String get leadDetailRestoreBody =>
      'ده بيشيل حكم \"غير مناسب\" ويرجّع العميل للكتالوج عند مرحلة \"عميل محتمل\".';

  @override
  String get leadDetailRestore => 'رجّع';

  @override
  String get leadDetailRestored => 'العميل المحتمل رجع';

  @override
  String get leadDetailSuitability => 'الملاءمة';

  @override
  String get leadDetailSuitabilityMarked =>
      'العميل ده اتحكم عليه إنه غير مناسب بعد معاينة يدوية. مخفي من الكتالوج وبرّه بورد المسار.';

  @override
  String get leadDetailSuitabilityPrompt =>
      'عاينت العميل ده ولقيته مش مستاهل؟ علّمه غير مناسب عشان يخرج من كتالوج الشغل.';

  @override
  String get leadDetailRestoreLead => 'رجّع العميل المحتمل';

  @override
  String get leadDetailMarkNotSuitable => 'علّمه غير مناسب';

  @override
  String get leadDetailNotesOptional => 'ملاحظات (اختياري)';

  @override
  String get leadDetailInspectionHint => 'المعاينة أظهرت إيه؟';

  @override
  String get leadDetailMergedAway => 'اتدمج في عميل محتمل تاني';

  @override
  String get leadDetailOpenSurvivor => 'افتح العميل الأصلي';

  @override
  String get leadDetailDuplicates => 'المكرر';

  @override
  String get leadDetailDuplicatesBody =>
      'الكتالوج اتبنى لكل فرع لوحده، فالبراند الواحد ممكن يظهر كذا عميل محتمل. ادمجهم هنا عشان كل الفروع تبقى على سجل واحد.';

  @override
  String get leadDetailAddresses => 'العناوين';

  @override
  String get leadDetailPrimaryAddress => 'العنوان الأساسي';

  @override
  String get leadDetailShippingAddress => 'عنوان الشحن';

  @override
  String leadDetailAddressSaved(String title) {
    return '$title اتحفظ';
  }

  @override
  String leadDetailSaveAddress(String title) {
    return 'احفظ $title';
  }

  @override
  String get leadFieldAddressLine1 => 'العنوان سطر 1';

  @override
  String get leadFieldAddressLine2 => 'العنوان سطر 2';

  @override
  String get leadFieldCity => 'المدينة';

  @override
  String get leadFieldState => 'المحافظة';

  @override
  String get leadFieldCountry => 'الدولة';

  @override
  String get leadFieldPincode => 'الرمز البريدي';

  @override
  String get leadFieldPhone => 'التليفون';

  @override
  String get leadFormEditTitle => 'تعديل عميل محتمل';

  @override
  String get leadFormSaved => 'العميل المحتمل اتحفظ';

  @override
  String get leadFormNewCategory => 'تصنيف جديد';

  @override
  String get leadFormCategoryName => 'اسم التصنيف';

  @override
  String get leadFormAddCategory => 'ضيف تصنيف';

  @override
  String get leadFormLeadName => 'اسم العميل المحتمل *';

  @override
  String get leadFormCompanyName => 'اسم الشركة';

  @override
  String get leadFormPrimaryArea => 'المنطقة الأساسية';

  @override
  String leadFormDuplicateExact(String place) {
    return 'موجود بالفعل في قائمتك: $place';
  }

  @override
  String leadFormDuplicateLikely(String place) {
    return 'يبدو أن هذا مكان لديك بالفعل: $place';
  }

  @override
  String get leadFormDuplicateHint =>
      'الحفظ سينشئ عميلًا محتملًا ثانيًا. إذا كان فرعًا آخر، أضفه إلى العميل الموجود.';

  @override
  String get leadFormAreaEstimated =>
      'تم تقدير المنطقة من موقع الخريطة — راجعها';

  @override
  String get leadFormAreaEstimatedUnsure =>
      'تقدير غير مؤكد للمنطقة من موقع الخريطة — برجاء المراجعة';

  @override
  String get leadFormPriceBand => 'شريحة السعر';

  @override
  String leadFormFitScoreRange(String label) {
    return '$label (0–100)';
  }

  @override
  String get leadFormSaveChanges => 'احفظ التعديلات';

  @override
  String get leadFormCreate => 'اعمل عميل محتمل';

  @override
  String get leadFormCardBrand => 'البراند';

  @override
  String get leadMapsCardTitle => 'المكان على خرائط جوجل';

  @override
  String get leadMapsCardDescription =>
      'الصق رابط المكان الأول. أي بيانات متاحة هتتملى تحت عشان تراجعها.';

  @override
  String get leadMapsFieldLabel => 'رابط خرائط جوجل';

  @override
  String get leadMapsPaste => 'الصق';

  @override
  String get leadMapsGetDetails => 'هات البيانات';

  @override
  String get leadMapsOpen => 'افتح الخريطة';

  @override
  String get leadMapsChecking => 'بنقرأ بيانات المكان…';

  @override
  String get leadMapsStillWorking =>
      'التفاصيل بتاخد وقت أطول. الرابط هيتحفظ؛ اضغط حاول تاني عشان تراجعها.';

  @override
  String get leadMapsDetailsImported =>
      'لقينا شوية بيانات. راجعها وكمّل النموذج تحت.';

  @override
  String get leadMapsLocationImported =>
      'ثبتنا الموقع. راجعه وكمّل النموذج تحت.';

  @override
  String get leadMapsLookupFailed =>
      'ماقدرناش نقرا التفاصيل. الرابط هيتحفظ مع العميل؛ كمّل البيانات تحت.';

  @override
  String get leadMapsUnrecognized =>
      'ده مش باين رابط خرائط جوجل. تقدر تحفظه وتكمّل البيانات تحت.';

  @override
  String get leadMapsLinkKept =>
      'الرابط هيتحفظ مع العميل. كمّل باقي البيانات تحت.';

  @override
  String get leadMapsFoundDetails => 'البيانات اللي لقيناها';

  @override
  String get leadFormCardClassification => 'التصنيف';

  @override
  String get leadFormCardContact => 'بيانات التواصل';

  @override
  String get leadFormTier => 'الفئة';

  @override
  String get leadFormSpecialty => 'سبيشالتي';

  @override
  String get leadFieldMobile => 'الموبايل';

  @override
  String get leadFieldWebsite => 'الموقع';

  @override
  String get leadFieldInstagram => 'إنستجرام';

  @override
  String get leadFieldFacebook => 'فيسبوك';

  @override
  String get leadFormRequired => 'مطلوب';

  @override
  String leadFormAddressRequired(String title) {
    return '$title: لازم تكتب سطر العنوان والمدينة والدولة مع بعض.';
  }

  @override
  String get leadFormScoreRangeError => '0–100';

  @override
  String get leadFormCategoryLabel => 'التصنيف';

  @override
  String get leadsSortTooltip => 'ترتيب';

  @override
  String get leadsSortScore => 'الدرجة';

  @override
  String get leadsSortRating => 'التقييم';

  @override
  String get leadsSortReviews => 'المراجعات';

  @override
  String get leadsSortBranches => 'الفروع';

  @override
  String get leadsSortName => 'الاسم';

  @override
  String get leadsSortNearest => 'الأقرب';

  @override
  String get leadsMapCategories => 'التصنيفات';

  @override
  String get leadActionCall => 'اتصل';

  @override
  String get leadActionInstagram => 'إنستجرام';

  @override
  String get leadActionWebsite => 'الموقع';

  @override
  String get leadActionMap => 'الخريطة';

  @override
  String get leadsMergeConfirmAction => 'ادمج';

  @override
  String get b2bAccountTitle => 'الحساب';

  @override
  String b2bAccountLoadFailed(String error) {
    return 'مش قادر يفتح الحساب.\n$error';
  }

  @override
  String b2bFailed(String error) {
    return 'فشل: $error';
  }

  @override
  String get b2bLogCall => 'سجّل مكالمة';

  @override
  String get b2bLogCallHint => 'اتكلمتوا في إيه؟';

  @override
  String get b2bActivityLogged => 'النشاط اتسجّل';

  @override
  String b2bLogActivityFailed(String error) {
    return 'مش قادر يسجّل النشاط: $error';
  }

  @override
  String get b2bMarkLostTitle => 'علّمه خسران / معلّق';

  @override
  String get b2bReasonHint => 'السبب';

  @override
  String get b2bMarkedLost => 'اتعلّم خسران/معلّق';

  @override
  String get b2bCreateCustomerTitle => 'اعمل عميل للعميل المحتمل';

  @override
  String get b2bCustomerName => 'اسم العميل';

  @override
  String get b2bAddress => 'العنوان';

  @override
  String get b2bContinue => 'كمّل';

  @override
  String get b2bCustomerSetupTitle => 'جهّز العميل';

  @override
  String get b2bLinkExistingCustomer => 'اربط بعميل موجود';

  @override
  String get b2bCreateNewCustomer => 'اعمل عميل جديد';

  @override
  String get b2bSearchExistingCustomer => 'دوّر في العملاء الموجودين';

  @override
  String get b2bNoMatchingCustomers => 'مفيش عملاء مطابقين.';

  @override
  String get b2bLinkAndContinue => 'اربط وكمّل';

  @override
  String get b2bLoadingTerritories => 'بيحمّل المناطق…';

  @override
  String get b2bTerritoriesFailed => 'مش قادر يجيب المناطق';

  @override
  String get b2bOpenLeadPage => 'افتح صفحة العميل المحتمل';

  @override
  String get b2bSectionContact => 'بيانات التواصل';

  @override
  String get b2bSectionInsights => 'تحليلات';

  @override
  String get b2bSectionRecentInvoices => 'آخر الفواتير';

  @override
  String get b2bSectionOpenTodos => 'المهام المفتوحة';

  @override
  String b2bAccountSectionWithCount(String title, int count) {
    return '$title ($count)';
  }

  @override
  String get b2bNone => 'مفيش';

  @override
  String get b2bPredictedNextOrder => 'الطلب الجاي المتوقع';

  @override
  String get b2bAvgOrderCycle => 'متوسط دورة الطلب';

  @override
  String b2bDaysValue(String days) {
    return '$days يوم';
  }

  @override
  String get b2bSendSample => 'ابعت عينة';

  @override
  String get b2bPlaceOrder => 'اعمل طلب';

  @override
  String get b2bOpenAccount => 'افتح حساب الجملة';

  @override
  String get b2bOrderResumeTitle => 'طلب جملة';

  @override
  String get b2bOrderResumeMessage => 'اختار حساب جملة أو كمّل طلب جملة محفوظ.';

  @override
  String get b2bOrderChooseAccount => 'اختار حساب جملة';

  @override
  String get b2bOrderChangeBranch => 'غيّر فرع التوصيل';

  @override
  String get b2bOrderPolicyUnavailable =>
      'سياسة أسعار الجملة المطلوبة مش متاحة. حاول تاني بعد تحميل الأسعار.';

  @override
  String get b2bOrderSetupFailedTitle => 'مش قادر يجهّز طلب الجملة';

  @override
  String get b2bMarkLost => 'علّمه خسران';

  @override
  String get b2bViewPricing => 'شوف الأسعار';

  @override
  String get b2bLabelsSection => 'الليبلات';

  @override
  String b2bLabelsNeedPrinting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محتاجين طباعة',
      one: 'واحد محتاج طباعة',
    );
    return '$_temp0';
  }

  @override
  String get b2bNoLabelsTracked => 'لسه مفيش ليبلات متتابعة للعميل ده.';

  @override
  String get b2bSetUpLabels => 'جهّز الليبلات';

  @override
  String get b2bLoadingLeadProfile => 'بيحمّل ملف العميل المحتمل…';

  @override
  String get b2bLeadProfile => 'ملف العميل المحتمل';

  @override
  String b2bMoreBranches(int count) {
    return '+ $count كمان';
  }

  @override
  String get b2bPipelineTitle => 'مسار الجملة';

  @override
  String get b2bMyFollowUps => 'متابعاتي';

  @override
  String get b2bRefresh => 'تحديث';

  @override
  String get b2bSwitchMode => 'غيّر الوضع';

  @override
  String get b2bGoToPos => 'روح لنقطة البيع (تجزئة)';

  @override
  String get b2bGoToKanban => 'روح لبورد التوصيل';

  @override
  String get b2bActiveTitle => 'العملاء النشطون';

  @override
  String get b2bActivePipelineBoard => 'لوحة المسار';

  @override
  String get b2bActiveSearchHint => 'ابحث باسم العميل أو المنطقة';

  @override
  String get b2bActiveKpiAccounts => 'العملاء النشطين';

  @override
  String b2bActiveKpiBilled(int days) {
    return 'المبيعات آخر $days يوم';
  }

  @override
  String b2bActiveKpiOrders(int days) {
    return 'الطلبات آخر $days يوم';
  }

  @override
  String get b2bActiveKpiOutstanding => 'المتبقي للتحصيل';

  @override
  String get b2bActiveKpiReorderDue => 'موعد إعادة الطلب';

  @override
  String get b2bActiveKpiNeedsAttention => 'يحتاج متابعة';

  @override
  String b2bActiveVsPrevious(int days) {
    return 'مقارنة بالـ $days يوم السابقة';
  }

  @override
  String get b2bActiveReorderOverdue => 'تأخر في إعادة الطلب';

  @override
  String get b2bActiveReorderDueSoon => 'قرب موعد الطلب';

  @override
  String b2bActiveReorderOk(String date) {
    return 'الطلب القادم تقريبًا $date';
  }

  @override
  String b2bActiveLastOrder(String date, String ago) {
    return 'آخر طلب: $date ($ago)';
  }

  @override
  String b2bActiveDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count يوم',
      one: 'امبارح',
      zero: 'النهارده',
    );
    return '$_temp0';
  }

  @override
  String get b2bActiveNoOrders => 'لا توجد طلبات بعد';

  @override
  String b2bActiveFigPeriod(int days) {
    return 'آخر $days يوم';
  }

  @override
  String b2bActiveFigOrders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب',
      few: '$count طلبات',
      two: 'طلبان',
      one: 'طلب واحد',
      zero: 'لا طلبات',
    );
    return '$_temp0';
  }

  @override
  String get b2bActiveFigLifetime => 'الإجمالي';

  @override
  String get b2bActiveFigAvgOrder => 'متوسط الطلب';

  @override
  String get b2bActiveFigOutstanding => 'المتبقي';

  @override
  String b2bActiveOldestUnpaid(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أقدم فاتورة غير مدفوعة من $count يوم',
      few: 'أقدم فاتورة غير مدفوعة من $count أيام',
      two: 'أقدم فاتورة غير مدفوعة من يومين',
      one: 'أقدم فاتورة غير مدفوعة من يوم',
      zero: 'أقدم فاتورة غير مدفوعة اليوم',
    );
    return '$_temp0';
  }

  @override
  String b2bActiveNextAction(String action) {
    return 'الخطوة الجاية: $action';
  }

  @override
  String b2bActiveNextActionOn(String action, String date) {
    return 'الخطوة الجاية: $action يوم $date';
  }

  @override
  String b2bActiveLastNote(String note) {
    return 'آخر ملاحظة: $note';
  }

  @override
  String get b2bActiveAlertOldUnpaid => 'فاتورة قديمة غير مدفوعة';

  @override
  String get b2bActiveAlertLabels => 'تنبيه الليبلات';

  @override
  String get b2bActiveAlertNoCustomer => 'غير مربوط بعميل';

  @override
  String get b2bActiveCall => 'اتصال';

  @override
  String get b2bActiveEmptyTitle => 'لا يوجد عملاء نشطين بعد';

  @override
  String get b2bActiveEmptyBody =>
      'العملاء اللي بتنقلهم لمرحلة \"نشط\" في لوحة المسار هيظهروا هنا.';

  @override
  String get b2bActiveNoMatches => 'لا يوجد عملاء مطابقون للبحث';

  @override
  String get b2bActiveClearFilters => 'مسح التصفية';

  @override
  String b2bActivePercent(String value) {
    return '$value%';
  }

  @override
  String b2bActivePlace(String area, String customer) {
    return '$area · $customer';
  }

  @override
  String get b2bNewLead => 'عميل محتمل جديد';

  @override
  String b2bMovedToStage(String title, String stage) {
    return '\"$title\" اتنقل لـ $stage';
  }

  @override
  String b2bAdvanceStageFailed(String error) {
    return 'مش قادر ينقل المرحلة: $error';
  }

  @override
  String get b2bFollowUpReminder => 'تذكير متابعة';

  @override
  String b2bFollowUpPrompt(String stage) {
    return 'هتتابع إمتى بعد النقل لـ \"$stage\"؟';
  }

  @override
  String get b2bSkip => 'تخطّي';

  @override
  String get b2bSetReminder => 'اضبط التذكير';

  @override
  String get b2bLostReasonHint => 'ليه ده خسران / معلّق؟';

  @override
  String b2bPipelineLoadFailed(String error) {
    return 'مش قادر يفتح المسار.\n$error';
  }

  @override
  String get b2bTodayTitle => 'النهارده';

  @override
  String b2bTodayLoadFailed(String error) {
    return 'مش قادر يجيب المتابعات.\n$error';
  }

  @override
  String get b2bNoFollowUpsToday => 'مفيش متابعات النهارده';

  @override
  String get b2bNoReordersDue => 'مفيش طلبات إعادة مستحقة';

  @override
  String get b2bFollowUpDone => 'المتابعة اتعلّمت خلصت';

  @override
  String b2bFollowUpFailed(String error) {
    return 'مش قادر يخلّص المتابعة: $error';
  }

  @override
  String get b2bDone => 'تمام';

  @override
  String b2bOverdueSuffix(String date) {
    return '$date · متأخرة';
  }

  @override
  String b2bAvgBasket(String amount) {
    return 'المتوسط: $amount';
  }

  @override
  String b2bScoreLabel(int score) {
    return 'الدرجة $score';
  }

  @override
  String get b2bNoAccounts => 'مفيش حسابات';

  @override
  String b2bLabelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ليبل',
      one: 'ليبل واحد',
    );
    return '$_temp0';
  }

  @override
  String b2bLastOrder(String date) {
    return 'آخر طلب: $date';
  }

  @override
  String b2bNextOrder(String date) {
    return 'الجاي: $date';
  }

  @override
  String get b2bCardLead => 'عميل محتمل';

  @override
  String get b2bCardOpportunity => 'فرصة';

  @override
  String b2bLabelsNeedPrintingTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ليبل محتاجين طباعة',
      one: 'ليبل واحد محتاج طباعة',
    );
    return '$_temp0';
  }

  @override
  String get pricingTitle => 'قوايم الأسعار';

  @override
  String get pricingCustomerLookup => 'بحث أسعار العميل';

  @override
  String get pricingRefresh => 'تحديث';

  @override
  String get pricingNewPriceList => 'قايمة أسعار جديدة';

  @override
  String get pricingNoPriceLists => 'لسه مفيش قوايم أسعار.';

  @override
  String get pricingNameField => 'الاسم';

  @override
  String get pricingCurrencyField => 'العملة';

  @override
  String get pricingCreate => 'اعمل';

  @override
  String pricingCreated(String name) {
    return 'اتعمل \"$name\"';
  }

  @override
  String pricingCreateFailed(String error) {
    return 'مش قادر يعمل قايمة أسعار: $error';
  }

  @override
  String get pricingDefaultBadge => 'الافتراضية';

  @override
  String pricingLoadFailed(String error) {
    return 'مش قادر يجيب قوايم الأسعار.\n$error';
  }

  @override
  String pricingDetailLoadFailed(String name, String error) {
    return 'مش قادر يفتح \"$name\".\n$error';
  }

  @override
  String pricingSetRateTitle(String category) {
    return 'حدد سعر $category';
  }

  @override
  String pricingRateUpdated(String category) {
    return 'سعر $category اتحدّث';
  }

  @override
  String pricingRateSet(String category) {
    return 'سعر $category اتحدد';
  }

  @override
  String get pricingAllCategoriesHaveRows => 'كل التصنيفات ليها سطر بالفعل.';

  @override
  String pricingItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أصناف',
      one: 'صنف واحد',
    );
    return '$_temp0';
  }

  @override
  String pricingOverrideTitle(String item) {
    return 'استثناء $item';
  }

  @override
  String get pricingOverrideUpdated => 'الاستثناء اتحدّث';

  @override
  String get pricingRemoveOverrideTitle => 'تشيل الاستثناء؟';

  @override
  String pricingRemoveOverrideBody(String item) {
    return '$item هيرجع لسعر تصنيفه.';
  }

  @override
  String get pricingRemove => 'شيل';

  @override
  String get pricingOverrideRemoved => 'الاستثناء اتشال';

  @override
  String get pricingAddOverride => 'ضيف استثناء';

  @override
  String get pricingItemCode => 'كود الصنف';

  @override
  String get pricingRateField => 'السعر';

  @override
  String get pricingOverrideAdded => 'الاستثناء اتضاف';

  @override
  String get pricingUnassignTitle => 'تشيل ربط العميل؟';

  @override
  String pricingUnassignBody(String customer) {
    return '$customer هيرجع لافتراضي مجموعته.';
  }

  @override
  String get pricingUnassign => 'شيل الربط';

  @override
  String get pricingCustomerUnassigned => 'ربط العميل اتشال';

  @override
  String pricingFailed(String error) {
    return 'فشل: $error';
  }

  @override
  String get pricingCategoryPrices => 'أسعار التصنيفات';

  @override
  String get pricingAddCategory => 'ضيف تصنيف';

  @override
  String get pricingNoCategoryRates => 'مفيش أسعار تصنيفات متحددة.';

  @override
  String pricingEditRateTooltip(String category) {
    return 'عدّل سعر $category';
  }

  @override
  String get pricingPerFlavorOverrides => 'استثناءات لكل نكهة';

  @override
  String pricingOverrideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count استثناءات',
      one: 'استثناء واحد',
    );
    return '$_temp0';
  }

  @override
  String get pricingNoOverrides => 'مفيش استثناءات لأصناف.';

  @override
  String get pricingEditOverride => 'عدّل الاستثناء';

  @override
  String get pricingRemoveOverride => 'شيل الاستثناء';

  @override
  String get pricingAssignedCustomers => 'العملاء المربوطين';

  @override
  String pricingCustomerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عملاء',
      one: 'عميل واحد',
    );
    return '$_temp0';
  }

  @override
  String get pricingNoCustomers => 'مفيش عملاء بيستخدموا القايمة دي.';

  @override
  String pricingViaGroup(String group) {
    return 'عن طريق مجموعة $group';
  }

  @override
  String get pricingDirectAssignment => 'ربط مباشر';

  @override
  String get customerPricingTitle => 'أسعار العميل';

  @override
  String get customerPricingSearchHint => 'دوّر على عملاء الشركات…';

  @override
  String customerPricingSearchFailed(String error) {
    return 'البحث فشل.\n$error';
  }

  @override
  String get customerPricingNoCustomers => 'مفيش عملاء.';

  @override
  String customerPricingLoadFailed(String customer, String error) {
    return 'مش قادر يجيب أسعار \"$customer\".\n$error';
  }

  @override
  String get customerPricingEffective => 'الأسعار السارية';

  @override
  String get customerPricingNoResolved => 'مفيش أسعار محسوبة.';

  @override
  String customerPricingSource(String group, String source) {
    return '$group · المصدر: $source';
  }

  @override
  String get pricingNoCategoryRatesShort => 'مفيش أسعار تصنيفات متحددة';

  @override
  String pricingCardSummary(String customers, String currency) {
    return '$customers · $currency';
  }

  @override
  String get pricingDisabledSuffix => ' · متوقفة';

  @override
  String customerPricingGroupLine(
    String group,
    String priceList,
    String assignment,
  ) {
    return 'المجموعة: $group\nقايمة الأسعار: $priceList ($assignment)';
  }

  @override
  String get pricingNoneValue => '(مفيش)';

  @override
  String get pricingDash => '—';

  @override
  String get journeyToday => 'النهارده';

  @override
  String get journeyYesterday => 'امبارح';

  @override
  String get journeyTomorrow => 'بكره';

  @override
  String journeyDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count أيام',
      one: 'من يوم',
    );
    return '$_temp0';
  }

  @override
  String journeyWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count أسابيع',
      one: 'من أسبوع',
    );
    return '$_temp0';
  }

  @override
  String journeyMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count شهور',
      one: 'من شهر',
    );
    return '$_temp0';
  }

  @override
  String journeyOverdueByDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'متأخر بـ $count أيام',
      one: 'متأخر بيوم',
    );
    return '$_temp0';
  }

  @override
  String get journeyOverdue => 'متأخر';

  @override
  String journeyInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بعد $count أيام',
      one: 'بعد يوم',
    );
    return '$_temp0';
  }

  @override
  String journeyInMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بعد $count شهور',
      one: 'بعد شهر',
    );
    return '$_temp0';
  }

  @override
  String get journeyTypeVisit => 'زيارة';

  @override
  String get journeyTypeCall => 'مكالمة';

  @override
  String get journeyTypeWhatsapp => 'واتساب';

  @override
  String get journeyTypeSampleDrop => 'تسليم عينة';

  @override
  String get journeyTypeMeeting => 'اجتماع';

  @override
  String get journeyTypeEmail => 'إيميل';

  @override
  String get journeyTypeOther => 'غير كده';

  @override
  String get journeyOutcomeInterested => 'مهتم';

  @override
  String get journeyOutcomeNeedsFollowUp => 'محتاج متابعة';

  @override
  String get journeyOutcomeSampleRequested => 'طلب عينة';

  @override
  String get journeyOutcomeOrderPlaced => 'عمل طلب';

  @override
  String get journeyOutcomeNotNow => 'مش دلوقتي';

  @override
  String get journeyOutcomeRejected => 'مرفوض';

  @override
  String get journeyEditorEditTitle => 'تعديل ملاحظة الزيارة';

  @override
  String get journeyEditorNewTitle => 'سجّل زيارة أو مكالمة';

  @override
  String get journeyEditorSubtitle =>
      'اللي حصل، ومين اللي اتكلمت معاه، وإيه الخطوة الجاية.';

  @override
  String get journeyEditorDate => 'التاريخ';

  @override
  String get journeyEditorType => 'النوع';

  @override
  String get journeyEditorNote => 'الملاحظة';

  @override
  String get journeyEditorNoteHint => 'عجبهم الماتشا وسألوا عن أسعار الجملة…';

  @override
  String get journeyEditorWhoSpoke => 'مين اللي اتكلمت معاه';

  @override
  String get journeyEditorWhoHint => 'دوس على اللي قابلته، أو ضيف حد جديد.';

  @override
  String get journeyEditorNewPerson => 'شخص جديد';

  @override
  String journeyEditorContactFailed(String error) {
    return 'مش قادر يحفظ جهة الاتصال: $error';
  }

  @override
  String get journeyEditorPerson => 'الشخص';

  @override
  String get journeyEditorPersonHint => 'مصطفى';

  @override
  String get journeyEditorRole => 'الوظيفة';

  @override
  String get journeyEditorRoleHint => 'مدير الفرع';

  @override
  String get journeyEditorTheirPhone => 'تليفونه';

  @override
  String get journeyEditorOutcome => 'النتيجة';

  @override
  String get journeyEditorNextAction => 'الخطوة الجاية';

  @override
  String get journeyEditorNextActionHelp =>
      'التاريخ هنا كمان بيظبط تذكير المتابعة على الحساب ده.';

  @override
  String get journeyEditorWhatToDo => 'المفروض تعمل إيه';

  @override
  String get journeyEditorWhatToDoHint =>
      'كلّم المدير عشان يأكد الطلب التجريبي';

  @override
  String get journeyEditorWhen => 'إمتى';

  @override
  String get journeyEditorNoReminder => 'من غير تذكير';

  @override
  String get journeyEditorLogIt => 'سجّلها';

  @override
  String get journeyEditorPickDate => 'اختار تاريخ';

  @override
  String get journeyEditorClear => 'امسح';

  @override
  String get journeySectionTitle => 'سجل الزيارات';

  @override
  String journeyOpenTasksTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهام مفتوحة',
      two: 'مهمتين مفتوحين',
      one: 'مهمة واحدة مفتوحة',
    );
    return '$_temp0';
  }

  @override
  String get journeyNoOpenTasks => 'مفيش مهام مفتوحة';

  @override
  String get journeyLatestLogsTitle => 'آخر السجلات';

  @override
  String journeyShowAllLogs(int count) {
    return 'اعرض كل السجلات ($count)';
  }

  @override
  String get journeyShowLatestLogs => 'اعرض الأحدث بس';

  @override
  String get journeyLogVisit => 'سجّل زيارة';

  @override
  String get journeyNoteAdded => 'الملاحظة اتضافت';

  @override
  String get journeyNoteUpdated => 'الملاحظة اتحدّثت';

  @override
  String get journeyNoteDeleted => 'الملاحظة اتمسحت';

  @override
  String get journeyDeleteTitle => 'تمسح الملاحظة دي؟';

  @override
  String get journeyDeleteBody => 'سجل الزيارة هيتشال للكل. مفيش رجوع بعد كده.';

  @override
  String journeyFailed(String error) {
    return 'فشل: $error';
  }

  @override
  String get journeyEdit => 'تعديل';

  @override
  String journeyLoggedBy(String user) {
    return 'سجّلها $user';
  }

  @override
  String get journeyEmptyTitle => 'لسه مفيش زيارات متسجلة.';

  @override
  String get journeyEmptyBody =>
      'سجّل اللي اتقال ومين قاله وإمتى تتابع — والخطوة الجاية بتاريخ بتظبط كمان تذكير الحساب ده.';

  @override
  String get journeyLoadFailed => 'مش قادر يجيب سجل الزيارات.';

  @override
  String get journeyMarkDone => 'خلصتها';

  @override
  String get journeyMarkNotDone => 'رجّعها لسه';

  @override
  String get journeyDoneLabel => 'خلصت';

  @override
  String journeyDoneOn(String date) {
    return 'خلصت $date';
  }

  @override
  String journeyDoneByOn(String date, String user) {
    return 'خلصت $date · $user';
  }

  @override
  String get journeyActionMarkedDone => 'الخطوة اتقفلت';

  @override
  String get journeyActionReopened => 'الخطوة رجعت مفتوحة';

  @override
  String get journeyCalendarTitle => 'تقويم المتابعات';

  @override
  String get journeyCalendarPreviousMonth => 'الشهر اللي فات';

  @override
  String get journeyCalendarNextMonth => 'الشهر الجاي';

  @override
  String get journeyCalendarScopeMine => 'بتاعتي';

  @override
  String get journeyCalendarScopeAll => 'الكل';

  @override
  String get journeyCalendarShowDone => 'ورّي اللي خلص';

  @override
  String journeyCalendarPendingCount(int count) {
    return 'مفتوحة $count';
  }

  @override
  String journeyCalendarOverdueCount(int count) {
    return 'متأخرة $count';
  }

  @override
  String journeyCalendarDoneCount(int count) {
    return 'خلصت $count';
  }

  @override
  String journeyCalendarDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مطلوبة',
      one: 'مطلوبة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get journeyCalendarNothingOnDay => 'مفيش حاجة مطلوبة اليوم ده.';

  @override
  String get journeyCalendarEmptyMonth => 'مفيش حاجة مطلوبة الشهر ده.';

  @override
  String get journeyCalendarLoadFailed => 'مش قادر يجيب التقويم.';

  @override
  String get journeyCalendarSourceFollowup => 'تذكير';

  @override
  String get journeyCalendarNoAction => 'مفيش خطوة متكتوبة';

  @override
  String get errorConsoleCopyError => 'انسخ الخطأ';

  @override
  String get errorConsoleCopied => 'تفاصيل الخطأ اتنسخت';

  @override
  String get errorConsoleSummary => 'الملخص';

  @override
  String get errorConsoleFatal => 'قاتل';

  @override
  String get errorConsoleYes => 'أيوه';

  @override
  String get errorConsoleNo => 'لأ';

  @override
  String get errorConsoleOccurrences => 'عدد المرات';

  @override
  String get errorConsoleDetails => 'التفاصيل';

  @override
  String get errorConsoleStackTrace => 'تتبّع الخطأ';

  @override
  String get menuInstapayReconciliation => 'تسوية إنستاباي';

  @override
  String get instapayTitle => 'تسوية إنستاباي';

  @override
  String get instapayNoOrders => 'مفيش طلبات مستنية تأكيد إنستاباي';

  @override
  String get instapayCourierRequired => 'لازم مندوب عشان تحصيل الكاش';

  @override
  String get instapayConvertedToCod => 'اتحوّل لدفع عند الاستلام';

  @override
  String get instapayCollectedCashInstead => 'اتحصّل كاش بدالها';

  @override
  String get instapayConfirmReceived => 'أكّد الاستلام';

  @override
  String get instapayPaymentConfirmed => 'الدفع اتأكد';

  @override
  String get instapayBankReference => 'رقم مرجع البنك';

  @override
  String get kanbanMoveAction => 'انقل';

  @override
  String get kanbanDeliveryPartnerField => 'شريك التوصيل';

  @override
  String get kanbanSetDeliveryIncome => 'حدد دخل التوصيل';

  @override
  String get kanbanDeliveryIncomeField => 'دخل التوصيل';

  @override
  String get kanbanInvalidAmount => 'اكتب مبلغ صحيح مش بالسالب';

  @override
  String get kanbanUpdatingDeliveryIncome => 'بيحدّث دخل التوصيل…';

  @override
  String kanbanErrorWithMessage(String error) {
    return 'خطأ: $error';
  }

  @override
  String get posShowHeaderTooltip => 'وريني الهيدر';

  @override
  String get posCartDeliveryAmountField => 'مبلغ التوصيل';

  @override
  String get posCartResetToDefault => 'رجّع الافتراضي';

  @override
  String get posCartSetAction => 'حدد';

  @override
  String get posCartPromoCode => 'كود الخصم';

  @override
  String get posCartPromoCodeHint => 'مثلاً EGY2026';

  @override
  String get reportsColumnSegment => 'الشريحة';

  @override
  String get reportsColumnRecencyDays => 'آخر شراء (يوم)';

  @override
  String get reportsColumnFrequency => 'التكرار';

  @override
  String get reportsColumnAov => 'متوسط الطلب';

  @override
  String get tripsOneBranchOnly =>
      'اختار فواتير من فرع واحد بس عشان تعمل رحلة.';

  @override
  String get webPushOnlyInWebApp => 'إشعارات الويب متاحة في نسخة الويب بس.';

  @override
  String get webPushEnabled => 'إشعارات الويب مفعّلة على الجهاز ده.';

  @override
  String get webPushDisabledForEnv => 'إشعارات الويب مقفولة في البيئة دي.';

  @override
  String get webPushNotConfigured => 'إشعارات الويب مش متظبطة في البيئة دي.';

  @override
  String get webPushUnsupportedPrompt =>
      'المتصفح ده مش بيدعم طلب إذن الإشعارات.';

  @override
  String get webPushPermissionRequired =>
      'دوس على تفعيل الإشعارات عشان تسمح بإشعارات الويب على الجهاز ده.';

  @override
  String get webPushPermissionDenied => 'إذن الإشعارات اترفض.';

  @override
  String get webPushNoToken =>
      'لسه مفيش توكن لإشعارات الويب. جرّب تاني بعد ما تقفل التطبيق وتفتحه.';

  @override
  String get webPushTokenReady => 'توكن إشعارات الويب جاهز للتسجيل.';

  @override
  String get webPushEnableFailed =>
      'مش قادر يفعّل الإشعارات. اقفل التطبيق من الشاشة الرئيسية وافتحه وجرّب تاني.';

  @override
  String get b2bCustomerLabelsTooltip => 'ليبلات العملاء';

  @override
  String get b2bFollowUpsHeader => 'المتابعات';

  @override
  String get b2bReorderDueHeader => 'طلبات إعادة مستحقة';

  @override
  String get expensesEmptyManagerHint =>
      'اعمل مصروف جديد عشان تسجّل مصاريف التشغيل.';

  @override
  String get expensesEmptyStaffHint => 'قدّم مصروف جديد والمدير هيراجعه.';

  @override
  String get expenseSourceCash => 'كاش';

  @override
  String get expenseSourceBank => 'بنك';

  @override
  String get expenseSourceMobileWallet => 'محفظة موبايل';

  @override
  String get expenseSourcePosProfile => 'بروفايل نقطة البيع';

  @override
  String get expenseSourceAccount => 'حساب';

  @override
  String get instapayConvertFailed => 'مش قادر يحوّل الطلب لكاش';

  @override
  String get instapayConfirmFailed => 'مش قادر يأكد الدفع';

  @override
  String get instapayConfirmSheetTitle => 'أكّد استلام إنستاباي';

  @override
  String get instapayAwaitingBadge => 'في انتظار إنستاباي';

  @override
  String get inventoryCountSubmitting => 'بيقدّم التسوية';

  @override
  String get inventoryCountSubmitError => 'خطأ في تقديم التسوية';

  @override
  String get kanbanExitSelection => 'اخرج من التحديد';

  @override
  String get kanbanSelectOrders => 'اختار طلبات';

  @override
  String get kanbanMoveOrderTitle => 'نقل الطلب';

  @override
  String get kanbanCreateFailedFallback => 'الإنشاء فشل';

  @override
  String get kanbanDeliveryIncomeHelp =>
      'اكتب دخل توصيل مخصص للطلب ده. سيبها فاضية عشان ترجع لافتراضي المنطقة. ده هيعمل تعديل للطلب.';

  @override
  String get kanbanCannotAmend => 'الطلب ده مينفعش يتعدّل';

  @override
  String get kanbanDeliveryIncomeReset => 'دخل التوصيل رجع لافتراضي المنطقة';

  @override
  String get kanbanAmendmentFailed => 'التعديل فشل';

  @override
  String get kanbanShippingNotUpdated =>
      'تكلفة الشحن ماتحدّثتش. صلّح منطقة العنوان.';

  @override
  String get leadsNotSuitableBadge => 'غير مناسب';

  @override
  String get bundleSelectionTitle => 'اختيار الباقة';

  @override
  String get bundleUpdateAction => 'حدّث الباقة';

  @override
  String get bundleAddToCartAction => 'ضيف للسلة';

  @override
  String get bundleSelectFromGroups => 'اختار أصناف من كل مجموعة تحت:';

  @override
  String get bundleCatalogDriftWarning =>
      'خيارات الباقة يمكن تكون اتغيّرت من ساعة ما الطلب اتعمل. راجع اختياراتك وأكّدها.';

  @override
  String get bundleNoItemsInGroup => 'مفيش أصناف متاحة في المجموعة دي';

  @override
  String get bundleUnknownItem => 'صنف غير معروف';

  @override
  String get bundleUnknownBundle => 'باقة غير معروفة';

  @override
  String get bundleNoItemGroups => 'مفيش مجموعات أصناف';

  @override
  String get bundleNoItemGroupsBody => 'الباقة دي مفيهاش مجموعات أصناف متاحة';

  @override
  String get posCartPromoDiscount => 'خصم الكود';

  @override
  String get posCartFreeDelivery => 'توصيل مجاني';

  @override
  String get posCartDeliveryAmountHelp =>
      'اكتب مبلغ توصيل مخصص. سيبها فاضية عشان ترجع لافتراضي المنطقة.';

  @override
  String get posCartBundleLoadFailed =>
      'محتويات الباقة مش قادرة تتحمّل. عدّل الباقة واختار الأصناف تاني قبل ما تبعت.';

  @override
  String get posCartPromoApplied => 'اتطبق';

  @override
  String get posCartPromoNotEligible => 'مش مؤهل';

  @override
  String get posSalesPartnerFallback => 'شريك المبيعات';

  @override
  String get reportsColumnBomCost => 'تكلفة قائمة المواد';

  @override
  String get reportsColumnTimesInBundle => 'مرات في الباقات';

  @override
  String get settingsIosWebPushTitle => 'إشعارات الويب على الآيفون';

  @override
  String get settingsIosWebPushBody =>
      'نزّل التطبيق على الشاشة الرئيسية للآيفون، وبعدين دوس على تفعيل الإشعارات عشان توصلك التنبيهات.';

  @override
  String get settingsEnablingNotifications => 'بيفعّل الإشعارات...';

  @override
  String get settingsEnableNotifications => 'فعّل الإشعارات';

  @override
  String get settingsNotificationAlerts => 'تنبيهات الإشعارات';

  @override
  String get settingsAlarmsMutedAll => 'كل تنبيهات الطلبات مكتومة حاليًا';

  @override
  String get settingsAlarmsActive => 'تنبيهات الطلبات شغّالة';

  @override
  String get settingsAlarmsEnabledDevice =>
      'تنبيهات الإشعارات اتفعّلت على الجهاز ده';

  @override
  String get settingsAlarmsMutedDevice =>
      'تنبيهات الإشعارات اتكتمت على الجهاز ده';

  @override
  String get settingsChooseAlarmSound =>
      'اختار صوت تنبيه الموظفين جوه التطبيق:';

  @override
  String get settingsAlarmSoundNote =>
      'الصوت ده بيتستخدم لتنبيه الموظفين جوه التطبيق. إشعارات الطلبات والتطبيق مقفول بتستخدم نغمة الطلبات.';

  @override
  String get settingsProfileLoadFailed => 'مش قادر يجيب ملف المستخدم';

  @override
  String get shiftUnknownUser => 'مستخدم غير معروف';

  @override
  String kanbanDeliveryIncomeUpdated(String amount) {
    return 'دخل التوصيل اتحدّث لـ $amount';
  }

  @override
  String kanbanAddressNoTerritory(String city) {
    return 'العنوان اتحفظ، بس \"$city\" مش مطابق لأي منطقة — تكلفة الشحن ماتحدّثتش. صلّح منطقة العنوان.';
  }

  @override
  String get reportsColumnComponent => 'المكوّن';

  @override
  String get leadContactsTitle => 'جهات الاتصال';

  @override
  String leadContactsTitleCount(int count) {
    return 'جهات الاتصال ($count)';
  }

  @override
  String get leadContactsEmpty =>
      'لا يوجد أشخاص مسجلون بعد. أضف المالك أو المدير أو أي شخص تقابله في الزيارة.';

  @override
  String get leadContactsAdd => 'إضافة جهة اتصال';

  @override
  String get leadContactsEdit => 'تعديل جهة الاتصال';

  @override
  String get leadContactsRemove => 'حذف';

  @override
  String get leadContactsRemoveTitle => 'حذف جهة الاتصال؟';

  @override
  String leadContactsRemoveBody(String name) {
    return 'حذف $name من هذا العميل المحتمل؟';
  }

  @override
  String get leadContactsMakePrimary => 'تعيين كجهة أساسية';

  @override
  String get leadContactsPrimary => 'جهة الاتصال الأساسية';

  @override
  String get leadContactsPrimaryHint => 'الشخص الذي يتم الاتصال به أولاً.';

  @override
  String get leadContactsSaved => 'تم تحديث جهات الاتصال';

  @override
  String get leadContactsName => 'الاسم';

  @override
  String get leadContactsRole => 'الوظيفة / المسمى';

  @override
  String get leadContactsRoleHint => 'مالك، مدير، باريستا…';

  @override
  String get leadContactsPhone => 'الهاتف';

  @override
  String get leadContactsEmail => 'البريد الإلكتروني';

  @override
  String get leadContactsNotes => 'ملاحظات';

  @override
  String get leadContactsPickFromPhone => 'اختيار من جهات اتصال الهاتف';

  @override
  String get leadContactsNeedNameOrPhone => 'أضف اسمًا أو رقم هاتف.';

  @override
  String get leadContactRoleOwner => 'مالك';

  @override
  String get leadContactRoleManager => 'مدير';

  @override
  String get leadContactRoleShiftManager => 'مدير وردية';

  @override
  String get leadContactRoleBarista => 'باريستا';

  @override
  String get leadContactRolePurchasing => 'مشتريات';

  @override
  String get leadContactRoleAccountant => 'محاسب';

  @override
  String get visitPlannerTitle => 'مخطط الزيارات';

  @override
  String get visitPlanDay => 'خطّط يوماً';

  @override
  String get visitBuildDay => 'تكوين يوم';

  @override
  String get visitRouteTitle => 'المسار';

  @override
  String visitRouteFallbackTitle(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString محطة',
      few: '$countString محطات',
      two: 'محطتان',
      one: 'محطة واحدة',
      zero: 'مسار فارغ',
    );
    return '$_temp0';
  }

  @override
  String get visitScopeMine => 'مساراتي';

  @override
  String get visitScopeAll => 'مسارات الجميع';

  @override
  String get visitNoRoutesOnDay => 'لا يوجد مسار مخطط لهذا اليوم.';

  @override
  String get visitPlansLoadFailed =>
      'تعذّر تحميل المسارات. اسحب للأسفل للمحاولة مرة أخرى.';

  @override
  String visitStopsCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString محطة',
      few: '$countString محطات',
      two: 'محطتان',
      one: 'محطة واحدة',
      zero: 'بدون محطات',
    );
    return '$_temp0';
  }

  @override
  String visitDistanceKm(String km) {
    return '$km كم';
  }

  @override
  String visitDurationMinutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String visitDayTotal(String duration) {
    return 'اليوم $duration';
  }

  @override
  String visitLeg(String km, int minutes) {
    return '$km كم · $minutes دقيقة';
  }

  @override
  String get visitNextStop => 'المحطة التالية';

  @override
  String get visitGo => 'انطلق';

  @override
  String get visitNavigate => 'التوجيه';

  @override
  String get visitCall => 'اتصال';

  @override
  String get visitCheckIn => 'تسجيل الزيارة';

  @override
  String get visitSkip => 'تخطّي';

  @override
  String get visitReopen => 'إعادة فتح';

  @override
  String get visitPin => 'تثبيت في هذا الترتيب';

  @override
  String get visitUnpin => 'إلغاء التثبيت';

  @override
  String get visitRemoveStop => 'إزالة من المسار';

  @override
  String get visitOptimise => 'تحسين المسار';

  @override
  String get visitOptimiseFromHere => 'التحسين من موقعي الحالي';

  @override
  String get visitNavigateWholeRoute => 'فتح المسار كاملاً في الخرائط';

  @override
  String get visitDeleteRoute => 'حذف المسار';

  @override
  String get visitDeleteRouteConfirm =>
      'سيُحذف المسار. الزيارات المسجّلة تبقى في سجل الرحلة.';

  @override
  String get visitNoStops => 'لا توجد محطات في هذا المسار بعد.';

  @override
  String get visitLocationUnavailable => 'تعذّر تحديد موقعك.';

  @override
  String visitRouteTruncated(int handed, int total) {
    return 'الخرائط تقبل $handed من $total محطة دفعة واحدة. استخدم التوجيه محطة بمحطة لبقية المسار.';
  }

  @override
  String get visitOutcome => 'النتيجة';

  @override
  String get visitLogJourneyNote => 'تسجيل ملاحظة رحلة';

  @override
  String get visitLogJourneyNoteHint =>
      'تُسجّل الزيارة في سجل العميل المحتمل وتحدّد تذكير المتابعة.';

  @override
  String get visitNoteWhatHappened => 'ماذا حدث';

  @override
  String get visitNextAction => 'الإجراء التالي';

  @override
  String get visitNextActionDate => 'اختر تاريخاً';

  @override
  String get visitMarkVisited => 'تمت الزيارة';

  @override
  String get visitSuggestDay => 'خطّط يومي';

  @override
  String get visitMaxStops => 'أقصى عدد محطات';

  @override
  String get visitDayHours => 'اليوم (ساعات)';

  @override
  String get visitStartFromMyLocation => 'البدء من موقعي';

  @override
  String get visitStartFromMyLocationHint =>
      'عند الإيقاف يخطّط حول أفضل تجمّع في أي مكان.';

  @override
  String get visitIncludeCustomers => 'تضمين العملاء الحاليين';

  @override
  String get visitIncludeCustomersHint =>
      'زيارات متابعة للحسابات النشطة في الطريق.';

  @override
  String get visitCandidateDoors => 'أماكن تستحق الزيارة';

  @override
  String get visitClearSelection => 'مسح';

  @override
  String get visitNoCandidates => 'لا توجد نتائج مطابقة لهذه الفلاتر.';

  @override
  String get visitTargetsLoadFailed => 'تعذّر تحميل المرشحين.';

  @override
  String visitProposedDay(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString محطة مقترحة',
      few: '$countString محطات مقترحة',
      two: 'محطتان مقترحتان',
      one: 'محطة واحدة مقترحة',
    );
    return '$_temp0';
  }

  @override
  String visitConsidered(int count) {
    return 'تمت دراسة $count مكان';
  }

  @override
  String visitDroppedForTime(int count) {
    return 'تم استبعاد $count لتناسب اليوم';
  }

  @override
  String visitSelectedCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString محطة محدّدة',
      few: '$countString محطات محدّدة',
      two: 'محطتان محدّدتان',
      one: 'محطة واحدة محدّدة',
    );
    return '$_temp0';
  }

  @override
  String get visitCreateRoute => 'إنشاء المسار';

  @override
  String get visitEngineRoadExplained =>
      'المسافات والأزمنة مأخوذة من شبكة الطرق.';

  @override
  String get visitEngineEstimateExplained =>
      'المسافات تقديرية بخط مستقيم معدّلة للقيادة داخل المدينة. ترتيب الزيارات محسوب بدقة، أما الدقائق فتقريبية.';

  @override
  String get visitEngineRecheck => 'إعادة الفحص';

  @override
  String get materialsSectionTitle => 'قائمة الأسعار والمواد';

  @override
  String get materialsSendCta => 'إرسال قائمة الأسعار';

  @override
  String get materialsSendTitle => 'إرسال المواد';

  @override
  String get materialsRecipientLabel => 'إرسال إلى';

  @override
  String get materialsNoRecipient =>
      'لا توجد جهات اتصال على هذا العميل. أضف واحدة أولاً، أو أرسل واختر المحادثة داخل واتساب.';

  @override
  String get materialsPickLabel => 'المواد المرسلة';

  @override
  String get materialsPreparing => 'قيد التجهيز';

  @override
  String get materialsMessageLabel => 'الرسالة';

  @override
  String get materialsSending => 'جارٍ إنشاء الرابط…';

  @override
  String get materialsLinkReady => 'تم إنشاء الرابط وتسجيله على العميل.';

  @override
  String get materialsCopyLink => 'نسخ الرابط';

  @override
  String get materialsLinkCopied => 'تم نسخ الرابط';

  @override
  String get materialsLibraryEmpty =>
      'لا توجد مواد في المكتبة بعد. اطلب من المدير رفع قائمة الأسعار.';

  @override
  String get materialsRetry => 'إعادة المحاولة';

  @override
  String get materialsNothingSent => 'لم يتم إرسال أي شيء بعد.';

  @override
  String get materialsHistoryUnavailable => 'تعذّر تحميل سجل الإرسال السابق.';

  @override
  String get materialsNotOpenedYet => 'لم يُفتح بعد';

  @override
  String materialsPageCount(Object count) {
    return '$count صفحات';
  }

  @override
  String materialsStillPreparing(Object count) {
    return '$count من هذه الملفات ما زالت قيد التجهيز. الرابط يعمل الآن، لكن أول فتح قد يستغرق ثوانٍ.';
  }

  @override
  String materialsOpenedCount(Object count) {
    return 'فُتح $count مرة';
  }

  @override
  String materialsSendFailed(Object error) {
    return 'تعذّر إنشاء الرابط: $error';
  }

  @override
  String materialsLoadFailed(Object error) {
    return 'تعذّر تحميل مكتبة المواد: $error';
  }

  @override
  String materialsLinkPlaceholderHint(Object token) {
    return 'اترك $token في مكان الرابط؛ سيتم استبداله تلقائيًا عند الإرسال.';
  }

  @override
  String get sessionExpiredMessage =>
      'انتهت جلستك. يُرجى تسجيل الدخول مرة أخرى.';

  @override
  String get appUpdateRequiredTitle => 'التحديث مطلوب';

  @override
  String get appUpdateRequiredBody =>
      'هذا الإصدار من Jarz POS قديم ولم يعد قابلاً للاستخدام. ثبّت أحدث إصدار للمتابعة.';

  @override
  String appUpdateBuildLine(Object current, Object minimum) {
    return 'الإصدار المثبّت $current · الإصدار المطلوب $minimum';
  }

  @override
  String get appUpdateDownloadButton => 'تنزيل التحديث';

  @override
  String get appUpdateRecheckButton => 'قمت بالتثبيت — أعد المحاولة';

  @override
  String get appUpdateOpenFailed =>
      'تعذّر فتح صفحة التنزيل. اطلب رابط التثبيت من المدير.';

  @override
  String get appUpdateInstallHint =>
      'سيطلب المتصفّح إذناً لتثبيت التطبيقات من هذا المصدر. اسمح بذلك، ثم افتح الملف المُنزّل للتثبيت.';

  @override
  String get appUpdateAvailableBanner => 'يتوفر إصدار جديد — اضغط للتنزيل.';

  @override
  String get materialsZoomedIn => 'قرّب على التفاصيل';

  @override
  String get materialsDownloadedFile => 'حمّل الملف';

  @override
  String materialsReadFor(Object time) {
    return 'قرأها لمدة $time';
  }

  @override
  String materialsPagesRead(Object count) {
    return '$count صفحات';
  }

  @override
  String get commonDone => 'تم';

  @override
  String get visitAddToRoute => 'إضافة إلى مسار';

  @override
  String get visitAddStop => 'إضافة';

  @override
  String get visitAddedToRoute => 'تمت الإضافة إلى المسار';

  @override
  String get visitOpenRoute => 'فتح';

  @override
  String visitWhichDoor(int count) {
    return 'أي فرع؟ ($count بموقع محدد)';
  }

  @override
  String get visitWhichDay => 'أي يوم';

  @override
  String get visitNewRoute => 'مسار جديد…';

  @override
  String visitNewRouteOn(String date) {
    return 'مسار جديد يوم $date';
  }

  @override
  String get visitNoUpcomingRoutes => 'لا توجد مسارات قادمة بعد.';

  @override
  String get visitNoDoorsToRoute => 'لا يوجد هنا ما يمكن التوجه إليه.';

  @override
  String get visitNoDoorsToRouteHint =>
      'لا يحتوي هذا السجل على فرع بموقع محدد. أضف الموقع أولاً ليصبح محطة.';

  @override
  String get visitFilters => 'عوامل التصفية';

  @override
  String get visitClearFilters => 'مسح الكل';

  @override
  String get visitFilterTier => 'فئة الملاءمة';

  @override
  String get visitFilterCategory => 'التصنيف';

  @override
  String get visitFilterArea => 'المنطقة';

  @override
  String visitFilterMinFit(int score) {
    return 'أقل درجة ملاءمة: $score';
  }

  @override
  String get visitFilterSpecialty => 'التخصصية فقط';

  @override
  String get visitFilterNeverVisited => 'التي لم تُزر من قبل فقط';

  @override
  String get visitFilterNeverVisitedHint => 'أماكن لم يدخلها أحد بعد.';

  @override
  String get visitEmptyDayHint =>
      'اختر الأماكن بالأسفل، أو اضغط «خطّط يومي». يتكوّن المسار أثناء اختيارك.';

  @override
  String get visitCostingDay => 'جارٍ حساب المسار…';

  @override
  String get visitManualOrderNote =>
      'ترتيبك أنت — اضغط «تحسين المسار» لإعادته تلقائياً.';

  @override
  String visitSkippedNoPin(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString مكاناً بلا موقع ولن تظهر على المسار',
      few: '$countString أماكن بلا موقع ولن تظهر على المسار',
      two: 'مكانان بلا موقع ولن يظهرا على المسار',
      one: 'مكان واحد بلا موقع ولن يظهر على المسار',
    );
    return '$_temp0';
  }

  @override
  String get visitSaveDraft => 'حفظ كمسودة';

  @override
  String get shiftCourierCarryTitle => 'أموال ما زالت مع المندوبين';

  @override
  String shiftCourierCarryBody(int transactions, Object amount, int couriers) {
    return '$transactions طلب بقيمة $amount ما زالت مع $couriers مندوب. أكِّد كل طلب أو سوِّه الآن.';
  }

  @override
  String get shiftCourierCarryHint =>
      'علّم كل طلب ما زال نقده مع المندوب. أي طلب تتركه بدون تأكيد يجب تسويته قبل إغلاق الشيفت.';

  @override
  String get shiftCourierCarryConfirmAll => 'تأكيد الكل';

  @override
  String get shiftCourierCarryClearAll => 'إلغاء الكل';

  @override
  String get shiftCourierCarrySettleNow => 'تسوية مندوب الآن';

  @override
  String shiftCourierCarryConfirmedOf(int confirmed, int total) {
    return 'تم تأكيد $confirmed من $total';
  }

  @override
  String shiftCourierCarryRowLabel(Object invoice, Object customer) {
    return '$invoice — $customer';
  }

  @override
  String get shiftCourierCarryCheckboxLabel => 'النقد ما زال مع المندوب';

  @override
  String shiftCourierCarryCarriedBadge(int count, int days) {
    return 'مرحّل عبر $count شيفت · $days يوم خارج الفرع';
  }

  @override
  String get shiftCourierCarryUnconfirmed =>
      'أكِّد كل طلب ما زال مع مندوب، أو سوِّه، قبل إغلاق الشيفت.';

  @override
  String shiftCourierCarriedSummary(int count, Object amount) {
    return '$count طلب بقيمة $amount خرجت من الشيفت وما زالت مع المندوبين، وتبقى مفتوحة حتى تتم تسويتها.';
  }

  @override
  String shiftMonitorCarriedOut(int count, Object amount) {
    return 'مُرحَّل للخارج: $count · $amount';
  }

  @override
  String shiftMonitorSettledIn(int count, Object amount) {
    return 'محصَّل من شيفتات سابقة: $count · $amount';
  }

  @override
  String get shiftMonitorCourierOutstandingTitle => 'مع المندوبين الآن';

  @override
  String shiftMonitorCourierOutstandingSummary(
    Object amount,
    int transactions,
    int days,
  ) {
    return '$amount على $transactions طلب، وأقدمها $days يوم.';
  }

  @override
  String get shiftMonitorCourierOutstandingEmpty =>
      'لا يوجد مندوب يحمل نقدًا حاليًا.';

  @override
  String shiftMonitorCourierRow(Object name, Object branch) {
    return '$name · $branch';
  }

  @override
  String shiftMonitorCourierRowDetail(int count, Object amount, int days) {
    return '$count طلب · $amount · أقدمها $days يوم';
  }

  @override
  String get expensesAdvanceTabExpenses => 'المصروفات';

  @override
  String get expensesAdvanceTabAdvances => 'سلف الموظفين';

  @override
  String get expensesAdvanceNewRequest => 'سلفة جديدة';

  @override
  String get expensesAdvanceFormTitle => 'طلب سلفة لموظف';

  @override
  String get expensesAdvanceEmployeeLabel => 'الموظف';

  @override
  String get expensesAdvanceEmployeeRequired => 'اختر موظفًا';

  @override
  String get expensesAdvanceEmployeeHint => 'اضغط لاختيار موظف';

  @override
  String get expensesAdvanceEmployeePickerTitle => 'اختيار الموظف';

  @override
  String get expensesAdvanceEmployeeSearchHint =>
      'ابحث بالاسم أو الفرع أو القسم';

  @override
  String get expensesAdvanceEmployeeNoMatches => 'لا يوجد موظف مطابق للبحث';

  @override
  String get expensesAdvanceAmountLabel => 'قيمة السلفة';

  @override
  String get expensesAdvanceAmountInvalid => 'من فضلك أدخل قيمة صحيحة';

  @override
  String get expensesAdvancePurposeLabel => 'الغرض من السلفة';

  @override
  String get expensesAdvancePurposeRequired => 'اكتب سبب طلب السلفة';

  @override
  String get expensesAdvancePayFromLabel => 'الصرف من';

  @override
  String get expensesAdvancePaymentSourceRequired => 'اختر مصدر الصرف';

  @override
  String get expensesAdvanceSalaryMonthLabel => 'تُخصم من مرتب شهر';

  @override
  String get expensesAdvanceSalaryMonthHelp =>
      'النقدية تُصرف في تاريخ السلفة من الحساب المختار في كل الأحوال. هذا يحدد فقط مرتب أي شهر ستُخصم منه السلفة — قبل يوم القبض تكون عادةً من مرتب الشهر الماضي.';

  @override
  String get expensesAdvanceSalaryMonthRequired =>
      'اختر الشهر الذي ستُخصم السلفة من مرتبه.';

  @override
  String get expensesAdvanceSalaryMonthSuggested => 'مقترح';

  @override
  String get expensesAdvanceSalaryMonthCardLabel => 'شهر المرتب';

  @override
  String expensesAdvanceSalaryMonthChip(String month) {
    return 'مرتب $month';
  }

  @override
  String get expensesAdvanceDateLabel => 'تاريخ السلفة (اختياري)';

  @override
  String get expensesAdvanceDateNotSet => 'اليوم';

  @override
  String get expensesAdvanceDateClear => 'مسح التاريخ';

  @override
  String get expensesAdvanceSubmit => 'إرسال الطلب';

  @override
  String get expensesAdvanceNoOptions =>
      'لا يمكن طلب سلفة قبل توفر قائمة الموظفين ومصدر للصرف.';

  @override
  String get expensesAdvanceSubmitted => 'تم إرسال طلب السلفة للاعتماد';

  @override
  String get expensesAdvanceMonthLabel => 'الشهر';

  @override
  String get expensesAdvanceStatusFilterLabel => 'الحالة';

  @override
  String get expensesAdvanceStatusFilterAll => 'كل الحالات';

  @override
  String get expensesAdvanceEmptyTitle => 'لا توجد سلف موظفين لهذا الشهر.';

  @override
  String get expensesAdvanceEmptyApproverBody =>
      'ستظهر هنا طلبات مديري الخطوط في انتظار الاعتماد.';

  @override
  String get expensesAdvanceEmptyRequesterBody =>
      'استخدم زر سلفة جديدة لطلب نقدية لموظف.';

  @override
  String get expensesAdvanceEmptyReadOnlyBody =>
      'لا تملك صلاحية طلب أو اعتماد السلف.';

  @override
  String get expensesAdvanceUnavailableTitle => 'سلف الموظفين غير متاحة';

  @override
  String get expensesAdvanceUnavailableBody =>
      'وحدة الموارد البشرية غير مثبتة على هذا الموقع، لذلك لا يمكن طلب السلف من هنا.';

  @override
  String get expensesAdvanceSummaryTotal => 'الإجمالي';

  @override
  String get expensesAdvanceSummaryPending => 'في انتظار الاعتماد';

  @override
  String get expensesAdvanceSummaryApproved => 'المعتمدة';

  @override
  String get expensesAdvanceSummaryOutstanding => 'المتبقي';

  @override
  String expensesAdvanceSummaryCount(int count) {
    return '$count طلب';
  }

  @override
  String expensesAdvanceSummaryPendingValue(int count, Object amount) {
    return '$count | $amount';
  }

  @override
  String get expensesAdvanceApprove => 'اعتماد وصرف';

  @override
  String get expensesAdvanceReject => 'رفض';

  @override
  String get expensesAdvanceApproveTitle => 'اعتماد السلفة؟';

  @override
  String expensesAdvanceApproveBody(
    Object amount,
    Object employee,
    Object source,
  ) {
    return 'الاعتماد يصرف $amount إلى $employee الآن من $source. تخرج النقدية من هذا الحساب فورًا ولا يمكن التراجع عن ذلك من هذه الشاشة.';
  }

  @override
  String get expensesAdvanceApproveConfirm => 'اعتماد وصرف الآن';

  @override
  String get expensesAdvanceApproved => 'تم اعتماد السلفة وصرفها';

  @override
  String expensesAdvanceApprovedWithEntry(Object entry) {
    return 'تم اعتماد السلفة وصرفها · $entry';
  }

  @override
  String get expensesAdvanceRejectTitle => 'رفض طلب السلفة؟';

  @override
  String get expensesAdvanceRejectHint => 'وضح لمقدم الطلب سبب الرفض';

  @override
  String get expensesAdvanceRejectReasonRequired => 'السبب مطلوب';

  @override
  String get expensesAdvanceRejected => 'تم رفض طلب السلفة';

  @override
  String get expensesAdvanceIdLabel => 'رقم السلفة';

  @override
  String get expensesAdvancePostingDateLabel => 'تاريخ السلفة';

  @override
  String get expensesAdvanceBranchLabel => 'الفرع';

  @override
  String get expensesAdvancePayingAccountLabel => 'حساب الصرف';

  @override
  String get expensesAdvancePaidLabel => 'المصروف';

  @override
  String get expensesAdvanceClaimedLabel => 'المسوى';

  @override
  String get expensesAdvanceReturnedLabel => 'المرتجع';

  @override
  String get expensesAdvanceBalanceLabel => 'الرصيد المتبقي';

  @override
  String get expensesAdvanceRequestedByLabel => 'مقدم الطلب';

  @override
  String get expensesAdvanceApprovedByLabel => 'المعتمد';

  @override
  String get expensesAdvanceApprovedOnLabel => 'تاريخ الاعتماد';

  @override
  String get expensesAdvancePaymentEntryLabel => 'سند الدفع';

  @override
  String get expensesAdvanceStatusDraft => 'في انتظار الاعتماد';

  @override
  String get expensesAdvanceStatusPaid => 'مصروفة';

  @override
  String get expensesAdvanceStatusPartiallyPaid => 'مصروفة جزئيا';

  @override
  String get expensesAdvanceStatusUnpaid => 'غير مصروفة';

  @override
  String get expensesAdvanceStatusClaimed => 'تمت التسوية';

  @override
  String get expensesAdvanceStatusReturned => 'مرتجعة';

  @override
  String get expensesAdvanceStatusPartlyClaimedAndReturned =>
      'تسوية جزئية وإرجاع';

  @override
  String get expensesAdvanceStatusCancelled => 'ملغاة';

  @override
  String get managerEmployeeLedgerTitle => 'حساب الموظفين';

  @override
  String get managerEmployeeLedgerSubtitle =>
      'المستحق على كل موظف: السلف النقدية + الطلبات غير المدفوعة';

  @override
  String get managerEmployeeLedgerPeriodLabel => 'الفترة';

  @override
  String get managerEmployeeLedgerWindow30 => 'آخر 30 يوم';

  @override
  String get managerEmployeeLedgerWindow90 => 'آخر 90 يوم';

  @override
  String get managerEmployeeLedgerWindow180 => 'آخر 180 يوم';

  @override
  String get managerEmployeeLedgerWindow365 => 'آخر 365 يوم';

  @override
  String managerEmployeeLedgerActivityRange(Object from, Object to) {
    return 'الحركة المعروضة: من $from إلى $to';
  }

  @override
  String get managerEmployeeLedgerActivityInPeriod => 'الحركة في الفترة دي';

  @override
  String get managerEmployeeLedgerTotalOutstanding =>
      'إجمالي المستحق في الفترة دي';

  @override
  String get managerEmployeeLedgerTotalOutstandingAllTime =>
      'إجمالي المستحق (كل الفترات)';

  @override
  String get managerEmployeeLedgerAllTimeHint =>
      'كل المستحقات المفتوحة مهما كان تاريخها. الفترة تحت بتحدد السطور المعروضة بس.';

  @override
  String get managerEmployeeLedgerAdvancesLabel => 'السلف النقدية';

  @override
  String get managerEmployeeLedgerOrdersLabel => 'طلبات غير مدفوعة';

  @override
  String managerEmployeeLedgerAdvanceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سلفة',
      few: '$count سلف',
      two: 'سلفتين',
      one: 'سلفة واحدة',
      zero: 'مفيش سلف',
    );
    return '$_temp0';
  }

  @override
  String managerEmployeeLedgerOrderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب',
      few: '$count طلبات',
      two: 'طلبين',
      one: 'طلب واحد',
      zero: 'مفيش طلبات',
    );
    return '$_temp0';
  }

  @override
  String managerEmployeeLedgerEmployeeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شخص عليهم مستحقات',
      few: '$count أشخاص عليهم مستحقات',
      two: 'شخصين عليهم مستحقات',
      one: 'شخص واحد عليه مستحقات',
      zero: 'مفيش حد عليه مستحقات',
    );
    return '$_temp0';
  }

  @override
  String managerEmployeeLedgerSplit(Object advances, Object orders) {
    return 'سلف $advances • طلبات $orders';
  }

  @override
  String get managerEmployeeLedgerOutstandingLabel => 'المستحق';

  @override
  String get managerEmployeeLedgerOrderTotalLabel => 'إجمالي الطلب';

  @override
  String get managerEmployeeLedgerAdvanceAmountLabel => 'السلفة';

  @override
  String get managerEmployeeLedgerEmpty =>
      'مفيش مستحقات، ومفيش حركة في الفترة دي';

  @override
  String get managerEmployeeLedgerNoAdvances => 'مفيش سلف نقدية في الفترة دي';

  @override
  String get managerEmployeeLedgerNoOrders =>
      'مفيش طلبات غير مدفوعة في الفترة دي';

  @override
  String get managerEmployeeLedgerBalancePredatesPeriod =>
      'مفيش حاجة معروضة في الفترة دي. الرصيد فوق أقدم من كده، فوسع الفترة عشان تشوف السطور اللي وراه.';

  @override
  String get managerEmployeeLedgerUnmatched => 'مش مربوط بموظف';

  @override
  String get managerEmployeeLedgerLoadFailed => 'تعذر تحميل حساب الموظفين';

  @override
  String get managerEmployeeLedgerNoticeNoBranchAssigned =>
      'مفيش فرع متخصص ليك، فمفيش حاجة تتعرض هنا لسه.';

  @override
  String get managerEmployeeLedgerNoticeBranchNotPermitted =>
      'مش مسموح لك تشوف الفرع ده، فاتم تجاهله.';

  @override
  String get managerEmployeeLedgerNoticeHrmsUnavailable =>
      'نظام HRMS مش متثبت، فالسلف النقدية مش بتتسجل. الطلبات غير المدفوعة لسه بتتعرض.';

  @override
  String get managerEmployeeLedgerNoticeResultsTruncated =>
      'بتتعرض أول النتائج بس. ضيق الفرع أو الفترة عشان تشوف الباقي.';

  @override
  String get kanbanStateReceived => 'مستلم';

  @override
  String get kanbanStateInProgress => 'بيتجهز';

  @override
  String get kanbanStateReady => 'جاهز';

  @override
  String get cancelReasonCustomerRequested => 'العميل طلب الإلغاء';

  @override
  String get cancelReasonCreatedInError => 'الطلب اتعمل بالغلط أو مكرر';

  @override
  String get cancelReasonInventoryUnavailable => 'البضاعة مش متوفرة';

  @override
  String get cancelReasonPaymentIssue => 'مشكلة في الدفع';

  @override
  String get cancelReasonOther => 'سبب تاني';

  @override
  String get notSuitableReasonOutOfBusiness => 'قافل خلاص';

  @override
  String get notSuitableReasonWrongCategory => 'نشاط مش مناسب';

  @override
  String get notSuitableReasonTooSmall => 'صغير أوي';

  @override
  String get notSuitableReasonNoContactInfo => 'مفيش بيانات تواصل';

  @override
  String get notSuitableReasonUnreachable => 'مش بيرد';

  @override
  String get notSuitableReasonAlreadySupplied => 'متعامل مع مورّد تاني';

  @override
  String get notSuitableReasonPriceMismatch => 'السعر مش مناسب';

  @override
  String get notSuitableReasonOutsideDeliveryArea => 'برة نطاق التوصيل';

  @override
  String get notSuitableReasonDuplicate => 'مكرر';

  @override
  String get notSuitableReasonNotInterested => 'مش مهتم';

  @override
  String get notSuitableReasonOther => 'سبب تاني';

  @override
  String get leadSourceWalkIn => 'جه بنفسه';

  @override
  String get leadSourceReference => 'ترشيح';

  @override
  String get leadSourceCampaign => 'حملة إعلانية';

  @override
  String get leadSourceExistingCustomer => 'عميل حالي';

  @override
  String get leadSourceColdCall => 'اتصال مباشر';

  @override
  String get leadSourceSocialMedia => 'سوشال ميديا';

  @override
  String get customerSegmentChampion => 'أفضل العملاء';

  @override
  String get customerSegmentLoyal => 'عميل وفي';

  @override
  String get customerSegmentPotentialLoyalist => 'قرّب يبقى وفي';

  @override
  String get customerSegmentNewCustomer => 'عميل جديد';

  @override
  String get customerSegmentAtRisk => 'في خطر';

  @override
  String get customerSegmentCantLoseThem => 'مينفعش نخسرهم';

  @override
  String get customerSegmentLost => 'خسرناه';

  @override
  String get customerSegmentOneTime => 'طلب مرة واحدة';

  @override
  String get customerSegmentUnclassified => 'غير مصنّف';

  @override
  String get velocityTrendAccelerating => 'بيزيد';

  @override
  String get velocityTrendStable => 'ثابت';

  @override
  String get velocityTrendDeclining => 'بيقل';

  @override
  String get velocityTrendNewItem => 'صنف جديد';

  @override
  String get velocityTrendNoSales => 'مفيش مبيعات';

  @override
  String get visitStatusPlanned => 'مخططة';

  @override
  String get visitStatusInProgress => 'جارية';

  @override
  String get visitStatusVisited => 'اتزارت';

  @override
  String get visitStatusSkipped => 'اتخطّت';

  @override
  String get materialTypePriceList => 'قائمة أسعار';

  @override
  String get materialTypeProductPhotos => 'صور المنتجات';

  @override
  String get materialTypeCatalog => 'كتالوج';

  @override
  String get materialTypeCertificate => 'شهادة';

  @override
  String get materialTypeOther => 'غير كده';

  @override
  String get b2bStageShortLead => 'محتمل';

  @override
  String get b2bStageShortQualify => 'تأهيل';

  @override
  String get b2bStageShortSample => 'عينة';

  @override
  String get b2bStageShortApproved => 'موافقة';

  @override
  String get b2bStageShortTrial => 'تجربة';

  @override
  String get b2bStageShortCheckup => 'متابعة';

  @override
  String get b2bStageShortActive => 'نشط';

  @override
  String get b2bStageShortLostOnHold => 'خسران';

  @override
  String get statusChanged => 'اتغيّر';

  @override
  String get statusSettled => 'متسوّي';

  @override
  String get statusUnsettled => 'لسه متسوّاش';

  @override
  String get statusAccepted => 'مقبول';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusPaused => 'متوقف مؤقتاً';

  @override
  String get statusEnded => 'منتهي';

  @override
  String get statusClosed => 'مقفول';

  @override
  String get statusInProgress => 'جاري';

  @override
  String get reportsColumnItem => 'الصنف';

  @override
  String get reportsColumnVelocity30d => 'سرعة ٣٠ ي';

  @override
  String get reportsColumnVelocity60d => 'سرعة ٦٠ ي';

  @override
  String get reportsColumnTrend => 'الاتجاه';

  @override
  String get reportsColumnStock => 'الرصيد';

  @override
  String get reportsColumnCover => 'أيام التغطية';

  @override
  String get reportsColumnSold => 'المُباع';

  @override
  String get reportsColumnRevenue => 'الإيراد';

  @override
  String get reportsColumnVelocity => 'السرعة';

  @override
  String get menuShiftDistribution => 'توزيع الشيفتات';

  @override
  String get rosterTitle => 'توزيع الشيفتات';

  @override
  String get rosterAccessDenied =>
      'توزيع الشيفتات متاح للمديرين ومديري الخطوط فقط.';

  @override
  String get rosterHoursTitle => 'الساعات والوقت الإضافي';

  @override
  String get rosterHoursBasis =>
      'ساعات حسب الجدول — الشيفتات المخصصة فعليًا. الوقت الإضافي يُحتسب بمعدل كل موظف.';

  @override
  String get rosterPreviousMonth => 'الشهر السابق';

  @override
  String get rosterNextMonth => 'الشهر التالي';

  @override
  String get rosterAllBranches => 'كل الفروع';

  @override
  String get rosterEmployeeColumn => 'الموظف';

  @override
  String get rosterHrmsMissing =>
      'تطبيق الموارد البشرية غير مثبت على هذا الموقع، لذا لا يوجد جدول للعرض.';

  @override
  String get rosterNobodyRostered => 'لا يوجد أحد مُدرج في جدول هذا الشهر بعد.';

  @override
  String get rosterScopeUnconfigured =>
      'لا توجد فروع مرتبطة بملفات نقاط البيع الخاصة بك، لذا لا يوجد من يُعرض. اطلب من المسؤول ضبط موقع الشيفت في ملف نقطة البيع.';

  @override
  String rosterUncoveredWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أيام إجازة بدون تغطية',
      two: 'يوما إجازة بدون تغطية',
      one: 'يوم إجازة واحد بدون تغطية',
    );
    return '$_temp0';
  }

  @override
  String rosterStandardDay(Object hours) {
    return 'اليوم العادي: $hours ساعة';
  }

  @override
  String get rosterOffShort => 'إجازة';

  @override
  String get rosterHolidayShort => 'عطلة';

  @override
  String get rosterChangeShift => 'تغيير الشيفت';

  @override
  String get rosterMarkDayOff => 'تسجيل يوم إجازة';

  @override
  String get rosterClearDayOff => 'إلغاء يوم الإجازة';

  @override
  String get rosterNoShiftTypes => 'لم يتم إعداد أي أنواع شيفتات بعد.';

  @override
  String rosterShowAllShifts(int count) {
    return 'عرض كل الشيفتات ($count)';
  }

  @override
  String get rosterShowMyShifts => 'عرض شيفتات هذا الشخص فقط';

  @override
  String rosterShiftWindow(Object window, Object hours) {
    return '$window · $hours ساعة';
  }

  @override
  String rosterWorkingShift(Object shiftType, Object hours, Object location) {
    return 'على $shiftType · $hours ساعة · $location';
  }

  @override
  String rosterOffCoveredBy(Object offType, Object name) {
    return 'إجازة ($offType) — يغطيها $name';
  }

  @override
  String rosterOffUncovered(Object offType) {
    return 'إجازة ($offType) — لا أحد يغطي هذا اليوم';
  }

  @override
  String get rosterHoliday => 'عطلة رسمية';

  @override
  String get rosterUnrosteredWarning =>
      'غير مُدرج في الجدول — لن يتمكن هذا الموظف من تسجيل الحضور في هذا اليوم.';

  @override
  String get rosterOffType => 'السبب';

  @override
  String get rosterCoveredBy => 'التغطية بواسطة';

  @override
  String get rosterCoverHelper => 'من يتحمل هذا اليوم في الفرع.';

  @override
  String get rosterNobodyCovers => 'لا أحد';

  @override
  String get rosterCoverShift => 'شيفت التغطية';

  @override
  String get rosterCoverShiftHelper =>
      'الشيفت الذي ينتقل إليه في هذا اليوم، عادةً شيفت اليوم الكامل الأطول.';

  @override
  String get rosterNotes => 'ملاحظات (اختياري)';

  @override
  String get rosterOffTypeWeekly => 'راحة أسبوعية';

  @override
  String get rosterOffTypeVacation => 'إجازة';

  @override
  String get rosterOffTypeSick => 'إجازة مرضية';

  @override
  String get rosterOffTypeUnpaid => 'إجازة بدون أجر';

  @override
  String get rosterOffTypeOther => 'أخرى';

  @override
  String get rosterWorkedHours => 'ساعات العمل';

  @override
  String get rosterOvertimeHours => 'الوقت الإضافي';

  @override
  String get rosterCreditedOvertime => 'الإضافي المحتسب';

  @override
  String get rosterCreditedHours => 'الساعات المدفوعة';

  @override
  String rosterCourierTag(Object multiplier) {
    return 'مندوب ×$multiplier';
  }

  @override
  String rosterRowDays(Object worked, Object off, Object cover) {
    return '$worked عمل · $off إجازة · $cover تغطية';
  }

  @override
  String get rosterLegendWorking => 'عمل';

  @override
  String get rosterLegendOff => 'إجازة';

  @override
  String get rosterLegendUnrostered => 'غير مُدرج';

  @override
  String get rosterLegendHoliday => 'عطلة';

  @override
  String get settlementPartnerFeeInputLabel => 'تكلفة التوصيل لدى الشريك';

  @override
  String get settlementPartnerFeeInputHint => 'اقرأها من تطبيق الشريك';

  @override
  String get settlementPartnerFeeRequired =>
      'أدخل تكلفة التوصيل لدى الشريك لهذا الطلب';

  @override
  String get settlementPartnerFeeInvalid => 'أدخل مبلغًا صحيحًا';

  @override
  String get settlementPartnerFeeWhy =>
      'أسعار مناطقنا لا تنطبق على الشريك — فهو يسعّر هذا العنوان بنفسه.';

  @override
  String get settlementPartnerNoDeduction =>
      'المندوب يسلّم المبلغ كاملًا. لا يُخصم شيء مقابل أجرته — تُحاسب شركته أسبوعيًا.';

  @override
  String get commonReasonRequired => 'السبب مطلوب';

  @override
  String get expensesReject => 'رفض';

  @override
  String get expensesRejectTitle => 'رفض هذا المصروف؟';

  @override
  String get expensesRejectHint => 'وضح لمقدم الطلب سبب الرفض';

  @override
  String get expensesRejected => 'تم رفض المصروف';

  @override
  String get expensesRejectedStatus => 'مرفوض';

  @override
  String get expensesRejectionReason => 'سبب الرفض';

  @override
  String get expensesCancelAction => 'إلغاء المصروف';

  @override
  String get expensesCancelTitle => 'إلغاء هذا المصروف المعتمد؟';

  @override
  String expensesCancelBody(Object amount, Object source) {
    return 'سيتم عكس القيد المحاسبي بمبلغ $amount وإعادة المبلغ إلى $source.';
  }

  @override
  String get expensesCancelHint => 'لماذا يتم عكس هذا المصروف؟';

  @override
  String get expensesCancelConfirm => 'إلغاء وعكس القيد';

  @override
  String get expensesCancelled => 'تم إلغاء المصروف وعكس القيد المحاسبي';

  @override
  String get productionCancelBatch => 'إلغاء الدفعة';

  @override
  String get productionCancelBatchTitle => 'إلغاء هذه الدفعة؟';

  @override
  String productionCancelBatchBody(Object item) {
    return 'كل ما تبقى في التشغيل الجاري لـ $item سيعود إلى المخزن. لم يتم إنتاج أي كمية بعد، لذا لن تتأثر المنتجات الجاهزة.';
  }

  @override
  String get productionCancelBatchHint => 'لماذا لن يتم إنهاء هذه الدفعة؟';

  @override
  String get productionCancelBatchConfirm => 'إلغاء الدفعة';

  @override
  String get productionBatchCancelled =>
      'تم إلغاء الدفعة وإرجاع الخامات إلى المخزن';

  @override
  String get productionPlanCancel => 'إلغاء الخطة';

  @override
  String get productionPlanCancelTitle => 'إلغاء خطة هذا اليوم؟';

  @override
  String get productionPlanCancelBody =>
      'استخدم هذا عندما لن يتم الإنتاج نهائيًا في هذا اليوم. الإقفال بكميات صفرية بدلًا من ذلك يسجل يومًا حاول ولم ينتج شيئًا.';

  @override
  String get productionPlanCancelHint => 'لماذا تم إلغاء اليوم؟';

  @override
  String get productionPlanCancelConfirm => 'إلغاء الخطة';

  @override
  String get productionPlanCancelled => 'تم إلغاء خطة الإنتاج';

  @override
  String get productionPlanCancelledStatus => 'ملغاة';

  @override
  String get receiptReject => 'رفض';

  @override
  String get receiptRejectTitle => 'رفض هذا الإيصال؟';

  @override
  String get receiptRejectHint => 'ما المشكلة في إثبات التحويل؟';

  @override
  String get receiptRejectConfirm => 'رفض الإيصال';

  @override
  String get receiptRejected => 'تم رفض الإيصال';

  @override
  String get receiptRejectedStatus => 'مرفوض';

  @override
  String get receiptRejectionReason => 'سبب الرفض';

  @override
  String get historyDateRangeAll => 'كل التواريخ';

  @override
  String historyDateRangeValue(Object from, Object to) {
    return '$from - $to';
  }

  @override
  String get stockTransferHistoryTitle => 'سجل التحويلات';

  @override
  String get stockTransferHistorySearchHint => 'رقم القيد أو الصنف';

  @override
  String get stockTransferHistoryEmpty => 'لا توجد تحويلات مخزون بعد.';

  @override
  String stockTransferHistoryRoute(Object source, Object target) {
    return 'من $source إلى $target';
  }

  @override
  String get stockTransferHistoryMixed => 'مخازن متعددة';

  @override
  String stockTransferHistorySummary(Object items, Object qty) {
    return '$items صنف، $qty وحدة';
  }

  @override
  String get cashTransferHistoryTitle => 'سجل التحويلات النقدية';

  @override
  String get cashTransferHistorySearchHint => 'رقم القيد أو الملاحظة';

  @override
  String get cashTransferHistoryEmpty => 'لا توجد تحويلات نقدية بعد.';

  @override
  String get inventoryCountHistoryTitle => 'سجل الجرد';

  @override
  String get inventoryCountHistorySearchHint => 'رقم الجرد أو الصنف';

  @override
  String get inventoryCountHistoryEmpty => 'لا توجد عمليات جرد بعد.';

  @override
  String inventoryCountHistoryAdjusted(Object items) {
    return 'تم تعديل $items صنف';
  }

  @override
  String inventoryCountHistoryDeltas(Object up, Object down) {
    return '$up زيادة، $down نقص';
  }

  @override
  String get inventoryCountHistoryValueChange => 'تغير القيمة';

  @override
  String get shiftHistoryTitle => 'سجل الورديات';

  @override
  String get shiftHistoryEmpty => 'لا توجد ورديات بعد.';

  @override
  String get shiftHistoryStatusOpen => 'مفتوحة';

  @override
  String get shiftHistoryStatusClosed => 'مغلقة';

  @override
  String get shiftHistoryAmountsHidden => 'المبالغ تظهر للمديرين فقط.';

  @override
  String get shiftHistoryDifference => 'زيادة / عجز';

  @override
  String get shiftHistoryMineOnly => 'وردياتي فقط';

  @override
  String get shiftHistoryStillOpen => 'ما زالت مفتوحة';

  @override
  String shiftHistoryDuration(Object start, Object end) {
    return 'من $start إلى $end';
  }

  @override
  String shiftHistoryOpenedBy(Object name) {
    return 'فتحها $name';
  }

  @override
  String get menuMonthlyExpenses => 'المصروفات الشهرية';

  @override
  String get monthlyExpensesTitle => 'المصروفات الشهرية';

  @override
  String get monthlyExpensesRefreshTooltip => 'تحديث';

  @override
  String get monthlyExpensesMonthLabel => 'الشهر';

  @override
  String get monthlyExpensesPreviousMonthTooltip => 'الشهر السابق';

  @override
  String get monthlyExpensesNextMonthTooltip => 'الشهر التالي';

  @override
  String get monthlyExpensesLoadFailed => 'تعذر تحميل بيانات هذا الشهر.';

  @override
  String get monthlyExpensesRemaining => 'المتبقي';

  @override
  String get monthlyExpensesDue => 'المستحق';

  @override
  String get monthlyExpensesPaid => 'المدفوع';

  @override
  String get monthlyExpensesRunRate => 'المعدل الشهري';

  @override
  String monthlyExpensesRemainingCaption(Object paid, Object due) {
    return 'تم دفع $paid من إجمالي $due';
  }

  @override
  String monthlyExpensesOverpaidNotice(Object amount) {
    return 'زيادة في الدفع بمقدار $amount';
  }

  @override
  String monthlyExpensesItemsBreakdown(int paid, int partial, int unpaid) {
    return '$paid مدفوع، $partial جزئي، $unpaid غير مدفوع';
  }

  @override
  String monthlyExpensesItemsTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بند مستحق',
      few: '$count بنود مستحقة',
      two: 'بندان مستحقان',
      one: 'بند واحد مستحق',
      zero: 'لا توجد بنود مستحقة',
    );
    return '$_temp0';
  }

  @override
  String get monthlyExpensesGapsTitle => 'يحتاج انتباهك';

  @override
  String get monthlyExpensesRecurringTitle => 'المصروفات المتكررة';

  @override
  String get monthlyExpensesRecurringEmpty =>
      'لا توجد أي مصروفات متكررة مسجلة حتى الآن.';

  @override
  String get monthlyExpensesCategoryUncategorised => 'بدون تصنيف';

  @override
  String monthlyExpensesCategorySubtotal(Object remaining, Object due) {
    return 'متبقي $remaining من $due';
  }

  @override
  String get monthlyExpensesStatusPaid => 'مدفوع';

  @override
  String get monthlyExpensesStatusPartial => 'جزئي';

  @override
  String get monthlyExpensesStatusUnpaid => 'غير مدفوع';

  @override
  String get monthlyExpensesStatusNotDue => 'غير مستحق';

  @override
  String get monthlyExpensesStatusOverpaid => 'مدفوع بالزيادة';

  @override
  String get monthlyExpensesLifecyclePaused => 'موقوف مؤقتاً';

  @override
  String get monthlyExpensesLifecycleEnded => 'منتهي';

  @override
  String get monthlyExpensesPayAction => 'دفع';

  @override
  String get monthlyExpensesInferredBadge => 'من دفتر الأستاذ';

  @override
  String monthlyExpensesInferredExplain(Object amount) {
    return 'مبلغ $amount من المدفوع مقروء من دفتر الأستاذ ولم يُدفع من خلال هذا التطبيق.';
  }

  @override
  String get monthlyExpensesSharedAccountBadge => 'حساب مشترك';

  @override
  String monthlyExpensesSharedAccountExplain(Object account) {
    return 'توجد مصروفات أخرى تُرحَّل إلى $account هذا الشهر، لذلك لا يمكن نسب مدفوعات دفتر الأستاذ إلى هذا البند.';
  }

  @override
  String get monthlyExpensesFrequencyLabel => 'التكرار';

  @override
  String get monthlyExpensesDueDateLabel => 'تاريخ الاستحقاق';

  @override
  String get monthlyExpensesAccountLabel => 'حساب المصروف';

  @override
  String get monthlyExpensesCostCenterLabel => 'مركز التكلفة';

  @override
  String get monthlyExpensesSupplierLabel => 'المورد';

  @override
  String get monthlyExpensesNotesLabel => 'ملاحظات';

  @override
  String get monthlyExpensesAmountLabel => 'المبلغ';

  @override
  String get monthlyExpensesMonthlyEquivalentLabel => 'ما يعادله شهرياً';

  @override
  String get monthlyExpensesPaymentsTitle => 'المدفوعات';

  @override
  String get monthlyExpensesPaymentsEmpty =>
      'لا توجد مدفوعات مسجلة لهذا الشهر.';

  @override
  String get monthlyExpensesPaymentCancelAction => 'إلغاء الدفعة';

  @override
  String get monthlyExpensesPaymentCancelTitle => 'إلغاء هذه الدفعة؟';

  @override
  String monthlyExpensesPaymentCancelBody(Object amount, Object source) {
    return 'سيؤدي هذا إلى عكس القيد المحاسبي بمبلغ $amount وإعادة المبلغ إلى $source.';
  }

  @override
  String get monthlyExpensesPaymentCancelHint => 'لماذا يتم عكس هذه الدفعة؟';

  @override
  String get monthlyExpensesPaymentCancelConfirm => 'إلغاء وعكس القيد';

  @override
  String get monthlyExpensesPaymentCancelled =>
      'تم إلغاء الدفعة وعكس القيد المحاسبي';

  @override
  String get monthlyExpensesSalariesTitle => 'المرتبات';

  @override
  String get monthlyExpensesSalariesEmpty =>
      'لا يوجد موظف لديه هيكل رواتب لهذا الشهر.';

  @override
  String get monthlyExpensesPayrollNotConfigured =>
      'لم يتم إعداد الرواتب، لذلك لا يمكن دفع المرتبات من هذه الشاشة.';

  @override
  String get monthlyExpensesPayrollAccountLabel => 'حساب المرتبات';

  @override
  String get monthlyExpensesSalaryBaseLabel => 'الأساسي';

  @override
  String get monthlyExpensesSalaryVariableLabel => 'المتغير';

  @override
  String get monthlyExpensesSalarySlipExists =>
      'توجد قسيمة راتب معتمدة تغطي هذا الشهر بالفعل، والدفع من هنا سيسجل الراتب مرتين.';

  @override
  String monthlyExpensesMissingStructureTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count موظف بدون هيكل رواتب',
      few: '$count موظفين بدون هيكل رواتب',
      two: 'موظفان بدون هيكل رواتب',
      one: 'موظف واحد بدون هيكل رواتب',
    );
    return '$_temp0';
  }

  @override
  String get monthlyExpensesMissingStructureBody =>
      'رواتبهم غير محتسبة في الأرقام أعلاه. عيّن هيكل رواتب في الموارد البشرية لتضمينهم.';

  @override
  String monthlyExpensesUnattributedGl(Object amount) {
    return 'مبلغ $amount مُرحَّل إلى حساب المرتبات ولا يمكن نسبه إلى موظف بعينه، لذلك يُعرض هنا بدلاً من إضافته إلى أحد الصفوف.';
  }

  @override
  String monthlyExpensesPayTitle(Object name) {
    return 'دفع $name';
  }

  @override
  String monthlyExpensesPayPeriod(Object month) {
    return 'عن شهر $month';
  }

  @override
  String get monthlyExpensesPayAmountLabel => 'المبلغ المراد دفعه';

  @override
  String get monthlyExpensesPayAmountInvalid => 'أدخل مبلغاً أكبر من صفر';

  @override
  String get monthlyExpensesPayFromLabel => 'الدفع من';

  @override
  String get monthlyExpensesPayFromRequired =>
      'اختر الحساب الذي سيتم الدفع منه';

  @override
  String get monthlyExpensesPayDateLabel => 'تاريخ الدفع';

  @override
  String get monthlyExpensesPayRemarksLabel => 'ملاحظات (اختياري)';

  @override
  String get monthlyExpensesPaySubmit => 'دفع';

  @override
  String monthlyExpensesPaySourceOption(Object label, Object balance) {
    return '$label — $balance';
  }

  @override
  String get monthlyExpensesPayNoSources =>
      'لا يوجد حساب نقدي أو بنكي متاح للدفع منه.';

  @override
  String monthlyExpensesPayRemainingHint(Object amount) {
    return 'المتبقي: $amount';
  }

  @override
  String get monthlyExpensesPaymentRecorded => 'تم تسجيل الدفعة';

  @override
  String get monthlyExpensesOverpayTitle => 'أكثر من المستحق';

  @override
  String get monthlyExpensesOverpayConfirm => 'ادفع على أي حال';

  @override
  String get monthlyExpensesAddAction => 'إضافة مصروف';

  @override
  String get monthlyExpensesNewTitle => 'مصروف متكرر جديد';

  @override
  String get monthlyExpensesEditTitle => 'تعديل المصروف المتكرر';

  @override
  String get monthlyExpensesNameLabel => 'الاسم';

  @override
  String get monthlyExpensesNameRequired => 'أدخل اسماً لهذا المصروف';

  @override
  String get monthlyExpensesAmountRequired => 'أدخل مبلغاً أكبر من صفر';

  @override
  String get monthlyExpensesCategoryLabel => 'التصنيف';

  @override
  String get monthlyExpensesCategoryRequired => 'اختر تصنيفاً';

  @override
  String get monthlyExpensesFrequencyRequired => 'اختر التكرار';

  @override
  String get monthlyExpensesAccountRequired => 'اختر حساب المصروف';

  @override
  String get monthlyExpensesDayOfMonthLabel => 'يوم من الشهر';

  @override
  String get monthlyExpensesDayOfMonthInvalid => 'أدخل يوماً بين 1 و 28';

  @override
  String get monthlyExpensesStartDateLabel => 'يبدأ';

  @override
  String get monthlyExpensesEndDateLabel => 'ينتهي (اختياري)';

  @override
  String get monthlyExpensesDefaultPayingAccountLabel =>
      'يُدفع عادة من (اختياري)';

  @override
  String get monthlyExpensesNoneOption => 'بدون';

  @override
  String get monthlyExpensesSaved => 'تم حفظ المصروف المتكرر';

  @override
  String get monthlyExpensesManageTooltip => 'إدارة';

  @override
  String get monthlyExpensesEditAction => 'تعديل';

  @override
  String get monthlyExpensesPauseAction => 'إيقاف مؤقت';

  @override
  String get monthlyExpensesResumeAction => 'استئناف';

  @override
  String get monthlyExpensesEndAction => 'إنهاء';

  @override
  String monthlyExpensesEndTitle(Object name) {
    return 'إنهاء $name؟';
  }

  @override
  String get monthlyExpensesEndBody =>
      'لن يصبح مستحقاً بعد الآن. تبقى المدفوعات السابقة مسجلة كما هي.';

  @override
  String get monthlyExpensesEndConfirm => 'إنهاؤه';

  @override
  String get monthlyExpensesStatusUpdated => 'تم تحديث الحالة';

  @override
  String get monthlyExpensesReadOnlyNotice =>
      'يمكنك عرض هذا الشهر دون تعديل سجل المصروفات.';

  @override
  String get monthlyExpensesFormMissingOptions =>
      'لم يرسل الخادم التصنيفات والتكرارات والحسابات التي يحتاجها هذا النموذج.';

  @override
  String get monthlyExpensesSalarySlipBadge => 'قسيمة راتب';

  @override
  String get monthlyExpensesGrossLabel => 'الراتب قبل الخصم';

  @override
  String get monthlyExpensesPenaltyLabel => 'جزاء';

  @override
  String get monthlyExpensesAdvanceLabel => 'سلفة';

  @override
  String get monthlyExpensesJarsLabel => 'طلبات';

  @override
  String get monthlyExpensesNetPayableLabel => 'الصافي المستحق';

  @override
  String monthlyExpensesDeductionAmount(Object amount) {
    return '− $amount';
  }

  @override
  String monthlyExpensesDeductionsSummary(Object total, Object net) {
    return 'الخصومات $total • الصافي المطلوب تسليمه $net';
  }

  @override
  String monthlyExpensesOutstandingOf(Object outstanding, Object amount) {
    return 'متبقٍ $outstanding من $amount';
  }

  @override
  String get monthlyExpensesOffPayrollBadge => 'خارج كشف الرواتب';

  @override
  String get monthlyExpensesOffPayrollExplain =>
      'لا يوجد هيكل رواتب لهذا الشهر. يظهر هذا الصف لأن على الموظف سلفة أو طلبات أو جزاءات.';

  @override
  String monthlyExpensesSalariesForMonth(Object month, Object payMonth) {
    return 'مرتبات $month · تُصرف في $payMonth';
  }

  @override
  String monthlyExpensesPaySalaryPeriod(Object month) {
    return 'مرتب شهر $month';
  }

  @override
  String monthlyExpensesLeftStaffTitle(int count) {
    return 'موظفون تركوا العمل – عليهم مبالغ ($count)';
  }

  @override
  String get monthlyExpensesLeftStaffHint =>
      'ليسوا ضمن مرتبات هذا الشهر. يظهرون فقط لأن عليهم سلفة أو طلبات لم تُسدَّد.';

  @override
  String monthlyExpensesLeftOn(Object date) {
    return 'ترك العمل في $date';
  }

  @override
  String get monthlyExpensesPenaltiesTitle => 'الجزاءات';

  @override
  String get monthlyExpensesAdvancesTitle => 'السلف';

  @override
  String get monthlyExpensesOrdersTitle => 'طلبات الموظفين';

  @override
  String monthlyExpensesPenaltyDaysAmount(Object days) {
    return '$days يوم';
  }

  @override
  String monthlyExpensesPenaltyEquals(Object value) {
    return '= $value';
  }

  @override
  String get monthlyExpensesPenaltyAddAction => 'إضافة جزاء';

  @override
  String monthlyExpensesPenaltyTitle(Object name) {
    return 'جزاء على $name';
  }

  @override
  String get monthlyExpensesPenaltyUnitDays => 'أيام';

  @override
  String get monthlyExpensesPenaltyUnitHalfDays => 'أنصاف أيام';

  @override
  String get monthlyExpensesPenaltyUnitMoney => 'مبلغ';

  @override
  String get monthlyExpensesPenaltyDaysLabel => 'عدد الأيام';

  @override
  String get monthlyExpensesPenaltyHalfDaysLabel => 'عدد أنصاف الأيام';

  @override
  String get monthlyExpensesPenaltyAmountLabel => 'قيمة الجزاء';

  @override
  String get monthlyExpensesPenaltyQuantityInvalid => 'أدخل رقماً أكبر من صفر';

  @override
  String get monthlyExpensesPenaltyReasonLabel => 'السبب';

  @override
  String get monthlyExpensesPenaltyReasonRequired =>
      'اذكر سبب توقيع هذا الجزاء';

  @override
  String get monthlyExpensesPenaltyDateLabel => 'تاريخ الجزاء';

  @override
  String get monthlyExpensesPenaltySubmit => 'حفظ الجزاء';

  @override
  String monthlyExpensesPenaltyDayRateHint(Object amount, Object days) {
    return 'قيمة اليوم $amount — الراتب الشهري ÷ $days';
  }

  @override
  String get monthlyExpensesPenaltyNoDayRate =>
      'هذا الموظف بلا هيكل رواتب، لذلك لا قيمة لليوم هنا. أدخل الجزاء كمبلغ.';

  @override
  String get monthlyExpensesPenaltyRecorded => 'تم تسجيل الجزاء';

  @override
  String get monthlyExpensesPenaltyCancelAction => 'إلغاء الجزاء';

  @override
  String get monthlyExpensesPenaltyCancelTitle => 'إلغاء هذا الجزاء؟';

  @override
  String monthlyExpensesPenaltyCancelBody(Object amount) {
    return 'سيُرفع جزاء $amount من الراتب. لا يمكن التراجع عن ذلك؛ سجّل جزاءً جديداً إذا كان ما زال مستحقاً.';
  }

  @override
  String get monthlyExpensesPenaltyCancelHint => 'ما سبب الإلغاء؟';

  @override
  String get monthlyExpensesPenaltyCancelConfirm => 'إلغاء الجزاء';

  @override
  String get monthlyExpensesPenaltyCancelled => 'تم إلغاء الجزاء';

  @override
  String get monthlyExpensesPenaltySettledBadge => 'مُسوّى';

  @override
  String get monthlyExpensesSettleAdvancesTitle => 'سلف يتم تسويتها';

  @override
  String get monthlyExpensesSettleOrdersTitle => 'طلبات موظفين يتم تسويتها';

  @override
  String get monthlyExpensesSettleHint =>
      'الأرصدة المحددة تُسوّى بهذه الدفعة، بالإضافة إلى النقدية.';

  @override
  String get monthlyExpensesCashToHandOver => 'النقدية المسلَّمة';

  @override
  String get monthlyExpensesTotalDischarged => 'إجمالي ما يتم سداده';

  @override
  String get monthlyExpensesPayAmountOrSettlement =>
      'أدخل مبلغاً أو حدد رصيداً لتسويته';

  @override
  String get monthlyExpensesGapsInfoTitle => 'للعلم';

  @override
  String get paymentMethodCredit => 'آجل (على الحساب)';

  @override
  String get paymentMethodCreditSubtitle => 'يتسلم دلوقتي ويدفع بعدين';

  @override
  String get paymentMethodCreditNotAllowed => 'العميل ده مش معتمد للبيع الآجل';

  @override
  String get paymentMethodCreditChecking => 'بنراجع حساب العميل الآجل…';

  @override
  String get paymentMethodCreditUnavailable =>
      'تعذر مراجعة الحساب الآجل للعميل دلوقتي';

  @override
  String paymentMethodCreditAvailable(Object amount) {
    return 'الآجل المتاح: $amount';
  }

  @override
  String get paymentMethodCreditNoLimit => 'مفيش حد ائتماني متسجل';

  @override
  String paymentMethodCreditTerms(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوم واحد',
    );
    return 'الاستحقاق خلال $_temp0';
  }

  @override
  String paymentMethodCreditOnAccount(Object amount) {
    return 'المسجل على الحساب: $amount';
  }

  @override
  String get paymentMethodCreditOverLimit =>
      'العميل ده استهلك كل الآجل المتاح ليه';

  @override
  String get menuCreditAccounts => 'الحسابات الآجلة';

  @override
  String get creditAccountsTitle => 'الحسابات الآجلة';

  @override
  String get creditAccountsSubtitle =>
      'المحلات اللي عليها رصيد مفتوح، الأكبر الأول';

  @override
  String get creditAccountsPeriodLabel => 'الفترة';

  @override
  String get creditAccountsWindow30 => 'آخر 30 يوم';

  @override
  String get creditAccountsWindow90 => 'آخر 90 يوم';

  @override
  String get creditAccountsWindow180 => 'آخر 180 يوم';

  @override
  String get creditAccountsWindow365 => 'آخر 365 يوم';

  @override
  String get creditAccountsTotalOutstanding =>
      'إجمالي المستحق على الحساب في الفترة دي';

  @override
  String get creditAccountsTotalOutstandingAllTime =>
      'إجمالي المستحق على الحساب (كل الفترات)';

  @override
  String get creditAccountsAllTimeHint =>
      'كل الفواتير المفتوحة مهما كان تاريخها. الفترة تحت بتحدد الفواتير المعروضة بس.';

  @override
  String creditAccountsCustomerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محل عليهم مستحقات',
      few: '$count محلات عليهم مستحقات',
      two: 'محلين عليهم مستحقات',
      one: 'محل واحد عليه مستحقات',
      zero: 'مفيش محل عليه مستحقات',
    );
    return '$_temp0';
  }

  @override
  String creditAccountsListedInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فاتورة معروضة',
      few: '$count فواتير معروضة',
      two: 'فاتورتين معروضين',
      one: 'فاتورة واحدة معروضة',
      zero: 'مفيش فواتير معروضة',
    );
    return '$_temp0';
  }

  @override
  String creditAccountsActivityRange(Object from, Object to) {
    return 'الفواتير المعروضة: من $from إلى $to';
  }

  @override
  String get creditAccountsEmpty => 'مفيش محل عليه رصيد آجل مفتوح';

  @override
  String get creditAccountsLoadFailed => 'تعذر تحميل الحسابات الآجلة';

  @override
  String get creditAccountsNoticeResultsTruncated =>
      'بتتعرض أول النتائج بس. ضيق الفرع أو الفترة عشان تشوف الباقي.';

  @override
  String creditAccountsOpenInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فاتورة مفتوحة',
      few: '$count فواتير مفتوحة',
      two: 'فاتورتين مفتوحين',
      one: 'فاتورة واحدة مفتوحة',
      zero: 'مفيش فواتير مفتوحة',
    );
    return '$_temp0';
  }

  @override
  String creditAccountsOldestAge(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'من $days يوم',
      few: 'من $days أيام',
      two: 'من يومين',
      one: 'من يوم',
      zero: 'النهارده',
    );
    return 'أقدم فاتورة $_temp0';
  }

  @override
  String get creditAccountsOldestUnknown => 'أقدم فاتورة من غير تاريخ';

  @override
  String get creditAccountBalanceLabel => 'الرصيد على الحساب';

  @override
  String get creditAccountOpenInvoicesTitle =>
      'الفواتير المفتوحة، الأقدم الأول';

  @override
  String get creditAccountInvoiceOutstandingLabel => 'المستحق';

  @override
  String get creditAccountInvoiceTotalLabel => 'إجمالي الفاتورة';

  @override
  String creditAccountInvoiceAge(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'من $days يوم',
      few: 'من $days أيام',
      two: 'من يومين',
      one: 'من يوم',
      zero: 'النهارده',
    );
    return '$_temp0';
  }

  @override
  String get creditAccountNoInvoicesInWindow =>
      'مفيش فواتير معروضة في الفترة دي. الرصيد فوق أقدم من كده، فوسع الفترة عشان تشوف الفواتير اللي وراه.';

  @override
  String get creditAccountRecordPayment => 'تسجيل دفعة';

  @override
  String creditAccountTerms(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوم واحد',
    );
    return 'المهلة: $_temp0';
  }

  @override
  String creditAccountLimit(Object amount) {
    return 'الحد الائتماني $amount';
  }

  @override
  String creditAccountAvailable(Object amount) {
    return 'المتاح $amount';
  }

  @override
  String get creditSendToCustomer => 'إرسال للعميل';

  @override
  String get creditSendModeIndividual => 'إيصالات منفصلة';

  @override
  String get creditSendModeConsolidated => 'كشف حساب مجمّع';

  @override
  String get creditSendModeIndividualHint => 'إيصال لكل طلب تختاره.';

  @override
  String get creditSendModeConsolidatedHint =>
      'كل الطلبات اللي تختارها في كشف واحد بإجمالي المستحق.';

  @override
  String get creditSendSelectAll => 'تحديد الكل';

  @override
  String creditSendSelectedCount(int selected, int total) {
    return '$selected من $total متحدد';
  }

  @override
  String creditSendTotalDue(String amount) {
    return 'إجمالي المستحق: $amount';
  }

  @override
  String get creditSendWhatsApp => 'واتساب';

  @override
  String get creditSendShare => 'مشاركة';

  @override
  String get creditSendLoadFailed => 'مقدرناش نحمّل الطلبات. حاول تاني.';

  @override
  String get creditAccountFifoHint => 'الدفعة بتقفل أقدم الفواتير الأول.';

  @override
  String get creditPaymentTitle => 'تسجيل دفعة';

  @override
  String get creditPaymentAmountLabel => 'المبلغ';

  @override
  String creditPaymentFullBalanceHint(Object amount) {
    return 'الرصيد بالكامل $amount';
  }

  @override
  String get creditPaymentMethodLabel => 'مدفوعة بـ';

  @override
  String get creditPaymentBranchLabel => 'الفرع';

  @override
  String get creditPaymentBranchMissing => 'اختار الفرع اللي استلم الفلوس';

  @override
  String get creditPaymentBranchLoadFailed => 'تعذر تحميل الفروع';

  @override
  String get creditPaymentRemarksLabel => 'ملاحظة (اختياري)';

  @override
  String get creditPaymentSubmit => 'تسجيل الدفعة';

  @override
  String get creditPaymentAmountInvalid => 'اكتب مبلغ أكبر من صفر';

  @override
  String get creditPaymentAmountExceedsBalance =>
      'أكبر من الرصيد. الزيادة هتفضل رصيد مقدم للعميل.';

  @override
  String get creditPaymentFailed => 'تعذر تسجيل الدفعة';

  @override
  String get creditPaymentFifoNotice =>
      'المبلغ بيتوزع على أقدم الفواتير الأول، فممكن ميقفلش الفواتير اللي متوقعها.';

  @override
  String get creditSettingsTitle => 'حساب الآجل';

  @override
  String get creditSettingsAllowed => 'مسموح بالطلب آجل';

  @override
  String get creditSettingsNotAllowed => 'الآجل مش مسموح';

  @override
  String get creditSettingsAllowSwitch => 'السماح بالطلب آجل';

  @override
  String get creditSettingsDaysLabel => 'أيام الآجل';

  @override
  String get creditSettingsDaysHelper => '0 يعني الافتراضي 30 يوم';

  @override
  String get creditSettingsLimitLabel => 'حد الآجل';

  @override
  String get creditSettingsLimitHelper => 'سيبه فاضي أو 0 لو من غير حد';

  @override
  String get creditSettingsNoLimit => 'من غير حد';

  @override
  String get creditSettingsEdit => 'تعديل الآجل';

  @override
  String get creditSettingsSaved => 'اتحفظت إعدادات الآجل';

  @override
  String get creditSettingsSaveFailed => 'تعذر حفظ إعدادات الآجل';

  @override
  String get creditSettingsDaysInvalid => 'اكتب أيام من 0 لـ 365';

  @override
  String get creditSettingsLimitInvalid => 'اكتب حد 0 أو أكتر';

  @override
  String creditSettingsOffWithBalance(Object amount) {
    return 'الآجل اتقفل للطلبات الجديدة. لسه عليه $amount وتقدر تحصلها.';
  }

  @override
  String get creditAccountPayInvoice => 'ادفع الأوردر ده';

  @override
  String creditPaymentTargetInvoice(Object invoice) {
    return 'للأوردر $invoice';
  }

  @override
  String creditPaymentTargetOutstandingHint(Object amount) {
    return 'المتبقي على الأوردر ده $amount';
  }

  @override
  String get creditPaymentTargetNotice =>
      'المبلغ بيروح للأوردر ده الأول، وأي زيادة بتقفل أقدم الأوردرات المفتوحة.';

  @override
  String get creditPaymentResultTitle => 'تم تسجيل الدفعة';

  @override
  String creditPaymentResultCleared(int count, Object amount, Object invoices) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount قفلت فواتير $invoices',
      two: '$amount قفلت فاتورتين $invoices',
      one: '$amount قفلت فاتورة $invoices',
    );
    return '$_temp0';
  }

  @override
  String creditPaymentResultPartial(Object amount, Object invoice) {
    return '$amount راحت لفاتورة $invoice ولسه مفتوحة جزئياً';
  }

  @override
  String creditPaymentResultAdvance(Object amount) {
    return '$amount فضلت رصيد مقدم';
  }

  @override
  String creditPaymentResultNoneAllocated(Object amount) {
    return 'مكانش فيه فواتير مفتوحة، فالمبلغ كله $amount فضل رصيد مقدم';
  }

  @override
  String creditPaymentResultRemaining(Object amount) {
    return 'لسه على الحساب: $amount';
  }

  @override
  String creditPaymentResultEntry(Object name) {
    return 'سند القبض $name';
  }

  @override
  String creditListJoin(Object first, Object last) {
    return '$first و$last';
  }

  @override
  String get creditAccountBranchScopeNote =>
      'الرصيد ده بيغطي الفروع اللي بتشوفها. الدفعة بتقفل أقدم فواتير المحل الأول في كل الفروع، فممكن تقفل فواتير مش معروضة هنا.';

  @override
  String get creditAccountNoOpenInvoices => 'مفيش فواتير مفتوحة للمحل ده.';

  @override
  String creditPaymentResultAlreadyRecorded(Object amount) {
    return 'الدفعة دي كانت اتسجلت قبل كده. مبلغ $amount دخل قبل كده ومحصلش تسجيل تاني.';
  }

  @override
  String get creditPaymentResultAlreadyRecordedHint =>
      'حدّث الحساب عشان تشوف الرصيد بعدها.';

  @override
  String get creditPaymentResultAlreadyRecordedTitle => 'الدفعة مسجلة قبل كده';

  @override
  String get menuReplenishment => 'تسليم للفروع';

  @override
  String get replenishmentTitle => 'تسليم للفروع';

  @override
  String replenishmentBasis(int coverDays, int salesDays) {
    return 'تغطية $coverDays يوم، محسوبة من مبيعات آخر $salesDays يوم';
  }

  @override
  String replenishmentSourceLine(String warehouse) {
    return 'من $warehouse';
  }

  @override
  String replenishmentGeneratedOn(String when) {
    return 'اتحسب $when';
  }

  @override
  String get replenishmentBranchLabel => 'الفرع';

  @override
  String replenishmentBranchOption(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صنف ناقص',
      few: '$count أصناف ناقصة',
      two: 'صنفين ناقصين',
      one: 'صنف ناقص',
      zero: 'مغطّى',
    );
    return '$name · $_temp0';
  }

  @override
  String replenishmentBelowCoverCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صنف تحت التغطية',
      few: '$count أصناف تحت التغطية',
      two: 'صنفين تحت التغطية',
      one: 'صنف واحد تحت التغطية',
      zero: 'مفيش حاجة تحت التغطية',
    );
    return '$_temp0';
  }

  @override
  String replenishmentBranchCovered(String name) {
    return '$name عنده كفاية من كل حاجة دلوقتي';
  }

  @override
  String replenishmentNegativeBinsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صنف رصيده بالسالب',
      few: '$count أصناف رصيدها بالسالب',
      two: 'صنفين رصيدهم بالسالب',
      one: 'صنف رصيده بالسالب',
    );
    return '$_temp0';
  }

  @override
  String replenishmentTotalShort(String qty) {
    return 'المصنع ناقصه $qty على كل الفروع';
  }

  @override
  String replenishmentOnHand(String qty) {
    return 'عنده $qty';
  }

  @override
  String replenishmentPerDay(String rate) {
    return 'بيبيع $rate في اليوم';
  }

  @override
  String replenishmentDaysOfCover(String days) {
    return 'تغطية $days يوم';
  }

  @override
  String get replenishmentNoSalesYet => 'لسه مفيش مبيعات';

  @override
  String get replenishmentNegativeStock => 'الرصيد بالسالب، اعمل جرد للصنف ده';

  @override
  String replenishmentFactoryHas(String qty) {
    return 'المصنع عنده $qty';
  }

  @override
  String replenishmentShortBy(String qty) {
    return 'المصنع مش مغطي ده — ناقص $qty';
  }

  @override
  String get replenishmentQtyLabel => 'ابعت';

  @override
  String replenishmentTypedTotal(int lineCount, String totalQty) {
    String _temp0 = intl.Intl.pluralLogic(
      lineCount,
      locale: localeName,
      other: '$lineCount سطر',
      few: '$lineCount سطور',
      two: 'سطرين',
      one: 'سطر واحد',
    );
    return '$_temp0 · $totalQty قطعة';
  }

  @override
  String replenishmentSendAction(String name) {
    return 'ابعت لـ $name';
  }

  @override
  String replenishmentConfirmTitle(String name) {
    return 'تبعت لـ $name؟';
  }

  @override
  String replenishmentConfirmBody(
    int lineCount,
    String totalQty,
    String source,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      lineCount,
      locale: localeName,
      other: '$lineCount سطر',
      few: '$lineCount سطور',
      two: 'سطرين',
      one: 'سطر واحد',
    );
    return '$_temp0 · $totalQty قطعة، من $source';
  }

  @override
  String get replenishmentConfirmAction => 'ابعت';

  @override
  String replenishmentSentTitle(String name) {
    return 'اتبعت لـ $name';
  }

  @override
  String replenishmentSentBody(
    int lineCount,
    String totalQty,
    String stockEntry,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      lineCount,
      locale: localeName,
      other: '$lineCount سطر',
      few: '$lineCount سطور',
      two: 'سطرين',
      one: 'سطر واحد',
    );
    return '$_temp0 · $totalQty قطعة · قيد $stockEntry';
  }

  @override
  String replenishmentSendFailed(String name, String reason) {
    return 'مقدرناش نبعت لـ $name: $reason';
  }

  @override
  String replenishmentFailedLine(String item) {
    return 'السطر اللي السيرفر رفضه: $item';
  }

  @override
  String get replenishmentNumbersKept =>
      'الكميات لسه على الشاشة — صلّح السبب وابعت تاني.';

  @override
  String get replenishmentNothingToSend => 'اكتب كمية الأول.';

  @override
  String get replenishmentEmptyTitle => 'مفيش حاجة تتبعت';

  @override
  String get replenishmentEmptyNoBranches =>
      'مفيش فروع بيع لسه. الفرع بيظهر هنا أول ما يبقى ليه POS profile.';

  @override
  String get replenishmentLoadFailed => 'مقدرناش نحمّل المطلوب إرساله';

  @override
  String get replenishmentNotAllowed => 'معندكش صلاحية تبعت مخزون.';

  @override
  String get replenishmentRefresh => 'تحديث';

  @override
  String get menuProductionRound => 'دورة الإنتاج';

  @override
  String get productionRoundTitle => 'دورة الإنتاج';

  @override
  String get productionRoundRefresh => 'تحديث';

  @override
  String get productionRoundTune => 'إعدادات الحساب';

  @override
  String get productionRoundOpenFromSend => 'المطلوب إنتاجه';

  @override
  String get productionRoundNotAllowed => 'مش عندك صلاحية تخطيط الإنتاج.';

  @override
  String get productionRoundLoadFailed => 'مقدرناش نحمّل دورة الإنتاج';

  @override
  String get productionRoundRefreshFailed =>
      'مقدرناش نحدّث — دي آخر أرقام اتحسبت.';

  @override
  String get productionRoundSizeSmall => 'صغير';

  @override
  String get productionRoundSizeMedium => 'وسط';

  @override
  String get productionRoundSizeLarge => 'كبير';

  @override
  String productionRoundBatchOne(String value) {
    return '$value تشغيلة';
  }

  @override
  String productionRoundBatches(String value) {
    return '$value تشغيلة';
  }

  @override
  String productionRoundJars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count برطمان',
      few: '$count برطمانات',
      two: 'برطمانين',
      one: 'برطمان واحد',
      zero: '0 برطمان',
    );
    return '$_temp0';
  }

  @override
  String productionRoundNeededNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صنف مطلوب حالًا',
      few: '$count أصناف مطلوبة حالًا',
      two: 'صنفين مطلوبين حالًا',
      one: 'صنف مطلوب حالًا',
    );
    return '$_temp0';
  }

  @override
  String productionRoundMissingMaterials(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خامة ناقصة',
      few: '$count خامات ناقصة',
      two: 'خامتين ناقصين',
      one: 'خامة واحدة ناقصة',
    );
    return '$_temp0';
  }

  @override
  String productionRoundBlockedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صنف واقف على خامات',
      few: '$count أصناف واقفة على خامات',
      two: 'صنفين واقفين على خامات',
      one: 'صنف واقف على خامات',
    );
    return '$_temp0';
  }

  @override
  String productionRoundCoverDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يغطي $count يوم',
      few: 'يغطي $count أيام',
      two: 'يغطي يومين',
      one: 'يغطي يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String productionRoundBackupDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count يوم احتياطي',
      few: '+ $count أيام احتياطي',
      two: '+ يومين احتياطي',
      one: '+ يوم احتياطي',
    );
    return '$_temp0';
  }

  @override
  String productionRoundSalesWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مبيعات آخر $count أسبوع',
      few: 'مبيعات آخر $count أسابيع',
      two: 'مبيعات آخر أسبوعين',
      one: 'مبيعات آخر أسبوع',
    );
    return '$_temp0';
  }

  @override
  String productionRoundUpdatedAt(String time) {
    return 'اتحدّث $time';
  }

  @override
  String productionRoundNotices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملاحظة',
      few: '$count ملاحظات',
      two: 'ملاحظتين',
      one: 'ملاحظة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get productionRoundNoticesTitle => 'ملاحظات';

  @override
  String get productionRoundTabMake => 'الإنتاج';

  @override
  String get productionRoundTabMaterials => 'الخامات';

  @override
  String get productionRoundTabBranches => 'الفروع';

  @override
  String get productionRoundEmptyTitle => 'مفيش إنتاج مطلوب';

  @override
  String get productionRoundEmptyBody =>
      'كل الفروع عندها كفاية للدورة كلها والاحتياطي.';

  @override
  String get productionRoundNoItems =>
      'مفيش أصناف ليها مبيعات أو رصيد نخطط على أساسها لسه.';

  @override
  String get productionRoundNothingInSize => 'مفيش حاجة تتعمل في الحجم ده.';

  @override
  String productionRoundCoveredGroup(int count) {
    return 'متغطي ($count)';
  }

  @override
  String get productionRoundStatusNow => 'مطلوب حالًا';

  @override
  String get productionRoundStatusRound => 'في الدورة دي';

  @override
  String get productionRoundStatusCovered => 'متغطي';

  @override
  String get productionRoundStatusNoSales => 'مفيش مبيعات';

  @override
  String get productionRoundBlockedTooltip => 'مستني خامة ناقصة';

  @override
  String get productionRoundBlockedBy => 'واقف على:';

  @override
  String productionRoundMissingQty(String name, String qty) {
    return '$name (ناقص $qty)';
  }

  @override
  String productionRoundSellsPerWeek(String rate) {
    return 'بيبيع $rate في الأسبوع';
  }

  @override
  String productionRoundBranchesNeed(String qty) {
    return 'الفروع محتاجة $qty';
  }

  @override
  String productionRoundFactoryHas(String qty) {
    return 'المصنع عنده $qty';
  }

  @override
  String productionRoundNetNeed(String qty) {
    return 'الصافي المطلوب $qty';
  }

  @override
  String get productionRoundNoBranchRows => 'مفيش أرقام فروع للصنف ده.';

  @override
  String get productionRoundColBranch => 'الفرع';

  @override
  String get productionRoundColSells => 'بيع/أسبوع';

  @override
  String get productionRoundColTarget => 'المستهدف';

  @override
  String get productionRoundColHas => 'عنده';

  @override
  String get productionRoundColNeeds => 'محتاج';

  @override
  String productionRoundDaysLeft(String days) {
    return 'يكفي $days يوم';
  }

  @override
  String get productionRoundCountFirst => 'بالسالب — اعمل جرد الأول';

  @override
  String get productionRoundMakeFirst => 'اعمل الأول';

  @override
  String productionRoundPrepStored(String batches, String qty) {
    return '$batches ($qty)';
  }

  @override
  String productionRoundPrepFresh(String batches) {
    return 'طازة، $batches';
  }

  @override
  String productionRoundFilterMissing(int count) {
    return 'الناقص ($count)';
  }

  @override
  String productionRoundFilterAll(int count) {
    return 'الكل ($count)';
  }

  @override
  String productionRoundNeedHave(String need, String have) {
    return 'محتاج $need · موجود $have';
  }

  @override
  String productionRoundShort(String qty) {
    return 'ناقص $qty';
  }

  @override
  String productionRoundAlternative(String qty) {
    return '+$qty في البدائل';
  }

  @override
  String get productionRoundNothingMissing => 'كل الخامات موجودة.';

  @override
  String get productionRoundNoMaterials => 'مفيش خامات للمراجعة.';

  @override
  String get productionRoundNoBranches => 'مفيش فروع بيع لسه.';

  @override
  String productionRoundBranchHolds(String has, String target) {
    return 'عنده $has من $target مستهدف';
  }

  @override
  String productionRoundBranchNeeds(String qty) {
    return 'محتاج $qty';
  }

  @override
  String productionRoundBelowBackup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صنف تحت الاحتياطي',
      few: '$count أصناف تحت الاحتياطي',
      two: 'صنفين تحت الاحتياطي',
      one: 'صنف تحت الاحتياطي',
    );
    return '$_temp0';
  }

  @override
  String get productionRoundTuneTitle => 'إعدادات الحساب';

  @override
  String get productionRoundTuneCycle => 'الأيام بين كل توريدة';

  @override
  String get productionRoundTuneBackup => 'أيام الاحتياطي';

  @override
  String get productionRoundTuneSales => 'فترة المبيعات';

  @override
  String productionRoundDaysValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      few: '$count أيام',
      two: 'يومين',
      one: 'يوم',
      zero: 'من غير',
    );
    return '$_temp0';
  }

  @override
  String productionRoundWeeksValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أسبوع',
      few: '$count أسابيع',
      two: 'أسبوعين',
      one: 'أسبوع',
    );
    return '$_temp0';
  }

  @override
  String get productionRoundTuneHint =>
      'أحجام التشغيلة جاية من الوصفات ومش بتتغير من هنا.';

  @override
  String get productionRoundTuneReset => 'رجّع الافتراضي';

  @override
  String get settingsBackgroundDeliveryTitle => 'استقبال الطلبات في الخلفية';

  @override
  String get settingsBackgroundDeliveryOk =>
      'الهاتف ده هيستقبل تنبيهات الطلبات والتطبيق مقفول.';

  @override
  String get settingsBackgroundDeliveryWarning =>
      'أندرويد ممكن ينيّم التطبيق، ووقتها تنبيهات الطلبات مش بتوصل خالص — ولا حتى بدون صوت.';

  @override
  String get settingsBackgroundDeliveryFix => 'اسمح بالعمل في الخلفية';

  @override
  String get settingsBackgroundDeliveryOpenSettings => 'افتح إعدادات التطبيق';

  @override
  String get settingsBackgroundDeliveryHint =>
      'في سامسونج، اقفل كمان خيار «تنويم التطبيقات غير المستخدمة» لتطبيق Jarz POS من إعدادات البطارية.';

  @override
  String get settingsBackgroundDeliveryNoScreen =>
      'تعذّر فتح الشاشة. افتح الإعدادات > التطبيقات > Jarz POS > البطارية واسمح بالعمل في الخلفية.';

  @override
  String get rosterLegendProblemsTitle => 'يحتاج إلى إصلاح';

  @override
  String get rosterLegendTextTitle => 'مكتوب في الخانة';

  @override
  String get rosterLegendMarkersTitle => 'علامات';

  @override
  String get rosterLegendWorkingTime => 'عمل — وقت بداية ونهاية الوردية';

  @override
  String get rosterTimeAmShort => 'ص';

  @override
  String get rosterTimePmShort => 'م';

  @override
  String get rosterNotSetShort => 'غير محدد';

  @override
  String get rosterLegendOffCovered => 'إجازة — مُغطّاة';

  @override
  String get rosterLegendOffUncovered => 'إجازة — لا أحد يغطيها';

  @override
  String get rosterLegendNotRosteredFuture =>
      'لم تُحدد وردية بعد — لا يمكنه تسجيل الحضور';

  @override
  String get rosterLegendNotRosteredPast => 'لا يوجد سجل (يوم مضى)';

  @override
  String get rosterLegendMarkerOvertime => 'أطول من اليوم العادي';

  @override
  String get rosterLegendMarkerCover => 'يُغطّي زميلاً';

  @override
  String get rosterLegendMarkerHolidayWorked => 'عمل في عطلة رسمية';

  @override
  String get rosterLegendMarkerWeekend => 'نهاية الأسبوع (الجمعة والسبت)';

  @override
  String get rosterLegendMarkerSelected => 'مُحدد لتعديل جماعي';

  @override
  String get rosterOnDutyRow => 'في الخدمة';

  @override
  String rosterOnDutyRowBranch(String branch) {
    return 'في الخدمة · $branch';
  }

  @override
  String get rosterBranchUnknown => 'بدون فرع';

  @override
  String get rosterUnrosteredPast => 'لم تُسند أي وردية في هذا اليوم.';

  @override
  String rosterCoveringFor(String name) {
    return 'يُغطّي عن $name';
  }

  @override
  String rosterAboveNormalDay(String hours, String standard) {
    return '$hours ساعة — أطول من اليوم العادي $standard ساعة';
  }

  @override
  String get menuAttendance => 'الحضور والانصراف';

  @override
  String get attendanceTitle => 'الحضور والانصراف';

  @override
  String get attendanceTabMonth => 'الشهر';

  @override
  String get attendanceTabDay => 'اليوم';

  @override
  String get attendanceTabEmployee => 'الموظف';

  @override
  String get attendanceTabSummary => 'الملخص';

  @override
  String get attendanceAccessDenied => 'ليس لديك صلاحية الاطلاع على الحضور';

  @override
  String get attendanceAccessDeniedHint =>
      'هذه الشاشة لمديري الفروع والمشرفين. اطلب من المسؤول إضافة الصلاحية إلى حسابك.';

  @override
  String get attendanceLoadFailedHint =>
      'حاول مرة أخرى. إذا تكرر الخطأ، أبلغ المسؤول بالوقت الذي ظهرت فيه الرسالة.';

  @override
  String get attendanceHrmsMissing => 'بيانات الحضور غير متاحة على هذا الموقع.';

  @override
  String get attendanceScopeEmpty => 'لا يوجد فرع مرتبط بحسابك';

  @override
  String get attendanceScopeEmptyHint =>
      'حسابك مقيّد بقائمة فروع فارغة، لذلك لا يوجد ما يُعرض. اطلب من المسؤول تحديد فروعك.';

  @override
  String get attendanceNobodyRostered => 'لا يوجد أحد على الجدول في هذه الفترة';

  @override
  String get attendanceNobodyRosteredHint =>
      'راجع الشهر والفترة والفرع المختار.';

  @override
  String get attendanceNoCheckins => 'لا توجد أي تسجيلات حضور في هذه الفترة';

  @override
  String get attendanceNoCheckinsHint =>
      'الأيام التي تظهر كغياب تعني أنه لم يُسجَّل حضور، وليس بالضرورة أن الموظف لم يحضر.';

  @override
  String get attendanceNoBranchResolved => 'فرع غير محدد';

  @override
  String get attendanceNoBranchResolvedHint =>
      'لم يتمكن النظام من ربط هؤلاء بفرع في هذا اليوم.';

  @override
  String get attendanceBranchNobodyRostered =>
      'لا يوجد أحد على الجدول في هذا الفرع';

  @override
  String get attendanceEmployeeColumn => 'الموظف';

  @override
  String get attendanceAllBranches => 'كل الفروع';

  @override
  String get attendancePreviousPeriod => 'السابق';

  @override
  String get attendanceNextPeriod => 'التالي';

  @override
  String get attendanceToday => 'اليوم';

  @override
  String get attendanceFromDate => 'من';

  @override
  String get attendanceToDate => 'إلى';

  @override
  String get attendanceThisMonth => 'هذا الشهر';

  @override
  String get attendanceWholeDay => 'اليوم كله';

  @override
  String get attendanceLegendTitle => 'دليل الألوان';

  @override
  String get attendanceScheduled => 'المجدول';

  @override
  String get attendanceActual => 'الفعلي';

  @override
  String get attendanceLateBy => 'مقدار التأخير';

  @override
  String get attendanceEarlyBy => 'مقدار الحضور المبكر';

  @override
  String get attendanceMinutesUnit => 'دقيقة';

  @override
  String get attendanceMinutesLateShort => 'دقيقة تأخير';

  @override
  String get attendanceHoursUnit => 'ساعة';

  @override
  String get attendanceWorkedHours => 'ساعات العمل';

  @override
  String get attendanceCheckinCount => 'عدد التسجيلات';

  @override
  String get attendanceGeoLabel => 'الموقع';

  @override
  String get attendanceGeoInside => 'داخل نطاق الفرع';

  @override
  String get attendanceGeoOutside => 'خارج نطاق الفرع';

  @override
  String get attendanceGeoUnknown => 'لم يُسجَّل موقع';

  @override
  String get attendanceOffshiftLabel => 'وقت الوردية';

  @override
  String get attendanceOffshiftValue => 'خارج وقت الوردية';

  @override
  String get attendanceShiftType => 'الوردية';

  @override
  String get attendanceBranch => 'الفرع';

  @override
  String get attendanceCoverDay => 'تغطية';

  @override
  String get attendanceCoverDayValue => 'بديل عن زميل';

  @override
  String get attendanceOffType => 'نوع الإجازة';

  @override
  String get attendanceCoveredBy => 'يغطيه';

  @override
  String get attendanceNobodyCovering => 'لا أحد';

  @override
  String get attendanceNotRosteredThisMonth => 'غير مجدول';

  @override
  String get attendancePickEmployee => 'اختر موظفًا';

  @override
  String get attendanceNoEmployeesToPick => 'لا يوجد موظفون للعرض';

  @override
  String get attendanceNoEmployeesToPickHint =>
      'القائمة مأخوذة من تبويب الشهر. غيّر الشهر أو الفرع من هناك.';

  @override
  String get attendanceByBranchTitle => 'حسب الفرع';

  @override
  String get attendanceByBranchEmpty =>
      'لا يوجد توزيع على الفروع في هذه الفترة.';

  @override
  String get attendanceTimelineTitle => 'يومًا بيوم';

  @override
  String get attendanceTimelineEmpty => 'لا توجد أيام في هذه الفترة.';

  @override
  String get attendanceCheckinsTitle => 'تسجيلات الحضور';

  @override
  String get attendanceCheckinsEmpty => 'لا توجد تسجيلات حضور في هذه الفترة.';

  @override
  String get attendanceGroupByBranch => 'الفرع';

  @override
  String get attendanceGroupByEmployee => 'الموظف';

  @override
  String get attendanceGroupByDay => 'اليوم';

  @override
  String get attendanceColumnGroup => 'المجموعة';

  @override
  String get attendanceTotalsRow => 'الإجمالي';

  @override
  String get attendanceMetricRostered => 'مجدول';

  @override
  String get attendanceMetricPresent => 'حاضر';

  @override
  String get attendanceMetricLate => 'متأخر';

  @override
  String get attendanceMetricAbsent => 'غائب';

  @override
  String get attendanceMetricPending => 'منتظر';

  @override
  String get attendanceMetricOff => 'إجازة';

  @override
  String get attendanceMetricWorkedHours => 'الساعات';

  @override
  String get attendanceMetricLateMinutes => 'دقائق التأخير';

  @override
  String get attendanceMetricAvgLate => 'متوسط التأخير';

  @override
  String get attendanceMetricAttendanceRate => 'نسبة الحضور';

  @override
  String get attendanceMetricPunctualityRate => 'نسبة الالتزام';

  @override
  String get attendanceMetricLateUnmatched => 'خارج الوردية';

  @override
  String get attendanceRateNoRoster => 'بدون جدول';

  @override
  String get attendanceRateNoRosterWhy =>
      'لا توجد أيام مجدولة في هذه الفترة، لذلك لا يمكن حساب نسبة.';

  @override
  String get attendanceStatusPresent => 'حاضر';

  @override
  String get attendanceStatusPresentWhy =>
      'سجّل حضوره خلال مهلة السماح بعد بداية الوردية.';

  @override
  String get attendanceStatusLate => 'متأخر';

  @override
  String get attendanceStatusLateWhy => 'سجّل حضوره بعد انتهاء مهلة السماح.';

  @override
  String get attendanceStatusLateUnmatched => 'خارج الوردية';

  @override
  String get attendanceStatusLateUnmatchedWhy =>
      'يوجد تسجيل حضور لكنه خارج وقت الوردية، لذلك تعذّر مطابقته ببداية الوردية. يحتاج الأمر إلى مراجعة.';

  @override
  String get attendanceStatusAbsent => 'غائب';

  @override
  String get attendanceStatusAbsentWhy =>
      'كان مجدولًا في يوم مضى ولم يُسجَّل له أي حضور.';

  @override
  String get attendanceStatusPending => 'لم يسجّل بعد';

  @override
  String get attendanceStatusPendingWhy =>
      'مجدول اليوم أو لاحقًا ولم يسجّل حضوره بعد، ولا توجد مشكلة حتى الآن.';

  @override
  String get attendanceStatusOff => 'إجازة';

  @override
  String get attendanceStatusOffWhy => 'إجازة معتمدة، وليست مشكلة.';

  @override
  String get attendanceStatusHoliday => 'عطلة رسمية';

  @override
  String get attendanceStatusHolidayWhy =>
      'عطلة رسمية ضمن قائمة عطلات الوردية.';

  @override
  String get attendanceStatusNotRostered => 'غير مجدول';

  @override
  String get attendanceStatusNotRosteredWhy =>
      'لم يكن مجدولًا للعمل في هذا اليوم، وهذا يختلف عن الغياب.';

  @override
  String get attendanceStatusUnknown => 'غير معروف';

  @override
  String get attendanceStatusUnknownWhy =>
      'هذه النسخة من التطبيق لا تتعرف على الحالة التي أرسلها الخادم.';

  @override
  String get attendanceTokenPresent => 'ح';

  @override
  String get attendanceTokenLate => 'ت';

  @override
  String get attendanceTokenLateUnmatched => 'خ';

  @override
  String get attendanceTokenAbsent => 'غ';

  @override
  String get attendanceTokenPending => '…';

  @override
  String get attendanceTokenOff => 'ج';

  @override
  String get attendanceTokenHoliday => 'ع';

  @override
  String get attendanceTokenNotRostered => '–';

  @override
  String attendanceRangeShortened(int days) {
    return 'تم تقليص الفترة إلى $days يومًا كحد أقصى';
  }

  @override
  String get attendanceRangeAdjusted =>
      'تم تحريك الطرف الآخر من الفترة ليتوافق مع اختيارك.';

  @override
  String get attendanceServerRefused => 'رفض الخادم هذا الطلب';

  @override
  String get attendanceServerRefusedHint =>
      'عدّل التواريخ أو الفلاتر ثم حاول مرة أخرى.';

  @override
  String get attendanceTokenUnknown => '؟';

  @override
  String get posCartOrderPurposeDeliverAtBranch => 'الاستلام من الفرع';

  @override
  String get posStaffMemberLabel => 'الموظف';

  @override
  String get posStaffMemberChoose => 'اختار الموظف';

  @override
  String get posStaffMemberChange => 'تغيير';

  @override
  String get posStaffMemberHint =>
      'الطلب ده هيتخصم من مرتب الموظف اللي هتختاره.';

  @override
  String get posStaffMemberRequired => 'اختار الموظف صاحب الطلب ده';

  @override
  String get posStaffMemberPickerTitle => 'اختار الموظف';

  @override
  String get posStaffMemberSearchHint => 'دوّر بالاسم أو الفرع أو الوظيفة';

  @override
  String get posStaffMemberNoMatches => 'مفيش موظف مطابق للبحث ده';

  @override
  String get posStaffMemberEmpty => 'مفيش موظفين نشطين';

  @override
  String get posStaffMemberHrmsUnavailableTitle =>
      'نظام الموارد البشرية مش متفعّل';

  @override
  String get posStaffMemberHrmsUnavailableBody =>
      'طلبات الموظفين بتتسجل على ملف الموظف، وموديول الموارد البشرية مش متسطّب على النظام. اطلب من مسؤول النظام يفعّله.';

  @override
  String get posStaffMemberNewCustomerHint => 'هيتعمل له حساب عميل جديد';

  @override
  String posStaffMemberCustomerCreated(String name) {
    return 'تم إنشاء حساب عميل للموظف $name';
  }

  @override
  String posStaffMemberAssigned(String name) {
    return 'الطلب اتسجل على $name';
  }

  @override
  String get posStaffMemberEnsureFailed => 'تعذّر تجهيز حساب العميل للموظف ده';

  @override
  String get posStaffMemberLoadFailed => 'تعذّر تحميل قائمة الموظفين';

  @override
  String get posEmployeePaymentCashHint =>
      'الموظف هيدفع دلوقتي والفلوس هتدخل خزنة الفرع.';

  @override
  String get posCheckoutEmployeeCashPaid => 'تم إرسال الطلب ودفعه نقدي.';

  @override
  String get posEmployeeCashNotSupported =>
      'الطلب اتسجل آجل مش نقدي: السيستم لسه مش بيدعم الدفع النقدي لطلبات الموظفين. هيتخصم من مرتب الموظف.';

  @override
  String get managerStaffCustomersSyncAction =>
      'إنشاء حسابات العملاء الناقصة للموظفين';

  @override
  String get managerStaffCustomersSyncConfirmTitle =>
      'إنشاء حسابات العملاء الناقصة للموظفين؟';

  @override
  String get managerStaffCustomersSyncConfirmBody =>
      'كل موظف نشط ملوش حساب عميل مربوط هيتعمل له حساب، علشان طلباته تتخصم من المرتب. ولو فيه عميل مطابق للموظف بالفعل هيتربط بيه بدل ما يتكرر.';

  @override
  String get managerStaffCustomersSyncConfirm => 'إنشاء';

  @override
  String get managerStaffCustomersSyncRunning =>
      'جاري إنشاء حسابات العملاء للموظفين…';

  @override
  String get managerStaffCustomersSyncResultTitle => 'حسابات عملاء الموظفين';

  @override
  String managerStaffCustomersSyncCreated(int count) {
    return 'تم الإنشاء: $count';
  }

  @override
  String managerStaffCustomersSyncAdopted(int count) {
    return 'اتربط بعميل موجود: $count';
  }

  @override
  String managerStaffCustomersSyncExisting(int count) {
    return 'مربوط من قبل: $count';
  }

  @override
  String managerStaffCustomersSyncSkipped(int count) {
    return 'تم تخطيه ($count)';
  }

  @override
  String managerStaffCustomersSyncConflicts(int count) {
    return 'محتاج مراجعة ($count)';
  }

  @override
  String get managerStaffCustomersSyncConflictsHint =>
      'أكتر من عميل مطابق للموظفين دول، فمفيش ربط اتعمل. اربط العميل الصح من الـ Desk.';

  @override
  String managerStaffCustomersSyncMatchingCustomers(String customers) {
    return 'العملاء المطابقين: $customers';
  }

  @override
  String get managerStaffCustomersSyncNothingToDo =>
      'مفيش حاجة تتعمل: كل الموظفين ليهم حسابات عملاء مربوطة.';

  @override
  String get managerStaffCustomersSyncFailed =>
      'تعذّر إنشاء حسابات العملاء للموظفين';

  @override
  String get approvalsNeedsYourAction => 'مستني تصرفك';

  @override
  String get approvalsQueueExpenses => 'طلبات مصروفات مستنية موافقة';

  @override
  String get approvalsQueueEmployeeAdvances => 'سُلف موظفين مستنية موافقة';

  @override
  String get approvalsQueueItemRequests => 'طلبات أصناف مستنية قبول';

  @override
  String get approvalsQueuePaymentReceipts => 'إيصالات دفع مستنية تأكيد';

  @override
  String get approvalsQueueCustomShipping => 'شحن مخصص مستني موافقة';

  @override
  String approvalsMenuBadgeSemantics(int count) {
    return 'القائمة: $count حاجة مستنية تصرفك';
  }

  @override
  String b2bBranchesTitleCount(int count) {
    return 'الفروع ($count)';
  }

  @override
  String get b2bAddBranch => 'ضيف فرع';

  @override
  String get b2bNoBranches => 'لسه مفيش فروع.';

  @override
  String b2bBranchInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فاتورة',
      many: '$count فاتورة',
      few: '$count فواتير',
      two: 'فاتورتين',
      one: 'فاتورة واحدة',
      zero: 'مفيش فواتير',
    );
    return '$_temp0';
  }

  @override
  String b2bBilledAmount(String amount) {
    return 'اتحاسب $amount';
  }

  @override
  String b2bOutstandingAmount(String amount) {
    return 'متبقي $amount';
  }

  @override
  String b2bLastOrderOn(String date) {
    return 'آخر طلب $date';
  }

  @override
  String get b2bNoOrdersYet => 'لسه مفيش طلبات';

  @override
  String get b2bOpenBranchMap => 'افتح على الخريطة';

  @override
  String get b2bPrimaryBranch => 'الأساسي';

  @override
  String get b2bTerritoryMissing => 'مفيش منطقة توصيل';

  @override
  String get b2bUnassignedInvoices => 'فواتير مش متسجلة على فرع';

  @override
  String get b2bUnassignedInvoicesHint => 'فواتير مش مطابقة لعنوان أي فرع';

  @override
  String get b2bUnassignedShort => 'من غير فرع';

  @override
  String get b2bViewAllInvoices => 'كل الفواتير';

  @override
  String get b2bInvoicesTitle => 'الفواتير';

  @override
  String get b2bFilterAllBranches => 'كل الفروع';

  @override
  String get b2bSummaryInvoices => 'الفواتير';

  @override
  String get b2bSummaryBilled => 'إجمالي المحاسبة';

  @override
  String get b2bSummaryOutstanding => 'المتبقي';

  @override
  String get b2bNoInvoicesForSelection => 'مفيش فواتير للاختيار ده.';

  @override
  String b2bInvoicesTruncated(int count) {
    return 'بيظهر أول $count فاتورة بس.';
  }

  @override
  String get b2bInvoiceReturn => 'مرتجع';

  @override
  String get b2bMergeMenuItem => 'ضيف حساب تاني كفرع…';

  @override
  String get b2bMergeSearchTitle => 'ضيف حساب كفرع';

  @override
  String get b2bMergeSearchHint => 'دوّر على الحسابات بالاسم أو الموبايل';

  @override
  String get b2bMergeNoCandidates => 'مفيش حسابات مطابقة.';

  @override
  String get b2bMergeDoctypeLead => 'عميل محتمل';

  @override
  String get b2bMergeDoctypeCustomer => 'عميل';

  @override
  String b2bMergeLinkedCustomer(String customer) {
    return 'العميل المربوط: $customer';
  }

  @override
  String get b2bMergeConfirmTitle => 'دمج كفرع';

  @override
  String b2bMergeBecomesBranch(String source, String target) {
    return '$source هيبقى فرع من $target.';
  }

  @override
  String b2bMergeSwap(String name) {
    return 'خلّي $name هو الأساسي';
  }

  @override
  String b2bMergeSourceCustomer(String name) {
    return 'العميل اللي هيتدمج: $name';
  }

  @override
  String b2bMergeTargetCustomer(String name) {
    return 'العميل الأساسي: $name';
  }

  @override
  String get b2bMergeWarningsTitle => 'قبل ما تدمج';

  @override
  String get b2bMergeWarningIrreversible =>
      'دمج حسابين عملاء مينفعش يترجع فيه. كل الفواتير والمدفوعات هتتنقل للعميل الأساسي.';

  @override
  String get b2bMergeWarningCredit =>
      'شروط الآجل بتاعة الحساب المدموج هتتنقل معاه.';

  @override
  String get b2bMergeBlockedTitle => 'الدمج ده مينفعش يتعمل';

  @override
  String get b2bMergeBranchNameLabel => 'اسم الفرع';

  @override
  String get b2bMergeManagerOnly => 'المدير بس اللي يقدر يدمج حسابين عملاء.';

  @override
  String get b2bMergeConfirm => 'ادمج';

  @override
  String b2bMergeSuccess(String source, String target) {
    return '$source بقى فرع من $target.';
  }

  @override
  String get menuCashCustody => 'العُهد';

  @override
  String get custodyTitle => 'العُهد';

  @override
  String get custodyMyTitle => 'عهدتي';

  @override
  String get custodyMine => 'عهدتي';

  @override
  String custodyOfHolder(String name) {
    return 'عهدة - $name';
  }

  @override
  String get custodyTotalHeld => 'إجمالي العُهد';

  @override
  String custodyHoldersCount(String count) {
    return 'أصحاب العُهد: $count';
  }

  @override
  String get custodyNoHolders => 'مفيش أصحاب عُهد لسه.';

  @override
  String get custodyNotAHolder => 'إنت مش ماسك عهدة نقدية.';

  @override
  String get custodyAddHolder => 'إضافة صاحب عهدة';

  @override
  String get custodySearchEmployee => 'ابحث عن موظف';

  @override
  String get custodyNoCandidates => 'مفيش موظفين مطابقين.';

  @override
  String custodyHolderAdded(String name) {
    return '$name بقى يقدر يمسك عهدة.';
  }

  @override
  String get custodyDisabledBadge => 'موقوفة';

  @override
  String get custodyEnableTooltip => 'تفعيل أو إيقاف العهدة دي';

  @override
  String get custodyDisableHasBalance =>
      'لازم ترجّع الرصيد المتبقي قبل ما توقف العهدة دي.';

  @override
  String get custodyHolderEnabledMsg => 'تم تفعيل العهدة.';

  @override
  String get custodyHolderDisabledMsg => 'تم إيقاف العهدة.';

  @override
  String custodyLastMovement(String date) {
    return 'آخر حركة: $date';
  }

  @override
  String get custodyNoMovement => 'مفيش حركات لسه';

  @override
  String get custodyCurrentBalance => 'الرصيد الحالي';

  @override
  String get custodyIssueAction => 'سحب للعهدة';

  @override
  String get custodyReturnAction => 'رد نقدية';

  @override
  String get custodyIssueTitle => 'سحب نقدية للعهدة';

  @override
  String get custodyReturnTitle => 'رد نقدية من العهدة';

  @override
  String get custodySourceAccount => 'السحب من';

  @override
  String get custodyReturnAccount => 'الرد إلى';

  @override
  String get custodySelectAccount => 'اختار حساب';

  @override
  String get custodyAccountRequired => 'اختار حساب.';

  @override
  String get custodyAmountLabel => 'المبلغ';

  @override
  String get custodyAmountInvalid => 'اكتب مبلغ أكبر من صفر.';

  @override
  String custodyAmountExceedsBalance(String balance) {
    return 'المبلغ مينفعش يزيد عن رصيد العهدة ($balance).';
  }

  @override
  String get custodyDateLabel => 'التاريخ والوقت';

  @override
  String get custodyDateNow => 'دلوقتي';

  @override
  String get custodyRemarkLabel => 'ملاحظة (اختياري)';

  @override
  String get custodySubmitIssue => 'اسحب';

  @override
  String get custodySubmitReturn => 'رجّع';

  @override
  String custodyPosted(String entry) {
    return 'اتسجل: $entry';
  }

  @override
  String get custodyNoAccounts => 'مفيش حسابات متاحة.';

  @override
  String get custodyStatementTitle => 'كشف الحساب';

  @override
  String get custodyStatementEmpty => 'مفيش حركات في الفترة دي.';

  @override
  String get custodyPickDates => 'اختار الفترة';

  @override
  String custodyRangeLabel(String from, String to) {
    return 'من $from إلى $to';
  }

  @override
  String get custodyOpeningBalance => 'رصيد أول الفترة';

  @override
  String get custodyClosingBalance => 'رصيد آخر الفترة';

  @override
  String get custodyKindIssue => 'سحب للعهدة';

  @override
  String get custodyKindReturn => 'رد';

  @override
  String get custodyKindExpense => 'مصروف';

  @override
  String get custodyKindPurchase => 'مشتريات';

  @override
  String get custodyKindTransferIn => 'تحويل وارد';

  @override
  String get custodyKindTransferOut => 'تحويل صادر';

  @override
  String get custodyKindOther => 'أخرى';

  @override
  String custodyRunningBalance(String balance) {
    return 'الرصيد: $balance';
  }

  @override
  String custodyCounterAccount(String account) {
    return 'مقابل: $account';
  }

  @override
  String custodyAvailable(String balance) {
    return 'المتاح: $balance';
  }

  @override
  String get custodyInsufficientBalance => 'رصيد العهدة مش كفاية';

  @override
  String get custodyPurchasePaymentSubtitle => 'الدفع من عهدة الموظف';

  @override
  String get userErrorCustodyInsufficient => 'رصيد العهدة مش كفاية للمبلغ ده.';

  @override
  String get userErrorCustodyDisableWithBalance =>
      'مينفعش توقف عهدة فيها رصيد. رجّع النقدية الأول.';

  @override
  String get tasksMenuTitle => 'المهام';

  @override
  String get tasksBoardTitle => 'لوحة المهام';

  @override
  String get tasksOverviewTitle => 'متابعة الفريق';

  @override
  String get tasksNoAccess => 'لوحة المهام متاحة للمديرين ومديري الخطوط فقط.';

  @override
  String get tasksNewTask => 'مهمة جديدة';

  @override
  String get tasksEmptyColumn => 'مفيش مهام هنا';

  @override
  String get tasksViewAll => 'الكل';

  @override
  String get tasksViewMine => 'مهامي';

  @override
  String get tasksViewCreated => 'اللي أنا عملتها';

  @override
  String get tasksViewReview => 'مستنية مراجعتي';

  @override
  String get tasksStatusToDo => 'لسه';

  @override
  String get tasksStatusInProgress => 'شغّال عليها';

  @override
  String get tasksStatusInReview => 'في المراجعة';

  @override
  String get tasksStatusDone => 'خلصت';

  @override
  String get tasksPriorityNormal => 'عادية';

  @override
  String get tasksPriorityHigh => 'مهمة';

  @override
  String get tasksPriorityUrgent => 'عاجلة';

  @override
  String get tasksFilters => 'الفلاتر';

  @override
  String get tasksFilterAssignee => 'المسؤول عنها';

  @override
  String get tasksFilterCreator => 'عملها';

  @override
  String get tasksFilterBranch => 'الفرع';

  @override
  String get tasksFilterPriority => 'الأولوية';

  @override
  String get tasksFilterAny => 'أي';

  @override
  String get tasksFilterOverdueOnly => 'المتأخرة بس';

  @override
  String get tasksFilterShowArchived => 'اعرض المؤرشفة';

  @override
  String get tasksFilterDoneWindow => 'عمود \"خلصت\" يعرض';

  @override
  String tasksDoneWindowDays(int days) {
    return 'آخر $days يوم';
  }

  @override
  String get tasksDoneWindowAll => 'كل الفترات';

  @override
  String get tasksFilterClear => 'امسح الفلاتر';

  @override
  String get tasksFilterApply => 'تطبيق';

  @override
  String get tasksSearchHint => 'دوّر في المهام';

  @override
  String tasksDueOn(String date) {
    return 'مطلوبة $date';
  }

  @override
  String get tasksOverdueLabel => 'متأخرة';

  @override
  String get tasksArchivedTag => 'مؤرشفة';

  @override
  String get tasksUnassigned => 'مش متكلف بيها حد';

  @override
  String get tasksMoveTo => 'انقل إلى';

  @override
  String tasksMoveToStatus(String status) {
    return 'انقل إلى $status';
  }

  @override
  String tasksStatusChanged(String status) {
    return 'المهمة اتنقلت إلى $status';
  }

  @override
  String get tasksAssignee => 'المسؤول عنها';

  @override
  String get tasksCreator => 'عملها';

  @override
  String get tasksDueDate => 'ميعاد التسليم';

  @override
  String get tasksNoDueDate => 'من غير ميعاد';

  @override
  String get tasksBranch => 'الفرع';

  @override
  String get tasksNoBranch => 'من غير فرع';

  @override
  String get tasksDescription => 'التفاصيل';

  @override
  String get tasksNoDescription => 'مفيش تفاصيل';

  @override
  String get tasksStartedOnLabel => 'بدأت';

  @override
  String get tasksCompletedLabel => 'خلصت';

  @override
  String tasksCompletedBy(String name, String date) {
    return '$name يوم $date';
  }

  @override
  String get tasksArchivedBanner => 'المهمة دي مؤرشفة وللقراءة بس.';

  @override
  String get tasksActionStart => 'ابدأ';

  @override
  String get tasksActionSubmit => 'ابعتها للمراجعة';

  @override
  String get tasksActionApprove => 'موافقة';

  @override
  String get tasksActionSendBack => 'رجّعها';

  @override
  String get tasksActionReopen => 'افتحها تاني';

  @override
  String get tasksActionMarkDone => 'علّم إنها خلصت';

  @override
  String get tasksActionMoveToDo => 'رجّعها لـ\"لسه\"';

  @override
  String get tasksActionEdit => 'تعديل المهمة';

  @override
  String get tasksActionArchive => 'أرشفة';

  @override
  String get tasksActionUnarchive => 'إلغاء الأرشفة';

  @override
  String get tasksArchiveConfirm =>
      'تأرشف المهمة دي؟ هتبقى للقراءة بس لحد ما تلغي الأرشفة.';

  @override
  String get tasksReasonTitleSendBack => 'بترجّعها ليه؟';

  @override
  String get tasksReasonTitleReopen => 'بتفتحها تاني ليه؟';

  @override
  String get tasksReasonHint => 'السبب';

  @override
  String get tasksEditTitle => 'تعديل المهمة';

  @override
  String get tasksFieldTitle => 'العنوان';

  @override
  String get tasksFieldTitleRequired => 'اكتب عنوان';

  @override
  String get tasksFieldDescription => 'التفاصيل';

  @override
  String get tasksFieldAssignee => 'كلّف';

  @override
  String get tasksFieldAssigneeRequired => 'اختار مين هيعملها';

  @override
  String get tasksFieldDueDate => 'ميعاد التسليم';

  @override
  String get tasksFieldBranch => 'الفرع';

  @override
  String get tasksFieldPriority => 'الأولوية';

  @override
  String get tasksClearDate => 'امسح التاريخ';

  @override
  String get tasksNone => 'ولا حاجة';

  @override
  String get tasksSaved => 'المهمة اتحفظت';

  @override
  String get tasksCreated => 'المهمة اتعملت';

  @override
  String get tasksInitialSubtasks => 'المهام الفرعية';

  @override
  String get tasksAddSubtaskField => 'ضيف مهمة فرعية';

  @override
  String get tasksCreateButton => 'اعمل المهمة';

  @override
  String tasksSubtasksTitle(int done, int total) {
    return 'المهام الفرعية ($done/$total)';
  }

  @override
  String get tasksNoSubtasks => 'مفيش مهام فرعية لسه';

  @override
  String get tasksAddSubtask => 'ضيف مهمة فرعية';

  @override
  String get tasksEditSubtask => 'تعديل المهمة الفرعية';

  @override
  String get tasksDeleteSubtask => 'امسح المهمة الفرعية';

  @override
  String tasksDeleteSubtaskConfirm(String title) {
    return 'تمسح \"$title\"؟';
  }

  @override
  String get tasksSubtaskTitle => 'المهمة الفرعية';

  @override
  String get tasksSubtaskAssignee => 'متكلف بيها';

  @override
  String tasksSubtaskDoneBy(String name) {
    return 'خلّصها $name';
  }

  @override
  String tasksAttachmentsTitle(int count) {
    return 'المرفقات ($count)';
  }

  @override
  String get tasksNoAttachments => 'مفيش مرفقات';

  @override
  String get tasksAddAttachment => 'إرفاق';

  @override
  String get tasksAttachCamera => 'صوّر';

  @override
  String get tasksAttachGallery => 'اختار صورة';

  @override
  String get tasksAttachFile => 'اختار ملف';

  @override
  String get tasksRemoveAttachment => 'شيل المرفق';

  @override
  String tasksRemoveAttachmentConfirm(String file) {
    return 'تشيل \"$file\"؟';
  }

  @override
  String tasksFileTooLarge(String file) {
    return '\"$file\" أكبر من 10 ميجا.';
  }

  @override
  String get tasksFileEmpty => 'الملف ماتقراش. اختاره تاني.';

  @override
  String get tasksUploaded => 'المرفق اتضاف';

  @override
  String tasksFileSaved(String path) {
    return 'اتحفظ في $path';
  }

  @override
  String get tasksDownload => 'تحميل';

  @override
  String get tasksAttachmentsPartial =>
      'اللي كتبته اتحفظ، بس في ملفات مااترفعتش.';

  @override
  String tasksUploadedBy(String name, String date) {
    return '$name · $date';
  }

  @override
  String get tasksActivityTitle => 'النشاط';

  @override
  String get tasksTabLogs => 'اللي اتعمل';

  @override
  String get tasksTabComments => 'التعليقات';

  @override
  String get tasksTabHistory => 'السجل';

  @override
  String get tasksNoLogs => 'مفيش تحديثات لسه';

  @override
  String get tasksNoComments => 'مفيش تعليقات لسه';

  @override
  String get tasksNoHistory => 'مفيش سجل لسه';

  @override
  String get tasksAddLog => 'اكتب اللي عملته';

  @override
  String get tasksAddComment => 'اكتب تعليق';

  @override
  String get tasksLogHint => 'عملت إيه؟';

  @override
  String get tasksCommentHint => 'اكتب تعليقك';

  @override
  String get tasksMention => 'منشن';

  @override
  String get tasksMentionPick => 'اعمل منشن لحد';

  @override
  String get tasksNoMentionable => 'مفيش حد تاني يقدر يشوف المهمة دي.';

  @override
  String get tasksContentRequired => 'اكتب حاجة الأول';

  @override
  String get tasksSend => 'نشر';

  @override
  String tasksMentioned(String names) {
    return 'منشن: $names';
  }

  @override
  String tasksHistoryCreated(String actor) {
    return '$actor عمل المهمة';
  }

  @override
  String tasksHistoryReassigned(String actor) {
    return '$actor غيّر المسؤول عن المهمة';
  }

  @override
  String tasksHistoryStatus(String actor) {
    return '$actor غيّر حالة المهمة';
  }

  @override
  String tasksHistoryDueDate(String actor) {
    return '$actor غيّر ميعاد التسليم';
  }

  @override
  String tasksHistoryPriority(String actor) {
    return '$actor غيّر الأولوية';
  }

  @override
  String tasksHistoryTitle(String actor) {
    return '$actor غيّر عنوان المهمة';
  }

  @override
  String tasksHistoryBranch(String actor) {
    return '$actor غيّر الفرع';
  }

  @override
  String tasksHistorySubtaskAdded(String actor) {
    return '$actor ضاف مهمة فرعية';
  }

  @override
  String tasksHistorySubtaskDone(String actor) {
    return '$actor خلّص مهمة فرعية';
  }

  @override
  String tasksHistorySubtaskUndone(String actor) {
    return '$actor فتح مهمة فرعية تاني';
  }

  @override
  String tasksHistorySubtaskRemoved(String actor) {
    return '$actor مسح مهمة فرعية';
  }

  @override
  String tasksHistoryAttachmentAdded(String actor) {
    return '$actor ضاف مرفق';
  }

  @override
  String tasksHistoryAttachmentRemoved(String actor) {
    return '$actor شال مرفق';
  }

  @override
  String tasksHistoryArchived(String actor) {
    return '$actor أرشف المهمة';
  }

  @override
  String tasksHistoryUnarchived(String actor) {
    return '$actor لغى أرشفة المهمة';
  }

  @override
  String tasksHistoryOther(String actor) {
    return '$actor عدّل المهمة';
  }

  @override
  String tasksOverviewDays(int days) {
    return '$days يوم';
  }

  @override
  String get tasksOverviewOpen => 'مفتوحة';

  @override
  String get tasksOverviewInProgress => 'شغّال عليها';

  @override
  String get tasksOverviewInReview => 'في المراجعة';

  @override
  String get tasksOverviewOverdue => 'متأخرة';

  @override
  String get tasksOverviewDone => 'خلصت';

  @override
  String get tasksOverviewOnTime => 'في ميعادها';

  @override
  String get tasksOverviewNoData => 'مفيش مهام في الفترة دي';

  @override
  String get tasksOverviewManagerTag => 'مدير';

  @override
  String get tasksErrorOpenSubtasks =>
      'خلّص أو امسح المهام الفرعية المفتوحة الأول.';

  @override
  String get tasksErrorReasonRequired => 'لازم تكتب السبب.';

  @override
  String get tasksErrorArchived => 'المهمة دي مؤرشفة. الغي الأرشفة الأول.';

  @override
  String get tasksErrorMentionNotVisible =>
      'في حد عملتله منشن مش شايف المهمة دي.';

  @override
  String get tasksErrorFileTooLarge => 'الملف أكبر من 10 ميجا.';

  @override
  String get tasksQueueAssigned => 'مهام متكلف بيها';

  @override
  String get tasksQueueReview => 'مهام مستنية مراجعتك';

  @override
  String tasksFileTypeBlocked(String file) {
    return 'مينفعش ترفق \"$file\": نوع الملف ده مش مسموح.';
  }

  @override
  String get menuBranchAccess => 'صلاحيات الفروع';

  @override
  String get branchAccessTitle => 'صلاحيات الفروع';

  @override
  String get branchAccessTabPeople => 'الموظفين';

  @override
  String get branchAccessTabHistory => 'السجل';

  @override
  String get branchAccessAccessDenied =>
      'إدارة صلاحيات الفروع للمديرين ومديري الخط بس.';

  @override
  String get branchAccessSearchHint => 'دوّر على موظف';

  @override
  String get branchAccessNoUsers => 'مفيش حد مطابق.';

  @override
  String get branchAccessNoBranches => 'مفيش فروع تتعرض.';

  @override
  String get branchAccessBranchClosed => 'مقفول';

  @override
  String branchAccessOpenSince(String time, String name) {
    return 'مفتوح من $time مع $name';
  }

  @override
  String branchAccessLockedOpen(String branch, String time, String name) {
    return 'فرع $branch مفتوح من $time مع $name. الصلاحيات تتغير بعد ما الشيفت ده يتقفل.';
  }

  @override
  String get branchAccessNotYourBranch => 'تقدر تدير الفروع اللي انت فيها بس.';

  @override
  String get branchAccessCannotEditSelf => 'مينفعش تغيّر صلاحياتك بنفسك.';

  @override
  String get branchAccessYouTag => 'انت';

  @override
  String get branchAccessDisabledTag => 'موقوف';

  @override
  String get branchAccessChipMember => 'معاه صلاحية';

  @override
  String get branchAccessChipNone => 'مفيش صلاحية';

  @override
  String branchAccessChipDay(String branch, String date) {
    return '$branch · $date';
  }

  @override
  String branchAccessAddTitle(String branch) {
    return 'تدي صلاحية فرع $branch؟';
  }

  @override
  String branchAccessAddBody(String name, String branch) {
    return '$name هيقدر يفتح كاشير فرع $branch كل يوم لحد ما الصلاحية تتشال.';
  }

  @override
  String branchAccessMakePermanentBody(String name, String branch) {
    return '$name معاه صلاحية فرع $branch ليوم واحد بس. تخليها دايمة؟';
  }

  @override
  String branchAccessRemoveTitle(String branch) {
    return 'تشيل صلاحية فرع $branch؟';
  }

  @override
  String branchAccessRemoveBody(String name, String branch) {
    return '$name مش هيقدر يفتح كاشير فرع $branch تاني.';
  }

  @override
  String get branchAccessNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get branchAccessAddAction => 'ادي الصلاحية';

  @override
  String get branchAccessRemoveAction => 'شيل الصلاحية';

  @override
  String branchAccessAdded(String name, String branch) {
    return '$name بقى معاه صلاحية فرع $branch.';
  }

  @override
  String branchAccessRemoved(String name, String branch) {
    return 'اتشالت صلاحية $name على فرع $branch.';
  }

  @override
  String get branchAccessUnchanged =>
      'مفيش حاجة اتغيرت: الصلاحية كانت كده أصلاً.';

  @override
  String get branchAccessGiveDay => 'ادي صلاحية ليوم واحد';

  @override
  String branchAccessDayTitle(String name) {
    return 'صلاحية يوم واحد لـ $name';
  }

  @override
  String get branchAccessDayBranch => 'الفرع';

  @override
  String get branchAccessDayDate => 'اليوم';

  @override
  String get branchAccessDayHelper =>
      'الصلاحية من أول اليوم ده لحد الساعة 3 الفجر اليوم اللي بعده.';

  @override
  String get branchAccessDayNoBranch =>
      'مفيش فرع تديه: معاه صلاحية كل الفروع اللي بتديرها.';

  @override
  String branchAccessDayGranted(String date) {
    return 'اتدت الصلاحية ليوم $date.';
  }

  @override
  String get branchAccessDaySection => 'صلاحيات اليوم الواحد';

  @override
  String get branchAccessDayStatusActive => 'شغالة';

  @override
  String get branchAccessDayStatusScheduled => 'مجدولة';

  @override
  String get branchAccessDayStatusEnded => 'خلصت';

  @override
  String get branchAccessDayStatusCancelled => 'اتلغت';

  @override
  String get branchAccessCancelDay => 'الغي الصلاحية';

  @override
  String get branchAccessCancelDayTitle => 'تلغي صلاحية اليوم ده؟';

  @override
  String branchAccessCancelDayBody(String name, String branch, String date) {
    return '$name هيفقد صلاحية فرع $branch ليوم $date.';
  }

  @override
  String get branchAccessKeep => 'سيبها';

  @override
  String get branchAccessDayCancelled => 'اتلغت صلاحية اليوم الواحد.';

  @override
  String branchAccessHomeBranch(String branch) {
    return 'الفرع الأساسي: $branch';
  }

  @override
  String get branchAccessMoveAction => 'انقله لفرع تاني';

  @override
  String branchAccessMoveTitle(String name) {
    return 'نقل $name لفرع تاني';
  }

  @override
  String get branchAccessMoveExplain =>
      'صلاحية الكاشير بتتنقل دلوقتي. جدوله الأسبوعي وشيفتاته الجاية بتتنقل للفرع الجديد من النهارده.';

  @override
  String branchAccessMoveCurrent(String branch) {
    return 'الفرع الحالي: $branch';
  }

  @override
  String get branchAccessMoveTarget => 'الفرع الجديد';

  @override
  String branchAccessMoveKeepOld(String branch) {
    return 'يفضل معاه صلاحية $branch كمان';
  }

  @override
  String get branchAccessMoveKeepOldUnknown =>
      'يفضل معاه صلاحية فرعه الحالي كمان';

  @override
  String get branchAccessMoveConfirm => 'انقل';

  @override
  String get branchAccessMoveNoTarget =>
      'مفيش فرع تاني تقدر تنقل الشخص ده ليه.';

  @override
  String branchAccessMoved(String name, String branch) {
    return '$name اتنقل لفرع $branch.';
  }

  @override
  String branchAccessRosterNotMoved(String reason) {
    return 'الشيفت متنقلش: $reason. تسجيل الحضور في الفرع ده هيفضل مرفوض.';
  }

  @override
  String branchAccessRosterNotRestored(String reason) {
    return 'الشيفت مرجعش لمكانه: $reason';
  }

  @override
  String get branchAccessHistoryAllBranches => 'كل الفروع';

  @override
  String get branchAccessHistoryEmpty => 'مفيش تغييرات متسجلة لسه.';

  @override
  String branchAccessHistoryBy(String name) {
    return 'بواسطة $name';
  }

  @override
  String get branchAccessActionAdded => 'اتدت صلاحية';

  @override
  String get branchAccessActionRemoved => 'اتشالت صلاحية';

  @override
  String get branchAccessActionDayScheduled => 'صلاحية يوم اتجدولت';

  @override
  String get branchAccessActionDayStarted => 'صلاحية يوم بدأت';

  @override
  String get branchAccessActionDayEnded => 'صلاحية يوم خلصت';

  @override
  String get branchAccessActionDayCancelled => 'صلاحية يوم اتلغت';

  @override
  String get branchAccessSourceScreen => 'شاشة صلاحيات الفروع';

  @override
  String get branchAccessSourceShift => 'توزيع الشيفتات';

  @override
  String get branchAccessSourceCover => 'تغطية إجازة';

  @override
  String get branchAccessSourceScheduler => 'تلقائي';

  @override
  String get branchAccessSourceMove => 'نقل فرع';

  @override
  String get rosterGrantPosAccess => 'ادي كمان صلاحية الكاشير لليوم ده';

  @override
  String rosterGrantPosAccessHelper(String branch) {
    return 'يقدر يفتح كاشير فرع $branch في اليوم ده بس.';
  }

  @override
  String rosterPosAccessGranted(String branch) {
    return 'اتدت صلاحية كاشير فرع $branch لليوم ده.';
  }

  @override
  String rosterPosAccessScheduled(String branch) {
    return 'صلاحية كاشير فرع $branch اتجدولت لليوم ده.';
  }

  @override
  String rosterPosAccessAlreadyMember(String branch) {
    return 'معاه صلاحية كاشير فرع $branch أصلاً.';
  }

  @override
  String rosterPosAccessNotGranted(String reason) {
    return 'اتحفظ، بس صلاحية الكاشير متدتش: $reason';
  }

  @override
  String get rosterPosAccessNotConfirmed =>
      'اتحفظ، بس السيرفر مأكدش صلاحية الكاشير.';

  @override
  String get rosterPosAccessNoReason => 'من غير سبب';

  @override
  String get branchAccessUserNotEditable =>
      'مش مسموحلك تغيّر صلاحيات الشخص ده.';

  @override
  String get manufacturingHistorySearchHint => 'دوّر بالصنف أو رقم أمر الشغل';

  @override
  String get manufacturingHistoryBasisPosted => 'تاريخ المخزون';

  @override
  String get manufacturingHistoryBasisCreated => 'تاريخ الإنشاء';

  @override
  String get manufacturingHistoryDateHelp =>
      'تاريخ المخزون هو اليوم اللي الإنتاج اتحسب فيه في المخزون. تاريخ الإنشاء هو وقت ما الأمر اتسجل على الأبلكيشن.';

  @override
  String manufacturingHistoryPostedAt(String date) {
    return 'المخزون: $date';
  }

  @override
  String manufacturingHistoryCreatedAt(String date) {
    return 'الإنشاء: $date';
  }

  @override
  String get manufacturingHistoryNotPosted => 'لسه متسجلش في المخزون';

  @override
  String get manufacturingHistoryBackdated => 'بتاريخ قديم';

  @override
  String get manufacturingHistoryAllStatuses => 'كل الحالات';

  @override
  String get manufacturingHistoryAnyDate => 'أي تاريخ';

  @override
  String get manufacturingHistoryToday => 'النهارده';

  @override
  String get manufacturingHistoryYesterday => 'امبارح';

  @override
  String get manufacturingHistoryLast7 => 'آخر ٧ أيام';

  @override
  String get manufacturingHistoryLast30 => 'آخر ٣٠ يوم';

  @override
  String get manufacturingHistoryCustomRange => 'فترة مخصصة';

  @override
  String manufacturingHistorySummary(int count, String qty) {
    return '$count أمر شغل • اتعمل $qty';
  }

  @override
  String manufacturingHistoryQty(String qty) {
    return 'الكمية $qty';
  }

  @override
  String manufacturingHistoryMade(String made, String qty) {
    return 'اتعمل $made من $qty';
  }

  @override
  String manufacturingHistoryCapped(int count) {
    return 'بيظهر آخر $count بس. ضيّق الفلاتر عشان تشوف الأقدم.';
  }

  @override
  String get manufacturingWoStatusNotStarted => 'لسه مبدأش';

  @override
  String get manufacturingWoStatusInProcess => 'شغال';

  @override
  String get manufacturingWoStatusCompleted => 'خلص';

  @override
  String get manufacturingWoStatusStopped => 'متوقف';

  @override
  String get manufacturingWoStatusCancelled => 'ملغي';

  @override
  String get b2bBranchMapsLinked => 'مربوط بخرائط جوجل';

  @override
  String get b2bBranchMapsAutoMatched => 'اتربط تلقائي';

  @override
  String get b2bBranchMapsOnlySubtitle => 'على خرائط جوجل — لسه مش فرع توصيل';

  @override
  String get b2bBranchActions => 'إجراءات الفرع';

  @override
  String get b2bBranchLinkMaps => 'اربطه بفرع على خرائط جوجل';

  @override
  String get b2bBranchUnlinkMaps => 'افصله عن فرع خرائط جوجل';

  @override
  String get b2bBranchMakeDelivery => 'خليه فرع توصيل';

  @override
  String get b2bBranchSameAsExisting => 'هو نفس فرع موجود…';

  @override
  String get b2bBranchPickMapsTitle => 'أنهي فرع على خرائط جوجل؟';

  @override
  String get b2bBranchPickDeliveryTitle => 'أنهي فرع توصيل ده؟';

  @override
  String get b2bBranchNoFreeDelivery =>
      'كل فروع التوصيل مربوطة بالفعل بفرع على خرائط جوجل.';

  @override
  String get b2bBranchLinkedDone => 'الفرعين اتدمجوا';

  @override
  String get b2bBranchUnlinkedDone => 'فرع خرائط جوجل اتفصل';

  @override
  String b2bBranchPromotedDone(String name) {
    return '$name بقى فرع توصيل';
  }

  @override
  String get b2bBranchOnTalabat => 'على طلبات';

  @override
  String get settlementTermsTitle => 'شروط السداد';

  @override
  String get settlementTermsNotSet =>
      'مفيش شروط سداد متحددة، فمفيش تذكير بالتحصيل للمحل ده.';

  @override
  String get settlementTermsSetAction => 'حدد الشروط';

  @override
  String get settlementTermsEditAction => 'تعديل';

  @override
  String get settlementTermsLoadFailed => 'تعذر تحميل شروط السداد';

  @override
  String get settlementTermsPaused => 'التذكير متوقف';

  @override
  String get settlementLeadHint =>
      'هتتطبق لوحدها أول ما العميل المحتمل ده يبقى عميل.';

  @override
  String get settlementStateOverdue => 'متأخر';

  @override
  String get settlementStateDueToday => 'مستحق النهارده';

  @override
  String get settlementStateDueSoon => 'مستحق قريب';

  @override
  String get settlementStateOk => 'ماشي في ميعاده';

  @override
  String get settlementStateNone => 'مفيش مستحقات';

  @override
  String get settlementStateUnscheduled => 'من غير جدول';

  @override
  String get settlementNextDueLabel => 'الميعاد الجاي';

  @override
  String get settlementNextDueAmountLabel => 'المستحق في الميعاد ده';

  @override
  String get settlementDueNowLabel => 'مستحق دلوقتي';

  @override
  String get settlementOverdueAmountLabel => 'متأخر';

  @override
  String get settlementOverdueSinceLabel => 'متأخر من';

  @override
  String get settlementCollectNextDeliveryLabel => 'يتحصل مع التوصيل الجاي';

  @override
  String get settlementByBranchTitle => 'حسب الفرع';

  @override
  String get settlementUnassignedBranch => 'فاتورة من غير فرع';

  @override
  String settlementBranchLine(String due, String next) {
    return 'مستحق دلوقتي $due · مع التوصيل الجاي $next';
  }

  @override
  String get settlementRemindsLabel => 'التذكير يروح لـ';

  @override
  String get settlementRemindsAllManagers => 'كل المديرين';

  @override
  String get settlementNotesLabel => 'الاتفاق';

  @override
  String get settlementDescOnDelivery => 'بيدفع عند الاستلام';

  @override
  String get settlementDescInvoiceAfterInvoice =>
      'بيدفع الفاتورة اللي قبلها مع كل توصيل';

  @override
  String settlementDescWeekly(Object days) {
    return 'كل يوم $days';
  }

  @override
  String settlementDescWeeklyInterval(int weeks, Object days) {
    return 'كل $weeks أسابيع يوم $days';
  }

  @override
  String settlementDescMonthDays(Object days) {
    return 'كل شهر يوم $days';
  }

  @override
  String settlementDescMonthDayNumber(Object day) {
    return '$day';
  }

  @override
  String get settlementDescMonthDayLast => 'آخر الشهر';

  @override
  String settlementDescEveryNDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'كل $count يوم',
      few: 'كل $count أيام',
      two: 'كل يومين',
      one: 'كل يوم',
    );
    return '$_temp0';
  }

  @override
  String get settlementSheetTitle => 'شروط السداد';

  @override
  String get settlementSheetHint =>
      'جدول للتذكير بس. مفيش حاجة هنا بتوقف أي أوردر.';

  @override
  String get settlementCycleLabel => 'المحل ده بيدفع إزاي؟';

  @override
  String get settlementCycleOnDelivery => 'عند الاستلام';

  @override
  String get settlementCycleInvoiceAfterInvoice => 'فاتورة بفاتورة';

  @override
  String get settlementCycleWeekly => 'أسبوعي';

  @override
  String get settlementCycleDaysOfMonth => 'أيام في الشهر';

  @override
  String get settlementCycleEveryNDays => 'كل كام يوم';

  @override
  String get settlementCycleOnDeliveryHint =>
      'بيدفع على الباب. أي رصيد مفتوح بيظهر متأخر.';

  @override
  String get settlementCycleInvoiceAfterInvoiceHint =>
      'لما يوصله أوردر جديد، المحل بيدفع اللي قبله.';

  @override
  String get settlementWeekdaysLabel => 'يوم الدفع';

  @override
  String get settlementWeekIntervalLabel => 'كل كام أسبوع';

  @override
  String get settlementWeekIntervalHint => '1 = كل أسبوع، 2 = أسبوع وأسبوع';

  @override
  String get settlementMonthDaysLabel => 'أيام الشهر';

  @override
  String get settlementMonthDayLastChip => 'آخر يوم';

  @override
  String get settlementMonthDaysClampHint =>
      'لو اليوم مش موجود في الشهر (زي 31) بيتحسب آخر يوم في الشهر.';

  @override
  String get settlementIntervalDaysLabel => 'كل كام يوم';

  @override
  String get settlementAnchorDateLabel => 'العد من';

  @override
  String get settlementAnchorDateDefault => 'النهارده (الافتراضي)';

  @override
  String get settlementRemindDaysBeforeLabel => 'التذكير قبلها بكام يوم';

  @override
  String get settlementRemindDaysBeforeHint => '0 = في نفس اليوم بس';

  @override
  String get settlementOverdueRepeatLabel => 'كرر تذكير التأخير كل (يوم)';

  @override
  String get settlementResponsibleUserLabel => 'مين ييجيله التذكير';

  @override
  String get settlementResponsibleUserHint =>
      'إيميل المستخدم. سيبه فاضي لكل المديرين.';

  @override
  String get settlementNotesFieldLabel => 'الاتفاق (مرتجعات، خصومات، أي حاجة)';

  @override
  String get settlementEnabledLabel => 'ابعت تذكير';

  @override
  String get settlementSaveAction => 'احفظ الشروط';

  @override
  String get settlementSaveFailed => 'تعذر حفظ شروط السداد';

  @override
  String get settlementSaved => 'شروط السداد اتحفظت';

  @override
  String get settlementValidationPickDay => 'اختار يوم واحد على الأقل';

  @override
  String get settlementValidationWholeNumber => 'اكتب رقم صحيح، 1 أو أكتر';

  @override
  String get settlementValidationZeroOrMore => 'اكتب رقم صحيح، 0 أو أكتر';

  @override
  String get creditAccountsViewAccounts => 'الحسابات';

  @override
  String get creditAccountsViewCollections => 'التحصيل';

  @override
  String get collectionsSubtitle =>
      'المحلات اللي محتاجة تحصيل، الأهم الأول. تذكير بس، مفيش حاجة هنا بتوقف أوردر.';

  @override
  String collectionsEmpty(int days) {
    return 'مفيش تحصيل في الـ $days يوم الجايين';
  }

  @override
  String get collectionsLoadFailed => 'تعذر تحميل التحصيل';

  @override
  String get collectionsNoTerms => 'مفيش شروط سداد متحددة';

  @override
  String collectionsDueNow(Object amount) {
    return 'مستحق دلوقتي $amount';
  }

  @override
  String collectionsOverdueAmount(Object amount) {
    return 'متأخر $amount';
  }

  @override
  String collectionsNextDue(Object amount, Object date) {
    return '$amount مستحق $date';
  }

  @override
  String get approvalsQueueCreditCollections => 'تحصيل مستحق';

  @override
  String get menuUsers => 'المستخدمون';

  @override
  String get userAdminTitle => 'المستخدمون';

  @override
  String get userAdminAccessDenied =>
      'إدارة حسابات المستخدمين متاحة للمديرين فقط.';

  @override
  String get userAdminSearchHint => 'ابحث بالاسم أو البريد أو رقم الموبايل';

  @override
  String get userAdminFilterAll => 'الكل';

  @override
  String get userAdminFilterActive => 'نشط';

  @override
  String get userAdminFilterDisabled => 'موقوف';

  @override
  String get userAdminFilterManagers => 'المديرون';

  @override
  String get userAdminFilterLineManagers => 'المشرفون';

  @override
  String get userAdminFilterModerators => 'المودريتورز';

  @override
  String get userAdminFilterB2b => 'مبيعات الشركات';

  @override
  String get userAdminFilterProduction => 'الإنتاج';

  @override
  String get userAdminFilterStaff => 'الموظفون';

  @override
  String get userAdminFilterOther => 'أخرى';

  @override
  String get userAdminTierManager => 'مدير';

  @override
  String get userAdminTierLineManager => 'مشرف';

  @override
  String get userAdminTierModerator => 'مودريتور';

  @override
  String get userAdminTierB2b => 'مبيعات شركات';

  @override
  String get userAdminTierProduction => 'إنتاج';

  @override
  String get userAdminTierStaff => 'موظف';

  @override
  String get userAdminTierOther => 'أخرى';

  @override
  String get userAdminAddUser => 'إضافة مستخدم';

  @override
  String get userAdminNoUsers => 'مفيش مستخدمين مطابقين.';

  @override
  String userAdminCount(int count) {
    return '$count مستخدم';
  }

  @override
  String get userAdminYouTag => 'أنت';

  @override
  String get userAdminDisabledTag => 'موقوف';

  @override
  String get userAdminViewOnly => 'عرض فقط';

  @override
  String get userAdminViewOnlyBanner =>
      'ده حساب مدير نظام (System Manager). ممكن تشوفه هنا لكن مينفعش تعدّله.';

  @override
  String get userAdminDisabledBanner =>
      'الحساب ده موقوف، والمستخدم مش هيقدر يسجّل دخول.';

  @override
  String get userAdminNewTitle => 'مستخدم جديد';

  @override
  String get userAdminEditTitle => 'المستخدم';

  @override
  String get userAdminSectionAccount => 'الحساب';

  @override
  String get userAdminSectionRoles => 'ملفات الصلاحيات';

  @override
  String get userAdminSectionEmployee => 'الموظف';

  @override
  String get userAdminSectionBranches => 'الفروع';

  @override
  String get userAdminSectionActions => 'إجراءات الحساب';

  @override
  String get userAdminFirstName => 'الاسم الأول';

  @override
  String get userAdminLastName => 'اسم العائلة';

  @override
  String get userAdminMobile => 'رقم الموبايل';

  @override
  String get userAdminEmail => 'البريد الإلكتروني';

  @override
  String get userAdminEmailReadOnly =>
      'البريد الإلكتروني هو اسم الدخول ومينفعش يتغيّر.';

  @override
  String get userAdminPassword => 'كلمة المرور';

  @override
  String get userAdminConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get userAdminNewPassword => 'كلمة المرور الجديدة';

  @override
  String get userAdminShowPassword => 'إظهار كلمة المرور';

  @override
  String get userAdminHidePassword => 'إخفاء كلمة المرور';

  @override
  String get userAdminFieldRequired => 'مطلوب';

  @override
  String get userAdminEmailInvalid => 'اكتب بريد إلكتروني صحيح';

  @override
  String userAdminPasswordTooShort(int min) {
    return 'على الأقل $min حروف';
  }

  @override
  String get userAdminPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get userAdminRoleProfilesRequired =>
      'اختار ملف صلاحيات واحد على الأقل.';

  @override
  String get userAdminRoleProfilesReplaceWarning =>
      'صلاحيات المستخدم هتتستبدل بصلاحيات الملفات المختارة.';

  @override
  String get userAdminRoleProfilesSelfLocked =>
      'مينفعش تغيّر ملفات الصلاحيات الخاصة بيك.';

  @override
  String get userAdminRoleProfileNotAssignable =>
      'الملف ده يقدر يديه مدير النظام بس.';

  @override
  String get userAdminNoRoleProfiles => 'مفيش ملفات صلاحيات متاحة.';

  @override
  String get userAdminPrivilegedTag => 'صلاحيات عالية';

  @override
  String get userAdminRequirePosShift => 'يتطلب فتح وردية';

  @override
  String get userAdminRequirePosShiftHelp =>
      'لازم المستخدم يفتح وردية قبل ما يبيع على نقطة البيع.';

  @override
  String get userAdminEmployeeNone => 'مفيش موظف مربوط';

  @override
  String get userAdminEmployeeChoose => 'ربط موظف';

  @override
  String get userAdminEmployeeChange => 'تغيير';

  @override
  String get userAdminEmployeeUnlink => 'فك الربط';

  @override
  String get userAdminEmployeeUnlinkPending => 'ربط الموظف هيتشال لما تحفظ.';

  @override
  String get userAdminEmployeeSearchHint => 'ابحث عن موظف';

  @override
  String get userAdminEmployeeNoResults => 'مفيش موظفين نشطين مطابقين.';

  @override
  String userAdminEmployeeLinkedTo(String user) {
    return 'مربوط بـ $user';
  }

  @override
  String userAdminEmployeeLinkedWarning(String user) {
    return 'الموظف ده مربوط بالفعل بحساب $user.';
  }

  @override
  String get userAdminBranchesNone => 'مفيش صلاحية على أي فرع';

  @override
  String get userAdminManageBranchAccess => 'إدارة صلاحيات الفروع';

  @override
  String get userAdminLastLogin => 'آخر دخول';

  @override
  String get userAdminCreatedOn => 'تاريخ الإنشاء';

  @override
  String get userAdminNever => 'لم يسجّل دخول';

  @override
  String get userAdminCreate => 'إنشاء المستخدم';

  @override
  String get userAdminNoChanges => 'مفيش تغييرات تتحفظ.';

  @override
  String userAdminSavedMessage(String name) {
    return 'تم حفظ $name.';
  }

  @override
  String userAdminCreatedMessage(String name) {
    return 'تم إنشاء $name.';
  }

  @override
  String get userAdminChangePassword => 'تغيير كلمة المرور';

  @override
  String userAdminPasswordDialogTitle(String name) {
    return 'كلمة مرور جديدة لـ $name';
  }

  @override
  String get userAdminSignedOutEverywhereNote =>
      'سيتم تسجيل خروج المستخدم من كل أجهزته.';

  @override
  String get userAdminSignOutEverywhere => 'تسجيل خروج المستخدم من كل الأجهزة';

  @override
  String userAdminPasswordChangedMessage(String name) {
    return 'تم تغيير كلمة مرور $name.';
  }

  @override
  String get userAdminDisable => 'إيقاف';

  @override
  String get userAdminEnable => 'تفعيل';

  @override
  String userAdminDisableTitle(String name) {
    return 'إيقاف $name؟';
  }

  @override
  String get userAdminDisableBody =>
      'هيتعمل له تسجيل خروج من كل الأجهزة، ومش هيقدر يدخل تاني غير لما الحساب يتفعّل.';

  @override
  String userAdminEnableTitle(String name) {
    return 'تفعيل $name؟';
  }

  @override
  String get userAdminEnableBody =>
      'هيقدر يسجّل دخول تاني بكلمة المرور الحالية.';

  @override
  String userAdminDisabledMessage(String name) {
    return 'تم إيقاف $name.';
  }

  @override
  String userAdminEnabledMessage(String name) {
    return 'تم تفعيل $name.';
  }

  @override
  String get userAdminDelete => 'حذف المستخدم';

  @override
  String userAdminDeleteTitle(String name) {
    return 'حذف $name نهائيًا؟';
  }

  @override
  String get userAdminDeleteBody =>
      'ده هيحذف الحساب نهائيًا ومفيش رجوع فيه. لو الشخص ساب الشغل، الأفضل توقف الحساب بدل الحذف عشان سجلّه يفضل موجود. الحساب المربوط بطلبات أو سجلات تانية مينفعش يتحذف.';

  @override
  String userAdminDeletedMessage(String name) {
    return 'تم حذف $name.';
  }

  @override
  String get userAdminUnsavedTitle => 'تجاهل التغييرات؟';

  @override
  String get userAdminUnsavedBody => 'التغييرات اللي عملتها لسه ما اتحفظتش.';

  @override
  String get userAdminDiscard => 'تجاهل';

  @override
  String get pnlTitle => 'الأرباح والخسائر';

  @override
  String get pnlSubtitle =>
      'إيرادات الشركات والأفراد، كل المصروفات، وصافي الربح، متطابقة مع الدفاتر';

  @override
  String get pnlTotalRevenue => 'إجمالي الإيرادات';

  @override
  String get pnlB2cRevenue => 'إيرادات الأفراد (B2C)';

  @override
  String get pnlB2bRevenue => 'إيرادات الشركات (B2B)';

  @override
  String get pnlGrossProfit => 'مجمل الربح';

  @override
  String get pnlTotalExpenses => 'إجمالي المصروفات';

  @override
  String get pnlNetProfit => 'صافي الربح';

  @override
  String get pnlShippingNet => 'فرق الشحن';

  @override
  String pnlMarginOf(String pct) {
    return 'هامش $pct%';
  }

  @override
  String get pnlRevenueTrend => 'الإيرادات حسب القناة';

  @override
  String get pnlChannelB2c => 'أفراد';

  @override
  String get pnlChannelB2b => 'شركات';

  @override
  String get pnlChannelStaff => 'موظفين';

  @override
  String get pnlChannelSamples => 'عينات';

  @override
  String get pnlChannelAdjustments => 'تسويات في الدفاتر';

  @override
  String get pnlChannelOther => 'أخرى';

  @override
  String get pnlShippingIncome => 'إيراد الشحن';

  @override
  String get pnlShippingExpense => 'مصروف الشحن';

  @override
  String get pnlChannelSplit => 'الشركات مقابل الأفراد';

  @override
  String pnlOrdersCount(int count) {
    return '$count طلب';
  }

  @override
  String pnlReturnsCount(int count) {
    return '$count مرتجع';
  }

  @override
  String get pnlStatement => 'قائمة الأرباح والخسائر';

  @override
  String get pnlSales => 'المبيعات';

  @override
  String get pnlCostOfSales => 'تكلفة المبيعات';

  @override
  String get pnlRecurringExpenses => 'المصروفات الثابتة';

  @override
  String get pnlOtherExpenses => 'مصروفات أخرى';

  @override
  String get pnlRevenueVsExpenses => 'الإيرادات مقابل المصروفات';

  @override
  String get pnlExpenses => 'المصروفات';

  @override
  String get pnlShippingTitle => 'الشحن: المحصّل مقابل المدفوع';

  @override
  String get pnlShippingDifference => 'الفرق';

  @override
  String pnlPerDelivery(String income, String expense, int count) {
    return 'لكل توصيلة: $income محصّل، $expense مدفوع ($count توصيلة)';
  }

  @override
  String pnlRecurringPosted(String posted, String due) {
    return 'اتسجل $posted من $due مستحق للشهور دي';
  }

  @override
  String get pnlExpenseMix => 'الفلوس راحت فين';

  @override
  String get pnlLedgerMatches => 'مطابق للدفاتر';

  @override
  String pnlLedgerMismatch(String amount) {
    return 'مختلف عن الدفاتر بـ $amount';
  }

  @override
  String pnlWarnCogs(String pct) {
    return 'تكلفة البضاعة متسجلة لـ $pct% بس من الطلبات في الفترة دي، فالربح هنا أعلى من الحقيقي.';
  }

  @override
  String pnlWarnShipping(String pct) {
    return '$pct% بس من تكلفة المناديب المسجلة على الطلبات وصلت للدفاتر، فمصروف الشحن أقل من الحقيقي.';
  }

  @override
  String pnlWarnRecurring(String posted, String due) {
    return 'المصروفات الثابتة: اتسجل $posted من $due مستحق للشهور دي.';
  }

  @override
  String get pnlNoteShippingInFreight =>
      'قبل سبتمبر ٢٠٢٦ إيراد الشحن كان بيتسجل جوه حساب مصاريف المناديب، وهنا بيظهر لوحده.';

  @override
  String get pnlRunningTotal => 'الإجمالي التراكمي للفترة';

  @override
  String get expensesPeriodLabel => 'الفترة المدفوعة';

  @override
  String get expensesPeriodFrom => 'من';

  @override
  String get expensesPeriodTo => 'إلى';

  @override
  String get expensesPeriodSelect => 'اختر الفترة';

  @override
  String get expensesPeriodHelper => 'تتوزع التكلفة على الشهور تلقائيًا';

  @override
  String get expensesPeriodRequired => 'اختر الفترة التي تغطيها الفاتورة';

  @override
  String get expensesPeriodFromAfterTo =>
      'يجب أن تبدأ الفترة قبل نهايتها أو في نفس اليوم';

  @override
  String get expensesPeriodAfterExpenseDate =>
      'الفترة لا يمكن أن تنتهي بعد تاريخ المصروف';

  @override
  String expensesPeriodValue(String from, String to) {
    return 'الفترة: $from – $to';
  }

  @override
  String get expensesPeriodTooLong => 'لا يمكن أن تزيد الفترة عن 366 يومًا';

  @override
  String get expensesPeriodJournalEntries => 'قيود توزيع الفترة';

  @override
  String get reportsRangeLastMonth => 'الشهر اللي فات';

  @override
  String reportShowAllCount(int count) {
    return 'عرض الكل ($count)';
  }

  @override
  String get reportShowLess => 'عرض أقل';

  @override
  String get reportOverridesTitle => 'تعديلات تكلفة المناديب';

  @override
  String get reportOverridesHint =>
      'التعديلات المعتمدة على اللي اتدفع للمندوب، مقارنةً بسعر المنطقة الأساسي';

  @override
  String get reportOverridesNetExtra => 'صافي الزيادة المدفوعة';

  @override
  String reportOverridesVsStandard(String pct) {
    return '$pct% فوق السعر الأساسي للطلبات دي';
  }

  @override
  String get reportOverridesExtraPaid => 'مدفوع فوق الأساسي';

  @override
  String reportOverridesIncreases(int count, String avg) {
    return '$count طلب، متوسط +$avg';
  }

  @override
  String get reportOverridesSaved => 'مدفوع أقل من الأساسي';

  @override
  String reportOverridesDecreases(int count) {
    return '$count طلب';
  }

  @override
  String get reportOverridesShare => 'طلبات عليها تعديل';

  @override
  String reportOverridesShareOf(int count, int total) {
    return '$count من $total توصيلة';
  }

  @override
  String get reportOverridesDecisions => 'القرارات';

  @override
  String reportOverridesDecisionsValue(
    int approved,
    int rejected,
    int pending,
  ) {
    return '$approved اتوافق · $rejected اترفض · $pending مستني';
  }

  @override
  String reportOverridesPendingExtra(String amount) {
    return 'الطلبات المستنية هتزود $amount';
  }

  @override
  String get reportOverridesByArea => 'الزيادة بتروح فين';

  @override
  String reportOverridesLargest(String pct) {
    return 'أكبر تعديل: +$pct%';
  }

  @override
  String get dealsTitle => 'أسعار خاصة';

  @override
  String get dealsSubtitle => 'سعر خاص لفترة محددة وبعدها يرجع السعر العادي';

  @override
  String get dealsNone => 'مفيش عروض شغالة';

  @override
  String get dealsNew => 'عرض جديد';

  @override
  String dealsHistory(int count) {
    return 'عروض قديمة ($count)';
  }

  @override
  String get dealStatusActive => 'شغال';

  @override
  String get dealStatusUpcoming => 'لسه هيبدأ';

  @override
  String get dealStatusExpired => 'خلص';

  @override
  String get dealStatusCancelled => 'اتلغى';

  @override
  String dealCategoryLabel(String group) {
    return 'كل $group';
  }

  @override
  String dealRateVsNormal(String rate, String normal) {
    return '$rate (بدل $normal)';
  }

  @override
  String get dealEditTitle => 'تعديل العرض';

  @override
  String get dealHelp =>
      'العميل ده هيدفع الأسعار دي على الطلبات اللي تتعمل في فترة العرض. بعد آخر يوم السعر العادي بيرجع لوحده.';

  @override
  String get dealPickDates => 'اختار تواريخ العرض';

  @override
  String get dealStartLocked =>
      'العرض الشغال بيفضل بنفس تاريخ البداية والأسعار لأن في طلبات اتحسبت بيها. تقدر تغير تاريخ النهاية، أو تنهيه وتعمل عرض جديد.';

  @override
  String get dealAddCategory => 'إضافة فئة';

  @override
  String get dealAddItem => 'إضافة صنف';

  @override
  String get dealRateLabel => 'سعر العرض';

  @override
  String dealNormalPrice(String amount) {
    return 'العادي: $amount';
  }

  @override
  String get dealEnd => 'إنهاء العرض';

  @override
  String get dealEndConfirm =>
      'تنهي العرض ده؟ طلبات النهارده هتفضل بسعر العرض، ومن بكره العميل ده هيدفع السعر العادي.';

  @override
  String get dealEnded => 'العرض انتهى';

  @override
  String get dealSaved => 'العرض اتحفظ';

  @override
  String get dealSaveFailed => 'مقدرناش نحفظ العرض';

  @override
  String get dealNeedsDates => 'اختار تواريخ العرض الأول';

  @override
  String get dealNeedsLines => 'ضيف سعر واحد على الأقل';

  @override
  String get dealInvalidRate => 'اكتب سعر صحيح في كل سطر';

  @override
  String get dealCancelled => 'العرض اتلغى';

  @override
  String get dealEndsTonight =>
      'العرض هينتهي النهارده. من بكره العميل ده هيدفع السعر العادي.';

  @override
  String get followupsMenuTitle => 'المتابعات';

  @override
  String get followupsTitle => 'متابعات النهارده';

  @override
  String get followupsSummaryDue => 'مستحقة';

  @override
  String get followupsSummaryOverdue => 'متأخرة';

  @override
  String get followupsSummaryCalls => 'مكالمات';

  @override
  String get followupsSummaryMessages => 'رسايل';

  @override
  String get followupsSectionOverdue => 'متأخر';

  @override
  String get followupsSectionToday => 'النهارده';

  @override
  String get followupsEmpty => 'مفيش متابعات مستحقة دلوقتي.';

  @override
  String get followupsLoadFailed => 'مقدرناش نحمّل المتابعات';

  @override
  String get followupsStep3h => 'بعد ٣ ساعات';

  @override
  String followupsStepDay(String day) {
    return 'اليوم $day';
  }

  @override
  String get followupsChannelMessage => 'رسالة';

  @override
  String get followupsChannelCall => 'مكالمة';

  @override
  String get followupsCustomerNew => 'جديد';

  @override
  String get followupsCustomerRepeat => 'متكرر';

  @override
  String get followupsValueHigh => 'قيمة عالية ≥ ١٠٠٠';

  @override
  String get followupsValueLow => 'أقل من ١٠٠٠';

  @override
  String get followupsRegular => 'منتظم';

  @override
  String followupsWooOrder(String number) {
    return 'أوردر #$number';
  }

  @override
  String followupsLifetimeOrders(String count) {
    return '$count أوردر';
  }

  @override
  String followupsDueAt(String time) {
    return 'معادها $time';
  }

  @override
  String get followupsActionWhatsapp => 'واتساب';

  @override
  String get followupsActionCopy => 'انسخ الرسالة';

  @override
  String get followupsActionCall => 'اتصل';

  @override
  String get followupsActionLog => 'سجّل النتيجة';

  @override
  String get followupsActionSkip => 'تخطّي';

  @override
  String get followupsMessageCopied => 'الرسالة اتنسخت';

  @override
  String get followupsNoWhatsapp => 'مفيش رقم واتساب للعميل ده';

  @override
  String get followupsNoPhone => 'مفيش رقم تليفون للعميل ده';

  @override
  String get followupsLogTitle => 'سجّل نتيجة المتابعة';

  @override
  String get followupsReachedLabel => 'العميل ردّ؟';

  @override
  String get followupsReached => 'ردّ';

  @override
  String get followupsNotReached => 'مردّش';

  @override
  String get followupsReachedRequired => 'اختار العميل ردّ ولا لأ';

  @override
  String get followupsOutcomeLabel => 'النتيجة';

  @override
  String get followupsOutcomeRequired => 'اختار النتيجة';

  @override
  String get followupsOutcomeHappy => 'سعيد';

  @override
  String get followupsOutcomeQuality => 'شكوى جودة';

  @override
  String get followupsOutcomeDelivery => 'شكوى توصيل';

  @override
  String get followupsOutcomeNoReply => 'مردّش';

  @override
  String get followupsOutcomeOptedOut => 'مش عايز رسايل';

  @override
  String get followupsNotesHint => 'ملاحظات (اختياري)';

  @override
  String get followupsConfirmQualityTitle => 'تسجّل شكوى جودة؟';

  @override
  String get followupsConfirmQualityBody =>
      'العميل ده هيخرج من دورة المتابعة، والشكوى هتروح لكريم.';

  @override
  String get followupsConfirmOptOutTitle => 'توقف الرسايل للعميل ده؟';

  @override
  String get followupsConfirmOptOutBody =>
      'العميل ده هيخرج من دورة المتابعة ومش هيوصله رسايل متابعة تاني.';

  @override
  String get followupsLogged => 'النتيجة اتسجلت';

  @override
  String followupsEscalated(String task) {
    return 'اتفتحت مهمة: $task';
  }

  @override
  String get followupsApologyTitle => 'كود الاعتذار';

  @override
  String get followupsApologyBody => 'ابعت الكود ده للعميل:';

  @override
  String get followupsApologyCopy => 'انسخ الكود';

  @override
  String get followupsApologyCopied => 'الكود اتنسخ';

  @override
  String get followupsApologySend => 'ابعته على واتساب';

  @override
  String get followupsSkipTitle => 'تتخطّى المتابعة دي؟';

  @override
  String get followupsSkipReasonHint => 'السبب (اختياري)';

  @override
  String get followupsSkipped => 'المتابعة اتخطّت';

  @override
  String get followupsStatsCalls => 'مكالمات اتعملت';

  @override
  String get followupsStatsReached => 'مكالمات اتردّ عليها';

  @override
  String get followupsStatsReachRate => 'نسبة الرد';

  @override
  String get followupsStatsReordered => 'طلبوا تاني';

  @override
  String get followupsStatsByStatus => 'حسب الحالة';

  @override
  String get followupsStatsByOutcome => 'حسب النتيجة';

  @override
  String get followupsStatsEmpty => 'مفيش بيانات لسه';

  @override
  String get followupsStatusPending => 'مستنية';

  @override
  String get followupsStatusDone => 'اتعملت';

  @override
  String get followupsStatusSkipped => 'اتخطّت';

  @override
  String get followupsStatsTotal => 'إجمالي المتابعات';

  @override
  String get followupsStatsTouchedCustomers => 'عملاء اتعملهم متابعة';

  @override
  String get followupsStatsReorderRate => 'نسبة الطلب تاني';

  @override
  String get followupsSentTotal => 'اتبعتت';

  @override
  String get followupsSentDelivered => 'وصلت';

  @override
  String get followupsSentRead => 'اتقرت';

  @override
  String get followupsSentFailed => 'فشلت';

  @override
  String get followupsSentReplied => 'ردّوا على واتساب';

  @override
  String get followupsSentReordered => 'طلبوا تاني (خلال ٣٠ يوم)';

  @override
  String get followupsSentOptedOut => 'عملاء وقفوا الرسايل';

  @override
  String get followupsSentRefused => 'واتساب رفضها، مستنية الموظفين';

  @override
  String get followupsSentByStep => 'حسب المرحلة';

  @override
  String get followupsSentByDay => 'حسب اليوم';

  @override
  String get followupsSentCancelled => 'اتلغت قبل الإرسال';

  @override
  String get followupsSentMessages => 'الرسايل';

  @override
  String followupsSentStepSummary(String sent, String read, String reordered) {
    return '$sent اتبعتت · $read اتقرت · $reordered طلبوا تاني';
  }

  @override
  String followupsSentCode(String code) {
    return 'كود $code';
  }

  @override
  String followupsSentReorderInvoice(String invoice) {
    return 'طلب تاني: $invoice';
  }

  @override
  String get followupsSentReasonOrderCancelled => 'الطلب اتلغى';

  @override
  String get followupsSentReasonOrderReturned => 'الطلب اترجع';

  @override
  String get followupsSentReasonExcluded => 'شركات / موظفين';

  @override
  String get followupsSentReasonNewOrder => 'طلب تاني';

  @override
  String get followupsSentReasonOptedOut => 'وقف الرسايل';

  @override
  String get followupsSentReasonQuality => 'شكوى جودة';

  @override
  String get customerSegmentRegular => 'منتظمين';

  @override
  String get rosterViewWeek => 'أسبوع';

  @override
  String get rosterViewMonth => 'شهر';

  @override
  String get rosterPreviousWeek => 'الأسبوع السابق';

  @override
  String get rosterNextWeek => 'الأسبوع التالي';

  @override
  String get rosterSelectDays => 'تحديد أيام';

  @override
  String get rosterLegendButton => 'معنى الخانات';

  @override
  String get rosterMoreOptions => 'خيارات إضافية';

  @override
  String rosterCoverShiftSummary(String shift) {
    return 'وردية التغطية: $shift';
  }

  @override
  String get rosterUncoveredFix => 'معالجة';

  @override
  String get rosterUncoveredListTitle => 'أيام إجازة بدون من يغطيها';

  @override
  String get rosterPlanAction => 'خطّط الجدول';

  @override
  String get rosterPlanTitle => 'تخطيط الجدول';

  @override
  String get rosterPlanStepWhen => 'إمتى';

  @override
  String get rosterPlanStepWho => 'مين';

  @override
  String get rosterPlanStepWeek => 'أسبوعهم';

  @override
  String get rosterPlanStepCheck => 'راجع ونفّذ';

  @override
  String get rosterPlanBack => 'رجوع';

  @override
  String get rosterPlanNext => 'التالي';

  @override
  String get rosterPlanApply => 'نفّذ';

  @override
  String get rosterPlanWhenQuestion => 'بتخطط لأنهي أيام؟';

  @override
  String get rosterPlanNextMonth => 'الشهر الجاي';

  @override
  String get rosterPlanRestOfMonth => 'باقي الشهر ده';

  @override
  String get rosterPlanCustom => 'تواريخ تانية';

  @override
  String get rosterPlanPickDates => 'اختار التواريخ';

  @override
  String rosterPlanPeriodRange(String start, String end, String days) {
    return 'من $start لحد $end ($days يوم)';
  }

  @override
  String rosterPlanPeriodTooLong(String max) {
    return 'دي أكتر من $max يوم. اختار مدة أقصر.';
  }

  @override
  String get rosterPlanPeriodNone => 'اختار التواريخ الأول.';

  @override
  String get rosterPlanStandingHint =>
      'الأسبوع اللي هتحدده هيكمّل بعد التواريخ دي كمان، والشهور اللي جاية هتمشي عليه لوحدها. التغطيات بس للتواريخ دي.';

  @override
  String get rosterPlanWhoQuestion => 'بتخطط لمين؟';

  @override
  String get rosterPlanSelectAll => 'اختار الكل';

  @override
  String get rosterPlanUnselectAll => 'شيل الكل';

  @override
  String rosterPlanSelectedCount(String count) {
    return '$count متختارين';
  }

  @override
  String get rosterPlanNoBranch => 'من غير فرع';

  @override
  String get rosterPlanNoPeople => 'مفيش حد تقدر تخطط له.';

  @override
  String get rosterPlanSameForEveryone => 'نفس الأسبوع للكل';

  @override
  String rosterPlanSameForEveryoneHint(String name) {
    return 'بينسخ وردية وأيام إجازة $name للباقيين.';
  }

  @override
  String rosterPlanSameForEveryoneDone(String name) {
    return 'اتنسخت وردية وأيام إجازة $name للكل.';
  }

  @override
  String get rosterPlanShift => 'الوردية';

  @override
  String get rosterPlanOtherShifts => 'ورديات تانية';

  @override
  String get rosterPlanBranch => 'الفرع';

  @override
  String get rosterPlanDaysOff => 'يوم الإجازة';

  @override
  String get rosterPlanWorksEveryDay => 'من غير إجازة: شغال كل يوم';

  @override
  String rosterPlanFridayVariant(String shift) {
    return 'يوم الجمعة يشتغل $shift';
  }

  @override
  String rosterPlanCoverQuestion(String day) {
    return 'مين هيغطي يوم $day؟';
  }

  @override
  String get rosterPlanNobodyCovers => 'محدش';

  @override
  String get rosterPlanCoverShift => 'وردية التغطية';

  @override
  String get rosterPlanPickShift => 'اختار وردية';

  @override
  String get rosterPlanNeedsShift => 'اختار وردية للشخص ده.';

  @override
  String get rosterPlanNeedsCoverShift => 'اختار وردية التغطية.';

  @override
  String get rosterPlanIncomplete =>
      'كل شخص محتاج وردية، وكل تغطية محتاجة وردية.';

  @override
  String get rosterPlanNoUsualWeek => 'مفيش أسبوع ثابت متسجّل لسه';

  @override
  String get rosterPlanWeekdaySaturday => 'السبت';

  @override
  String get rosterPlanWeekdaySunday => 'الأحد';

  @override
  String get rosterPlanWeekdayMonday => 'الإتنين';

  @override
  String get rosterPlanWeekdayTuesday => 'التلات';

  @override
  String get rosterPlanWeekdayWednesday => 'الأربع';

  @override
  String get rosterPlanWeekdayThursday => 'الخميس';

  @override
  String get rosterPlanWeekdayFriday => 'الجمعة';

  @override
  String get rosterPlanChecking => 'بنراجع الخطة…';

  @override
  String get rosterPlanCheckFailed => 'مقدرناش نراجع الخطة.';

  @override
  String get rosterPlanLoadFailed => 'مقدرناش نجيب الموظفين.';

  @override
  String get rosterPlanSummaryTitle => 'اللي هيحصل';

  @override
  String get rosterPlanSummaryPeople => 'أشخاص';

  @override
  String get rosterPlanSummaryShiftDays => 'أيام شغل';

  @override
  String get rosterPlanSummaryDayOffs => 'أيام إجازة';

  @override
  String get rosterPlanSummaryCovers => 'تغطيات';

  @override
  String get rosterPlanSummaryManualKept => 'أيام متعدلة بالإيد هتفضل زي ما هي';

  @override
  String get rosterPlanSummaryManualReplaced => 'أيام متعدلة بالإيد هتتغير';

  @override
  String get rosterPlanErrorsTitle => 'صلّح دول الأول';

  @override
  String get rosterPlanWarningsTitle => 'تستاهل تبص عليها';

  @override
  String get rosterPlanNotesTitle => 'للعلم';

  @override
  String rosterPlanIssueWhere(String name, String date) {
    return '$name · $date';
  }

  @override
  String get rosterPlanNoIssues => 'مفيش مشاكل.';

  @override
  String get rosterPlanApplyBlocked => 'صلّح المشاكل اللي بالأحمر علشان تنفّذ.';

  @override
  String get rosterPlanManualTitle => 'أيام اتعدلت بالإيد';

  @override
  String get rosterPlanManualHint =>
      'الأيام دي اتعدلت يوم بيوم، وهتفضل زي ما هي إلا لو اخترت تستبدلها.';

  @override
  String get rosterPlanReplaceManual => 'استبدلها هي كمان';

  @override
  String get rosterPlanManualEmpty => 'اتفضّى';

  @override
  String rosterPlanManualLine(String date, String current) {
    return '$date · $current';
  }

  @override
  String get rosterPlanGrantPos => 'ادّي اللي بيغطي صلاحية الكاشير في الفرع ده';

  @override
  String rosterPlanApplied(String count) {
    return 'الجدول اتعمل لـ $count شخص.';
  }

  @override
  String rosterRepeatWeekly(String weekday) {
    return 'كرّر كل $weekday';
  }

  @override
  String rosterRepeatWeeklyHelper(String weekday) {
    return 'من اليوم ده ورايح، ده هيبقى يوم $weekday المعتاد بتاعه.';
  }

  @override
  String get rosterRepeatUsualBranch => 'فرعه المعتاد';

  @override
  String get rosterRepeatNoPosAccess =>
      'صلاحية الكاشير بتتدي يوم بيوم، فالتغيير المتكرر مش بيديها.';

  @override
  String get rosterWeeklyReviewTitle => 'راجع التغيير الأسبوعي';

  @override
  String get rosterWeeklyChecking => 'بنراجع التغيير…';

  @override
  String get rosterWeeklyCheckFailed => 'مقدرناش نراجع التغيير.';

  @override
  String get rosterWeeklyStandingTitle => 'الأسبوع المعتاد';

  @override
  String rosterWeeklyStandingLine(
    String name,
    String weekday,
    String before,
    String after,
  ) {
    return '$name · $weekday: $before ← $after';
  }

  @override
  String get rosterWeeklyNothing => 'ولا حاجة';

  @override
  String get rosterWeeklyOff => 'إجازة';

  @override
  String rosterWeeklyChangeCount(
    int count,
    String countText,
    String weekday,
    String start,
    String through,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText يوم $weekday من $start لحد $through هيتغيروا.',
      one: 'يوم $weekday واحد ($start) هيتغير.',
    );
    return '$_temp0';
  }

  @override
  String rosterWeeklyNoDatedDays(String weekday) {
    return 'مفيش يوم $weekday موجود في الجدول هيتغير.';
  }

  @override
  String rosterWeeklyRotaFromAfter(String through, String rotaFrom) {
    return 'بعد $through، الجدول الأسبوعي هيكمّل بيه (من $rotaFrom).';
  }

  @override
  String rosterWeeklyRotaFrom(String rotaFrom) {
    return 'الجدول الأسبوعي هيكمّل بيه من $rotaFrom.';
  }

  @override
  String get rosterWeeklyReplacedHint => 'الأيام دي هتتغير هي كمان.';

  @override
  String get rosterWeeklyApply => 'طبّق كل أسبوع';

  @override
  String rosterWeeklyApplied(String weekday, String start) {
    return 'اتحفظ: كل $weekday من $start.';
  }

  @override
  String get rosterWeeklyNotApplied => 'متغيرش حاجة. راجع المعاينة وجرّب تاني.';

  @override
  String get courierAlertsTitle => 'تنبيهات المناديب';

  @override
  String get courierAlertsNoAccess =>
      'تنبيهات المناديب متاحة لمديري التوصيل بس.';

  @override
  String get courierAlertsFilterOpen => 'المفتوحة';

  @override
  String get courierAlertsFilterAll => 'الكل';

  @override
  String get courierAlertsEmptyOpen =>
      'مفيش تنبيهات مفتوحة. المناديب كلهم تمام.';

  @override
  String get courierAlertsEmptyAll => 'مفيش تنبيهات لسه.';

  @override
  String courierAlertsOpenCount(int count) {
    return '$count مفتوح';
  }

  @override
  String courierAlertsHighCount(int count) {
    return '$count عالي';
  }

  @override
  String get courierAlertsSeverityLow => 'منخفضة';

  @override
  String get courierAlertsSeverityMedium => 'متوسطة';

  @override
  String get courierAlertsSeverityHigh => 'عالية';

  @override
  String get courierAlertsStatusOpen => 'مفتوح';

  @override
  String get courierAlertsStatusReviewed => 'اتراجع';

  @override
  String get courierAlertsStatusDismissed => 'اتجاهل';

  @override
  String get courierAlertTypeDetour => 'انحراف عن المسار';

  @override
  String get courierAlertTypeExcessiveIdle => 'وقوف طويل';

  @override
  String get courierAlertTypeSpeeding => 'سرعة زايدة';

  @override
  String get courierAlertTypeDeliveredFarFromPin => 'تسليم بعيد عن الموقع';

  @override
  String get courierAlertTypePingGap => 'انقطاع في الإشارة';

  @override
  String get courierAlertTypeMockGps => 'موقع مزيّف';

  @override
  String get courierAlertTypeUnexpectedStop => 'وقفة غير متوقعة';

  @override
  String get courierAlertTypeStalePing => 'موقع قديم';

  @override
  String get courierAlertTypeTrackerModeChanged => 'تغيير وضع التتبع';

  @override
  String get courierAlertTypeTrackingLost => 'فقدان التتبع';

  @override
  String get courierAlertTypeActionRefused => 'إجراء مرفوض';

  @override
  String get courierAlertTypeDeliveryCodeFailed => 'كود التسليم غلط';

  @override
  String get courierAlertsFieldCourier => 'المندوب';

  @override
  String get courierAlertsFieldInvoice => 'الفاتورة';

  @override
  String get courierAlertsFieldBranch => 'الفرع';

  @override
  String get courierAlertsFieldDetected => 'وقت الرصد';

  @override
  String get courierAlertsFieldStatus => 'الحالة';

  @override
  String get courierAlertsFieldDetails => 'التفاصيل';

  @override
  String get courierAlertsFieldNote => 'ملاحظة المراجعة';

  @override
  String get courierAlertsNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get courierAlertsMarkReviewed => 'تمت المراجعة';

  @override
  String get courierAlertsDismiss => 'تجاهل';

  @override
  String get courierAlertsUpdated => 'التنبيه اتحدّث.';

  @override
  String get courierSetupEntry => 'المناديب';

  @override
  String get courierSetupTitle => 'المناديب';

  @override
  String get courierSetupAction => 'تجهيز مندوب';

  @override
  String get courierSetupSearchHint => 'ابحث بالاسم أو الفرع أو الحساب';

  @override
  String get courierSetupEmpty => 'مفيش موظفين.';

  @override
  String get courierSetupStatusReady => 'جاهز';

  @override
  String get courierSetupStatusNeedsFix => 'محتاج إصلاح';

  @override
  String get courierSetupStatusNotCourier => 'لسه مش مندوب';

  @override
  String get courierSetupSetUp => 'جهّزه كمندوب';

  @override
  String get courierSetupFix => 'إصلاح الإعداد (رقم سري جديد)';

  @override
  String get courierSetupResetPin => 'رقم سري جديد';

  @override
  String get courierSetupResetTitle => 'تغيير الرقم السري؟';

  @override
  String courierSetupResetBody(String name) {
    return '$name هياخد رقم سري جديد والقديم هيقف. الرقم الجديد هيظهر مرة واحدة بس.';
  }

  @override
  String get courierSetupFormTitle => 'تجهيز مندوب';

  @override
  String get courierSetupModeExisting => 'موظف موجود';

  @override
  String get courierSetupModeNew => 'شخص جديد';

  @override
  String get courierSetupEmployee => 'الموظف';

  @override
  String get courierSetupEmployeeHint => 'اكتب اسم للبحث';

  @override
  String get courierSetupFullName => 'الاسم بالكامل';

  @override
  String get courierSetupMobile => 'رقم الموبايل';

  @override
  String get courierSetupBranch => 'الفرع';

  @override
  String get courierSetupPosProfile => 'POS Profile (اختياري)';

  @override
  String get courierSetupPosProfileHelp =>
      'سيبه فاضي عشان يستخدم الافتراضي للفرع.';

  @override
  String get courierSetupSubmit => 'تجهيز';

  @override
  String get courierSetupProblemNoIdentity => 'الحساب مش مربوط بموظف';

  @override
  String get courierSetupProblemNoPosProfile => 'مش على POS Profile';

  @override
  String get courierSetupProblemNoEmployeeBranch => 'الموظف مالوش فرع';

  @override
  String get courierSetupProblemBranchNotAssigned =>
      'الفرع مش مطابق للـ POS Profile';

  @override
  String get courierSetupHintNoIdentity =>
      'افتح الموظف واختار الحساب في User ID وتأكد إن الموظف Active.';

  @override
  String get courierSetupHintNoPosProfile =>
      'ضيف الحساب في جدول Users في الـ POS Profile بتاع الفرع.';

  @override
  String get courierSetupHintNoEmployeeBranch => 'حدد الفرع في سجل الموظف.';

  @override
  String get courierSetupHintBranchNotAssigned =>
      'فرع الموظف وفرع الـ POS Profile لازم يبقوا نفس الفرع.';

  @override
  String get courierSetupDoneTitle => 'المندوب جاهز';

  @override
  String get courierSetupPinResetTitle => 'رقم سري جديد';

  @override
  String get courierSetupLoginId => 'رقم الدخول';

  @override
  String get courierSetupPinLabel => 'الرقم السري';

  @override
  String get courierSetupPinOnce =>
      'بيظهر مرة واحدة بس. انسخه أو ابعته دلوقتي، مش هيظهر تاني.';

  @override
  String get courierSetupNoPin =>
      'السيرفر ما رجّعش رقم سري. استخدم \"رقم سري جديد\" عشان تطلع واحد.';

  @override
  String get courierSetupWebLink => 'رابط الويب';

  @override
  String get courierSetupApkLink => 'تطبيق الأندرويد';

  @override
  String get courierSetupStillMissing => 'لسه ناقص';

  @override
  String get courierSetupShareWhatsapp => 'ابعت للمندوب على واتساب';

  @override
  String get courierSetupCopy => 'نسخ';

  @override
  String get courierSetupCopied => 'اتنسخ.';

  @override
  String get rptCourierBalancesPartnerFallback => 'شريك توصيل';

  @override
  String rptInstapayExpectedReference(String reference) {
    return 'المرجع: $reference';
  }

  @override
  String get rptRangeToday => 'اليوم';

  @override
  String get rptRangeYesterday => 'أمس';

  @override
  String get rptRangeLast7Days => 'آخر 7 أيام';

  @override
  String get rptRangeThisMonth => 'هذا الشهر';

  @override
  String get rptRangeLastMonth => 'الشهر الماضي';

  @override
  String get rptRangeLast30Days => 'آخر 30 يومًا';

  @override
  String get rptRangeLast90Days => 'آخر 90 يومًا';

  @override
  String get rptRangeThisYear => 'من بداية السنة';

  @override
  String get rptBranchLabel => 'الفرع';

  @override
  String get rptAllBranches => 'كل الفروع';

  @override
  String get rptExport => 'تصدير CSV';

  @override
  String get rptExportEmpty => 'لا توجد بيانات للتصدير بعد.';

  @override
  String get rptExportFailed => 'تعذّر تصدير التقرير.';

  @override
  String get rptExportCopied => 'المشاركة غير متاحة، لذلك تم نسخ التقرير.';

  @override
  String get rptHubOverview => 'نظرة عامة';

  @override
  String get rptHubDailyOps => 'التشغيل اليومي';

  @override
  String get rptHubSalesCustomers => 'المبيعات والعملاء';

  @override
  String get rptHubStock => 'المخزون';

  @override
  String get rptHubPeople => 'الفريق';

  @override
  String get rptBusinessOverviewTitle => 'نظرة عامة على النشاط';

  @override
  String get rptBusinessOverviewSubtitle =>
      'الأرباح والخسائر وأهم الأرقام والتقسيم حسب الفرع';

  @override
  String get rptUnitEconomicsTitle => 'اقتصاديات الطلب';

  @override
  String get rptUnitEconomicsSubtitle => 'هامش المساهمة لكل طلب ونقطة التعادل';

  @override
  String get rptDailyCloseTitle => 'إقفال اليوم';

  @override
  String get rptDailyCloseSubtitle => 'المبيعات حسب الفرع والقناة وطريقة الدفع';

  @override
  String get rptCashOverShortTitle => 'زيادة وعجز النقدية';

  @override
  String get rptCashOverShortSubtitle =>
      'فروقات الدرج حسب الفرع والكاشير والوردية';

  @override
  String get rptFulfilmentSlaTitle => 'زمن تنفيذ الطلبات';

  @override
  String get rptFulfilmentSlaSubtitle =>
      'زمن التجهيز والتوصيل والطلبات المتأخرة والإلغاءات';

  @override
  String get rptPromoTitle => 'أكواد الخصم';

  @override
  String get rptPromoSubtitle => 'الطلبات والخصم والإيراد لكل كود';

  @override
  String get rptStockAdjustmentsTitle => 'الهالك وتسويات المخزون';

  @override
  String get rptStockAdjustmentsSubtitle => 'قيمة المخزون المفقود والزائد';

  @override
  String get rptLabourCostTitle => 'تكلفة العمالة';

  @override
  String get rptLabourCostSubtitle => 'تكلفة العمالة مقارنة بالمبيعات لكل فرع';

  @override
  String get rptInventoryRestockTitle => 'المخزون وإعادة الطلب';

  @override
  String get rptInventoryRestockSubtitle =>
      'مستويات المخزون وسرعة البيع وما يجب طلبه';

  @override
  String get rptCustomersSegmentsTitle => 'العملاء والشرائح';

  @override
  String get rptCustomersSegmentsSubtitle =>
      'الاحتفاظ بالعملاء وأفضل العملاء وشرائح العملاء';

  @override
  String get rptShippingCouriersTitle => 'الشحن والمناديب';

  @override
  String get rptShippingCouriersSubtitle =>
      'تكلفة المناديب مقابل رسوم الشحن والأرصدة غير المسوّاة';

  @override
  String get rptComingSoon => 'هذا التقرير قيد التجهيز.';

  @override
  String get rptAccessDenied => 'ليس لديك صلاحية لعرض هذا التقرير.';

  @override
  String get rptB2bReportTooltip => 'تقرير مبيعات الشركات';

  @override
  String get rptAlertsTitle => 'التنبيهات';

  @override
  String get rptDailyCloseNetSales => 'صافي المبيعات';

  @override
  String get rptDailyCloseOrders => 'الطلبات';

  @override
  String get rptDailyCloseAvgOrder => 'متوسط قيمة الطلب';

  @override
  String get rptDailyCloseShipping => 'إيراد الشحن';

  @override
  String get rptDailyCloseReturns => 'المرتجعات';

  @override
  String rptDailyCloseReturnsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرتجع',
      many: '$count مرتجعًا',
      few: '$count مرتجعات',
      two: 'مرتجعان',
      one: 'مرتجع واحد',
      zero: 'لا مرتجعات',
    );
    return '$_temp0';
  }

  @override
  String get rptDailyCloseCancelled => 'الملغاة';

  @override
  String get rptDailyCloseGrossSales => 'إجمالي المبيعات';

  @override
  String get rptDailyCloseGrandTotal => 'الإجمالي الكلي';

  @override
  String get rptDailyCloseOutstanding => 'لم يُحصَّل بعد';

  @override
  String get rptDailyCloseOutstandingHint =>
      'يُسوّى لاحقًا بقيد يومية (طلبات، المناديب)';

  @override
  String get rptDailyCloseChannels => 'المبيعات حسب القناة';

  @override
  String get rptDailyCloseByHour => 'المبيعات حسب الساعة';

  @override
  String get rptDailyClosePayments => 'المدفوعات حسب طريقة الدفع';

  @override
  String get rptDailyCloseBranches => 'الفروع';

  @override
  String get rptDailyCloseBranchesHint =>
      'اضغط على الفرع لعرض قنواته ومدفوعاته';

  @override
  String get rptDailyCloseChannel => 'القناة';

  @override
  String get rptDailyCloseMode => 'طريقة الدفع';

  @override
  String get rptDailyCloseAmount => 'المبلغ';

  @override
  String get rptDailyCloseShare => 'النسبة';

  @override
  String get rptDailyCloseBranch => 'الفرع';

  @override
  String get rptDailyCloseHour => 'الساعة';

  @override
  String get rptDailyClosePrevDay => 'اليوم السابق';

  @override
  String get rptDailyCloseNextDay => 'اليوم التالي';

  @override
  String rptDailyCloseOrdersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب',
      many: '$count طلبًا',
      few: '$count طلبات',
      two: 'طلبان',
      one: 'طلب واحد',
      zero: 'لا طلبات',
    );
    return '$_temp0';
  }

  @override
  String get rptDailyCloseChannelPos => 'الفرع (نقطة البيع)';

  @override
  String get rptDailyCloseChannelWoo => 'المتجر الإلكتروني';

  @override
  String get rptDailyCloseChannelTalabat => 'طلبات';

  @override
  String get rptDailyCloseChannelB2b => 'الشركات';

  @override
  String get rptDailyCloseChannelStaff => 'الموظفون';

  @override
  String get rptDailyCloseChannelSamples => 'العينات';

  @override
  String get rptDailyCloseChannelPartner => 'شريك التوصيل';

  @override
  String rptDailyCloseScopedTo(String branches) {
    return 'مقتصر على فروعك: $branches';
  }

  @override
  String get rptCashOverShortShifts => 'الورديات';

  @override
  String get rptCashOverShortWithDiff => 'ورديات بها فرق';

  @override
  String get rptCashOverShortOver => 'زيادة';

  @override
  String get rptCashOverShortShort => 'عجز';

  @override
  String get rptCashOverShortNet => 'الصافي';

  @override
  String get rptCashOverShortBranches => 'حسب الفرع';

  @override
  String get rptCashOverShortCashiers => 'حسب الكاشير';

  @override
  String get rptCashOverShortCashiersHint => 'الأكبر عجزًا أولاً';

  @override
  String get rptCashOverShortCashier => 'الكاشير';

  @override
  String get rptCashOverShortBranch => 'الفرع';

  @override
  String get rptCashOverShortShiftList => 'إغلاقات الورديات';

  @override
  String get rptCashOverShortShiftListHint =>
      'الأحدث أولاً. اضغط على الوردية لعرض التفاصيل.';

  @override
  String get rptCashOverShortShift => 'الوردية';

  @override
  String get rptCashOverShortOpened => 'وقت الفتح';

  @override
  String get rptCashOverShortClosed => 'وقت الإغلاق';

  @override
  String get rptCashOverShortExpected => 'المتوقع';

  @override
  String get rptCashOverShortCounted => 'المعدود';

  @override
  String get rptCashOverShortDifference => 'الفرق';

  @override
  String get rptCashOverShortOpeningEntry => 'قيد الفتح';

  @override
  String get rptCashOverShortOpeningDifference => 'الفرق عند الفتح';

  @override
  String get rptCashOverShortLedger => 'حساب زيادة وعجز النقدية';

  @override
  String get rptCashOverShortLedgerHint =>
      'ما تم قيده في الدفاتر خلال هذه الفترة';

  @override
  String get rptCashOverShortAtClose => 'مقيد عند إغلاق الوردية';

  @override
  String get rptCashOverShortAtOpen => 'مقيد عند فتح الوردية';

  @override
  String get rptCashOverShortUnlinked => 'غير مرتبط بوردية';

  @override
  String get rptCashOverShortNotClosed => 'لم تُغلق';

  @override
  String get rptCashOverShortNoShifts => 'لا توجد ورديات مغلقة في هذه الفترة';

  @override
  String get rptSlaOrders => 'الطلبات';

  @override
  String get rptSlaDelivered => 'تم توصيلها';

  @override
  String get rptSlaCancelled => 'ملغاة';

  @override
  String get rptSlaReturned => 'مرتجعة';

  @override
  String get rptSlaMedianDispatch => 'الوقت الوسيط حتى الخروج للتوصيل';

  @override
  String get rptSlaMedianDeliver => 'الوقت الوسيط حتى التوصيل';

  @override
  String get rptSlaP90Deliver => '٩٠٪ من الطلبات وصلت خلال';

  @override
  String get rptSlaLateOrders => 'طلبات متأخرة';

  @override
  String get rptSlaOpenLate => 'متأخرة ولم تُسلَّم بعد';

  @override
  String rptSlaLatePct(String pct) {
    return '$pct٪ من الطلبات المسلّمة';
  }

  @override
  String rptSlaMinutes(String minutes) {
    return '$minutes د';
  }

  @override
  String rptSlaHoursMinutes(String hours, String minutes) {
    return '$hours س $minutes د';
  }

  @override
  String rptSlaLateRule(String minutes) {
    return 'متأخر = تم التوصيل بعد نهاية موعد التوصيل، أو بعد أكثر من $minutes دقيقة من الطلب إذا لم يكن له موعد.';
  }

  @override
  String rptSlaDataSince(String date) {
    return 'تُسجَّل أوقات الطلبات منذ $date؛ الطلبات الأقدم ليس لها أوقات.';
  }

  @override
  String rptSlaTimedCoverage(String dispatched, String delivered) {
    return 'طلبات بأوقات مسجّلة: $dispatched خرجت للتوصيل، $delivered تم توصيلها';
  }

  @override
  String get rptSlaByDay => 'زمن التوصيل حسب اليوم';

  @override
  String get rptSlaByDayHint => 'الوسيط بالدقائق من الطلب حتى التوصيل';

  @override
  String get rptSlaLateByDay => 'الطلبات المتأخرة حسب اليوم';

  @override
  String get rptSlaBranches => 'حسب الفرع';

  @override
  String get rptSlaBranch => 'الفرع';

  @override
  String get rptSlaDispatchCol => 'حتى الخروج';

  @override
  String get rptSlaDeliverCol => 'حتى التوصيل';

  @override
  String get rptSlaLateCol => 'متأخر';

  @override
  String get rptSlaLateList => 'الطلبات المتأخرة (الأسوأ أولاً)';

  @override
  String get rptSlaLateListHint => 'اضغط على الطلب لعرض أوقاته';

  @override
  String get rptSlaInvoice => 'الطلب';

  @override
  String get rptSlaCustomer => 'العميل';

  @override
  String get rptSlaLateBy => 'متأخر بمقدار';

  @override
  String get rptSlaCreated => 'وقت الطلب';

  @override
  String get rptSlaDeadline => 'الموعد النهائي';

  @override
  String get rptSlaDeliveredAt => 'وقت التوصيل';

  @override
  String get rptSlaNotDelivered => 'لم يُسلَّم بعد';

  @override
  String get rptSlaSlot => 'موعد التوصيل';

  @override
  String get rptSlaRule => 'معيار التأخير';

  @override
  String get rptSlaRuleSlot => 'نهاية موعد التوصيل';

  @override
  String get rptSlaRuleSlotStart => 'بداية الموعد + الحد الزمني';

  @override
  String get rptSlaRuleThreshold => 'الحد الزمني';

  @override
  String get rptSlaState => 'الحالة';

  @override
  String get rptSlaTotalTime => 'من الطلب حتى التوصيل';

  @override
  String get rptSlaCancellations => 'أسباب الإلغاء';

  @override
  String get rptSlaReason => 'السبب';

  @override
  String get rptSlaCount => 'العدد';

  @override
  String get rptSlaNoReason => 'بدون سبب';

  @override
  String get rptSlaNoLate => 'لا توجد طلبات متأخرة في هذه الفترة';

  @override
  String get rptSlaCopyInvoice => 'نسخ رقم الطلب';

  @override
  String get rptSlaCopied => 'تم نسخ رقم الطلب';

  @override
  String rptG1BranchGlNote(String branch) {
    return 'الفرع $branch: المبيعات وتكلفة البضاعة ودخل الشحن خاصة بهذا الفرع. المصروفات وصافي الربح ومطابقة الدفاتر على مستوى الشركة كلها.';
  }

  @override
  String get rptG1AtAGlance => 'نظرة سريعة';

  @override
  String get rptG1ByBranchTitle => 'حسب الفرع';

  @override
  String get rptG1ByBranchHint => 'اضغط على فرع لعرض أرقامه فقط';

  @override
  String get rptG1ColMargin => 'الهامش';

  @override
  String get rptG1ColMetric => 'البند';

  @override
  String get rptG1ColAmount => 'المبلغ';

  @override
  String get rptG1ShipCostVsCharged => 'تكلفة التوصيل مقابل المحصّل';

  @override
  String get rptG1ShipCostVsChargedHint =>
      'ما دفعه العملاء للتوصيل مقابل ما تكلّفه المندوبون';

  @override
  String get rptG1ShipLossByArea => 'الخسارة حسب المنطقة';

  @override
  String get rptG1ShipLossByAreaHint =>
      'صافي الشحن لكل منطقة، الأكبر خسارة أولاً';

  @override
  String get rptG1ColArea => 'المنطقة';

  @override
  String get rptG1ColCost => 'التكلفة';

  @override
  String get rptG1ColCharged => 'المحصّل';

  @override
  String get rptG1ColNet => 'الصافي';

  @override
  String get rptG1Settled => 'تمت تسويته';

  @override
  String rptG1UnsettledAsOf(String date) {
    return 'حتى $date';
  }

  @override
  String get rptG1ColCourier => 'المندوب';

  @override
  String get rptG1ColOwed => 'المستحق';

  @override
  String get rptG1ColDaysAged => 'الأيام';

  @override
  String get rptG1DoubleTrips => 'رحلات مزدوجة';

  @override
  String get rptG1DoubleExtraCost => 'تكلفة توصيل إضافية';

  @override
  String rptG1OverridesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تعديل',
      many: '$count تعديلاً',
      few: '$count تعديلات',
      two: 'تعديلان',
      one: 'تعديل واحد',
      zero: 'لا تعديلات',
    );
    return '$_temp0';
  }

  @override
  String get rptG1Units => 'الوحدات';

  @override
  String get rptG1ColType => 'النوع';

  @override
  String get rptG1CostBasis => 'أساس التكلفة';

  @override
  String get rptG1CostActual => 'فعلية';

  @override
  String get rptG1CostBom => 'تقديرية (الوصفة)';

  @override
  String get rptG1CostNone => 'بدون تكلفة';

  @override
  String rptG1CostCoverage(String pct) {
    return 'تكلفة البضاعة فعلية لـ $pct% من الإيراد، والباقي تقديري من الوصفات.';
  }

  @override
  String get rptG1OrdersTrend => 'الطلبات عبر الفترة';

  @override
  String get rptG1ProductTapHint => 'اضغط على منتج لعرض التفاصيل';

  @override
  String get rptG1AvgPrice => 'متوسط سعر الوحدة';

  @override
  String get rptG1CostPerUnit => 'تكلفة الوحدة';

  @override
  String get rptG1ColClient => 'العميل';

  @override
  String get rptG1ColGroup => 'المجموعة';

  @override
  String get rptG1ColClients => 'العملاء';

  @override
  String get rptG1ColLastOrder => 'آخر طلب';

  @override
  String get rptG1ColDaysSince => 'منذ (يوم)';

  @override
  String get rptG2RestockAll => 'الكل';

  @override
  String get rptG2RestockStatusOther => 'أخرى';

  @override
  String get rptG2ColumnSuggestedQty => 'الكمية المقترحة';

  @override
  String get rptG2ColumnDaysCover => 'أيام التغطية';

  @override
  String get rptG2RestockEmpty => 'لا توجد أصناف مطابقة لهذا الفلتر.';

  @override
  String get rptG2RestockHint => 'اضغط على أي صنف لعرض معدل بيعه.';

  @override
  String rptG2RecencyDaysAgo(String days) {
    return 'منذ $days يوم';
  }

  @override
  String rptG2OrdersCount(String count) {
    return '$count طلب';
  }

  @override
  String get rptG2SegmentOverlay => 'فئة إضافية';

  @override
  String get rptG2SegmentsOverlayNote =>
      'الفئات الإضافية تتداخل مع غيرها ولا تُحسب في الإجمالي.';

  @override
  String get rptG2ColumnMobile => 'الجوال';

  @override
  String get rptG2ColumnTerritory => 'المنطقة';

  @override
  String get rptG2ColumnUpdatedOn => 'تاريخ التحديث';

  @override
  String get rptG2CustomerSummaryTitle => 'ملخص العميل';

  @override
  String get rptG2StockValue => 'قيمة المخزون';

  @override
  String get rptG2GrandTotal => 'الإجمالي العام';

  @override
  String get rptG2GroupTotal => 'إجمالي المجموعة';

  @override
  String get rptG2TotalQty => 'إجمالي الكمية';

  @override
  String get rptG2Company => 'الشركة';

  @override
  String get rptG2Refresh => 'تحديث';

  @override
  String get rptUnitEconInputsTitle => 'مدخلات المالك';

  @override
  String get rptUnitEconInputsSubtitle =>
      'قيم تُدخلها بنفسك. هي تقديرات وغير مسجلة في الدفاتر.';

  @override
  String get rptUnitEconEditInputs => 'تعديل المدخلات';

  @override
  String get rptUnitEconAdSpend => 'الإنفاق الإعلاني';

  @override
  String get rptUnitEconAdSpendHelp => 'الإجمالي للفترة المحددة';

  @override
  String get rptUnitEconKashierPct => 'نسبة رسوم كاشير';

  @override
  String get rptUnitEconKashierPctHelp =>
      'تُطبق على الإيرادات المدفوعة عبر كاشير';

  @override
  String get rptUnitEconTalabatPct => 'نسبة عمولة طلبات';

  @override
  String get rptUnitEconTalabatPctHelp => 'تُطبق على إيرادات قناة طلبات';

  @override
  String get rptUnitEconExtraFixed => 'تكاليف ثابتة إضافية';

  @override
  String get rptUnitEconExtraFixedHelp =>
      'تكاليف غير مسجلة في الدفاتر مثل رواتب خارج كشف الرواتب أو عائد المستثمر أو الأدوات';

  @override
  String rptUnitEconAppliedAmount(String amount) {
    return 'المطبق في هذا التقرير: $amount';
  }

  @override
  String get rptUnitEconResetDefaults => 'استعادة القيم الافتراضية';

  @override
  String get rptUnitEconInvalidNumber => 'أدخل رقمًا يساوي صفرًا أو أكثر';

  @override
  String get rptUnitEconInvalidPct => 'أدخل نسبة بين 0 و100';

  @override
  String get rptUnitEconBadgeOwnerInput => 'مدخل من المالك';

  @override
  String get rptUnitEconBadgeEstimate => 'تقديري';

  @override
  String get rptUnitEconLegend =>
      'الأرقام الموسومة بـ«تقديري» أو «مدخل من المالك» ليست مبالغ مسجلة في الدفاتر.';

  @override
  String get rptUnitEconContributionMargin => 'هامش المساهمة';

  @override
  String get rptUnitEconNetProfit => 'صافي الربح';

  @override
  String get rptUnitEconWaterfallTitle => 'من الإيرادات إلى صافي الربح';

  @override
  String get rptUnitEconRevenue => 'الإيرادات';

  @override
  String get rptUnitEconCogs => 'تكلفة البضاعة';

  @override
  String get rptUnitEconShippingNet => 'صافي تكلفة التوصيل';

  @override
  String get rptUnitEconKashierFees => 'رسوم كاشير';

  @override
  String get rptUnitEconTalabatCommission => 'عمولة طلبات';

  @override
  String get rptUnitEconVariableTotal => 'التكاليف المتغيرة';

  @override
  String get rptUnitEconContribution => 'المساهمة';

  @override
  String get rptUnitEconRecurring => 'المصروفات المتكررة';

  @override
  String get rptUnitEconOtherExpenses => 'مصروفات أخرى';

  @override
  String get rptUnitEconFixedTotal => 'التكاليف الثابتة';

  @override
  String get rptUnitEconBreakEvenTitle => 'نقطة التعادل';

  @override
  String get rptUnitEconBreakEvenRevenue => 'إيرادات التعادل';

  @override
  String get rptUnitEconBreakEvenOrders => 'طلبات التعادل';

  @override
  String get rptUnitEconGap => 'الفجوة حتى التعادل';

  @override
  String rptUnitEconPastBreakEven(String amount) {
    return 'تجاوزت نقطة التعادل بمقدار $amount';
  }

  @override
  String rptUnitEconProgress(String pct) {
    return 'تم بلوغ $pct من إيرادات التعادل';
  }

  @override
  String get rptUnitEconNoBreakEven =>
      'لا توجد نقطة تعادل: الطلبات لا تغطي تكاليفها المتغيرة.';

  @override
  String get rptUnitEconPerOrderTitle => 'لكل طلب';

  @override
  String get rptUnitEconFees => 'الرسوم';

  @override
  String get rptUnitEconShipping => 'التوصيل';

  @override
  String get rptUnitEconNotesTitle => 'ملاحظات';

  @override
  String get rptUnitEconMetric => 'البند';

  @override
  String get rptUnitEconValue => 'القيمة';

  @override
  String get rptUnitEconNoteAdSpendIsOwnerInput =>
      'الإنفاق الإعلاني من إدخالك وليس مبلغًا مسجلًا.';

  @override
  String get rptUnitEconNoteAdSpendNotEntered =>
      'لم يتم إدخال الإنفاق الإعلاني، لذلك صافي الربح لا يشمل الإعلانات.';

  @override
  String get rptUnitEconNoteExtraFixedIsOwnerInput =>
      'التكاليف الثابتة الإضافية من إدخالك وليست مبالغ مسجلة.';

  @override
  String get rptUnitEconNoteKashierFeesEstimated =>
      'رسوم كاشير تقديرية بناءً على النسبة التي أدخلتها.';

  @override
  String get rptUnitEconNoteTalabatCommissionEstimated =>
      'عمولة طلبات تقديرية بناءً على النسبة التي أدخلتها.';

  @override
  String get rptUnitEconNoteBookedPartnerCommissionReplaced =>
      'تم استبدال عمولة الشريك المسجلة بالتقدير حتى لا تُحتسب مرتين.';

  @override
  String get rptUnitEconNoteBookedKashierFeesReplaced =>
      'تم استبدال رسوم كاشير المسجلة بالتقدير حتى لا تُحتسب مرتين.';

  @override
  String get rptUnitEconNoteStockAdjustmentInOther =>
      'تسويات المخزون مدرجة ضمن المصروفات الأخرى.';

  @override
  String get rptUnitEconNoteCogsIncomplete =>
      'تكلفة البضاعة غير مكتملة: بعض الأصناف بلا تكلفة.';

  @override
  String get rptUnitEconNoteShippingExpenseIncomplete =>
      'مصروف التوصيل غير مكتمل لهذه الفترة.';

  @override
  String get rptUnitEconNoteRecurringNotFullyPosted =>
      'بعض المصروفات المتكررة المستحقة في هذه الفترة لم تُسجل بعد.';

  @override
  String get rptUnitEconNoteAdsAlsoBooked =>
      'الإعلانات مسجلة أيضًا في الدفاتر؛ تأكد من عدم احتسابها مرتين.';

  @override
  String get rptUnitEconNoteContributionNotPositive =>
      'المساهمة ليست موجبة، لذلك لا توجد نقطة تعادل.';

  @override
  String get rptUnitEconBasisTitle => 'أساس الحساب';

  @override
  String get rptUnitEconBasisSubtitle =>
      'الأرقام المسجلة التي بُنيت عليها التقديرات';

  @override
  String get rptUnitEconBasisKashierReceipts => 'متحصلات كاشير';

  @override
  String get rptUnitEconBasisTalabatSales => 'مبيعات منصة طلبات';

  @override
  String get rptUnitEconBasisTalabatOrders => 'عدد طلبات منصة طلبات';

  @override
  String get rptUnitEconBasisShippingIncome => 'إيراد التوصيل';

  @override
  String get rptUnitEconBasisShippingExpense => 'مصروف التوصيل';

  @override
  String get rptUnitEconBasisStockAdjustment => 'تسوية المخزون';

  @override
  String get rptUnitEconBasisBookedPartnerCommission => 'عمولة الشريك المسجلة';

  @override
  String get rptUnitEconBasisBookedKashierFees => 'رسوم كاشير المسجلة';

  @override
  String get rptUnitEconBasisRecurringDue => 'المصروفات المتكررة المستحقة';

  @override
  String get rptUnitEconBasisCogsCoverage => 'المبيعات ذات التكلفة المعروفة';

  @override
  String get rptUnitEconBasisLedgerNetProfit => 'صافي الربح في الدفاتر';

  @override
  String get rptPromoConsumerOnly =>
      'طلبات المستهلكين فقط (بدون مبيعات الشركات)';

  @override
  String get rptPromoOrdersWithPromo => 'طلبات بكود خصم';

  @override
  String rptPromoShareOfOrders(String pct, String count) {
    return '$pct من $count طلب مستهلك';
  }

  @override
  String get rptPromoDiscountTotal => 'إجمالي الخصم';

  @override
  String get rptPromoRevenue => 'إيراد الطلبات بكود';

  @override
  String get rptPromoAov => 'متوسط الطلب بكود';

  @override
  String get rptPromoNonPromoAov => 'متوسط الطلب بدون كود';

  @override
  String rptPromoAovDiff(String diff) {
    return '$diff مقارنة بدون كود';
  }

  @override
  String get rptPromoNewCustomers => 'عملاء جدد عبر الأكواد';

  @override
  String get rptPromoCodesTitle => 'الأكواد';

  @override
  String get rptPromoCode => 'الكود';

  @override
  String get rptPromoOrders => 'الطلبات';

  @override
  String get rptPromoDiscount => 'الخصم';

  @override
  String get rptPromoRevenueShort => 'الإيراد';

  @override
  String get rptPromoAovShort => 'متوسط الطلب';

  @override
  String get rptPromoNew => 'عملاء جدد';

  @override
  String get rptPromoRepeatAfter => 'طلبوا مرة أخرى';

  @override
  String get rptPromoRepeatAfterHelp => 'عملاء طلبوا لاحقًا مرة أخرى بدون كود';

  @override
  String get rptPromoDiscountRate => 'الخصم كنسبة من الإيراد';

  @override
  String get rptPromoChartTitle => 'الإيراد والخصم لكل كود';

  @override
  String get rptPromoNoCodes => 'لم تُستخدم أي أكواد في هذه الفترة.';

  @override
  String get rptWasteLoss => 'مخزون مفقود';

  @override
  String get rptWasteGain => 'مخزون زائد';

  @override
  String get rptWasteNet => 'الصافي';

  @override
  String get rptWasteEntriesCount => 'الحركات';

  @override
  String get rptWasteByType => 'حسب النوع';

  @override
  String get rptWasteByBranch => 'حسب الفرع';

  @override
  String get rptWasteWorstItems => 'أكبر الخسائر حسب الصنف';

  @override
  String get rptWasteEntries => 'أحدث الحركات';

  @override
  String get rptWasteItem => 'الصنف';

  @override
  String get rptWasteItemCode => 'كود الصنف';

  @override
  String get rptWasteQty => 'الكمية';

  @override
  String get rptWasteUom => 'الوحدة';

  @override
  String get rptWasteValue => 'القيمة';

  @override
  String get rptWasteDate => 'التاريخ';

  @override
  String get rptWasteVoucher => 'المستند';

  @override
  String get rptWasteWarehouse => 'المخزن';

  @override
  String get rptWasteBranch => 'الفرع';

  @override
  String get rptWasteType => 'النوع';

  @override
  String get rptWasteRemarks => 'ملاحظات';

  @override
  String get rptWasteSignHint =>
      'القيم السالبة مخزون مفقود والموجبة مخزون زائد.';

  @override
  String get rptWasteTypeStockReconciliation => 'جرد المخزون';

  @override
  String get rptWasteTypeMaterialIssue => 'صرف مواد (هالك)';

  @override
  String get rptWasteTypeMaterialReceipt => 'استلام مواد';

  @override
  String get rptWasteTypeStockEntry => 'حركة مخزون';

  @override
  String get rptLabourPctOfSales => 'العمالة كنسبة من المبيعات';

  @override
  String get rptLabourCost => 'تكلفة العمالة';

  @override
  String get rptLabourSales => 'المبيعات';

  @override
  String get rptLabourHours => 'الساعات';

  @override
  String get rptLabourSalesPerHour => 'المبيعات لكل ساعة';

  @override
  String get rptLabourHeadcount => 'عدد الموظفين';

  @override
  String get rptLabourBasisSalarySlips => 'بناءً على قسائم الرواتب';

  @override
  String get rptLabourBasisSalarySlipsHelp =>
      'التكلفة من قسائم الرواتب موزعة على الفترة المحددة.';

  @override
  String get rptLabourBasisRecurring => 'بناءً على مصروفات الرواتب المتكررة';

  @override
  String get rptLabourBasisRecurringHelp =>
      'لا توجد قسائم رواتب لهذه الفترة، لذلك التكلفة من مصروفات الرواتب المتكررة موزعة على الفترة.';

  @override
  String get rptLabourBasisEstimate => 'تكلفة تقديرية';

  @override
  String get rptLabourBasisEstimateHelp =>
      'لم يتم العثور على رواتب لهذه الفترة، لذلك التكلفة تقديرية وقد تكون غير دقيقة.';

  @override
  String get rptLabourByBranch => 'حسب الفرع';

  @override
  String get rptLabourBranch => 'الفرع';

  @override
  String get rptLabourEmployees => 'الموظفون';

  @override
  String get rptLabourEmployee => 'الموظف';

  @override
  String get rptLabourEmployeeId => 'رقم الموظف';

  @override
  String get rptLabourDays => 'الأيام';

  @override
  String get rptLabourCostPerHour => 'التكلفة لكل ساعة';

  @override
  String get rptLabourUnassigned => 'غير محدد';

  @override
  String get rptLabourChartTitle => 'تكلفة العمالة مقابل المبيعات';

  @override
  String get rptG2ColumnStatus => 'الحالة';

  @override
  String get rptG2LastSale => 'آخر بيع';

  @override
  String get chatNavLabel => 'المحادثات';

  @override
  String get chatInboxTitle => 'المحادثات';

  @override
  String get chatNotAllowed => 'حسابك مالوش صلاحية على محادثات العملاء.';

  @override
  String get chatInboxLoadError => 'مقدرناش نحمّل المحادثات.';

  @override
  String get chatInboxEmpty => 'مفيش محادثات هنا لسه.';

  @override
  String get chatInboxEmptySearch => 'مفيش محادثات مطابقة للبحث.';

  @override
  String get chatSearchHint => 'ابحث بالاسم أو الموبايل';

  @override
  String get chatLoadMore => 'حمّل أكتر';

  @override
  String get chatLoadOlder => 'حمّل الرسايل الأقدم';

  @override
  String get chatSegmentOpen => 'مفتوحة';

  @override
  String get chatSegmentMine => 'بتاعتي';

  @override
  String get chatSegmentAll => 'الكل';

  @override
  String get chatSegmentClosed => 'مقفولة';

  @override
  String get chatChannelAll => 'كل القنوات';

  @override
  String get chatChannelWhatsApp => 'واتساب';

  @override
  String get chatChannelMessenger => 'ماسنجر';

  @override
  String get chatChannelInstagram => 'إنستجرام';

  @override
  String get chatChannelFacebookComment => 'تعليق فيسبوك';

  @override
  String get chatChannelInstagramComment => 'تعليق إنستجرام';

  @override
  String get chatStatusOpen => 'مفتوحة';

  @override
  String get chatStatusAnswered => 'اترد عليها';

  @override
  String get chatStatusClosed => 'مقفولة';

  @override
  String get chatIntentInquiry => 'استفسار';

  @override
  String get chatIntentOrder => 'طلب';

  @override
  String get chatIntentOther => 'أخرى';

  @override
  String get chatComplaintBadge => 'شكوى';

  @override
  String chatPreviewYou(String text) {
    return 'انت: $text';
  }

  @override
  String chatWaitingMinutes(String minutes) {
    return 'مستني من $minutes دقيقة';
  }

  @override
  String get chatDraftReadyTooltip => 'فيه رد مقترح جاهز';

  @override
  String chatAssignedTo(String name) {
    return 'متحولة لـ $name';
  }

  @override
  String get chatAssignedToYou => 'المحادثة دي بقت معاك.';

  @override
  String chatSentBy(String name) {
    return 'بعتها $name';
  }

  @override
  String get chatSentBySystem => 'اتبعتت أوتوماتيك';

  @override
  String get chatSentFromPhone => 'اتبعتت من الموبايل';

  @override
  String get chatMessageFailed => 'موصلتش';

  @override
  String get chatMessageImage => 'صورة';

  @override
  String get chatMessageAudio => 'رسالة صوتية';

  @override
  String get chatMessageVideo => 'فيديو';

  @override
  String get chatMessageDocument => 'ملف';

  @override
  String get chatMessageSticker => 'ستيكر';

  @override
  String get chatMessageLocation => 'لوكيشن';

  @override
  String get chatMessageReaction => 'تفاعل';

  @override
  String get chatMessageTemplate => 'رسالة جاهزة';

  @override
  String get chatMessageUnsupported => 'رسالة مش مدعومة';

  @override
  String get chatOpenInMaps => 'افتح على الخريطة';

  @override
  String get chatOpenMedia => 'افتح';

  @override
  String get chatMediaLoadFailed => 'مقدرناش نفتح الملف.';

  @override
  String get chatMediaUnavailable => 'الملف مش متاح';

  @override
  String get chatThreadLoadError => 'مقدرناش نحمّل المحادثة دي.';

  @override
  String get chatWindowClosedBanner =>
      'فترة الرد (24 ساعة) خلصت. ممكن العميل ميوصلوش رد عادي لحد ما يبعت تاني.';

  @override
  String get chatComposerHint => 'اكتب ردك';

  @override
  String get chatComposerSendTooltip => 'ابعت';

  @override
  String get chatActionAssignToMe => 'خليها معايا';

  @override
  String get chatActionClose => 'اقفل المحادثة';

  @override
  String get chatActionReopen => 'افتح المحادثة تاني';

  @override
  String get chatActionCustomerCard => 'بيانات العميل';

  @override
  String get chatActionLinkCustomer => 'اربط بعميل';

  @override
  String get chatActionStartOrder => 'ابدأ طلب';

  @override
  String get chatActionFailed => 'العملية منجحتش. جرّب تاني.';

  @override
  String get chatClosedDone => 'المحادثة اتقفلت.';

  @override
  String get chatReopenedDone => 'المحادثة اتفتحت تاني.';

  @override
  String get chatStartOrderNeedsCustomer => 'اربط المحادثة بعميل الأول.';

  @override
  String get chatCustomerNotLinked => 'المحادثة دي لسه مش مربوطة بعميل.';

  @override
  String get chatCustomerPhone => 'الموبايل';

  @override
  String get chatCustomerTerritory => 'المنطقة';

  @override
  String get chatCustomerTotalOrders => 'عدد الطلبات';

  @override
  String get chatCustomerLastOrder => 'آخر طلب';

  @override
  String get chatCustomerLifetimeValue => 'إجمالي المشتريات';

  @override
  String get chatCustomerRecentItems => 'آخر أصناف';

  @override
  String get chatLinkSearchHint => 'ابحث عن العميل بالاسم أو الموبايل';

  @override
  String get chatLinkNoResults => 'ملقيناش عملاء.';

  @override
  String get chatLinkSearchFailed => 'البحث عن العميل منجحش.';

  @override
  String chatLinkDone(String name) {
    return 'اتربطت بـ $name.';
  }

  @override
  String get chatDraftTitle => 'الرد المقترح';

  @override
  String get chatDraftEditedLabel => 'متعدّل';

  @override
  String get chatDraftUnavailable => 'مفيش رد مقترح — اكتب ردك بنفسك.';

  @override
  String chatDraftUpsell(String item) {
    return 'ضيف: $item';
  }

  @override
  String chatDraftNeedsHuman(String reason) {
    return 'محتاجك: $reason';
  }

  @override
  String get chatDraftComplaintLock =>
      'دي شكوى. عدّل الرد بأسلوبك قبل ما تبعته.';

  @override
  String get chatDraftRegenerate => 'اقترح رد تاني';

  @override
  String get chatDraftReject => 'ارفض';

  @override
  String get chatDraftEdit => 'عدّل';

  @override
  String get chatDraftSend => 'ابعت';

  @override
  String get chatPlantedTitle => 'اختبار تدريب';

  @override
  String chatPlantedNotSent(String error) {
    return 'اختبار تدريب — الرد ده كان فيه غلطة مقصودة: $error. متبعتش.';
  }

  @override
  String get chatPlantedNotSentNoDetail =>
      'اختبار تدريب — الرد ده كان فيه غلطة مقصودة. متبعتش.';

  @override
  String chatPlantedCaught(String error) {
    return 'برافو — الرد ده كان فيه غلطة مقصودة: $error. انت صلحتها ورَدّك اتبعت.';
  }

  @override
  String get chatPlantedCaughtNoDetail =>
      'برافو — الرد ده كان فيه غلطة مقصودة. انت صلحتها ورَدّك اتبعت.';

  @override
  String chatPlantedMissed(String error) {
    return 'اختبار تدريب — الرد ده كان فيه غلطة مقصودة: $error. رَدّك المتعدّل اتبعت بيها، فابعت للعميل تصحيح.';
  }

  @override
  String get chatPlantedMissedNoDetail =>
      'اختبار تدريب — الرد ده كان فيه غلطة مقصودة. رَدّك المتعدّل اتبعت بيها، فابعت للعميل تصحيح.';

  @override
  String get chatPlantedRealDraftReady => 'الرد الحقيقي جاهز تحت.';

  @override
  String get chatRejectTitle => 'ليه بترفض الرد ده؟';

  @override
  String get chatRejectChooseReason => 'اختار سبب.';

  @override
  String get chatRejectReasonWrongInfo => 'معلومة غلط';

  @override
  String get chatRejectReasonWrongPrice => 'سعر أو رقم غلط';

  @override
  String get chatRejectReasonTone => 'الأسلوب مش مناسب';

  @override
  String get chatRejectReasonOffTopic => 'مش بيرد على العميل';

  @override
  String get chatRejectReasonUpsell => 'اقتراح بيع إضافي مش مناسب';

  @override
  String get chatRejectReasonOther => 'سبب تاني';

  @override
  String get chatRejectNoteHint => 'ضيف ملاحظة (اختياري)';

  @override
  String get chatRejectNoteRequired => 'اكتب السبب من فضلك.';

  @override
  String get chatRejectConfirm => 'ارفض الرد';

  @override
  String get chatRejectCaught =>
      'برافو — الرد ده كان اختبار تدريب فيه غلطة مقصودة.';

  @override
  String get chatRegenerateTitle => 'اقترح رد تاني';

  @override
  String get chatRegenerateHintLabel => 'توجيه للرد الجديد (اختياري)';

  @override
  String get chatRegenerateHintExample => 'مثلاً: اذكر إن التوصيل مجاني';

  @override
  String get chatMetricsTitle => 'إحصائيات المحادثات';

  @override
  String get chatMetricsNotAllowed => 'إحصائيات المحادثات للمديرين بس.';

  @override
  String get chatMetricsLoadError => 'مقدرناش نحمّل الإحصائيات.';

  @override
  String get chatMetricsConversations => 'المحادثات';

  @override
  String get chatMetricsInbound => 'رسايل جات';

  @override
  String get chatMetricsOutbound => 'رسايل اتبعتت';

  @override
  String get chatMetricsMedianFirstResponse => 'متوسط أول رد';

  @override
  String chatMetricsMinutes(String minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get chatMetricsUnansweredOpen => 'مفتوحة ومتردش عليها';

  @override
  String get chatMetricsWaitingOverAlert => 'مستنية كتير';

  @override
  String get chatMetricsDrafts => 'الردود المقترحة';

  @override
  String get chatMetricsTotal => 'الإجمالي';

  @override
  String get chatMetricsAsIsRate => 'نسبة اللي اتبعت زي ما هو';

  @override
  String get chatMetricsSentAsIs => 'اتبعت من غير تعديل';

  @override
  String get chatMetricsSentEdited => 'اتبعت متعدّل';

  @override
  String get chatMetricsRejected => 'اترفض';

  @override
  String get chatMetricsSuperseded => 'اتلغى بعد رسالة جديدة';

  @override
  String get chatMetricsBlocked => 'اتمنع';

  @override
  String get chatMetricsPlanted => 'اختبارات التدريب اللي اتكشفت';

  @override
  String chatMetricsPlantedValue(String caught, String total) {
    return '$caught من $total';
  }

  @override
  String get chatMetricsCost => 'تكلفة الذكاء الاصطناعي';

  @override
  String get chatMetricsByModerator => 'حسب الموديريتور';

  @override
  String get chatMetricsNoModerators => 'مفيش ردود في الفترة دي.';

  @override
  String get chatMetricsModerator => 'الموديريتور';

  @override
  String get chatMetricsModSent => 'اتبعت';

  @override
  String get chatMetricsModAsIs => 'زي ما هو';

  @override
  String get chatMetricsModEdited => 'متعدّل';

  @override
  String get rptRevenueDashboardTitle => 'لوحة الإيرادات';

  @override
  String get rptRevenueDashboardSubtitle =>
      'اليوم مقابل نفس اليوم الأسبوع الماضي، وما يحتاج متابعة';

  @override
  String get rptRevAtAGlance => 'نظرة سريعة';

  @override
  String get rptRevToday => 'اليوم';

  @override
  String get rptRevYesterday => 'أمس';

  @override
  String get rptRevLast7Days => 'آخر ٧ أيام';

  @override
  String get rptRevMonthToDate => 'منذ بداية الشهر';

  @override
  String get rptRevCustom => 'فترة مخصصة';

  @override
  String get rptRevB2c => 'الأفراد (B2C)';

  @override
  String get rptRevB2b => 'قطاع الأعمال (B2B)';

  @override
  String get rptRevOther => 'أخرى (موظفين، عينات)';

  @override
  String get rptRevColB2c => 'أفراد';

  @override
  String get rptRevColB2b => 'أعمال';

  @override
  String get rptRevColNet => 'الصافي';

  @override
  String get rptRevNetSales => 'صافي المبيعات';

  @override
  String get rptRevAverageOrder => 'متوسط الطلب';

  @override
  String rptRevVsPeriod(String period) {
    return 'مقابل $period';
  }

  @override
  String rptRevVsPeriodUpTo(String period, String time) {
    return 'مقابل $period حتى الساعة $time';
  }

  @override
  String rptRevCaptionB2c(String amount) {
    return 'أفراد $amount';
  }

  @override
  String rptRevCaptionB2b(String amount) {
    return 'أعمال $amount';
  }

  @override
  String rptRevNewCustomersCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString عميل جديد',
      few: '$countString عملاء جدد',
      two: 'عميلان جديدان',
      one: 'عميل جديد واحد',
      zero: 'لا عملاء جدد',
    );
    return '$_temp0';
  }

  @override
  String rptRevDeliveryPickup(String delivery, String pickup) {
    return '$delivery توصيل / $pickup استلام';
  }

  @override
  String rptRevDiscountsAmount(String amount) {
    return 'خصومات $amount';
  }

  @override
  String rptRevReturnsAmount(String amount) {
    return 'مرتجعات $amount';
  }

  @override
  String rptRevCancelledShort(String count) {
    return 'ملغي $count';
  }

  @override
  String rptRevTotalInclShipping(String amount) {
    return 'الإجمالي شامل الشحن $amount';
  }

  @override
  String rptRevDailyAverageAmount(String amount) {
    return 'المتوسط اليومي $amount';
  }

  @override
  String rptRevBestDayOn(String day, String amount) {
    return 'الأفضل $day $amount';
  }

  @override
  String rptRevWorstDayOn(String day, String amount) {
    return 'الأضعف $day $amount';
  }

  @override
  String get rptRevDeliveryFees => 'رسوم التوصيل';

  @override
  String get rptRevDailyAverage => 'المتوسط اليومي';

  @override
  String get rptRevReturns => 'المرتجعات';

  @override
  String get rptRevCancelled => 'الملغاة';

  @override
  String get rptRevDiscounts => 'الخصومات';

  @override
  String get rptRevNeedsAttention => 'يحتاج متابعة';

  @override
  String get rptRevNothingNeedsAttention => 'لا يوجد ما يحتاج متابعة';

  @override
  String rptRevAttnCancelled(int count, String amount) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString طلب ملغي',
      few: '$countString طلبات ملغاة',
      two: 'طلبان ملغيان',
      one: 'طلب ملغي واحد',
    );
    return '$_temp0 · $amount';
  }

  @override
  String rptRevAttnReturns(int count, String amount) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString مرتجع',
      few: '$countString مرتجعات',
      two: 'مرتجعان',
      one: 'مرتجع واحد',
    );
    return '$_temp0 · $amount';
  }

  @override
  String rptRevAttnBranchDrop(
    String name,
    String pct,
    String amount,
    String compare,
  ) {
    return 'مبيعات الأفراد في $name أقل بـ $pct% ($amount مقابل $compare)';
  }

  @override
  String rptRevAttnSourceDrop(
    String name,
    String pct,
    String amount,
    String compare,
  ) {
    return '$name أقل بـ $pct% ($amount مقابل $compare)';
  }

  @override
  String rptRevAttnDiscountHigh(String amount, String pct, String compare) {
    return 'الخصومات $amount = $pct% من المبيعات (مقابل $compare%)';
  }

  @override
  String get rptRevWhereFrom => 'مصادر المبيعات';

  @override
  String get rptRevBySourceTitle => 'حسب المصدر';

  @override
  String get rptRevSourcePos => 'نقطة البيع / الهاتف';

  @override
  String get rptRevSourceWoo => 'الموقع الإلكتروني';

  @override
  String get rptRevSourceTalabat => 'طلبات';

  @override
  String get rptRevSourcePartner => 'شريك';

  @override
  String get rptRevSourceStaff => 'الموظفين';

  @override
  String get rptRevSourceSamples => 'العينات';

  @override
  String get rptRevByPaymentTitle => 'حسب طريقة الدفع';

  @override
  String get rptRevByBranchTitle => 'حسب الفرع';

  @override
  String get rptRevNoProfile => 'بدون فرع';

  @override
  String get rptRevByHour => 'حسب الساعة';

  @override
  String get rptRevByHourSubtitle => 'صافي المبيعات لكل ساعة';

  @override
  String rptRevHourTooltip(String hour, String orders, String amount) {
    return 'الساعة $hour:00 · $orders طلب · $amount';
  }

  @override
  String get rptRevLinkProducts => 'المنتجات';

  @override
  String get rptRevLinkB2b => 'عملاء قطاع الأعمال';

  @override
  String rptRevUpdatedAt(String time) {
    return 'آخر تحديث $time';
  }

  @override
  String get rptRevBranchCashTitle => 'النقدية في الفروع الآن';

  @override
  String get rptRevBranchCashError => 'تعذر تحميل نقدية الفروع';

  @override
  String get managerBarOrders => 'الطلبات';

  @override
  String get managerBarProducts => 'المنتجات';

  @override
  String get managerBarMore => 'المزيد';

  @override
  String get stockHandoverTabHandovers => 'التسليمات';

  @override
  String get stockHandoverTabTransfer => 'تحويل كامل';

  @override
  String get stockHandoverNoAccess =>
      'افتح وردية على فرعك عشان تسجّل استلام وتسليم البضاعة.';

  @override
  String stockHandoverLoadFailed(String reason) {
    return 'مقدرناش نحمّل التسليمات: $reason';
  }

  @override
  String stockHandoverWaitingForYou(int count) {
    return 'مستنية تأكيدك ($count)';
  }

  @override
  String stockHandoverWaitingForThem(int count) {
    return 'مستنية الطرف التاني ($count)';
  }

  @override
  String stockHandoverRecent(int count) {
    return 'الأخيرة ($count)';
  }

  @override
  String get stockHandoverNothingWaiting => 'مفيش حاجة مستنياك.';

  @override
  String stockHandoverRoute(String source, String target) {
    return 'من $source لـ $target';
  }

  @override
  String stockHandoverDeclaredBy(String name, String time) {
    return 'سجّلها $name · $time';
  }

  @override
  String stockHandoverChangedBy(String name, String time) {
    return 'عدّلها $name · $time';
  }

  @override
  String stockHandoverAwaiting(String side) {
    return 'مستنية $side';
  }

  @override
  String get stockHandoverChangedBadge => 'متعدّلة';

  @override
  String get stockHandoverStatusPending => 'مستنية';

  @override
  String get stockHandoverStatusConfirmed => 'اتأكدت';

  @override
  String get stockHandoverStatusRejected => 'اترفضت';

  @override
  String get stockHandoverStatusCancelled => 'اتلغت';

  @override
  String stockHandoverReason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String stockHandoverEntry(String entry) {
    return 'قيد $entry';
  }

  @override
  String get stockHandoverConfirm => 'تأكيد';

  @override
  String get stockHandoverChange => 'تعديل';

  @override
  String get stockHandoverReject => 'رفض';

  @override
  String get stockHandoverCancel => 'إلغاء التسليم';

  @override
  String get stockHandoverConfirmTitle => 'تأكيد التسليم ده؟';

  @override
  String stockHandoverConfirmBody(String source, String target) {
    return 'البضاعة هتتنقل من $source لـ $target دلوقتي.';
  }

  @override
  String get stockHandoverRejectTitle => 'رفض التسليم ده؟';

  @override
  String get stockHandoverRejectReasonHint => 'السبب (اختياري)';

  @override
  String get stockHandoverCancelTitle => 'إلغاء التسليم ده؟';

  @override
  String get stockHandoverCancelBody =>
      'لسه مفيش حاجة اتنقلت، والطرف التاني مش هيتطلب منه يأكدها.';

  @override
  String get stockHandoverKeep => 'سيبها';

  @override
  String stockHandoverConfirmedSnack(String entry) {
    return 'اتأكدت. البضاعة اتنقلت ($entry).';
  }

  @override
  String get stockHandoverRejectedSnack => 'اترفض التسليم.';

  @override
  String get stockHandoverCancelledSnack => 'اتلغى التسليم.';

  @override
  String stockHandoverSentSnack(String side) {
    return 'اتبعتت. مستنية $side تأكد.';
  }

  @override
  String get stockHandoverActingAs => 'إنت';

  @override
  String get stockHandoverIReceived => 'استلمت';

  @override
  String get stockHandoverFromWhom => 'استلمت من مين؟';

  @override
  String get stockHandoverNoCounterparts =>
      'مفيش طرف تاني تستلم منه أو تسلّمه.';

  @override
  String get stockHandoverItemsTitle => 'ضيف الأصناف';

  @override
  String get stockHandoverEditTitle => 'تعديل الكميات';

  @override
  String stockHandoverReviewButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مراجعة ($count صنف)',
      few: 'مراجعة ($count أصناف)',
      two: 'مراجعة (صنفين)',
      one: 'مراجعة (صنف واحد)',
      zero: 'مراجعة',
    );
    return '$_temp0';
  }

  @override
  String get stockHandoverNoItems => 'مفيش أصناف بين الطرفين دول.';

  @override
  String get stockHandoverReviewTitle => 'مراجعة';

  @override
  String stockHandoverReviewReceived(String name) {
    return 'إنت استلمت من $name:';
  }

  @override
  String stockHandoverReviewChange(String source, String target) {
    return 'الكميات الصح، من $source لـ $target:';
  }

  @override
  String stockHandoverReviewTotal(String qty) {
    return 'الإجمالي: $qty';
  }

  @override
  String get stockHandoverReviewHint =>
      'مفيش حاجة هتتنقل غير لما الطرف التاني يأكد.';

  @override
  String get stockHandoverBack => 'رجوع';

  @override
  String get stockHandoverSend => 'تأكيد وإرسال';

  @override
  String get stockHandoverDiscardTitle => 'تلغي الكميات اللي كتبتها؟';

  @override
  String get stockHandoverDiscard => 'إلغاء';

  @override
  String get stockHandoverKeepEditing => 'كمّل';

  @override
  String get stockHandoverISentOut => 'بعتّ بضاعة';

  @override
  String get stockHandoverReviewSentOut => 'إنت بعتّ:';

  @override
  String stockHandoverReviewHintSentOut(String side) {
    return 'البضاعة دي هتخرج من $side دلوقتي وتبقى «في الطريق». المدير هيطابقها مع الفروع اللي هتستلمها.';
  }

  @override
  String get stockHandoverSentOutSnack => 'اتسجّلت. البضاعة دلوقتي في الطريق.';

  @override
  String get stockHandoverNoChangeHint => 'مفيش تغيير. أكّدها بدل كده.';

  @override
  String stockHandoverDispatchTitle(String source) {
    return '$source بعتّ بضاعة';
  }

  @override
  String get stockHandoverDispatchWaiting =>
      'في الطريق · مستنية المدير يطابقها';

  @override
  String get stockHandoverGroupWaiting => 'مستنية المدير يطابقها';

  @override
  String get stockHandoverUnknownSender => 'مش عارف مين بعتها';

  @override
  String get stockHandoverUnknownSenderHint => 'المدير هيطابقها مع اللي اتبعت';

  @override
  String get stockHandoverUnknownSenderLabel => 'مش معروف مين بعت';

  @override
  String get stockHandoverReviewReceivedUnknown =>
      'إنت استلمت (مش عارف من مين):';

  @override
  String get stockHandoverReviewHintUnknown =>
      'المدير هيطابقها مع اللي اتبعت. مفيش حاجة هتتنقل قبل كده.';

  @override
  String get stockHandoverSentToManagerSnack =>
      'اتبعتت. مستنية المدير يطابقها.';

  @override
  String get stockTransitEntryTitle => 'البضاعة اللي في الطريق';

  @override
  String stockTransitEntryToApprove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count استلام مستني موافقتك',
      few: '$count استلامات مستنية موافقتك',
      two: 'استلامين مستنيين موافقتك',
      one: 'استلام واحد مستني موافقتك',
      zero: 'مفيش حاجة مستنية موافقة',
    );
    return '$_temp0';
  }

  @override
  String get stockTransitEntrySubtitle => 'طابق اللي اتبعت مع اللي وصل';

  @override
  String get stockTransitTitle => 'البضاعة اللي في الطريق';

  @override
  String get stockTransitSummaryToApprove => 'مستنية موافقة';

  @override
  String get stockTransitSummaryUnits => 'قطع في الطريق';

  @override
  String get stockTransitSummaryOverdue => 'بعتات متأخرة';

  @override
  String stockTransitSectionToApprove(int count) {
    return 'مستنية موافقتك ($count)';
  }

  @override
  String stockTransitSectionInTransit(int count) {
    return 'في الطريق ($count)';
  }

  @override
  String get stockTransitNothingToApprove => 'مفيش استلامات مستنية موافقة.';

  @override
  String get stockTransitNothingInTransit => 'مفيش بضاعة في الطريق.';

  @override
  String stockTransitReceivedBy(String target) {
    return '$target استلم';
  }

  @override
  String stockTransitNamedChip(String source) {
    return 'بيقول من $source';
  }

  @override
  String get stockTransitUnknownChip => 'مش عارف مين بعت';

  @override
  String stockTransitUnresolved(String qty) {
    return '$qty من غير مصدر';
  }

  @override
  String stockTransitLeftToAssign(String qty) {
    return 'فاضل تحدد مصدر $qty';
  }

  @override
  String stockTransitOverAssigned(String qty) {
    return 'متحدد زيادة $qty';
  }

  @override
  String get stockTransitAllAssigned => 'كله متحدد';

  @override
  String get stockTransitTapToChoose => 'دوس عشان تحدد جت منين';

  @override
  String get stockTransitEditedByYou => 'إنت اللي حددتها';

  @override
  String stockTransitReceivedChanged(String was, String now) {
    return 'المستلم $was ← $now';
  }

  @override
  String stockTransitReasonExact(String source, String qty) {
    return 'مطابقة بالظبط — $source بعت $qty';
  }

  @override
  String stockTransitReasonOnlySender(String source) {
    return '$source بس اللي بعت الصنف ده';
  }

  @override
  String get stockTransitReasonSameShipment => 'نفس شحنة باقي الأصناف';

  @override
  String get stockTransitReasonSentBefore => 'اتبعتت قبل ما تتستلم';

  @override
  String get stockTransitReasonSentAfter => 'اتبعتت بعد ما اتستلمت — راجعها';

  @override
  String stockTransitReasonUsual(String source, String percent) {
    return 'غالبًا بتيجي من $source ($percent%)';
  }

  @override
  String stockTransitReasonNamed(String source) {
    return 'اللي استلم قال إنها من $source';
  }

  @override
  String get stockTransitReasonSplit => 'متقسمة على أكتر من بعتة';

  @override
  String get stockTransitReasonNoSend =>
      'محدش سجّل إنه بعت الصنف ده — اتأكد مين بعت';

  @override
  String get stockTransitConfidenceHigh => 'متأكدين';

  @override
  String get stockTransitConfidenceMedium => 'غالبًا';

  @override
  String get stockTransitConfidenceLow => 'راجعها';

  @override
  String get stockTransitApprove => 'موافقة';

  @override
  String get stockTransitCannotApproveOwn =>
      'إنت اللي سجّلت الاستلام ده. لازم مدير تاني يوافق عليه.';

  @override
  String stockTransitApprovedSnack(String target, String entry) {
    return 'تمت الموافقة. البضاعة اتنقلت لـ $target ($entry).';
  }

  @override
  String stockTransitRejectTitle(String target) {
    return 'ترفض اللي $target استلمه؟';
  }

  @override
  String get stockTransitRejectBody =>
      'مفيش حاجة هتتنقل، واللي استلم هيشوف إنها اترفضت.';

  @override
  String get stockTransitReasonRequiredHint => 'السبب (لازم)';

  @override
  String get stockTransitRejectedSnack => 'اترفض الاستلام.';

  @override
  String get stockTransitDriftSnack =>
      'حاجة اتغيرت في الوقت ده. حدّثنا الشاشة — راجع تاني.';

  @override
  String get stockTransitApproveConfident => 'وافق على المتأكدين منها';

  @override
  String get stockTransitApproveConfidentNone =>
      'مفيش استلام متأكدين منه بالكامل لسه.';

  @override
  String stockTransitApproveConfidentTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'توافق على $count استلام متأكدين منهم؟',
      few: 'توافق على $count استلامات متأكدين منهم؟',
      two: 'توافق على استلامين متأكدين منهم؟',
      one: 'توافق على استلام واحد متأكدين منه؟',
    );
    return '$_temp0';
  }

  @override
  String get stockTransitApproveConfidentBody =>
      'كل سطر تحت ليه مصدر واحد أكيد. كل استلام بيتوافق عليه لوحده.';

  @override
  String stockTransitApproveConfidentButton(int count) {
    return 'وافق على $count';
  }

  @override
  String stockTransitApproveConfidentDone(int ok, int failed) {
    return 'اتوافق على $ok، و$failed متوافقش عليهم';
  }

  @override
  String stockTransitApproveConfidentChanged(String receipt) {
    return '$receipt اتغير في الوقت ده — سبناه لك تراجعه';
  }

  @override
  String stockTransitSheetTitle(String item) {
    return '$item — جت منين؟';
  }

  @override
  String get stockTransitActuallyReceived => 'اللي وصل فعلًا';

  @override
  String stockTransitDeclaredQty(String qty) {
    return 'اتسجّل $qty';
  }

  @override
  String get stockTransitOpenSends => 'البعتات اللي في الطريق';

  @override
  String stockTransitSendLeft(String qty) {
    return 'فاضل $qty';
  }

  @override
  String stockTransitReservedElsewhere(String qty) {
    return '$qty منهم مقترحين لاستلامات تانية';
  }

  @override
  String get stockTransitOverRemaining => 'أكتر من اللي فاضل في البعتة دي';

  @override
  String get stockTransitNoOpenSends => 'محدش باعت الصنف ده.';

  @override
  String get stockTransitNotDeclared => 'اللي بعت ماسجّلش';

  @override
  String get stockTransitAddNotDeclared => 'اللي بعت ماسجّلش — اختار مين بعت';

  @override
  String get stockTransitPickSender => 'مين بعتها؟';

  @override
  String get stockTransitNoSenders => 'مفيش طرف تاني تختاره.';

  @override
  String get stockTransitFillRest => 'كمّل الباقي';

  @override
  String get stockTransitResetSuggestion => 'رجّع الاقتراح';

  @override
  String get stockTransitSuggested => 'مقترحة';

  @override
  String get stockTransitDone => 'تمام';

  @override
  String get stockTransitRemove => 'شيل';

  @override
  String stockTransitAgeHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'في الطريق من $hours ساعة',
      few: 'في الطريق من $hours ساعات',
      two: 'في الطريق من ساعتين',
      one: 'في الطريق من ساعة',
      zero: 'لسه حالًا',
    );
    return '$_temp0';
  }

  @override
  String stockTransitAgeDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'في الطريق من $days يوم',
      few: 'في الطريق من $days أيام',
      two: 'في الطريق من يومين',
      one: 'في الطريق من يوم',
    );
    return '$_temp0';
  }

  @override
  String get stockTransitOverdue => 'متأخرة';

  @override
  String stockTransitLeftOf(String left, String total) {
    return 'فاضل $left من $total';
  }

  @override
  String get stockTransitReturn => 'رجّعها للي بعت';

  @override
  String get stockTransitWriteOff => 'اعتبرها فاقد';

  @override
  String stockTransitReturnTitle(String source) {
    return 'ترجيع لـ $source';
  }

  @override
  String stockTransitReturnBody(String source) {
    return 'القطع دي هترجع لمخزون $source.';
  }

  @override
  String stockTransitWriteOffTitle(String source) {
    return 'فاقد من بعتة $source';
  }

  @override
  String get stockTransitWriteOffBody =>
      'القطع دي هتتسجّل فاقد، ومينفعش ترجع فيها.';

  @override
  String stockTransitWriteOffConfirmTitle(String qty) {
    return 'تسجّل $qty قطعة فاقد؟';
  }

  @override
  String stockTransitReturnConfirm(String qty) {
    return 'رجّع $qty';
  }

  @override
  String stockTransitWriteOffConfirm(String qty) {
    return 'سجّل $qty فاقد';
  }

  @override
  String stockTransitReturnedSnack(String source) {
    return 'رجعت لـ $source.';
  }

  @override
  String get stockTransitWrittenOffSnack => 'اتسجّلت فاقد.';

  @override
  String get stockTransitCannotActOwn =>
      'إنت اللي بعتّ دي. لازم مدير تاني يرجّعها أو يسجّلها فاقد.';

  @override
  String stockTransitSentBy(String name, String time) {
    return 'بعتها $name · $time';
  }

  @override
  String get userErrorHandoverRule => 'التسليم ده مينفعش يتم لسه.';

  @override
  String get stockTransferBecomesOfficialNote =>
      'بتبقى رسمية لما الطرف التاني يأكد، وبتتسجّل وقتها.';

  @override
  String get stockTransferPostDirectTitle => 'ترحيل فوري (بدون تأكيد)';

  @override
  String get stockTransferPostDirectSubtitle =>
      'الكمية بتتحرك فوراً، والفرع مش محتاج يأكد.';

  @override
  String stockTransferSentPending(String handover) {
    return 'اتبعت. مستني الطرف التاني يأكد ($handover).';
  }

  @override
  String replenishmentSentPendingBody(
    int lineCount,
    String totalQty,
    String name,
    String handover,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      lineCount,
      locale: localeName,
      other: '$lineCount سطر',
      few: '$lineCount سطور',
      two: 'سطرين',
      one: 'سطر واحد',
    );
    return '$_temp0 · $totalQty قطعة · مستني $name يأكد ($handover)';
  }

  @override
  String get menuWeeklyCount => 'الجرد الأسبوعي';

  @override
  String get menuWeeklyCountApprovals => 'موافقات الجرد';

  @override
  String get approvalsQueueBranchCounts => 'الجرد الأسبوعي';

  @override
  String get weeklyCountTitle => 'الجرد الأسبوعي';

  @override
  String get weeklyCountApprovalsTitle => 'موافقات الجرد';

  @override
  String get weeklyCountDetailTitle => 'مراجعة الجرد';

  @override
  String get weeklyCountLoadError => 'تعذر تحميل الجرد الأسبوعي';

  @override
  String get weeklyCountNoBranches => 'لا يوجد فرع مطلوب منك جرده';

  @override
  String get weeklyCountPickBranch => 'اختر الفرع';

  @override
  String get weeklyCountOtherBranches => 'فروع أخرى';

  @override
  String get weeklyCountChangeBranch => 'تغيير الفرع';

  @override
  String weeklyCountWeekRange(String start, String end) {
    return 'أسبوع $start – $end';
  }

  @override
  String get weeklyCountStateDue => 'مطلوب الجرد';

  @override
  String get weeklyCountStatePending => 'بانتظار موافقة المدير';

  @override
  String get weeklyCountStateDone => 'تم جرد هذا الأسبوع ✓';

  @override
  String get weeklyCountStateRejected => 'الجرد مرفوض — أعد العد';

  @override
  String weeklyCountCountedBy(String name, String time) {
    return 'عدّه $name · $time';
  }

  @override
  String weeklyCountApprovedBy(String name) {
    return 'اعتمده $name';
  }

  @override
  String weeklyCountRejectionReason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get weeklyCountRecount => 'إعادة العد';

  @override
  String get weeklyCountReviewButton => 'مراجعة الجرد';

  @override
  String weeklyCountProgress(int counted, int total) {
    return '$counted / $total تم عدّه';
  }

  @override
  String get weeklyCountSectionLarge => 'كبير';

  @override
  String get weeklyCountSectionMedium => 'وسط';

  @override
  String get weeklyCountSectionSmall => 'صغير';

  @override
  String get weeklyCountLabelsHeading => 'ليبلات عملاء الجملة';

  @override
  String get weeklyCountAllZero => 'الكل صفر';

  @override
  String get weeklyCountAllZeroTitle => 'تعيين صفر؟';

  @override
  String weeklyCountAllZeroBody(int count, String section) {
    return 'سيتم وضع صفر لـ $count صنف لم يُعدّ بعد في قسم $section. الأصناف التي عددتها لن تتغير.';
  }

  @override
  String get weeklyCountAllZeroNothing => 'كل أصناف هذا القسم معدودة بالفعل';

  @override
  String get weeklyCountUncounted => 'لم يُعدّ';

  @override
  String get weeklyCountSubmit => 'إرسال الجرد';

  @override
  String weeklyCountFinishFirst(int count) {
    return 'يجب عدّ كل الأصناف أولاً — باقي $count';
  }

  @override
  String get weeklyCountEmptySheet => 'لا توجد أصناف للجرد في هذا الفرع';

  @override
  String get weeklyCountKeypadClear => 'مسح';

  @override
  String get weeklyCountKeypadUncount => 'إلغاء العد';

  @override
  String get weeklyCountSubmitConfirmTitle => 'إرسال الجرد؟';

  @override
  String weeklyCountSubmitConfirmSummary(String branch, int count) {
    return '$branch · تم عدّ $count صنف';
  }

  @override
  String get weeklyCountSubmitConfirmApprover => 'سيتم تحديث المخزون فوراً';

  @override
  String get weeklyCountSubmitConfirmStaff => 'سيُرسل للمدير للموافقة';

  @override
  String get weeklyCountSubmitConfirmButton => 'إرسال';

  @override
  String get weeklyCountDoneTitle => 'تم إرسال الجرد';

  @override
  String get weeklyCountDonePosted => 'تم تحديث المخزون';

  @override
  String get weeklyCountBackHome => 'العودة للرئيسية';

  @override
  String weeklyCountBannerDue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      few: '$days أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return 'الجرد الأسبوعي مطلوب — باقي $_temp0';
  }

  @override
  String get weeklyCountBannerLastDay => 'الجرد الأسبوعي مطلوب — اليوم آخر يوم';

  @override
  String get weeklyCountBannerRejected => 'الجرد الأسبوعي مرفوض — أعد العد';

  @override
  String get weeklyCountErrMissingItems =>
      'لم يتم عدّ كل الأصناف. تم تحديث القائمة، عدّ الأصناف الناقصة.';

  @override
  String get weeklyCountErrUnknownItems =>
      'بعض الأصناف لم تعد ضمن جرد هذا الفرع. تم تحديث القائمة.';

  @override
  String get weeklyCountErrInvalidQty =>
      'كمية غير صحيحة. استخدم أرقاماً صحيحة من صفر فأكثر.';

  @override
  String get weeklyCountErrAlreadyPending =>
      'يوجد جرد لهذا الفرع بانتظار موافقة المدير.';

  @override
  String get weeklyCountErrAlreadyDone =>
      'تم جرد هذا الفرع بالفعل هذا الأسبوع.';

  @override
  String get weeklyCountErrNoAccess => 'ليس لديك صلاحية على هذا الفرع.';

  @override
  String get weeklyCountErrNoWarehouse =>
      'هذا الفرع ليس له مخزن. تواصل مع المدير.';

  @override
  String get weeklyCountErrReasonRequired => 'اكتب سبب الرفض.';

  @override
  String get weeklyCountErrNotPending => 'هذا الجرد تمت مراجعته بالفعل';

  @override
  String get weeklyCountErrNotFound => 'الجرد غير موجود';

  @override
  String get weeklyCountErrPostFailed =>
      'تعذر ترحيل الجرد، حاول مرة أخرى أو تواصل مع المدير';

  @override
  String get weeklyCountErrNoItems => 'لا توجد أصناف للجرد في هذا الفرع';

  @override
  String get weeklyCountErrOwnCount =>
      'لا يمكنك مراجعة جرد قمت به بنفسك، يراجعه مدير آخر';

  @override
  String get weeklyCountApprovalsPending => 'بانتظار الموافقة';

  @override
  String get weeklyCountApprovalsNonePending => 'لا يوجد جرد بانتظار الموافقة';

  @override
  String get weeklyCountApprovalsHistory => 'آخر الجرد';

  @override
  String get weeklyCountApprovalsNoHistory => 'لا يوجد جرد سابق';

  @override
  String get weeklyCountApproverOnly => 'موافقة الجرد للمديرين فقط';

  @override
  String weeklyCountDifferences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اختلاف',
      few: '$count اختلافات',
      two: 'اختلافان',
      one: 'اختلاف واحد',
      zero: 'بدون اختلاف',
    );
    return '$_temp0';
  }

  @override
  String weeklyCountItemsCount(int count) {
    return '$count صنف';
  }

  @override
  String get weeklyCountStatusPendingApproval => 'بانتظار الموافقة';

  @override
  String get weeklyCountStatusApproved => 'معتمد';

  @override
  String get weeklyCountStatusRejected => 'مرفوض';

  @override
  String get weeklyCountStatusCancelled => 'ملغي';

  @override
  String get weeklyCountColCounted => 'المعدود';

  @override
  String get weeklyCountColSystem => 'النظام';

  @override
  String get weeklyCountColDifference => 'الفرق';

  @override
  String weeklyCountNoDifference(int count) {
    return 'بدون اختلاف ($count)';
  }

  @override
  String get weeklyCountApprove => 'اعتماد';

  @override
  String get weeklyCountReject => 'رفض';

  @override
  String get weeklyCountApproveTitle => 'اعتماد الجرد؟';

  @override
  String get weeklyCountApproveBody => 'سيتم تعديل المخزون بالفرق';

  @override
  String get weeklyCountRejectTitle => 'رفض الجرد';

  @override
  String get weeklyCountRejectHint => 'سبب الرفض (مطلوب)';

  @override
  String get weeklyCountRejectQuickCareful => 'أعد العد بعناية';

  @override
  String get weeklyCountRejectQuickUnreasonable => 'عدد غير منطقي';

  @override
  String get weeklyCountRejectQuickSizes => 'راجع الأحجام (كبير / وسط / صغير)';

  @override
  String get weeklyCountApprovedToast => 'تم اعتماد الجرد';

  @override
  String get weeklyCountRejectedToast => 'تم رفض الجرد';

  @override
  String get rosterFilterAll => 'الكل';

  @override
  String get rosterFilterTooltip => 'تصفية حسب الفرع أو الشخص';

  @override
  String get rosterFilterTitle => 'المعروض في الجدول';

  @override
  String get rosterFilterHelp =>
      'بدون اختيار يظهر الجميع. يظهر الشخص إذا اخترته هو أو أحد فروعه.';

  @override
  String get rosterFilterBranches => 'الفروع';

  @override
  String get rosterFilterPeople => 'الأشخاص';

  @override
  String get rosterFilterSelectAll => 'تحديد الكل';

  @override
  String get rosterFilterSearchHint => 'ابحث عن شخص';

  @override
  String get rosterFilterNoPeople => 'لا يوجد أحد مطابق';

  @override
  String get rosterFilterApply => 'تطبيق';

  @override
  String rosterFilterBranchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فروع',
      two: 'فرعان',
      one: 'فرع واحد',
    );
    return '$_temp0';
  }

  @override
  String rosterFilterPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أشخاص',
      two: 'شخصان',
      one: 'شخص واحد',
    );
    return '$_temp0';
  }

  @override
  String rosterFilterPeopleAndBranches(String people, String branches) {
    return '$people + $branches';
  }

  @override
  String get rosterFilterNoMatch => 'لا يوجد أحد في الجدول يطابق هذه التصفية';

  @override
  String get attendanceCheckoutCorrected =>
      'ضغط تسجيل انصراف عند الوصول — احتُسب تسجيل حضور';

  @override
  String get attendanceMissedCheckout => 'لم يسجّل انصراف';

  @override
  String attendanceLogTypeNote(String note) {
    return 'ملاحظة: $note';
  }

  @override
  String attendanceOriginalLogType(String original) {
    return 'ضغط $original، واحتُسب بشكل مختلف';
  }

  @override
  String get attendanceApproveDevice => 'اعتماد هذا الهاتف';

  @override
  String get attendanceApproveDeviceConfirmTitle => 'اعتماد هذا الهاتف؟';

  @override
  String attendanceApproveDeviceConfirmBody(String name) {
    return 'سيصبح هذا الهاتف جهاز $name المعتمد وسيُزال تنبيه الجهاز الجديد.';
  }

  @override
  String attendanceApproveDeviceDone(String name) {
    return 'تم اعتماد الهاتف لـ $name';
  }

  @override
  String attendanceApproveDeviceFailed(String error) {
    return 'تعذّر اعتماد الهاتف: $error';
  }

  @override
  String get followupsWrittenByClaude => 'كتبها Claude';

  @override
  String get followupsActionRewrite => 'اكتبها تاني';

  @override
  String get followupsActionBrief => 'نبذة قبل المكالمة';

  @override
  String get followupsBriefLoading => 'بنجهّز النبذة...';

  @override
  String get followupsBriefRefresh => 'حدّث النبذة';

  @override
  String get followupsBriefFailed => 'مقدرناش نحمّل النبذة';

  @override
  String get followupsBriefEmpty => 'مفيش نبذة متاحة للعميل ده.';

  @override
  String get followupResultsTitle => 'نتائج المتابعة';

  @override
  String get followupResultsRange7 => '٧ أيام';

  @override
  String get followupResultsRange30 => '٣٠ يوم';

  @override
  String get followupResultsRangeMonth => 'الشهر ده';

  @override
  String get followupResultsRangeCustom => 'فترة محددة';

  @override
  String get followupResultsRangePickerHelp => 'اختار الفترة';

  @override
  String get followupResultsTabOverview => 'نظرة عامة';

  @override
  String get followupResultsTabMessages => 'الرسايل';

  @override
  String get followupResultsTabReplies => 'الردود';

  @override
  String get followupResultsTabOrders => 'الطلبات';

  @override
  String get followupResultsTabCalls => 'المكالمات';

  @override
  String get followupResultsCostTitle => 'التكلفة مقابل الطلبات';

  @override
  String get followupResultsTotalCost => 'إجمالي التكلفة';

  @override
  String get followupResultsMessagesCost => 'الرسايل';

  @override
  String followupResultsMessagesCostDetail(String count, String each) {
    return '$count × $each';
  }

  @override
  String get followupResultsDiscountsCost => 'خصومات اتدّت';

  @override
  String get followupResultsOrders => 'الطلبات';

  @override
  String get followupResultsRevenue => 'المبيعات';

  @override
  String get followupResultsNet => 'الصافي';

  @override
  String get followupResultsRoi => 'العائد';

  @override
  String followupResultsRoiValue(String value) {
    return '×$value';
  }

  @override
  String get followupResultsCostPerOrder => 'تكلفة الطلب';

  @override
  String followupResultsOrdersWithCode(String count, String amount) {
    return 'طلبات استخدمت كود: $count ($amount)';
  }

  @override
  String get followupResultsCostNote =>
      'الطلبات المحسوبة هي اللي اتعملت خلال ٣٠ يوم بعد الرسالة. تكلفة الرسالة الواحدة بتتحدد من إعدادات المتابعة.';

  @override
  String followupResultsCustomers(String count) {
    return '$count عميل اتبعتلهم رسايل';
  }

  @override
  String get followupResultsFunnelTitle => 'من الرسالة للطلب';

  @override
  String get followupResultsReplied => 'ردّوا';

  @override
  String get followupResultsOrdered => 'طلبوا';

  @override
  String get followupResultsCodesTitle => 'الأكواد';

  @override
  String get followupResultsCodesIssued => 'اتصدرت';

  @override
  String get followupResultsCodesUsed => 'اتستخدمت';

  @override
  String get followupResultsCodesUnused => 'لسه متستخدمتش';

  @override
  String get followupResultsCodesExpired => 'انتهت';

  @override
  String get followupResultsAttentionTitle => 'حاجات تستاهل نظرة';

  @override
  String get followupResultsSearchHint =>
      'الاسم أو التليفون أو الكود أو الفاتورة';

  @override
  String get followupResultsFilterStep => 'المرحلة';

  @override
  String get followupResultsFilterStatus => 'الحالة';

  @override
  String get followupResultsFilterOutcome => 'النتيجة';

  @override
  String get followupResultsOutcomeUsedCode => 'استخدموا الكود';

  @override
  String get followupResultsOutcomeNoResponse => 'مفيش استجابة';

  @override
  String get followupResultsClearFilters => 'مسح الفلاتر';

  @override
  String followupResultsCountLine(String shown, String total) {
    return '$shown من $total رسالة';
  }

  @override
  String followupResultsTruncated(String shown, String total) {
    return 'معروض آخر $shown من $total رسالة. ضيّق الفترة عشان تشوف الباقي.';
  }

  @override
  String get followupResultsMessagesEmpty => 'مفيش رسايل مطابقة';

  @override
  String get followupResultsRepliesEmpty => 'مفيش ردود في الفترة دي';

  @override
  String get followupResultsOrdersEmpty =>
      'مفيش طلبات جت بعد الرسايل في الفترة دي';

  @override
  String get followupResultsCodeUsed => 'اتستخدم';

  @override
  String get followupResultsCodeUnused => 'متستخدمش';

  @override
  String get followupResultsCodeExpired => 'انتهى';

  @override
  String get followupResultsTierVip => 'VIP';

  @override
  String get followupResultsTierLoyal => 'وفيّ';

  @override
  String get followupResultsTierRepeat => 'بيكرر الطلب';

  @override
  String get followupResultsTierOneBig => 'طلب واحد كبير';

  @override
  String get followupResultsTierOne => 'طلب واحد';

  @override
  String get followupResultsReplyImage => '[صورة]';

  @override
  String get followupResultsReplyVoice => '[رسالة صوتية]';

  @override
  String get followupResultsReplyVideo => '[فيديو]';

  @override
  String get followupResultsReplyDocument => '[ملف]';

  @override
  String get followupResultsReplySticker => '[ملصق]';

  @override
  String get followupResultsReplyLocation => '[موقع]';

  @override
  String get followupResultsReplyButton => '[ضغط على زر]';

  @override
  String get followupResultsReplyOther => '[مرفق]';

  @override
  String get followupResultsStopReply => 'طلب وقف الرسايل';

  @override
  String followupResultsRepliesCount(String count) {
    return '$count ردود';
  }

  @override
  String get followupResultsSheetReplies => 'الردود';

  @override
  String get followupResultsSheetOrders => 'الطلبات بعد الرسالة';

  @override
  String get followupResultsSheetNoReplies => 'مفيش ردود';

  @override
  String get followupResultsSheetNoOrders => 'مفيش طلبات';

  @override
  String followupResultsSheetMoreReplies(String count) {
    return '$count ردود تانية مش معروضة';
  }

  @override
  String get followupResultsSheetCode => 'الكود';

  @override
  String followupResultsSheetDiscount(String amount) {
    return 'الخصم $amount';
  }

  @override
  String get followupResultsSheetError => 'سبب الفشل';

  @override
  String get followupResultsSheetAllMessages => 'اعرض كل الرسايل لنفس العميل';

  @override
  String followupResultsOrdersSummary(String count, String amount) {
    return '$count طلب · $amount';
  }

  @override
  String followupResultsOrderAfterStep(String step) {
    return 'بعد رسالة: $step';
  }
}
