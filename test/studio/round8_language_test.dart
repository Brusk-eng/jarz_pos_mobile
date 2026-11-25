import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/features/today/presentation/today_words.dart';

void main() {
  test('Today subtitle: format and waiting time in Arabic', () {
    expect(
      todayLineArabic('Static · Red Velvet Cheesecake · waiting 2 days'),
      'ستاتيك · Red Velvet Cheesecake · مستنية بقالها يومين',
    );
    expect(todayLineArabic('Reel · Mango · waiting 1 day'), contains('يوم'));
  });

  test('a line already in Arabic is unchanged', () {
    expect(
      todayLineArabic('ستاتيك · مستنية بقالها 3 أيام'),
      'ستاتيك · مستنية بقالها 3 أيام',
    );
  });
}
