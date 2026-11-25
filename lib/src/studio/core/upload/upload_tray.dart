import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/studio_tokens.dart';
import '../offline/reachability.dart';
import 'file_source.dart';
import 'upload_engine.dart';
import 'upload_job.dart';
import 'upload_strings.dart';

/// What is uploading, what failed (with "try again") and what is done. Draws
/// nothing while the queue is empty. Put it on any screen that starts uploads.
class UploadTray extends ConsumerWidget {
  const UploadTray({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(studioUploadEngineProvider);
    if (q.jobs.isEmpty) return const SizedBox.shrink();
    final t = UploadStrings.of(context);
    final theme = Theme.of(context);
    final engine = ref.read(studioUploadEngineProvider.notifier);
    return Card(
      key: const ValueKey('upload-tray'),
      margin: const EdgeInsets.symmetric(
        horizontal: StudioSpacing.gutter,
        vertical: StudioSpacing.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload_outlined, size: 20),
                const SizedBox(width: StudioSpacing.sm),
                Expanded(
                  child: Text(
                    '${t.trayTitle}  ${t.trayCounts(q.active.length, q.failed.length, q.done.length)}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (q.done.isNotEmpty)
                  TextButton(
                    key: const ValueKey('tray-clear'),
                    onPressed: engine.clearFinished,
                    child: Text(t.dismissDone),
                  ),
              ],
            ),
            if (q.active.isNotEmpty) ...[
              const SizedBox(height: StudioSpacing.xs),
              LinearProgressIndicator(
                key: const ValueKey('tray-overall'),
                value: q.overall,
              ),
            ],
            const SizedBox(height: StudioSpacing.sm),
            for (final j in q.jobs) _JobRow(job: j),
          ],
        ),
      ),
    );
  }
}

class _JobRow extends ConsumerWidget {
  const _JobRow({required this.job});
  final UploadJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UploadStrings.of(context);
    final theme = Theme.of(context);
    final engine = ref.read(studioUploadEngineProvider.notifier);
    final online = ref.watch(studioReachabilityProvider);

    final status = switch (job.status) {
      UploadStatus.queued => online ? t.waitingForTurn : t.waitingForConnection,
      UploadStatus.uploading => t.uploadingPercent(
        (job.progress * 100).round(),
      ),
      UploadStatus.paused =>
        job.needsFile ? t.pickAgainWhy : t.waitingForConnection,
      UploadStatus.failed => t.errorText(job.errorCode, job.errorMessage),
      UploadStatus.done =>
        job.followUpError != null ? t.followUpFailed : t.uploaded,
    };
    final isError =
        job.status == UploadStatus.failed || job.followUpError != null;

    return Padding(
      key: ValueKey('upload-${job.id}'),
      padding: const EdgeInsets.symmetric(vertical: StudioSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            status,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isError ? StudioColors.danger : StudioColors.plumMuted,
            ),
          ),
          if (job.status == UploadStatus.uploading)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.xxs),
              child: LinearProgressIndicator(value: job.progress),
            ),
          Wrap(
            spacing: StudioSpacing.sm,
            children: [
              if (job.status == UploadStatus.failed)
                TextButton(
                  key: ValueKey('retry-${job.id}'),
                  onPressed: () => engine.retry(job.id),
                  child: Text(t.retry),
                ),
              if (job.needsFile)
                TextButton(
                  key: ValueKey('pick-again-${job.id}'),
                  onPressed: () async {
                    final files = await ref
                        .read(studioFileSourceProvider)
                        .pickFiles(multiple: false);
                    for (final f in files) {
                      await engine.enqueue(f, purpose: job.purpose);
                    }
                  },
                  child: Text(t.pickAgain),
                ),
              if (job.status == UploadStatus.done && job.followUpError != null)
                TextButton(
                  key: ValueKey('follow-${job.id}'),
                  onPressed: () => engine.retryFollowUp(job.id),
                  child: Text(t.tryAgain),
                ),
              if (job.isActive || job.status == UploadStatus.failed)
                TextButton(
                  key: ValueKey('cancel-${job.id}'),
                  onPressed: () => engine.cancel(job.id),
                  child: Text(t.cancel),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
