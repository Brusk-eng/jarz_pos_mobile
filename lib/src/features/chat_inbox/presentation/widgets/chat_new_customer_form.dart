import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../../../core/utils/territory_label.dart';
import '../../../pos/data/repositories/pos_repository.dart';
import '../../data/chat_repository.dart';
import '../../data/models/chat_models.dart';
import '../../state/chat_providers.dart';
import '../chat_bidi.dart';
import '../chat_labels.dart';

/// What the link sheet / new-customer form hands back: an existing customer to
/// link, or a customer that was just created (and already linked).
class ChatLinkChoice {
  const ChatLinkChoice.picked(ChatCustomerOption this.option) : created = null;
  const ChatLinkChoice.created(ChatCreateCustomerResult this.created)
    : option = null;

  final ChatCustomerOption? option;
  final ChatCreateCustomerResult? created;
}

/// The delivery areas the POS offers when it creates a customer.
final chatTerritoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      return ref.watch(posRepositoryProvider).getTerritories();
    });

/// "New customer" from a chat: opens at once with the non-AI [initial]
/// prefill, then asks the server to read the chat (`get_new_customer_prefill`,
/// a model call) and fills every field the moderator has not touched yet.
/// One button, "Create & link".
class ChatNewCustomerScreen extends ConsumerStatefulWidget {
  const ChatNewCustomerScreen({
    super.key,
    required this.conversation,
    this.initial = ChatNewCustomerPrefill.empty,
    this.fallbackName,
  });

  final String conversation;
  final ChatNewCustomerPrefill initial;

  /// Used for the name field when [initial] has none.
  final String? fallbackName;

  @override
  ConsumerState<ChatNewCustomerScreen> createState() =>
      _ChatNewCustomerScreenState();
}

