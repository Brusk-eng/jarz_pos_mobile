import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/studio_toast.dart';
import '../data/tiktok_repository.dart';
import '../tiktok_strings.dart';

/// The TikTok card at the top of Settings (founder only): the connection
/// status, the account name once connected, Connect and Disconnect.
///
/// The connect flow runs in the browser (TikTok asks the founder to allow the
/// app and sends the browser back to the server), so the card re-reads the
/// status when the app comes back to the front.
class TikTokCard extends ConsumerStatefulWidget {
  const TikTokCard({super.key});

  @override
  ConsumerState<TikTokCard> createState() => _TikTokCardState();
}

class _TikTokCardState extends ConsumerState<TikTokCard>
    with WidgetsBindingObserver {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(tiktokStatusProvider);
    }
  }

  Future<void> _connect(TikTokStrings t) async {
    setState(() => _busy = true);
    try {
      final url = await ref.read(tiktokRepositoryProvider).connectUrl();
      final opened = await ref.read(studioLinkOpenerProvider)(Uri.parse(url));
      if (!opened) showStudioToast(t.connectFailed);
    } catch (_) {
      showStudioToast(t.connectFailed, duration: studioErrorToastDuration);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect(TikTokStrings t) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('tiktok-disconnect-dialog'),
        title: Text(t.disconnectTitle),
        content: Text(t.disconnectBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            key: const ValueKey('tiktok-disconnect-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.disconnect),
          ),
        ],
      ),
    );
    if (sure != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(tiktokRepositoryProvider).disconnect();
      ref.invalidate(tiktokStatusProvider);
      showStudioToast(t.disconnected);
    } catch (_) {
      showStudioToast(t.loadFailed, duration: studioErrorToastDuration);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = TikTokStrings.of(context);
    final status = ref.watch(tiktokStatusProvider);
    final text = Theme.of(context).textTheme;

    Widget body;
    if (status.isLoading && !status.hasValue) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: StudioSpacing.md),
        child: LinearProgressIndicator(key: ValueKey('tiktok-loading')),
      );
    } else if (status.hasError && !status.hasValue) {
      body = Text(
        t.loadFailed,
        key: const ValueKey('tiktok-error'),
        style: text.bodyMedium?.copyWith(color: StudioColors.danger),
      );
    } else {
      final s = status.requireValue;
      final line = !s.connected
          ? t.notConnected
          : (s.accountName == null
                ? t.connectedNoName
                : t.connectedAs(s.accountName!));
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                s.connected ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: s.connected
                    ? StudioColors.success
                    : StudioColors.plumMuted,
              ),
              const SizedBox(width: StudioSpacing.sm),
              Expanded(
                child: Text(
                  line,
                  key: const ValueKey('tiktok-status'),
                  style: text.titleSmall,
                ),
              ),
            ],
          ),
          if (s.connected && s.expiresAt != null)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.xs),
              child: Text(
                t.validUntil(_date(s.refreshExpiresAt ?? s.expiresAt!)),
                key: const ValueKey('tiktok-expiry'),
                style: text.bodySmall,
              ),
            ),
          if (!s.configured)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.sm),
              child: Text(
                t.notConfigured,
                key: const ValueKey('tiktok-not-configured'),
                style: text.bodySmall,
              ),
            ),
          if (s.error != null)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.sm),
              child: Text(
                t.lastProblem(s.error!),
                key: const ValueKey('tiktok-last-problem'),
                style: text.bodySmall?.copyWith(color: StudioColors.danger),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: StudioSpacing.sm),
            child: Text(t.shadowNote, style: text.bodySmall),
          ),
          const SizedBox(height: StudioSpacing.md),
          Wrap(
            spacing: StudioSpacing.sm,
            runSpacing: StudioSpacing.sm,
            children: [
              if (!s.connected)
                FilledButton(
                  key: const ValueKey('tiktok-connect'),
                  onPressed: (_busy || !s.configured)
                      ? null
                      : () => _connect(t),
                  child: Text(t.connect),
                )
              else
                OutlinedButton(
                  key: const ValueKey('tiktok-disconnect'),
                  onPressed: _busy ? null : () => _disconnect(t),
                  child: Text(t.disconnect),
                ),
              TextButton(
                key: const ValueKey('tiktok-refresh'),
                onPressed: () => ref.invalidate(tiktokStatusProvider),
                child: Text(t.refresh),
              ),
            ],
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StudioSpacing.gutter,
        StudioSpacing.sm,
        StudioSpacing.gutter,
        StudioSpacing.sm,
      ),
      child: Card(
        key: const ValueKey('tiktok-card'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(StudioSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.title, style: text.titleMedium),
              const SizedBox(height: StudioSpacing.sm),
              body,
            ],
          ),
        ),
      ),
    );
  }
}
