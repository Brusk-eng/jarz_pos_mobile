import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/core/network/dio_provider.dart';

import '../../helpers/mock_services.dart';

/// The server's POS release floor answers 426 to any Android build below it.
/// Studio's build number is its own CI run count, far below that floor, so
/// Studio must not send the build headers at all.
void main() {
  test('a Studio interceptor sends no build or platform header', () async {
    final interceptor = SessionInterceptor(
      MockSessionManager(),
      MockOfflineQueue(),
      '',
      isWebOverride: true,
      sendBuildIdentity: false,
    );
    final options = RequestOptions(
      path: '/api/method/jarz_social.api.studio.session.me',
    );
    final seen = Completer<RequestOptions>();
    interceptor.onRequest(options, _Handler(seen));
    final out = await seen.future;

    expect(out.headers.containsKey(kBuildHeader), isFalse);
    expect(out.headers.containsKey(kPlatformHeader), isFalse);
  });
}

class _Handler extends RequestInterceptorHandler {
  _Handler(this._c);
  final Completer<RequestOptions> _c;

  @override
  void next(RequestOptions requestOptions) => _c.complete(requestOptions);
}
