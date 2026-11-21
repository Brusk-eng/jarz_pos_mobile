import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_routes.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../../../core/localization/localized_display_mappers.dart';
import '../../data/materials_repository.dart';
import '../../data/models/sales_material.dart';
import '../../state/materials_notifier.dart';
import '../screens/client_preview_screen.dart';

/// One person the pack can go to.
///
/// A local value type rather than the leads feature's `LeadContact`: this
/// sheet is reachable from a Lead today and from an Opportunity or a Customer
/// tomorrow, and none of those should have to become an import here.
class MaterialRecipient {
  const MaterialRecipient({
    required this.name,
    this.role = '',
    this.phone = '',
  });

  final String name;
  final String role;
  final String phone;

  bool get hasPhone => phone.trim().isNotEmpty;
}

/// Opens the send sheet. Returns the minted share when one was sent.
Future<MaterialShare?> showSendMaterialsSheet(
  BuildContext context, {
  required String referenceDoctype,
  required String referenceName,
  required List<MaterialRecipient> recipients,
  MaterialRecipient? preselected,
}) {
  return showModalBottomSheet<MaterialShare>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SendMaterialsSheet(
      referenceDoctype: referenceDoctype,
      referenceName: referenceName,
      recipients: recipients,
      preselected: preselected,
    ),
  );
}

/// Pick a pack, pick a person, check the words, open WhatsApp.
///
/// The whole sheet exists to replace "attach five files to a chat one at a
/// time". What actually leaves here is a single link to a page built for
/// reading a price list on a phone — which is also the only way the rep ever
/// finds out whether the prospect opened it.
class _SendMaterialsSheet extends ConsumerStatefulWidget {
  const _SendMaterialsSheet({
    required this.referenceDoctype,
    required this.referenceName,
    required this.recipients,
    this.preselected,
  });

  final String referenceDoctype;
  final String referenceName;
  final List<MaterialRecipient> recipients;
  final MaterialRecipient? preselected;

  @override
  ConsumerState<_SendMaterialsSheet> createState() =>
      _SendMaterialsSheetState();
}

class _SendMaterialsSheetState extends ConsumerState<_SendMaterialsSheet> {
  final _message = TextEditingController();
  final Set<String> _picked = <String>{};

  MaterialRecipient? _recipient;
  MaterialLibrary? _library;

  /// True once the rep has typed in the message box. After that the sheet
  /// stops rewriting it when the recipient changes — silently discarding
  /// someone's edit because they corrected the name is worse than a stale
  /// greeting they can see and fix.
  bool _edited = false;
  bool _sending = false;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _recipient = widget.preselected ??
        (widget.recipients.isNotEmpty ? widget.recipients.first : null);
    _message.addListener(() {
      if (!_seeded) return;
      _edited = true;
    });
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  /// Fills the editor from the server's template. Runs once when the library
  /// arrives, and again on a recipient change only while untouched.
  void _seed(MaterialLibrary library) {
    _library = library;
    if (_picked.isEmpty && !_seeded) {
      final defaults =
          library.materials.where((m) => m.isDefault).map((m) => m.name);
      _picked.addAll(defaults);
      // A library with nothing flagged default would otherwise open with an
      // empty basket and a disabled send button, which reads as broken.
      if (_picked.isEmpty && library.materials.isNotEmpty) {
        _picked.add(library.materials.first.name);
      }
    }
    if (!_edited) {
      _message.text = library.previewFor(_recipient?.name);
    }
    _seeded = true;
  }

  void _chooseRecipient(MaterialRecipient? value) {
    setState(() {
      _recipient = value;
      final library = _library;
      if (library != null && !_edited) {
        _message.text = library.previewFor(value?.name);
      }
    });
  }

  /// The ticked materials ordered as the library lists them, so the price
  /// list stays first on the customer's page instead of following the tap
  /// order. Shared by send and the client preview so both see the same pack.
  List<String> _orderedPicked(MaterialLibrary library) => library.materials
      .map((m) => m.name)
      .where(_picked.contains)
      .toList();

