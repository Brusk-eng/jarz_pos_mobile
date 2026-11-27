import '../../../shared/layout/studio_layout.dart';
import '../../../shared/studio_pickers.dart';
import '../../../data/api/studio_api_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/how_this_works_sheet.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../inbox/presentation/inbox_hub.dart';
import '../../inbox/presentation/ui_helpers.dart';
import '../../settings/data/settings_repository.dart';
import 'notifications_strings.dart';
import '../../../shared/studio_error_text.dart';

String _hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay _parse(String? v, TimeOfDay fallback) {
  if (v == null || v.length < 5) return fallback;
  final h = int.tryParse(v.substring(0, 2));
  final m = int.tryParse(v.substring(3, 5));
  return h == null || m == null ? fallback : TimeOfDay(hour: h, minute: m);
}

/// Quiet hours, the daily digest and the read-only list of what this person is
/// told about (`settings.my_notifications` / `settings.set_my_notifications`).
class NotificationPrefsScreen extends ConsumerStatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  ConsumerState<NotificationPrefsScreen> createState() => _PrefsState();
}

class _PrefsState extends ConsumerState<NotificationPrefsScreen> {
  bool _busy = false;

  Future<void> _save({
    String? quietFrom,
    String? quietTo,
    bool? digestEnabled,
    String? digestTime,
  }) async {
    final t = NotificationsStrings.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(myNotificationPrefsProvider.notifier)
          .save(
            quietFrom: quietFrom,
            quietTo: quietTo,
            digestEnabled: digestEnabled,
            digestTime: digestTime,
          );
      if (mounted) showStudioNote(context, t.saved);
    } catch (e) {
      if (mounted) showStudioError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(String? current, void Function(String) then) async {
    final picked = await showStudioTimePicker(
      context: context,
      initialTime: _parse(current, const TimeOfDay(hour: 22, minute: 0)),
    );
    if (picked != null) then(_hhmm(picked));
  }

  @override
  Widget build(BuildContext context) {
    final t = NotificationsStrings.of(context);
    final copy = t.prefsCopy;
    final value = ref.watch(myNotificationPrefsProvider);

    return ViewEditScaffold(
      contentWidth: StudioContentWidth.form,
      title: copy.title,
      parentRoute: InboxPaths.notifications,
      showLanguageSwitch: true,
      actions: [
        IconButton(
          key: const ValueKey('help'),
          tooltip: StudioStrings.of(context).howThisWorks,
          icon: const Icon(Icons.help_outline),
          onPressed: () => HowThisWorksSheet.show(
            context,
            title: copy.title,
            lines: copy.help,
          ),
        ),
      ],
      body: StudioAsyncView<NotificationPrefs>(
        value: value,
        onRetry: () => ref.invalidate(myNotificationPrefsProvider),
        isEmpty: (_) => false,
        empty: StudioEmptyConfig(
          purpose: copy.purpose,
          firstStep: copy.firstStep,
        ),
        builder: (context, p) {
          final theme = Theme.of(context);
          return ListView(
            key: const ValueKey('prefs-list'),
            padding: const EdgeInsets.all(StudioSpacing.gutter),
            children: [
              Text(t.quietHours, style: theme.textTheme.titleMedium),
              const SizedBox(height: StudioSpacing.xs),
              Text(t.quietNote, style: theme.textTheme.bodySmall),
              const SizedBox(height: StudioSpacing.sm),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      key: const ValueKey('quiet-from'),
                      title: Text(t.quietFrom),
                      trailing: Text(p.quietFrom ?? t.notSet),
                      onTap: _busy
                          ? null
                          : () =>
                                _pick(p.quietFrom, (v) => _save(quietFrom: v)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      key: const ValueKey('quiet-to'),
                      title: Text(t.quietTo),
                      trailing: Text(p.quietTo ?? t.notSet),
                      onTap: _busy
                          ? null
                          : () => _pick(p.quietTo, (v) => _save(quietTo: v)),
                    ),
                    if (p.quietFrom != null || p.quietTo != null)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          key: const ValueKey('quiet-clear'),
                          // An explicit null on both: the quiet hours go.
                          onPressed: _busy
                              ? null
                              : () => _save(
                                  quietFrom: studioClear,
                                  quietTo: studioClear,
                                ),
                          child: Text(t.clearQuiet),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: StudioSpacing.lg),
              Text(t.digest, style: theme.textTheme.titleMedium),
              const SizedBox(height: StudioSpacing.sm),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      key: const ValueKey('digest-switch'),
                      title: Text(t.digestOn),
                      value: p.digestEnabled,
                      onChanged: _busy ? null : (v) => _save(digestEnabled: v),
                    ),
                    if (p.digestEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        key: const ValueKey('digest-time'),
                        title: Text(t.digestTime),
                        trailing: Text(p.digestTime ?? t.notSet),
                        onTap: _busy
                            ? null
                            : () => _pick(
                                p.digestTime,
                                (v) => _save(digestTime: v),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: StudioSpacing.lg),
              Text(t.eventsTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: StudioSpacing.xs),
              Text(t.eventsNote, style: theme.textTheme.bodySmall),
              const SizedBox(height: StudioSpacing.sm),
              for (final e in p.events)
                ListTile(
                  key: ValueKey('event-${e.event}'),
                  dense: true,
                  leading: const Icon(Icons.notifications_none, size: 20),
                  title: Text(e.label),
                  subtitle: Text(t.audience(e.audience)),
                ),
            ],
          );
        },
      ),
    );
  }
}
