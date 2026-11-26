import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';

/// The TikTok endpoints live next to the Studio API, not inside it
/// (`jarz_social.api.tiktok.*`): they are outside the frozen contract.
const tiktokMethodPrefix = 'jarz_social.api.tiktok.';

/// What the server says about the TikTok connection. No token ever travels
/// here: only whether one is stored, the account name and the dates.
class TikTokStatus {
  const TikTokStatus({
    required this.configured,
    required this.connected,
    this.accountName,
    this.expiresAt,
    this.refreshExpiresAt,
    this.scopes = const [],
    this.error,
  });

  /// The app id and secret are entered in Social Account Settings.
  final bool configured;
  final bool connected;
  final String? accountName;
  final DateTime? expiresAt;
  final DateTime? refreshExpiresAt;
  final List<String> scopes;

  /// The last connect or refresh problem, in a plain sentence.
  final String? error;

  factory TikTokStatus.fromJson(Map<String, dynamic> j) => TikTokStatus(
    configured: j['configured'] == true,
    connected: j['connected'] == true,
    accountName: _text(j['account_name']),
    expiresAt: DateTime.tryParse('${j['expires_at'] ?? ''}'),
    refreshExpiresAt: DateTime.tryParse('${j['refresh_expires_at'] ?? ''}'),
    scopes: [for (final s in (j['scopes'] as List? ?? const [])) '$s'],
    error: _text(j['error']),
  );

  static String? _text(Object? v) {
    final s = '${v ?? ''}'.trim();
    return s.isEmpty ? null : s;
  }
}

class TikTokRepository {
  TikTokRepository(this._api);
  final StudioApi _api;

  Future<TikTokStatus> status() async {
    final d = await _api.call('${tiktokMethodPrefix}status', get: true);
    return TikTokStatus.fromJson(Map<String, dynamic>.from(d as Map));
  }

  /// The TikTok page to open in a browser. Founder only on the server.
  Future<String> connectUrl() async {
    final d = await _api.call('${tiktokMethodPrefix}connect_url', get: true);
    return '${(d as Map)['url']}';
  }

  Future<TikTokStatus> disconnect() async {
    final d = await _api.call('${tiktokMethodPrefix}disconnect');
    return TikTokStatus.fromJson(Map<String, dynamic>.from(d as Map));
  }
}

final tiktokRepositoryProvider = Provider<TikTokRepository>(
  (ref) => TikTokRepository(ref.watch(studioApiProvider)),
);

final tiktokStatusProvider = FutureProvider.autoDispose<TikTokStatus>(
  (ref) => ref.watch(tiktokRepositoryProvider).status(),
);
