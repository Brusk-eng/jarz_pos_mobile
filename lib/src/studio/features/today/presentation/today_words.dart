import '../../../core/l10n/plural.dart';

/// Arabic words for the English format names and the waiting time the server
/// can put in a Today line's subtitle. A line the server already wrote in
/// Arabic matches none of these and is returned as it came.
const _formats = {
  'Static': 'ستاتيك',
  'Carousel': 'كاروسيل',
  'Video': 'فيديو',
  'Reel': 'ريل',
  'Feed reel': 'ريل الفيد',
  'Feed carousel': 'كاروسيل الفيد',
  'Feed static': 'ستاتيك الفيد',
  'Story': 'Story',
};

String todayLineArabic(String text) {
  final parts = text.split(' · ');
  return [
    for (final p in parts)
      if (_formats[p] case final f?)
        f
      else if (RegExp(r'^waiting (\d+) days?$').firstMatch(p) case final m?)
        'مستنية بقالها ${arDay.of(int.parse(m.group(1)!))}'
      else
        p,
  ].join(' · ');
}
