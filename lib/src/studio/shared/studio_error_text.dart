import 'package:flutter/material.dart';

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
    return tr('That did not go through. Nothing was changed.', _arGeneric);
  }
  return switch (error) {
    StudioShadowMode() => tr(
      'The Studio is not switched on yet, so nothing can be changed.',
      'الـ Studio لسه مش شغّال، فمفيش حاجة تتغيّر.',
    ),
    StudioGateFailed(:final problems) =>
      problems.isEmpty
          ? studioGateHeader(ar: ar)
          : '${studioGateHeader(ar: ar)}\n${[for (final p in problems) '- ${p.message}'].join('\n')}',
    StudioStale() => tr(
      'Someone changed this a moment ago. Showing the latest, try again.',
      'حد غيّر ده من لحظات. بنعرض آخر نسخة، جرّب تاني.',
    ),
    StudioNotPermitted() => tr(
      'You are not allowed to do this.',
      'مش مسموح لك تعمل ده.',
    ),
    StudioNotFound() => tr('This is no longer there.', 'ده مبقاش موجود.'),
    StudioAlreadyDone() => tr(
      'This was already done. Showing how it stands now.',
      'ده اتعمل قبل كده. بنعرض الحالة دلوقتي.',
    ),
    StudioNetworkError() => tr(
      'No connection. Check the internet and try again.',
      'مفيش اتصال. اتأكد من النت وجرّب تاني.',
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
          ? tr('That did not go through. Nothing was changed.', _arGeneric)
          : message,
    _ => tr('That did not go through. Nothing was changed.', _arGeneric),
  };
}

const _arGeneric = 'ده ماتمش. مفيش حاجة اتغيّرت.';

/// The sentence above a list of gate problems.
String studioGateHeader({required bool ar}) => ar
    ? 'مينفعش نكمل لسه. صلّح الحاجات دي الأول:'
    : 'This cannot go ahead yet. Fix these first:';

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
