import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../state/promo_lookup_providers.dart';
import 'promo_code_parts.dart';
import 'promo_lookup_result_view.dart';

/// The Code tab: type a promo code and see what the offer is, optionally
/// tried against one order. Kept alive so switching tabs keeps the answer.
class PromoCodeTab extends ConsumerStatefulWidget {
  const PromoCodeTab({super.key});

  @override
  ConsumerState<PromoCodeTab> createState() => _PromoCodeTabState();
}

class _PromoCodeTabState extends ConsumerState<PromoCodeTab>
    with AutomaticKeepAliveClientMixin {
  final _codeController = TextEditingController();
  final _orderController = TextEditingController();
  bool _showCodeError = false;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final l10n = context.l10n;
    final lookup = ref.watch(promoLookupProvider);
    final loading = lookup.isLoading;

    return Align(
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
                errorText: _showCodeError ? l10n.promoLookupEnterCode : null,
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
                  ? PromoLookupHint(text: l10n.promoLookupIntro)
                  : PromoLookupResultView(result: result),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => PromoLookupErrorNote(
                message: context.userErrorMessage(
                  e,
                  fallback: l10n.promoLookupLoadFailed,
                ),
              ),
            ),
          ],
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
