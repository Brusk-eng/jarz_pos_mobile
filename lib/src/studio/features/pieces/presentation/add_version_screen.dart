import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../core/upload/file_source.dart';
import '../../../core/upload/picked_file.dart';
import '../../../core/upload/upload_engine.dart';
import '../../../core/upload/upload_strings.dart';
import '../../../data/api/studio_api_base.dart';
import '../../../data/models/studio_enums.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../data/pieces_repository.dart';
import '../state/add_version_state.dart';

/// `/pieces/:id/add-version`: a creator adds a cut (a video, a picture or the
/// slides of a carousel), the story lead adds the frames of a story and puts
/// them in order. The files go up through the upload engine (the tray shows
/// them, they keep going when the person leaves); when the last file is
/// stored the version is added with their media ids (see
/// [registerVersionFollowUp]). Only when the piece's `actions` allow it.
class AddVersionScreen extends ConsumerStatefulWidget {
  const AddVersionScreen({super.key, required this.pieceId});

  final String pieceId;

  @override
  ConsumerState<AddVersionScreen> createState() => _AddVersionState();
}

class _AddVersionState extends ConsumerState<AddVersionScreen> {
  final _files = <PickedFile>[];
  final _title = TextEditingController();
  final _problems = <String>[];
  bool _busy = false;
  int? _started;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick(bool gallery, bool several) async {
    final src = ref.read(studioFileSourceProvider);
    final picked = gallery
        ? await src.pickMedia(multiple: several)
        : await src.pickFiles(multiple: several);
    if (picked.isEmpty || !mounted) return;
    setState(() {
      if (!several) _files.clear();
      for (final f in picked) {
        if (!_files.any((x) => x.signature == f.signature)) _files.add(f);
      }
    });
  }

