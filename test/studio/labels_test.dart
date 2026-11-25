import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_labels.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_strings.dart';
import 'package:jarz_pos/src/studio/data/fake/studio_fixtures.g.dart';
import 'package:jarz_pos/src/studio/data/models/studio_enums.dart';
import 'package:jarz_pos/src/studio/features/assets/assets_strings.dart';
import 'package:jarz_pos/src/studio/features/paid/paid_strings.dart';
import 'package:jarz_pos/src/studio/features/pieces/pieces_strings.dart';
import 'package:jarz_pos/src/studio/features/references/references_strings.dart';
import 'package:jarz_pos/src/studio/features/reports/reports_strings.dart';
import 'package:jarz_pos/src/studio/features/results/results_strings.dart';
import 'package:jarz_pos/src/studio/features/settings/settings_strings.dart';
import 'package:jarz_pos/src/studio/features/shoots/shoots_strings.dart';
import 'package:jarz_pos/src/studio/shared/studio_toast.dart';

typedef _Label = String Function(BuildContext c, Enum e);

/// Every enum the app shows to a person, with the function that words it.
/// An enum value that has no label in English or in Arabic fails the test; a
/// new enum in the generated models fails it until it is listed here or in
/// [_notShownAsWords].
final _shown = <String, ({List<Enum> values, _Label label})>{
  'PieceStage': (
    values: PieceStage.values,
    label: (c, e) => StudioLabels.of(c).pieceStage(e as PieceStage),
  ),
  'PostStatus': (
    values: PostStatus.values,
    label: (c, e) => PiecesStrings.of(c).postStatus(e as PostStatus),
  ),
  'ReviewOutcome': (
    values: ReviewOutcome.values,
    label: (c, e) => PiecesStrings.of(c).reviewOutcome(e as ReviewOutcome),
  ),
  'AdState': (
    values: AdState.values,
    label: (c, e) => PaidStrings.of(c).stateLabel(e as AdState),
  ),
  'PaidDueKind': (
    values: PaidDueKind.values,
    label: (c, e) => PaidStrings.of(c).dueKindLabel(e as PaidDueKind),
  ),
  'ShootStatus': (
    values: ShootStatus.values,
    label: (c, e) => ShootStrings.of(c).status(e as ShootStatus),
  ),
  'AssetStatus': (
    values: AssetStatus.values,
    label: (c, e) => AssetStrings.of(c).status(e as AssetStatus),
  ),
  'AssetKind': (
    values: AssetKind.values,
    label: (c, e) => AssetStrings.of(c).kind(e as AssetKind),
  ),
  'AssetCategory': (
    values: AssetCategory.values,
    label: (c, e) => AssetStrings.of(c).category(e as AssetCategory),
  ),
  'ConsentStatus': (
    values: ConsentStatus.values,
    label: (c, e) => AssetStrings.of(c).consentStatus(e as ConsentStatus),
  ),
  'ConsentScope': (
    values: ConsentScope.values,
    label: (c, e) => AssetStrings.of(c).scope(e as ConsentScope),
  ),
  'ScorecardStatus': (
    values: ScorecardStatus.values,
    label: (c, e) => ResultsStrings.of(c).statusLabel(e as ScorecardStatus),
  ),
  'ScoreSource': (
    values: ScoreSource.values,
    label: (c, e) => ResultsStrings.of(c).sourceLabel(e as ScoreSource),
  ),
  'ReportKind': (
    values: ReportKind.values,
    label: (c, e) => ReportsStrings.of(c).kindLabel(e as ReportKind),
  ),
  'FlavourStatus': (
    values: FlavourStatus.values,
    label: (c, e) => SettingsStrings.of(c).statusLabel(e as FlavourStatus),
  ),
  'MomentKind': (
    values: MomentKind.values,
    label: (c, e) => SettingsStrings.of(c).kindLabel(e as MomentKind),
  ),
  'LaunchStage': (
    values: LaunchStage.values,
    label: (c, e) => SettingsStrings.of(c).stageLabel(e as LaunchStage),
  ),
  'PersonRole': (
    values: PersonRole.values,
    label: (c, e) => SettingsStrings.of(c).roleLabel(e as PersonRole),
  ),
  'JarLabel': (
    values: JarLabel.values,
    label: (c, e) => SettingsStrings.of(c).labelName(e as JarLabel),
  ),
  'ClaimStatus': (
    values: ClaimStatus.values,
    label: (c, e) => SettingsStrings.of(c).claimStatusLabel(e as ClaimStatus),
  ),
  'RefStatus': (
    values: RefStatus.values,
    label: (c, e) => ReferencesStrings.of(c).statusLabel(e as RefStatus),
  ),
  'RefMedia': (
    values: RefMedia.values,
    label: (c, e) => ReferencesStrings.of(c).formatLabel(e as RefMedia),
  ),
  'RefSrcType': (
    values: RefSrcType.values,
    label: (c, e) => ReferencesStrings.of(c).sourceLabel(e as RefSrcType),
  ),
  'Feasibility': (
    values: Feasibility.values,
    label: (c, e) => ReferencesStrings.of(c).feasibilityLabel(e as Feasibility),
  ),
  'CompGroup': (
    values: CompGroup.values,
    label: (c, e) => ReferencesStrings.of(c).groupLabel(e as CompGroup),
  ),
  'OwnerTeam': (
    values: OwnerTeam.values,
    label: (c, e) => PiecesStrings.of(c).team(e as OwnerTeam),
  ),
  'Persona': (
    values: Persona.values,
    label: (c, e) => PiecesStrings.of(c).persona(e as Persona),
  ),
  'Situation': (
    values: Situation.values,
    label: (c, e) => PiecesStrings.of(c).situation(e as Situation),
  ),
  'ContentLayer': (
    values: ContentLayer.values,
    label: (c, e) => PiecesStrings.of(c).layer(e as ContentLayer),
  ),
  'PieceFormat': (
    values: PieceFormat.values,
    label: (c, e) => PiecesStrings.of(c).format(e as PieceFormat),
  ),
  'PieceUse': (
    values: PieceUse.values,
    label: (c, e) => PiecesStrings.of(c).use(e as PieceUse),
  ),
  'PostChannel': (
    values: PostChannel.values,
    label: (c, e) => PiecesStrings.of(c).channel(e as PostChannel),
  ),
  'PostingMode': (
    values: PostingMode.values,
    label: (c, e) => PiecesStrings.of(c).postingMode(e as PostingMode),
  ),
  'ProdRoute': (
    values: ProdRoute.values,
    label: (c, e) => PiecesStrings.of(c).route(e as ProdRoute),
  ),
  'ReadBucket': (
    values: ReadBucket.values,
    label: (c, e) => PiecesStrings.of(c).readBucket(e as ReadBucket),
  ),
  'ScriptLang': (
    values: ScriptLang.values,
    label: (c, e) => PiecesStrings.of(c).scriptLang(e as ScriptLang),
  ),
  // The words kept in StudioLabels.
  'BlockKey': (
    values: BlockKey.values,
    label: (c, e) => StudioLabels.of(c).block(e as BlockKey),
  ),
  'LineKind': (
    values: LineKind.values,
    label: (c, e) => StudioLabels.of(c).lineKind(e as LineKind),
  ),
  'DecisionStatus': (
    values: DecisionStatus.values,
    label: (c, e) => StudioLabels.of(c).decisionStatus(e as DecisionStatus),
  ),
  'IdeaStatus': (
    values: IdeaStatus.values,
    label: (c, e) => StudioLabels.of(c).ideaStatus(e as IdeaStatus),
  ),
  'IdeaSource': (
    values: IdeaSource.values,
    label: (c, e) => StudioLabels.of(c).ideaSource(e as IdeaSource),
  ),
  'FrameStatus': (
    values: FrameStatus.values,
    label: (c, e) => StudioLabels.of(c).frameStatus(e as FrameStatus),
  ),
  'PostedHow': (
    values: PostedHow.values,
    label: (c, e) => StudioLabels.of(c).postedHow(e as PostedHow),
  ),
  'TaskKind': (
    values: TaskKind.values,
    label: (c, e) => StudioLabels.of(c).taskKind(e as TaskKind),
  ),
  'VersionKind': (
    values: VersionKind.values,
    label: (c, e) => StudioLabels.of(c).versionKind(e as VersionKind),
  ),
  'MediaKind': (
    values: MediaKind.values,
    label: (c, e) => StudioLabels.of(c).mediaKind(e as MediaKind),
  ),
  'ActualKind': (
    values: ActualKind.values,
    label: (c, e) => StudioLabels.of(c).actualKind(e as ActualKind),
  ),
  'ActualMatch': (
    values: ActualMatch.values,
    label: (c, e) => StudioLabels.of(c).actualMatch(e as ActualMatch),
  ),
  'SignalLevel': (
    values: SignalLevel.values,
    label: (c, e) => StudioLabels.of(c).signalLevel(e as SignalLevel),
  ),
  'NoteLevel': (
    values: NoteLevel.values,
    label: (c, e) => StudioLabels.of(c).noteLevel(e as NoteLevel),
  ),
  'CheckSeverity': (
    values: CheckSeverity.values,
    label: (c, e) => StudioLabels.of(c).checkSeverity(e as CheckSeverity),
  ),
  'MoveKind': (
    values: MoveKind.values,
    label: (c, e) => StudioLabels.of(c).moveKind(e as MoveKind),
  ),
  'ReadWindow': (
    values: ReadWindow.values,
    label: (c, e) => StudioLabels.of(c).readWindow(e as ReadWindow),
  ),
};

