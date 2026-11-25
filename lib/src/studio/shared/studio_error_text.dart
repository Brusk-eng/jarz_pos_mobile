import 'package:flutter/material.dart';

import '../core/l10n/studio_labels.dart';
import '../data/studio_error.dart';

/// The one mapping from a failed Studio call to plain words, in English and
/// Arabic. Every screen uses this (no screen words SHADOW_MODE, GATE_FAILED,
/// STALE, NOT_PERMITTED, ALREADY_DONE... its own way).
///
/// GATE_FAILED lists the server's problems under a header; screens that show
/// the problems in their own sheet use [studioGateHeader] instead.
String studioErrorMessage(Object error, {required bool ar}) {
  String tr(String en, String arabic) => ar ? arabic : en;
  if (error is! StudioError) {
    return tr(
      'That did not go through. Nothing was changed. Try again.',
      _arGeneric,
    );
  }
  return switch (error) {
    StudioShadowMode() => tr(
      'The Studio is not switched on yet, so nothing was changed.',
      'الـ Studio لسه مش شغّال، فمفيش حاجة اتغيّرت.',
    ),
    StudioGateFailed(:final problems) =>
      problems.isEmpty
          ? studioGateHeader(ar: ar)
          : '${studioGateHeader(ar: ar)}\n${[for (final p in problems) '- ${StudioLabels.forLanguage(ar ? 'ar' : 'en').problem(p.code, message: p.message)}'].join('\n')}',
    StudioStale() => tr(
      'This changed since you opened it. Refresh the page and try again.',
      'اتغيّر من ساعة ما فتحته. حدّث الصفحة وجرّب تاني.',
    ),
    StudioNotPermitted() => tr('Your role cannot do that.', 'مش مسموح لدورك.'),
    StudioNotFound() => tr(
      'This is no longer there. Go back and refresh.',
      'ده مبقاش موجود. ارجع وحدّث الصفحة.',
    ),
    StudioAlreadyDone() => tr(
      'Already done. This is how it stands now.',
      'اتعمل قبل كده. دي الحالة دلوقتي.',
    ),
    StudioNetworkError() => tr(
      'No connection. Check the internet and try again.',
      'مفيش نت. اتأكد من الاتصال وجرّب تاني.',
    ),
    StudioRateLimited() => tr(
      'Too many tries in a row. Wait a moment and try again.',
      'محاولات كتير ورا بعض. استنى شوية وجرّب تاني.',
    ),
    StudioServerError() => tr(
      'Something went wrong on our side. Try again soon.',
      'حصلت مشكلة عندنا. جرّب تاني كمان شوية.',
    ),
    StudioValidation(:final message) =>
      message.isEmpty
          ? tr(
              'That did not go through. Nothing was changed. Try again.',
              _arGeneric,
            )
          : message,
    _ => tr(
      'That did not go through. Nothing was changed. Try again.',
      _arGeneric,
    ),
  };
}

const _arGeneric = 'ده ماتمش، ومفيش حاجة اتغيّرت. جرّب تاني.';

/// The sentence above a list of gate problems.
String studioGateHeader({required bool ar}) => ar
    ? 'الفحص مانجحش. صلّح اللي تحت وجرّب تاني:'
    : 'The check failed. Fix these and try again:';

bool _isAr(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

/// [studioErrorMessage] in the language of the screen.
String studioErrorText(BuildContext context, Object error) =>
    studioErrorMessage(error, ar: _isAr(context));

/// Shows a failure as a snack bar in plain words.
void showStudioError(BuildContext context, Object error) {
  final text = studioErrorText(context, error);
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 6)),
    );
}
