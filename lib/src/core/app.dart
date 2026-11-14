import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';
import 'debug/app_error_console.dart';
import 'localization/localization_extensions.dart';
import 'localization/locale_notifier.dart';
import 'router.dart';
import 'ui/loading_overlay.dart';
import 'widgets/global_orientation_enforcer.dart';
import 'widgets/manager_bottom_bar.dart';
import 'websocket/websocket_service.dart';
import 'sync/offline_sync_service.dart';
import '../features/pos/state/courier_ws_bridge.dart';
import '../features/pos/state/branch_access_ws_bridge.dart';
import '../features/pos/state/pos_notifier.dart';
import '../features/printing/pos_printer_provider.dart';
import 'network/user_service.dart';
import '../features/pos/order_alert/order_alert_bridge.dart';
import '../features/pos/order_alert/presentation/order_alert_overlay.dart';
import '../features/about/data/about_release_info_repository.dart';
import '../features/about/state/shorebird_update_provider.dart';
import '../features/app_update/presentation/app_update_gate.dart';
import '../features/auth/presentation/session_expired_gate.dart';
import '../features/app_update/state/app_update_provider.dart';
import '../features/approvals/presentation/pending_approvals_widgets.dart';
import '../features/kanban/providers/collect_cash_prompt.dart';
import '../features/update_channel/presentation/shorebird_restart_gate.dart';

class JarzPosApp extends ConsumerWidget {
  const JarzPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeNotifierProvider);
    final isAuthenticated = ref.watch(currentAuthStateProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supported) {
        if (locale != null) {
          return locale;
        }
        if (deviceLocale == null) {
          return supported.first;
        }
        return supported.firstWhere(
          (element) => element.languageCode == deviceLocale.languageCode,
          orElse: () => supported.first,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 1),
        // Every app bar's menu button carries the pending-approvals badge, so
        // a manager sees that something needs them from any screen without
        // opening the side menu. Set here once instead of on 31 screens.
        actionIconTheme: ActionIconThemeData(
          drawerButtonIconBuilder: (_) => const PendingApprovalsMenuIcon(),
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final routed = isAuthenticated
            ? _AuthenticatedServiceBootstrap(
                // Renders the child untouched unless this user has the
                // manager bottom bar switched on.
                child: ManagerBottomBarHost(
                  child: child ?? const SizedBox.shrink(),
                ),
              )
            : child ?? const SizedBox.shrink();
        return GlobalOrientationEnforcer(
          // Outermost thing below orientation: a build the server has refused
          // must not reach routing, auth, or a till - only the update screen.
          child: AppUpdateGate(
            // Below the update gate (a refused build must not even get to
            // sign in) and above everything else: a session the server has
            // dropped ends here rather than in each feature.
            //
            // Directly below it: the Shorebird lifecycle (cold-start patch
            // check before login, per-channel track, and the forced "close
            // and reopen" screen). A refused APK must still win over a patch.
            child: ShorebirdRestartGate(
              isAuthenticated: isAuthenticated,
              child: SessionExpiredGate(
                child: AppErrorConsole(
                  child: OrderAlertOverlay(
                    child: GestureDetector(
                      onTap: () {
                        final currentScope = FocusScope.of(context);
                        if (!currentScope.hasPrimaryFocus &&
                            currentScope.hasFocus) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: LoadingOverlay(
                        child: Column(
                          children: [
                            if (isAuthenticated) const _ShorebirdUpdateBanner(),
                            if (isAuthenticated)
                              const _AppUpdateAvailableBanner(),
                            Expanded(child: routed),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthenticatedServiceBootstrap extends ConsumerStatefulWidget {
  const _AuthenticatedServiceBootstrap({required this.child});

  final Widget child;

  @override
  ConsumerState<_AuthenticatedServiceBootstrap> createState() =>
      _AuthenticatedServiceBootstrapState();
}

class _AuthenticatedServiceBootstrapState
    extends ConsumerState<_AuthenticatedServiceBootstrap>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The Shorebird recheck on resume lives in ShorebirdRestartGate (it
      // re-resolves the update channel first, and also runs signed out).
      // A branch granted or removed while the app was in the background (the
      // realtime event is missed when the socket is down) shows up now.
      ref.read(posNotifierProvider.notifier).refreshProfileList();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(posPrinterServiceProvider);
    ref.watch(webSocketServiceProvider);
    ref.watch(offlineSyncServiceProvider);
    ref.watch(userRolesFutureProvider);
    ref.watch(courierWsBridgeProvider);
    ref.watch(branchAccessWsBridgeProvider);
    ref.watch(orderAlertBridgeProvider);
    // Collect-cash prompts reach the cashier on any screen, not only once the
    // Kanban board has been opened. Does not load the board.
    ref.watch(collectCashPromptListenerProvider);
    ref.watch(shorebirdUpdateProvider);

    return widget.child;
  }
}

/// Soft nudge for a newer APK that is not yet mandatory.
///
/// Distinct from [_ShorebirdUpdateBanner], which is about an OTA patch already
/// downloaded and only needing a restart. This one means a whole new APK
/// exists and the user has to go install it.
class _AppUpdateAvailableBanner extends ConsumerWidget {
  const _AppUpdateAvailableBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirement = ref.watch(appUpdateProvider).valueOrNull;
    // updateRequired suppresses it: that case gets the full-screen gate, and
    // two update prompts at once reads as a bug.
    if (requirement == null ||
        !requirement.updateAvailable ||
        requirement.updateRequired ||
        requirement.downloadUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.blue.shade700,
      child: InkWell(
        onTap: () {
          final uri = Uri.tryParse(requirement.downloadUrl);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.download, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.appUpdateAvailableBanner,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShorebirdUpdateBanner extends ConsumerWidget {
  const _ShorebirdUpdateBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(shorebirdUpdateProvider);
    if (statusAsync.valueOrNull != ShorebirdPatchStatus.restartRequired) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.amber.shade700,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.shorebirdUpdateBannerMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