  /// "See what the client gets" with exactly what Send would send now: the
  /// current (edited) message, the ticked materials, the chosen recipient.
  /// Send pressed there runs this sheet's own send with those same inputs.
  Future<void> _openClientPreview() async {
    final library = _library;
    if (library == null || _picked.isEmpty || _sending) return;
    final send = await showClientPreview(
      context,
      referenceDoctype: widget.referenceDoctype,
      referenceName: widget.referenceName,
      materials: _orderedPicked(library),
      contactName: _recipient?.name,
      message: _message.text,
    );
    if (send && mounted) await _send();
  }

  Future<void> _send() async {
    final library = _library;
    if (library == null || _picked.isEmpty) return;

    setState(() => _sending = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final share = await ref.read(materialsRepositoryProvider).createShare(
            referenceDoctype: widget.referenceDoctype,
            referenceName: widget.referenceName,
            materials: _orderedPicked(library),
            contactName: _recipient?.name,
            contactPhone: _recipient?.phone,
            message: _message.text,
          );

      ref.invalidate(materialSharesProvider(
        materialSharesKey(widget.referenceDoctype, widget.referenceName),
      ));

      await _openWhatsapp(share.whatsappUrl);
      if (!mounted) return;
      navigator.pop(share);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.materialsLinkReady),
          action: SnackBarAction(
            label: l10n.materialsCopyLink,
            onPressed: () => Clipboard.setData(ClipboardData(text: share.url)),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(
        SnackBar(content: Text(context.userErrorMessage(error))),
      );
    }
  }

  /// The sheet as this record would receive it: their price list, their
  /// running deal, their name on top.
  void _openPreview(SalesMaterial material) {
    context.push(
      Uri(
        path: AppRoutes.priceSheetPreview,
        queryParameters: {
          'material': material.name,
          'title': material.label,
          'doctype': widget.referenceDoctype,
          'name': widget.referenceName,
        },
      ).toString(),
    );
  }

  Future<void> _openTemplate(SalesMaterial material) async {
    await context.push(
      Uri(
        path: AppRoutes.priceSheetTemplate,
        queryParameters: {'material': material.name},
      ).toString(),
    );
  }

