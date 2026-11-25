import 'package:flutter/widgets.dart';

import '../../data/models/studio_enums.dart';

/// Texts of the Library (assets) screens, English and Arabic, in the same
/// pattern as `StudioStrings`. The Arabic gets a language review later;
/// flavor, size, dessert and order stay English inside it.
abstract class AssetStrings {
  const AssetStrings();

  static AssetStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const AssetStringsAr()
      : const AssetStringsEn();

  bool get isArabic;
  String date(String? iso);

  // ---- Library ---------------------------------------------------------
  String get libraryTitle;
  String get libraryHelpTitle;
  List<String> get libraryHelp;
  String get emptyPurpose;
  String get emptyFirstStep;
  String get emptyFilteredPurpose;
  String get emptyFilteredFirstStep;
  String get clearFilters;
  String get addAsset;
  String get search;
  String get filterKind;
  String get filterFlavour;
  String get filterStatus;
  String get filterConsent;
  String get any;
  String get loadMore;

  // ---- Words for enums -------------------------------------------------
  String kind(AssetKind k);
  String category(AssetCategory c);
  String status(AssetStatus s);
  String consentStatus(ConsentStatus s);
  String scope(ConsentScope s);

  // ---- Asset page ------------------------------------------------------
  String get assetTitle;
  String get assetHelpTitle;
  List<String> get assetHelp;
  String get noMedia;
  String get openFullScreen;
  String get fieldFlavour;
  String get fieldCategory;
  String get fieldNote;
  String get fieldTags;
  String uploadedBy(String name);
  String usedTimes(int n);
  String get notUsedYet;
  String get consentTitle;
  String get consentWho;
  String get consentDate;
  String get consentScope;
  String get consentProof;
  String get consentLoggedBy;
  String get paidOk;
  String get paidNotOk;
  String get ratingTitle;
  String get noRatingsYet;
  String ratingSummary(String avg, int n);
  String yourRating(int score);
  String scoreLabel(int score);
  String get commentsTitle;
  String commentsCount(int n);
  String get commentHint;
  String get commentSend;
  String get commentSent;
  String get hiddenNotice;

  // ---- Actions ---------------------------------------------------------
  String get actionConsent;
  String get actionMarkUsed;
  String get actionRate;

  // ---- Add / edit ------------------------------------------------------
  String get addTitle;
  String get editTitle;
  String get pickFromGallery;
  String get pickFiles;
  String get noFilesPicked;
  String get fieldTitle;
  String get fieldKind;
  String get chooseKind;
  String get uploadButton;
  String get saveButton;
  String get cancel;
  String get hideFromLibrary;
  String get openForRating;
  String get saved;
  String get uploadStarted;
  String get removeFile;
  String get addHelpTitle;
  List<String> get addHelp;

  // ---- Consent sheet ---------------------------------------------------
  String get consentSheetTitle;
  String get consentStatusLabel;
  String get consentGivenNeeds;
  String get consentWhoHint;
  String get consentPickDate;
  String get consentAttachProof;
  String get consentProofAttached;
  String get consentProofUploading;
  String get consentProofFailed;
  String get consentSave;

  // ---- Mark used sheet -------------------------------------------------
  String get usedSheetTitle;
  String get usedNoteHint;

  // ---- Errors ----------------------------------------------------------
  String get errShadow;
  String get errStale;
  String get errNotPermitted;
  String get errNetwork;
  String get errGeneric;
  String get errNotFound;
  String get needsConnection;
}

const _monthsEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthsAr = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', //
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

