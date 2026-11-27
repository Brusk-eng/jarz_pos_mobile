import 'package:flutter/material.dart';

import '../../data/recipe_book_models.dart';
import '../../domain/recipe_scaling.dart';
import '../recipe_book_strings.dart';
import 'recipe_book_common.dart';
import 'recipe_scale_widgets.dart';

const _tabular = [FontFeature.tabularFigures()];

/// The ingredients, grouped by section, each tappable to scale to it.
class RecipeIngredientsList extends StatelessWidget {
  const RecipeIngredientsList({
    super.key,
    required this.ingredients,
    required this.factor,
    required this.onTapIngredient,
  });

  final List<RecipeIngredient> ingredients;
  final double factor;
  final ValueChanged<RecipeIngredient> onTapIngredient;

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    if (ingredients.isEmpty) {
      return RecipeBookMessage(
        icon: Icons.kitchen_outlined,
        title: s.noIngredients,
      );
    }
    final sections = groupIngredientsBySection(ingredients);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections) ...[
          if (section.section != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
              child: Text(
                section.section!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final ingredient in section.items)
            _IngredientRow(
              ingredient: ingredient,
              factor: factor,
              onTap: () => onTapIngredient(ingredient),
            ),
        ],
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.factor,
    required this.onTap,
  });

  final RecipeIngredient ingredient;
  final double factor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaled = isScaled(factor);
    final amount = formatIngredientAmount(
      scaledIngredientAmount(ingredient, factor),
      ingredient.unit,
    );
    final note = ingredient.note;
    return InkWell(
      key: ValueKey('recipe-ingredient-${ingredient.key}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ingredient.name, style: theme.textTheme.bodyLarge),
                  if (note != null)
                    Text(
                      note,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amount,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFeatures: _tabular,
                fontWeight: FontWeight.w600,
                color: scaled ? recipeScaledColor(context) : null,
              ),
            ),
            SizedBox(
              width: 52,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 6),
                child: Text(
                  displayUnit(ingredient.unit),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The method: numbered step cards.
class RecipeStepsList extends StatelessWidget {
  const RecipeStepsList({
    super.key,
    required this.steps,
    required this.factor,
    this.unresolvedTokens = const <String>[],
  });

  final List<RecipeStep> steps;
  final double factor;
  final List<String> unresolvedTokens;

  @override
  Widget build(BuildContext context) {
    final s = RecipeBookStrings.of(context);
    if (steps.isEmpty) {
      return RecipeBookMessage(icon: Icons.notes, title: s.noSteps);
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final step in steps) RecipeStepCard(step: step, factor: factor),
          if (unresolvedTokens.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                s.unresolvedNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RecipeStepCard extends StatelessWidget {
  const RecipeStepCard({super.key, required this.step, required this.factor});

  final RecipeStep step;
  final double factor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = RecipeBookStrings.of(context);
    final lines = splitSegmentsIntoLines(step.segments);
    final minutes = scaleDuration(step.durationMins, step.scalingMode, factor);
    final target = formatTargetRange(
      step.captureMin,
      step.captureMax,
      step.captureLabel,
    );
    final durationTinted =
        minutes != null && durationScales(step.scalingMode) && isScaled(factor);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.45);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${step.stepNo}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      step.title.isEmpty ? s.step(step.stepNo) : step.title,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
              ],
            ),
            if (lines.isNotEmpty) const SizedBox(height: 8),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: SizedBox(
                  width: double.infinity,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        for (final segment in line)
                          _span(context, segment, factor),
                      ],
                    ),
                    textDirection: lineIsRtl(line)
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    textAlign: TextAlign.start,
                    style: bodyStyle,
                  ),
                ),
              ),
            if (minutes != null || target != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (minutes != null)
                    _StepChip(
                      icon: Icons.timer_outlined,
                      label: formatMinutes(
                        minutes,
                        hour: s.hour,
                        minute: s.minute,
                      ),
                      tinted: durationTinted,
                    ),
                  if (target != null)
                    _StepChip(
                      icon: target.contains('°C')
                          ? Icons.thermostat_outlined
                          : Icons.flag_outlined,
                      label: s.target(target),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static InlineSpan _span(
    BuildContext context,
    RecipeSegment segment,
    double factor,
  ) {
    final text = renderSegment(segment, factor);
    if (segment.isText) return TextSpan(text: text);
    return TextSpan(
      text: text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontFeatures: _tabular,
        color: tokenLooksScaled(segment, factor)
            ? recipeScaledColor(context)
            : null,
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.icon,
    required this.label,
    this.tinted = false,
  });

  final IconData icon;
  final String label;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tinted
        ? recipeScaledColor(context)
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontFeatures: _tabular,
            ),
          ),
        ],
      ),
    );
  }
}

/// Equipment, prep time and notes.
class RecipeNotesView extends StatelessWidget {
  const RecipeNotesView({super.key, required this.detail});

  final RecipeDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = RecipeBookStrings.of(context);
    Widget block(String heading, String body) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            heading,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          for (final line in body.split('\n'))
            if (line.trim().isNotEmpty)
              Text(
                line.trim(),
                textDirection: containsArabic(line)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
        ],
      ),
    );
    final prep = detail.prepTimeMins;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (detail.equipment?.trim().isNotEmpty ?? false)
          block(s.equipment, detail.equipment!),
        if (prep != null && prep > 0)
          block(
            s.prepTime,
            formatMinutes(prep, hour: s.hour, minute: s.minute),
          ),
        if (detail.notes?.trim().isNotEmpty ?? false)
          block(s.notes, detail.notes!),
      ],
    );
  }
}

/// Every version of the recipe; answers the SOP name picked, or null.
Future<String?> showRecipeVersionsSheet(
  BuildContext context, {
  required List<RecipeVersion> versions,
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final s = RecipeBookStrings.of(sheetContext);
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(s.versions, style: theme.textTheme.titleMedium),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      for (final v in versions)
                        ListTile(
                          selected: v.name == selected,
                          onTap: () => Navigator.of(sheetContext).pop(v.name),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  recipeVersionLine(sheetContext, v),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              RecipeStatusPill(
                                status: v.status,
                                label: s.versionStatus(v.status),
                              ),
                            ],
                          ),
                          subtitle: v.changeSummary == null
                              ? null
                              : Text(
                                  v.changeSummary!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          trailing: v.name == selected
                              ? const Icon(Icons.check)
                              : null,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
