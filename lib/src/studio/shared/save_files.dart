import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/studio_api.dart';
import '../core/theme/studio_tokens.dart';
import '../data/models/studio_enums.dart';
import '../data/models/studio_models.dart';
import 'media/studio_media_viewer.dart';
import 'studio_toast.dart';
import 'studio_tr.dart';

/// "Save" for the files of a version or an asset: one button per file (each
/// slide of a carousel) and "Save all" when there are several, each through
/// `media.download_link` (a signed link that opens in the browser; no zip).
class SaveFilesBar extends ConsumerStatefulWidget {
  const SaveFilesBar({super.key, required this.files});

  final List<StudioMedia> files;

  @override
  ConsumerState<SaveFilesBar> createState() => _SaveFilesBarState();
}

class _SaveFilesBarState extends ConsumerState<SaveFilesBar> {
  bool _busy = false;

  Future<bool> _save(StudioMedia m) async {
    try {
      final link = await ref
          .read(studioApiProvider)
          .mediaDownloadLink(mediaId: m.id);
      return await ref.read(studioLinkOpenerProvider)(Uri.parse(link.url));
    } catch (_) {
      return false;
    }
  }

  Future<void> _run(List<StudioMedia> files) async {
    final failed = context.tr(
      'Could not save. Try again.',
      'ماقدرتش أحفظ. جرّب تاني.',
    );
    setState(() => _busy = true);
    var allOk = true;
    for (final m in files) {
      allOk = await _save(m) && allOk;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (!allOk) showStudioToast(failed);
  }

  @override
  Widget build(BuildContext context) {
    final files = widget.files;
    if (files.isEmpty) return const SizedBox.shrink();
    String label(int i, StudioMedia m) {
      if (files.length == 1) {
        return m.kind == MediaKind.video
            ? context.tr('Save the video', 'احفظ الفيديو')
            : context.tr('Save', 'احفظ');
      }
      return m.kind == MediaKind.video
          ? context.tr('Save video ${i + 1}', 'احفظ الفيديو ${i + 1}')
          : context.tr('Save file ${i + 1}', 'احفظ الملف ${i + 1}');
    }

    return Wrap(
      key: const ValueKey('save-files'),
      spacing: StudioSpacing.sm,
      runSpacing: StudioSpacing.sm,
      children: [
        for (final (i, m) in files.indexed)
          OutlinedButton.icon(
            key: ValueKey('save-media-$i'),
            icon: const Icon(Icons.download),
            onPressed: _busy ? null : () => _run([m]),
            label: Text(label(i, m)),
          ),
        if (files.length > 1)
          FilledButton.tonalIcon(
            key: const ValueKey('save-media-all'),
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: _busy ? null : () => _run(files),
            label: Text(context.tr('Save all', 'احفظ الكل')),
          ),
      ],
    );
  }
}

/// The files of a version: its files, or the pictures of its story frames.
List<StudioMedia> versionFiles(PieceVersion v) => v.files.isNotEmpty
    ? [for (final f in v.files) f.media]
    : [for (final f in v.frames) ?f.asset.media];
