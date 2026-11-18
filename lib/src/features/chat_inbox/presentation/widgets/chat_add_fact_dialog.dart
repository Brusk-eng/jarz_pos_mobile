import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/models/chat_models.dart';
import '../chat_bidi.dart';
import '../chat_labels.dart';

// "Add to facts": a manager turns what a moderator told the AI (a fact
// conflict line) into an approved fact, so the AI may say it from then on
// without a warning. Shared by the draft panel's confirm-facts alert and the
// moderator-overrides screen.
//
// Every string here is inline bilingual (chatBi), never an .arb key: an .arb
// edit forces a full APK, while this stays a Shorebird patch.

/// The separator between the moderator's side and our facts in a conflict
/// line: `"<what the moderator said> → <what our facts say>"`.
const chatConflictSeparator = ' → ';

/// The moderator's side of a conflict line (the text before " → "), trimmed.
/// The whole line when it has no separator.
String chatConflictModeratorSide(String line) {
  final at = line.indexOf(chatConflictSeparator);
  return (at < 0 ? line : line.substring(0, at)).trim();
}

/// A topic for the fact: the moderator's side of [line], cut to at most
/// [maxChars] at a word boundary (a hard cut when one word is longer).
String chatFactTopicFromLine(String line, {int maxChars = 60}) {
  final side = chatConflictModeratorSide(line).replaceAll(RegExp(r'\s+'), ' ');
  if (side.length <= maxChars) return side;
  final cut = side.substring(0, maxChars);
  final space = cut.lastIndexOf(' ');
  final trimmed = space > 0 ? cut.substring(0, space) : cut;
  return trimmed.replaceAll(RegExp(r'[\s,.;:،؛\-–]+$'), '').trim();
}

/// What the manager entered in the dialog.
class ChatFactApprovalInput {
  final String topic;
  final String factEn;
  final String factAr;
  final String category;

  const ChatFactApprovalInput({
    required this.topic,
    this.factEn = '',
    this.factAr = '',
    this.category = ChatFactCategories.other,
  });
}

/// A fact category as the manager reads it (wire value in English).
String chatFactCategoryLabel(BuildContext context, String category) {
  final ar = switch (category) {
    ChatFactCategories.product => 'المنتج',
    ChatFactCategories.sizes => 'الأحجام',
    ChatFactCategories.storage => 'التخزين',
    ChatFactCategories.ingredientsAndClaims => 'المكونات والادعاءات',
    ChatFactCategories.delivery => 'التوصيل',
    ChatFactCategories.payment => 'الدفع',
    ChatFactCategories.ordering => 'الطلب',
    ChatFactCategories.allergensAndNutrition =>
      'مسببات الحساسية والقيم الغذائية',
    ChatFactCategories.brandVoice => 'أسلوب البراند',
    ChatFactCategories.other => 'أخرى',
    _ => category,
  };
  return chatBi(context, category, ar);
}

/// Opens "Add to approved facts" for the conflict [line], prefilled from the
/// moderator's side. [onSubmit] runs the request while the dialog shows a
/// spinner; a failure keeps the dialog open with the server's message (also
/// in a SnackBar). Returns true once [onSubmit] succeeded.
Future<bool> showChatAddFactDialog(
  BuildContext context, {
  required String line,
  required Future<void> Function(ChatFactApprovalInput input) onSubmit,
}) async {
  final added = await showDialog<bool>(
    context: context,
    builder: (context) => ChatAddFactDialog(line: line, onSubmit: onSubmit),
  );
  return added ?? false;
}

class ChatAddFactDialog extends StatefulWidget {
  const ChatAddFactDialog({
    super.key,
    required this.line,
    required this.onSubmit,
  });

  final String line;
  final Future<void> Function(ChatFactApprovalInput input) onSubmit;

  @override
  State<ChatAddFactDialog> createState() => _ChatAddFactDialogState();
}

