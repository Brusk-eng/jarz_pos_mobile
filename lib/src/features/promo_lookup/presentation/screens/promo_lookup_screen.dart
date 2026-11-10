import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../widgets/promo_code_tab.dart';
import '../widgets/promo_customer_tab.dart';

/// Promo code lookup for any staff member, in two tabs:
/// * Customer (default): a caller asks "do I have a code?" — search them by
///   name or phone and see their personal, open, used and expired codes.
/// * Code: type a code and see the offer, optionally tried on one order.
///
/// Read-only; both endpoints only need a login.
class PromoLookupScreen extends StatelessWidget {
  const PromoLookupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text(l10n.promoLookupTitle),
          bottom: TabBar(
            tabs: [
              Tab(
                key: const ValueKey('promoLookupCustomerTab'),
                icon: const Icon(Icons.person_search_outlined),
                text: l10n.promoLookupTabCustomer,
                iconMargin: const EdgeInsets.only(bottom: 2),
              ),
              Tab(
                key: const ValueKey('promoLookupCodeTab'),
                icon: const Icon(Icons.local_offer_outlined),
                text: l10n.promoLookupTabCode,
                iconMargin: const EdgeInsets.only(bottom: 2),
              ),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(children: [PromoCustomerTab(), PromoCodeTab()]),
        ),
      ),
    );
  }
}
