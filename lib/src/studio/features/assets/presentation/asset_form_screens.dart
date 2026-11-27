import '../../../shared/layout/studio_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/studio_api.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../core/upload/file_source.dart';
import '../../../core/upload/picked_file.dart';
import '../../../core/upload/upload_engine.dart';
import '../../../core/upload/upload_strings.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/how_this_works_sheet.dart';
import '../../settings/data/settings_repository.dart';
import '../assets_strings.dart';
import '../data/assets_repository.dart';
import '../state/library_state.dart';
import 'asset_widgets.dart';
import '../../../shared/studio_toast.dart';
import '../../../core/l10n/studio_strings.dart';

/// `/assets/new`: pick files from the phone, say what they are, and send
/// them up. The upload runs in the background (the tray shows it); each file
/// becomes an asset when it is stored.
class AssetAddScreen extends ConsumerStatefulWidget {
  const AssetAddScreen({super.key});

  @override
  ConsumerState<AssetAddScreen> createState() => _AssetAddScreenState();
}

class _AssetAddScreenState extends ConsumerState<AssetAddScreen> {
  final files = <PickedFile>[];
  final title = TextEditingController();
  final note = TextEditingController();
  AssetKind? kind;
  String? flavourId;
  bool flavourChosen = false;
  AssetCategory? category;
  String? kindError;
  String? flavourError;
  String? categoryError;
  final problems = <String>[];
  var busy = false;

