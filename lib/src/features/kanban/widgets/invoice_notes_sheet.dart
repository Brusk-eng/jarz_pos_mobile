import 'package:jarz_pos/src/core/localization/user_error_message.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localized_formatters.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/websocket/websocket_service.dart';
import '../models/kanban_models.dart';
import '../providers/kanban_provider.dart';

class InvoiceNotesSheet extends ConsumerStatefulWidget {
  const InvoiceNotesSheet({
    super.key,
    required this.invoice,
  });

  final InvoiceCard invoice;

  static Future<void> show(
    BuildContext context, {
    required InvoiceCard invoice,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => InvoiceNotesSheet(invoice: invoice),
    );
  }

  @override
  ConsumerState<InvoiceNotesSheet> createState() => _InvoiceNotesSheetState();
}

class _InvoiceNotesSheetState extends ConsumerState<InvoiceNotesSheet> {
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  StreamSubscription<Map<String, dynamic>>? _notesRealtimeSub;

  List<InvoiceNote> _notes = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _notesRealtimeSub = ref.read(webSocketServiceProvider).kanbanUpdates.listen(
      (event) {
        final eventName = (event['event'] ?? '').toString().toLowerCase();
        final invoiceId = (event['invoice_id'] ?? event['invoice'] ?? '').toString();
        if (eventName == 'invoice_note_added' && invoiceId == widget.invoice.id) {
          _loadNotes(background: true);
        }
      },
    );
  }

  @override
  void dispose() {
    _notesRealtimeSub?.cancel();
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadNotes({bool background = false}) async {
    if (!background) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final notes = await ref.read(kanbanProvider.notifier).getInvoiceNotes(widget.invoice.id);
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _submitNote() async {
    final note = _noteController.text.trim();
    if (note.isEmpty || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(kanbanProvider.notifier).addInvoiceNote(
            invoiceId: widget.invoice.id,
            note: note,
          );
      if (!mounted) return;
      _noteController.clear();
      _noteFocusNode.requestFocus();
      await _loadNotes(background: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.invoiceNoteAdded)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.userErrorMessage(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildNotesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.userErrorMessage(_error!),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadNotes,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (_notes.isEmpty) {
      return Center(
        child: Text(
          context.l10n.invoiceNotesEmpty,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: _notes.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final note = _notes[index];
        final addedOn = note.addedOnDateTime;
        final timestampLabel =
            addedOn == null ? note.addedOn : formatDateTime(context, addedOn.toLocal());
        return ListTile(
          title: Text(
            note.addedByFullName.isNotEmpty ? note.addedByFullName : note.addedBy,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(note.note),
                const SizedBox(height: 6),
                Text(
                  timestampLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          isThreeLine: true,
          dense: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.invoiceNotesTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.invoiceInvoiceLabel(widget.invoice.displayId),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: context.l10n.commonClose,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildNotesList()),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  focusNode: _noteFocusNode,
                  minLines: 2,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: context.l10n.invoiceNotesHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        child: Text(context.l10n.commonClose),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submitNote,
                        child: _isSaving
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(context.l10n.invoiceAddingNote),
                                ],
                              )
                            : Text(context.l10n.commonAdd),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