  /// Launch directly. Do NOT gate on `canLaunchUrl`: on Android 11+ it returns
  /// false unless every scheme is declared in the manifest `<queries>`, which
  /// silently blocks the launch. Same lesson as the leads quick actions.
  Future<void> _openWhatsapp(String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.parse(url);
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // externalApplication may be unavailable for this URI; fall through.
    }
    try {
      await launchUrl(uri);
    } catch (_) {
      // No handler; the snackbar's copy action is the way out.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final library = ref.watch(materialLibraryProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (context, controller) => library.when(
          loading: () => const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _ErrorState(
            message: context.userErrorMessage(error),
            onRetry: () => ref.invalidate(materialLibraryProvider),
          ),
          data: (value) {
            _seed(value);
            if (value.materials.isEmpty) {
              return _ErrorState(message: l10n.materialsLibraryEmpty);
            }
            return _body(context, controller, value);
          },
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    ScrollController controller,
    MaterialLibrary library,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pending = library.materials
        .where((m) => _picked.contains(m.name) && !m.ready)
        .toList();

    return Column(
      children: [
        const _Grabber(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.materialsSendTitle,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              Text(l10n.materialsRecipientLabel,
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              _RecipientPicker(
                recipients: widget.recipients,
                emptyText: widget.referenceDoctype == 'Customer'
                    ? l10n.materialsNoRecipientCustomer
                    : l10n.materialsNoRecipient,
                selected: _recipient,
                enabled: !_sending,
                onChanged: _chooseRecipient,
              ),
              const SizedBox(height: 20),
              Text(l10n.materialsPickLabel, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              for (final material in library.materials)
                _MaterialTile(
                  material: material,
                  checked: _picked.contains(material.name),
                  enabled: !_sending,
                  canEditTemplate: library.canEditSheets,
                  onPreview: () => _openPreview(material),
                  onEditTemplate: () => _openTemplate(material),
                  onChanged: (on) => setState(() {
                    if (on) {
                      _picked.add(material.name);
                    } else {
                      _picked.remove(material.name);
                    }
                  }),
                ),
              if (pending.isNotEmpty) ...[
                const SizedBox(height: 8),
                _Notice(text: l10n.materialsStillPreparing(pending.length)),
              ],
              const SizedBox(height: 20),
              Text(l10n.materialsMessageLabel,
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _message,
                enabled: !_sending,
                minLines: 5,
                maxLines: 10,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  helperMaxLines: 3,
                  helperText:
                      l10n.materialsLinkPlaceholderHint(library.linkPlaceholder),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('materials-client-preview'),
                    onPressed: (_sending || _picked.isEmpty)
                        ? null
                        : _openClientPreview,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(
                      l10n.clientPreviewButton,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('materials-send'),
                    onPressed: (_sending || _picked.isEmpty) ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _sending ? l10n.materialsSending : l10n.materialsSendCta,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecipientPicker extends StatelessWidget {
  const _RecipientPicker({
    required this.recipients,
    required this.selected,
    required this.enabled,
    required this.onChanged,
    required this.emptyText,
  });

  final List<MaterialRecipient> recipients;
  final MaterialRecipient? selected;
  final bool enabled;
  final ValueChanged<MaterialRecipient?> onChanged;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (recipients.isEmpty) {
      return _Notice(text: emptyText);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final recipient in recipients)
          ChoiceChip(
            selected: identical(recipient, selected) ||
                (selected != null &&
                    recipient.name == selected!.name &&
                    recipient.phone == selected!.phone),
            onSelected: enabled ? (_) => onChanged(recipient) : null,
            avatar: Icon(
              recipient.hasPhone ? Icons.person : Icons.person_off_outlined,
              size: 16,
            ),
            label: Text(
              recipient.role.trim().isEmpty
                  ? recipient.name
                  : '${recipient.name} · ${recipient.role.trim()}',
            ),
          ),
      ],
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({
    required this.material,
    required this.checked,
    required this.enabled,
    required this.onChanged,
    this.canEditTemplate = false,
    this.onPreview,
    this.onEditTemplate,
  });

  final SalesMaterial material;
  final bool checked;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  /// Only consulted for a generated sheet.
  final bool canEditTemplate;
  final VoidCallback? onPreview;
  final VoidCallback? onEditTemplate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bits = <String>[
      if (material.materialType.trim().isNotEmpty)
        localizedMaterialType(context, material.materialType),
      if (material.pageCount > 1) l10n.materialsPageCount(material.pageCount),
      if (!material.ready) l10n.materialsPreparing,
    ];
    final generated = material.isGenerated;
    final theme = Theme.of(context);
    Widget? subtitle = bits.isEmpty ? null : Text(bits.join(' · '));
    if (generated) {
      // A generated sheet has no file to describe: its prices are filled in
      // for whoever it is sent to, so it offers a look at exactly that.
      subtitle = Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (bits.isNotEmpty) Text(bits.join(' · ')),
          Container(
            key: ValueKey('materials-auto-prices-${material.name}'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              l10n.materialsAutoPricesChip,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton.icon(
            key: ValueKey('materials-preview-${material.name}'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: onPreview,
            icon: const Icon(Icons.visibility, size: 16),
            label: Text(l10n.materialsPreview),
          ),
          if (canEditTemplate)
            TextButton.icon(
              key: ValueKey('materials-edit-template-${material.name}'),
              style:
                  TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: onEditTemplate,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(l10n.materialsEditTemplate),
            ),
        ],
      );
    }
    return CheckboxListTile(
      value: checked,
      onChanged: enabled ? (value) => onChanged(value ?? false) : null,
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(material.label),
      subtitle: subtitle,
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Grabber(),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.materialsRetry),
            ),
          ],
        ],
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