class _ChatNewCustomerScreenState extends ConsumerState<ChatNewCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _address = TextEditingController();

  /// Fields the moderator changed by hand; the AI answer never overwrites
  /// these. Programmatic fills do not call `onChanged`, so they do not count.
  final _touched = <String>{};

  List<String> _phones = const <String>[];
  String? _territory;
  String? _location;
  bool _aiLoading = true;
  String? _aiNote;
  bool _busy = false;
  ChatCustomerCandidate? _existing;

  @override
  void initState() {
    super.initState();
    _applyPrefill(widget.initial);
    if (_name.text.trim().isEmpty && widget.fallbackName != null) {
      _name.text = widget.fallbackName!;
    }
    unawaited(_loadAi());
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _address.dispose();
    super.dispose();
  }

  /// Fill every field in [prefill] that the moderator has not touched.
  void _applyPrefill(ChatNewCustomerPrefill prefill) {
    if (!_touched.contains('name') && prefill.customerName.trim().isNotEmpty) {
      _name.text = prefill.customerName.trim();
    }
    if (!_touched.contains('mobile') && (prefill.mobileNo ?? '').isNotEmpty) {
      _mobile.text = prefill.mobileNo!;
    }
    if (!_touched.contains('address') && (prefill.address ?? '').isNotEmpty) {
      _address.text = prefill.address!;
    }
    if (!_touched.contains('territory') &&
        (prefill.territory ?? '').isNotEmpty) {
      _territory = prefill.territory;
    }
    if (!_touched.contains('location') && (prefill.location ?? '').isNotEmpty) {
      _location = prefill.location;
    }
    final merged = <String>{..._phones, ...prefill.phones};
    _phones = merged.toList(growable: false);
  }

  Future<void> _loadAi() async {
    try {
      final prefill = await ref
          .read(chatRepositoryProvider)
          .fetchNewCustomerPrefill(widget.conversation);
      if (!mounted) return;
      setState(() {
        _applyPrefill(prefill);
        _aiLoading = false;
        _aiNote = prefill.ai
            ? null
            : chatBi(
                context,
                'Could not read the chat; fill the rest by hand.',
                'معرفناش نقرا المحادثة؛ كمّل الباقي بإيدك.',
              );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiLoading = false;
        _aiNote = chatBi(
          context,
          'Could not read the chat; fill the rest by hand.',
          'معرفناش نقرا المحادثة؛ كمّل الباقي بإيدك.',
        );
      });
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _create() async {
    if (_busy) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _territory == null) return;
    setState(() {
      _busy = true;
      _existing = null;
    });
    final failed = context.l10n.customerCreateFailed;
    try {
      final pin = ChatNewCustomerPrefill(location: _location);
      final result = await ref
          .read(chatThreadProvider(widget.conversation).notifier)
          .createCustomerFromChat(
            customerName: _name.text.trim(),
            mobileNo: _mobile.text.trim(),
            address: _address.text.trim(),
            territory: _territory!,
            locationLink: pin.locationLink,
            latitude: pin.coordinates?.lat,
            longitude: pin.coordinates?.lng,
          );
      if (!mounted) return;
      final existing = result.existing;
      if (existing != null) {
        setState(() {
          _existing = existing;
          _busy = false;
        });
        return;
      }
      Navigator.of(context).pop(ChatLinkChoice.created(result));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(context.userErrorMessage(e, fallback: failed));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final territories = ref.watch(chatTerritoriesProvider);
    final uiDirection = Directionality.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(chatBi(context, 'New customer', 'عميل جديد'))),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: ListView(
              key: const ValueKey('chat-newcust-form'),
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (_aiLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      key: const ValueKey('chat-newcust-ai-loading'),
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          chatBi(
                            context,
                            'Filling from the chat…',
                            'بنملّي من المحادثة…',
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                else if (_aiNote != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _aiNote!,
                      key: const ValueKey('chat-newcust-ai-note'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (_existing != null) _existingCard(context, _existing!),
                TextFormField(
                  key: const ValueKey('chat-newcust-name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textDirection: chatTextDirection(_name.text, uiDirection),
                  onChanged: (_) {
                    _touched.add('name');
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: l10n.customerNameLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.customerNameRequired
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('chat-newcust-mobile'),
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) {
                    _touched.add('mobile');
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: l10n.mobileNumberLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.mobileNumberRequired
                      : null,
                ),
                if (_phones.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final phone in _phones)
                          ChoiceChip(
                            key: ValueKey('chat-newcust-phone-$phone'),
                            label: Text(phone),
                            selected: _mobile.text.trim() == phone,
                            onSelected: (_) => setState(() {
                              _mobile.text = phone;
                              _touched.add('mobile');
                            }),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                _territoryField(context, territories),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('chat-newcust-address'),
                  controller: _address,
                  minLines: 2,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textDirection: chatTextDirection(_address.text, uiDirection),
                  onChanged: (_) {
                    _touched.add('address');
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: l10n.detailedAddressRequired,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_on),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.addressRequired
                      : null,
                ),
                if (_location != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: InputChip(
                      key: const ValueKey('chat-newcust-location'),
                      avatar: const Icon(Icons.place_outlined, size: 18),
                      label: Text(
                        chatBi(
                          context,
                          'Pin from the chat',
                          'لوكيشن من المحادثة',
                        ),
                      ),
                      onDeleted: () => setState(() {
                        _location = null;
                        _touched.add('location');
                      }),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const ValueKey('chat-newcust-create'),
                  onPressed: _busy ? null : _create,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1),
                  label: Text(chatBi(context, 'Create & link', 'إنشاء وربط')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _existingCard(BuildContext context, ChatCustomerCandidate existing) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('chat-newcust-existing'),
      color: theme.colorScheme.tertiaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              chatBi(
                context,
                'This number belongs to ${existing.customerName}',
                'الرقم ده بتاع ${existing.customerName}',
              ),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const ValueKey('chat-newcust-existing-link'),
              onPressed: () => Navigator.of(
                context,
              ).pop(ChatLinkChoice.picked(existing.toOption())),
              child: Text(chatBi(context, 'Link to them', 'اربطها بيه')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _territoryField(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> territories,
  ) {
    final l10n = context.l10n;
    return territories.when(
      data: (list) {
        final known = list.any((t) => t['name']?.toString() == _territory);
        return DropdownButtonFormField<String>(
          key: const ValueKey('chat-newcust-territory'),
          initialValue: known ? _territory : null,
          isExpanded: true,
          menuMaxHeight: 320,
          decoration: InputDecoration(
            labelText: l10n.territoryLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.map_outlined),
          ),
          items: [
            for (final territory in list)
              DropdownMenuItem<String>(
                value: territory['name']?.toString(),
                child: Text(
                  territoryLabelOf(territory).isEmpty
                      ? l10n.unknownTerritory
                      : territoryLabelOf(territory),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => setState(() {
            _territory = value;
            _touched.add('territory');
          }),
          validator: (value) => (value == null || value.isEmpty)
              ? l10n.territorySelectRequired
              : null,
        );
      },
      loading: () => TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: l10n.territoryLabel,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.map_outlined),
          suffixIcon: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: l10n.territoryLabel,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.map_outlined),
          errorText: l10n.territoryLoadFailed,
        ),
      ),
    );
  }
}
