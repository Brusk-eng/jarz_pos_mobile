import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/env/env.dart';
import 'src/core/monitoring/sentry_service.dart';
import 'src/studio/core/config/studio_config.dart';
import 'src/studio/core/network/studio_api.dart';
import 'src/studio/studio_app.dart';

/// Entry point of Jarz Studio.
///
///   flutter run -d chrome -t lib/main_studio.dart --dart-define=STUDIO_FAKE=1
///
/// With STUDIO_FAKE=1 nothing talks to a server: no env file, no Sentry, no
/// login. Otherwise the POS env and Sentry setup are reused unchanged.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (StudioConfig.fake) {
    runApp(const ProviderScope(child: StudioApp()));
    return;
  }

  try {
    await loadEnv();
  } catch (_) {
    // Continue with compile-time defines only, as the POS app does.
  }

  var started = false;
  Future<void> start() async {
    started = true;
    runApp(
      ProviderScope(overrides: studioRootOverrides(), child: const StudioApp()),
    );
  }

  try {
    await SentryService.instance.initialize(
      config: SentryRuntimeConfig.fromEnvironment(
        appEnvironment: resolveEnvName(currentHost: Uri.base.host),
      ),
      appRunner: start,
    );
  } catch (_) {
    if (!started) await start();
  }
}
