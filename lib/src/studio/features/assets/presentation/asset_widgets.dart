import 'package:flutter/material.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/studio_error.dart';
import '../assets_strings.dart';

/// The plain sentence for a failed Library action.
String assetErrorText(AssetStrings t, Object e) => switch (e) {
  StudioShadowMode() => t.errShadow,
  StudioStale() => t.errStale,
  StudioNotPermitted() => t.errNotPermitted,
  StudioNetworkError() => t.errNetwork,
  StudioNotFound() => t.errNotFound,
  StudioValidation(:final message) when message.isNotEmpty => message,
  _ => t.errGeneric,
};

/// Customer content: where its consent stands, as a small pill.
class ConsentPill extends StatelessWidget {
  const ConsentPill({super.key, required this.consent});
  final Consent consent;

  @override
  Widget build(BuildContext context) {
    final t = AssetStrings.of(context);
    final (bg, fg) = switch (consent.status) {
      ConsentStatus.given => (const Color(0xFFE3F3EB), StudioColors.success),
      ConsentStatus.refused => (const Color(0xFFF8E3E0), StudioColors.danger),
      ConsentStatus.asked => (const Color(0xFFFBEFD9), StudioColors.warning),
      _ => (StudioColors.blushPale, StudioColors.plumMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StudioSpacing.sm,
        vertical: StudioSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(StudioRadii.pill),
      ),
      child: Text(
        t.consentStatus(consent.status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

/// A centred column no wider than [maxWidth], for desktop widths.
class AssetPage extends StatelessWidget {
  const AssetPage({super.key, required this.child, this.maxWidth = 720});
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

String formatBytes(int n) {
  if (n >= 1024 * 1024 * 1024) {
    return '${(n / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  if (n >= 1024 * 1024) return '${(n / (1024 * 1024)).toStringAsFixed(1)} MB';
  if (n >= 1024) return '${(n / 1024).toStringAsFixed(0)} KB';
  return '$n B';
}
