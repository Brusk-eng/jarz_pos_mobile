import 'package:flutter/foundation.dart';

/// The Shorebird patch track a device follows.
///
/// Only these two exist on purpose. The server may one day send something
/// else; anything unrecognised is read as [stable], which is exactly what an
/// app built before this feature did (Shorebird's default track).
enum PatchTrack {
  stable('stable'),
  beta('beta');

  const PatchTrack(this.wireName);

  /// The track name Shorebird and the server use.
  final String wireName;

  /// Parses a track name. Returns `null` for anything that is not exactly a
  /// known track, so callers can tell "server said stable" from "server said
  /// nonsense".
  static PatchTrack? tryParse(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase();
    for (final track in PatchTrack.values) {
      if (track.wireName == normalized) return track;
    }
    return null;
  }
}

/// The server's answer to "which patch track is this device on?".
@immutable
class UpdateChannel {
  const UpdateChannel({
    required this.track,
    required this.forceRestart,
    required this.channel,
    required this.source,
  });

  /// Today's behaviour: Shorebird's default track, no forced restart. Every
  /// failure path lands here.
  static const fallback = UpdateChannel(
    track: PatchTrack.stable,
    forceRestart: false,
    channel: 'normal',
    source: 'fallback',
  );

  /// What the app knows before it has asked the server this session: the
  /// track last resolved on this device. Never forces a restart - only a live
  /// server answer can do that.
  factory UpdateChannel.cached(PatchTrack track) => UpdateChannel(
    track: track,
    forceRestart: false,
    channel: track == PatchTrack.beta ? 'fast' : 'normal',
    source: 'cache',
  );

  final PatchTrack track;

  /// Whether a downloaded patch should block the app until it is restarted.
  final bool forceRestart;

  /// "fast" or "normal" - informational only.
  final String channel;

  /// "device", "role", "default" from the server; "cache" or "fallback"
  /// locally. Informational only.
  final String source;

  /// Parses the Frappe `message` payload. Never throws.
  ///
  /// A missing or unknown `track` discards the whole answer (including
  /// `force_restart`) and returns [fallback]: a payload we cannot read is not
  /// one we act on.
  static UpdateChannel fromJson(Object? json) {
    if (json is! Map) return fallback;
    final track = PatchTrack.tryParse(json['track']);
    if (track == null) return fallback;
    final channel = json['channel'];
    final source = json['source'];
    return UpdateChannel(
      track: track,
      // Strictly `true`: "1", "yes", 1 are not a reason to lock a till.
      forceRestart: json['force_restart'] == true,
      channel: channel is String && channel.trim().isNotEmpty
          ? channel.trim()
          : (track == PatchTrack.beta ? 'fast' : 'normal'),
      source: source is String && source.trim().isNotEmpty
          ? source.trim()
          : 'server',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UpdateChannel &&
      other.track == track &&
      other.forceRestart == forceRestart &&
      other.channel == channel &&
      other.source == source;

  @override
  int get hashCode => Object.hash(track, forceRestart, channel, source);

  @override
  String toString() =>
      'UpdateChannel(track: ${track.wireName}, forceRestart: $forceRestart, '
      'channel: $channel, source: $source)';
}
