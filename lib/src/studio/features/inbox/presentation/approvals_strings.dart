import 'package:flutter/material.dart';

import '../state/approvals_logic.dart';

/// Words of the founder's approvals list, English and Arabic. The Arabic is
/// Egyptian; product and flavour names stay in English.
class ApprovalsStrings {
  const ApprovalsStrings(this.ar);

  final bool ar;

  static ApprovalsStrings of(BuildContext context) =>
      ApprovalsStrings(Localizations.localeOf(context).languageCode == 'ar');

  String _t(String en, String arabic) => ar ? arabic : en;

  // Tabs and empty states.
  String get tabToApprove => _t('To approve', 'مستنية موافقتك');
  String get tabApproved => _t(
    'Approved — going out next 7 days',
    'اتوافق عليها — هتنزل في الـ 7 أيام الجاية',
  );
  String get emptyToApprove =>
      _t('Nothing waiting for you.', 'مفيش حاجة مستنياك.');
  String get emptyToApproveHint => _t(
    'When a piece is ready for your yes it lands here, in the order it goes out.',
    'أول ما قطعة تبقى جاهزة لموافقتك هتظهر هنا، بترتيب معاد نزولها.',
  );
  String get emptyApprovedHint => _t(
    'What you approve shows here with the time it goes out and who posts it.',
    'اللي بتوافق عليه هيظهر هنا بمعاد نزوله واللي هينشره.',
  );
  String get emptyApproved => _t(
    'Nothing approved is going out in the next 7 days.',
    'مفيش حاجة معتمدة هتنزل في الـ 7 أيام الجاية.',
  );

  // Day groups.
  String get groupOverdue => _t('Overdue — slot passed', 'متأخرة — معادها فات');
  String get groupToday => _t('Today', 'النهارده');
  String get groupTomorrow => _t('Tomorrow', 'بكرة');
  String get groupNoTime => _t('No time set yet', 'لسه من غير معاد');
  String groupTitle(ApprovalGroup g, String dayText) => switch (g.kind) {
    ApprovalDay.overdue => groupOverdue,
    ApprovalDay.today => groupToday,
    ApprovalDay.tomorrow => groupTomorrow,
    ApprovalDay.later => dayText,
    ApprovalDay.noTime => groupNoTime,
  };

  // Card.
  String get noSlot => _t('No time set yet', 'لسه من غير معاد');
  String get notJudged => _t('Not judged yet', 'لسه متقيمتش');
  String get judgeStale =>
      _t('(judged before the last change)', '(اتقيّمت قبل آخر تعديل)');
  String judgeLine(String verdict, String? reason) =>
      reason == null ? verdict : '$verdict — $reason';
  String get sellJudge => _t('Sell judge', 'حكم البيع');
  String get captionTitle =>
      _t('Caption as it will post', 'الكابشن زي ما هيتنشر');
  String get noCaption => _t('No caption yet', 'مفيش كابشن لسه');
  String get showAll => _t('Show all', 'اعرض الكل');
  String get showLess => _t('Show less', 'اعرض أقل');
  String get failedChecks => _t('Checks that failed', 'فحوصات مش ناجحة');
  String get badgeHardYesPrice => _t(
    'Needs your hard yes (price/box post)',
    'محتاجة موافقتك الصريحة (بوست سعر/بوكس)',
  );
  String get badgeHardYesLaunch => _t(
    'Needs your hard yes (launch post)',
    'محتاجة موافقتك الصريحة (بوست إطلاق)',
  );
  String get badgeTrial =>
      _t('Already ran as a trial reel', 'نزلت قبل كده كريل تجريبي');
  String get openMedia => _t('Open the file', 'افتح الملف');
  String get openDetails => _t('Open details', 'افتح التفاصيل');
  String filesCount(int n) => _t('$n files', '$n ملفات');
  String get postsByItself =>
      _t('Posts by itself at that time', 'هتتنشر لوحدها في المعاد ده');
  String postsByHand(String? name) => name == null
      ? _t('Posted by hand by the team', 'هتتنشر بإيد الفريق')
      : _t('Posted by hand by $name', 'هتتنشر بإيد $name');