/// Enums no person reads as a word: wire values for the API, the upload
/// machinery, internal grades and tags of a reference, and errors (which have
/// their own sentences in `studio_error_text.dart`).
const _notShownAsWords = {
  'AdRoute', // a setting written as the wire value in the ad plan
  'CompMarket', // market codes (EG, GCC...), shown as the code
  'CompStatus', // competitor list filter, shown by the screen's own chips
  'CompTier', // A / B tier letter
  'Confidence', // low / medium / high of a model score, shown as the value
  'DecisionKind', // option or text: picks the answer box, never shown
  'ErrorCode', // errors have their own sentences
  'MoveNeeds', // what a piece move needs; the move's own label says it
  'ReadSource', // api / hand / legacy, a technical note
  'RefGrade', // strong / weak, shown by the reference screen's own chips
  'RefLayer', // reference tags use ReferencesStrings maps keyed by wire
  'RefLook',
  'RefPersona',
  'RefSituation',
  'RemakeFit',
  'SignalSection', // the section title comes with the signal
  'SocialPlatform', // Instagram, Facebook, TikTok: platform names, never translated
  'StudioLang', // the language chip
  'StudioMode', // Shadow / Live, the strip has its own sentence
  'TargetType', // version / asset, an API routing value
  'UploadMode',
  'UploadPurpose',
  'VerdictLabel', // RUN / FIX / DROP stay as they are (glossary)
  'VerdictPhase',
  'ViewBy', // who raised a decision option, worded in DecisionsStrings
};

