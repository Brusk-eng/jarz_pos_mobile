import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_strings.dart';
import 'package:jarz_pos/src/studio/core/theme/studio_theme.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';
import 'package:jarz_pos/src/studio/data/models/studio_models.dart';
import 'package:jarz_pos/src/studio/features/calendar/presentation/calendar_widgets.dart';
import 'package:jarz_pos/src/studio/features/inbox/presentation/approval_card.dart';
import 'package:jarz_pos/src/studio/features/inbox/state/approvals_logic.dart';
import 'package:jarz_pos/src/studio/shared/person_text.dart';
import 'package:jarz_pos/src/studio/shared/post_platforms.dart';

/// One post, two platforms: the approvals card words, the marks on a calendar
/// tile, and an older server that sends neither field.

ApproveCard _card(String versionId) {
  final page = ApproveCardPage.fromJson(
    jsonDecode(studioFixtures['inbox.to_approve']!) as Map<String, dynamic>,
  );
  return page.items.firstWhere((c) => c.version.id == versionId);
}

ApproveCard _with(
  ApproveCard c, {
  List<String>? platforms,
  Map<String, String>? status,
}) => c.copyWith(
  posts: [
    for (final p in c.posts)
      p.copyWith(
        platforms: platforms,
        platformStatus: status,
        slotTime: '2026-12-01T20:00:00+02:00',
      ),
  ],
);

Future<void> _pump(WidgetTester tester, Widget child, {String locale = 'en'}) {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp.router(
      locale: Locale(locale),
      theme: buildStudioTheme(locale: Locale(locale)),
      supportedLocales: StudioStrings.supportedLocales,
      localizationsDelegates: const [
        StudioStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ],
      ),
    ),
  );
}

Widget _approval(ApproveCard c, ApprovalCardMode mode) => ApprovalCard(
  key: ValueKey('approve-${c.version.id}'),
  card: c,
  now: DateTime(2026, 11, 27, 9),
  mode: mode,
);

String _t(WidgetTester t, String key) {
  final f = find.byKey(ValueKey(key));
  final w = t.widget(f);
  if (w is PersonText) return w.text;
  if (w is Text) return w.data!;
  return t
      .widget<PersonText>(
        find.descendant(of: f, matching: find.byType(PersonText)),
      )
      .text;
}

const _both = ['Instagram', 'TikTok'];

