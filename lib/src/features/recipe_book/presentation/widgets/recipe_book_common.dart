import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/recipe_book_models.dart';
import '../recipe_book_strings.dart';

/// Content width on a tablet or the web: a recipe reads like a page, not a
/// spreadsheet.
const double kRecipeBookMaxWidth = 720;

/// Centres [child] and caps its width at [kRecipeBookMaxWidth].
class RecipeBookWidth extends StatelessWidget {
  const RecipeBookWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: kRecipeBookMaxWidth),
      child: child,
    ),
  );
}

/// Pill colours by status: approved green, trial amber, retired grey.
({Color background, Color foreground}) recipeStatusColors(
  BuildContext context,
  String status,
) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (status) {
    RecipeStatus.trial || VersionStatus.trial => (
      background: dark ? const Color(0xFF4A3A10) : const Color(0xFFFFF3D6),
      foreground: dark ? const Color(0xFFFFD27A) : const Color(0xFF8A5A00),
    ),
    RecipeStatus.retired => (
      background: dark ? const Color(0xFF33363A) : const Color(0xFFECEEF0),
      foreground: dark ? const Color(0xFFB8BEC4) : const Color(0xFF5F6368),
    ),
    _ => (
      background: dark ? const Color(0xFF173D24) : const Color(0xFFE3F4E8),
      foreground: dark ? const Color(0xFF8FD6A4) : const Color(0xFF1E7A3C),
    ),
  };
}

/// A small status pill: Approved / Trial / Retired.
class RecipeStatusPill extends StatelessWidget {
  const RecipeStatusPill({super.key, required this.status, this.label});

  /// A [RecipeStatus] or [VersionStatus] value.
  final String status;

  /// Overrides the text (e.g. "Current" for a version).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    // A "previous" or "current" version reads as approved.
    final colorKey = switch (status) {
      VersionStatus.current || VersionStatus.previous => RecipeStatus.approved,
      _ => status,
    };
    final colors = recipeStatusColors(context, colorKey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label ?? s.recipeStatus(colorKey),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// "27 Nov" (this year) or "27 Nov 2025"; null for a blank or odd date.
String? recipeShortDate(BuildContext context, String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final parsed = DateTime.tryParse(value.replaceFirst(' ', 'T'));
  if (parsed == null) return null;
  final locale = Localizations.localeOf(context).toLanguageTag();
  final pattern = parsed.year == DateTime.now().year ? 'd MMM' : 'd MMM yyyy';
  try {
    return DateFormat(pattern, locale).format(parsed);
  } catch (_) {
    return DateFormat(pattern).format(parsed);
  }
}

/// A quiet one-line description of a version: "v4 · approved 27 Nov",
/// "Trial v2 · updated 23 Nov", "v3 · retired · updated 2 Oct".
String recipeVersionLine(BuildContext context, RecipeVersion version) {
  final s = RecipeBookStrings.of(context);
  final approved = recipeShortDate(context, version.approvedOn);
  final updated = recipeShortDate(context, version.modified);
  switch (version.status) {
    case VersionStatus.trial:
      return [
        s.trialVersion(version.version),
        if (updated != null) s.updatedOn(updated),
      ].join(' · ');
    case VersionStatus.retired:
      return [
        s.versionNo(version.version),
        s.retiredWord,
        if (updated != null) s.updatedOn(updated),
      ].join(' · ');
    default:
      return [
        s.versionNo(version.version),
        if (approved != null)
          s.approvedOn(approved)
        else if (updated != null)
          s.updatedOn(updated),
      ].join(' · ');
  }
}

/// A centred message with an optional action, for empty and error states.
class RecipeBookMessage extends StatelessWidget {
  const RecipeBookMessage({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// A grey placeholder bar for loading skeletons.
class RecipeSkeletonBar extends StatelessWidget {
  const RecipeSkeletonBar({super.key, required this.width, this.height = 12});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}
