import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/studio_language_sync.dart';
import 'core/l10n/studio_locale.dart';
import 'core/l10n/studio_material_localizations.dart';
import 'core/l10n/studio_strings.dart';
import 'core/router/studio_router.dart';
import 'core/theme/studio_theme.dart';
import 'core/upload/upload_engine.dart';
import 'core/upload/upload_tray.dart';
import 'data/write_refresh.dart';
import 'features/assets/state/library_state.dart';
import 'features/pieces/state/add_version_state.dart';
import 'shared/studio_toast.dart';

/// Root of the Jarz Studio app.
class StudioApp extends ConsumerStatefulWidget {
  const StudioApp({super.key});

  @override
  ConsumerState<StudioApp> createState() => _StudioAppState();
}

class _StudioAppState extends ConsumerState<StudioApp> {
  @override
  void initState() {
    super.initState();
    // Uploads left over from the last run (a closed tab, a lost connection)
    // pick up again when the app starts.
    final container = ProviderScope.containerOf(context, listen: false);
    Future<void>.microtask(() async {
      try {
        // The follow-ups first, so a file that finished while the app was
        // closed gets its asset or version when the queue is read.
        registerAssetFollowUp(container);
        registerVersionFollowUp(container);
        await ref.read(studioUploadEngineProvider.notifier).restore();
      } catch (_) {
        // No stored queue (or no storage in this environment): nothing to resume.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(studioWriteRefreshProvider); // one place: data/write_refresh.dart
    ref.watch(studioLanguageSyncProvider); // the language, kept with the server
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
        StudioMaterialLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      scaffoldMessengerKey: studioMessengerKey,
      // The upload tray sits under every screen, so a running upload stays in
      // sight while the person moves around. It draws nothing when idle.
      builder: (context, child) => Column(
        children: [
          Expanded(child: child ?? const SizedBox.shrink()),
          const SafeArea(top: false, child: UploadTray()),
        ],
      ),
    );
  }
}
