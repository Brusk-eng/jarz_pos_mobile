import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../shell/more_common.dart';
import '../../shell/more_strings.dart';
import '../settings_strings.dart';
import '../state/settings_state.dart';

/// The people of the team: role, linked login, active.
class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = SettingsStrings.of(context);
    final value = ref.watch(peopleListProvider);
    return ViewEditScaffold(
      title: t.peopleTitle,
      parentRoute: '/more/settings',
      actions: [
        moreHelpAction(context, title: t.peopleHelpTitle, lines: t.peopleHelp),
      ],
      body: MoreBody(
        child: StudioAsyncView<List<StudioPerson>>(
          value: value,
          onRetry: () => ref.invalidate(peopleListProvider),
          empty: StudioEmptyConfig(
            purpose: t.peopleEmptyPurpose,
            firstStep: t.peopleEmptyFirstStep,
            icon: Icons.people_outline,
          ),
          builder: (context, items) => ListView(
            key: const ValueKey('people-list'),
            padding: const EdgeInsets.only(bottom: StudioSpacing.xxl),
            children: [
              for (final p in items)
                MoreCard(
                  key: ValueKey('person-${p.key}'),
                  onTap: () => context.go('/more/settings/people/${p.key}'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.fullName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              t.roleLabel(p.studioRole),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      MorePill(
                        p.enabled ? t.active : t.inactive,
                        foreground: p.enabled
                            ? const Color(0xFF1F6B4A)
                            : StudioColors.plumMuted,
                        background: p.enabled
                            ? const Color(0xFFD7EFE2)
                            : const Color(0xFFF2EFF3),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One person. The pencil changes name, role, linked login, active and
/// "rates every version".
class PersonScreen extends ConsumerWidget {
  const PersonScreen({super.key, required this.personKey});

  final String personKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = SettingsStrings.of(context);
    final value = ref.watch(peopleListProvider);
    final person = value.valueOrNull
        ?.where((p) => p.key == personKey)
        .firstOrNull;

    return ViewEditScaffold(
      title: person?.fullName ?? t.personTitle,
      parentRoute: '/more/settings/people',
      onEdit: person != null && person.actions.contains('edit')
          ? () => _edit(context, ref, person)
          : null,
      actions: [
        moreHelpAction(context, title: t.peopleHelpTitle, lines: t.peopleHelp),
      ],
      body: MoreBody(
        child: StudioAsyncView<List<StudioPerson>>(
          value: value,
          onRetry: () => ref.invalidate(peopleListProvider),
          empty: StudioEmptyConfig(
            purpose: t.peopleEmptyPurpose,
            firstStep: t.peopleEmptyFirstStep,
          ),
          isEmpty: (items) => !items.any((p) => p.key == personKey),
          builder: (context, items) =>
              _PersonBody(p: items.firstWhere((p) => p.key == personKey)),
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    StudioPerson p,
  ) async {
    final fields = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PersonDialog(p: p),
    );
    if (fields == null || fields.isEmpty || !context.mounted) return;
    final t = SettingsStrings.of(context);
    await runMoreWrite(
      context,
      () => ref.read(peopleListProvider.notifier).change(p.key, fields),
      okText: t.personSaved,
    );
  }
}

class _PersonBody extends StatelessWidget {
  const _PersonBody({required this.p});

  final StudioPerson p;

  @override
  Widget build(BuildContext context) {
    final t = SettingsStrings.of(context);
    final m = MoreStrings.of(context);
    return ListView(
      key: const ValueKey('person-body'),
      children: [
        MoreCard(
          padding: const EdgeInsets.all(StudioSpacing.lg),
          child: Column(
            children: [
              LabeledValue(t.fullName, p.fullName),
              LabeledValue(t.roleField, t.roleLabel(p.studioRole)),
              LabeledValue(
                t.linkedLogin,
                p.hasLogin ? (p.user ?? m.yes) : t.noLogin,
              ),
              LabeledValue(t.activeField, p.enabled ? t.active : t.inactive),
              LabeledValue(t.mustRateField, p.mustRate ? m.yes : m.no),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonDialog extends StatefulWidget {
  const _PersonDialog({required this.p});

  final StudioPerson p;

  @override
  State<_PersonDialog> createState() => _PersonDialogState();
}

class _PersonDialogState extends State<_PersonDialog> {
  late final _name = TextEditingController(text: widget.p.fullName);
  late final _user = TextEditingController(text: widget.p.user ?? '');
  late PersonRole _role = widget.p.studioRole;
  late bool _enabled = widget.p.enabled;
  late bool _mustRate = widget.p.mustRate;

  @override
  void dispose() {
    _name.dispose();
    _user.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SettingsStrings.of(context);
    final m = MoreStrings.of(context);
    return AlertDialog(
      key: const ValueKey('person-dialog'),
      title: Text(t.editPerson),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('person-name'),
              controller: _name,
              decoration: InputDecoration(labelText: t.fullName),
            ),
            const SizedBox(height: StudioSpacing.md),
            Text(t.roleField, style: Theme.of(context).textTheme.labelLarge),
            Wrap(
              spacing: StudioSpacing.sm,
              children: [
                for (final r in const [
                  PersonRole.founder,
                  PersonRole.marketingLead,
                  PersonRole.creator,
                  PersonRole.storyLead,
                  PersonRole.moderator,
                ])
                  ChoiceChip(
                    key: ValueKey('person-role-${r.wire}'),
                    label: Text(t.roleLabel(r)),
                    selected: _role == r,
                    onSelected: (_) => setState(() => _role = r),
                  ),
              ],
            ),
            TextField(
              key: const ValueKey('person-user'),
              controller: _user,
              decoration: InputDecoration(
                labelText: t.loginField,
                hintText: t.loginHint,
              ),
            ),
            SwitchListTile(
              key: const ValueKey('person-enabled'),
              contentPadding: EdgeInsets.zero,
              title: Text(t.activeField),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            SwitchListTile(
              key: const ValueKey('person-must-rate'),
              contentPadding: EdgeInsets.zero,
              title: Text(t.mustRateField),
              value: _mustRate,
              onChanged: (v) => setState(() => _mustRate = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(m.cancel),
        ),
        FilledButton(
          key: const ValueKey('person-save'),
          onPressed: () {
            // Only what changed goes to the server.
            final p = widget.p;
            final out = <String, dynamic>{
              if (_name.text.trim() != p.fullName &&
                  _name.text.trim().isNotEmpty)
                'full_name': _name.text.trim(),
              if (_role != p.studioRole) 'studio_role': _role.wire,
              if (_user.text.trim() != (p.user ?? ''))
                'user': _user.text.trim(),
              if (_enabled != p.enabled) 'enabled': _enabled,
              if (_mustRate != p.mustRate) 'must_rate': _mustRate,
            };
            Navigator.of(context).pop(out);
          },
          child: Text(m.save),
        ),
      ],
    );
  }
}