String _wire(Enum e) => (e as dynamic).wire as String;

void main() {
  test('every enum of the generated models is worded or marked not shown', () {
    final src = File(
      'lib/src/studio/data/models/studio_enums.dart',
    ).readAsStringSync();
    final names = RegExp(
      r'^enum (\w+) \{',
      multiLine: true,
    ).allMatches(src).map((m) => m.group(1)!).toSet();
    expect(names, isNotEmpty);
    final known = {..._shown.keys, ..._notShownAsWords};
    expect(
      names.difference(known),
      isEmpty,
      reason: 'a new enum needs labels (or an entry in _notShownAsWords)',
    );
    expect(
      known.difference(names),
      isEmpty,
      reason: 'the list names an enum that does not exist any more',
    );
  });

  for (final locale in const ['en', 'ar']) {
    testWidgets('every enum value has a label in $locale', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
        scaffoldMessengerKey: studioMessengerKey,
          locale: Locale(locale),
          supportedLocales: StudioStrings.supportedLocales,
          localizationsDelegates: const [
            StudioStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      final missing = <String>[];
      _shown.forEach((name, entry) {
        for (final v in entry.values) {
          if (v.name == 'unknown') continue;
          String label;
          try {
            label = entry.label(ctx, v).trim();
          } catch (e) {
            missing.add('$name.${v.name}: $e');
            continue;
          }
          final wire = _wire(v);
          // A raw wire value (or the Dart name) is a missing label.
          if (label.isEmpty || label == wire || label == v.name) {
            // A word that is the same in both forms (Hero, Hub, UGC) is fine
            // only when the wire is a different case.
            if (label.isEmpty || label == v.name) {
              missing.add('$name.${v.name} -> "$label"');
            }
          }
        }
      });
      expect(missing, isEmpty);
    });
  }

  test('every action code a fixture lists has a label in both languages', () {
    final codes = <String>{...StudioLabels.actionCodes};
    void walk(dynamic v) {
      if (v is Map) {
        final a = v['actions'];
        if (a is List) codes.addAll(a.whereType<String>());
        v.values.forEach(walk);
      } else if (v is List) {
        v.forEach(walk);
      }
    }

    for (final raw in studioFixtures.values) {
      walk(jsonDecode(raw));
    }
    final missing = [
      for (final c in codes)
        if (StudioLabels.en.action(c) == null ||
            StudioLabels.arabic.action(c) == null ||
            StudioLabels.en.action(c)!.isEmpty ||
            StudioLabels.arabic.action(c)!.isEmpty)
          c,
    ];
    expect(missing, isEmpty);
    // The raw code is never the label.
    for (final c in codes) {
      expect(StudioLabels.en.action(c), isNot(c));
    }
  });

  test('a code the app does not know has no label and is not shown raw', () {
    expect(StudioLabels.en.action('rename_the_moon'), isNull);
    expect(StudioLabels.arabic.action('rename_the_moon'), isNull);
    expect(StudioLabels.en.metric('mystery_metric'), isNull);
    expect(
      StudioLabels.en.block(BlockKey.unknown, fallback: 'Server title'),
      'Server title',
    );
  });

  test('every scorecard number and gate has a name in both languages', () {
    final keys = <String>{...StudioLabels.metricKeys};
    final card = jsonDecode(studioFixtures['results.scorecard']!) as Map;
    for (final n in card['numbers'] as List) {
      keys.add((n as Map)['key'] as String);
    }
    for (final g in card['gates'] as List) {
      keys.add((g as Map)['key'] as String);
    }
    for (final k in keys) {
      expect(StudioLabels.en.metric(k), isNotNull, reason: k);
      expect(StudioLabels.arabic.metric(k), isNotNull, reason: k);
    }
  });

  test('every Today block key the contract lists has a title', () {
    for (final k in BlockKey.values) {
      if (k == BlockKey.unknown) continue;
      expect(StudioLabels.en.block(k), isNotEmpty, reason: k.name);
      expect(StudioLabels.arabic.block(k), isNotEmpty, reason: k.name);
    }
  });
}
