import 'package:dio/dio.dart';
import 'package:jarz_pos/src/features/about/data/about_release_info_repository.dart';
import 'package:jarz_pos/src/features/update_channel/data/update_channel.dart';
import 'package:jarz_pos/src/features/update_channel/data/update_channel_service.dart';
import 'package:jarz_pos/src/features/update_channel/data/update_channel_store.dart';

/// In-memory [UpdateChannelStore].
class MemoryUpdateChannelStore implements UpdateChannelStore {
  MemoryUpdateChannelStore({
    this.track,
    this.forcedPatch,
    this.throwOnRead = false,
  });

  PatchTrack? track;
  int? forcedPatch;
  final bool throwOnRead;
  final List<PatchTrack> writes = [];

  @override
  Future<PatchTrack?> readTrack() async {
    if (throwOnRead) throw StateError('prefs unavailable');
    return track;
  }

  @override
  Future<void> writeTrack(PatchTrack value) async {
    writes.add(value);
    track = value;
  }

  @override
  Future<int?> readForcedRestartPatch() async => forcedPatch;

  @override
  Future<void> writeForcedRestartPatch(int patchNumber) async {
    forcedPatch = patchNumber;
  }
}

/// [UpdateChannelService] that returns scripted answers (`null` = no answer).
class ScriptedUpdateChannelService extends UpdateChannelService {
  ScriptedUpdateChannelService(this.answers) : super(Dio());

  final List<UpdateChannel?> answers;
  final List<String?> tokens = [];
  int calls = 0;

  @override
  Future<UpdateChannel?> fetchChannel({String? fcmToken}) async {
    calls++;
    tokens.add(fcmToken);
    if (answers.isEmpty) return null;
    return answers.length == 1 ? answers.first : answers.removeAt(0);
  }
}

/// Scripts a sequence of [readStatus] results and records the track of every
/// call. When the script is exhausted the last status is repeated.
class FakeShorebirdUpdateGateway implements ShorebirdUpdateGateway {
  FakeShorebirdUpdateGateway({
    required List<ShorebirdPatchStatus> statuses,
    required this.downloadResult,
    this.nextPatchNumber,
  }) : _statuses = List.of(statuses);

  final List<ShorebirdPatchStatus> _statuses;
  final bool downloadResult;
  final int? nextPatchNumber;

  int readCalls = 0;
  int downloadCalls = 0;
  final List<PatchTrack> readTracks = [];
  final List<PatchTrack> downloadTracks = [];

  @override
  Future<ShorebirdDiagnostics> readStatus({required PatchTrack track}) async {
    readCalls++;
    readTracks.add(track);
    final status = _statuses.length <= 1
        ? (_statuses.isEmpty ? ShorebirdPatchStatus.unknown : _statuses.first)
        : _statuses.removeAt(0);
    return ShorebirdDiagnostics(
      status: status,
      nextPatchNumber: status == ShorebirdPatchStatus.restartRequired
          ? nextPatchNumber
          : null,
    );
  }

  @override
  Future<bool> downloadUpdate({required PatchTrack track}) async {
    downloadCalls++;
    downloadTracks.add(track);
    // Yield so overlapping callers can interleave like a real download.
    await Future<void>.delayed(Duration.zero);
    return downloadResult;
  }
}