String _d(String? iso, List<String> months) {
  final d = iso == null ? null : DateTime.tryParse(iso);
  if (d == null) return '';
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class AssetStringsEn extends AssetStrings {
  const AssetStringsEn();
  @override
  bool get isArabic => false;
  @override
  String date(String? iso) => _d(iso, _monthsEn);

  @override
  String get libraryTitle => 'Library';
  @override
  String get libraryHelpTitle => 'How the Library works';
  @override
  List<String> get libraryHelp => const [
    'Raw clips, photos, templates and customer content live here.',
    'Filter by kind, flavor, status or consent, or search by words.',
    'Add files from your phone. They go straight up and get tagged.',
    'Customer content needs a consent record before it is used.',
  ];
  @override
  String get emptyPurpose =>
      'The Library holds the raw clips, photos and customer content the team can use.';
  @override
  String get emptyFirstStep => 'Add the first file from your phone.';
  @override
  String get emptyFilteredPurpose => 'Nothing matches these filters.';
  @override
  String get emptyFilteredFirstStep => 'Clear the filters to see everything.';
  @override
  String get clearFilters => 'Clear filters';
  @override
  String get addAsset => 'Add files';
  @override
  String get search => 'Search';
  @override
  String get filterKind => 'Kind';
  @override
  String get filterFlavour => 'Flavor';
  @override
  String get filterStatus => 'Status';
  @override
  String get filterConsent => 'Consent';
  @override
  String get any => 'Any';
  @override
  String get loadMore => 'Show more';

  @override
  String kind(AssetKind k) => switch (k) {
    AssetKind.clip => 'Clip',
    AssetKind.photo => 'Photo',
    AssetKind.template => 'Template',
    AssetKind.storyFrame => 'Story frame',
    AssetKind.storyPhoto => 'Story photo',
    AssetKind.kitchenShot => 'Kitchen shot',
    AssetKind.customerContent => 'Customer content',
    AssetKind.oldCreative => 'Old creative',
    AssetKind.unknown => 'Other',
  };
  @override
  String category(AssetCategory c) => switch (c) {
    AssetCategory.customers => 'Customers',
    AssetCategory.delivery => 'Delivery',
    AssetCategory.jars => 'Jars',
    AssetCategory.kitchen => 'Kitchen',
    AssetCategory.team => 'Team',
    AssetCategory.other => 'Other',
    AssetCategory.unknown => 'Other',
  };
  @override
  String status(AssetStatus s) => switch (s) {
    AssetStatus.newValue => 'New',
    AssetStatus.used => 'Used',
    AssetStatus.skipped => 'Skipped',
    AssetStatus.retired => 'Retired',
    AssetStatus.unknown => 'Other',
  };
  @override
  String consentStatus(ConsentStatus s) => switch (s) {
    ConsentStatus.notNeeded => 'Not needed',
    ConsentStatus.asked => 'Asked, no answer yet',
    ConsentStatus.given => 'Given',
    ConsentStatus.refused => 'Refused',
    ConsentStatus.unknown => 'Other',
  };
  @override
  String scope(ConsentScope s) => switch (s) {
    ConsentScope.organicOnly => 'Organic only',
    ConsentScope.organicAndPaid => 'Organic and paid',
    ConsentScope.unknown => 'Other',
  };

  @override
  String get assetTitle => 'File';
  @override
  String get assetHelpTitle => 'About this file';
  @override
  List<String> get assetHelp => const [
    'Tap the picture to see it full screen.',
    'Customer content shows its consent record. Paid use needs consent for paid.',
    'Rate it to say if it is worth using, and leave a comment for the team.',
  ];
  @override
  String get noMedia => 'No picture yet. It may still be processing.';
  @override
  String get openFullScreen => 'Open full screen';
  @override
  String get fieldFlavour => 'Flavor';
  @override
  String get fieldCategory => 'Category';
  @override
  String get fieldNote => 'Note';
  @override
  String get fieldTags => 'Tags';
  @override
  String uploadedBy(String name) => 'Added by $name';
  @override
  String usedTimes(int n) => n == 1 ? 'Used once' : 'Used $n times';
  @override
  String get notUsedYet => 'Not used yet';
  @override
  String get consentTitle => 'Consent';
  @override
  String get consentWho => 'Who gave it';
  @override
  String get consentDate => 'Date';
  @override
  String get consentScope => 'Covers';
  @override
  String get consentProof => 'Proof';
  @override
  String get consentLoggedBy => 'Logged by';
  @override
  String get paidOk => 'Can be used in paid ads';
  @override
  String get paidNotOk => 'Not for paid ads';
  @override
  String get ratingTitle => 'Rating';
  @override
  String get noRatingsYet => 'No ratings yet.';
  @override
  String ratingSummary(String avg, int n) =>
      n == 1 ? '$avg from 1 person' : '$avg from $n people';
  @override
  String yourRating(int score) => 'Your rating: $score';
  @override
  String scoreLabel(int score) => switch (score) {
    1 => 'Drop it',
    2 => 'Weak',
    3 => 'Okay',
    4 => 'Strong',
    _ => 'Use it',
  };
  @override
  String get commentsTitle => 'Comments';
  @override
  String commentsCount(int n) => n == 0
      ? 'No comments yet.'
      : n == 1
      ? '1 comment'
      : '$n comments';
  @override
  String get commentHint => 'Write a comment';
  @override
  String get commentSend => 'Send';
  @override
  String get commentSent => 'Comment sent';
  @override
  String get hiddenNotice => 'Hidden from the Library.';

  @override
  String get actionConsent => 'Record consent';
  @override
  String get actionMarkUsed => 'Mark as used';
  @override
  String get actionRate => 'Rate';

  @override
  String get addTitle => 'Add files';
  @override
  String get editTitle => 'Edit the file';
  @override
  String get pickFromGallery => 'From the camera roll';
  @override
  String get pickFiles => 'From files';
  @override
  String get noFilesPicked => 'Pick the photos or clips to add.';
  @override
  String get fieldTitle => 'Title';
  @override
  String get fieldKind => 'What it is';
  @override
  String get chooseKind => 'Choose what it is';
  @override
  String get uploadButton => 'Upload';
  @override
  String get saveButton => 'Save';
  @override
  String get cancel => 'Cancel';
  @override
  String get hideFromLibrary => 'Hide from the Library';
  @override
  String get openForRating => 'Open for rating';
  @override
  String get saved => 'Saved';
  @override
  String get uploadStarted => 'Uploading. You can keep working.';
  @override
  String get removeFile => 'Remove';
  @override
  String get addHelpTitle => 'Adding files';
  @override
  List<String> get addHelp => const [
    'Pick the files, say what they are, and tap Upload.',
    'They go straight up from your phone. You can leave this screen.',
    'If the connection drops, the upload waits and carries on.',
  ];

  @override
  String get consentSheetTitle => 'Customer consent';
  @override
  String get consentStatusLabel => 'Where it stands';
  @override
  String get consentGivenNeeds =>
      'Given needs who gave it, the date, what it covers and a screenshot of the message.';
  @override
  String get consentWhoHint => 'Name or handle';
  @override
  String get consentPickDate => 'Pick the date';
  @override
  String get consentAttachProof => 'Attach the screenshot';
  @override
  String get consentProofAttached => 'Screenshot attached';
  @override
  String get consentProofUploading => 'Uploading the screenshot';
  @override
  String get consentProofFailed => 'The screenshot did not upload. Try again.';
  @override
  String get consentSave => 'Save consent';

  @override
  String get usedSheetTitle => 'Mark as';
  @override
  String get usedNoteHint => 'Where it was used, or why not (optional)';

  @override
  String get errShadow =>
      'The Studio is not switched on yet. Nothing was changed.';
  @override
  String get errStale =>
      'This changed meanwhile. The new version is on screen.';
  @override
  String get errNotPermitted => 'You are not allowed to do this.';
  @override
  String get errNetwork => 'No connection. Try again when you are online.';
  @override
  String get errGeneric => 'That did not work. Try again.';
  @override
  String get errNotFound => 'This file is no longer there.';
  @override
  String get needsConnection => 'The Library needs a connection.';
}

class AssetStringsAr extends AssetStrings {
  const AssetStringsAr();
  @override
  bool get isArabic => true;
  @override
  String date(String? iso) => _d(iso, _monthsAr);

  @override
  String get libraryTitle => 'المكتبة';
  @override
  String get libraryHelpTitle => 'المكتبة بتشتغل إزاي';
  @override
  List<String> get libraryHelp => const [
    'هنا الكليبات والصور الخام والتمبلتس ومحتوى العملاء.',
    'فلتر بالنوع أو الـ flavor أو الحالة أو الموافقة، أو دوّر بكلمات.',
    'ضيف ملفات من تليفونك. بتترفع على طول وتتعمل لها تاجز.',
    'محتوى العملاء لازم له سجل موافقة قبل ما يتستخدم.',
  ];
  @override
  String get emptyPurpose =>
      'المكتبة فيها الكليبات والصور الخام ومحتوى العملاء اللي الفريق يقدر يستخدمها.';
  @override
  String get emptyFirstStep => 'ضيف أول ملف من تليفونك.';
  @override
  String get emptyFilteredPurpose => 'مفيش حاجة بتطابق الفلاتر دي.';
  @override
  String get emptyFilteredFirstStep => 'امسح الفلاتر عشان تشوف كل حاجة.';
  @override
  String get clearFilters => 'امسح الفلاتر';
  @override
  String get addAsset => 'ضيف ملفات';
  @override
  String get search => 'بحث';
  @override
  String get filterKind => 'النوع';
  @override
  String get filterFlavour => 'الـ flavor';
  @override
  String get filterStatus => 'الحالة';
  @override
  String get filterConsent => 'الموافقة';
  @override
  String get any => 'أي حاجة';
  @override
  String get loadMore => 'وريني أكتر';

  @override
  String kind(AssetKind k) => switch (k) {
    AssetKind.clip => 'كليب',
    AssetKind.photo => 'صورة',
    AssetKind.template => 'تمبلت',
    AssetKind.storyFrame => 'فريم ستوري',
    AssetKind.storyPhoto => 'صورة ستوري',
    AssetKind.kitchenShot => 'لقطة مطبخ',
    AssetKind.customerContent => 'محتوى عميل',
    AssetKind.oldCreative => 'شغل قديم',
    AssetKind.unknown => 'حاجة تانية',
  };
  @override
  String category(AssetCategory c) => switch (c) {
    AssetCategory.customers => 'العملاء',
    AssetCategory.delivery => 'التوصيل',
    AssetCategory.jars => 'البرطمانات',
    AssetCategory.kitchen => 'المطبخ',
    AssetCategory.team => 'الفريق',
    AssetCategory.other => 'حاجة تانية',
    AssetCategory.unknown => 'حاجة تانية',
  };
  @override
  String status(AssetStatus s) => switch (s) {
    AssetStatus.newValue => 'جديد',
    AssetStatus.used => 'اتستخدم',
    AssetStatus.skipped => 'اتخطّى',
    AssetStatus.retired => 'اتسحب',
    AssetStatus.unknown => 'حاجة تانية',
  };
  @override
  String consentStatus(ConsentStatus s) => switch (s) {
    ConsentStatus.notNeeded => 'مش مطلوبة',
    ConsentStatus.asked => 'اتسأل ولسه مردّش',
    ConsentStatus.given => 'اتوافق',
    ConsentStatus.refused => 'اترفض',
    ConsentStatus.unknown => 'حاجة تانية',
  };
  @override
  String scope(ConsentScope s) => switch (s) {
    ConsentScope.organicOnly => 'أورجانيك بس',
    ConsentScope.organicAndPaid => 'أورجانيك وإعلانات',
    ConsentScope.unknown => 'حاجة تانية',
  };

  @override
  String get assetTitle => 'الملف';
  @override
  String get assetHelpTitle => 'عن الملف ده';
  @override
  List<String> get assetHelp => const [
    'دوس على الصورة تشوفها بالشاشة كلها.',
    'محتوى العميل بيظهر معاه سجل الموافقة. الإعلانات محتاجة موافقة للإعلانات.',
    'قيّمه عشان تقول يستاهل ولا لأ، واكتب تعليق للفريق.',
  ];
  @override
  String get noMedia => 'مفيش صورة لسه. ممكن لسه بتتعالج.';
  @override
  String get openFullScreen => 'افتح بالشاشة كلها';
  @override
  String get fieldFlavour => 'الـ flavor';
  @override
  String get fieldCategory => 'القسم';
  @override
  String get fieldNote => 'ملاحظة';
  @override
  String get fieldTags => 'تاجز';
  @override
  String uploadedBy(String name) => 'ضافه $name';
  @override
  String usedTimes(int n) => n == 1 ? 'اتستخدم مرة' : 'اتستخدم $n مرات';
  @override
  String get notUsedYet => 'لسه ما اتستخدمش';
  @override
  String get consentTitle => 'الموافقة';
  @override
  String get consentWho => 'مين وافق';
  @override
  String get consentDate => 'التاريخ';
  @override
  String get consentScope => 'بتغطي';
  @override
  String get consentProof => 'الإثبات';
  @override
  String get consentLoggedBy => 'سجّلها';
  @override
  String get paidOk => 'ينفع في الإعلانات';
  @override
  String get paidNotOk => 'مش للإعلانات';
  @override
  String get ratingTitle => 'التقييم';
  @override
  String get noRatingsYet => 'مفيش تقييمات لسه.';
  @override
  String ratingSummary(String avg, int n) =>
      n == 1 ? '$avg من واحد' : '$avg من $n';
  @override
  String yourRating(int score) => 'تقييمك: $score';
  @override
  String scoreLabel(int score) => switch (score) {
    1 => 'سيبه',
    2 => 'ضعيف',
    3 => 'كويس',
    4 => 'قوي',
    _ => 'استخدمه',
  };
  @override
  String get commentsTitle => 'التعليقات';
  @override
  String commentsCount(int n) => n == 0
      ? 'مفيش تعليقات لسه.'
      : n == 1
      ? 'تعليق واحد'
      : '$n تعليقات';
  @override
  String get commentHint => 'اكتب تعليق';
  @override
  String get commentSend => 'ابعت';
  @override
  String get commentSent => 'التعليق اتبعت';
  @override
  String get hiddenNotice => 'مخفي من المكتبة.';

  @override
  String get actionConsent => 'سجّل الموافقة';
  @override
  String get actionMarkUsed => 'علّمه اتستخدم';
  @override
  String get actionRate => 'قيّم';

  @override
  String get addTitle => 'ضيف ملفات';
  @override
  String get editTitle => 'عدّل الملف';
  @override
  String get pickFromGallery => 'من الصور على التليفون';
  @override
  String get pickFiles => 'من الملفات';
  @override
  String get noFilesPicked => 'اختار الصور أو الكليبات اللي عايز تضيفها.';
  @override
  String get fieldTitle => 'العنوان';
  @override
  String get fieldKind => 'ده إيه';
  @override
  String get chooseKind => 'اختار ده إيه';
  @override
  String get uploadButton => 'ارفع';
  @override
  String get saveButton => 'احفظ';
  @override
  String get cancel => 'إلغاء';
  @override
  String get hideFromLibrary => 'اخفيه من المكتبة';
  @override
  String get openForRating => 'مفتوح للتقييم';
  @override
  String get saved => 'اتحفظ';
  @override
  String get uploadStarted => 'بيترفع. كمّل شغلك.';
  @override
  String get removeFile => 'شيل';
  @override
  String get addHelpTitle => 'إضافة ملفات';
  @override
  List<String> get addHelp => const [
    'اختار الملفات وقول هي إيه ودوس ارفع.',
    'بتترفع على طول من تليفونك. تقدر تسيب الشاشة دي.',
    'لو النت قطع، الرفع بيستنى ويكمّل.',
  ];

  @override
  String get consentSheetTitle => 'موافقة العميل';
  @override
  String get consentStatusLabel => 'وصلت لفين';
  @override
  String get consentGivenNeeds =>
      'اتوافق محتاجة اسم اللي وافق والتاريخ وبتغطي إيه وسكرين شوت للرسالة.';
  @override
  String get consentWhoHint => 'الاسم أو الهاندل';
  @override
  String get consentPickDate => 'اختار التاريخ';
  @override
  String get consentAttachProof => 'ارفق السكرين شوت';
  @override
  String get consentProofAttached => 'السكرين شوت اتضاف';
  @override
  String get consentProofUploading => 'بيترفع السكرين شوت';
  @override
  String get consentProofFailed => 'السكرين شوت ما اترفعش. جرّب تاني.';
  @override
  String get consentSave => 'احفظ الموافقة';

  @override
  String get usedSheetTitle => 'علّمه كـ';
  @override
  String get usedNoteHint => 'اتستخدم فين، أو ليه لأ (اختياري)';

  @override
  String get errShadow => 'الـ Studio لسه مش شغّال. ماحصلش أي تغيير.';
  @override
  String get errStale => 'ده اتغيّر في الأثناء. النسخة الجديدة قدامك.';
  @override
  String get errNotPermitted => 'مش مسموح لك بالحاجة دي.';
  @override
  String get errNetwork => 'مفيش نت. جرّب تاني لما يرجع.';
  @override
  String get errGeneric => 'ما نفعش. جرّب تاني.';
  @override
  String get errNotFound => 'الملف ده ما بقاش موجود.';
  @override
  String get needsConnection => 'المكتبة محتاجة نت.';
}
