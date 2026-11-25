import 'package:flutter/widgets.dart';

import '../../core/l10n/plural.dart';
import '../../data/models/studio_enums.dart';

/// Texts of the References screens, English and Arabic, same pattern as
/// `StudioStrings`. Brand and product words people say in English (flavor,
/// size, dessert, order) stay in English inside Arabic.
abstract class ReferencesStrings {
  const ReferencesStrings();

  static ReferencesStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const ReferencesStringsAr()
      : const ReferencesStringsEn();

  // ---- The grid ----------------------------------------------------------
  String get title;
  String get helpTitle;
  List<String> get help;
  String get emptyPurpose;
  String get emptyFirstStep;
  String get emptyFiltered;
  String get searchHint;
  String get filters;
  String get filtersTitle;
  String get format;
  String get source;
  String get remakeFit;
  String get competitor;
  String get sortBy;
  String get apply;
  String get reset;
  String get competitorsButton;
  String get noPicture;

  String statusLabel(RefStatus s);
  String formatLabel(RefMedia m);
  String sourceLabel(RefSrcType s);
  String remakeLabel(String wire);
  String sortLabel(String wire);

  // ---- One reference -----------------------------------------------------
  String get pageTitle;
  String get openSource;
  String get numbers;
  String get noNumbers;
  String get ourTake;
  String get whyItWorks;
  String get textOnIt;
  String get notes;
  String get noNotes;
  String get usedFor;
  String get nothingLinked;
  String get madeFromIt;
  String get details;
  String get addedBy;
  String get lockedNote;
  String get canWeMakeIt;
  String get whatToMake;
  String get whatBlocks;
  String get linkedShot;
  String get linkedPiece;
  String get strongRef;
  String get weakRef;
  String get realRef;
  String metricLabel(String key);
  String plainWord(String wire);
  String feasibilityLabel(Feasibility f);

  // ---- Actions -----------------------------------------------------------
  String get shortlist;
  String get sendToShoot;
  String get markUsed;
  String get drop;
  String get addNote;
  String get linkToPiece;
  String get unlink;
  String get dropTitle;
  String get dropHint;
  String get dropConfirm;
  String get noteTitle;
  String get noteHint;
  String get noteConfirm;
  String get pickShootTitle;
  String get pickShotTitle;
  String get noShoots;
  String get noShots;
  String get pickPieceTitle;
  String get searchPieces;
  String get noPieces;
  String get backToShoots;
  String movedTo(String status);
  String get noteAdded;
  String get linked;
  String get unlinked;
  String shotsInShoot(int n);

  // ---- Competitors -------------------------------------------------------
  String get competitorsTitle;
  String get competitorsHelpTitle;
  List<String> get competitorsHelp;
  String get competitorsEmptyPurpose;
  String get competitorsEmptyFirstStep;
  String get competitorsSearchHint;
  String get competitorTitle;
  String get followers;
  String get liveAds;
  String get outliers;
  String get survivors;
  String get referencesCount;
  String get seeTheirReferences;
  String get instagram;
  String get tiktok;
  String get website;
  String get adLibrary;
  String get removedBecause;
  String get removedBadge;
  String groupLabel(CompGroup g);
  String get market;
}

Map<String, String> _plainAr = const {
  'household': 'البيت',
  'self_treater': 'لنفسها',
  'self-treater': 'لنفسها',
  'house': 'جارز للبيت',
  'hub': 'Hub',
  'hero': 'Hero',
  'hygiene': 'Hygiene',
  'product': 'المنتج',
};

