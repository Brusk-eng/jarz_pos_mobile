import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/features/update_channel/data/update_channel.dart';
import 'package:jarz_pos/src/features/update_channel/data/update_channel_service.dart';
import 'package:jarz_pos/src/features/update_channel/state/update_channel_provider.dart';

import 'update_channel_fakes.dart';

void main() {
  group('UpdateChannel.fromJson', () {
    test('reads a fast-channel answer', () {
      final channel = UpdateChannel.fromJson({
        'channel': 'fast',
        'track': 'beta',
        'force_restart': true,
        'source': 'device',
      });
      expect(channel.track, PatchTrack.beta);
      expect(channel.forceRestart, isTrue);
      expect(channel.channel, 'fast');
      expect(channel.source, 'device');
    });

    test('reads a normal-channel answer', () {
      final channel = UpdateChannel.fromJson({
        'channel': 'normal',
        'track': 'stable',
        'force_restart': false,
        'source': 'default',
      });
      expect(channel.track, PatchTrack.stable);
      expect(channel.forceRestart, isFalse);
    });

    test('tolerates case and whitespace in the track name', () {
      expect(
        UpdateChannel.fromJson({'track': ' BETA '}).track,
        PatchTrack.beta,
      );
    });

    for (final bad in <Object?>[
      null,
      'beta',
      42,
      <String, dynamic>{},
      {'track': null},
      {'track': 'staging'},
      {'track': 'alpha', 'force_restart': true},
      {'track': 7},
      {'channel': 'fast', 'force_restart': true},
    ]) {
      test('falls back to stable for $bad', () {
        expect(UpdateChannel.fromJson(bad), UpdateChannel.fallback);
        expect(UpdateChannel.fromJson(bad).forceRestart, isFalse);
      });
    }

    test('force_restart must be literally true', () {
      for (final value in <Object?>['true', 1, 'yes', null]) {
        expect(
          UpdateChannel.fromJson({
            'track': 'beta',
            'force_restart': value,
          }).forceRestart,
          isFalse,
          reason: '$value',
        );
      }
    });

    test('missing channel/source get sensible defaults', () {
      final channel = UpdateChannel.fromJson({'track': 'beta'});
      expect(channel.channel, 'fast');
      expect(channel.source, 'server');
      expect(channel.forceRestart, isFalse);
    });
  });

  group('UpdateChannelService', () {
    UpdateChannelService serviceWith(_FakeAdapter adapter) {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      return UpdateChannelService(dio, timeout: const Duration(seconds: 2));
    }

    test('parses a 200 answer and sends the token', () async {
      final adapter = _FakeAdapter.json(200, {
        'message': {
          'channel': 'fast',
          'track': 'beta',
          'force_restart': true,
          'source': 'role',
        },
      });
      final result = await serviceWith(adapter).fetchChannel(fcmToken: 'tok');
      expect(result?.track, PatchTrack.beta);
      expect(result?.forceRestart, isTrue);
      expect(adapter.lastPath, contains('app_release.get_update_channel'));
      expect(adapter.lastMethod, 'POST');
      expect(adapter.lastBody, contains('"token":"tok"'));
    });

    test('omits the token when there is none', () async {
      final adapter = _FakeAdapter.json(200, {
        'message': {'track': 'stable'},
      });
      await serviceWith(adapter).fetchChannel();
      expect(adapter.lastBody ?? '', isNot(contains('token')));
    });

    for (final status in [403, 404, 417, 500]) {
      test(
        'HTTP $status (e.g. server without the endpoint) -> stable',
        () async {
          final result = await serviceWith(
            _FakeAdapter.json(status, {'exc_type': 'Whatever'}),
          ).fetchChannel(fcmToken: 'tok');
          expect(result, UpdateChannel.fallback);
        },
      );
    }

    test('an unknown track -> stable', () async {
      final result = await serviceWith(
        _FakeAdapter.json(200, {
          'message': {'track': 'canary', 'force_restart': true},
        }),
      ).fetchChannel();
      expect(result, UpdateChannel.fallback);
    });

    test('a non-JSON body -> stable', () async {
      final result = await serviceWith(
        _FakeAdapter.raw(200, '<html>proxy</html>', 'text/html'),
      ).fetchChannel();
      expect(result, UpdateChannel.fallback);
    });

    test('no answer at all (offline) -> null, i.e. keep current', () async {
      final result = await serviceWith(
        _FakeAdapter.failing(const SocketException('offline')),
      ).fetchChannel();
      expect(result, isNull);
    });

    test('a hung request times out -> null, i.e. keep current', () async {
      final adapter = _FakeAdapter.hanging();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      final result = await UpdateChannelService(
        dio,
        timeout: const Duration(milliseconds: 50),
      ).fetchChannel();
      expect(result, isNull);
    });
  });

  group('updateChannelProvider', () {
    ProviderContainer containerWith({
      required MemoryUpdateChannelStore store,
      required ScriptedUpdateChannelService service,
      FcmTokenReader? tokenReader,
    }) {
      final container = ProviderContainer(
        overrides: [
          updateChannelStoreProvider.overrideWithValue(store),
          updateChannelServiceProvider.overrideWithValue(service),
          updateChannelFcmTokenReaderProvider.overrideWithValue(
            tokenReader ?? () async => 'fcm-token',
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    const fastAnswer = UpdateChannel(
      track: PatchTrack.beta,
      forceRestart: true,
      channel: 'fast',
      source: 'role',
    );

    test('defaults to stable with nothing cached', () async {
      final container = containerWith(
        store: MemoryUpdateChannelStore(),
        service: ScriptedUpdateChannelService([]),
      );
      final channel = await container.read(updateChannelProvider.future);
      expect(channel.track, PatchTrack.stable);
      expect(channel.forceRestart, isFalse);
    });

    test('starts from the cached track, without forcing a restart', () async {
      final container = containerWith(
        store: MemoryUpdateChannelStore(track: PatchTrack.beta),
        service: ScriptedUpdateChannelService([]),
      );
      final channel = await container.read(updateChannelProvider.future);
      expect(channel.track, PatchTrack.beta);
      expect(channel.forceRestart, isFalse);
      expect(channel.source, 'cache');
    });

    test('an unreadable cache means stable', () async {
      final container = containerWith(
        store: MemoryUpdateChannelStore(throwOnRead: true),
        service: ScriptedUpdateChannelService([]),
      );
      expect(
        await container.read(updateChannelProvider.notifier).currentTrack(),
        PatchTrack.stable,
      );
    });

    test(
      'refresh applies and caches the server answer, sending the token',
      () async {
        final store = MemoryUpdateChannelStore();
        final service = ScriptedUpdateChannelService([fastAnswer]);
        final container = containerWith(store: store, service: service);

        await container.read(updateChannelProvider.notifier).refresh();

        expect(container.read(updateChannelProvider).valueOrNull, fastAnswer);
        expect(store.track, PatchTrack.beta);
        expect(service.tokens, ['fcm-token']);
      },
    );

    test('a server error answer resets a cached beta to stable', () async {
      final store = MemoryUpdateChannelStore(track: PatchTrack.beta);
      final container = containerWith(
        store: store,
        service: ScriptedUpdateChannelService([UpdateChannel.fallback]),
      );
      await container.read(updateChannelProvider.future);

      await container.read(updateChannelProvider.notifier).refresh();

      expect(
        container.read(updateChannelProvider).valueOrNull?.track,
        PatchTrack.stable,
      );
      expect(store.track, PatchTrack.stable);
    });

    test('no answer (offline) keeps the cached track and cache', () async {
      final store = MemoryUpdateChannelStore(track: PatchTrack.beta);
      final container = containerWith(
        store: store,
        service: ScriptedUpdateChannelService([null]),
      );

      await container.read(updateChannelProvider.notifier).refresh();

      expect(
        container.read(updateChannelProvider).valueOrNull?.track,
        PatchTrack.beta,
      );
      expect(store.writes, isEmpty);
    });

    test(
      'a failing token reader still asks the server, without a token',
      () async {
        final service = ScriptedUpdateChannelService([fastAnswer]);
        final container = containerWith(
          store: MemoryUpdateChannelStore(),
          service: service,
          tokenReader: () async => throw StateError('no firebase'),
        );

        await container.read(updateChannelProvider.notifier).refresh();

        expect(service.tokens, [null]);
        expect(
          container.read(updateChannelProvider).valueOrNull?.track,
          PatchTrack.beta,
        );
      },
    );

    test('concurrent refreshes share one request', () async {
      final service = ScriptedUpdateChannelService([fastAnswer]);
      final container = containerWith(
        store: MemoryUpdateChannelStore(),
        service: service,
      );
      final notifier = container.read(updateChannelProvider.notifier);

      await Future.wait([notifier.refresh(), notifier.refresh()]);

      expect(service.calls, 1);
    });
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter._(this._respond);

  factory _FakeAdapter.json(int status, Object body) => _FakeAdapter._(
    (_) async => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    ),
  );

  factory _FakeAdapter.raw(int status, String body, String contentType) =>
      _FakeAdapter._(
        (_) async => ResponseBody.fromString(
          body,
          status,
          headers: {
            Headers.contentTypeHeader: [contentType],
          },
        ),
      );

  factory _FakeAdapter.failing(Object error) =>
      _FakeAdapter._((_) async => throw error);

  factory _FakeAdapter.hanging() =>
      _FakeAdapter._((_) => Completer<ResponseBody>().future);

  final Future<ResponseBody> Function(RequestOptions options) _respond;

  String? lastPath;
  String? lastMethod;
  String? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastPath = options.path;
    lastMethod = options.method;
    if (requestStream != null) {
      final bytes = await requestStream.expand((chunk) => chunk).toList();
      lastBody = utf8.decode(bytes);
    }
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}
