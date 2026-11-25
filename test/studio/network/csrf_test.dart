import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';

/// Answers from a script and records every request.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final ResponseBody Function(RequestOptions o, int n) respond;
  final seen = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options);
    return respond(options, seen.length);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

Map<String, dynamic> _me(String? token) => {
  'message': {
    ...(jsonDecode(studioFixtures['me.founder']!) as Map<String, dynamic>),
    'csrf_token': token,
  },
};

void main() {
  gatewayRetryTests();
  const csrf = 'X-Frappe-CSRF-Token';

  DioStudioApi apiWith(_Adapter a) {
    final dio = Dio()..httpClientAdapter = a;
    return DioStudioApi(dio);
  }

  test('no token: no header on POST', () async {
    final a = _Adapter((o, n) {
      if (o.path.endsWith('session.me')) return _json(_me(null));
      return _json({
        'message': {'seen_help': <String>[]},
      });
    });
    final api = apiWith(a);
    await api.sessionMe();
    await api.sessionHelpSeen(key: 'tour');
    expect(a.seen.last.method, 'POST');
    expect(a.seen.last.headers.containsKey(csrf), isFalse);
  });

  test('token from session.me goes on every POST, never on GET', () async {
    final a = _Adapter((o, n) {
      if (o.path.endsWith('session.me')) return _json(_me('fixture-csrf'));
      return _json({
        'message': {'seen_help': <String>[]},
      });
    });
    final api = apiWith(a);
    await api.sessionMe();
    await api.sessionHelpSeen(key: 'a');
    await api.sessionHelpSeen(key: 'b');
    expect(a.seen[0].headers.containsKey(csrf), isFalse);
    expect(a.seen[1].headers[csrf], 'fixture-csrf');
    expect(a.seen[2].headers[csrf], 'fixture-csrf');
  });

  test('CSRFTokenError: re-fetch session.me once and retry once', () async {
    var token = 'old';
    final a = _Adapter((o, n) {
      if (o.path.endsWith('session.me')) {
        if (n > 1) token = 'new';
        return _json(_me(token));
      }
      if (o.headers[csrf] == 'new') {
        return _json({
          'message': {
            'seen_help': ['x'],
          },
        });
      }
      return _json({'exc_type': 'CSRFTokenError'}, 400);
    });
    final api = apiWith(a);
    await api.sessionMe();
    final r = await api.sessionHelpSeen(key: 'x');
    expect(r.seenHelp, ['x']);
    // me, post(old), me, post(new)
    expect(a.seen.length, 4);
    expect(a.seen[3].headers[csrf], 'new');
  });

  test('a second CSRF failure is not retried again', () async {
    final a = _Adapter((o, n) {
      if (o.path.endsWith('session.me')) return _json(_me('t'));
      return _json({'exc_type': 'CSRFTokenError'}, 400);
    });
    final api = apiWith(a);
    await api.sessionMe();
    await expectLater(
      api.sessionHelpSeen(key: 'x'),
      throwsA(isA<StudioError>()),
    );
    expect(a.seen.length, 4);
  });
}

void gatewayRetryTests() {
  group('read retry on 502/503/504', () {
    DioStudioApi apiWith(_Adapter a) =>
        DioStudioApi(Dio()..httpClientAdapter = a, retryDelay: Duration.zero);

    test('a GET that gets a 502 is retried once and then succeeds', () async {
      final a = _Adapter(
        (o, n) => n == 1 ? _json({'exc_type': 'x'}, 502) : _json(_me(null)),
      );
      final me = await apiWith(a).sessionMe();
      expect(me.user, isNotEmpty);
      expect(a.seen.length, 2);
    });

    test('a second 504 shows the error (one retry only)', () async {
      final a = _Adapter((o, n) => _json({'exc_type': 'x'}, 504));
      await expectLater(
        apiWith(a).sessionMe(),
        throwsA(isA<StudioServerError>()),
      );
      expect(a.seen.length, 2);
    });

    test('a POST is never retried on 502', () async {
      final a = _Adapter((o, n) => _json({'exc_type': 'x'}, 502));
      await expectLater(
        apiWith(a).sessionHelpSeen(key: 'x'),
        throwsA(isA<StudioServerError>()),
      );
      expect(a.seen.length, 1);
    });
  });
}
