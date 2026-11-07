import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../state/promo_lookup_providers.dart';
import '../widgets/promo_lookup_result_view.dart';

/// Any staff member types a promo code and sees what the offer is, optionally
/// tried against one order. Read-only; `lookup_promo_code` only needs a login.
class PromoLookupScreen extends ConsumerStatefulWidget {
  const PromoLookupScreen({super.key});

  @override
  ConsumerState<PromoLookupScreen> createState() => _PromoLookupScreenState();
}

class _PromoLookupScreenState extends ConsumerState<PromoLookupScreen> {
  final _codeController = TextEditingController();
  final _orderController = TextEditingController();
  bool _showCodeError = false;

  @override
  void dispose() {
    _codeController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _showCodeError = true);
      return;
    }
    if (_showCodeError) setState(() => _showCodeError = false);
    FocusScope.of(context).unfocus();
    ref
        .read(promoLookupProvider.notifier)
        .lookup(code: code, order: _orderController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lookup = ref.watch(promoLookupProvider);
    final loading = lookup.isLoading;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: Text(l10n.promoLookupTitle)),
      body: SafeArea(
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  key: const ValueKey('promoLookupCodeField'),
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: const [_UpperCaseFormatter()],
                  textInputAction: TextInputAction.search,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofocus: true,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) {
                    if (_showCodeError) setState(() => _showCodeError = false);
                  },
                  decoration: InputDecoration(
                    labelText: l10n.promoLookupCodeLabel,
                    prefixIcon: const Icon(Icons.local_offer_outlined),
                    border: const OutlineInputBorder(),
                    errorText: _showCodeError
                        ? l10n.promoLookupEnterCode
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('promoLookupOrderField'),
                  controller: _orderController,
                  textInputAction: TextInputAction.search,
                  autocorrect: false,
                  enableSuggestions: false,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: l10n.promoLookupOrderLabel,
                    hintText: l10n.promoLookupOrderHint,
                    prefixIcon: const Icon(Icons.receipt_long_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const ValueKey('promoLookupCheckButton'),
                  onPressed: loading ? null : _submit,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(l10n.promoLookupCheck),
                ),
                const SizedBox(height: 16),
                lookup.when(
                  skipLoadingOnReload: false,
                  data: (result) => result == null
                      ? _Hint(text: l10n.promoLookupIntro)
                      : PromoLookupResultView(result: result),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => _ErrorNote(
                    message: context.userErrorMessage(
                      e,
                      fallback: l10n.promoLookupLoadFailed,
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

/// Codes are stored upper-case; typing them in lower case should still look
/// like the code on the flyer.
class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    if (upper == newValue.text) return newValue;
    return newValue.copyWith(text: upper);
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 40,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
