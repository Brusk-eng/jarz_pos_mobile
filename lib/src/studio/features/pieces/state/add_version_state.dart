import '../../../core/upload/upload_engine.dart';
import '../../../core/upload/upload_job.dart';
import '../../../data/models/studio_enums.dart';
import '../../assets/data/assets_repository.dart';
import '../data/pieces_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Upload purpose and follow-up key of the files of a new version.
const versionFollowUpKey = 'version';

/// `versions.add` kind of a piece format (the kind must match the format).
String versionKindOf(PieceFormat f) => switch (f) {
  PieceFormat.reel || PieceFormat.trial => 'video',
  PieceFormat.staticValue => 'static',
  PieceFormat.carousel => 'carousel',
  PieceFormat.story => 'story',
  _ => 'video',
};

/// The files of a version go up one by one; when the LAST file of the batch
/// is stored, this adds the version with every media id in the picked order.
/// A story first turns each stored file into a "Story frame" asset (the
/// contract's `frames` are asset ids), then adds the version with them.
///
/// Every call here uses request ids fixed when the files were picked, so it
/// is safe to run again after a failure, from two files finishing at once, or
/// after the app was closed and reopened (the engine calls it again).
void registerVersionFollowUp(ProviderContainer container) {
  container.read(studioUploadEngineProvider.notifier).registerFollowUp(
    versionFollowUpKey,
    (job, media) async {
      final batch = job.meta['batch'] as String?;
      final size = job.meta['batch_size'] as int? ?? 1;
      final jobs = [
        for (final j in container.read(studioUploadEngineProvider).jobs)
          if (j.meta['batch'] == batch) j,
      ];
      // Not every file is stored yet: the last one to finish does the work.
      if (jobs.length < size ||
          jobs.any((j) => j.status != UploadStatus.done || j.media == null)) {
        return;
      }
      jobs.sort(
        (a, b) =>
            (a.meta['position'] as int).compareTo(b.meta['position'] as int),
      );
      final pieceId = job.meta['piece_id'] as String;
      final kind = job.meta['kind'] as String;
      final addRequestId = job.meta['add_request_id'] as String;
      final title = job.meta['title'] as String?;
      final pieces = container.read(piecesRepositoryProvider);
      if (kind == 'story') {
        final assets = container.read(assetsRepositoryProvider);
        final ids = <String>[];
        for (final j in jobs) {
          final a = await assets.create(
            mediaId: j.media!.id,
            kind: AssetKind.storyFrame.wire,
            requestId: j.meta['asset_request_id'] as String?,
          );
          ids.add(a.id);
        }
        await pieces.addVersion(
          pieceId: pieceId,
          kind: kind,
          frames: ids,
          title: title,
          requestId: addRequestId,
        );
      } else {
        await pieces.addVersion(
          pieceId: pieceId,
          kind: kind,
          mediaIds: [for (final j in jobs) j.media!.id],
          title: title,
          requestId: addRequestId,
        );
      }
      container.invalidate(pieceProvider(pieceId));
      container.invalidate(pieceBoardProvider);
    },
  );
}
