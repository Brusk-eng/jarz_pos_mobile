import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../shared/studio_toast.dart';
import '../biometric_strings.dart';
import '../data/biometric_service.dart';
import '../data/session_repository.dart';
import '../state/studio_session_notifier.dart';

/// Whether a stored login is waiting behind the fingerprint (login screen).
final studioBiometricEnabledProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final bio = ref.watch(studioBiometricProvider);
  return bio.supported && await bio.isEnabled();
});

/// Whether the switch in Settings is shown at all, and whether it can be
/// turned on (a strong biometric is enrolled).
final studioBiometricAvailableProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final bio = ref.watch(studioBiometricProvider);
  return bio.supported && await bio.canUse();
});

/// "Sign in with fingerprint / face" under the password form. Draws nothing
/// on web or when the option is off.
class BiometricLoginButton extends ConsumerStatefulWidget {
  const BiometricLoginButton({super.key});

  @override
  ConsumerState<BiometricLoginButton> createState() =>
      _BiometricLoginButtonState();
}

class _BiometricLoginButtonState extends ConsumerState<BiometricLoginButton> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    bool ok = false;
    try {
      ok = await ref.read(studioSessionProvider.notifier).biometricSignIn();
    } catch (_) {
      ok = false;
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _failed = !ok;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(studioBiometricEnabledProvider).valueOrNull;
    if (enabled != true) return const SizedBox.shrink();
    final t = BiometricStrings.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: StudioSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            key: const ValueKey('login-biometric'),
            onPressed: _busy ? null : _go,
            icon: const Icon(Icons.fingerprint),
            label: Text(t.loginButton),
          ),
          if (_failed)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.sm),
              child: Text(
                t.verifyFailed,
                key: const ValueKey('login-biometric-failed'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// Asks once, after a password login, whether to use fingerprint / face next
/// time. Sits above the router; draws nothing itself.
class BiometricOfferHost extends ConsumerWidget {
  const BiometricOfferHost({
    super.key,
    required this.child,
    required this.dialogContext,
  });

  final Widget child;

  /// The context to show the dialog on (the router's navigator).
  final BuildContext? Function() dialogContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<BiometricCredentials?>(studioBiometricOfferProvider, (_, next) {
      if (next == null) return;
      // After the frame: the router has just moved off the login screen.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final ctx = dialogContext();
        if (ctx == null || !ctx.mounted) {
          ref.read(studioBiometricOfferProvider.notifier).state = null;
          return;
        }
        await _ask(ctx, ref, next);
      });
    });
    return child;
  }

  Future<void> _ask(
    BuildContext ctx,
    WidgetRef ref,
    BiometricCredentials creds,
  ) async {
    final bio = ref.read(studioBiometricProvider);
    final t = BiometricStrings.of(ctx);
    final yes = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        key: const ValueKey('biometric-offer'),
        icon: const Icon(Icons.fingerprint, size: 40),
        title: Text(t.offerTitle),
        content: Text(t.offerBody),
        actions: [
          TextButton(
            key: const ValueKey('biometric-offer-no'),
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(t.offerNo),
          ),
          FilledButton(
            key: const ValueKey('biometric-offer-yes'),
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(t.offerYes),
          ),
        ],
      ),
    );
    // Asked once: whatever the answer, the question is not repeated. The
    // switch in Settings stays for a later change of mind.
    await bio.markOffered();
    ref.read(studioBiometricOfferProvider.notifier).state = null;
    if (yes != true) return;
    final ok = await bio.enable(creds.username, creds.password);
    showStudioToast(ok ? t.turnedOn : t.verifyFailed);
  }
}

/// The on / off switch at the end of the Settings hub. Draws nothing on web.
class BiometricSettingsTile extends ConsumerStatefulWidget {
  const BiometricSettingsTile({super.key});

  @override
  ConsumerState<BiometricSettingsTile> createState() =>
      _BiometricSettingsTileState();
}

class _BiometricSettingsTileState extends ConsumerState<BiometricSettingsTile> {
  bool _busy = false;

  Future<void> _toggle(bool on) async {
    final bio = ref.read(studioBiometricProvider);
    final t = BiometricStrings.of(context);
    setState(() => _busy = true);
    try {
      if (!on) {
        await bio.wipe();
        showStudioToast(t.turnedOff);
      } else {
        final me = ref.read(studioSessionProvider).valueOrNull;
        final password = await _askPassword(context);
        if (password == null || password.isEmpty || me == null) return;
        // The password is checked against the server once, then stored.
        final ok = await ref
            .read(studioSessionRepositoryProvider)
            .login(me.user, password);
        if (!ok) {
          if (mounted) showStudioToast(StudioStrings.of(context).signInFailed);
          return;
        }
        final saved = await bio.enable(me.user, password);
        showStudioToast(saved ? t.turnedOn : t.verifyFailed);
      }
    } catch (_) {
      if (mounted) showStudioToast(StudioStrings.of(context).errorGeneric);
    } finally {
      ref.invalidate(studioBiometricEnabledProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPassword(BuildContext context) {
    final t = BiometricStrings.of(context);
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.passwordDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.passwordDialogBody),
            const SizedBox(height: StudioSpacing.md),
            TextField(
              key: const ValueKey('biometric-password'),
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: StudioStrings.of(context).password,
              ),
              onSubmitted: (v) => Navigator.of(c).pop(v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text(t.cancel),
          ),
          FilledButton(
            key: const ValueKey('biometric-password-ok'),
            onPressed: () => Navigator.of(c).pop(controller.text),
            child: Text(t.offerYes),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bio = ref.watch(studioBiometricProvider);
    if (!bio.supported) return const SizedBox.shrink();
    final t = BiometricStrings.of(context);
    final enabled = ref.watch(studioBiometricEnabledProvider).valueOrNull;
    final available = ref.watch(studioBiometricAvailableProvider).valueOrNull;
    final on = enabled == true;
    // Off and nothing enrolled: the switch cannot be turned on.
    final canToggle = !_busy && enabled != null && (on || available == true);
    return SwitchListTile(
      key: const ValueKey('settings-biometric'),
      secondary: const Icon(Icons.fingerprint, color: StudioColors.deepPlum),
      title: Text(t.settingsTitle),
      subtitle: Text(
        on
            ? t.settingsOn
            : (available == false ? t.settingsUnavailable : t.settingsOff),
      ),
      value: on,
      onChanged: canToggle ? _toggle : null,
    );
  }
}
