import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/materials_repository.dart';
import '../../data/models/material_share_preview.dart';
import '../widgets/zoomable_sheet_page.dart';

/// Opens [ClientPreviewScreen] over the send sheet. Resolves to true when the
/// rep pressed Send there, so the sheet runs its own send with the same
/// inputs; false/null means "back to edit".
Future<bool> showClientPreview(
  BuildContext context, {
  required String referenceDoctype,
  required String referenceName,
  required List<String> materials,
  String? contactName,
  String? message,
}) async {
  final send = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => ClientPreviewScreen(
        referenceDoctype: referenceDoctype,
        referenceName: referenceName,
        materials: materials,
        contactName: contactName,
        message: message,
      ),
    ),
  );
  return send ?? false;
}

/// "See what the client gets": the WhatsApp message as it will arrive, and
/// below it a replica of the client's page — greeting, then every ticked
/// material's pages. Nothing is minted and no view is counted; the link in
/// the message is a stand-in until Send.
class ClientPreviewScreen extends ConsumerStatefulWidget {
  const ClientPreviewScreen({
    super.key,
    required this.referenceDoctype,
    required this.referenceName,
    required this.materials,
    this.contactName,
    this.message,
  });

  final String referenceDoctype;
  final String referenceName;
  final List<String> materials;
  final String? contactName;
  final String? message;

  @override
  ConsumerState<ClientPreviewScreen> createState() =>
      _ClientPreviewScreenState();
}

class _ClientPreviewScreenState extends ConsumerState<ClientPreviewScreen> {
  late Future<MaterialSharePreview> _future = _load();

  /// While a page is zoomed the list must not steal its pans.
  bool _zoomed = false;

  Future<MaterialSharePreview> _load() =>
      ref.read(materialsRepositoryProvider).previewMaterialShare(
            referenceDoctype: widget.referenceDoctype,
            referenceName: widget.referenceName,
            materials: widget.materials,
            contactName: widget.contactName,
            message: widget.message,
          );

  void _retry() => setState(() => _future = _load());

  void _onZoomChanged(bool zoomed) {
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clientPreviewTitle),
        actions: [
          IconButton(
            tooltip: l10n.materialsRetry,
            icon: const Icon(Icons.refresh),
            onPressed: _retry,
          ),
        ],
      ),
      body: FutureBuilder<MaterialSharePreview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.userErrorMessage(snapshot.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _retry,
                      child: Text(l10n.materialsRetry),
                    ),
                  ],
                ),
              ),
            );
          }
          return _body(context, snapshot.data!);
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('client-preview-back'),
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.clientPreviewBackToEdit),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('client-preview-send'),
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.send),
                  label: Text(l10n.clientPreviewSend),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, MaterialSharePreview preview) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final greeting = preview.greetingName?.trim() ?? '';

    return ListView(
      physics: _zoomed
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _SectionLabel(text: l10n.clientPreviewMessageLabel),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _MessageBubble(
            message: preview.message,
            placeholderUrl: preview.linkPlaceholderUrl,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.clientPreviewLinkCaption,
                  key: const ValueKey('client-preview-link-caption'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        _SectionLabel(text: l10n.clientPreviewPageLabel),
        if (greeting.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              l10n.clientPreviewGreeting(greeting),
              key: const ValueKey('client-preview-greeting'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (preview.items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.clientPreviewNoItems),
          ),
        for (final (index, item) in preview.items.indexed)
          _ItemSection(
            key: ValueKey('client-preview-item-$index'),
            item: item,
            onZoomChanged: _onZoomChanged,
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The message as an outgoing WhatsApp bubble, with the stand-in link set
/// apart so nobody mistakes it for the real one.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.placeholderUrl});

  final String message;
  final String placeholderUrl;

  // WhatsApp's outgoing-bubble green and its link blue.
  static const _bubble = Color(0xFFDCF8C6);
  static const _link = Color(0xFF027EB5);

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.black87,
      height: 1.4,
    );
    final linkStyle = base?.copyWith(
      color: _link,
      decoration: TextDecoration.underline,
      fontStyle: FontStyle.italic,
    );

    final spans = <TextSpan>[];
    final token = placeholderUrl.trim();
    if (token.isEmpty || !message.contains(token)) {
      spans.add(TextSpan(text: message));
    } else {
      final parts = message.split(token);
      for (var i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i]));
        if (i < parts.length - 1) {
          spans.add(TextSpan(text: token, style: linkStyle));
        }
      }
    }

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        key: const ValueKey('client-preview-message'),
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: _bubble,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        // Same direction as the editor the rep typed it in.
        child: Text.rich(
          TextSpan(style: base, children: spans),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}

/// One material on the client's page: its title, then its pages; a file with
/// no pages is a download card, as the page shows it.
class _ItemSection extends StatelessWidget {
  const _ItemSection({
    super.key,
    required this.item,
    required this.onZoomChanged,
  });

  final PublicShareItem item;
  final ValueChanged<bool> onZoomChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.title.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                item.title.trim(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (item.isDownloadOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(
                    item.title.trim().isEmpty ? item.type : item.title.trim(),
                  ),
                  subtitle: Text(l10n.clientPreviewDownloadOnly),
                  trailing: const Icon(Icons.download),
                ),
              ),
            )
          else
            for (final page in item.pages)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                // A bounded box per page: the zoom widget needs one, and a
                // list gives none.
                child: AspectRatio(
                  aspectRatio: page.aspectRatio,
                  child: ZoomableSheetPage(
                    page: page,
                    panWhenFitted: false,
                    onZoomChanged: onZoomChanged,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
