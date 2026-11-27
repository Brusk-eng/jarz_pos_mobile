import 'package:flutter/material.dart';

import '../core/theme/studio_tokens.dart';
import 'layout/studio_layout.dart';
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
    this.rootTab = false,
    this.contentWidth = StudioContentWidth.reading,
    this.titleExtra,
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

  /// A bottom-bar destination (Today, Inbox, Calendar, Pieces, More): it is
  /// where the person lands, so it never shows a back arrow. Pushed screens
  /// leave this false and always do.
  final bool rootTab;

  /// The widest the body gets (centred) on a wide window; collections pass
  /// [StudioContentWidth.full]. A phone never reaches the cap.
  final double contentWidth;

  /// A widget next to the title on one line (wide windows, e.g. Today's day
  /// switcher). It takes the room between the title and the actions.
  final Widget? titleExtra;

  @override
  Widget build(BuildContext context) {
    final t = StudioStrings.of(context);
    final router = GoRouter.maybeOf(context);
    final canPop = router?.canPop() ?? Navigator.of(context).canPop();

    Widget? leading;
    if (!rootTab && (parentRoute != null || canPop)) {
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
        title: titleExtra == null
            ? Text(title)
            : Row(
                children: [
                  Text(title),
                  const SizedBox(width: StudioSpacing.xl),
                  Expanded(child: titleExtra!),
                ],
              ),
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
      body: StudioPage(maxWidth: contentWidth, child: body),
    );
  }
}
