import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/data/studio_error.dart';

void main() {
  final examples = (jsonDecode(studioFixtures['errors']!) as Map)
      .cast<String, Map<String, dynamic>>();

  StudioError parse(String code) {
    final e = examples[code]!;
    return StudioError.fromResponse(e['http_status'] as int, e['body']);
  }

  test('every error code maps to its own case, code and status', () {
    expect(examples.keys, hasLength(10));
    for (final code in examples.keys) {
      final err = parse(code);
      expect(err.code, code, reason: code);
      expect(err.statusCode, examples[code]!['http_status'], reason: code);
      expect(err.message, isNotEmpty, reason: code);
    }
  });

  test('cases carry their payload', () {
    expect(parse('UNAUTHENTICATED'), isA<StudioUnauthenticated>());
    expect(parse('UNAUTHENTICATED').deadSession, isTrue);
    expect(parse('NOT_PERMITTED'), isA<StudioNotPermitted>());
    expect(parse('NOT_FOUND'), isA<StudioNotFound>());
    final v = parse('VALIDATION') as StudioValidation;
    expect(v.field, 'reason');
    final g = parse('GATE_FAILED') as StudioGateFailed;
    expect(g.problems, isNotEmpty);
    expect(g.problems.first, isA<StudioProblem>());
    expect(g.problems.first.code, 'labels_missing');
    final s = parse('STALE') as StudioStale;
    expect(
      PieceVersion.fromJson(Map<String, dynamic>.from(s.current as Map)).id,
      'PC-00163-v2',
    );
    final a = parse('ALREADY_DONE') as StudioAlreadyDone;
    expect((a.current as Map)['id'], 'PC-00163-v2');
    expect(parse('SHADOW_MODE'), isA<StudioShadowMode>());
    expect(parse('RATE_LIMITED'), isA<StudioRateLimited>());
    expect(parse('SERVER_ERROR'), isA<StudioServerError>());
  });

  test(
    'no answer is a network error; a bare Frappe failure reads by status',
    () {
      expect(StudioError.fromResponse(null, null), isA<StudioNetworkError>());
      expect(StudioError.fromResponse(500, 'boom'), isA<StudioServerError>());
      expect(StudioError.fromResponse(418, null), isA<StudioUnknownError>());
      expect(
        StudioError.fromResponse(403, 'Please login to access this page'),
        isA<StudioUnauthenticated>(),
      );
      expect(
        StudioError.fromResponse(403, {'exc': 'x'}),
        isA<StudioNotPermitted>(),
      );
    },
  );

  test('an unknown code falls back to the HTTP status', () {
    final err = StudioError.fromResponse(409, {
      'error': {'code': 'NEW_THING', 'message': 'hi'},
    });
    expect(err, isA<StudioUnknownError>());
    expect(err.message, 'hi');
    expect(
      StudioError.fromResponse(404, {
        'error': {'code': 'NEW_THING', 'message': 'gone'},
      }),
      isA<StudioNotFound>(),
    );
  });
}
