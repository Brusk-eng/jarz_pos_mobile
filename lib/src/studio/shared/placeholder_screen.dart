import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/studio_strings.dart';
import '../core/router/studio_screen.dart';
import 'studio_async_view.dart';
import 'view_edit_scaffold.dart';

/// A destination that is not built yet: a ViewEditScaffold around the empty
/// state, whose text says what the screen is for and what to do first. Later
/// packages replace the body feature by feature.
class StudioPlaceholderScreen extends StatelessWidget {
  const StudioPlaceholderScreen({
    super.key,
    required this.screen,
    this.parentRoute,
    this.titleSuffix,
    this.bottom,
  });

  final StudioScreen screen;
  final String? parentRoute;

  /// Appended to the title, e.g. the id of a piece opened by deep link.
  final String? titleSuffix;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final copy = StudioStrings.of(context).screen(screen);
    return ViewEditScaffold(
      title: titleSuffix == null ? copy.title : '${copy.title} $titleSuffix',
      screen: screen,
      parentRoute: parentRoute,
      bottom: bottom,
      body: PlaceholderBody(screen: screen),
    );
  }
}

/// Just the body, for screens that bring their own scaffold (Inbox tabs).
class PlaceholderBody extends StatelessWidget {
  const PlaceholderBody({super.key, required this.screen});

  final StudioScreen screen;

  @override
  Widget build(BuildContext context) {
    final copy = StudioStrings.of(context).screen(screen);
    return StudioAsyncView<void>(
      value: const AsyncData<void>(null),
      isEmpty: (_) => true,
      builder: (_, _) => const SizedBox.shrink(),
      empty: StudioEmptyConfig(
        purpose: copy.purpose,
        firstStep: copy.firstStep,
      ),
    );
  }
}
