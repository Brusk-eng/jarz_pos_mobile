import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../state/promo_lookup_providers.dart';
import 'customer_promo_result_view.dart';
import 'promo_code_parts.dart';

/// The Customer tab: a customer calls asking whether they have a promo code.
/// Staff type the name or phone number and see the customer's codes.
/// Kept alive so switching to the Code tab and back keeps the answer.
class PromoCustomerTab extends ConsumerStatefulWidget {
  const PromoCustomerTab({super.key});

  @override
  ConsumerState<PromoCustomerTab> createState() => _PromoCustomerTabState();
}

class _PromoCustomerTabState extends ConsumerState<PromoCustomerTab>
    with AutomaticKeepAliveClientMixin {
  final _queryController = TextEditingController();
  bool _showQueryError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _queryController.text.trim();
    if (query.length < CustomerPromoLookupNotifier.minQueryLength) {
      setState(() => _showQueryError = true);
      return;
    }
    if (_showQueryError) setState(() => _showQueryError = false);
    FocusScope.of(context).unfocus();
    ref.read(customerPromoLookupProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final lookup = ref.watch(customerPromoLookupProvider);
    final loading = lookup.isLoading;

    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              key: const ValueKey('promoCustomerSearchField'),
              controller: _queryController,
              // Names and phone numbers both go here, so the keyboard stays
              // a normal text keyboard.
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              enableSuggestions: false,
              autofocus: true,
              onSubmitted: (_) => _submit(),
              onChanged: (_) {
                if (_showQueryError) setState(() => _showQueryError = false);
              },
              decoration: InputDecoration(
                hintText: l10n.promoCustomerSearchHint,
                prefixIcon: const Icon(Icons.person_search_outlined),
                border: const OutlineInputBorder(),
                errorText: _showQueryError
                    ? l10n.promoCustomerQueryTooShort
                    : null,
                errorMaxLines: 2,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('promoCustomerSearchButton'),
              onPressed: loading ? null : _submit,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(l10n.promoCustomerSearch),
            ),
            const SizedBox(height: 16),
            lookup.when(
              skipLoadingOnReload: false,
              data: (result) => result == null
                  ? PromoLookupHint(
                      text: l10n.promoCustomerIntro,
                      icon: Icons.person_search_outlined,
                    )
                  : CustomerPromoResultView(result: result),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => PromoLookupErrorNote(
                message: context.userErrorMessage(
                  e,
                  fallback: l10n.promoCustomerLoadFailed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
