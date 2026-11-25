import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/offline/kv_store.dart';
import 'package:jarz_pos/src/studio/data/studio_error.dart';

import 'helpers.dart';
import 'inbox/ui_test_helpers.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';

void main() {
  testWidgets('Skip is remembered on the device even when the save fails', (
    tester,
  ) async {
    usePhone(tester, height: 1800);
    final api = _FailingSave();
    final c = await pumpStudioWith(tester, api);
    expect(find.byKey(const ValueKey('walkthrough')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('walkthrough-skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('walkthrough')), findsNothing);
    final keys = await c.read(studioKvStoreProvider).keys('walkthrough_seen:');
    expect(keys, hasLength(1));
    expect(api.saves, 1);
  });
}

class _FailingSave extends FakeStudioApi {
  _FailingSave()
    : super(role: 'creator', delay: Duration.zero, firstLogin: true);
  int saves = 0;

  @override
  Future<dynamic> call(
    String method, {
    Map<String, dynamic>? params,
    bool get = false,
  }) {
    if (method.endsWith('session.help_seen')) {
      saves++;
      return Future.error(const StudioServerError('down', statusCode: 500));
    }
    return super.call(method, params: params, get: get);
  }
}