  // Actions.
  String get approve => _t('Approve', 'وافق');
  String get sendBack => _t('Send back', 'رجّعها');
  String get changeTime => _t('Change time', 'غيّر المعاد');
  String get undoApproval => _t('Undo approval', 'ألغي الموافقة');
  String get undoTooLate => _t(
    'Too close to the slot to undo (15 min).',
    'قريب أوي من المعاد، مينفعش تلغي (15 دقيقة).',
  );
  String get pickDate => _t('Pick the day', 'اختار اليوم');
  String get pickTime => _t('Pick the time', 'اختار الساعة');
  String get approvedToast => _t('Approved.', 'اتوافق عليها.');

  // Results of an action.
  String approvedByItself(String when, String platform) => _t(
    'Approved. Posts by itself $when on $platform',
    'اتوافق عليها. هتتنشر لوحدها $when على $platform',
  );
  String approvedByHand(String? name, String when, String platform) =>
      name == null
      ? _t(
          'Approved. The team posts it by hand $when on $platform',
          'اتوافق عليها. الفريق هينشرها بإيده $when على $platform',
        )
      : _t(
          'Approved. $name posts it by hand $when on $platform',
          'اتوافق عليها. هتتنشر بإيد $name $when على $platform',
        );
  String get approvedNoSlot => _t(
    'Approved. It has no time yet, so it will not post until one is set.',
    'اتوافق عليها. لسه من غير معاد، فمش هتتنشر قبل ما يتحدد معاد.',
  );
  String get sentBack => _t('Sent back with your note.', 'اترجعت بملاحظتك.');
  String get timeSaved => _t('New time saved.', 'المعاد الجديد اتحفظ.');
  String get approvalUndone => _t(
    'Approval undone. It is back in To approve.',
    'الموافقة اتلغت. رجعت لـ مستنية موافقتك.',
  );
  String get loadMore => _t('Load more', 'حمّل كمان');

  // Times.
  String get am => _t('am', 'ص');
  String get pm => _t('pm', 'م');

  /// "Tue 1 Dec · 8:00 pm".
  String when(DateTime d, {bool withDay = true}) {
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final mm = d.minute.toString().padLeft(2, '0');
    final time = '$h12:$mm ${d.hour < 12 ? am : pm}';
    return withDay ? '${dayText(d)} · $time' : time;
  }

  /// "Tue 1 Dec".
  String dayText(DateTime d) {
    final wd = (ar ? _daysAr : _daysEn)[d.weekday - 1];
    final mo = (ar ? _monthsAr : _monthsEn)[d.month - 1];
    return '$wd ${d.day} $mo';
  }

  /// "in 2 days 4 h" / "3 h 20 min ago".
  String countdown(ApprovalSpan s) {
    final parts = <String>[
      if (s.days > 0) _days(s.days),
      if (s.hours > 0) _hours(s.hours),
      if (s.days == 0 && s.minutes > 0) _mins(s.minutes),
    ];
    if (parts.isEmpty) parts.add(_mins(s.minutes == 0 ? 1 : s.minutes));
    final joined = parts.join(ar ? ' و' : ' ');
    return s.past
        ? _t('$joined ago', 'من $joined')
        : _t('in $joined', 'بعد $joined');
  }

  String _days(int n) => ar
      ? (n == 1
            ? 'يوم'
            : n == 2
            ? 'يومين'
            : n <= 10
            ? '$n أيام'
            : '$n يوم')
      : (n == 1 ? '1 day' : '$n days');
  String _hours(int n) => ar
      ? (n == 1
            ? 'ساعة'
            : n == 2
            ? 'ساعتين'
            : n <= 10
            ? '$n ساعات'
            : '$n ساعة')
      : '$n h';
  String _mins(int n) => ar
      ? (n == 1
            ? 'دقيقة'
            : n == 2
            ? 'دقيقتين'
            : n <= 10
            ? '$n دقايق'
            : '$n دقيقة')
      : '$n min';

  static const _daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _daysAr = [
    'الاتنين', 'التلات', 'الأربع', 'الخميس', 'الجمعة', 'السبت', 'الأحد', //
  ];
  static const _monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _monthsAr = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', //
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
}
