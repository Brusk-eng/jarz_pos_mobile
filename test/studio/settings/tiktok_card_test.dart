import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/features/settings/presentation/settings_hub_screen.dart';

import '../more/more_test_utils.dart';

const _tall = Size(360, 1800);

Finder _key(String k) => find.byKey(ValueKey(k));

RecordingApi _api({String role = 'founder', bool connected = false}) {
  final api = RecordingApi(role: role);
  var isConnected = connected;
  Map<String, dynamic> status() => {
    'configured': true,
    'connected': isConnected,
    'account_name': isConnected ? 'jarzegypt' : null,
    'expires_at': isConnected ? '2026-11-27T12:00:00' : null,
    'refresh_expires_at': isConnected ? '2027-11-26T12:00:00' : null,
    'scopes': isConnected ? ['accounts'] : <String>[],
    'error': null,
  };
  api.respond['jarz_social.api.tiktok.status'] = (_) => status();
  api.respond['jarz_social.api.tiktok.connect_url'] = (_) {
    isConnected = true; // the browser round trip, as far as the card can tell
    return {'url': 'https://business-api.tiktok.example/authorize?state=s'};
  };
  api.respond['jarz_social.api.tiktok.disconnect'] = (_) {
    isConnected = false;
    return status();
  };
  return api;
}

void main() {
  testWidgets('founder sees the card, not connected, with Connect', (
    tester,
  ) async {
    final api = _api();
    await pumpMore(tester, const SettingsHubScreen(), size: _tall, api: api);
    expect(_key('tiktok-card'), findsOneWidget);
    expect(find.text('Not connected'), findsOneWidget);
    expect(_key('tiktok-connect'), findsOneWidget);
    expect(_key('tiktok-disconnect'), findsNothing);
    expect(api.count('jarz_social.api.tiktok.status'), 1);
  });

  testWidgets('a lead does not see the card and never asks for it', (
    tester,
  ) async {
    final api = _api(role: 'lead');
    await pumpMore(tester, const SettingsHubScreen(), size: _tall, api: api);
    expect(_key('tiktok-card'), findsNothing);
    expect(api.count('jarz_social.api.tiktok.status'), 0);
  });

  testWidgets('Connect opens the address the server built', (tester) async {
    final api = _api();
    final opened = <Uri>[];
    await pumpMore(
      tester,
      const SettingsHubScreen(),
      size: _tall,
      api: api,
      opened: opened,
    );
    await tester.tap(_key('tiktok-connect'));
    await tester.pumpAndSettle();
    expect(opened, hasLength(1));
    expect(opened.single.host, 'business-api.tiktok.example');
    expect(api.count('jarz_social.api.tiktok.connect_url'), 1);
  });

  testWidgets('a failed launch tells the founder, no crash', (tester) async {
    final api = _api();
    await pumpMore(
      tester,
      const SettingsHubScreen(),
      size: _tall,
      api: api,
      openResult: false,
    );
    await tester.tap(_key('tiktok-connect'));
    await tester.pumpAndSettle();
    expect(find.text('Could not open TikTok. Try again.'), findsOneWidget);
  });

  testWidgets('connected shows the account name, Disconnect asks first', (
    tester,
  ) async {
    final api = _api(connected: true);
    await pumpMore(tester, const SettingsHubScreen(), size: _tall, api: api);
    expect(find.text('Connected as jarzegypt'), findsOneWidget);
    expect(_key('tiktok-connect'), findsNothing);
    await tester.tap(_key('tiktok-disconnect'));
    await tester.pumpAndSettle();
    expect(_key('tiktok-disconnect-dialog'), findsOneWidget);
    expect(api.count('jarz_social.api.tiktok.disconnect'), 0);
    await tester.tap(_key('tiktok-disconnect-confirm'));
    await tester.pumpAndSettle();
    expect(api.count('jarz_social.api.tiktok.disconnect'), 1);
    expect(find.text('Not connected'), findsOneWidget);
  });

  testWidgets('Connect is off until the app id and secret are entered', (
    tester,
  ) async {
    final api = _api();
    api.respond['jarz_social.api.tiktok.status'] = (_) => {
      'configured': false,
      'connected': false,
      'scopes': <String>[],
    };
    await pumpMore(tester, const SettingsHubScreen(), size: _tall, api: api);
    expect(_key('tiktok-not-configured'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(_key('tiktok-connect')).onPressed,
      isNull,
    );
  });

  testWidgets('a status that cannot be read shows a plain line', (
    tester,
  ) async {
    final api = _api();
    api.respond['jarz_social.api.tiktok.status'] = (_) =>
        throw StateError('down');
    await pumpMore(tester, const SettingsHubScreen(), size: _tall, api: api);
    expect(_key('tiktok-error'), findsOneWidget);
  });

  testWidgets('Arabic: short Egyptian lines', (tester) async {
    await pumpMore(
      tester,
      const SettingsHubScreen(),
      size: _tall,
      api: _api(connected: true),
      locale: 'ar',
    );
    expect(find.text('متوصّل بحساب jarzegypt'), findsOneWidget);
    expect(find.text('افصل'), findsOneWidget);
  });

  testWidgets('the fake API serves the card (connect then disconnect)', (
    tester,
  ) async {
    await pumpMore(tester, const SettingsHubScreen(), size: _tall);
    expect(find.text('Not connected'), findsOneWidget);
    await tester.tap(_key('tiktok-connect'));
    await tester.pumpAndSettle();
    await tester.tap(_key('tiktok-refresh'));
    await tester.pumpAndSettle();
    expect(find.text('Connected as jarzegypt'), findsOneWidget);
  });
}
