import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/reachability.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/studio_error.dart';
import '../shoots_strings.dart';
import '../state/on_set_state.dart';

/// The plain sentence for a failed shoot action.
String shootErrorText(ShootStrings t, Object e) => switch (e) {
  StudioShadowMode() => t.errShadow,
  StudioStale() => t.errStale,
  StudioNotPermitted() => t.errNotPermitted,
  StudioNetworkError() => t.errNetwork,
  StudioNotFound() => t.errNotFound,
  StudioValidation(:final message) when message.isNotEmpty => message,
  _ => t.errGeneric,
};

/// Says whether the phone is connected and what is waiting to be sent:
/// "No connection", "3 changes waiting to send", "All sent". Draws nothing
/// when there is nothing to say.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ShootStrings.of(context);
    final online = ref.watch(studioReachabilityProvider);
    final s = ref.watch(onSetProvider);
    final pending = s.pending;

    String? text;
    var color = StudioColors.warning;
    IconData icon = Icons.cloud_off_outlined;
    VoidCallback? send;
    if (s.blockedMessage != null && pending > 0) {
      text = '${s.blockedMessage}  ${t.waitingToSend(pending)}';
      color = StudioColors.danger;
      icon = Icons.error_outline;
    } else if (!online) {
      text = pending > 0
          ? '${t.offlineBanner}  ${t.waitingToSend(pending)}'
          : t.offlineBanner;
    } else if (pending > 0) {
      text = s.sending ? t.sendingNow : t.waitingToSend(pending);
      icon = Icons.cloud_upload_outlined;
      if (!s.sending) {
        send = () => ref.read(onSetProvider.notifier).flush();
      }
    } else if (s.everSent) {
      text = t.allSent;
      color = StudioColors.success;
      icon = Icons.cloud_done_outlined;
    }
    if (text == null) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('sync-banner'),
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(
        horizontal: StudioSpacing.gutter,
        vertical: StudioSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: StudioSpacing.sm),
          Expanded(
            child: Text(
              text,
              key: const ValueKey('sync-text'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (send != null)
            TextButton(
              key: const ValueKey('sync-send'),
              onPressed: send,
              child: Text(t.sendNow),
            ),
        ],
      ),
    );
  }
}

/// A shoot's status as a small pill.
class ShootStatusPill extends StatelessWidget {
  const ShootStatusPill({super.key, required this.status});
  final ShootStatus status;

  @override
  Widget build(BuildContext context) {
    final t = ShootStrings.of(context);
    final (bg, fg) = switch (status) {
      ShootStatus.ready => (const Color(0xFFE3F3EB), StudioColors.success),
      ShootStatus.prep => (const Color(0xFFFBEFD9), StudioColors.warning),
      ShootStatus.shot => (StudioColors.softBlush, StudioColors.deepPlum),
      ShootStatus.done => (const Color(0xFFE8E6EE), StudioColors.deepPlum),
      _ => (StudioColors.blushPale, StudioColors.plumMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StudioSpacing.md,
        vertical: StudioSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(StudioRadii.pill),
      ),
      child: Text(
        t.status(status),
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}

/// A centred column no wider than [maxWidth], for desktop widths.
class ShootPage extends StatelessWidget {
  const ShootPage({super.key, required this.child, this.maxWidth = 720});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
