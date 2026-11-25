import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

/// Flutter's own Arabic words for its built-in widgets, where the default does
/// not read naturally ("رفض" for Dismiss, "تمويه" for Scrim, "حسنًا" for OK).
/// English and every other part of Arabic stay Flutter's.
class StudioMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const StudioMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      GlobalMaterialLocalizations.delegate.isSupported(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // Flutter's delegate loads the date symbols; it is always loaded first.
    final base = await GlobalMaterialLocalizations.delegate.load(locale);
    if (locale.languageCode != 'ar') return base;
    final name = locale.toString();
    return SynchronousFuture(
      StudioMaterialLocalizationAr(
        fullYearFormat: intl.DateFormat.y(name),
        compactDateFormat: intl.DateFormat.yMd(name),
        shortDateFormat: intl.DateFormat.yMMMd(name),
        mediumDateFormat: intl.DateFormat.MMMEd(name),
        longDateFormat: intl.DateFormat.yMMMMEEEEd(name),
        yearMonthFormat: intl.DateFormat.yMMMM(name),
        shortMonthDayFormat: intl.DateFormat.MMMd(name),
        decimalFormat: intl.NumberFormat.decimalPattern(name),
        twoDigitZeroPaddedFormat: intl.NumberFormat('00', name),
      ),
    );
  }

  @override
  bool shouldReload(StudioMaterialLocalizationsDelegate old) => false;
}

/// The Arabic bundle with the Studio's own words for the labels a screen reader
/// reads and the buttons the pickers show.
class StudioMaterialLocalizationAr extends MaterialLocalizationAr {
  const StudioMaterialLocalizationAr({
    required super.fullYearFormat,
    required super.compactDateFormat,
    required super.shortDateFormat,
    required super.mediumDateFormat,
    required super.longDateFormat,
    required super.yearMonthFormat,
    required super.shortMonthDayFormat,
    required super.decimalFormat,
    required super.twoDigitZeroPaddedFormat,
  });

  @override
  String get modalBarrierDismissLabel => 'إغلاق';
  @override
  String get scrimLabel => 'الخلفية';
  @override
  String get okButtonLabel => 'تمام';
  @override
  String get cancelButtonLabel => 'إلغاء';
  @override
  String get saveButtonLabel => 'احفظ';
  @override
  String get continueButtonLabel => 'كمّل';
  @override
  String get closeButtonLabel => 'إغلاق';
  @override
  String get menuDismissLabel => 'إغلاق القائمة';
  @override
  String get currentDateLabel => 'النهارده';
  @override
  String get selectedDateLabel => 'التاريخ المختار';
  @override
  String get datePickerHelpText => 'اختار التاريخ';
  @override
  String get inputDateModeButtonLabel => 'اكتب التاريخ';
  @override
  String get calendarModeButtonLabel => 'اختار من التقويم';
  @override
  String get refreshIndicatorSemanticLabel => 'تحديث';
}
