import '../../../shared/studio_chips.dart';
import '../../../shared/studio_pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../core/upload/file_source.dart';
import '../../../core/upload/upload_engine.dart';
import '../../../core/upload/upload_job.dart';
import '../../../core/upload/upload_strings.dart';
import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../assets_strings.dart';
import 'asset_widgets.dart';

/// Records where customer consent stands. `Given` needs who, the date, what
/// it covers and a screenshot of the message; the screenshot goes up through
/// the upload engine first.
Future<bool?> showConsentSheet(
  BuildContext context, {
  required StudioAsset asset,
  required Future<void> Function({
    required String status,
    String? who,
    String? date,
    String? scope,
    String? proofMediaId,
    required String requestId,
  })
  save,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ConsentSheet(asset: asset, save: save),
  );
}

class _ConsentSheet extends ConsumerStatefulWidget {
  const _ConsentSheet({required this.asset, required this.save});
  final StudioAsset asset;
  final Future<void> Function({
    required String status,
    String? who,
    String? date,
    String? scope,
    String? proofMediaId,
    required String requestId,
  })
  save;

  @override
  ConsumerState<_ConsentSheet> createState() => _ConsentSheetState();
}

class _ConsentSheetState extends ConsumerState<_ConsentSheet> {
  late ConsentStatus status =
      widget.asset.consent?.status ?? ConsentStatus.asked;
  late final who = TextEditingController(text: widget.asset.consent?.who);
  late String? date = widget.asset.consent?.date;
  late ConsentScope? scope = widget.asset.consent?.scope;
  late String? proofMediaId = widget.asset.consent?.proof?.id;
  String? proofName;
  String? proofJobId;
  var proofState = _Proof.none;
  final errors = <String, String>{};
  String? banner;
  var busy = false;
  final _requestId = newRequestId();

  @override
  void initState() {
    super.initState();
    if (proofMediaId != null) proofState = _Proof.done;
  }

  @override
  void dispose() {
    who.dispose();
    super.dispose();
  }

  Future<void> pickProof() async {
    final t = AssetStrings.of(context);
    final files = await ref
        .read(studioFileSourceProvider)
        .pickMedia(multiple: false);
    if (files.isEmpty || !mounted) return;
    final engine = ref.read(studioUploadEngineProvider.notifier);
    final r = await engine.enqueue(files.first, purpose: 'consent_proof');
    if (!mounted) return;
    if (!r.ok) {
      // The same screenshot may already be stored: treat as a plain refusal.
      setState(() {
        proofState = _Proof.failed;
        banner = UploadStrings.of(
          context,
        ).rejection(r.rejection!, files.first.name);
      });
      return;
    }
    setState(() {
      proofState = _Proof.uploading;
      proofName = files.first.name;
      proofJobId = r.job!.id;
      errors.remove('proof_media_id');
    });
    final job = await engine.whenSettled(r.job!.id);
    if (!mounted) return;
    setState(() {
      if (job.status == UploadStatus.done && job.media != null) {
        proofMediaId = job.media!.id;
        proofState = _Proof.done;
        banner = null;
      } else {
        proofState = _Proof.failed;
        banner = t.consentProofFailed;
      }
    });
  }

