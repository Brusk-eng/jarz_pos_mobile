import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/studio_strings.dart';
import '../core/router/studio_screen.dart';
import 'how_this_works_sheet.dart';
import 'language_switch.dart';

/// "Tap = view, pencil = edit." The body is read-only; when [onEdit] is set a
/// pencil in the app bar opens the edit form (a separate screen or sheet the
/// caller pushes). There is no inline editing anywhere.
///
/// When [screen] is set, a "?" opens that screen's "how this works" sheet.
class ViewEditScaffold extends StatelessWidget {
  const ViewEditScaffold({
    super.key,
    required this.title,
    required this.body,
    this.screen,
    this.onEdit,
    this.actions = const [],
    this.parentRoute,
    this.showLanguageSwitch = false,
    this.bottom,
  });

  final String title;
  final Widget body;
  final StudioScreen? screen;

  /// Opens the edit form. Null hides the pencil (read-only for this user).
  final VoidCallback? onEdit;
  final List<Widget> actions;

  /// Where the back arrow goes when the screen was opened by deep link and
  /// there is nothing to pop. Null hides the arrow.
  final String? parentRoute;
  final bool showLanguageSwitch;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final t = StudioStrings.of(context);
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? Navigator.of(context).canPop();

    Widget? leading;
    if (parentRoute != null || canPop) {
      leading = BackButton(
        key: const ValueKey('back'),
        onPressed: () {
          if (canPop) {
            if (router != null) {
              router.pop();
            } else {
              Navigator.of(context).pop();
            }
          } else if (parentRoute != null) {
            router?.go(parentRoute!);
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: leading,
        title: Text(title),
        bottom: bottom,
        actions: [
          ...actions,
          if (showLanguageSwitch) const LanguageSwitchButton(),
          if (screen != null)
            IconButton(
              key: const ValueKey('help'),
              tooltip: t.howThisWorks,
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                final copy = t.screen(screen!);
                HowThisWorksSheet.show(
                  context,
                  title: copy.title,
                  lines: copy.help,
                );
              },
            ),
          if (onEdit != null)
            IconButton(
              key: const ValueKey('edit'),
              tooltip: t.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
        ],
      ),
      body: body,
    );
  }
}
