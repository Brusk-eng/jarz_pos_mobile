import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';

import 'generated/fixture_codecs.g.dart';

void main() {
  test('every contract fixture has a codec and every codec a fixture', () {
    expect(fixtureCodecs.keys.toSet(), studioFixtures.keys.toSet());
    expect(studioFixtures.length, greaterThanOrEqualTo(140));
  });

  group('fixture parses into its model and round-trips', () {
    for (final name in studioFixtures.keys) {
      test(name, () {
        final raw = jsonDecode(studioFixtures[name]!);
        final codec = fixtureCodecs[name]!;
        final model = codec.parse(raw);
        final back = jsonDecode(jsonEncode(codec.toJson(model)));
        expect(
          const DeepCollectionEquality().equals(back, raw),
          isTrue,
          reason: 'round trip changed $name',
        );
      });
    }
  });
}
