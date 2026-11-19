import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/followup_whatsapp.dart';
import '../../data/followups_repository.dart';
import '../../data/models/followup_models.dart';
import '../../state/followups_providers.dart';

/// Opens the "Brief before call" bottom sheet for [row]. [onCall] and
/// [onWhatsapp] reuse the card's own handlers.
Future<void> showCallBriefSheet(
  BuildContext context, {
  required FollowupRow row,
  required VoidCallback onCall,
  required VoidCallback onWhatsapp,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => CallBriefSheet(
      row: row,
      onCall: onCall,
      onWhatsapp: onWhatsapp,
    ),
  );
}

class CallBriefSheet extends ConsumerStatefulWidget {
  const CallBriefSheet({
    super.key,
    required this.row,
    required this.onCall,
    required this.onWhatsapp,
  });

  final FollowupRow row;
  final VoidCallback onCall;
  final VoidCallback onWhatsapp;

  @override
  ConsumerState<CallBriefSheet> createState() => _CallBriefSheetState();
}

class _CallBriefSheetState extends ConsumerState<CallBriefSheet> {
  late String _brief = widget.row.aiBrief;
  bool _loading = false;
  Object? _error;
  bool _fromClaude = false;

  @override
  void initState() {
    super.initState();
    _fromClaude = _brief.trim().isNotEmpty;
    if (_brief.trim().isEmpty) _load(refresh: false);
  }

  Future<void> _load({required bool refresh}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // Capture before the await; the sheet may be closed while Claude thinks.
    final notifier = ref.read(followupsTodayProvider.notifier);
    final FollowupsRepository repo = ref.read(followupsRepositoryProvider);
    try {
      final result = await repo.getCallBrief(widget.row.name, refresh: refresh);
      notifier.rememberBrief(widget.row.name, result.isClaude ? result.brief : '');
      if (!mounted) return;
      setState(() {
        _brief = result.brief;
        _fromClaude = result.isClaude;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final row = widget.row;
    final hasPhone = followupTelUri(row.phone) != null;
    final hasWhatsapp = followupMsisdn(row).isNotEmpty;

    Widget body;
    if (_loading) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(l10n.followupsBriefLoading),
            ],
          ),
        ),
      );
    } else if (_error != null && _brief.trim().isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          context.userErrorMessage(_error!, fallback: l10n.followupsBriefFailed),
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    } else {
      body = SelectableText(
        _brief.trim().isEmpty ? l10n.followupsBriefEmpty : _brief.trim(),
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.followupsActionBrief} - ${row.displayName}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: l10n.followupsBriefRefresh,
                  onPressed: _loading ? null : () => _load(refresh: true),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (_fromClaude && !_loading)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l10n.followupsWrittenByClaude,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: body,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: hasPhone ? widget.onCall : null,
                    icon: const Icon(Icons.call, size: 18),
                    label: Text(l10n.followupsActionCall),
                  ),
                ),
                if (hasWhatsapp) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onWhatsapp,
                      icon: const Icon(Icons.chat, size: 18),
                      label: Text(l10n.followupsActionWhatsapp),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
