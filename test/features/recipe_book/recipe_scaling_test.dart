import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/features/recipe_book/data/recipe_book_models.dart';
import 'package:jarz_pos/src/features/recipe_book/domain/recipe_scaling.dart';

import 'recipe_book_fixtures.dart';

RecipeSegment _token(
  String format, {
  double? amount,
  bool scales = true,
  String unit = '',
  String name = '',
}) => RecipeSegment.token(
  format: format,
  amount: amount,
  scales: scales,
  unit: unit,
  name: name,
);

void main() {
  group('number formatting', () {
    test('grams: one decimal max, .0 dropped, thousands separator', () {
      expect(formatGrams(1500), '1,500 g');
      expect(formatGrams(1234.56), '1,234.6 g');
      expect(formatGrams(900.04), '900 g');
      expect(formatGrams(12.5), '12.5 g');
      expect(formatGrams(1234567.89), '1,234,567.9 g');
      expect(formatGrams(0), '0 g');
    });

    test('qty: up to 3 decimals, trailing zeros dropped, no unit', () {
      expect(formatQty(2), '2');
      expect(formatQty(1.25), '1.25');
      expect(formatQty(0.12345), '0.123');
      expect(formatQty(3.1000), '3.1');
    });

    test('count: whole from 10 up, nearest half below', () {
      expect(formatCount(4), '4');
      expect(formatCount(4.04), '4');
      expect(formatCount(4.26), '4.5');
      expect(formatCount(1.5), '1.5');
      expect(formatCount(57.15), '57');
      expect(formatCount(45), '45');
    });

    test('never prints -0', () {
      expect(formatDecimal(-0.0001, maxDecimals: 1), '0');
    });

    test('ingredient amounts: grams rule for g, qty rule otherwise', () {
      expect(formatIngredientAmount(1800, 'g'), '1,800');
      expect(formatIngredientAmount(67.5, 'piece'), '68');
      expect(formatIngredientAmount(57.15, 'piece'), '57');
      expect(formatIngredientAmount(1.27, 'Kg'), '1.27');
      expect(displayUnit('Kg'), 'kg');
      expect(displayUnit('piece'), 'piece');
    });
  });

  group('token rendering', () {
    test('grams scale with the factor', () {
      final t = _token('grams', amount: 900);
      expect(renderSegment(t, 1), '900 g');
      expect(renderSegment(t, 2), '1,800 g');
      expect(renderSegment(t, 1.27), '1,143 g');
      expect(tokenLooksScaled(t, 2), isTrue);
      expect(tokenLooksScaled(t, 1), isFalse);
    });

    test('each tokens (scales: false) never scale', () {
      final t = _token('grams', amount: 120, scales: false);
      expect(renderSegment(t, 3), '120 g');
      expect(tokenLooksScaled(t, 3), isFalse);
    });

    test('count, qty, full, name and uom', () {
      expect(renderSegment(_token('count', amount: 2.5), 3), '7.5');
      expect(renderSegment(_token('qty', amount: 0.125), 3), '0.375');
      expect(
        renderSegment(
          _token('full', amount: 2, unit: 'Kg', name: 'Butter'),
          1.5,
        ),
        '3 Kg Butter',
      );
      final name = _token('name', name: 'Cocoa');
      expect(renderSegment(name, 2), 'Cocoa');
      expect(tokenLooksScaled(name, 2), isFalse);
      expect(renderSegment(_token('uom', unit: 'Kg'), 2), 'Kg');
    });

    test('plain text is returned as is, spaces kept', () {
      expect(renderSegment(const RecipeSegment.text('Sift '), 2), 'Sift ');
    });
  });

  group('lines and direction', () {
    test('splits at newlines inside text segments and detects RTL', () {
      final detail = RecipeDetail.fromJson(kFudgeCakeJson);
      final lines = splitSegmentsIntoLines(detail.steps.first.segments);
      expect(lines, hasLength(2));
      expect(
        lines[0].map((s) => renderSegment(s, 1)).join(),
        'Sift 900 g cocoa.',
      );
      expect(lineIsRtl(lines[0]), isFalse);
      expect(
        lines[1].map((s) => renderSegment(s, 2)).join(),
        'انخل 1,800 g كاكاو.',
      );
      expect(lineIsRtl(lines[1]), isTrue);
    });

    test('drops blank lines', () {
      final lines = splitSegmentsIntoLines(const [
        RecipeSegment.text('One\n\n'),
        RecipeSegment.text('Two'),
      ]);
      expect(lines, hasLength(2));
    });
  });

  group('durations and targets', () {
    test('Fixed is unchanged; Per Batch and Per Unit scale, rounded', () {
      expect(scaleDuration(20, 'Fixed', 3), 20);
      expect(scaleDuration(40, 'Per Batch', 1.27), 51);
      expect(scaleDuration(5, 'Per Unit', 2.5), 13);
      expect(scaleDuration(null, 'Per Batch', 2), isNull);
      expect(durationScales('Fixed'), isFalse);
      expect(durationScales('Per Batch'), isTrue);
    });

    test('minutes read as hours past an hour', () {
      expect(formatMinutes(45), '45 min');
      expect(formatMinutes(60), '1 h');
      expect(formatMinutes(85), '1 h 25 min');
    });

    test('target range appends °C only when the label mentions it', () {
      expect(formatTargetRange(92, 98, 'Core temperature °C'), '92–98 °C');
      expect(formatTargetRange(40, 55, 'Brix'), '40–55');
      expect(formatTargetRange(40, null, null), '≥ 40');
      expect(formatTargetRange(null, 55, '°C'), '≤ 55 °C');
      expect(formatTargetRange(null, null, '°C'), isNull);
    });
  });

  group('factors', () {
    test('from an ingredient: entered ÷ ingredient amount', () {
      expect(factorFromIngredient(1800, 1500), closeTo(1.2, 1e-9));
      expect(factorFromIngredient(3000, 1500), 2);
      expect(factorFromIngredient(0, 1500), isNull);
      expect(factorFromIngredient(100, 0), isNull);
      expect(factorFromIngredient(null, 1500), isNull);
    });

    test('from a target yield: target ÷ yield amount', () {
      expect(factorFromTargetYield(18.1, 14.29), closeTo(1.2666, 1e-3));
      expect(factorFromTargetYield(10, null), isNull);
      expect(factorFromTargetYield(-1, 14.29), isNull);
    });

    test('factor and batch labels', () {
      expect(formatFactor(1), '×1');
      expect(formatFactor(0.5), '×½');
      expect(formatFactor(1.2666), '×1.27');
      const y = RecipeYield(label: 'One batch', amount: 14.29, unit: 'Kg');
      expect(formatYieldAt(y, 1), '14.29 kg');
      expect(formatYieldAt(y, 18.1 / 14.29), '18.1 kg');
      expect(formatYieldAt(const RecipeYield(), 2), isNull);
      expect(
        formatYieldAt(const RecipeYield(amount: 1500, unit: 'g'), 2),
        '3,000 g',
      );
    });

    test('typed amounts accept separators and Arabic digits', () {
      expect(parseAmount('1,800'), 1800);
      expect(parseAmount('1.5'), 1.5);
      expect(parseAmount('١٨٠٠'), 1800);
      expect(parseAmount('١٫٥'), 1.5);
      expect(parseAmount(''), isNull);
      expect(parseAmount('abc'), isNull);
    });
  });

  group('ingredient grouping', () {
    test('ingredients group by section, unsectioned first', () {
      const items = [
        RecipeIngredient(key: 'a', name: 'A', section: 'Dough'),
        RecipeIngredient(key: 'b', name: 'B'),
        RecipeIngredient(key: 'c', name: 'C', section: 'Core'),
        RecipeIngredient(key: 'd', name: 'D', section: 'Dough'),
      ];
      final sections = groupIngredientsBySection(items);
      expect(sections.map((s) => s.section), [null, 'Dough', 'Core']);
      expect(sections[1].items.map((i) => i.key), ['a', 'd']);
    });
  });

  group('parsing', () {
    test('index and detail parse the contract shapes', () {
      final index = RecipeBookIndex.fromJson(kRecipeIndexJson);
      final fudge = index.recipes.first;
      expect(fudge.hasTrial, isTrue);
      expect(fudge.headlineVersion?.version, 4);
      expect(fudge.openSop, 'SOP-0042');

      final detail = RecipeDetail.fromJson(kFudgeCakeJson);
      expect(detail.batchYield.amount, 14.29);
      expect(detail.ingredients, hasLength(3));
      expect(detail.steps[1].scalingMode, 'Per Batch');
      expect(detail.steps[1].segments[1].scales, isFalse);
      expect(detail.hasNotes, isTrue);
    });

    test('a missing yield amount is unknown, not zero', () {
      final detail = RecipeDetail.fromJson({
        'name': 'SOP-1',
        'title': 'X',
        'yield': {'label': 'One batch', 'amount': null, 'unit': ''},
      });
      expect(detail.batchYield.isKnown, isFalse);
      expect(detail.key, 'X');
    });
  });
}
