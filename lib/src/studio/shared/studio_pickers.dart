import 'package:flutter/material.dart';

import 'studio_tr.dart';

/// THE date picker of the Studio: the same dialog as Flutter's, with its OK and
/// Cancel buttons named in both languages (the default OK reads as nothing to a
/// screen reader). Every screen that asks for a date goes through this.
Future<DateTime?> showStudioDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) => showDatePicker(
  context: context,
  initialDate: initialDate,
  firstDate: firstDate,
  lastDate: lastDate,
  helpText: helpText,
  confirmText: context.tr('OK', 'تمام'),
  cancelText: context.tr('Cancel', 'إلغاء'),
);

/// THE time picker of the Studio, with named OK and Cancel.
Future<TimeOfDay?> showStudioTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String? helpText,
}) => showTimePicker(
  context: context,
  initialTime: initialTime,
  helpText: helpText,
  confirmText: context.tr('OK', 'تمام'),
  cancelText: context.tr('Cancel', 'إلغاء'),
);