void main() {
  group('approvals card', () {
    testWidgets('both platforms: channel line and the approved words', (
      tester,
    ) async {
      final c = _with(
        _card('PC-00188-v1'),
        platforms: _both,
        status: {'Instagram': 'planned', 'TikTok': 'planned'},
      );
      await _pump(tester, _approval(c, ApprovalCardMode.approved));
      expect(_t(tester, 'card-channel'), 'Instagram feed reel + TikTok');
      expect(
        _t(tester, 'card-approved-note'),
        'Approved. Posts by itself Tue 1 Dec · 8:00 pm on Instagram and TikTok',
      );
    });

    testWidgets('TikTok by hand: Instagram by itself, TikTok by a person', (
      tester,
    ) async {
      final c = _with(
        _card('PC-00188-v1'),
        platforms: _both,
        status: {'Instagram': 'planned', 'TikTok': 'by hand'},
      );
      await _pump(tester, _approval(c, ApprovalCardMode.approved));
      final name = c.posts.first.assignee?.fullName;
      final who = name ?? 'the team';
      expect(
        _t(tester, 'card-approved-note'),
        'Approved. Posts by itself Tue 1 Dec · 8:00 pm on Instagram; TikTok: posted by hand by $who',
      );
    });

    testWidgets('TikTok failed: still goes to both, the card does not change', (
      tester,
    ) async {
      final c = _with(
        _card('PC-00188-v1'),
        platforms: _both,
        status: {'Instagram': 'planned', 'TikTok': 'failed'},
      );
      await _pump(tester, _approval(c, ApprovalCardMode.approved));
      expect(_t(tester, 'card-channel'), 'Instagram feed reel + TikTok');
      expect(
        _t(tester, 'card-approved-note'),
        contains('on Instagram and TikTok'),
      );
    });

    testWidgets('empty list (older server): exactly as before', (tester) async {
      final c = _with(_card('PC-00188-v1'), platforms: const [], status: null);
      await _pump(tester, _approval(c, ApprovalCardMode.approved));
      expect(_t(tester, 'card-channel'), 'Instagram feed reel');
      expect(
        _t(tester, 'card-approved-note'),
        'Approved. Posts by itself Tue 1 Dec · 8:00 pm on Instagram',
      );
    });

    testWidgets('missing fields (null) parse and behave as before', (
      tester,
    ) async {
      final json = jsonDecode(studioFixtures['inbox.to_approve']!) as Map;
      for (final it in json['items'] as List) {
        for (final p in it['posts'] as List) {
          (p as Map).remove('platforms');
          p.remove('platform_status');
        }
      }
      final page = ApproveCardPage.fromJson(json.cast<String, dynamic>());
      final c = page.items.firstWhere((x) => x.version.id == 'PC-00188-v1');
      expect(c.posts.first.platforms, isNull);
      await _pump(tester, _approval(c, ApprovalCardMode.waiting));
      expect(_t(tester, 'card-channel'), 'Instagram feed reel');
    });

    testWidgets('Arabic: both platforms and TikTok by hand', (tester) async {
      final both = _with(
        _card('PC-00188-v1'),
        platforms: _both,
        status: {'Instagram': 'planned', 'TikTok': 'planned'},
      );
      await _pump(
        tester,
        _approval(both, ApprovalCardMode.approved),
        locale: 'ar',
      );
      expect(
        _t(tester, 'card-approved-note'),
        endsWith('على Instagram و TikTok'),
      );
      expect(_t(tester, 'card-channel'), endsWith('+ TikTok'));

      final hand = _with(
        _card('PC-00188-v1'),
        platforms: _both,
        status: {'Instagram': 'planned', 'TikTok': 'by hand'},
      );
      await _pump(
        tester,
        _approval(hand, ApprovalCardMode.approved),
        locale: 'ar',
      );
      await tester.pumpAndSettle();
      final name = hand.posts.first.assignee?.fullName ?? 'الفريق';
      expect(
        _t(tester, 'card-approved-note'),
        endsWith('على Instagram؛ TikTok: هتتنشر بإيد $name'),
      );
    });
  });

  group('calendar tile marks', () {
    PostSummary post(List<String>? platforms, Map<String, String>? status) =>
        PostSummary.fromJson({
          'id': 'SP-1',
          'title': 'A reel',
          'status': 'Draft',
          'caption_ready': true,
          'modified': '2026-11-27T09:00:00+02:00',
          'channel': 'Feed reel',
          'platforms': ?platforms,
          'platform_status': ?status,
        });

    testWidgets('one item, two marks coloured by state, tap shows words', (
      tester,
    ) async {
      await _pump(
        tester,
        PostTile(
          post: post(_both, {'Instagram': 'posted', 'TikTok': 'failed'}),
        ),
      );
      expect(find.byType(PostTile), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mark-Instagram-posted')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('mark-TikTok-failed')), findsOneWidget);
      expect(find.text('IG'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('platform-marks')));
      await tester.pump();
      expect(
        _t(tester, 'platform-marks-words'),
        'Instagram: posted\nTikTok: failed',
      );
    });

    testWidgets('planned grey, by hand amber; Arabic words', (tester) async {
      expect(platformStateColor('planned'), const Color(0xFF6E6B80));
      expect(platformStateColor('by hand'), const Color(0xFFB7791F));
      expect(platformStateColor('posted'), const Color(0xFF3F8F6B));
      expect(platformStateColor('failed'), const Color(0xFFC0392B));
      await _pump(
        tester,
        PostTile(
          post: post(_both, {'Instagram': 'planned', 'TikTok': 'by hand'}),
        ),
        locale: 'ar',
      );
      await tester.tap(find.byKey(const ValueKey('platform-marks')));
      await tester.pump();
      expect(
        _t(tester, 'platform-marks-words'),
        'Instagram: متجدول\nTikTok: هتتنشر بإيد حد من الفريق',
      );
    });

    testWidgets('empty platforms: no marks, as before', (tester) async {
      await _pump(tester, PostTile(post: post(const [], const {})));
      expect(find.byKey(const ValueKey('platform-marks')), findsNothing);
      await _pump(tester, PostTile(post: post(null, null)));
      expect(find.byKey(const ValueKey('platform-marks')), findsNothing);
    });
  });
}