  @override
  void dispose() {
    title.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> pick(bool gallery) async {
    final src = ref.read(studioFileSourceProvider);
    final picked = gallery ? await src.pickMedia() : await src.pickFiles();
    if (picked.isEmpty || !mounted) return;
    setState(() {
      for (final f in picked) {
        if (!files.any((x) => x.signature == f.signature)) files.add(f);
      }
      kind ??= files.first.mime.startsWith('video/')
          ? AssetKind.clip
          : AssetKind.photo;
    });
  }

  Future<void> upload() async {
    final t = AssetStrings.of(context);
    final u = UploadStrings.of(context);
    if (files.isEmpty) return;
    if (kind == null || !flavourChosen || category == null) {
      // Every file is tagged on the way in: no "Any" by default.
      setState(() {
        kindError = kind == null ? t.chooseKind : null;
        flavourError = flavourChosen ? null : t.chooseFlavour;
        categoryError = category == null ? t.chooseCategory : null;
      });
      return;
    }
    setState(() {
      busy = true;
      problems.clear();
      kindError = null;
      flavourError = null;
      categoryError = null;
    });
    final container = ProviderScope.containerOf(context, listen: false);
    registerAssetFollowUp(container);
    final engine = ref.read(studioUploadEngineProvider.notifier);
    var started = 0;
    for (final f in List.of(files)) {
      final r = await engine.enqueue(
        f,
        purpose: 'asset',
        meta: {
          'followUp': assetFollowUpKey,
          'kind': kind!.wire,
          'title': files.length == 1 && title.text.trim().isNotEmpty
              ? title.text.trim()
              : null,
          'flavour_id': flavourId,
          'category': category?.wire,
          'note': note.text.trim().isEmpty ? null : note.text.trim(),
          'create_request_id': newRequestId(),
        },
      );
      if (r.ok) {
        started++;
        files.remove(f);
      } else {
        problems.add(u.rejection(r.rejection!, f.name));
      }
    }
    if (!mounted) return;
    setState(() => busy = false);
    if (started > 0 && problems.isEmpty) {
      showStudioToast(t.uploadStarted);
      context.canPop() ? context.pop() : context.go('/assets');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AssetStrings.of(context);
    final flavours = ref.watch(flavoursProvider).valueOrNull ?? const [];
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/assets'),
        ),
        title: Text(t.addTitle),
        actions: [
          IconButton(
            key: const ValueKey('help'),
            tooltip: StudioStrings.of(context).howThisWorks,
            icon: const Icon(Icons.help_outline),
            onPressed: () => HowThisWorksSheet.show(
              context,
              title: t.addHelpTitle,
              lines: t.addHelp,
            ),
          ),
        ],
      ),
      body: StudioPage(
        maxWidth: StudioContentWidth.form,
        child: AssetPage(
          child: ListView(
            padding: const EdgeInsets.all(StudioSpacing.gutter),
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('pick-gallery'),
                      onPressed: () => pick(true),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(t.pickFromGallery),
                    ),
                  ),
                  const SizedBox(width: StudioSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('pick-files'),
                      onPressed: () => pick(false),
                      icon: const Icon(Icons.folder_open_outlined),
                      label: Text(t.pickFiles),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StudioSpacing.md),
              if (files.isEmpty)
                Text(
                  t.noFilesPicked,
                  key: const ValueKey('no-files'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              for (final f in files)
                ListTile(
                  key: ValueKey('file-${f.signature}'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    f.mime.startsWith('video/')
                        ? Icons.movie_outlined
                        : Icons.image_outlined,
                  ),
                  title: Text(
                    f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(formatBytes(f.size)),
                  trailing: IconButton(
                    tooltip: t.removeFile,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => files.remove(f)),
                  ),
                ),
              if (problems.isNotEmpty)
                for (final p in problems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
                    child: Text(
                      p,
                      key: const ValueKey('add-problem'),
                      style: const TextStyle(color: StudioColors.danger),
                    ),
                  ),
              const SizedBox(height: StudioSpacing.md),
              DropdownButtonFormField<AssetKind>(
                key: const ValueKey('add-kind'),
                isExpanded: true,
                initialValue: kind,
                decoration: InputDecoration(
                  labelText: t.fieldKind,
                  errorText: kindError,
                ),
                items: [
                  for (final k in AssetKind.values)
                    if (k != AssetKind.unknown)
                      DropdownMenuItem(value: k, child: Text(t.kind(k))),
                ],
                onChanged: (v) => setState(() => kind = v),
              ),
              const SizedBox(height: StudioSpacing.md),
              DropdownButtonFormField<String?>(
                key: const ValueKey('add-flavour'),
                isExpanded: true,
                initialValue: flavourChosen ? (flavourId ?? '') : null,
                decoration: InputDecoration(
                  labelText: t.fieldFlavour,
                  errorText: flavourError,
                ),
                items: [
                  DropdownMenuItem(value: '', child: Text(t.noFlavour)),
                  for (final f in flavours)
                    DropdownMenuItem(value: f.id, child: Text(f.name)),
                ],
                onChanged: (v) => setState(() {
                  flavourChosen = v != null;
                  flavourId = (v == null || v.isEmpty) ? null : v;
                  flavourError = null;
                }),
              ),
              const SizedBox(height: StudioSpacing.md),
              DropdownButtonFormField<AssetCategory?>(
                key: const ValueKey('add-category'),
                isExpanded: true,
                initialValue: category,
                decoration: InputDecoration(
                  labelText: t.fieldCategory,
                  errorText: categoryError,
                ),
                items: [
                  for (final c in AssetCategory.values)
                    if (c != AssetCategory.unknown)
                      DropdownMenuItem(value: c, child: Text(t.category(c))),
                ],
                onChanged: (v) => setState(() {
                  category = v;
                  categoryError = null;
                }),
              ),
              if (files.length <= 1) ...[
                const SizedBox(height: StudioSpacing.md),
                TextField(
                  key: const ValueKey('add-title'),
                  controller: title,
                  decoration: InputDecoration(labelText: t.fieldTitle),
                ),
              ],
              const SizedBox(height: StudioSpacing.md),
              TextField(
                key: const ValueKey('add-note'),
                controller: note,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(labelText: t.fieldNote),
              ),
              const SizedBox(height: StudioSpacing.lg),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  key: const ValueKey('add-upload'),
                  onPressed: files.isEmpty || busy ? null : upload,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(t.uploadButton),
                ),
              ),
              if (files.isEmpty || busy)
                Padding(
                  padding: const EdgeInsets.only(top: StudioSpacing.sm),
                  child: Text(
                    busy ? t.uploadStillRunning : t.uploadPickFirst,
                    key: const ValueKey('add-upload-why'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `/assets/:id/edit`: tag and fix a file (title, flavor, category, tags,
/// note, hidden, open for rating).
class AssetEditScreen extends ConsumerStatefulWidget {
  const AssetEditScreen({super.key, required this.assetId});
  final String assetId;

  @override
  ConsumerState<AssetEditScreen> createState() => _AssetEditScreenState();
}

class _AssetEditScreenState extends ConsumerState<AssetEditScreen> {
  final title = TextEditingController();
  final note = TextEditingController();
  final tags = TextEditingController();
  String? flavourId;
  AssetCategory? category;
  var hidden = false;
  var ratingOpen = true;
  StudioAsset? original;
  final errors = <String, String>{};
  String? banner;
  var busy = false;

  void _fill(StudioAsset a) {
    original = a;
    title.text = a.title;
    note.text = a.note ?? '';
    tags.text = a.tags.join(', ');
    flavourId = a.flavour?.id;
    category = a.category;
    hidden = a.hidden;
    ratingOpen = a.ratingOpen;
  }

  @override
  void dispose() {
    title.dispose();
    note.dispose();
    tags.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final t = AssetStrings.of(context);
    final o = original!;
    errors.clear();
    banner = null;
    final newTags = [
      for (final s in tags.text.split(','))
        if (s.trim().isNotEmpty) s.trim(),
    ];
    final fields = <String, dynamic>{
      if (title.text.trim() != o.title) 'title': title.text.trim(),
      if (flavourId != o.flavour?.id) 'flavour_id': flavourId,
      if (category != o.category) 'category': category?.wire,
      if (newTags.join('|') != o.tags.join('|')) 'tags': newTags,
      if (note.text.trim() != (o.note ?? '')) 'note': note.text.trim(),
      if (hidden != o.hidden) 'hidden': hidden,
      if (ratingOpen != o.ratingOpen) 'rating_open': ratingOpen,
    };
    if (fields.isEmpty) {
      context.pop();
      return;
    }
    setState(() => busy = true);
    try {
      final n = ref.read(assetProvider(widget.assetId).notifier);
      final updated = await ref
          .read(assetsRepositoryProvider)
          .update(widget.assetId, fields, baseModified: o.modified);
      await n.refresh();
      ref.invalidate(libraryProvider);
      if (!mounted) return;
      showStudioToast(t.saved);
      updated.id; // saved
      context.pop();
    } on StudioStale catch (e) {
      try {
        _fill(
          StudioAsset.fromJson(Map<String, dynamic>.from(e.current as Map)),
        );
      } catch (_) {}
      if (mounted) setState(() => banner = t.errStale);
    } on StudioValidation catch (e) {
      if (mounted) {
        setState(() {
          if (e.field != null && e.field!.isNotEmpty) {
            errors[e.field!] = e.message;
          } else {
            banner = e.message;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => banner = assetErrorText(t, e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AssetStrings.of(context);
    final value = ref.watch(assetProvider(widget.assetId));
    final flavours = ref.watch(flavoursProvider).valueOrNull ?? const [];
    final loaded = value.valueOrNull;
    if (original == null && loaded != null) _fill(loaded);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/assets/${widget.assetId}'),
        ),
        title: Text(t.editTitle),
      ),
      body: StudioPage(
        maxWidth: StudioContentWidth.form,
        child: original == null
            ? Center(
                child: value.hasError
                    ? Text(t.errGeneric)
                    : const CircularProgressIndicator(),
              )
            : AssetPage(
                child: ListView(
                  padding: const EdgeInsets.all(StudioSpacing.gutter),
                  children: [
                    if (banner != null)
                      Container(
                        key: const ValueKey('edit-banner'),
                        margin: const EdgeInsets.only(bottom: StudioSpacing.md),
                        padding: const EdgeInsets.all(StudioSpacing.md),
                        decoration: BoxDecoration(
                          color: StudioColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(StudioRadii.md),
                        ),
                        child: Text(banner!),
                      ),
                    TextField(
                      key: const ValueKey('edit-title'),
                      controller: title,
                      decoration: InputDecoration(
                        labelText: t.fieldTitle,
                        errorText: errors['title'],
                      ),
                    ),
                    const SizedBox(height: StudioSpacing.md),
                    DropdownButtonFormField<String?>(
                      key: const ValueKey('edit-flavour'),
                      isExpanded: true,
                      initialValue: flavourId,
                      decoration: InputDecoration(
                        labelText: t.fieldFlavour,
                        errorText: errors['flavour_id'],
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(t.any)),
                        for (final f in flavours)
                          DropdownMenuItem(value: f.id, child: Text(f.name)),
                      ],
                      onChanged: (v) => setState(() => flavourId = v),
                    ),
                    const SizedBox(height: StudioSpacing.md),
                    DropdownButtonFormField<AssetCategory?>(
                      key: const ValueKey('edit-category'),
                      isExpanded: true,
                      initialValue: category,
                      decoration: InputDecoration(
                        labelText: t.fieldCategory,
                        errorText: errors['category'],
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(t.any)),
                        for (final c in AssetCategory.values)
                          if (c != AssetCategory.unknown)
                            DropdownMenuItem(
                              value: c,
                              child: Text(t.category(c)),
                            ),
                      ],
                      onChanged: (v) => setState(() => category = v),
                    ),
                    const SizedBox(height: StudioSpacing.md),
                    TextField(
                      key: const ValueKey('edit-tags'),
                      controller: tags,
                      decoration: InputDecoration(
                        labelText: t.fieldTags,
                        errorText: errors['tags'],
                      ),
                    ),
                    const SizedBox(height: StudioSpacing.md),
                    TextField(
                      key: const ValueKey('edit-note'),
                      controller: note,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: t.fieldNote,
                        errorText: errors['note'],
                      ),
                    ),
                    SwitchListTile(
                      key: const ValueKey('edit-rating-open'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.openForRating),
                      value: ratingOpen,
                      onChanged: (v) => setState(() => ratingOpen = v),
                    ),
                    SwitchListTile(
                      key: const ValueKey('edit-hidden'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.hideFromLibrary),
                      value: hidden,
                      onChanged: (v) => setState(() => hidden = v),
                    ),
                    const SizedBox(height: StudioSpacing.md),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        key: const ValueKey('edit-save'),
                        onPressed: busy ? null : save,
                        child: Text(t.saveButton),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
