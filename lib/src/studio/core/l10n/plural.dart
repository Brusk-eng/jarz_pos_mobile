/// Arabic count phrases for 1, 2, 3 to 10 and 11 and over.
///
/// `one` and `two` are the whole phrase ("بوست", "بوستين"); `few` and `many`
/// get the number in front ("3 بوستات", "12 بوست"). Zero uses `many`'s noun
/// unless the caller handles it first.
/// A counted noun with its four Arabic forms. [of] gives the whole phrase for a
/// count by the Arabic number rules (1: singular, 2: dual, 3 to 10: plural,
/// 11 and over: singular), so no screen writes "9 قطعة" or "3 تقييم" by hand.
class ArNoun {
  const ArNoun({
    required this.one,
    required this.two,
    required this.few,
    required this.many,
  });

  final String one;
  final String two;
  final String few;
  final String many;

  String of(int n) => arCount(n, one: one, two: two, few: few, many: many);
}

/// The nouns the app counts, one place each.
const arPiece = ArNoun(one: 'قطعة', two: 'قطعتين', few: 'قطع', many: 'قطعة');
const arOpenPiece = ArNoun(
  one: 'قطعة مفتوحة',
  two: 'قطعتين مفتوحتين',
  few: 'قطع مفتوحة',
  many: 'قطعة مفتوحة',
);
const arRating = ArNoun(
  one: 'تقييم واحد',
  two: 'تقييمين',
  few: 'تقييمات',
  many: 'تقييم',
);
const arComment = ArNoun(
  one: 'تعليق واحد',
  two: 'تعليقين',
  few: 'تعليقات',
  many: 'تعليق',
);
const arMoment = ArNoun(
  one: 'موعد',
  two: 'موعدين',
  few: 'مواعيد',
  many: 'موعد',
);
const arDay = ArNoun(one: 'يوم', two: 'يومين', few: 'أيام', many: 'يوم');
const arFrame = ArNoun(
  one: 'فريم واحد',
  two: 'فريمين',
  few: 'فريمات',
  many: 'فريم',
);
const arShot = ArNoun(
  one: 'شوت واحد',
  two: 'شوتين',
  few: 'شوتس',
  many: 'شوت',
);
const arFile = ArNoun(one: 'ملف', two: 'ملفين', few: 'ملفات', many: 'ملف');

String arCount(
  int n, {
  required String one,
  required String two,
  required String few,
  required String many,
}) {
  if (n == 1) return one;
  if (n == 2) return two;
  if (n >= 3 && n <= 10) return '$n $few';
  return '$n $many';
}
