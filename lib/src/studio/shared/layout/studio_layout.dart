import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/studio_tokens.dart';

/// The Studio's width classes. Every screen reads them from here, so no screen
/// carries its own magic width.
///
/// * compact  < 600   a phone
/// * medium   600-1023  a large phone turned sideways, a small tablet
/// * expanded 1024-1439 a tablet turned sideways, a laptop
/// * large    >= 1440  a desktop
enum StudioBreakpoint {
  compact,
  medium,
  expanded,
  large;

  static const double mediumMin = 600;
  static const double expandedMin = 1024;
  static const double largeMin = 1440;

  /// The class of a width in logical pixels.
  static StudioBreakpoint forWidth(double width) {
    if (width >= largeMin) return large;
    if (width >= expandedMin) return expanded;
    if (width >= mediumMin) return medium;
    return compact;
  }

  bool get isCompact => this == compact;

  /// At least [medium] wide.
  bool get isMediumUp => index >= medium.index;

  /// At least [expanded] wide: two or more columns, master and detail side by
  /// side.
  bool get isWide => index >= expanded.index;
}

/// Reading the class of the screen (or of the space a widget got).
extension StudioLayoutContext on BuildContext {
  /// The class of the whole window.
  StudioBreakpoint get breakpoint =>
      StudioBreakpoint.forWidth(MediaQuery.sizeOf(this).width);

  /// The window is at least [StudioBreakpoint.expanded] wide.
  bool get isWideScreen => breakpoint.isWide;

  /// The window is at least [StudioBreakpoint.medium] wide (not a phone).
  bool get isMediumScreenUp => breakpoint.isMediumUp;

  /// The window is a phone.
  bool get isCompactScreen => breakpoint.isCompact;
}

/// The widest a screen's content gets.
class StudioContentWidth {
  StudioContentWidth._();

  /// Forms, settings, one detail: a comfortable line length.
  static const double form = 720;

  /// Reading screens (a piece, a post, a shoot).
  static const double reading = 840;

  /// Wide lists that still read as a column (references).
  static const double wide = 1100;

  /// Collections (grids, boards, the week): the full window.
  static const double full = double.infinity;
}

/// Centres [child] and caps its width at [maxWidth]; the empty side margins
/// still scroll the content with the mouse wheel. On a phone (narrower than
/// the cap) it changes nothing. Height stays exactly what the parent gave, so
/// a `Column` with `Expanded` or a list inside keeps working.
class StudioPage extends StatelessWidget {
  const StudioPage({
    super.key,
    required this.child,
    this.maxWidth = StudioContentWidth.reading,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (maxWidth == double.infinity) return child;
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth <= maxWidth) return child;
        final margin = (box.maxWidth - maxWidth) / 2;
        // The side margins pass a mouse wheel on to the content, so the page
        // scrolls with the pointer anywhere over it.
        Widget side(bool left) => SizedBox(
          width: margin,
          height: box.hasBoundedHeight ? box.maxHeight : null,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerSignal: (e) => _forward(e, left: left, margin: margin),
          ),
        );
        return Row(
          children: [
            side(true),
            SizedBox(
              width: maxWidth,
              height: box.hasBoundedHeight ? box.maxHeight : null,
              child: child,
            ),
            side(false),
          ],
        );
      },
    );
  }
}

/// A wheel turn over a margin is replayed just inside the content's edge, so
/// the scroll view under it takes it.
void _forward(
  PointerSignalEvent e, {
  required bool left,
  required double margin,
}) {
  if (e is! PointerScrollEvent) return;
  // The origin of this margin on screen; the content starts at the left
  // margin's end and ends where the right margin starts.
  final origin = e.position.dx - e.localPosition.dx;
  final x = left ? origin + margin + 1 : origin - 1;
  GestureBinding.instance.handlePointerEvent(
    e.copyWith(position: Offset(x, e.position.dy)),
  );
}

/// How many columns a grid of sections gets in a space [width] wide:
/// 1 below [StudioBreakpoint.expanded], 2 up to the large class, 3 from it.
int studioSectionColumns(double width) =>
    switch (StudioBreakpoint.forWidth(width)) {
      StudioBreakpoint.compact || StudioBreakpoint.medium => 1,
      StudioBreakpoint.expanded => 2,
      StudioBreakpoint.large => 3,
    };

/// One section for [ResponsiveSectionGrid]. [weight] is how tall it is,
/// roughly (a count of rows); the grid puts the next section in the lightest
/// column so short sections do not leave holes.
class GridSection {
  const GridSection({required this.child, this.weight = 1});

  final Widget child;
  final double weight;
}

/// Sections that flow into 1, 2 or 3 columns by the window's class,
/// masonry style: each section goes under the lightest column, in order, so
/// the first sections land on the top row and short ones fill gaps. Inside a
/// column the order of the sections is kept.
///
/// Not lazy: it builds every section, so use it for tens of sections, not
/// hundreds. Put it in a scroll view.
class ResponsiveSectionGrid extends StatelessWidget {
  const ResponsiveSectionGrid({
    super.key,
    required this.sections,
    this.gap = StudioSpacing.md,
    this.columnsFor = studioSectionColumns,
  });

  final List<GridSection> sections;
  final double gap;

  /// The number of columns for a width; override to ask for fewer or more.
  final int Function(double width) columnsFor;

  /// Which column each section goes to (pure, so tests can check it).
  static List<List<int>> assign(List<double> weights, int columns) {
    final cols = [for (var i = 0; i < columns; i++) <int>[]];
    final load = List<double>.filled(columns, 0);
    for (var i = 0; i < weights.length; i++) {
      var best = 0;
      for (var c = 1; c < columns; c++) {
        if (load[c] < load[best]) best = c;
      }
      cols[best].add(i);
      load[best] += weights[i];
    }
    return cols;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final columns = sections.length < 2
            ? 1
            : columnsFor(
                MediaQuery.sizeOf(context).width,
              ).clamp(1, sections.length);
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                sections[i].child,
              ],
            ],
          );
        }
        final cols = assign([for (final s in sections) s.weight], columns);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < columns; c++) ...[
              if (c > 0) SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < cols[c].length; j++) ...[
                      if (j > 0) SizedBox(height: gap),
                      sections[cols[c][j]].child,
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Cards in a grid whose column count follows the width: as many columns as
/// fit at [minCellWidth], up to [maxColumns]. Cells in a row keep their own
/// height (no stretching), left-aligned in each cell; rows are as tall as
/// their tallest cell. Not lazy.
class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.minCellWidth = 420,
    this.maxColumns = 4,
    this.gap = StudioSpacing.md,
  });

  final List<Widget> children;
  final double minCellWidth;
  final int maxColumns;
  final double gap;

  /// The column count for a width (pure, so tests can check it).
  static int columnsFor(double width, double minCellWidth, int maxColumns) {
    final n = ((width + 0) / minCellWidth).floor();
    return n.clamp(1, maxColumns);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = columnsFor(box.maxWidth, minCellWidth, maxColumns);
        if (cols == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                children[i],
              ],
            ],
          );
        }
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < cols; c++) ...[
                  if (c > 0) SizedBox(width: gap),
                  Expanded(
                    child: i + c < children.length
                        ? children[i + c]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) SizedBox(height: gap),
              rows[r],
            ],
          ],
        );
      },
    );
  }
}
