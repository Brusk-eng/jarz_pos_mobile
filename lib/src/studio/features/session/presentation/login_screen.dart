import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../shared/language_switch.dart';
import '../state/studio_session_notifier.dart';

class StudioLoginScreen extends ConsumerStatefulWidget {
  const StudioLoginScreen({super.key});

  @override
  ConsumerState<StudioLoginScreen> createState() => _StudioLoginScreenState();
}

class _StudioLoginScreenState extends ConsumerState<StudioLoginScreen> {
  final _user = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = StudioStrings.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await ref
          .read(studioSessionProvider.notifier)
          .login(_user.text.trim(), _password.text);
      if (!ok && mounted) setState(() => _error = t.signInFailed);
    } catch (_) {
      if (mounted) setState(() => _error = t.errorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = StudioStrings.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(actions: const [LanguageSwitchButton()]),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(StudioSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.loginTitle, style: theme.textTheme.displaySmall),
                const SizedBox(height: StudioSpacing.sm),
                Text(t.loginSubtitle, style: theme.textTheme.bodyMedium),
                const SizedBox(height: StudioSpacing.xl),
                TextField(
                  key: const ValueKey('login-user'),
                  controller: _user,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: t.username),
                ),
                const SizedBox(height: StudioSpacing.md),
                TextField(
                  key: const ValueKey('login-password'),
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _busy ? null : _submit(),
                  decoration: InputDecoration(labelText: t.password),
                ),
                if (_error != null) ...[
                  const SizedBox(height: StudioSpacing.md),
                  Text(
                    _error!,
                    key: const ValueKey('login-error'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: StudioColors.danger,
                    ),
                  ),
                ],
                const SizedBox(height: StudioSpacing.lg),
                FilledButton(
                  key: const ValueKey('login-submit'),
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(t.signIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
