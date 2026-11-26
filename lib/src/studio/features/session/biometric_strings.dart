import 'package:flutter/widgets.dart';

/// Texts of the fingerprint / face sign-in (offer, login button, settings
/// switch), English and Arabic, same pattern as `StudioStrings`.
abstract class BiometricStrings {
  const BiometricStrings();

  static BiometricStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const BiometricStringsAr()
      : const BiometricStringsEn();

  String get offerTitle;
  String get offerBody;
  String get offerYes;
  String get offerNo;
  String get promptReason;
  String get loginButton;
  String get verifyFailed;
  String get settingsTitle;
  String get settingsOn;
  String get settingsOff;
  String get settingsUnavailable;
  String get passwordDialogTitle;
  String get passwordDialogBody;
  String get cancel;
  String get turnedOn;
  String get turnedOff;
}

class BiometricStringsEn extends BiometricStrings {
  const BiometricStringsEn();
  @override
  String get offerTitle => 'Use fingerprint / face to sign in next time?';
  @override
  String get offerBody =>
      'Your password stays encrypted on this phone and is only released '
      'after your fingerprint or face check.';
  @override
  String get offerYes => 'Turn on';
  @override
  String get offerNo => 'Not now';
  @override
  String get promptReason => 'Sign in to Jarz Studio';
  @override
  String get loginButton => 'Sign in with fingerprint / face';
  @override
  String get verifyFailed => 'Could not verify. Use your password.';
  @override
  String get settingsTitle => 'Fingerprint / face sign-in';
  @override
  String get settingsOn => 'Open the app without typing your password.';
  @override
  String get settingsOff => 'Off. You type your password to sign in.';
  @override
  String get settingsUnavailable =>
      'Set up a fingerprint or face in your phone settings first.';
  @override
  String get passwordDialogTitle => 'Enter your password to turn it on';
  @override
  String get passwordDialogBody =>
      'We check it once, then keep it encrypted on this phone.';
  @override
  String get cancel => 'Cancel';
  @override
  String get turnedOn => 'Fingerprint / face sign-in is on.';
  @override
  String get turnedOff => 'Fingerprint / face sign-in is off.';
}

class BiometricStringsAr extends BiometricStrings {
  const BiometricStringsAr();
  @override
  String get offerTitle => 'تدخل بالبصمة أو الوش المرة الجاية؟';
  @override
  String get offerBody =>
      'كلمة السر هتفضل مشفّرة على موبايلك، ومش بتتفتح غير ببصمتك أو وشك.';
  @override
  String get offerYes => 'شغّلها';
  @override
  String get offerNo => 'مش دلوقتي';
  @override
  String get promptReason => 'ادخل Jarz Studio';
  @override
  String get loginButton => 'ادخل بالبصمة أو الوش';
  @override
  String get verifyFailed => 'مقدرناش نتأكد. ادخل بكلمة السر.';
  @override
  String get settingsTitle => 'الدخول بالبصمة أو الوش';
  @override
  String get settingsOn => 'افتح التطبيق من غير ما تكتب كلمة السر.';
  @override
  String get settingsOff => 'مقفولة. بتكتب كلمة السر عشان تدخل.';
  @override
  String get settingsUnavailable =>
      'فعّل بصمة أو Face Unlock من إعدادات موبايلك الأول.';
  @override
  String get passwordDialogTitle => 'اكتب كلمة السر عشان نشغّلها';
  @override
  String get passwordDialogBody =>
      'هنتأكد منها مرة واحدة، وبعدها بتفضل مشفّرة على الموبايل.';
  @override
  String get cancel => 'إلغاء';
  @override
  String get turnedOn => 'الدخول بالبصمة اتفعّل.';
  @override
  String get turnedOff => 'الدخول بالبصمة اتقفل.';
}