class _ChatAddFactDialogState extends State<ChatAddFactDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _topic;
  late final TextEditingController _factEn;
  final _factAr = TextEditingController();
  String _category = ChatFactCategories.other;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _topic = TextEditingController(text: chatFactTopicFromLine(widget.line));
    _factEn = TextEditingController(
      text: chatConflictModeratorSide(widget.line),
    );
    _factEn.addListener(_onChanged);
    _factAr.addListener(_onChanged);
  }

  @override
  void dispose() {
    _factEn.removeListener(_onChanged);
    _factAr.removeListener(_onChanged);
    _topic.dispose();
    _factEn.dispose();
    _factAr.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasFact =>
      _factEn.text.trim().isNotEmpty || _factAr.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        ChatFactApprovalInput(
          topic: _topic.text.trim(),
          factEn: _factEn.text.trim(),
          factAr: _factAr.text.trim(),
          category: _category,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final message = context.userErrorMessage(
        e,
        fallback: context.l10n.chatActionFailed,
      );
      setState(() {
        _busy = false;
        _error = message;
      });
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String bi(String en, String ar) => chatBi(context, en, ar);
    final factMissing = bi(
      'Write the fact in English or Arabic',
      'اكتب المعلومة بالإنجليزي أو بالعربي',
    );

    return AlertDialog(
      key: const ValueKey('chat-add-fact-dialog'),
      title: Text(bi('Add to approved facts', 'إضافة للمعلومات المعتمدة')),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  bi(
                    'From now on the AI may say this without a warning.',
                    'من دلوقتي الذكاء الاصطناعي يقدر يقول ده من غير تحذير.',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('chat-add-fact-topic'),
                  controller: _topic,
                  enabled: !_busy,
                  maxLength: 140,
                  decoration: InputDecoration(
                    labelText: bi('Topic', 'الموضوع'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? bi('Enter a topic', 'اكتب الموضوع')
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('chat-add-fact-en'),
                  controller: _factEn,
                  enabled: !_busy,
                  minLines: 2,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textDirection: chatTextDirection(
                    _factEn.text,
                    TextDirection.ltr,
                  ),
                  decoration: InputDecoration(
                    labelText: bi('Fact in English', 'المعلومة بالإنجليزي'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (_) => _hasFact ? null : factMissing,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('chat-add-fact-ar'),
                  controller: _factAr,
                  enabled: !_busy,
                  minLines: 2,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    labelText: bi(
                      'Fact in Arabic (optional)',
                      'المعلومة بالعربي (اختياري)',
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (_) => _hasFact ? null : factMissing,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('chat-add-fact-category'),
                  initialValue: _category,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: bi('Category', 'التصنيف'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final category in ChatFactCategories.all)
                      DropdownMenuItem(
                        value: category,
                        child: Text(chatFactCategoryLabel(context, category)),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(
                          () => _category = value ?? ChatFactCategories.other,
                        ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    key: const ValueKey('chat-add-fact-error'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('chat-add-fact-cancel'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          key: const ValueKey('chat-add-fact-submit'),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(bi('Add', 'إضافة')),
        ),
      ],
    );
  }
}

/// Under one conflict line: a green "Added to facts ✓" once the line is an
/// approved fact; else, for a manager ([canApprove]), a small "Add to facts"
/// button; else nothing. [keyId] makes the keys unique per line.
class ChatFactConflictAction extends StatelessWidget {
  const ChatFactConflictAction({
    super.key,
    required this.keyId,
    required this.approved,
    required this.canApprove,
    this.onAdd,
  });

  final String keyId;
  final bool approved;
  final bool canApprove;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    if (approved) {
      final green = Colors.green.shade700;
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Container(
          key: ValueKey('chat-fact-added-$keyId'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: green.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: green.withValues(alpha: 0.5)),
          ),
          child: Text(
            chatBi(context, 'Added to facts ✓', 'اتضافت للمعلومات ✓'),
            style: TextStyle(
              color: green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    if (!canApprove) return const SizedBox.shrink();
    return TextButton.icon(
      key: ValueKey('chat-fact-add-$keyId'),
      onPressed: onAdd,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      icon: const Icon(Icons.playlist_add_check, size: 16),
      label: Text(chatBi(context, 'Add to facts', 'أضف للمعلومات')),
    );
  }
}

/// The SnackBar text after a successful approval.
String chatFactAddedMessage(BuildContext context) =>
    chatBi(context, 'Added to approved facts', 'اتضافت للمعلومات المعتمدة');