  Future<void> submit() async {
    final t = AssetStrings.of(context);
    errors.clear();
    banner = null;
    if (status == ConsentStatus.given) {
      final miss = AssetStrings.of(context).isArabic ? 'مطلوب' : 'Needed';
      if (who.text.trim().isEmpty) errors['who'] = miss;
      if (date == null) errors['date'] = miss;
      if (scope == null) errors['scope'] = miss;
      if (proofMediaId == null) errors['proof_media_id'] = miss;
      if (errors.isNotEmpty) {
        setState(() {});
        return;
      }
    }
    setState(() => busy = true);
    try {
      await widget.save(
        status: status.wire,
        who: who.text.trim().isEmpty ? null : who.text.trim(),
        date: date,
        scope: scope?.wire,
        proofMediaId: proofMediaId,
        requestId: _requestId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on StudioValidation catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          if (e.field != null && e.field!.isNotEmpty) {
            errors[e.field!] = e.message;
          } else {
            banner = e.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          banner = assetErrorText(t, e);
        });
      }
    }
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final d = await showStudioDatePicker(
      context: context,
      initialDate: date == null ? now : (DateTime.tryParse(date!) ?? now),
      firstDate: DateTime(now.year - 2),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (d != null) {
      setState(() {
        date =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        errors.remove('date');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AssetStrings.of(context);
    final theme = Theme.of(context);
    final given = status == ConsentStatus.given;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        StudioSpacing.gutter,
        0,
        StudioSpacing.gutter,
        MediaQuery.of(context).viewInsets.bottom + StudioSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.consentSheetTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: StudioSpacing.md),
            Text(t.consentStatusLabel, style: theme.textTheme.labelMedium),
            Wrap(
              spacing: StudioSpacing.sm,
              children: [
                for (final s in ConsentStatus.values)
                  if (s != ConsentStatus.unknown)
                    StudioChoiceChip(
                      key: ValueKey('consent-${s.wire}'),
                      label: Text(t.consentStatus(s)),
                      selected: status == s,
                      onSelected: (_) => setState(() => status = s),
                    ),
              ],
            ),
            if (given) ...[
              const SizedBox(height: StudioSpacing.md),
              Text(t.consentGivenNeeds, style: theme.textTheme.bodySmall),
              const SizedBox(height: StudioSpacing.md),
              TextField(
                key: const ValueKey('consent-who'),
                controller: who,
                decoration: InputDecoration(
                  labelText: t.consentWho,
                  hintText: t.consentWhoHint,
                  errorText: errors['who'],
                ),
              ),
              const SizedBox(height: StudioSpacing.md),
              InkWell(
                key: const ValueKey('consent-date'),
                onTap: pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: t.consentDate,
                    errorText: errors['date'],
                  ),
                  child: Text(date == null ? t.consentPickDate : t.date(date)),
                ),
              ),
              const SizedBox(height: StudioSpacing.md),
              Text(t.consentScope, style: theme.textTheme.labelMedium),
              Wrap(
                spacing: StudioSpacing.sm,
                children: [
                  for (final s in ConsentScope.values)
                    if (s != ConsentScope.unknown)
                      StudioChoiceChip(
                        key: ValueKey('scope-${s.wire}'),
                        label: Text(t.scope(s)),
                        selected: scope == s,
                        onSelected: (_) => setState(() {
                          scope = s;
                          errors.remove('scope');
                        }),
                      ),
                ],
              ),
              if (errors['scope'] != null)
                Text(
                  errors['scope']!,
                  style: const TextStyle(
                    color: StudioColors.danger,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: StudioSpacing.md),
              OutlinedButton.icon(
                key: const ValueKey('consent-proof'),
                onPressed: proofState == _Proof.uploading ? null : pickProof,
                icon: Icon(
                  proofState == _Proof.done
                      ? Icons.check_circle_outline
                      : Icons.attach_file,
                ),
                label: Text(switch (proofState) {
                  _Proof.done => t.consentProofAttached,
                  _Proof.uploading => t.consentProofUploading,
                  _ => t.consentAttachProof,
                }),
              ),
              if (errors['proof_media_id'] != null)
                Text(
                  errors['proof_media_id']!,
                  style: const TextStyle(
                    color: StudioColors.danger,
                    fontSize: 12,
                  ),
                ),
            ],
            if (banner != null)
              Padding(
                padding: const EdgeInsets.only(top: StudioSpacing.md),
                child: Text(
                  banner!,
                  key: const ValueKey('consent-banner'),
                  style: const TextStyle(color: StudioColors.danger),
                ),
              ),
            const SizedBox(height: StudioSpacing.lg),
            FilledButton(
              key: const ValueKey('consent-save'),
              onPressed: busy || proofState == _Proof.uploading ? null : submit,
              child: Text(t.consentSave),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Proof { none, uploading, done, failed }

/// Mark raw material used, skipped (story lead) or retired.
Future<bool?> showMarkUsedSheet(
  BuildContext context, {
  required Future<void> Function({
    required String status,
    String? note,
    required String requestId,
  })
  save,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _UsedSheet(save: save),
  );
}

class _UsedSheet extends StatefulWidget {
  const _UsedSheet({required this.save});
  final Future<void> Function({
    required String status,
    String? note,
    required String requestId,
  })
  save;

  @override
  State<_UsedSheet> createState() => _UsedSheetState();
}

class _UsedSheetState extends State<_UsedSheet> {
  var status = AssetStatus.used;
  final note = TextEditingController();
  String? error;
  var busy = false;
  final _requestId = newRequestId();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final t = AssetStrings.of(context);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.save(
        status: status.wire,
        note: note.text.trim().isEmpty ? null : note.text.trim(),
        requestId: _requestId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = assetErrorText(t, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AssetStrings.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        StudioSpacing.gutter,
        0,
        StudioSpacing.gutter,
        MediaQuery.of(context).viewInsets.bottom + StudioSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.usedSheetTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: StudioSpacing.md),
          Wrap(
            spacing: StudioSpacing.sm,
            children: [
              for (final s in AssetStatus.values)
                if (s != AssetStatus.unknown)
                  StudioChoiceChip(
                    key: ValueKey('used-${s.wire}'),
                    label: Text(t.status(s)),
                    selected: status == s,
                    onSelected: (_) => setState(() => status = s),
                  ),
            ],
          ),
          const SizedBox(height: StudioSpacing.md),
          TextField(
            key: const ValueKey('used-note'),
            controller: note,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(hintText: t.usedNoteHint),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.sm),
              child: Text(
                error!,
                key: const ValueKey('used-error'),
                style: const TextStyle(color: StudioColors.danger),
              ),
            ),
          const SizedBox(height: StudioSpacing.lg),
          FilledButton(
            key: const ValueKey('used-save'),
            onPressed: busy ? null : submit,
            child: Text(t.saveButton),
          ),
        ],
      ),
    );
  }
}
