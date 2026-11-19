import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';
import '../router.dart';
import 'app_error_reporter.dart';

class AppErrorConsole extends StatelessWidget {
  const AppErrorConsole({super.key, required this.child});

  final Widget child;

  /// The floating "N errors" pill sits in the bottom-right corner and swallows
  /// taps meant for whatever the screen puts there (FABs, kanban card actions).
  /// Keep it for local development only — release builds (staging, production,
  /// distributed APKs) never render it, so it can't block real usage. Error
  /// capture itself is unaffected: [AppErrorReporter] still records everything
  /// and Sentry still receives it.
  static bool get _badgeEnabled => kDebugMode;

  @override
  Widget build(BuildContext context) {
    if (!_badgeEnabled) {
      return child;
    }

    return AnimatedBuilder(
      animation: AppErrorReporter.instance,
      builder: (context, _) {
        final reporter = AppErrorReporter.instance;

        return Stack(
          children: <Widget>[
            child,
            if (reporter.hasRecords)
              Positioned(
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: Material(
                    elevation: 6,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _showDiagnosticsSheet(context),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB3261E),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.bug_report_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              reporter.records.length == 1
                                  ? '1 error'
                                  : '${reporter.records.length} errors',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Resolves a context that actually sits under a [Navigator].
  ///
  /// This widget is mounted from `MaterialApp.builder`, so its own context is an
  /// *ancestor* of the router's navigator. Passing it to [showModalBottomSheet]
  /// makes `Navigator.of` find nothing and blow up on its internal `navigator!`
  /// ("Null check operator used on a null value") in release builds, where the
  /// friendlier debug assert is compiled out. Prefer the router's navigator and
  /// fall back to any navigator above us; never assert.
  BuildContext? _navigatorContext(BuildContext context) {
    final routerContext = rootNavigatorKey.currentContext;
    if (routerContext != null) {
      return routerContext;
    }
    return Navigator.maybeOf(context)?.context;
  }

  Future<void> _showDiagnosticsSheet(BuildContext context) async {
    // The diagnostics UI must never be the thing that crashes the app: if there
    // is no navigator to host the sheet, silently do nothing.
    final sheetContext = _navigatorContext(context);
    if (sheetContext == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: sheetContext,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return AnimatedBuilder(
              animation: AppErrorReporter.instance,
              builder: (context, _) {
                final records = AppErrorReporter.instance.records.reversed
                    .toList(growable: false);

                return Material(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                        child: Row(
                          children: <Widget>[
                            const Expanded(
                              child: Text(
                                'Diagnostics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: records.isEmpty
                                  ? null
                                  : () {
                                      AppErrorReporter.instance.clear();
                                      Navigator.of(context).pop();
                                    },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Clear'),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Recent uncaught, provider, logger, and API errors are listed here with copyable details.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            24 + MediaQuery.paddingOf(context).bottom,
                          ),
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            return _ErrorRecordTile(record: records[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ErrorRecordTile extends StatelessWidget {
  const _ErrorRecordTile({required this.record});

  final AppErrorRecord record;

  @override
  Widget build(BuildContext context) {
    final detailsText = record.details.isEmpty
        ? null
        : const JsonEncoder.withIndent('  ').convert(record.details);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          record.message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('${record.source} • ${record.timestamp.toLocal()}'),
        ),
        trailing: IconButton(
          tooltip: 'Copy error',
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: record.toClipboardText()),
            );
            if (!context.mounted) {
              return;
            }
            final messenger = ScaffoldMessenger.maybeOf(context);
            messenger?.showSnackBar(
              const SnackBar(content: Text('Error details copied')),
            );
          },
          icon: const Icon(Icons.copy_all_outlined),
        ),
        children: <Widget>[
          if (record.summary != null && record.summary != record.message)
            _DetailBlock(label: 'Summary', value: record.summary!),
          _DetailBlock(label: 'Fatal', value: record.fatal ? 'Yes' : 'No'),
          if (record.occurrences > 1)
            _DetailBlock(label: 'Occurrences', value: '${record.occurrences}'),
          if (detailsText != null)
            _DetailBlock(label: 'Details', value: detailsText, monospace: true),
          if (record.stackTrace != null)
            _DetailBlock(
              label: 'Stack trace',
              value: record.stackTrace!,
              monospace: true,
            ),
        ],
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final style = monospace
        ? Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace')
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectionArea(child: Text(value, style: style)),
        ],
      ),
    );
  }
}

Widget buildAppErrorWidget(FlutterErrorDetails details) {
  return Builder(
    builder: (context) {
      final contextLocale = Localizations.maybeLocaleOf(context);
      final locale =
          contextLocale ?? WidgetsBinding.instance.platformDispatcher.locale;
      final supportedLocale = locale.languageCode == 'ar'
          ? const Locale('ar')
          : const Locale('en');
      final localizations = lookupAppLocalizations(supportedLocale);
      // The reporter keeps the original exception and stack for diagnostics.
      // The render fallback is deliberately generic: a build error can contain
      // a full framework trace or a server payload, neither of which belongs
      // in the operator-facing screen.
      final message = localizations.userErrorScreenFailed;

      return Directionality(
        textDirection: supportedLocale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Material(
          color: const Color(0xFFFFF7F7),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DefaultTextStyle(
              style: const TextStyle(color: Color(0xFF7A1C1C)),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFB3261E),
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(message),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
