import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/features/replenishment/domain/carton_packing.dart';

PackLine _line(String name, String size, int qty) =>
    PackLine(itemCode: name, name: name, size: size, qty: qty);

void main() {
  group('packCartons', () {
    test('24 medium with no large cartons fills 2 B2B cartons', () {
      final r = packCartons([_line('Lotus', 'medium', 24)]);
      expect(r.cartons.length, 2);
      expect(r.b2bUsed, 2);
      expect(r.largeUsed, 0);
      expect(r.cartons.every((c) => c.type == CartonType.b2b), isTrue);
      expect(r.cartons.first.jars, 12);
      expect(r.cartons.first.fillPercent, 100);
      expect(r.totalJars, 24);
    });

    test('20 medium with 1 large carton in hand is one Large carton', () {
      final r = packCartons([_line('Lotus', 'medium', 20)], largeInHand: 1);
      expect(r.cartons.length, 1);
      expect(r.largeUsed, 1);
      expect(r.b2bUsed, 0);
      expect(r.cartons.single.fillPercent, 100);
    });

    test('4 large + 6 medium share exactly one B2B carton', () {
      final r = packCartons([
        _line('Mango', 'large', 4),
        _line('Lotus', 'medium', 6),
      ]);
      expect(r.cartons.length, 1);
      expect(r.cartons.single.type, CartonType.b2b);
      expect(r.cartons.single.usedUnits, 120);
    });

    test('8 large + 6 medium make 2 B2B cartons, the first is the 8 large', () {
      final r = packCartons([
        _line('Lotus', 'medium', 6),
        _line('Mango', 'large', 8),
      ]);
      expect(r.cartons.length, 2);
      expect(r.b2bUsed, 2);
      expect(r.cartons.first.lines.single.name, 'Mango');
      expect(r.cartons.first.lines.single.qty, 8);
      expect(r.cartons.last.lines.single.name, 'Lotus');
    });

    test('3 medium with 5 large cartons in hand drops to 1 B2B', () {
      final r = packCartons([_line('Lotus', 'medium', 3)], largeInHand: 5);
      expect(r.cartons.length, 1);
      expect(r.cartons.single.type, CartonType.b2b);
      expect(r.largeUsed, 0);
      expect(r.b2bUsed, 1);
    });

    test('unknown size is listed as unpacked, not packed', () {
      final r = packCartons([
        _line('Mystery', '', 5),
        _line('Lotus', 'medium', 2),
      ]);
      expect(r.unpacked.single.name, 'Mystery');
      expect(r.cartons.length, 1);
      expect(r.totalJars, 2);
    });

    test('empty input gives no cartons', () {
      final r = packCartons(const []);
      expect(r.cartons, isEmpty);
      expect(r.unpacked, isEmpty);
      expect(r.totalJars, 0);
      expect(r.isEmpty, isTrue);
    });

    test('zero quantities are ignored', () {
      final r = packCartons([_line('Lotus', 'medium', 0)]);
      expect(r.isEmpty, isTrue);
    });
  });
}
