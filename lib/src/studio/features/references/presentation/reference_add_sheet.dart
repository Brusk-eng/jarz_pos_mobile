import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/api/studio_api_base.dart';
import '../../../data/models/studio_enums.dart';
import '../../../shared/studio_error_text.dart';
import '../data/references_repository.dart';
import '../references_strings.dart';
import '../state/references_state.dart';
import '../../../shared/studio_toast.dart';

/// "Add a reference" (`references.create`): a link, where it was seen, the
/// format, who made it and a note. Link only: the contract's create takes an
/// uploaded media id for a picture, and the upload flow belongs to the
/// library screens, so a picture is not offered here.
class AddReferenceSheet extends ConsumerStatefulWidget {
  const AddReferenceSheet({super.key});

  static Future<bool?> show(BuildContext context) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => const AddReferenceSheet(),
  );

  @override
  ConsumerState<AddReferenceSheet> createState() => _AddReferenceState();
}

class _AddReferenceState extends ConsumerState<AddReferenceSheet> {
  final _title = TextEditingController();
  final _url = TextEditingController();
  final _brand = TextEditingController();
  final _why = TextEditingController();
  RefSrcType? _src;
  RefMedia? _media;
  String? _titleError;
  String? _error;
  bool _busy = false;
  final _requestId = newRequestId();

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _brand.dispose();
    _why.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final a = AddReferenceStrings.of(context);
    if (_title.text.trim().isEmpty) {
      setState(() => _titleError = a.titleNeeded);
      return;
    }
    final nav = Navigator.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() {
      _busy = true;
      _error = null;
      _titleError = null;
    });
    String? opt(TextEditingController c) {
      final v = c.text.trim();
      return v.isEmpty ? null : v;
    }

    try {
      await ref
          .read(referencesRepositoryProvider)
          .create(
            title: _title.text.trim(),
            url: opt(_url),
            brand: opt(_brand),
            why: opt(_why),
            srcType: _src?.wire,
            mediaType: _media?.wire,
            requestId: _requestId,
          );
      ref.invalidate(referenceGridProvider);
      showStudioToast(a.added);
      nav.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = studioErrorMessage(e, ar: isAr);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = AddReferenceStrings.of(context);
    final t = ReferencesStrings.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.gutter,
            0,
            StudioSpacing.gutter,
            StudioSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: StudioSpacing.md),
              TextField(
                key: const ValueKey('ref-add-title'),
                controller: _title,
                decoration: InputDecoration(
                  labelText: a.titleLabel,
                  errorText: _titleError,
                ),
              ),
              const SizedBox(height: StudioSpacing.sm),
              TextField(
                key: const ValueKey('ref-add-url'),
                controller: _url,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: a.linkLabel),
              ),
              const SizedBox(height: StudioSpacing.sm),
              TextField(
                key: const ValueKey('ref-add-brand'),
                controller: _brand,
                decoration: InputDecoration(labelText: a.brandLabel),
              ),
              const SizedBox(height: StudioSpacing.md),
              Text(t.source, style: theme.textTheme.labelLarge),
              Wrap(
                spacing: StudioSpacing.sm,
                children: [
                  for (final s in const [
                    RefSrcType.metaAd,
                    RefSrcType.tiktokAd,
                    RefSrcType.igPost,
                    RefSrcType.igReel,
                  ])
                    ChoiceChip(
                      key: ValueKey('ref-add-src-${s.wire}'),
                      label: Text(t.sourceLabel(s)),
                      selected: _src == s,
                      onSelected: (v) => setState(() => _src = v ? s : null),
                    ),
                ],
              ),
              const SizedBox(height: StudioSpacing.sm),
              Text(t.format, style: theme.textTheme.labelLarge),
              Wrap(
                spacing: StudioSpacing.sm,
                children: [
                  for (final m in const [
                    RefMedia.reel,
                    RefMedia.staticValue,
                    RefMedia.carousel,
                  ])
                    ChoiceChip(
                      key: ValueKey('ref-add-media-${m.wire}'),
                      label: Text(t.formatLabel(m)),
                      selected: _media == m,
                      onSelected: (v) => setState(() => _media = v ? m : null),
                    ),
                ],
              ),
              const SizedBox(height: StudioSpacing.sm),
              TextField(
                key: const ValueKey('ref-add-why'),
                controller: _why,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: a.noteLabel),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: StudioSpacing.sm),
                  child: Text(
                    _error!,
                    key: const ValueKey('ref-add-error'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: StudioColors.danger,
                    ),
                  ),
                ),
              const SizedBox(height: StudioSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('ref-add-save'),
                  onPressed: _busy ? null : _save,
                  child: Text(a.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The few words of the form (English and Arabic side by side).
class AddReferenceStrings {
  const AddReferenceStrings._(this.ar);
  final bool ar;

  static AddReferenceStrings of(BuildContext context) => AddReferenceStrings._(
    Localizations.localeOf(context).languageCode == 'ar',
  );

  String tr(String en, String arabic) => ar ? arabic : en;

  String get tooltip => tr('Add a reference', 'ضيف مرجع');
  String get title => tr('Add a reference', 'ضيف مرجع');
  String get titleLabel => tr('Title', 'العنوان');
  String get titleNeeded => tr('Give it a title.', 'اكتب عنوان.');
  String get linkLabel => tr('Link', 'اللينك');
  String get brandLabel => tr('Who made it', 'مين عامله');
  String get noteLabel =>
      tr('Why it is worth learning from', 'ليه يستاهل نتعلم منه');
  String get save => tr('Add', 'ضيف');
  String get added => tr('Reference added.', 'المرجع اتضاف.');
}