  Future<void> _save(PieceFormat format) async {
    if (_files.isEmpty || _busy) return;
    final container = ProviderScope.containerOf(context, listen: false);
    registerVersionFollowUp(container);
    final engine = ref.read(studioUploadEngineProvider.notifier);
    final u = UploadStrings.of(context);
    setState(() {
      _busy = true;
      _problems.clear();
    });
    final kind = versionKindOf(format);
    final batch = newRequestId();
    final addId = newRequestId();
    final title = _title.text.trim();
    var ok = 0;
    for (final (i, f) in List.of(_files).indexed) {
      final r = await engine.enqueue(
        f,
        purpose: kind == 'story' ? 'story_frame' : 'version_file',
        meta: {
          'followUp': versionFollowUpKey,
          'batch': batch,
          'batch_size': _files.length,
          'position': i,
          'piece_id': widget.pieceId,
          'kind': kind,
          'title': title.isEmpty ? null : title,
          'add_request_id': addId,
          'asset_request_id': newRequestId(),
        },
      );
      if (r.ok) {
        ok++;
      } else {
        _problems.add(u.rejection(r.rejection!, f.name));
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok == _files.length) _started = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AddVersionStrings.of(context);
    final piece = ref.watch(pieceProvider(widget.pieceId));
    final back = '/pieces/${widget.pieceId}';
    return ViewEditScaffold(
      title: t.title,
      parentRoute: back,
      body: StudioAsyncView(
        value: piece,
        onRetry: () => ref.invalidate(pieceProvider(widget.pieceId)),
        isEmpty: (_) => false,
        empty: StudioEmptyConfig(purpose: t.title, firstStep: t.title),
        builder: (context, p) {
          if (!p.actions.contains('add_version')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(StudioSpacing.xl),
                child: Text(
                  t.notAllowed,
                  key: const ValueKey('add-version-not-allowed'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (_started != null) return _Done(count: _started!, back: back);
          final story = p.format == PieceFormat.story;
          final several = story || p.format == PieceFormat.carousel;
          final theme = Theme.of(context);
          return ListView(
            key: const ValueKey('add-version-form'),
            padding: const EdgeInsets.all(StudioSpacing.gutter),
            children: [
              Text(p.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: StudioSpacing.xs),
              Text(
                story
                    ? t.storyIntro
                    : (several ? t.carouselIntro : t.singleIntro),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: StudioSpacing.md),
              Wrap(
                spacing: StudioSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('add-version-gallery'),
                    onPressed: () => _pick(true, several),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(t.fromGallery),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('add-version-files'),
                    onPressed: () => _pick(false, several),
                    icon: const Icon(Icons.folder_open_outlined),
                    label: Text(t.fromFiles),
                  ),
                ],
              ),
              const SizedBox(height: StudioSpacing.md),
              if (_files.isEmpty)
                Text(
                  t.nothingPicked,
                  key: const ValueKey('add-version-empty'),
                  style: theme.textTheme.bodySmall,
                )
              else ...[
                if (several && _files.length > 1)
                  Text(t.dragToOrder, style: theme.textTheme.bodySmall),
                ReorderableListView(
                  key: const ValueKey('add-version-files-list'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: several,
                  onReorderItem: (from, to) => setState(() {
                    _files.insert(to, _files.removeAt(from));
                  }),
                  children: [
                    for (final (i, f) in _files.indexed)
                      ListTile(
                        key: ValueKey('add-version-file-${f.signature}'),
                        leading: CircleAvatar(
                          radius: 14,
                          child: Text('${i + 1}'),
                        ),
                        title: Text(
                          f.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          f.mime.startsWith('video/') ? t.video : t.picture,
                        ),
                        trailing: IconButton(
                          key: ValueKey('add-version-remove-$i'),
                          tooltip: t.remove,
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _files.remove(f)),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: StudioSpacing.sm),
              TextField(
                key: const ValueKey('add-version-title'),
                controller: _title,
                decoration: InputDecoration(labelText: t.titleLabel),
              ),
              for (final msg in _problems)
                Padding(
                  padding: const EdgeInsets.only(top: StudioSpacing.sm),
                  child: Text(
                    msg,
                    key: const ValueKey('add-version-problem'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: StudioColors.danger,
                    ),
                  ),
                ),
              const SizedBox(height: StudioSpacing.lg),
              if (_files.isEmpty || _busy)
                Padding(
                  padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
                  child: Text(
                    _busy ? t.uploadingNow : t.pickFirst,
                    key: ValueKey(
                      _busy ? 'add-version-busy' : 'add-version-pick-first',
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              FilledButton(
                key: const ValueKey('add-version-save'),
                onPressed: _files.isEmpty || _busy
                    ? null
                    : () => _save(p.format),
                child: Text(story ? t.saveFrames : t.save),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.count, required this.back});

  final int count;
  final String back;

  @override
  Widget build(BuildContext context) {
    final t = AddVersionStrings.of(context);
    final theme = Theme.of(context);
    return ListView(
      key: const ValueKey('add-version-done'),
      padding: const EdgeInsets.all(StudioSpacing.gutter),
      children: [
        const Icon(Icons.cloud_upload_outlined, size: 40),
        const SizedBox(height: StudioSpacing.md),
        Text(t.started(count), style: theme.textTheme.titleMedium),
        const SizedBox(height: StudioSpacing.sm),
        Text(t.whatNext, key: const ValueKey('add-version-next')),
        const SizedBox(height: StudioSpacing.lg),
        FilledButton(
          key: const ValueKey('add-version-back'),
          onPressed: () => context.canPop() ? context.pop() : context.go(back),
          child: Text(t.backToPiece),
        ),
      ],
    );
  }
}

/// The words of the screen, English and Arabic side by side.
class AddVersionStrings {
  const AddVersionStrings._(this.ar);
  final bool ar;

  static AddVersionStrings of(BuildContext context) =>
      AddVersionStrings._(Localizations.localeOf(context).languageCode == 'ar');

  String tr(String en, String arabic) => ar ? arabic : en;

  String get title => tr('Add a version', 'ضيف نسخة');
  String get button => tr('Add a version', 'ضيف نسخة');
  String get buttonFrames => tr('Add the frames', 'ضيف الفريمات');
  String get pickFirst => tr(
    'Pick at least one file first. The upload button wakes up once you have.',
    'اختار ملف واحد على الأقل الأول. زرار الرفع بيشتغل أول ما تختار.',
  );
  String get uploadingNow => tr(
    'The upload is still running. The button wakes up when it is done.',
    'الرفع لسه شغال. الزرار بيشتغل تاني أول ما يخلص.',
  );
  String get notAllowed => tr(
    'Your role cannot add a version to this piece.',
    'مش مسموح لدورك تضيف نسخة للقطعة دي.',
  );
  String get singleIntro => tr(
    'Pick the finished cut. It uploads in the background.',
    'اختار النسخة الجاهزة. هتترفع في الخلفية.',
  );
  String get carouselIntro => tr(
    'Pick the slides, then drag them into the order people swipe through.',
    'اختار الشرايح، وبعدين اسحبها بالترتيب اللي الناس هتقلّب بيه.',
  );
  String get storyIntro => tr(
    'Pick the pictures and clips for the Story frames, then drag them into the order they post.',
    'اختار الصور والكليبات لفريمات الـ Story، وبعدين اسحبها بترتيب النشر.',
  );
  String get fromGallery => tr('From the gallery', 'من المعرض');
  String get fromFiles => tr('From files', 'من الملفات');
  String get nothingPicked => tr('Nothing picked yet.', 'لسه ما اتختارش حاجة.');
  String get dragToOrder => tr(
    'Hold and drag to change the order.',
    'امسك واسحب عشان تغيّر الترتيب.',
  );
  String get video => tr('Video', 'فيديو');
  String get picture => tr('Picture', 'صورة');
  String get remove => tr('Remove', 'امسح');
  String get titleLabel => tr('Title (optional)', 'العنوان (اختياري)');
  String get save => tr('Upload the version', 'ارفع النسخة');
  String get saveFrames => tr('Upload the frames', 'ارفع الفريمات');
  String started(int n) => tr(
    n == 1 ? '1 file is uploading.' : '$n files are uploading.',
    n == 1
        ? 'ملف واحد بيترفع.'
        : (n == 2
              ? 'ملفين بيترفعوا.'
              : (n <= 10 ? '$n ملفات بيترفعوا.' : '$n ملف بيترفعوا.')),
  );
  String get whatNext => tr(
    'When the files are stored, the version is added to the piece. It goes to review once it has its verdict, passes the checks and has a slot. Then the founder approves it or sends it back with a reason. You can leave this page; the uploads keep going.',
    'أول ما الملفات تتخزن، النسخة بتتضاف للقطعة. وبتروح للريفيو لما يبقى ليها verdict وتعدّي الفحوصات وليها ميعاد. بعدها المؤسس بيوافق عليها أو بيرجّعها بسبب. ممكن تسيب الصفحة؛ الرفع بيكمّل.',
  );
  String get backToPiece => tr('Back to the piece', 'رجوع للقطعة');
}
