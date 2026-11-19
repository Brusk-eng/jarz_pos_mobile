import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_models.dart';
import '../chat_labels.dart';
import 'chat_new_customer_form.dart';

/// "Link customer": suggested customers first (one tap links), then a search
/// box prefilled with the best phone, then a prominent "New customer" button
/// that opens [ChatNewCustomerScreen]. Returns a [ChatLinkChoice] or null.
///
/// [fallbackQuery] (the chat's phone or contact name) is searched when the
/// suggestions cannot be loaded.
Future<ChatLinkChoice?> showChatLinkCustomerSheet(
  BuildContext context, {
  required String conversation,
  String? fallbackQuery,
  String? fallbackName,
}) {
  return showModalBottomSheet<ChatLinkChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => ChatLinkCustomerSheet(
      conversation: conversation,
      fallbackQuery: fallbackQuery,
      fallbackName: fallbackName,
    ),
  );
}

class ChatLinkCustomerSheet extends ConsumerStatefulWidget {
  const ChatLinkCustomerSheet({
    super.key,
    required this.conversation,
    this.fallbackQuery,
    this.fallbackName,
  });

  final String conversation;
  final String? fallbackQuery;
  final String? fallbackName;

  @override
  ConsumerState<ChatLinkCustomerSheet> createState() =>
      _ChatLinkCustomerSheetState();
}

class _ChatLinkCustomerSheetState extends ConsumerState<ChatLinkCustomerSheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  bool _queryTouched = false;

  ChatSuggestCustomersResult? _suggested;
  bool _suggestLoading = true;
  Object? _suggestError;

  List<ChatCustomerOption> _results = const [];
  bool _loading = false;
  Object? _error;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSuggestions());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    try {
      final result = await ref
          .read(chatRepositoryProvider)
          .suggestCustomers(widget.conversation);
      if (!mounted) return;
      setState(() {
        _suggested = result;
        _suggestLoading = false;
      });
      // The best phone, else the cleaned name from the prefill.
      final seed =
          result.bestPhone ??
          (result.prefill.customerName.trim().isEmpty
              ? widget.fallbackQuery
              : result.prefill.customerName.trim());
      _seedQuery(seed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _suggestError = e;
        _suggestLoading = false;
      });
      _seedQuery(widget.fallbackQuery);
    }
  }

  void _seedQuery(String? seed) {
    final text = seed?.trim() ?? '';
    if (_queryTouched || text.isEmpty) return;
    _query.text = text;
    unawaited(_search());
  }

  void _onChanged(String _) {
    _queryTouched = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    final text = _query.text.trim();
    final seq = ++_seq;
    if (text.length < 2) {
      setState(() {
        _results = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref
          .read(chatRepositoryProvider)
          .searchCustomers(text);
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _newCustomer() async {
    final choice = await Navigator.of(context).push<ChatLinkChoice>(
      MaterialPageRoute(
        builder: (_) => ChatNewCustomerScreen(
          conversation: widget.conversation,
          initial: _suggested?.prefill ?? ChatNewCustomerPrefill.empty,
          fallbackName: widget.fallbackName,
        ),
      ),
    );
    if (choice != null && mounted) Navigator.of(context).pop(choice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final candidates =
        _suggested?.candidates ?? const <ChatCustomerCandidate>[];
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.chatActionLinkCustomer,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (_suggestLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(
                        key: ValueKey('chat-suggest-loading'),
                      ),
                    ),
                  if (candidates.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 2),
                      child: Text(
                        chatBi(context, 'Suggested', 'اقتراحات'),
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    for (final candidate in candidates)
                      _CandidateTile(
                        candidate: candidate,
                        onTap: () => Navigator.of(
                          context,
                        ).pop(ChatLinkChoice.picked(candidate.toOption())),
                      ),
                    const Divider(height: 20),
                  ],
                  TextField(
                    key: const ValueKey('chat-link-search'),
                    controller: _query,
                    onChanged: _onChanged,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      labelText: l10n.chatLinkSearchHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_loading) const LinearProgressIndicator(),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        context.userErrorMessage(
                          _error,
                          fallback: l10n.chatLinkSearchFailed,
                        ),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  if (_suggestError != null && !_suggestLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        chatBi(
                          context,
                          'Suggestions are unavailable; search instead.',
                          'الاقتراحات مش متاحة؛ دوّر بنفسك.',
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  if (!_loading &&
                      _error == null &&
                      _results.isEmpty &&
                      _query.text.trim().length >= 2)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(l10n.chatLinkNoResults),
                    ),
                  for (final option in _results)
                    ListTile(
                      key: ValueKey('chat-link-option-${option.name}'),
                      leading: const Icon(Icons.person_outline),
                      title: Text(option.customerName),
                      subtitle: Text(
                        [
                          if (option.mobileNo != null) option.mobileNo!,
                          if (option.customerName != option.name) option.name,
                        ].join(' · '),
                      ),
                      onTap: () => Navigator.of(
                        context,
                      ).pop(ChatLinkChoice.picked(option)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const ValueKey('chat-link-new-customer'),
              onPressed: _newCustomer,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(chatBi(context, 'New customer', 'عميل جديد')),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({required this.candidate, required this.onTap});

  final ChatCustomerCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = candidate.totalOrders;
    return ListTile(
      key: ValueKey('chat-suggest-${candidate.name}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_search_outlined),
      title: Text(candidate.customerName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (candidate.mobileNo != null) candidate.mobileNo!,
              chatBi(
                context,
                '$orders ${orders == 1 ? 'order' : 'orders'}',
                '$orders ${orders == 1 ? 'طلب' : 'طلبات'}',
              ),
            ].join(' · '),
          ),
          if (candidate.reasons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final reason in candidate.reasons)
                    Container(
                      key: ValueKey('chat-suggest-reason-$reason'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        chatSuggestionReasonLabel(context, reason),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
