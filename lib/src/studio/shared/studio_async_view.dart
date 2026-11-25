import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/studio_strings.dart';
import '../core/theme/studio_tokens.dart';
import '../data/studio_error.dart';

/// What an empty screen says: what the screen is for, what to do first, and an
/// optional action.
class StudioEmptyConfig {
  const StudioEmptyConfig({
    required this.purpose,
    required this.firstStep,
    this.icon = Icons.auto_awesome_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String purpose;
  final String firstStep;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
}

/// One widget for the four states of any async screen: loading skeleton,
/// empty state, error with retry, and the data itself.
class StudioAsyncView<T> extends StatelessWidget {
  const StudioAsyncView({
    super.key,
    required this.value,
    required this.builder,
    required this.empty,
    this.isEmpty,
    this.onRetry,
    this.emptyOnNotFound = false,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final StudioEmptyConfig empty;

  /// Decides when loaded data counts as empty. Defaults to null, empty
  /// iterables and empty maps.
  final bool Function(T data)? isEmpty;
  final VoidCallback? onRetry;

  /// For reads where NOT_FOUND means "nothing there yet" (a week with no
  /// scorecard): show the empty state instead of the error.
  final bool emptyOnNotFound;

  bool _empty(T data) {
    if (isEmpty != null) return isEmpty!(data);
    if (data == null) return true;
    if (data is Iterable) return data.isEmpty;
    if (data is Map) return data.isEmpty;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const StudioSkeleton(),
      error: (error, _) => emptyOnNotFound && error is StudioNotFound
          ? StudioEmptyState(config: empty)
          : StudioErrorState(onRetry: onRetry),
      data: (data) => _empty(data)
          ? StudioEmptyState(config: empty)
          : builder(context, data),
    );
  }
}

class StudioEmptyState extends StatelessWidget {
  const StudioEmptyState({super.key, required this.config});

  final StudioEmptyConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(StudioSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: StudioColors.blushPale,
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: StudioColors.berryPink),
              ),
              const SizedBox(height: StudioSpacing.lg),
              Text(
                config.purpose,
                key: const ValueKey('empty-purpose'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: StudioSpacing.md),
              Text(
                config.firstStep,
                key: const ValueKey('empty-first-step'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              if (config.actionLabel != null && config.onAction != null) ...[
                const SizedBox(height: StudioSpacing.lg),
                FilledButton(
                  onPressed: config.onAction,
                  child: Text(config.actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StudioErrorState extends StatelessWidget {
  const StudioErrorState({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = StudioStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: StudioColors.danger),
            const SizedBox(height: StudioSpacing.md),
            Text(
              t.errorGeneric,
              key: const ValueKey('error-text'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: StudioSpacing.lg),
              FilledButton(onPressed: onRetry, child: Text(t.retry)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Static placeholder bars while data loads. No animation, so tests settle.
class StudioSkeleton extends StatelessWidget {
  const StudioSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = StudioStrings.of(context);
    return Semantics(
      label: t.loading,
      child: ListView(
        key: const ValueKey('skeleton'),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(StudioSpacing.gutter),
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: StudioSpacing.md),
              child: Container(
                height: i == 0 ? 28 : 72,
                width: i == 0 ? 160 : double.infinity,
                decoration: BoxDecoration(
                  color: StudioColors.blushPale,
                  borderRadius: BorderRadius.circular(StudioRadii.md),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
