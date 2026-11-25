import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/studio_locale.dart';
import 'core/l10n/studio_strings.dart';
import 'core/router/studio_router.dart';
import 'core/theme/studio_theme.dart';

/// Root of the Jarz Studio app.
class StudioApp extends ConsumerWidget {
  const StudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(studioLocaleProvider);
    final router = ref.watch(studioRouterProvider);
    return MaterialApp.router(
      title: StudioStrings.forLocale(locale).appName,
      debugShowCheckedModeBanner: false,
      theme: buildStudioTheme(locale: locale),
      locale: locale,
      supportedLocales: StudioStrings.supportedLocales,
      localizationsDelegates: const [
        StudioStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
