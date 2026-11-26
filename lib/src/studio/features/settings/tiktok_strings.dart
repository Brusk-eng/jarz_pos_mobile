import 'package:flutter/widgets.dart';

/// Texts of the TikTok card in Settings, English and Arabic. Arabic is short
/// Egyptian; the product words people say in English stay in English.
abstract class TikTokStrings {
  const TikTokStrings();

  static TikTokStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? const TikTokStringsAr()
      : const TikTokStringsEn();

  String get title;
  String get notConnected;
  String get notConfigured;
  String get connect;
  String get disconnect;
  String get refresh;
  String get connectFailed;
  String get loadFailed;
  String get disconnectTitle;
  String get disconnectBody;
  String get cancel;
  String get disconnected;
  String connectedAs(String name);
  String get connectedNoName;
  String validUntil(String date);
  String get shadowNote;
  String lastProblem(String text);
}

class TikTokStringsEn extends TikTokStrings {
  const TikTokStringsEn();

  @override
  String get title => 'TikTok';
  @override
  String get notConnected => 'Not connected';
  @override
  String get notConfigured =>
      'The TikTok app id and secret are not entered yet. Enter them in '
      'Social Account Settings first.';
  @override
  String get connect => 'Connect TikTok';
  @override
  String get disconnect => 'Disconnect';
  @override
  String get refresh => 'Check again';
  @override
  String get connectFailed => 'Could not open TikTok. Try again.';
  @override
  String get loadFailed => 'Could not read the TikTok status.';
  @override
  String get disconnectTitle => 'Disconnect TikTok?';
  @override
  String get disconnectBody =>
      'Jarz stops reading and posting to this account until you connect it again.';
  @override
  String get cancel => 'Cancel';
  @override
  String get disconnected => 'TikTok disconnected';
  @override
  String connectedAs(String name) => 'Connected as $name';
  @override
  String get connectedNoName => 'Connected';
  @override
  String validUntil(String date) => 'Access valid until $date';
  @override
  String get shadowNote =>
      'Connecting is safe. Nothing is posted to TikTok until publishing is on.';
  @override
  String lastProblem(String text) => 'Last problem: $text';
}

class TikTokStringsAr extends TikTokStrings {
  const TikTokStringsAr();

  @override
  String get title => 'TikTok';
  @override
  String get notConnected => 'مش متوصّل';
  @override
  String get notConfigured =>
      'لسه محدش دخّل الـ app id والـ secret بتوع TikTok. ادخلهم الأول في '
      'Social Account Settings.';
  @override
  String get connect => 'وصّل TikTok';
  @override
  String get disconnect => 'افصل';
  @override
  String get refresh => 'اتأكد تاني';
  @override
  String get connectFailed => 'مقدرناش نفتح TikTok. جرّب تاني.';
  @override
  String get loadFailed => 'مقدرناش نقرا حالة TikTok.';
  @override
  String get disconnectTitle => 'تفصل TikTok؟';
  @override
  String get disconnectBody =>
      'جارز هيبطّل يقرا من الحساب ده وينشر عليه لحد ما توصّله تاني.';
  @override
  String get cancel => 'إلغاء';
  @override
  String get disconnected => 'TikTok اتفصل';
  @override
  String connectedAs(String name) => 'متوصّل بحساب $name';
  @override
  String get connectedNoName => 'متوصّل';
  @override
  String validUntil(String date) => 'الوصول شغّال لحد $date';
  @override
  String get shadowNote =>
      'التوصيل آمن. مفيش حاجة بتتنشر على TikTok لحد ما النشر يتفتح.';
  @override
  String lastProblem(String text) => 'آخر مشكلة: $text';
}