String _humanize(String wire) {
  final s = wire.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class ReferencesStringsEn extends ReferencesStrings {
  const ReferencesStringsEn();

  @override
  String get title => 'References';
  @override
  String get helpTitle => 'References';
  @override
  List<String> get help => const [
    'Ads and posts worth learning from, one card each.',
    'Open one to read why it works and what we would make from it.',
    'Shortlist the good ones, send one to a shoot, or drop it with a reason.',
    'Competitors sit one tap away, with their own page.',
  ];
  @override
  String get emptyPurpose => 'Ads and posts to learn from, and competitors.';
  @override
  String get emptyFirstStep =>
      'No references yet. Claude adds new ones every day; check back soon.';
  @override
  String get emptyFiltered =>
      'Nothing matches these filters. Clear a filter to see more.';
  @override
  String get searchHint => 'Search references';
  @override
  String get filters => 'Filters';
  @override
  String get filtersTitle => 'Filter the references';
  @override
  String get format => 'Format';
  @override
  String get source => 'Where it ran';
  @override
  String get remakeFit => 'Can we remake it';
  @override
  String get competitor => 'Competitor';
  @override
  String get sortBy => 'Sort by';
  @override
  String get apply => 'Show results';
  @override
  String get reset => 'Clear filters';
  @override
  String get competitorsButton => 'Competitors';
  @override
  String get noPicture => 'No picture';

  @override
  String statusLabel(RefStatus s) => switch (s) {
    RefStatus.newValue => 'New',
    RefStatus.shortlisted => 'Shortlisted',
    RefStatus.forAShoot => 'For a shoot',
    RefStatus.remade => 'Used',
    RefStatus.dropped => 'Dropped',
    RefStatus.unknown => 'Other',
  };
  @override
  String formatLabel(RefMedia m) => switch (m) {
    RefMedia.staticValue => 'Static',
    RefMedia.reel => 'Reel',
    RefMedia.carousel => 'Carousel',
    RefMedia.unknown => 'Other',
  };
  @override
  String sourceLabel(RefSrcType s) => switch (s) {
    RefSrcType.metaAd => 'Meta ad',
    RefSrcType.tiktokAd => 'TikTok ad',
    RefSrcType.igPost => 'Instagram post',
    RefSrcType.igReel => 'Instagram reel',
    RefSrcType.other => 'Other',
    RefSrcType.unknown => 'Other',
  };
  @override
  String remakeLabel(String wire) => switch (wire) {
    'ok' => 'Yes, we can remake it',
    'learn' => 'Only to learn from',
    _ => _humanize(wire),
  };
  @override
  String sortLabel(String wire) => switch (wire) {
    'reach' => 'Reach',
    'rank' => 'Rank',
    _ => 'Newest',
  };

  @override
  String get pageTitle => 'Reference';
  @override
  String get openSource => 'Open the original';
  @override
  String get numbers => 'Numbers';
  @override
  String get noNumbers => 'No numbers for this one.';
  @override
  String get ourTake => 'Our take';
  @override
  String get whyItWorks => 'Why it works';
  @override
  String get textOnIt => 'Words on it';
  @override
  String get notes => 'Notes';
  @override
  String get noNotes => 'No notes yet.';
  @override
  String get usedFor => 'Linked to';
  @override
  String get nothingLinked => 'Not linked to a shot or a piece yet.';
  @override
  String get madeFromIt => 'What we made from it';
  @override
  String get details => 'Details';
  @override
  String get addedBy => 'Added by';
  @override
  String get lockedNote => 'Locked, because it is part of a finished piece.';
  @override
  String get canWeMakeIt => 'Can we make it';
  @override
  String get whatToMake => 'What we would make';
  @override
  String get whatBlocks => 'What stops us';
  @override
  String get linkedShot => 'Shot';
  @override
  String get linkedPiece => 'Piece';
  @override
  String get strongRef => 'Strong match';
  @override
  String get weakRef => 'Weak match';
  @override
  String get realRef => 'Real reference';
  @override
  String metricLabel(String key) => switch (key) {
    'copies' => 'Copies of the ad',
    'days' => 'Days running',
    'rank' => 'Rank',
    'survivor' => 'Survived rounds',
    'reach' => 'Reach',
    'views' => 'Views',
    'likes' => 'Likes',
    _ => _humanize(key),
  };
  @override
  String plainWord(String wire) => _humanize(wire);
  @override
  String feasibilityLabel(Feasibility f) => switch (f) {
    Feasibility.inbox => 'Not looked at yet',
    Feasibility.can => 'We can make it',
    Feasibility.needs => 'Needs something first',
    Feasibility.cant => 'We cannot make it',
    Feasibility.used => 'Already used',
    Feasibility.unknown => 'Unknown',
  };

  @override
  String get shortlist => 'Add to shortlist';
  @override
  String get sendToShoot => 'Send to a shoot';
  @override
  String get markUsed => 'Mark as used';
  @override
  String get drop => 'Drop';
  @override
  String get addNote => 'Add a note';
  @override
  String get linkToPiece => 'Link to a piece';
  @override
  String get unlink => 'Unlink';
  @override
  String get dropTitle => 'Why drop this one?';
  @override
  String get dropHint => 'A line so the team knows';
  @override
  String get dropConfirm => 'Drop it';
  @override
  String get noteTitle => 'Add a note';
  @override
  String get noteHint => 'What should the team know?';
  @override
  String get noteConfirm => 'Add note';
  @override
  String get pickShootTitle => 'Pick a shoot';
  @override
  String get pickShotTitle => 'Pick the shot';
  @override
  String get noShoots => 'No shoots are planned yet. Plan a shoot first.';
  @override
  String get noShots => 'This shoot has no shots yet.';
  @override
  String get pickPieceTitle => 'Pick a piece';
  @override
  String get searchPieces => 'Search pieces';
  @override
  String get noPieces => 'No pieces match your search.';
  @override
  String get backToShoots => 'Back to shoots';
  @override
  String movedTo(String status) => 'Now: $status';
  @override
  String get noteAdded => 'Note added';
  @override
  String get linked => 'Linked';
  @override
  String get unlinked => 'Unlinked';
  @override
  String shotsInShoot(int n) => n == 1 ? '1 shot' : '$n shots';

  @override
  String get competitorsTitle => 'Competitors';
  @override
  String get competitorsHelpTitle => 'Competitors';
  @override
  List<String> get competitorsHelp => const [
    'The brands we watch, with what they run now.',
    'Open one for its numbers and notes.',
    'From its page, see every reference we took from it.',
  ];
  @override
  String get competitorsEmptyPurpose => 'The brands we watch and learn from.';
  @override
  String get competitorsEmptyFirstStep =>
      'No competitors yet. Claude adds them from the daily competitor read.';
  @override
  String get competitorsSearchHint => 'Search competitors';
  @override
  String get competitorTitle => 'Competitor';
  @override
  String get followers => 'Followers';
  @override
  String get liveAds => 'Ads running now';
  @override
  String get outliers => 'Outlier posts';
  @override
  String get survivors => 'Long-running ads';
  @override
  String get referencesCount => 'References from them';
  @override
  String get seeTheirReferences => 'See their references';
  @override
  String get instagram => 'Instagram';
  @override
  String get tiktok => 'TikTok';
  @override
  String get website => 'Website';
  @override
  String get adLibrary => 'Ads Library';
  @override
  String get removedBecause => 'Removed because';
  @override
  String get removedBadge => 'Removed';
  @override
  String groupLabel(CompGroup g) => switch (g) {
    CompGroup.egDessert => 'Egypt, desserts',
    CompGroup.egCafe => 'Egypt, cafes',
    CompGroup.oom => 'Outside the market',
    CompGroup.unknown => 'Other',
  };
  @override
  String get market => 'Market';
}

class ReferencesStringsAr extends ReferencesStrings {
  const ReferencesStringsAr();

  @override
  String get title => 'المراجع';
  @override
  String get helpTitle => 'المراجع';
  @override
  List<String> get help => const [
    'إعلانات وبوستات تستاهل نتعلم منها، كارت لكل واحد.',
    'افتح أي مرجع تشوف ليه شغّال وإيه اللي ممكن نعمله منه.',
    'ضيف المفيد للقائمة القصيرة، ابعته لتصوير، أو سيبه مع السبب.',
    'المنافسين على بعد ضغطة، ولكل منافس صفحته.',
  ];
  @override
  String get emptyPurpose => 'إعلانات وبوستات نتعلم منها، والمنافسين.';
  @override
  String get emptyFirstStep =>
      'مفيش مراجع لسه. Claude بيضيف مراجع جديدة كل يوم، جرّب بعد شوية.';
  @override
  String get emptyFiltered =>
      'مفيش مرجع بيطابق الفلاتر دي. امسح فلتر يظهر أكتر.';
  @override
  String get searchHint => 'دوّر في المراجع';
  @override
  String get filters => 'فلاتر';
  @override
  String get filtersTitle => 'فلتر المراجع';
  @override
  String get format => 'النوع';
  @override
  String get source => 'اتنشر فين';
  @override
  String get remakeFit => 'نقدر نعيده؟';
  @override
  String get competitor => 'المنافس';
  @override
  String get sortBy => 'رتّب حسب';
  @override
  String get apply => 'اعرض النتائج';
  @override
  String get reset => 'امسح الفلاتر';
  @override
  String get competitorsButton => 'المنافسين';
  @override
  String get noPicture => 'مفيش صورة';

  @override
  String statusLabel(RefStatus s) => switch (s) {
    RefStatus.newValue => 'جديد',
    RefStatus.shortlisted => 'في القائمة القصيرة',
    RefStatus.forAShoot => 'للتصوير',
    RefStatus.remade => 'اتستخدم',
    RefStatus.dropped => 'اتسيب',
    RefStatus.unknown => 'غير ذلك',
  };
  @override
  String formatLabel(RefMedia m) => switch (m) {
    RefMedia.staticValue => 'صورة ثابتة',
    RefMedia.reel => 'Reel',
    RefMedia.carousel => 'Carousel',
    RefMedia.unknown => 'غير ذلك',
  };
  @override
  String sourceLabel(RefSrcType s) => switch (s) {
    RefSrcType.metaAd => 'إعلان Meta',
    RefSrcType.tiktokAd => 'إعلان TikTok',
    RefSrcType.igPost => 'بوست Instagram',
    RefSrcType.igReel => 'Reel على Instagram',
    RefSrcType.other => 'غير ذلك',
    RefSrcType.unknown => 'غير ذلك',
  };
  @override
  String remakeLabel(String wire) => switch (wire) {
    'ok' => 'أيوه، نقدر نعيده',
    'learn' => 'نتعلم منه بس',
    _ => _humanize(wire),
  };
  @override
  String sortLabel(String wire) => switch (wire) {
    'reach' => 'الوصول',
    'rank' => 'الترتيب',
    _ => 'الأحدث',
  };

  @override
  String get pageTitle => 'مرجع';
  @override
  String get openSource => 'افتح الأصل';
  @override
  String get numbers => 'الأرقام';
  @override
  String get noNumbers => 'مفيش أرقام للمرجع ده.';
  @override
  String get ourTake => 'رأينا';
  @override
  String get whyItWorks => 'ليه شغّال';
  @override
  String get textOnIt => 'الكلام اللي عليه';
  @override
  String get notes => 'الملاحظات';
  @override
  String get noNotes => 'مفيش ملاحظات لسه.';
  @override
  String get usedFor => 'مربوط بـ';
  @override
  String get nothingLinked => 'مش مربوط بشوت أو قطعة لسه.';
  @override
  String get madeFromIt => 'اللي عملناه منه';
  @override
  String get details => 'تفاصيل';
  @override
  String get addedBy => 'اتضاف من';
  @override
  String get lockedNote => 'مقفول لأنه جزء من قطعة خلصت.';
  @override
  String get canWeMakeIt => 'نقدر نعمله؟';
  @override
  String get whatToMake => 'اللي هنعمله';
  @override
  String get whatBlocks => 'اللي بيمنعنا';
  @override
  String get linkedShot => 'شوت';
  @override
  String get linkedPiece => 'قطعة';
  @override
  String get strongRef => 'تشابه قوي';
  @override
  String get weakRef => 'تشابه ضعيف';
  @override
  String get realRef => 'مرجع حقيقي';
  @override
  String metricLabel(String key) => switch (key) {
    'copies' => 'نسخ الإعلان',
    'days' => 'أيام شغّال',
    'rank' => 'الترتيب',
    'survivor' => 'جولات صمد فيها',
    'reach' => 'الوصول',
    'views' => 'المشاهدات',
    'likes' => 'الإعجابات',
    _ => _humanize(key),
  };
  @override
  String plainWord(String wire) =>
      _plainAr[wire.toLowerCase()] ?? _humanize(wire);
  @override
  String feasibilityLabel(Feasibility f) => switch (f) {
    Feasibility.inbox => 'لسه محدش بصّ عليه',
    Feasibility.can => 'نقدر نعمله',
    Feasibility.needs => 'محتاج حاجة الأول',
    Feasibility.cant => 'مش هنقدر نعمله',
    Feasibility.used => 'اتستخدم قبل كده',
    Feasibility.unknown => 'غير معروف',
  };

  @override
  String get shortlist => 'ضيفه للقائمة';
  @override
  String get sendToShoot => 'ابعته لتصوير';
  @override
  String get markUsed => 'علّمه إنه اتستخدم';
  @override
  String get drop => 'سيبه';
  @override
  String get addNote => 'ضيف ملاحظة';
  @override
  String get linkToPiece => 'اربطه بقطعة';
  @override
  String get unlink => 'فك الربط';
  @override
  String get dropTitle => 'ليه هتسيب المرجع ده؟';
  @override
  String get dropHint => 'اكتب سطر يفهّم الفريق';
  @override
  String get dropConfirm => 'سيبه';
  @override
  String get noteTitle => 'ضيف ملاحظة';
  @override
  String get noteHint => 'إيه اللي الفريق لازم يعرفه؟';
  @override
  String get noteConfirm => 'ضيف الملاحظة';
  @override
  String get pickShootTitle => 'اختار التصوير';
  @override
  String get pickShotTitle => 'اختار الشوت';
  @override
  String get noShoots => 'مفيش تصوير متخطط لسه. اعمل خطة تصوير الأول.';
  @override
  String get noShots => 'التصوير ده مفيهوش شوتس لسه.';
  @override
  String get pickPieceTitle => 'اختار قطعة';
  @override
  String get searchPieces => 'دوّر في القطع';
  @override
  String get noPieces => 'مفيش قطع بتطابق البحث.';
  @override
  String get backToShoots => 'رجوع للتصوير';
  @override
  String movedTo(String status) => 'دلوقتي: $status';
  @override
  String get noteAdded => 'الملاحظة اتضافت';
  @override
  String get linked => 'اتربط';
  @override
  String get unlinked => 'اتفك الربط';
  @override
  String shotsInShoot(int n) =>
      arCount(n, one: 'شوت واحد', two: 'شوتين', few: 'شوتس', many: 'شوت');

  @override
  String get competitorsTitle => 'المنافسين';
  @override
  String get competitorsHelpTitle => 'المنافسين';
  @override
  List<String> get competitorsHelp => const [
    'البراندات اللي بنراقبها، وإيه اللي شغّالينه دلوقتي.',
    'افتح أي واحد تشوف أرقامه وملاحظاته.',
    'من صفحته، شوف كل المراجع اللي خدناها منه.',
  ];
  @override
  String get competitorsEmptyPurpose => 'البراندات اللي بنراقبها ونتعلم منها.';
  @override
  String get competitorsEmptyFirstStep =>
      'مفيش منافسين لسه. Claude بيضيفهم من القراءة اليومية للمنافسين.';
  @override
  String get competitorsSearchHint => 'دوّر في المنافسين';
  @override
  String get competitorTitle => 'منافس';
  @override
  String get followers => 'المتابعين';
  @override
  String get liveAds => 'إعلانات شغّالة دلوقتي';
  @override
  String get outliers => 'بوستات فوق المعتاد';
  @override
  String get survivors => 'إعلانات صمدت';
  @override
  String get referencesCount => 'مراجع منهم';
  @override
  String get seeTheirReferences => 'شوف مراجعهم';
  @override
  String get instagram => 'Instagram';
  @override
  String get tiktok => 'TikTok';
  @override
  String get website => 'الموقع';
  @override
  String get adLibrary => 'Ads Library';
  @override
  String get removedBecause => 'اتشال بسبب';
  @override
  String get removedBadge => 'اتشال';
  @override
  String groupLabel(CompGroup g) => switch (g) {
    CompGroup.egDessert => 'مصر، desserts',
    CompGroup.egCafe => 'مصر، كافيهات',
    CompGroup.oom => 'برّه السوق',
    CompGroup.unknown => 'غير ذلك',
  };
  @override
  String get market => 'السوق';
}
