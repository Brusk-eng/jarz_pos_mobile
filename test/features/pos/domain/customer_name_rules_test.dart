import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/features/pos/domain/customer_name_rules.dart';

void main() {
  group('customerNameProblem', () {
    test('empty and whitespace are "empty"', () {
      expect(customerNameProblem(null), CustomerNameProblem.empty);
      expect(customerNameProblem(''), CustomerNameProblem.empty);
      expect(customerNameProblem('   '), CustomerNameProblem.empty);
    });

    test('symbols, digits and tatweel only are rejected', () {
      for (final bad in [
        '...',
        '-',
        '123',
        '٣٤٥',
        '+20 100',
        '؟؟',
        'ـــ',
        '.-_/',
      ]) {
        expect(
          customerNameProblem(bad),
          CustomerNameProblem.noLetter,
          reason: bad,
        );
      }
    });

    test('Arabic and Latin names pass, with digits or symbols mixed in', () {
      for (final good in [
        'أحمد علي',
        'محمد',
        'Ahmed',
        'ahmed.ali',
        'Mona 2',
        'José',
        'ب',
        'Cafe 33 - Maadi',
      ]) {
        expect(customerNameProblem(good), isNull, reason: good);
        expect(customerNameHasLetter(good), isTrue, reason: good);
      }
    });
  });
}
