import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/user_error_message.dart';
import '../../data/repositories/address_pin_repository.dart';
import '../../domain/geo_pin_sources.dart';
import 'location_link_field.dart';
import 'location_point_picker.dart';

/// Opens the "Add map pin" bottom sheet for [addressName].
///
/// Resolves true when a pin was written (or the address already held an
/// equal-or-better one, which also satisfies the delivery rule), false when
/// staff dismissed the sheet.
Future<bool> showAddPinSheet(
  BuildContext context, {
  required String addressName,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      // Lift the form above the keyboard; the field lives at the top.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AddPinSheet(addressName: addressName),
        ),
      ),
    ),
  );
  return saved ?? false;
}

/// Sheet body: title, hint and the [AddPinForm]. Pops `true` once saved.
class AddPinSheet extends StatelessWidget {
  const AddPinSheet({super.key, required this.addressName, this.previewBuilder});

  final String addressName;
  final LocationPreviewBuilder? previewBuilder;

  static const titleKey = ValueKey('add_pin_sheet_title');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.courierLaunchPinSheetTitle,
          key: titleKey,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.courierLaunchPinSheetHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        AddPinForm(
          addressName: addressName,
          previewBuilder: previewBuilder,
          onSaved: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// Paste-a-link field, "Pick on map" and a Save button that writes the pin
/// through the existing address-pin endpoint (`set_address_pin`).
///
/// Shared by the sheet (Kanban card, order details) and the cart's inline
/// delivery-pin card. Source is always `pos_link` — the highest rung ordinary
/// staff may write; `manual_override` stays the line manager's correction
/// screen. The server keeps a better existing pin and says so, which still
/// counts as "this address has a pin".
class AddPinForm extends ConsumerStatefulWidget {
  const AddPinForm({
    super.key,
    required this.addressName,
    required this.onSaved,
    this.focusNode,
    this.previewBuilder,
  });

  final String addressName;

  /// Called after the pin was saved (or an equal-or-better one already stood).
  final VoidCallback onSaved;

  /// Focus node for the link field, so the cart can pull the cursor in when
  /// the server refuses an unpinned address.
  final FocusNode? focusNode;
  final LocationPreviewBuilder? previewBuilder;

  static const pickOnMapKey = ValueKey('add_pin_pick_on_map');
  static const saveKey = ValueKey('add_pin_save');
  static const pickedKey = ValueKey('add_pin_picked');

  @override
  ConsumerState<AddPinForm> createState() => _AddPinFormState();
}

class _AddPinFormState extends ConsumerState<AddPinForm> {
  LocationLinkValue _value = LocationLinkValue.empty;
  LatLng? _picked;
  bool _saving = false;

  bool get _canSave => !_saving && (_picked != null || _value.isConfirmed);

  Future<void> _pickOnMap() async {
    final point = await showLocationPointPicker(
      context,
      initial: _picked ??
          (_value.isConfirmed
              ? LatLng(_value.latitude!, _value.longitude!)
              : null),
    );
    if (point == null || !mounted) return;
    setState(() => _picked = point);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final picked = _picked;
    setState(() => _saving = true);
    try {
      // A dropped pin wins over whatever is in the link box; with only a link
      // the server re-resolves it and keeps the pasted text.
      final decision = await ref
          .read(addressPinRepositoryProvider)
          .setPin(
            address: widget.addressName,
            link: picked == null ? _value.link : null,
            latitude: picked?.latitude,
            longitude: picked?.longitude,
            source: GeoPinSource.posLink,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            decision.accepted == false
                ? l10n.courierLaunchPinKept
                : l10n.courierLaunchPinSaved,
          ),
        ),
      );
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.userErrorMessage(
              e,
              fallback: l10n.courierLaunchPinSaveFailed,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final picked = _picked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LocationLinkField(
          focusNode: widget.focusNode,
          enabled: !_saving,
          previewBuilder: widget.previewBuilder,
          onChanged: (value) => setState(() => _value = value),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: AddPinForm.pickOnMapKey,
            onPressed: _saving ? null : _pickOnMap,
            icon: const Icon(Icons.pin_drop_outlined),
            label: Text(l10n.addressPinPickOnMap),
          ),
        ),
        if (picked != null) ...[
          const SizedBox(height: 8),
          Row(
            key: AddPinForm.pickedKey,
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
              const SizedBox(width: 6),
              Expanded(
                child: Directionality(
                  // Coordinates are LTR digits even in an Arabic UI.
                  textDirection: TextDirection.ltr,
                  child: Text(
                    l10n.courierLaunchPinPicked(
                      '${picked.latitude.toStringAsFixed(5)}, '
                      '${picked.longitude.toStringAsFixed(5)}',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: l10n.locationLinkClear,
                onPressed: _saving ? null : () => setState(() => _picked = null),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          key: AddPinForm.saveKey,
          onPressed: _canSave ? _save : null,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(l10n.courierLaunchPinSave),
        ),
      ],
    );
  }
}
