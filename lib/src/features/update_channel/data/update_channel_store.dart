import 'package:shared_preferences/shared_preferences.dart';

import 'update_channel.dart';

/// Device-local memory of the last resolved patch track, so a cold start
/// before login (or offline) checks the same track the device was last told
/// to follow.
abstract class UpdateChannelStore {
  /// Returns `null` when nothing (readable) is stored. Never throws.
  Future<PatchTrack?> readTrack();

  /// Never throws.
  Future<void> writeTrack(PatchTrack track);

  /// The patch number this device was last forced to restart for. Used to
  /// stop the forced-restart screen from looping if a restart does not clear
  /// the pending patch. Never throws.
  Future<int?> readForcedRestartPatch();

  /// Never throws.
  Future<void> writeForcedRestartPatch(int patchNumber);
}

class SharedPrefsUpdateChannelStore implements UpdateChannelStore {
  const SharedPrefsUpdateChannelStore();

  static const trackKey = 'shorebird_update_track_v1';
  static const forcedRestartPatchKey = 'shorebird_forced_restart_patch_v1';

  @override
  Future<PatchTrack?> readTrack() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return PatchTrack.tryParse(prefs.getString(trackKey));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeTrack(PatchTrack track) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(trackKey, track.wireName);
    } catch (_) {
      // Losing the cache only means the next pre-login check uses "stable".
    }
  }

  @override
  Future<int?> readForcedRestartPatch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(forcedRestartPatchKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeForcedRestartPatch(int patchNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(forcedRestartPatchKey, patchNumber);
    } catch (_) {}
  }
}
