import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../update_channel/state/update_channel_provider.dart';
import '../../data/about_release_info_repository.dart';

final aboutReleaseInfoRepositoryProvider = Provider<AboutReleaseInfoRepository>(
  (ref) {
    return AboutReleaseInfoRepository();
  },
);

final aboutReleaseInfoProvider = FutureProvider.autoDispose<AboutReleaseInfo>((
  ref,
) async {
  final repository = ref.watch(aboutReleaseInfoRepositoryProvider);
  // Same track as the auto-updater, so the About screen reports (and never
  // checks) a different track than the one this device follows.
  final track = await ref.read(updateChannelProvider.notifier).currentTrack();
  return repository.fetchReleaseInfo(track: track);
});
