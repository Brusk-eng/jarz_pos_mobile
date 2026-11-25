// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'studio_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PersonRefImpl _$$PersonRefImplFromJson(Map<String, dynamic> json) =>
    _$PersonRefImpl(
      key: json['key'] as String,
      fullName: json['full_name'] as String,
    );

Map<String, dynamic> _$$PersonRefImplToJson(_$PersonRefImpl instance) =>
    <String, dynamic>{'key': instance.key, 'full_name': instance.fullName};

_$FlavourRefImpl _$$FlavourRefImplFromJson(Map<String, dynamic> json) =>
    _$FlavourRefImpl(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$$FlavourRefImplToJson(_$FlavourRefImpl instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_$DocRefImpl _$$DocRefImplFromJson(Map<String, dynamic> json) => _$DocRefImpl(
  doctype: json['doctype'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$$DocRefImplToJson(_$DocRefImpl instance) =>
    <String, dynamic>{'doctype': instance.doctype, 'name': instance.name};

_$StudioProblemImpl _$$StudioProblemImplFromJson(Map<String, dynamic> json) =>
    _$StudioProblemImpl(
      code: json['code'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$$StudioProblemImplToJson(_$StudioProblemImpl instance) =>
    <String, dynamic>{'code': instance.code, 'message': instance.message};

_$StudioMediaImpl _$$StudioMediaImplFromJson(Map<String, dynamic> json) =>
    _$StudioMediaImpl(
      id: json['id'] as String,
      kind: $enumDecode(
        _$MediaKindEnumMap,
        json['kind'],
        unknownValue: MediaKind.unknown,
      ),
      thumbUrl: json['thumb_url'] as String?,
      posterUrl: json['poster_url'] as String?,
      feedUrl: json['feed_url'] as String?,
      url: json['url'] as String,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      durationS: (json['duration_s'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$StudioMediaImplToJson(_$StudioMediaImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$MediaKindEnumMap[instance.kind]!,
      'thumb_url': instance.thumbUrl,
      'poster_url': instance.posterUrl,
      'feed_url': instance.feedUrl,
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
      'duration_s': instance.durationS,
    };

const _$MediaKindEnumMap = {
  MediaKind.image: 'image',
  MediaKind.video: 'video',
  MediaKind.audio: 'audio',
  MediaKind.unknown: '__unknown__',
};

_$NavItemImpl _$$NavItemImplFromJson(Map<String, dynamic> json) =>
    _$NavItemImpl(
      key: json['key'] as String,
      label: json['label'] as String,
      route: json['route'] as String,
      inBar: json['in_bar'] as bool,
      badge: (json['badge'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$NavItemImplToJson(_$NavItemImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'route': instance.route,
      'in_bar': instance.inBar,
      'badge': instance.badge,
    };

_$MeProfileImpl _$$MeProfileImplFromJson(Map<String, dynamic> json) =>
    _$MeProfileImpl(
      user: json['user'] as String,
      fullName: json['full_name'] as String,
      roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
      isFounder: json['is_founder'] as bool,
      mode: $enumDecode(
        _$StudioModeEnumMap,
        json['mode'],
        unknownValue: StudioMode.unknown,
      ),
      serverTime: json['server_time'] as String,
      person: json['person'] == null
          ? null
          : PersonRef.fromJson(json['person'] as Map<String, dynamic>),
      studioRole: $enumDecodeNullable(
        _$PersonRoleEnumMap,
        json['studio_role'],
        unknownValue: PersonRole.unknown,
      ),
      homeRoute: json['home_route'] as String,
      nav: (json['nav'] as List<dynamic>)
          .map((e) => NavItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      seenHelp: (json['seen_help'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$MeProfileImplToJson(_$MeProfileImpl instance) =>
    <String, dynamic>{
      'user': instance.user,
      'full_name': instance.fullName,
      'roles': instance.roles,
      'is_founder': instance.isFounder,
      'mode': _$StudioModeEnumMap[instance.mode]!,
      'server_time': instance.serverTime,
      'person': instance.person?.toJson(),
      'studio_role': _$PersonRoleEnumMap[instance.studioRole],
      'home_route': instance.homeRoute,
      'nav': instance.nav.map((e) => e.toJson()).toList(),
      'seen_help': instance.seenHelp,
    };

const _$StudioModeEnumMap = {
  StudioMode.shadow: 'Shadow',
  StudioMode.live: 'Live',
  StudioMode.unknown: '__unknown__',
};

const _$PersonRoleEnumMap = {
  PersonRole.founder: 'Founder',
  PersonRole.marketingLead: 'Marketing Lead',
  PersonRole.creator: 'Creator',
  PersonRole.storyLead: 'Story Lead',
  PersonRole.moderator: 'Moderator',
  PersonRole.unknown: '__unknown__',
};

_$HelpSeenImpl _$$HelpSeenImplFromJson(Map<String, dynamic> json) =>
    _$HelpSeenImpl(
      seenHelp: (json['seen_help'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$HelpSeenImplToJson(_$HelpSeenImpl instance) =>
    <String, dynamic>{'seen_help': instance.seenHelp};

_$OkResultImpl _$$OkResultImplFromJson(Map<String, dynamic> json) =>
    _$OkResultImpl(ok: json['ok'] as bool);

Map<String, dynamic> _$$OkResultImplToJson(_$OkResultImpl instance) =>
    <String, dynamic>{'ok': instance.ok};

_$SkipItemImpl _$$SkipItemImplFromJson(Map<String, dynamic> json) =>
    _$SkipItemImpl(
      index: (json['index'] as num).toInt(),
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$$SkipItemImplToJson(_$SkipItemImpl instance) =>
    <String, dynamic>{'index': instance.index, 'reason': instance.reason};

_$VerdictBriefImpl _$$VerdictBriefImplFromJson(Map<String, dynamic> json) =>
    _$VerdictBriefImpl(
      label: $enumDecode(
        _$VerdictLabelEnumMap,
        json['label'],
        unknownValue: VerdictLabel.unknown,
      ),
      phase: $enumDecode(
        _$VerdictPhaseEnumMap,
        json['phase'],
        unknownValue: VerdictPhase.unknown,
      ),
      stale: json['stale'] as bool,
      sell: (json['sell'] as num?)?.toDouble(),
      pct: (json['pct'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$VerdictBriefImplToJson(_$VerdictBriefImpl instance) =>
    <String, dynamic>{
      'label': _$VerdictLabelEnumMap[instance.label]!,
      'phase': _$VerdictPhaseEnumMap[instance.phase]!,
      'stale': instance.stale,
      'sell': instance.sell,
      'pct': instance.pct,
    };

const _$VerdictLabelEnumMap = {
  VerdictLabel.rUN: 'RUN',
  VerdictLabel.fIX: 'FIX',
  VerdictLabel.dROP: 'DROP',
  VerdictLabel.bLOCKED: 'BLOCKED',
  VerdictLabel.unknown: '__unknown__',
};

const _$VerdictPhaseEnumMap = {
  VerdictPhase.script: 'script',
  VerdictPhase.finalValue: 'final',
  VerdictPhase.unknown: '__unknown__',
};

_$VersionBriefImpl _$$VersionBriefImplFromJson(Map<String, dynamic> json) =>
    _$VersionBriefImpl(
      id: json['id'] as String,
      versionNo: (json['version_no'] as num).toInt(),
      kind: $enumDecode(
        _$VersionKindEnumMap,
        json['kind'],
        unknownValue: VersionKind.unknown,
      ),
      reviewOutcome: $enumDecodeNullable(
        _$ReviewOutcomeEnumMap,
        json['review_outcome'],
        unknownValue: ReviewOutcome.unknown,
      ),
      awaitingReview: json['awaiting_review'] as bool,
      isCurrent: json['is_current'] as bool,
      thumb: json['thumb'] == null
          ? null
          : StudioMedia.fromJson(json['thumb'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$VersionBriefImplToJson(_$VersionBriefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version_no': instance.versionNo,
      'kind': _$VersionKindEnumMap[instance.kind]!,
      'review_outcome': _$ReviewOutcomeEnumMap[instance.reviewOutcome],
      'awaiting_review': instance.awaitingReview,
      'is_current': instance.isCurrent,
      'thumb': instance.thumb?.toJson(),
    };

const _$VersionKindEnumMap = {
  VersionKind.video: 'video',
  VersionKind.staticValue: 'static',
  VersionKind.carousel: 'carousel',
  VersionKind.story: 'story',
  VersionKind.unknown: '__unknown__',
};

const _$ReviewOutcomeEnumMap = {
  ReviewOutcome.approved: 'Approved',
  ReviewOutcome.fix: 'Fix',
  ReviewOutcome.unknown: '__unknown__',
};

_$PostBriefImpl _$$PostBriefImplFromJson(Map<String, dynamic> json) =>
    _$PostBriefImpl(
      id: json['id'] as String,
      channel: $enumDecodeNullable(
        _$PostChannelEnumMap,
        json['channel'],
        unknownValue: PostChannel.unknown,
      ),
      slotTime: json['slot_time'] as String?,
      status: $enumDecode(
        _$PostStatusEnumMap,
        json['status'],
        unknownValue: PostStatus.unknown,
      ),
      postingMode: $enumDecodeNullable(
        _$PostingModeEnumMap,
        json['posting_mode'],
        unknownValue: PostingMode.unknown,
      ),
    );

Map<String, dynamic> _$$PostBriefImplToJson(_$PostBriefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'channel': _$PostChannelEnumMap[instance.channel],
      'slot_time': instance.slotTime,
      'status': _$PostStatusEnumMap[instance.status]!,
      'posting_mode': _$PostingModeEnumMap[instance.postingMode],
    };

const _$PostChannelEnumMap = {
  PostChannel.feedReel: 'Feed reel',
  PostChannel.trialReel: 'Trial reel',
  PostChannel.trialReelFeed: 'Trial reel → feed',
  PostChannel.feedStatic: 'Feed static',
  PostChannel.feedCarousel: 'Feed carousel',
  PostChannel.tikTok: 'TikTok',
  PostChannel.story: 'Story',
  PostChannel.unknown: '__unknown__',
};

const _$PostStatusEnumMap = {
  PostStatus.draft: 'Draft',
  PostStatus.checked: 'Checked',
  PostStatus.scheduled: 'Scheduled',
  PostStatus.publishing: 'Publishing',
  PostStatus.published: 'Published',
  PostStatus.failed: 'Failed',
  PostStatus.cancelled: 'Cancelled',
  PostStatus.unknown: '__unknown__',
};

const _$PostingModeEnumMap = {
  PostingMode.bySystem: 'By system',
  PostingMode.byHand: 'By hand',
  PostingMode.unknown: '__unknown__',
};

_$PieceRefImpl _$$PieceRefImplFromJson(Map<String, dynamic> json) =>
    _$PieceRefImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      format: $enumDecode(
        _$PieceFormatEnumMap,
        json['format'],
        unknownValue: PieceFormat.unknown,
      ),
      stage: $enumDecode(
        _$PieceStageEnumMap,
        json['stage'],
        unknownValue: PieceStage.unknown,
      ),
    );

Map<String, dynamic> _$$PieceRefImplToJson(_$PieceRefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'format': _$PieceFormatEnumMap[instance.format]!,
      'stage': _$PieceStageEnumMap[instance.stage]!,
    };

const _$PieceFormatEnumMap = {
  PieceFormat.reel: 'reel',
  PieceFormat.trial: 'trial',
  PieceFormat.staticValue: 'static',
  PieceFormat.carousel: 'carousel',
  PieceFormat.story: 'story',
  PieceFormat.unknown: '__unknown__',
};

const _$PieceStageEnumMap = {
  PieceStage.idea: 'Idea',
  PieceStage.script: 'Script',
  PieceStage.toShoot: 'To shoot',
  PieceStage.toEdit: 'To edit',
  PieceStage.inReview: 'In review',
  PieceStage.approved: 'Approved',
  PieceStage.scheduled: 'Scheduled',
  PieceStage.posted: 'Posted',
  PieceStage.read: 'Read',
  PieceStage.unknown: '__unknown__',
};

_$BlockedImpl _$$BlockedImplFromJson(Map<String, dynamic> json) =>
    _$BlockedImpl(
      waitsOn: json['waits_on'] as String,
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$$BlockedImplToJson(_$BlockedImpl instance) =>
    <String, dynamic>{'waits_on': instance.waitsOn, 'reason': instance.reason};

_$PieceSummaryImpl _$$PieceSummaryImplFromJson(
  Map<String, dynamic> json,
) => _$PieceSummaryImpl(
  id: json['id'] as String,
  legacyId: json['legacy_id'] as String?,
  title: json['title'] as String,
  titleAr: json['title_ar'] as String?,
  format: $enumDecode(
    _$PieceFormatEnumMap,
    json['format'],
    unknownValue: PieceFormat.unknown,
  ),
  use: $enumDecodeNullable(
    _$PieceUseEnumMap,
    json['use'],
    unknownValue: PieceUse.unknown,
  ),
  stage: $enumDecode(
    _$PieceStageEnumMap,
    json['stage'],
    unknownValue: PieceStage.unknown,
  ),
  parked: json['parked'] as String?,
  persona: $enumDecodeNullable(
    _$PersonaEnumMap,
    json['persona'],
    unknownValue: Persona.unknown,
  ),
  situation: $enumDecodeNullable(
    _$SituationEnumMap,
    json['situation'],
    unknownValue: Situation.unknown,
  ),
  layer: $enumDecodeNullable(
    _$ContentLayerEnumMap,
    json['layer'],
    unknownValue: ContentLayer.unknown,
  ),
  level: (json['level'] as num?)?.toInt(),
  series: json['series'] as String?,
  flavours: (json['flavours'] as List<dynamic>)
      .map((e) => FlavourRef.fromJson(e as Map<String, dynamic>))
      .toList(),
  noFlavour: json['no_flavour'] as bool,
  assignee: json['assignee'] == null
      ? null
      : PersonRef.fromJson(json['assignee'] as Map<String, dynamic>),
  assigneeTeam: $enumDecodeNullable(
    _$OwnerTeamEnumMap,
    json['assignee_team'],
    unknownValue: OwnerTeam.unknown,
  ),
  dueDate: json['due_date'] as String?,
  picture: json['picture'] == null
      ? null
      : StudioMedia.fromJson(json['picture'] as Map<String, dynamic>),
  verdict: json['verdict'] == null
      ? null
      : VerdictBrief.fromJson(json['verdict'] as Map<String, dynamic>),
  currentVersion: json['current_version'] == null
      ? null
      : VersionBrief.fromJson(json['current_version'] as Map<String, dynamic>),
  nextPost: json['next_post'] == null
      ? null
      : PostBrief.fromJson(json['next_post'] as Map<String, dynamic>),
  paidState: json['paid_state'] as String?,
  blocked: json['blocked'] == null
      ? null
      : Blocked.fromJson(json['blocked'] as Map<String, dynamic>),
  modified: json['modified'] as String,
  actions: (json['actions'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$$PieceSummaryImplToJson(_$PieceSummaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'legacy_id': instance.legacyId,
      'title': instance.title,
      'title_ar': instance.titleAr,
      'format': _$PieceFormatEnumMap[instance.format]!,
      'use': _$PieceUseEnumMap[instance.use],
      'stage': _$PieceStageEnumMap[instance.stage]!,
      'parked': instance.parked,
      'persona': _$PersonaEnumMap[instance.persona],
      'situation': _$SituationEnumMap[instance.situation],
      'layer': _$ContentLayerEnumMap[instance.layer],
      'level': instance.level,
      'series': instance.series,
      'flavours': instance.flavours.map((e) => e.toJson()).toList(),
      'no_flavour': instance.noFlavour,
      'assignee': instance.assignee?.toJson(),
      'assignee_team': _$OwnerTeamEnumMap[instance.assigneeTeam],
      'due_date': instance.dueDate,
      'picture': instance.picture?.toJson(),
      'verdict': instance.verdict?.toJson(),
      'current_version': instance.currentVersion?.toJson(),
      'next_post': instance.nextPost?.toJson(),
      'paid_state': instance.paidState,
      'blocked': instance.blocked?.toJson(),
      'modified': instance.modified,
      'actions': instance.actions,
    };

const _$PieceUseEnumMap = {
  PieceUse.feedOnly: 'Feed only',
  PieceUse.feedPaid: 'Feed + paid',
  PieceUse.trialOnly: 'Trial only',
  PieceUse.trialPaid: 'Trial + paid',
  PieceUse.paidOnly: 'Paid only',
  PieceUse.storiesOnly: 'Stories only',
  PieceUse.unknown: '__unknown__',
};

const _$PersonaEnumMap = {
  Persona.household: 'Household',
  Persona.selfTreater: 'Self-treater',
  Persona.unknown: '__unknown__',
};

const _$SituationEnumMap = {
  Situation.jarsForTheHouse: 'Jars for the house',
  Situation.oneJarForMe: 'One jar for me',
  Situation.guestsAreComing: 'Guests are coming',
  Situation.aGiftToSend: 'A gift to send',
  Situation.officeLunch: 'Office lunch',
  Situation.other: 'Other',
  Situation.unknown: '__unknown__',
};

const _$ContentLayerEnumMap = {
  ContentLayer.hero: 'Hero',
  ContentLayer.hub: 'Hub',
  ContentLayer.hygiene: 'Hygiene',
  ContentLayer.unknown: '__unknown__',
};

const _$OwnerTeamEnumMap = {
  OwnerTeam.creators: 'creators',
  OwnerTeam.claude: 'claude',
  OwnerTeam.unknown: '__unknown__',
};

_$ScriptLineImpl _$$ScriptLineImplFromJson(Map<String, dynamic> json) =>
    _$ScriptLineImpl(
      lang: $enumDecode(
        _$ScriptLangEnumMap,
        json['lang'],
        unknownValue: ScriptLang.unknown,
      ),
      t: json['t'] as String?,
      line: json['line'] as String,
    );

Map<String, dynamic> _$$ScriptLineImplToJson(_$ScriptLineImpl instance) =>
    <String, dynamic>{
      'lang': _$ScriptLangEnumMap[instance.lang]!,
      't': instance.t,
      'line': instance.line,
    };

const _$ScriptLangEnumMap = {
  ScriptLang.ar: 'ar',
  ScriptLang.en: 'en',
  ScriptLang.broll: 'broll',
  ScriptLang.unknown: '__unknown__',
};

_$ScriptImpl _$$ScriptImplFromJson(Map<String, dynamic> json) => _$ScriptImpl(
  length: json['length'] as String?,
  opening: json['opening'] as String?,
  screenAr: json['screen_ar'] as String?,
  screenEn: json['screen_en'] as String?,
  block: json['block'] as String?,
  holds: (json['holds'] as List<dynamic>).map((e) => e as String).toList(),
  notes: json['notes'] as String?,
  lines: (json['lines'] as List<dynamic>)
      .map((e) => ScriptLine.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$ScriptImplToJson(_$ScriptImpl instance) =>
    <String, dynamic>{
      'length': instance.length,
      'opening': instance.opening,
      'screen_ar': instance.screenAr,
      'screen_en': instance.screenEn,
      'block': instance.block,
      'holds': instance.holds,
      'notes': instance.notes,
      'lines': instance.lines.map((e) => e.toJson()).toList(),
    };

_$AdBriefImpl _$$AdBriefImplFromJson(Map<String, dynamic> json) =>
    _$AdBriefImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      roundCode: json['round_code'] as String?,
      state: $enumDecodeNullable(
        _$AdStateEnumMap,
        json['state'],
        unknownValue: AdState.unknown,
      ),
      thumb: json['thumb'] == null
          ? null
          : StudioMedia.fromJson(json['thumb'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AdBriefImplToJson(_$AdBriefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'round_code': instance.roundCode,
      'state': _$AdStateEnumMap[instance.state],
      'thumb': instance.thumb?.toJson(),
    };

const _$AdStateEnumMap = {
  AdState.queued: 'Queued',
  AdState.testing: 'Testing',
  AdState.winner: 'Winner',
  AdState.oneMoreRound: 'One more round',
  AdState.off: 'Off',
  AdState.inScale: 'In scale',
  AdState.unknown: '__unknown__',
};

_$ShotBriefImpl _$$ShotBriefImplFromJson(Map<String, dynamic> json) =>
    _$ShotBriefImpl(
      id: json['id'] as String,
      shootId: json['shoot_id'] as String,
      shootTitle: json['shoot_title'] as String,
      shootDate: json['shoot_date'] as String?,
      what: json['what'] as String,
      done: json['done'] as bool,
    );

Map<String, dynamic> _$$ShotBriefImplToJson(_$ShotBriefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shoot_id': instance.shootId,
      'shoot_title': instance.shootTitle,
      'shoot_date': instance.shootDate,
      'what': instance.what,
      'done': instance.done,
    };

_$HistoryItemImpl _$$HistoryItemImplFromJson(Map<String, dynamic> json) =>
    _$HistoryItemImpl(
      at: json['at'] as String,
      by: PersonRef.fromJson(json['by'] as Map<String, dynamic>),
      field: json['field'] as String,
      old: json['old'] as String?,
      newValue: json['new'] as String?,
      summary: json['summary'] as String,
    );

Map<String, dynamic> _$$HistoryItemImplToJson(_$HistoryItemImpl instance) =>
    <String, dynamic>{
      'at': instance.at,
      'by': instance.by.toJson(),
      'field': instance.field,
      'old': instance.old,
      'new': instance.newValue,
      'summary': instance.summary,
    };

_$MoveImpl _$$MoveImplFromJson(Map<String, dynamic> json) => _$MoveImpl(
  to: $enumDecode(
    _$PieceStageEnumMap,
    json['to'],
    unknownValue: PieceStage.unknown,
  ),
  kind: $enumDecode(
    _$MoveKindEnumMap,
    json['kind'],
    unknownValue: MoveKind.unknown,
  ),
  label: json['label'] as String,
  enabled: json['enabled'] as bool,
  problems: (json['problems'] as List<dynamic>)
      .map((e) => StudioProblem.fromJson(e as Map<String, dynamic>))
      .toList(),
  needs: $enumDecode(
    _$MoveNeedsEnumMap,
    json['needs'],
    unknownValue: MoveNeeds.unknown,
  ),
);

Map<String, dynamic> _$$MoveImplToJson(_$MoveImpl instance) =>
    <String, dynamic>{
      'to': _$PieceStageEnumMap[instance.to]!,
      'kind': _$MoveKindEnumMap[instance.kind]!,
      'label': instance.label,
      'enabled': instance.enabled,
      'problems': instance.problems.map((e) => e.toJson()).toList(),
      'needs': _$MoveNeedsEnumMap[instance.needs]!,
    };

const _$MoveKindEnumMap = {
  MoveKind.forward: 'forward',
  MoveKind.back: 'back',
  MoveKind.unknown: '__unknown__',
};

const _$MoveNeedsEnumMap = {
  MoveNeeds.none: '',
  MoveNeeds.reason: 'reason',
  MoveNeeds.skipShootReason: 'skip_shoot_reason',
  MoveNeeds.unknown: '__unknown__',
};

_$GateCheckItemImpl _$$GateCheckItemImplFromJson(Map<String, dynamic> json) =>
    _$GateCheckItemImpl(
      key: json['key'] as String,
      label: json['label'] as String,
      ok: json['ok'] as bool,
      detail: json['detail'] as String?,
    );

Map<String, dynamic> _$$GateCheckItemImplToJson(_$GateCheckItemImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'ok': instance.ok,
      'detail': instance.detail,
    };

_$GateResultImpl _$$GateResultImplFromJson(Map<String, dynamic> json) =>
    _$GateResultImpl(
      ok: json['ok'] as bool,
      versionId: json['version_id'] as String?,
      captionHash: json['caption_hash'] as String?,
      checks: (json['checks'] as List<dynamic>)
          .map((e) => GateCheckItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      fails: (json['fails'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$GateResultImplToJson(_$GateResultImpl instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'version_id': instance.versionId,
      'caption_hash': instance.captionHash,
      'checks': instance.checks.map((e) => e.toJson()).toList(),
      'fails': instance.fails,
    };

_$PieceVerdictImpl _$$PieceVerdictImplFromJson(Map<String, dynamic> json) =>
    _$PieceVerdictImpl(
      id: json['id'] as String,
      pieceId: json['piece_id'] as String,
      versionId: json['version_id'] as String?,
      phase: $enumDecode(
        _$VerdictPhaseEnumMap,
        json['phase'],
        unknownValue: VerdictPhase.unknown,
      ),
      verdict: $enumDecode(
        _$VerdictLabelEnumMap,
        json['verdict'],
        unknownValue: VerdictLabel.unknown,
      ),
      sell: (json['sell'] as num?)?.toDouble(),
      pct: (json['pct'] as num?)?.toDouble(),
      conf: $enumDecodeNullable(
        _$ConfidenceEnumMap,
        json['conf'],
        unknownValue: Confidence.unknown,
      ),
      judgedOn: json['judged_on'] as String,
      why: json['why'] as String?,
      stops: json['stops'] as String?,
      fixes: (json['fixes'] as List<dynamic>).map((e) => e as String).toList(),
      stale: json['stale'] as bool,
      by: json['by'] as String,
      batch: json['batch'] as String?,
    );

Map<String, dynamic> _$$PieceVerdictImplToJson(_$PieceVerdictImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'piece_id': instance.pieceId,
      'version_id': instance.versionId,
      'phase': _$VerdictPhaseEnumMap[instance.phase]!,
      'verdict': _$VerdictLabelEnumMap[instance.verdict]!,
      'sell': instance.sell,
      'pct': instance.pct,
      'conf': _$ConfidenceEnumMap[instance.conf],
      'judged_on': instance.judgedOn,
      'why': instance.why,
      'stops': instance.stops,
      'fixes': instance.fixes,
      'stale': instance.stale,
      'by': instance.by,
      'batch': instance.batch,
    };

const _$ConfidenceEnumMap = {
  Confidence.low: 'low',
  Confidence.medium: 'medium',
  Confidence.high: 'high',
  Confidence.unknown: '__unknown__',
};

_$RatingStatsImpl _$$RatingStatsImplFromJson(Map<String, dynamic> json) =>
    _$RatingStatsImpl(
      n: (json['n'] as num).toInt(),
      avg: (json['avg'] as num).toDouble(),
      sd: (json['sd'] as num).toDouble(),
      distribution: (json['distribution'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      withComment: (json['with_comment'] as num).toInt(),
      waiting: (json['waiting'] as List<dynamic>)
          .map((e) => PersonRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$RatingStatsImplToJson(_$RatingStatsImpl instance) =>
    <String, dynamic>{
      'n': instance.n,
      'avg': instance.avg,
      'sd': instance.sd,
      'distribution': instance.distribution,
      'with_comment': instance.withComment,
      'waiting': instance.waiting.map((e) => e.toJson()).toList(),
    };

_$RatingImpl _$$RatingImplFromJson(Map<String, dynamic> json) => _$RatingImpl(
  score: (json['score'] as num).toInt(),
  comment: json['comment'] as String?,
  person: PersonRef.fromJson(json['person'] as Map<String, dynamic>),
  ratedAt: json['rated_at'] as String,
);

Map<String, dynamic> _$$RatingImplToJson(_$RatingImpl instance) =>
    <String, dynamic>{
      'score': instance.score,
      'comment': instance.comment,
      'person': instance.person.toJson(),
      'rated_at': instance.ratedAt,
    };

_$StudioCommentImpl _$$StudioCommentImplFromJson(Map<String, dynamic> json) =>
    _$StudioCommentImpl(
      id: json['id'] as String,
      targetType: $enumDecode(
        _$TargetTypeEnumMap,
        json['target_type'],
        unknownValue: TargetType.unknown,
      ),
      targetId: json['target_id'] as String,
      frame: (json['frame'] as num?)?.toInt(),
      body: json['body'] as String,
      person: PersonRef.fromJson(json['person'] as Map<String, dynamic>),
      at: json['at'] as String,
    );

Map<String, dynamic> _$$StudioCommentImplToJson(_$StudioCommentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'target_type': _$TargetTypeEnumMap[instance.targetType]!,
      'target_id': instance.targetId,
      'frame': instance.frame,
      'body': instance.body,
      'person': instance.person.toJson(),
      'at': instance.at,
    };

const _$TargetTypeEnumMap = {
  TargetType.version: 'version',
  TargetType.asset: 'asset',
  TargetType.unknown: '__unknown__',
};

_$CommentResultImpl _$$CommentResultImplFromJson(Map<String, dynamic> json) =>
    _$CommentResultImpl(
      comment: StudioComment.fromJson(json['comment'] as Map<String, dynamic>),
      commentsCount: (json['comments_count'] as num).toInt(),
    );

Map<String, dynamic> _$$CommentResultImplToJson(_$CommentResultImpl instance) =>
    <String, dynamic>{
      'comment': instance.comment.toJson(),
      'comments_count': instance.commentsCount,
    };

_$RatingsResultImpl _$$RatingsResultImplFromJson(Map<String, dynamic> json) =>
    _$RatingsResultImpl(
      stats: RatingStats.fromJson(json['stats'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>)
          .map((e) => Rating.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$RatingsResultImplToJson(_$RatingsResultImpl instance) =>
    <String, dynamic>{
      'stats': instance.stats.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

_$AssetBriefImpl _$$AssetBriefImplFromJson(Map<String, dynamic> json) =>
    _$AssetBriefImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      kind: $enumDecode(
        _$AssetKindEnumMap,
        json['kind'],
        unknownValue: AssetKind.unknown,
      ),
      media: json['media'] == null
          ? null
          : StudioMedia.fromJson(json['media'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AssetBriefImplToJson(_$AssetBriefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'kind': _$AssetKindEnumMap[instance.kind]!,
      'media': instance.media?.toJson(),
    };

const _$AssetKindEnumMap = {
  AssetKind.clip: 'Clip',
  AssetKind.photo: 'Photo',
  AssetKind.template: 'Template',
  AssetKind.storyFrame: 'Story frame',
  AssetKind.storyPhoto: 'Story photo',
  AssetKind.kitchenShot: 'Kitchen shot',
  AssetKind.customerContent: 'Customer content',
  AssetKind.oldCreative: 'Old creative',
  AssetKind.unknown: '__unknown__',
};

_$VersionFileImpl _$$VersionFileImplFromJson(Map<String, dynamic> json) =>
    _$VersionFileImpl(
      position: (json['position'] as num).toInt(),
      lang: $enumDecodeNullable(
        _$StudioLangEnumMap,
        json['lang'],
        unknownValue: StudioLang.unknown,
      ),
      media: StudioMedia.fromJson(json['media'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$VersionFileImplToJson(_$VersionFileImpl instance) =>
    <String, dynamic>{
      'position': instance.position,
      'lang': _$StudioLangEnumMap[instance.lang],
      'media': instance.media.toJson(),
    };

const _$StudioLangEnumMap = {
  StudioLang.en: 'en',
  StudioLang.ar: 'ar',
  StudioLang.unknown: '__unknown__',
};

_$StoryFrameImpl _$$StoryFrameImplFromJson(Map<String, dynamic> json) =>
    _$StoryFrameImpl(
      position: (json['position'] as num).toInt(),
      asset: AssetBrief.fromJson(json['asset'] as Map<String, dynamic>),
      status: $enumDecodeNullable(
        _$FrameStatusEnumMap,
        json['status'],
        unknownValue: FrameStatus.unknown,
      ),
      reason: json['reason'] as String?,
      setBy: json['set_by'] == null
          ? null
          : PersonRef.fromJson(json['set_by'] as Map<String, dynamic>),
      setAt: json['set_at'] as String?,
      commentsCount: (json['comments_count'] as num).toInt(),
    );

Map<String, dynamic> _$$StoryFrameImplToJson(_$StoryFrameImpl instance) =>
    <String, dynamic>{
      'position': instance.position,
      'asset': instance.asset.toJson(),
      'status': _$FrameStatusEnumMap[instance.status],
      'reason': instance.reason,
      'set_by': instance.setBy?.toJson(),
      'set_at': instance.setAt,
      'comments_count': instance.commentsCount,
    };

const _$FrameStatusEnumMap = {
  FrameStatus.posted: 'posted',
  FrameStatus.skipped: 'skipped',
  FrameStatus.unknown: '__unknown__',
};

_$PieceVersionImpl _$$PieceVersionImplFromJson(Map<String, dynamic> json) =>
    _$PieceVersionImpl(
      id: json['id'] as String,
      piece: PieceRef.fromJson(json['piece'] as Map<String, dynamic>),
      versionNo: (json['version_no'] as num).toInt(),
      title: json['title'] as String?,
      kind: $enumDecode(
        _$VersionKindEnumMap,
        json['kind'],
        unknownValue: VersionKind.unknown,
      ),
      files: (json['files'] as List<dynamic>)
          .map((e) => VersionFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      frames: (json['frames'] as List<dynamic>)
          .map((e) => StoryFrame.fromJson(e as Map<String, dynamic>))
          .toList(),
      isCurrent: json['is_current'] as bool,
      awaitingReview: json['awaiting_review'] as bool,
      reviewOutcome: $enumDecodeNullable(
        _$ReviewOutcomeEnumMap,
        json['review_outcome'],
        unknownValue: ReviewOutcome.unknown,
      ),
      reviewReason: json['review_reason'] as String?,
      reviewedBy: json['reviewed_by'] == null
          ? null
          : PersonRef.fromJson(json['reviewed_by'] as Map<String, dynamic>),
      reviewedAt: json['reviewed_at'] as String?,
      createdBy: json['created_by'] == null
          ? null
          : PersonRef.fromJson(json['created_by'] as Map<String, dynamic>),
      created: json['created'] as String,
      modified: json['modified'] as String,
      locked: json['locked'] as bool,
      ratingOpen: json['rating_open'] as bool,
      hidden: json['hidden'] as bool,
      readyForAds: json['ready_for_ads'] as bool,
      adRoute: $enumDecodeNullable(
        _$AdRouteEnumMap,
        json['ad_route'],
        unknownValue: AdRoute.unknown,
      ),
      theme: json['theme'] as String?,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      ratePrompt: json['rate_prompt'] as String?,
      teamNote: json['team_note'] as String?,
      rating: RatingStats.fromJson(json['rating'] as Map<String, dynamic>),
      myRating: json['my_rating'] == null
          ? null
          : Rating.fromJson(json['my_rating'] as Map<String, dynamic>),
      commentsCount: (json['comments_count'] as num).toInt(),
      verdict: json['verdict'] == null
          ? null
          : PieceVerdict.fromJson(json['verdict'] as Map<String, dynamic>),
      post: json['post'] == null
          ? null
          : PostBrief.fromJson(json['post'] as Map<String, dynamic>),
      caption: json['caption'] as String?,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$PieceVersionImplToJson(_$PieceVersionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'piece': instance.piece.toJson(),
      'version_no': instance.versionNo,
      'title': instance.title,
      'kind': _$VersionKindEnumMap[instance.kind]!,
      'files': instance.files.map((e) => e.toJson()).toList(),
      'frames': instance.frames.map((e) => e.toJson()).toList(),
      'is_current': instance.isCurrent,
      'awaiting_review': instance.awaitingReview,
      'review_outcome': _$ReviewOutcomeEnumMap[instance.reviewOutcome],
      'review_reason': instance.reviewReason,
      'reviewed_by': instance.reviewedBy?.toJson(),
      'reviewed_at': instance.reviewedAt,
      'created_by': instance.createdBy?.toJson(),
      'created': instance.created,
      'modified': instance.modified,
      'locked': instance.locked,
      'rating_open': instance.ratingOpen,
      'hidden': instance.hidden,
      'ready_for_ads': instance.readyForAds,
      'ad_route': _$AdRouteEnumMap[instance.adRoute],
      'theme': instance.theme,
      'tags': instance.tags,
      'rate_prompt': instance.ratePrompt,
      'team_note': instance.teamNote,
      'rating': instance.rating.toJson(),
      'my_rating': instance.myRating?.toJson(),
      'comments_count': instance.commentsCount,
      'verdict': instance.verdict?.toJson(),
      'post': instance.post?.toJson(),
      'caption': instance.caption,
      'actions': instance.actions,
    };

const _$AdRouteEnumMap = {
  AdRoute.adsFeed: 'ads + feed',
  AdRoute.adOnly: 'ad only',
  AdRoute.feedOnly: 'feed only',
  AdRoute.hold: 'hold',
  AdRoute.off: 'off',
  AdRoute.unknown: '__unknown__',
};

_$StudioPieceImpl _$$StudioPieceImplFromJson(
  Map<String, dynamic> json,
) => _$StudioPieceImpl(
  id: json['id'] as String,
  legacyId: json['legacy_id'] as String?,
  title: json['title'] as String,
  titleAr: json['title_ar'] as String?,
  format: $enumDecode(
    _$PieceFormatEnumMap,
    json['format'],
    unknownValue: PieceFormat.unknown,
  ),
  use: $enumDecodeNullable(
    _$PieceUseEnumMap,
    json['use'],
    unknownValue: PieceUse.unknown,
  ),
  stage: $enumDecode(
    _$PieceStageEnumMap,
    json['stage'],
    unknownValue: PieceStage.unknown,
  ),
  parked: json['parked'] as String?,
  persona: $enumDecodeNullable(
    _$PersonaEnumMap,
    json['persona'],
    unknownValue: Persona.unknown,
  ),
  situation: $enumDecodeNullable(
    _$SituationEnumMap,
    json['situation'],
    unknownValue: Situation.unknown,
  ),
  layer: $enumDecodeNullable(
    _$ContentLayerEnumMap,
    json['layer'],
    unknownValue: ContentLayer.unknown,
  ),
  level: (json['level'] as num?)?.toInt(),
  series: json['series'] as String?,
  flavours: (json['flavours'] as List<dynamic>)
      .map((e) => FlavourRef.fromJson(e as Map<String, dynamic>))
      .toList(),
  noFlavour: json['no_flavour'] as bool,
  assignee: json['assignee'] == null
      ? null
      : PersonRef.fromJson(json['assignee'] as Map<String, dynamic>),
  assigneeTeam: $enumDecodeNullable(
    _$OwnerTeamEnumMap,
    json['assignee_team'],
    unknownValue: OwnerTeam.unknown,
  ),
  dueDate: json['due_date'] as String?,
  picture: json['picture'] == null
      ? null
      : StudioMedia.fromJson(json['picture'] as Map<String, dynamic>),
  verdict: json['verdict'] == null
      ? null
      : VerdictBrief.fromJson(json['verdict'] as Map<String, dynamic>),
  currentVersion: json['current_version'] == null
      ? null
      : VersionBrief.fromJson(json['current_version'] as Map<String, dynamic>),
  nextPost: json['next_post'] == null
      ? null
      : PostBrief.fromJson(json['next_post'] as Map<String, dynamic>),
  paidState: json['paid_state'] as String?,
  blocked: json['blocked'] == null
      ? null
      : Blocked.fromJson(json['blocked'] as Map<String, dynamic>),
  modified: json['modified'] as String,
  actions: (json['actions'] as List<dynamic>).map((e) => e as String).toList(),
  route: $enumDecodeNullable(
    _$ProdRouteEnumMap,
    json['route'],
    unknownValue: ProdRoute.unknown,
  ),
  lane: json['lane'] as String?,
  batch: json['batch'] as String?,
  skipShootReason: json['skip_shoot_reason'] as String?,
  script: Script.fromJson(json['script'] as Map<String, dynamic>),
  ownText: json['own_text'] as String?,
  adCopy: json['ad_copy'] as String?,
  note: json['note'] as String?,
  why: json['why'] as String?,
  score: json['score'] as String?,
  sourceKey: json['source_key'] as String?,
  launch: json['launch'] == null
      ? null
      : MomentRef.fromJson(json['launch'] as Map<String, dynamic>),
  parkedBy: json['parked_by'] == null
      ? null
      : PersonRef.fromJson(json['parked_by'] as Map<String, dynamic>),
  parkedAt: json['parked_at'] as String?,
  created: json['created'] as String,
  versions: (json['versions'] as List<dynamic>)
      .map((e) => PieceVersion.fromJson(e as Map<String, dynamic>))
      .toList(),
  posts: (json['posts'] as List<dynamic>)
      .map((e) => PostSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  reads: (json['reads'] as List<dynamic>)
      .map((e) => PostRead.fromJson(e as Map<String, dynamic>))
      .toList(),
  ads: (json['ads'] as List<dynamic>)
      .map((e) => AdBrief.fromJson(e as Map<String, dynamic>))
      .toList(),
  shots: (json['shots'] as List<dynamic>)
      .map((e) => ShotBrief.fromJson(e as Map<String, dynamic>))
      .toList(),
  verdicts: (json['verdicts'] as List<dynamic>)
      .map((e) => PieceVerdict.fromJson(e as Map<String, dynamic>))
      .toList(),
  gate: json['gate'] == null
      ? null
      : GateResult.fromJson(json['gate'] as Map<String, dynamic>),
  nextMoves: (json['next_moves'] as List<dynamic>)
      .map((e) => Move.fromJson(e as Map<String, dynamic>))
      .toList(),
  history: (json['history'] as List<dynamic>)
      .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  historyTotal: (json['history_total'] as num).toInt(),
);

Map<String, dynamic> _$$StudioPieceImplToJson(_$StudioPieceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'legacy_id': instance.legacyId,
      'title': instance.title,
      'title_ar': instance.titleAr,
      'format': _$PieceFormatEnumMap[instance.format]!,
      'use': _$PieceUseEnumMap[instance.use],
      'stage': _$PieceStageEnumMap[instance.stage]!,
      'parked': instance.parked,
      'persona': _$PersonaEnumMap[instance.persona],
      'situation': _$SituationEnumMap[instance.situation],
      'layer': _$ContentLayerEnumMap[instance.layer],
      'level': instance.level,
      'series': instance.series,
      'flavours': instance.flavours.map((e) => e.toJson()).toList(),
      'no_flavour': instance.noFlavour,
      'assignee': instance.assignee?.toJson(),
      'assignee_team': _$OwnerTeamEnumMap[instance.assigneeTeam],
      'due_date': instance.dueDate,
      'picture': instance.picture?.toJson(),
      'verdict': instance.verdict?.toJson(),
      'current_version': instance.currentVersion?.toJson(),
      'next_post': instance.nextPost?.toJson(),
      'paid_state': instance.paidState,
      'blocked': instance.blocked?.toJson(),
      'modified': instance.modified,
      'actions': instance.actions,
      'route': _$ProdRouteEnumMap[instance.route],
      'lane': instance.lane,
      'batch': instance.batch,
      'skip_shoot_reason': instance.skipShootReason,
      'script': instance.script.toJson(),
      'own_text': instance.ownText,
      'ad_copy': instance.adCopy,
      'note': instance.note,
      'why': instance.why,
      'score': instance.score,
      'source_key': instance.sourceKey,
      'launch': instance.launch?.toJson(),
      'parked_by': instance.parkedBy?.toJson(),
      'parked_at': instance.parkedAt,
      'created': instance.created,
      'versions': instance.versions.map((e) => e.toJson()).toList(),
      'posts': instance.posts.map((e) => e.toJson()).toList(),
      'reads': instance.reads.map((e) => e.toJson()).toList(),
      'ads': instance.ads.map((e) => e.toJson()).toList(),
      'shots': instance.shots.map((e) => e.toJson()).toList(),
      'verdicts': instance.verdicts.map((e) => e.toJson()).toList(),
      'gate': instance.gate?.toJson(),
      'next_moves': instance.nextMoves.map((e) => e.toJson()).toList(),
      'history': instance.history.map((e) => e.toJson()).toList(),
      'history_total': instance.historyTotal,
    };

const _$ProdRouteEnumMap = {
  ProdRoute.realShoot: 'Real shoot',
  ProdRoute.flow3DStatic: 'Flow 3D static',
  ProdRoute.aIVideo: 'AI video',
  ProdRoute.unknown: '__unknown__',
};

_$MomentRefImpl _$$MomentRefImplFromJson(Map<String, dynamic> json) =>
    _$MomentRefImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      kind: $enumDecode(
        _$MomentKindEnumMap,
        json['kind'],
        unknownValue: MomentKind.unknown,
      ),
      effectiveDate: json['effective_date'] as String?,
    );

Map<String, dynamic> _$$MomentRefImplToJson(_$MomentRefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'kind': _$MomentKindEnumMap[instance.kind]!,
      'effective_date': instance.effectiveDate,
    };

const _$MomentKindEnumMap = {
  MomentKind.launch: 'launch',
  MomentKind.heroWindow: 'hero_window',
  MomentKind.budgetStep: 'budget_step',
  MomentKind.unknown: '__unknown__',
};

_$ApproveCardImpl _$$ApproveCardImplFromJson(Map<String, dynamic> json) =>
    _$ApproveCardImpl(
      version: PieceVersion.fromJson(json['version'] as Map<String, dynamic>),
      piece: PieceSummary.fromJson(json['piece'] as Map<String, dynamic>),
      posts: (json['posts'] as List<dynamic>)
          .map((e) => PostSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      caption: json['caption'] as String?,
      gate: GateResult.fromJson(json['gate'] as Map<String, dynamic>),
      waitingSince: json['waiting_since'] as String,
      position: (json['position'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$$ApproveCardImplToJson(_$ApproveCardImpl instance) =>
    <String, dynamic>{
      'version': instance.version.toJson(),
      'piece': instance.piece.toJson(),
      'posts': instance.posts.map((e) => e.toJson()).toList(),
      'caption': instance.caption,
      'gate': instance.gate.toJson(),
      'waiting_since': instance.waitingSince,
      'position': instance.position,
      'total': instance.total,
    };

_$RateCardImpl _$$RateCardImplFromJson(Map<String, dynamic> json) =>
    _$RateCardImpl(
      targetType: $enumDecode(
        _$TargetTypeEnumMap,
        json['target_type'],
        unknownValue: TargetType.unknown,
      ),
      version: json['version'] == null
          ? null
          : PieceVersion.fromJson(json['version'] as Map<String, dynamic>),
      asset: json['asset'] == null
          ? null
          : StudioAsset.fromJson(json['asset'] as Map<String, dynamic>),
      piece: json['piece'] == null
          ? null
          : PieceSummary.fromJson(json['piece'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$RateCardImplToJson(_$RateCardImpl instance) =>
    <String, dynamic>{
      'target_type': _$TargetTypeEnumMap[instance.targetType]!,
      'version': instance.version?.toJson(),
      'asset': instance.asset?.toJson(),
      'piece': instance.piece?.toJson(),
    };

_$InboxCountsImpl _$$InboxCountsImplFromJson(Map<String, dynamic> json) =>
    _$InboxCountsImpl(
      toApprove: (json['to_approve'] as num).toInt(),
      decisions: (json['decisions'] as num).toInt(),
      ideas: (json['ideas'] as num).toInt(),
      toRate: (json['to_rate'] as num).toInt(),
      unreadNotifications: (json['unread_notifications'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$$InboxCountsImplToJson(_$InboxCountsImpl instance) =>
    <String, dynamic>{
      'to_approve': instance.toApprove,
      'decisions': instance.decisions,
      'ideas': instance.ideas,
      'to_rate': instance.toRate,
      'unread_notifications': instance.unreadNotifications,
      'total': instance.total,
    };

_$BoardColumnImpl _$$BoardColumnImplFromJson(Map<String, dynamic> json) =>
    _$BoardColumnImpl(
      stage: $enumDecode(
        _$PieceStageEnumMap,
        json['stage'],
        unknownValue: PieceStage.unknown,
      ),
      count: (json['count'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => PieceSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      next: json['next'] as String?,
    );

Map<String, dynamic> _$$BoardColumnImplToJson(_$BoardColumnImpl instance) =>
    <String, dynamic>{
      'stage': _$PieceStageEnumMap[instance.stage]!,
      'count': instance.count,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'next': instance.next,
    };

_$PieceBoardImpl _$$PieceBoardImplFromJson(Map<String, dynamic> json) =>
    _$PieceBoardImpl(
      columns: (json['columns'] as List<dynamic>)
          .map((e) => BoardColumn.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      parkedCount: (json['parked_count'] as num).toInt(),
    );

Map<String, dynamic> _$$PieceBoardImplToJson(_$PieceBoardImpl instance) =>
    <String, dynamic>{
      'columns': instance.columns.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'parked_count': instance.parkedCount,
    };

_$WeekGroupImpl _$$WeekGroupImplFromJson(Map<String, dynamic> json) =>
    _$WeekGroupImpl(
      person: json['person'] == null
          ? null
          : PersonRef.fromJson(json['person'] as Map<String, dynamic>),
      team: $enumDecodeNullable(
        _$OwnerTeamEnumMap,
        json['team'],
        unknownValue: OwnerTeam.unknown,
      ),
      pieces: (json['pieces'] as List<dynamic>)
          .map((e) => PieceSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      posts: (json['posts'] as List<dynamic>)
          .map((e) => PostSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      tasks: (json['tasks'] as List<dynamic>)
          .map((e) => StudioTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      shots: (json['shots'] as List<dynamic>)
          .map((e) => ShotBrief.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$WeekGroupImplToJson(_$WeekGroupImpl instance) =>
    <String, dynamic>{
      'person': instance.person?.toJson(),
      'team': _$OwnerTeamEnumMap[instance.team],
      'pieces': instance.pieces.map((e) => e.toJson()).toList(),
      'posts': instance.posts.map((e) => e.toJson()).toList(),
      'tasks': instance.tasks.map((e) => e.toJson()).toList(),
      'shots': instance.shots.map((e) => e.toJson()).toList(),
    };

_$ThisWeekImpl _$$ThisWeekImplFromJson(Map<String, dynamic> json) =>
    _$ThisWeekImpl(
      weekStart: json['week_start'] as String,
      weekEnd: json['week_end'] as String,
      groups: (json['groups'] as List<dynamic>)
          .map((e) => WeekGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ThisWeekImplToJson(_$ThisWeekImpl instance) =>
    <String, dynamic>{
      'week_start': instance.weekStart,
      'week_end': instance.weekEnd,
      'groups': instance.groups.map((e) => e.toJson()).toList(),
    };

_$StudioIdeaImpl _$$StudioIdeaImplFromJson(Map<String, dynamic> json) =>
    _$StudioIdeaImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      titleAr: json['title_ar'] as String?,
      hook: json['hook'] as String?,
      format: $enumDecodeNullable(
        _$PieceFormatEnumMap,
        json['format'],
        unknownValue: PieceFormat.unknown,
      ),
      angle: json['angle'] as String?,
      source: $enumDecode(
        _$IdeaSourceEnumMap,
        json['source'],
        unknownValue: IdeaSource.unknown,
      ),
      sourceReference: json['source_reference'] == null
          ? null
          : ReferenceBrief.fromJson(
              json['source_reference'] as Map<String, dynamic>,
            ),
      flavours: (json['flavours'] as List<dynamic>)
          .map((e) => FlavourRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      raisedBy: json['raised_by'] == null
          ? null
          : PersonRef.fromJson(json['raised_by'] as Map<String, dynamic>),
      status: $enumDecode(
        _$IdeaStatusEnumMap,
        json['status'],
        unknownValue: IdeaStatus.unknown,
      ),
      dropReason: json['drop_reason'] as String?,
      decidedAt: json['decided_at'] as String?,
      keptPieceId: json['kept_piece_id'] as String?,
      created: json['created'] as String,
      modified: json['modified'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$StudioIdeaImplToJson(_$StudioIdeaImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'title_ar': instance.titleAr,
      'hook': instance.hook,
      'format': _$PieceFormatEnumMap[instance.format],
      'angle': instance.angle,
      'source': _$IdeaSourceEnumMap[instance.source]!,
      'source_reference': instance.sourceReference?.toJson(),
      'flavours': instance.flavours.map((e) => e.toJson()).toList(),
      'raised_by': instance.raisedBy?.toJson(),
      'status': _$IdeaStatusEnumMap[instance.status]!,
      'drop_reason': instance.dropReason,
      'decided_at': instance.decidedAt,
      'kept_piece_id': instance.keptPieceId,
      'created': instance.created,
      'modified': instance.modified,
      'actions': instance.actions,
    };

const _$IdeaSourceEnumMap = {
  IdeaSource.claude: 'claude',
  IdeaSource.creator: 'creator',
  IdeaSource.founder: 'founder',
  IdeaSource.reference: 'reference',
  IdeaSource.customer: 'customer',
  IdeaSource.other: 'other',
  IdeaSource.unknown: '__unknown__',
};

const _$IdeaStatusEnumMap = {
  IdeaStatus.open: 'Open',
  IdeaStatus.kept: 'Kept',
  IdeaStatus.dropped: 'Dropped',
  IdeaStatus.unknown: '__unknown__',
};

_$IdeaKeepResultImpl _$$IdeaKeepResultImplFromJson(Map<String, dynamic> json) =>
    _$IdeaKeepResultImpl(
      idea: StudioIdea.fromJson(json['idea'] as Map<String, dynamic>),
      piece: PieceSummary.fromJson(json['piece'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$IdeaKeepResultImplToJson(
  _$IdeaKeepResultImpl instance,
) => <String, dynamic>{
  'idea': instance.idea.toJson(),
  'piece': instance.piece.toJson(),
};

_$PostSummaryImpl _$$PostSummaryImplFromJson(Map<String, dynamic> json) =>
    _$PostSummaryImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      piece: json['piece'] == null
          ? null
          : PieceRef.fromJson(json['piece'] as Map<String, dynamic>),
      versionId: json['version_id'] as String?,
      channel: $enumDecodeNullable(
        _$PostChannelEnumMap,
        json['channel'],
        unknownValue: PostChannel.unknown,
      ),
      slotTime: json['slot_time'] as String?,
      status: $enumDecode(
        _$PostStatusEnumMap,
        json['status'],
        unknownValue: PostStatus.unknown,
      ),
      postingMode: $enumDecodeNullable(
        _$PostingModeEnumMap,
        json['posting_mode'],
        unknownValue: PostingMode.unknown,
      ),
      assignee: json['assignee'] == null
          ? null
          : PersonRef.fromJson(json['assignee'] as Map<String, dynamic>),
      assigneeTeam: $enumDecodeNullable(
        _$OwnerTeamEnumMap,
        json['assignee_team'],
        unknownValue: OwnerTeam.unknown,
      ),
      thumb: json['thumb'] == null
          ? null
          : StudioMedia.fromJson(json['thumb'] as Map<String, dynamic>),
      captionReady: json['caption_ready'] as bool,
      moment: json['moment'] == null
          ? null
          : MomentRef.fromJson(json['moment'] as Map<String, dynamic>),
      postedAt: json['posted_at'] as String?,
      permalink: json['permalink'] as String?,
      waitsOn: json['waits_on'] as String?,
      level: $enumDecodeNullable(
        _$NoteLevelEnumMap,
        json['level'],
        unknownValue: NoteLevel.unknown,
      ),
      modified: json['modified'] as String,
    );

Map<String, dynamic> _$$PostSummaryImplToJson(_$PostSummaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'piece': instance.piece?.toJson(),
      'version_id': instance.versionId,
      'channel': _$PostChannelEnumMap[instance.channel],
      'slot_time': instance.slotTime,
      'status': _$PostStatusEnumMap[instance.status]!,
      'posting_mode': _$PostingModeEnumMap[instance.postingMode],
      'assignee': instance.assignee?.toJson(),
      'assignee_team': _$OwnerTeamEnumMap[instance.assigneeTeam],
      'thumb': instance.thumb?.toJson(),
      'caption_ready': instance.captionReady,
      'moment': instance.moment?.toJson(),
      'posted_at': instance.postedAt,
      'permalink': instance.permalink,
      'waits_on': instance.waitsOn,
      'level': _$NoteLevelEnumMap[instance.level],
      'modified': instance.modified,
    };

const _$NoteLevelEnumMap = {
  NoteLevel.info: 'info',
  NoteLevel.warn: 'warn',
  NoteLevel.stop: 'stop',
  NoteLevel.unknown: '__unknown__',
};

_$CheckItemImpl _$$CheckItemImplFromJson(Map<String, dynamic> json) =>
    _$CheckItemImpl(
      code: json['code'] as String,
      severity: $enumDecode(
        _$CheckSeverityEnumMap,
        json['severity'],
        unknownValue: CheckSeverity.unknown,
      ),
      message: json['message'] as String,
    );

Map<String, dynamic> _$$CheckItemImplToJson(_$CheckItemImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'severity': _$CheckSeverityEnumMap[instance.severity]!,
      'message': instance.message,
    };

const _$CheckSeverityEnumMap = {
  CheckSeverity.block: 'block',
  CheckSeverity.warn: 'warn',
  CheckSeverity.unknown: '__unknown__',
};

_$SocialPostImpl _$$SocialPostImplFromJson(Map<String, dynamic> json) =>
    _$SocialPostImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      piece: json['piece'] == null
          ? null
          : PieceRef.fromJson(json['piece'] as Map<String, dynamic>),
      versionId: json['version_id'] as String?,
      channel: $enumDecodeNullable(
        _$PostChannelEnumMap,
        json['channel'],
        unknownValue: PostChannel.unknown,
      ),
      slotTime: json['slot_time'] as String?,
      status: $enumDecode(
        _$PostStatusEnumMap,
        json['status'],
        unknownValue: PostStatus.unknown,
      ),
      postingMode: $enumDecodeNullable(
        _$PostingModeEnumMap,
        json['posting_mode'],
        unknownValue: PostingMode.unknown,
      ),
      assignee: json['assignee'] == null
          ? null
          : PersonRef.fromJson(json['assignee'] as Map<String, dynamic>),
      assigneeTeam: $enumDecodeNullable(
        _$OwnerTeamEnumMap,
        json['assignee_team'],
        unknownValue: OwnerTeam.unknown,
      ),
      thumb: json['thumb'] == null
          ? null
          : StudioMedia.fromJson(json['thumb'] as Map<String, dynamic>),
      captionReady: json['caption_ready'] as bool,
      moment: json['moment'] == null
          ? null
          : MomentRef.fromJson(json['moment'] as Map<String, dynamic>),
      postedAt: json['posted_at'] as String?,
      permalink: json['permalink'] as String?,
      waitsOn: json['waits_on'] as String?,
      level: $enumDecodeNullable(
        _$NoteLevelEnumMap,
        json['level'],
        unknownValue: NoteLevel.unknown,
      ),
      modified: json['modified'] as String,
      caption: json['caption'] as String?,
      postHow: json['post_how'] as String?,
      skipReason: json['skip_reason'] as String?,
      note: json['note'] as String?,
      momentOffsetDays: (json['moment_offset_days'] as num?)?.toInt(),
      postedBy: json['posted_by'] as String?,
      postedHow: $enumDecodeNullable(
        _$PostedHowEnumMap,
        json['posted_how'],
        unknownValue: PostedHow.unknown,
      ),
      lastError: json['last_error'] as String?,
      files: (json['files'] as List<dynamic>)
          .map((e) => StudioMedia.fromJson(e as Map<String, dynamic>))
          .toList(),
      frames: (json['frames'] as List<dynamic>)
          .map((e) => StoryFrame.fromJson(e as Map<String, dynamic>))
          .toList(),
      version: json['version'] == null
          ? null
          : VersionBrief.fromJson(json['version'] as Map<String, dynamic>),
      checks: (json['checks'] as List<dynamic>)
          .map((e) => CheckItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      captionProblems: (json['caption_problems'] as List<dynamic>)
          .map((e) => StudioProblem.fromJson(e as Map<String, dynamic>))
          .toList(),
      reads: (json['reads'] as List<dynamic>)
          .map((e) => PostRead.fromJson(e as Map<String, dynamic>))
          .toList(),
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$SocialPostImplToJson(
  _$SocialPostImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'piece': instance.piece?.toJson(),
  'version_id': instance.versionId,
  'channel': _$PostChannelEnumMap[instance.channel],
  'slot_time': instance.slotTime,
  'status': _$PostStatusEnumMap[instance.status]!,
  'posting_mode': _$PostingModeEnumMap[instance.postingMode],
  'assignee': instance.assignee?.toJson(),
  'assignee_team': _$OwnerTeamEnumMap[instance.assigneeTeam],
  'thumb': instance.thumb?.toJson(),
  'caption_ready': instance.captionReady,
  'moment': instance.moment?.toJson(),
  'posted_at': instance.postedAt,
  'permalink': instance.permalink,
  'waits_on': instance.waitsOn,
  'level': _$NoteLevelEnumMap[instance.level],
  'modified': instance.modified,
  'caption': instance.caption,
  'post_how': instance.postHow,
  'skip_reason': instance.skipReason,
  'note': instance.note,
  'moment_offset_days': instance.momentOffsetDays,
  'posted_by': instance.postedBy,
  'posted_how': _$PostedHowEnumMap[instance.postedHow],
  'last_error': instance.lastError,
  'files': instance.files.map((e) => e.toJson()).toList(),
  'frames': instance.frames.map((e) => e.toJson()).toList(),
  'version': instance.version?.toJson(),
  'checks': instance.checks.map((e) => e.toJson()).toList(),
  'caption_problems': instance.captionProblems.map((e) => e.toJson()).toList(),
  'reads': instance.reads.map((e) => e.toJson()).toList(),
  'actions': instance.actions,
};

const _$PostedHowEnumMap = {
  PostedHow.system: 'system',
  PostedHow.hand: 'hand',
  PostedHow.matched: 'matched',
  PostedHow.unknown: '__unknown__',
};

_$PostResultImpl _$$PostResultImplFromJson(Map<String, dynamic> json) =>
    _$PostResultImpl(
      post: SocialPost.fromJson(json['post'] as Map<String, dynamic>),
      warnings: (json['warnings'] as List<dynamic>)
          .map((e) => CheckItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$PostResultImplToJson(_$PostResultImpl instance) =>
    <String, dynamic>{
      'post': instance.post.toJson(),
      'warnings': instance.warnings.map((e) => e.toJson()).toList(),
    };

_$ReadyPostImpl _$$ReadyPostImplFromJson(Map<String, dynamic> json) =>
    _$ReadyPostImpl(
      post: PostSummary.fromJson(json['post'] as Map<String, dynamic>),
      files: (json['files'] as List<dynamic>)
          .map((e) => StudioMedia.fromJson(e as Map<String, dynamic>))
          .toList(),
      frames: (json['frames'] as List<dynamic>)
          .map((e) => StoryFrame.fromJson(e as Map<String, dynamic>))
          .toList(),
      caption: json['caption'] as String?,
      postHow: json['post_how'] as String?,
      dueInMin: (json['due_in_min'] as num).toInt(),
      route: json['route'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$ReadyPostImplToJson(_$ReadyPostImpl instance) =>
    <String, dynamic>{
      'post': instance.post.toJson(),
      'files': instance.files.map((e) => e.toJson()).toList(),
      'frames': instance.frames.map((e) => e.toJson()).toList(),
      'caption': instance.caption,
      'post_how': instance.postHow,
      'due_in_min': instance.dueInMin,
      'route': instance.route,
      'actions': instance.actions,
    };

_$ActualPostImpl _$$ActualPostImplFromJson(Map<String, dynamic> json) =>
    _$ActualPostImpl(
      id: json['id'] as String,
      platform: $enumDecode(
        _$SocialPlatformEnumMap,
        json['platform'],
        unknownValue: SocialPlatform.unknown,
      ),
      kind: $enumDecode(
        _$ActualKindEnumMap,
        json['kind'],
        unknownValue: ActualKind.unknown,
      ),
      extId: json['ext_id'] as String,
      permalink: json['permalink'] as String?,
      postedAt: json['posted_at'] as String?,
      caption: json['caption'] as String?,
      thumbUrl: json['thumb_url'] as String?,
      postId: json['post_id'] as String?,
      match: $enumDecode(
        _$ActualMatchEnumMap,
        json['match'],
        unknownValue: ActualMatch.unknown,
      ),
    );

Map<String, dynamic> _$$ActualPostImplToJson(_$ActualPostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'platform': _$SocialPlatformEnumMap[instance.platform]!,
      'kind': _$ActualKindEnumMap[instance.kind]!,
      'ext_id': instance.extId,
      'permalink': instance.permalink,
      'posted_at': instance.postedAt,
      'caption': instance.caption,
      'thumb_url': instance.thumbUrl,
      'post_id': instance.postId,
      'match': _$ActualMatchEnumMap[instance.match]!,
    };

const _$SocialPlatformEnumMap = {
  SocialPlatform.instagram: 'instagram',
  SocialPlatform.facebook: 'facebook',
  SocialPlatform.tiktok: 'tiktok',
  SocialPlatform.unknown: '__unknown__',
};

const _$ActualKindEnumMap = {
  ActualKind.feed: 'feed',
  ActualKind.reel: 'reel',
  ActualKind.carousel: 'carousel',
  ActualKind.story: 'story',
  ActualKind.unknown: '__unknown__',
};

const _$ActualMatchEnumMap = {
  ActualMatch.none: '',
  ActualMatch.auto: 'auto',
  ActualMatch.hand: 'hand',
  ActualMatch.ignored: 'ignored',
  ActualMatch.unknown: '__unknown__',
};

_$DriftItemImpl _$$DriftItemImplFromJson(Map<String, dynamic> json) =>
    _$DriftItemImpl(
      post: PostSummary.fromJson(json['post'] as Map<String, dynamic>),
      actual: json['actual'] == null
          ? null
          : ActualPost.fromJson(json['actual'] as Map<String, dynamic>),
      minutesLate: (json['minutes_late'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$DriftItemImplToJson(_$DriftItemImpl instance) =>
    <String, dynamic>{
      'post': instance.post.toJson(),
      'actual': instance.actual?.toJson(),
      'minutes_late': instance.minutesLate,
    };

_$DriftCountsImpl _$$DriftCountsImplFromJson(Map<String, dynamic> json) =>
    _$DriftCountsImpl(
      missing: (json['missing'] as num).toInt(),
      unplanned: (json['unplanned'] as num).toInt(),
      lateValue: (json['late'] as num).toInt(),
      closed: (json['closed'] as num).toInt(),
    );

Map<String, dynamic> _$$DriftCountsImplToJson(_$DriftCountsImpl instance) =>
    <String, dynamic>{
      'missing': instance.missing,
      'unplanned': instance.unplanned,
      'late': instance.lateValue,
      'closed': instance.closed,
    };

_$PostDriftImpl _$$PostDriftImplFromJson(Map<String, dynamic> json) =>
    _$PostDriftImpl(
      days: (json['days'] as num).toInt(),
      missing: (json['missing'] as List<dynamic>)
          .map((e) => DriftItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      unplanned: (json['unplanned'] as List<dynamic>)
          .map((e) => ActualPost.fromJson(e as Map<String, dynamic>))
          .toList(),
      lateValue: (json['late'] as List<dynamic>)
          .map((e) => DriftItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      closed: (json['closed'] as List<dynamic>)
          .map((e) => DriftItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      counts: DriftCounts.fromJson(json['counts'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PostDriftImplToJson(_$PostDriftImpl instance) =>
    <String, dynamic>{
      'days': instance.days,
      'missing': instance.missing.map((e) => e.toJson()).toList(),
      'unplanned': instance.unplanned.map((e) => e.toJson()).toList(),
      'late': instance.lateValue.map((e) => e.toJson()).toList(),
      'closed': instance.closed.map((e) => e.toJson()).toList(),
      'counts': instance.counts.toJson(),
    };

_$CheckRowImpl _$$CheckRowImplFromJson(Map<String, dynamic> json) =>
    _$CheckRowImpl(
      code: json['code'] as String,
      severity: $enumDecode(
        _$CheckSeverityEnumMap,
        json['severity'],
        unknownValue: CheckSeverity.unknown,
      ),
      message: json['message'] as String,
      postId: json['post_id'] as String?,
      pieceId: json['piece_id'] as String?,
      date: json['date'] as String?,
      time: json['time'] as String?,
      channel: $enumDecodeNullable(
        _$PostChannelEnumMap,
        json['channel'],
        unknownValue: PostChannel.unknown,
      ),
      title: json['title'] as String?,
    );

Map<String, dynamic> _$$CheckRowImplToJson(_$CheckRowImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'severity': _$CheckSeverityEnumMap[instance.severity]!,
      'message': instance.message,
      'post_id': instance.postId,
      'piece_id': instance.pieceId,
      'date': instance.date,
      'time': instance.time,
      'channel': _$PostChannelEnumMap[instance.channel],
      'title': instance.title,
    };

_$PostChecksImpl _$$PostChecksImplFromJson(Map<String, dynamic> json) =>
    _$PostChecksImpl(
      at: json['at'] as String,
      block: (json['block'] as num).toInt(),
      warn: (json['warn'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => CheckRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$PostChecksImplToJson(_$PostChecksImpl instance) =>
    <String, dynamic>{
      'at': instance.at,
      'block': instance.block,
      'warn': instance.warn,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

_$ShootBriefImpl _$$ShootBriefImplFromJson(Map<String, dynamic> json) =>
    _$ShootBriefImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      shootDate: json['shoot_date'] as String?,
      shootTime: json['shoot_time'] as String?,
      status: $enumDecode(
        _$ShootStatusEnumMap,
        json['status'],
        unknownValue: ShootStatus.unknown,
      ),
      nShots: (json['n_shots'] as num).toInt(),
      nDone: (json['n_done'] as num).toInt(),
    );

Map<String, dynamic> _$$ShootBriefImplToJson(_$ShootBriefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'shoot_date': instance.shootDate,
      'shoot_time': instance.shootTime,
      'status': _$ShootStatusEnumMap[instance.status]!,
      'n_shots': instance.nShots,
      'n_done': instance.nDone,
    };

const _$ShootStatusEnumMap = {
  ShootStatus.idea: 'Idea',
  ShootStatus.prep: 'Prep',
  ShootStatus.ready: 'Ready',
  ShootStatus.shot: 'Shot',
  ShootStatus.done: 'Done',
  ShootStatus.skipped: 'Skipped',
  ShootStatus.unknown: '__unknown__',
};

_$RoundBriefImpl _$$RoundBriefImplFromJson(Map<String, dynamic> json) =>
    _$RoundBriefImpl(
      code: json['code'] as String,
      title: json['title'] as String?,
      launchDate: json['launch_date'] as String,
      d4Date: json['d4_date'] as String,
      d7Date: json['d7_date'] as String,
      nAds: (json['n_ads'] as num).toInt(),
    );

Map<String, dynamic> _$$RoundBriefImplToJson(_$RoundBriefImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'title': instance.title,
      'launch_date': instance.launchDate,
      'd4_date': instance.d4Date,
      'd7_date': instance.d7Date,
      'n_ads': instance.nAds,
    };

_$CalendarRangeImpl _$$CalendarRangeImplFromJson(Map<String, dynamic> json) =>
    _$CalendarRangeImpl(
      from: json['from'] as String,
      to: json['to'] as String,
      posts: (json['posts'] as List<dynamic>)
          .map((e) => PostSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      moments: (json['moments'] as List<dynamic>)
          .map((e) => StudioMoment.fromJson(e as Map<String, dynamic>))
          .toList(),
      shoots: (json['shoots'] as List<dynamic>)
          .map((e) => ShootBrief.fromJson(e as Map<String, dynamic>))
          .toList(),
      rounds: (json['rounds'] as List<dynamic>)
          .map((e) => RoundBrief.fromJson(e as Map<String, dynamic>))
          .toList(),
      tasks: (json['tasks'] as List<dynamic>)
          .map((e) => StudioTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      deleted: (json['deleted'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      serverTime: json['server_time'] as String,
    );

Map<String, dynamic> _$$CalendarRangeImplToJson(_$CalendarRangeImpl instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'posts': instance.posts.map((e) => e.toJson()).toList(),
      'moments': instance.moments.map((e) => e.toJson()).toList(),
      'shoots': instance.shoots.map((e) => e.toJson()).toList(),
      'rounds': instance.rounds.map((e) => e.toJson()).toList(),
      'tasks': instance.tasks.map((e) => e.toJson()).toList(),
      'deleted': instance.deleted,
      'server_time': instance.serverTime,
    };

_$StudioTaskImpl _$$StudioTaskImplFromJson(Map<String, dynamic> json) =>
    _$StudioTaskImpl(
      id: json['id'] as String,
      kind: $enumDecode(
        _$TaskKindEnumMap,
        json['kind'],
        unknownValue: TaskKind.unknown,
      ),
      text: json['text'] as String,
      assignee: json['assignee'] == null
          ? null
          : PersonRef.fromJson(json['assignee'] as Map<String, dynamic>),
      assigneeTeam: $enumDecodeNullable(
        _$OwnerTeamEnumMap,
        json['assignee_team'],
        unknownValue: OwnerTeam.unknown,
      ),
      due: json['due'] as String?,
      dueTime: json['due_time'] as String?,
      done: json['done'] as bool,
      skipped: json['skipped'] as bool,
      doneBy: json['done_by'] == null
          ? null
          : PersonRef.fromJson(json['done_by'] as Map<String, dynamic>),
      doneAt: json['done_at'] as String?,
      shootId: json['shoot_id'] as String?,
      pieceId: json['piece_id'] as String?,
      postId: json['post_id'] as String?,
      note: json['note'] as String?,
      sortOrder: (json['sort_order'] as num).toDouble(),
      modified: json['modified'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$StudioTaskImplToJson(_$StudioTaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$TaskKindEnumMap[instance.kind]!,
      'text': instance.text,
      'assignee': instance.assignee?.toJson(),
      'assignee_team': _$OwnerTeamEnumMap[instance.assigneeTeam],
      'due': instance.due,
      'due_time': instance.dueTime,
      'done': instance.done,
      'skipped': instance.skipped,
      'done_by': instance.doneBy?.toJson(),
      'done_at': instance.doneAt,
      'shoot_id': instance.shootId,
      'piece_id': instance.pieceId,
      'post_id': instance.postId,
      'note': instance.note,
      'sort_order': instance.sortOrder,
      'modified': instance.modified,
      'actions': instance.actions,
    };

const _$TaskKindEnumMap = {
  TaskKind.todo: 'todo',
  TaskKind.prep: 'prep',
  TaskKind.unknown: '__unknown__',
};

_$BriefImpl _$$BriefImplFromJson(Map<String, dynamic> json) => _$BriefImpl(
  why: json['why'] as String?,
  frame: json['frame'] as String?,
  light: json['light'] as String?,
  action: json['action'] as String?,
  sound: json['sound'] as String?,
  copy: json['copy'] as String?,
  avoid: json['avoid'] as String?,
  check: json['check'] as String?,
  takes: json['takes'] as String?,
);

Map<String, dynamic> _$$BriefImplToJson(_$BriefImpl instance) =>
    <String, dynamic>{
      'why': instance.why,
      'frame': instance.frame,
      'light': instance.light,
      'action': instance.action,
      'sound': instance.sound,
      'copy': instance.copy,
      'avoid': instance.avoid,
      'check': instance.check,
      'takes': instance.takes,
    };

_$ShotRefImpl _$$ShotRefImplFromJson(Map<String, dynamic> json) =>
    _$ShotRefImpl(
      linkId: json['link_id'] as String,
      reference: ReferenceBrief.fromJson(
        json['reference'] as Map<String, dynamic>,
      ),
      grade: $enumDecodeNullable(
        _$RefGradeEnumMap,
        json['grade'],
        unknownValue: RefGrade.unknown,
      ),
      real: json['real'] as bool,
    );

Map<String, dynamic> _$$ShotRefImplToJson(_$ShotRefImpl instance) =>
    <String, dynamic>{
      'link_id': instance.linkId,
      'reference': instance.reference.toJson(),
      'grade': _$RefGradeEnumMap[instance.grade],
      'real': instance.real,
    };

const _$RefGradeEnumMap = {
  RefGrade.strong: 'strong',
  RefGrade.weak: 'weak',
  RefGrade.unknown: '__unknown__',
};

_$ShootShotImpl _$$ShootShotImplFromJson(Map<String, dynamic> json) =>
    _$ShootShotImpl(
      id: json['id'] as String,
      shootId: json['shoot_id'] as String,
      setup: json['setup'] as String?,
      sortOrder: (json['sort_order'] as num).toDouble(),
      what: json['what'] as String,
      lenS: (json['len_s'] as num?)?.toDouble(),
      note: json['note'] as String?,
      ar: json['ar'] as String?,
      en: json['en'] as String?,
      brief: Brief.fromJson(json['brief'] as Map<String, dynamic>),
      done: json['done'] as bool,
      doneBy: json['done_by'] == null
          ? null
          : PersonRef.fromJson(json['done_by'] as Map<String, dynamic>),
      doneAt: json['done_at'] as String?,
      pieces: (json['pieces'] as List<dynamic>)
          .map((e) => PieceRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      refs: (json['refs'] as List<dynamic>)
          .map((e) => ShotRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      refOk: json['ref_ok'] as bool,
      modified: json['modified'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$ShootShotImplToJson(_$ShootShotImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shoot_id': instance.shootId,
      'setup': instance.setup,
      'sort_order': instance.sortOrder,
      'what': instance.what,
      'len_s': instance.lenS,
      'note': instance.note,
      'ar': instance.ar,
      'en': instance.en,
      'brief': instance.brief.toJson(),
      'done': instance.done,
      'done_by': instance.doneBy?.toJson(),
      'done_at': instance.doneAt,
      'pieces': instance.pieces.map((e) => e.toJson()).toList(),
      'refs': instance.refs.map((e) => e.toJson()).toList(),
      'ref_ok': instance.refOk,
      'modified': instance.modified,
      'actions': instance.actions,
    };

_$ShootSummaryImpl _$$ShootSummaryImplFromJson(Map<String, dynamic> json) =>
    _$ShootSummaryImpl(
      id: json['id'] as String,
      legacyId: json['legacy_id'] as String?,
      title: json['title'] as String,
      shootDate: json['shoot_date'] as String?,
      shootTime: json['shoot_time'] as String?,
      status: $enumDecode(
        _$ShootStatusEnumMap,
        json['status'],
        unknownValue: ShootStatus.unknown,
      ),
      place: json['place'] as String?,
      assignee: json['assignee'] == null
          ? null
          : PersonRef.fromJson(json['assignee'] as Map<String, dynamic>),
      assigneeTeam: $enumDecodeNullable(
        _$OwnerTeamEnumMap,
        json['assignee_team'],
        unknownValue: OwnerTeam.unknown,
      ),
      nShots: (json['n_shots'] as num).toInt(),
      nDone: (json['n_done'] as num).toInt(),
      nNoRef: (json['n_no_ref'] as num).toInt(),
      nPieces: (json['n_pieces'] as num).toInt(),
      needs: (json['needs'] as List<dynamic>).map((e) => e as String).toList(),
      prepTotal: (json['prep_total'] as num).toInt(),
      prepDone: (json['prep_done'] as num).toInt(),
      modified: json['modified'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$ShootSummaryImplToJson(_$ShootSummaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'legacy_id': instance.legacyId,
      'title': instance.title,
      'shoot_date': instance.shootDate,
      'shoot_time': instance.shootTime,
      'status': _$ShootStatusEnumMap[instance.status]!,
      'place': instance.place,
      'assignee': instance.assignee?.toJson(),
      'assignee_team': _$OwnerTeamEnumMap[instance.assigneeTeam],
      'n_shots': instance.nShots,
      'n_done': instance.nDone,
      'n_no_ref': instance.nNoRef,
      'n_pieces': instance.nPieces,
      'needs': instance.needs,
      'prep_total': instance.prepTotal,
      'prep_done': instance.prepDone,
      'modified': instance.modified,
      'actions': instance.actions,
    };

_$StudioShootImpl _$$StudioShootImplFromJson(Map<String, dynamic> json) =>
    _$StudioShootImpl(
      id: json['id'] as String,
      legacyId: json['legacy_id'] as String?,
      title: json['title'] as String,
      shootDate: json['shoot_date'] as String?,
      shootTime: json['shoot_time'] as String?,
      status: $enumDecode(
        _$ShootStatusEnumMap,
        json['status'],
        unknownValue: ShootStatus.unknown,
      ),
      place: json['place'] as String?,
      assignee: json['assignee'] == null
          ? null
          : PersonRef.fromJson(json['assignee'] as Map<String, dynamic>),
      assigneeTeam: $enumDecodeNullable(
        _$OwnerTeamEnumMap,
        json['assignee_team'],
        unknownValue: OwnerTeam.unknown,
      ),
      nShots: (json['n_shots'] as num).toInt(),
      nDone: (json['n_done'] as num).toInt(),
      nNoRef: (json['n_no_ref'] as num).toInt(),
      nPieces: (json['n_pieces'] as num).toInt(),
      needs: (json['needs'] as List<dynamic>).map((e) => e as String).toList(),
      prepTotal: (json['prep_total'] as num).toInt(),
      prepDone: (json['prep_done'] as num).toInt(),
      modified: json['modified'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      people: json['people'] as String?,
      kit: json['kit'] as String?,
      notes: json['notes'] as String?,
      footage: json['footage'] as String?,
      shareEnabled: json['share_enabled'] as bool,
      shots: (json['shots'] as List<dynamic>)
          .map((e) => ShootShot.fromJson(e as Map<String, dynamic>))
          .toList(),
      prep: (json['prep'] as List<dynamic>)
          .map((e) => StudioTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      pieces: (json['pieces'] as List<dynamic>)
          .map((e) => PieceRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$StudioShootImplToJson(_$StudioShootImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'legacy_id': instance.legacyId,
      'title': instance.title,
      'shoot_date': instance.shootDate,
      'shoot_time': instance.shootTime,
      'status': _$ShootStatusEnumMap[instance.status]!,
      'place': instance.place,
      'assignee': instance.assignee?.toJson(),
      'assignee_team': _$OwnerTeamEnumMap[instance.assigneeTeam],
      'n_shots': instance.nShots,
      'n_done': instance.nDone,
      'n_no_ref': instance.nNoRef,
      'n_pieces': instance.nPieces,
      'needs': instance.needs,
      'prep_total': instance.prepTotal,
      'prep_done': instance.prepDone,
      'modified': instance.modified,
      'actions': instance.actions,
      'people': instance.people,
      'kit': instance.kit,
      'notes': instance.notes,
      'footage': instance.footage,
      'share_enabled': instance.shareEnabled,
      'shots': instance.shots.map((e) => e.toJson()).toList(),
      'prep': instance.prep.map((e) => e.toJson()).toList(),
      'pieces': instance.pieces.map((e) => e.toJson()).toList(),
    };

_$TickItemImpl _$$TickItemImplFromJson(Map<String, dynamic> json) =>
    _$TickItemImpl(
      shotId: json['shot_id'] as String,
      ok: json['ok'] as bool,
      error: json['error'] == null
          ? null
          : StudioProblem.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$TickItemImplToJson(_$TickItemImpl instance) =>
    <String, dynamic>{
      'shot_id': instance.shotId,
      'ok': instance.ok,
      'error': instance.error?.toJson(),
    };

_$ShotTickResultImpl _$$ShotTickResultImplFromJson(Map<String, dynamic> json) =>
    _$ShotTickResultImpl(
      results: (json['results'] as List<dynamic>)
          .map((e) => TickItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      shots: (json['shots'] as List<dynamic>)
          .map((e) => ShootShot.fromJson(e as Map<String, dynamic>))
          .toList(),
      piecesMoved: (json['pieces_moved'] as List<dynamic>)
          .map((e) => PieceRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ShotTickResultImplToJson(
  _$ShotTickResultImpl instance,
) => <String, dynamic>{
  'results': instance.results.map((e) => e.toJson()).toList(),
  'shots': instance.shots.map((e) => e.toJson()).toList(),
  'pieces_moved': instance.piecesMoved.map((e) => e.toJson()).toList(),
};

_$ShareLinkImpl _$$ShareLinkImplFromJson(Map<String, dynamic> json) =>
    _$ShareLinkImpl(
      url: json['url'] as String,
      token: json['token'] as String,
      message: json['message'] as String,
      whatsappUrl: json['whatsapp_url'] as String,
      regenerated: json['regenerated'] as bool,
    );

Map<String, dynamic> _$$ShareLinkImplToJson(_$ShareLinkImpl instance) =>
    <String, dynamic>{
      'url': instance.url,
      'token': instance.token,
      'message': instance.message,
      'whatsapp_url': instance.whatsappUrl,
      'regenerated': instance.regenerated,
    };

_$PrepItemImpl _$$PrepItemImplFromJson(Map<String, dynamic> json) =>
    _$PrepItemImpl(text: json['text'] as String, done: json['done'] as bool);

Map<String, dynamic> _$$PrepItemImplToJson(_$PrepItemImpl instance) =>
    <String, dynamic>{'text': instance.text, 'done': instance.done};

_$PublicPrepImpl _$$PublicPrepImplFromJson(Map<String, dynamic> json) =>
    _$PublicPrepImpl(
      title: json['title'] as String,
      shootDate: json['shoot_date'] as String?,
      shootTime: json['shoot_time'] as String?,
      place: json['place'] as String?,
      kit: json['kit'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((e) => PrepItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$PublicPrepImplToJson(_$PublicPrepImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'shoot_date': instance.shootDate,
      'shoot_time': instance.shootTime,
      'place': instance.place,
      'kit': instance.kit,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

_$ConsentImpl _$$ConsentImplFromJson(Map<String, dynamic> json) =>
    _$ConsentImpl(
      status: $enumDecode(
        _$ConsentStatusEnumMap,
        json['status'],
        unknownValue: ConsentStatus.unknown,
      ),
      who: json['who'] as String?,
      date: json['date'] as String?,
      scope: $enumDecodeNullable(
        _$ConsentScopeEnumMap,
        json['scope'],
        unknownValue: ConsentScope.unknown,
      ),
      proof: json['proof'] == null
          ? null
          : StudioMedia.fromJson(json['proof'] as Map<String, dynamic>),
      loggedBy: json['logged_by'] == null
          ? null
          : PersonRef.fromJson(json['logged_by'] as Map<String, dynamic>),
      paidOk: json['paid_ok'] as bool,
    );

Map<String, dynamic> _$$ConsentImplToJson(_$ConsentImpl instance) =>
    <String, dynamic>{
      'status': _$ConsentStatusEnumMap[instance.status]!,
      'who': instance.who,
      'date': instance.date,
      'scope': _$ConsentScopeEnumMap[instance.scope],
      'proof': instance.proof?.toJson(),
      'logged_by': instance.loggedBy?.toJson(),
      'paid_ok': instance.paidOk,
    };

const _$ConsentStatusEnumMap = {
  ConsentStatus.notNeeded: 'Not needed',
  ConsentStatus.asked: 'Asked',
  ConsentStatus.given: 'Given',
  ConsentStatus.refused: 'Refused',
  ConsentStatus.unknown: '__unknown__',
};

const _$ConsentScopeEnumMap = {
  ConsentScope.organicOnly: 'Organic only',
  ConsentScope.organicAndPaid: 'Organic and paid',
  ConsentScope.unknown: '__unknown__',
};

_$StudioAssetImpl _$$StudioAssetImplFromJson(Map<String, dynamic> json) =>
    _$StudioAssetImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      kind: $enumDecode(
        _$AssetKindEnumMap,
        json['kind'],
        unknownValue: AssetKind.unknown,
      ),
      media: json['media'] == null
          ? null
          : StudioMedia.fromJson(json['media'] as Map<String, dynamic>),
      flavour: json['flavour'] == null
          ? null
          : FlavourRef.fromJson(json['flavour'] as Map<String, dynamic>),
      category: $enumDecodeNullable(
        _$AssetCategoryEnumMap,
        json['category'],
        unknownValue: AssetCategory.unknown,
      ),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      theme: json['theme'] as String?,
      status: $enumDecode(
        _$AssetStatusEnumMap,
        json['status'],
        unknownValue: AssetStatus.unknown,
      ),
      uploadedBy: json['uploaded_by'] == null
          ? null
          : PersonRef.fromJson(json['uploaded_by'] as Map<String, dynamic>),
      usedCount: (json['used_count'] as num).toInt(),
      rating: RatingStats.fromJson(json['rating'] as Map<String, dynamic>),
      myRating: json['my_rating'] == null
          ? null
          : Rating.fromJson(json['my_rating'] as Map<String, dynamic>),
      commentsCount: (json['comments_count'] as num).toInt(),
      ratingOpen: json['rating_open'] as bool,
      hidden: json['hidden'] as bool,
      note: json['note'] as String?,
      sourceRef: json['source_ref'] as String?,
      consent: json['consent'] == null
          ? null
          : Consent.fromJson(json['consent'] as Map<String, dynamic>),
      created: json['created'] as String,
      modified: json['modified'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$StudioAssetImplToJson(_$StudioAssetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'kind': _$AssetKindEnumMap[instance.kind]!,
      'media': instance.media?.toJson(),
      'flavour': instance.flavour?.toJson(),
      'category': _$AssetCategoryEnumMap[instance.category],
      'tags': instance.tags,
      'theme': instance.theme,
      'status': _$AssetStatusEnumMap[instance.status]!,
      'uploaded_by': instance.uploadedBy?.toJson(),
      'used_count': instance.usedCount,
      'rating': instance.rating.toJson(),
      'my_rating': instance.myRating?.toJson(),
      'comments_count': instance.commentsCount,
      'rating_open': instance.ratingOpen,
      'hidden': instance.hidden,
      'note': instance.note,
      'source_ref': instance.sourceRef,
      'consent': instance.consent?.toJson(),
      'created': instance.created,
      'modified': instance.modified,
      'actions': instance.actions,
    };

const _$AssetCategoryEnumMap = {
  AssetCategory.customers: 'customers',
  AssetCategory.delivery: 'delivery',
  AssetCategory.jars: 'jars',
  AssetCategory.kitchen: 'kitchen',
  AssetCategory.other: 'other',
  AssetCategory.team: 'team',
  AssetCategory.unknown: '__unknown__',
};

const _$AssetStatusEnumMap = {
  AssetStatus.newValue: 'New',
  AssetStatus.used: 'Used',
  AssetStatus.skipped: 'Skipped',
  AssetStatus.retired: 'Retired',
  AssetStatus.unknown: '__unknown__',
};

_$UploadPutImpl _$$UploadPutImplFromJson(Map<String, dynamic> json) =>
    _$UploadPutImpl(
      method: json['method'] as String,
      url: json['url'] as String,
      headers: Map<String, String>.from(json['headers'] as Map),
    );

Map<String, dynamic> _$$UploadPutImplToJson(_$UploadPutImpl instance) =>
    <String, dynamic>{
      'method': instance.method,
      'url': instance.url,
      'headers': instance.headers,
    };

_$UploadPartImpl _$$UploadPartImplFromJson(Map<String, dynamic> json) =>
    _$UploadPartImpl(
      partNo: (json['part_no'] as num).toInt(),
      url: json['url'] as String,
      size: (json['size'] as num).toInt(),
    );

Map<String, dynamic> _$$UploadPartImplToJson(_$UploadPartImpl instance) =>
    <String, dynamic>{
      'part_no': instance.partNo,
      'url': instance.url,
      'size': instance.size,
    };

_$UploadBeginImpl _$$UploadBeginImplFromJson(Map<String, dynamic> json) =>
    _$UploadBeginImpl(
      uploadId: json['upload_id'] as String,
      mode: $enumDecode(
        _$UploadModeEnumMap,
        json['mode'],
        unknownValue: UploadMode.unknown,
      ),
      mediaKind: $enumDecode(
        _$MediaKindEnumMap,
        json['media_kind'],
        unknownValue: MediaKind.unknown,
      ),
      expiresAt: json['expires_at'] as String,
      partSize: (json['part_size'] as num?)?.toInt(),
      put: json['put'] == null
          ? null
          : UploadPut.fromJson(json['put'] as Map<String, dynamic>),
      parts: (json['parts'] as List<dynamic>)
          .map((e) => UploadPart.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$UploadBeginImplToJson(_$UploadBeginImpl instance) =>
    <String, dynamic>{
      'upload_id': instance.uploadId,
      'mode': _$UploadModeEnumMap[instance.mode]!,
      'media_kind': _$MediaKindEnumMap[instance.mediaKind]!,
      'expires_at': instance.expiresAt,
      'part_size': instance.partSize,
      'put': instance.put?.toJson(),
      'parts': instance.parts.map((e) => e.toJson()).toList(),
    };

const _$UploadModeEnumMap = {
  UploadMode.single: 'single',
  UploadMode.multipart: 'multipart',
  UploadMode.unknown: '__unknown__',
};

_$DownloadLinkImpl _$$DownloadLinkImplFromJson(Map<String, dynamic> json) =>
    _$DownloadLinkImpl(
      url: json['url'] as String,
      expiresAt: json['expires_at'] as String,
      filename: json['filename'] as String,
    );

Map<String, dynamic> _$$DownloadLinkImplToJson(_$DownloadLinkImpl instance) =>
    <String, dynamic>{
      'url': instance.url,
      'expires_at': instance.expiresAt,
      'filename': instance.filename,
    };

_$CompetitorBriefImpl _$$CompetitorBriefImplFromJson(
  Map<String, dynamic> json,
) => _$CompetitorBriefImpl(
  key: json['key'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$$CompetitorBriefImplToJson(
  _$CompetitorBriefImpl instance,
) => <String, dynamic>{'key': instance.key, 'name': instance.name};

_$LinkImpl _$$LinkImplFromJson(Map<String, dynamic> json) =>
    _$LinkImpl(label: json['label'] as String?, url: json['url'] as String);

Map<String, dynamic> _$$LinkImplToJson(_$LinkImpl instance) =>
    <String, dynamic>{'label': instance.label, 'url': instance.url};

_$MadeItemImpl _$$MadeItemImplFromJson(Map<String, dynamic> json) =>
    _$MadeItemImpl(
      versionId: json['version_id'] as String?,
      assetId: json['asset_id'] as String?,
      title: json['title'] as String,
    );

Map<String, dynamic> _$$MadeItemImplToJson(_$MadeItemImpl instance) =>
    <String, dynamic>{
      'version_id': instance.versionId,
      'asset_id': instance.assetId,
      'title': instance.title,
    };

_$NoteImpl _$$NoteImplFromJson(Map<String, dynamic> json) => _$NoteImpl(
  author: PersonRef.fromJson(json['author'] as Map<String, dynamic>),
  at: json['at'] as String,
  text: json['text'] as String,
);

Map<String, dynamic> _$$NoteImplToJson(_$NoteImpl instance) =>
    <String, dynamic>{
      'author': instance.author.toJson(),
      'at': instance.at,
      'text': instance.text,
    };

_$ShotLinkImpl _$$ShotLinkImplFromJson(Map<String, dynamic> json) =>
    _$ShotLinkImpl(
      linkId: json['link_id'] as String,
      shotId: json['shot_id'] as String?,
      pieceId: json['piece_id'] as String?,
      grade: $enumDecodeNullable(
        _$RefGradeEnumMap,
        json['grade'],
        unknownValue: RefGrade.unknown,
      ),
      real: json['real'] as bool,
    );

Map<String, dynamic> _$$ShotLinkImplToJson(_$ShotLinkImpl instance) =>
    <String, dynamic>{
      'link_id': instance.linkId,
      'shot_id': instance.shotId,
      'piece_id': instance.pieceId,
      'grade': _$RefGradeEnumMap[instance.grade],
      'real': instance.real,
    };

_$ReferenceBriefImpl _$$ReferenceBriefImplFromJson(Map<String, dynamic> json) =>
    _$ReferenceBriefImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      brand: json['brand'] as String?,
      status: $enumDecode(
        _$RefStatusEnumMap,
        json['status'],
        unknownValue: RefStatus.unknown,
      ),
      mediaType: $enumDecodeNullable(
        _$RefMediaEnumMap,
        json['media_type'],
        unknownValue: RefMedia.unknown,
      ),
      srcType: $enumDecodeNullable(
        _$RefSrcTypeEnumMap,
        json['src_type'],
        unknownValue: RefSrcType.unknown,
      ),
      image: json['image'] == null
          ? null
          : StudioMedia.fromJson(json['image'] as Map<String, dynamic>),
      url: json['url'] as String?,
      remake: $enumDecodeNullable(
        _$RemakeFitEnumMap,
        json['remake'],
        unknownValue: RemakeFit.unknown,
      ),
    );

Map<String, dynamic> _$$ReferenceBriefImplToJson(
  _$ReferenceBriefImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'brand': instance.brand,
  'status': _$RefStatusEnumMap[instance.status]!,
  'media_type': _$RefMediaEnumMap[instance.mediaType],
  'src_type': _$RefSrcTypeEnumMap[instance.srcType],
  'image': instance.image?.toJson(),
  'url': instance.url,
  'remake': _$RemakeFitEnumMap[instance.remake],
};

const _$RefStatusEnumMap = {
  RefStatus.newValue: 'New',
  RefStatus.shortlisted: 'Shortlisted',
  RefStatus.forAShoot: 'For a shoot',
  RefStatus.remade: 'Remade',
  RefStatus.dropped: 'Dropped',
  RefStatus.unknown: '__unknown__',
};

const _$RefMediaEnumMap = {
  RefMedia.staticValue: 'static',
  RefMedia.reel: 'reel',
  RefMedia.carousel: 'carousel',
  RefMedia.unknown: '__unknown__',
};

const _$RefSrcTypeEnumMap = {
  RefSrcType.metaAd: 'meta_ad',
  RefSrcType.tiktokAd: 'tiktok_ad',
  RefSrcType.igPost: 'ig_post',
  RefSrcType.igReel: 'ig_reel',
  RefSrcType.other: 'other',
  RefSrcType.unknown: '__unknown__',
};

const _$RemakeFitEnumMap = {
  RemakeFit.ok: 'ok',
  RemakeFit.learn: 'learn',
  RemakeFit.unknown: '__unknown__',
};

_$StudioReferenceImpl _$$StudioReferenceImplFromJson(
  Map<String, dynamic> json,
) => _$StudioReferenceImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  brand: json['brand'] as String?,
  status: $enumDecode(
    _$RefStatusEnumMap,
    json['status'],
    unknownValue: RefStatus.unknown,
  ),
  mediaType: $enumDecodeNullable(
    _$RefMediaEnumMap,
    json['media_type'],
    unknownValue: RefMedia.unknown,
  ),
  srcType: $enumDecodeNullable(
    _$RefSrcTypeEnumMap,
    json['src_type'],
    unknownValue: RefSrcType.unknown,
  ),
  image: json['image'] == null
      ? null
      : StudioMedia.fromJson(json['image'] as Map<String, dynamic>),
  url: json['url'] as String?,
  remake: $enumDecodeNullable(
    _$RemakeFitEnumMap,
    json['remake'],
    unknownValue: RemakeFit.unknown,
  ),
  competitor: json['competitor'] == null
      ? null
      : CompetitorBrief.fromJson(json['competitor'] as Map<String, dynamic>),
  src: json['src'] as String?,
  sourceDate: json['source_date'] as String?,
  text: json['text'] as String?,
  why: json['why'] as String?,
  take: json['take'] as String?,
  market: $enumDecodeNullable(
    _$CompMarketEnumMap,
    json['market'],
    unknownValue: CompMarket.unknown,
  ),
  formatNo: (json['format_no'] as num?)?.toInt(),
  hookNo: (json['hook_no'] as num?)?.toInt(),
  aware: (json['aware'] as num?)?.toInt(),
  persona: $enumDecodeNullable(
    _$RefPersonaEnumMap,
    json['persona'],
    unknownValue: RefPersona.unknown,
  ),
  situation: $enumDecodeNullable(
    _$RefSituationEnumMap,
    json['situation'],
    unknownValue: RefSituation.unknown,
  ),
  layer: $enumDecodeNullable(
    _$RefLayerEnumMap,
    json['layer'],
    unknownValue: RefLayer.unknown,
  ),
  look: $enumDecodeNullable(
    _$RefLookEnumMap,
    json['look'],
    unknownValue: RefLook.unknown,
  ),
  feasibility: $enumDecodeNullable(
    _$FeasibilityEnumMap,
    json['feasibility'],
    unknownValue: Feasibility.unknown,
  ),
  feasibilityBlock: json['feasibility_block'] as String?,
  feasibilityMake: json['feasibility_make'] as String?,
  metrics: (json['metrics'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  locked: json['locked'] as bool,
  addedBy: json['added_by'] as String?,
  links: (json['links'] as List<dynamic>)
      .map((e) => Link.fromJson(e as Map<String, dynamic>))
      .toList(),
  made: (json['made'] as List<dynamic>)
      .map((e) => MadeItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  notes: (json['notes'] as List<dynamic>)
      .map((e) => Note.fromJson(e as Map<String, dynamic>))
      .toList(),
  shotLinks: (json['shot_links'] as List<dynamic>)
      .map((e) => ShotLink.fromJson(e as Map<String, dynamic>))
      .toList(),
  created: json['created'] as String,
  modified: json['modified'] as String,
  actions: (json['actions'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$$StudioReferenceImplToJson(
  _$StudioReferenceImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'brand': instance.brand,
  'status': _$RefStatusEnumMap[instance.status]!,
  'media_type': _$RefMediaEnumMap[instance.mediaType],
  'src_type': _$RefSrcTypeEnumMap[instance.srcType],
  'image': instance.image?.toJson(),
  'url': instance.url,
  'remake': _$RemakeFitEnumMap[instance.remake],
  'competitor': instance.competitor?.toJson(),
  'src': instance.src,
  'source_date': instance.sourceDate,
  'text': instance.text,
  'why': instance.why,
  'take': instance.take,
  'market': _$CompMarketEnumMap[instance.market],
  'format_no': instance.formatNo,
  'hook_no': instance.hookNo,
  'aware': instance.aware,
  'persona': _$RefPersonaEnumMap[instance.persona],
  'situation': _$RefSituationEnumMap[instance.situation],
  'layer': _$RefLayerEnumMap[instance.layer],
  'look': _$RefLookEnumMap[instance.look],
  'feasibility': _$FeasibilityEnumMap[instance.feasibility],
  'feasibility_block': instance.feasibilityBlock,
  'feasibility_make': instance.feasibilityMake,
  'metrics': instance.metrics,
  'locked': instance.locked,
  'added_by': instance.addedBy,
  'links': instance.links.map((e) => e.toJson()).toList(),
  'made': instance.made.map((e) => e.toJson()).toList(),
  'notes': instance.notes.map((e) => e.toJson()).toList(),
  'shot_links': instance.shotLinks.map((e) => e.toJson()).toList(),
  'created': instance.created,
  'modified': instance.modified,
  'actions': instance.actions,
};

const _$CompMarketEnumMap = {
  CompMarket.eG: 'EG',
  CompMarket.gCC: 'GCC',
  CompMarket.mENA: 'MENA',
  CompMarket.uK: 'UK',
  CompMarket.eU: 'EU',
  CompMarket.uS: 'US',
  CompMarket.iN: 'IN',
  CompMarket.aU: 'AU',
  CompMarket.tR: 'TR',
  CompMarket.oTHER: 'OTHER',
  CompMarket.unknown: '__unknown__',
};

const _$RefPersonaEnumMap = {
  RefPersona.household: 'household',
  RefPersona.self: 'self',
  RefPersona.both: 'both',
  RefPersona.unknown: '__unknown__',
};

const _$RefSituationEnumMap = {
  RefSituation.house: 'house',
  RefSituation.me: 'me',
  RefSituation.guests: 'guests',
  RefSituation.gift: 'gift',
  RefSituation.office: 'office',
  RefSituation.other: 'other',
  RefSituation.unknown: '__unknown__',
};

const _$RefLayerEnumMap = {
  RefLayer.hero: 'hero',
  RefLayer.hub: 'hub',
  RefLayer.hygiene: 'hygiene',
  RefLayer.unknown: '__unknown__',
};

const _$RefLookEnumMap = {
  RefLook.aesthetic: 'Aesthetic',
  RefLook.founder: 'Founder',
  RefLook.product: 'Product',
  RefLook.uGC: 'UGC',
  RefLook.unknown: '__unknown__',
};

const _$FeasibilityEnumMap = {
  Feasibility.inbox: 'inbox',
  Feasibility.can: 'can',
  Feasibility.needs: 'needs',
  Feasibility.cant: 'cant',
  Feasibility.used: 'used',
  Feasibility.unknown: '__unknown__',
};

_$StudioCompetitorImpl _$$StudioCompetitorImplFromJson(
  Map<String, dynamic> json,
) => _$StudioCompetitorImpl(
  key: json['key'] as String,
  name: json['name'] as String,
  competitorGroup: $enumDecode(
    _$CompGroupEnumMap,
    json['competitor_group'],
    unknownValue: CompGroup.unknown,
  ),
  market: $enumDecodeNullable(
    _$CompMarketEnumMap,
    json['market'],
    unknownValue: CompMarket.unknown,
  ),
  tier: $enumDecodeNullable(
    _$CompTierEnumMap,
    json['tier'],
    unknownValue: CompTier.unknown,
  ),
  igHandle: json['ig_handle'] as String?,
  tiktokHandle: json['tiktok_handle'] as String?,
  site: json['site'] as String?,
  adlibUrl: json['adlib_url'] as String?,
  summary: json['summary'] as String?,
  followers: (json['followers'] as num?)?.toInt(),
  liveAds: (json['live_ads'] as num?)?.toInt(),
  outliers: (json['outliers'] as num?)?.toInt(),
  survivors: (json['survivors'] as num?)?.toInt(),
  image: json['image'] == null
      ? null
      : StudioMedia.fromJson(json['image'] as Map<String, dynamic>),
  status: $enumDecode(
    _$CompStatusEnumMap,
    json['status'],
    unknownValue: CompStatus.unknown,
  ),
  removedWhy: json['removed_why'] as String?,
  notes: (json['notes'] as List<dynamic>)
      .map((e) => Note.fromJson(e as Map<String, dynamic>))
      .toList(),
  referencesCount: (json['references_count'] as num).toInt(),
  modified: json['modified'] as String,
);

Map<String, dynamic> _$$StudioCompetitorImplToJson(
  _$StudioCompetitorImpl instance,
) => <String, dynamic>{
  'key': instance.key,
  'name': instance.name,
  'competitor_group': _$CompGroupEnumMap[instance.competitorGroup]!,
  'market': _$CompMarketEnumMap[instance.market],
  'tier': _$CompTierEnumMap[instance.tier],
  'ig_handle': instance.igHandle,
  'tiktok_handle': instance.tiktokHandle,
  'site': instance.site,
  'adlib_url': instance.adlibUrl,
  'summary': instance.summary,
  'followers': instance.followers,
  'live_ads': instance.liveAds,
  'outliers': instance.outliers,
  'survivors': instance.survivors,
  'image': instance.image?.toJson(),
  'status': _$CompStatusEnumMap[instance.status]!,
  'removed_why': instance.removedWhy,
  'notes': instance.notes.map((e) => e.toJson()).toList(),
  'references_count': instance.referencesCount,
  'modified': instance.modified,
};

const _$CompGroupEnumMap = {
  CompGroup.egDessert: 'eg-dessert',
  CompGroup.egCafe: 'eg-cafe',
  CompGroup.oom: 'oom',
  CompGroup.unknown: '__unknown__',
};

const _$CompTierEnumMap = {
  CompTier.a: 'A',
  CompTier.b: 'B',
  CompTier.unknown: '__unknown__',
};

const _$CompStatusEnumMap = {
  CompStatus.active: 'Active',
  CompStatus.removed: 'Removed',
  CompStatus.unknown: '__unknown__',
};

_$AdNumbersImpl _$$AdNumbersImplFromJson(Map<String, dynamic> json) =>
    _$AdNumbersImpl(
      windowStart: json['window_start'] as String,
      windowEnd: json['window_end'] as String,
      spend: (json['spend'] as num).toInt(),
      impressions: (json['impressions'] as num).toInt(),
      reach: (json['reach'] as num).toInt(),
      purchases: (json['purchases'] as num).toInt(),
      purchaseValue: (json['purchase_value'] as num).toInt(),
      cpa: (json['cpa'] as num?)?.toInt(),
      ctr: (json['ctr'] as num?)?.toDouble(),
      frequency: (json['frequency'] as num?)?.toDouble(),
      hold3: (json['hold3'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$AdNumbersImplToJson(_$AdNumbersImpl instance) =>
    <String, dynamic>{
      'window_start': instance.windowStart,
      'window_end': instance.windowEnd,
      'spend': instance.spend,
      'impressions': instance.impressions,
      'reach': instance.reach,
      'purchases': instance.purchases,
      'purchase_value': instance.purchaseValue,
      'cpa': instance.cpa,
      'ctr': instance.ctr,
      'frequency': instance.frequency,
      'hold3': instance.hold3,
    };

_$AdWindowsImpl _$$AdWindowsImplFromJson(Map<String, dynamic> json) =>
    _$AdWindowsImpl(d4: json['d4'] as String?, d7: json['d7'] as String?);

Map<String, dynamic> _$$AdWindowsImplToJson(_$AdWindowsImpl instance) =>
    <String, dynamic>{'d4': instance.d4, 'd7': instance.d7};

_$AdHintImpl _$$AdHintImplFromJson(Map<String, dynamic> json) => _$AdHintImpl(
  text: json['text'] as String,
  level: $enumDecode(
    _$NoteLevelEnumMap,
    json['level'],
    unknownValue: NoteLevel.unknown,
  ),
);

Map<String, dynamic> _$$AdHintImplToJson(_$AdHintImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'level': _$NoteLevelEnumMap[instance.level]!,
    };

_$PaidAdImpl _$$PaidAdImplFromJson(Map<String, dynamic> json) => _$PaidAdImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  piece: json['piece'] == null
      ? null
      : PieceRef.fromJson(json['piece'] as Map<String, dynamic>),
  version: json['version'] == null
      ? null
      : VersionBrief.fromJson(json['version'] as Map<String, dynamic>),
  roundCode: json['round_code'] as String?,
  adset: json['adset'] as String?,
  socialAdId: json['social_ad_id'] as String?,
  metaAdId: json['meta_ad_id'] as String?,
  state: $enumDecodeNullable(
    _$AdStateEnumMap,
    json['state'],
    unknownValue: AdState.unknown,
  ),
  stateLabel: json['state_label'] as String,
  queueRank: (json['queue_rank'] as num?)?.toInt(),
  queueNote: json['queue_note'] as String?,
  cboOn: json['cbo_on'] as String?,
  stateSetAt: json['state_set_at'] as String?,
  headlineAr: json['headline_ar'] as String?,
  headlineEn: json['headline_en'] as String?,
  primaryText: json['primary_text'] as String?,
  thumb: json['thumb'] == null
      ? null
      : StudioMedia.fromJson(json['thumb'] as Map<String, dynamic>),
  numbers: json['numbers'] == null
      ? null
      : AdNumbers.fromJson(json['numbers'] as Map<String, dynamic>),
  windows: AdWindows.fromJson(json['windows'] as Map<String, dynamic>),
  readDue: $enumDecodeNullable(
    _$ReadWindowEnumMap,
    json['read_due'],
    unknownValue: ReadWindow.unknown,
  ),
  hint: json['hint'] == null
      ? null
      : AdHint.fromJson(json['hint'] as Map<String, dynamic>),
  note: json['note'] as String?,
  modified: json['modified'] as String,
  actions: (json['actions'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$$PaidAdImplToJson(_$PaidAdImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'piece': instance.piece?.toJson(),
      'version': instance.version?.toJson(),
      'round_code': instance.roundCode,
      'adset': instance.adset,
      'social_ad_id': instance.socialAdId,
      'meta_ad_id': instance.metaAdId,
      'state': _$AdStateEnumMap[instance.state],
      'state_label': instance.stateLabel,
      'queue_rank': instance.queueRank,
      'queue_note': instance.queueNote,
      'cbo_on': instance.cboOn,
      'state_set_at': instance.stateSetAt,
      'headline_ar': instance.headlineAr,
      'headline_en': instance.headlineEn,
      'primary_text': instance.primaryText,
      'thumb': instance.thumb?.toJson(),
      'numbers': instance.numbers?.toJson(),
      'windows': instance.windows.toJson(),
      'read_due': _$ReadWindowEnumMap[instance.readDue],
      'hint': instance.hint?.toJson(),
      'note': instance.note,
      'modified': instance.modified,
      'actions': instance.actions,
    };

const _$ReadWindowEnumMap = {
  ReadWindow.d4: 'd4',
  ReadWindow.d7: 'd7',
  ReadWindow.unknown: '__unknown__',
};

_$PaidRoundImpl _$$PaidRoundImplFromJson(Map<String, dynamic> json) =>
    _$PaidRoundImpl(
      code: json['code'] as String,
      title: json['title'] as String?,
      launchDate: json['launch_date'] as String,
      d4Date: json['d4_date'] as String,
      d7Date: json['d7_date'] as String,
      assignee: json['assignee'] == null
          ? null
          : PersonRef.fromJson(json['assignee'] as Map<String, dynamic>),
      note: json['note'] as String?,
      ads: (json['ads'] as List<dynamic>)
          .map((e) => PaidAd.fromJson(e as Map<String, dynamic>))
          .toList(),
      stateCounts: Map<String, int>.from(json['state_counts'] as Map),
      modified: json['modified'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$PaidRoundImplToJson(_$PaidRoundImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'title': instance.title,
      'launch_date': instance.launchDate,
      'd4_date': instance.d4Date,
      'd7_date': instance.d7Date,
      'assignee': instance.assignee?.toJson(),
      'note': instance.note,
      'ads': instance.ads.map((e) => e.toJson()).toList(),
      'state_counts': instance.stateCounts,
      'modified': instance.modified,
      'actions': instance.actions,
    };

_$PaidDueImpl _$$PaidDueImplFromJson(Map<String, dynamic> json) =>
    _$PaidDueImpl(
      kind: $enumDecode(
        _$PaidDueKindEnumMap,
        json['kind'],
        unknownValue: PaidDueKind.unknown,
      ),
      title: json['title'] as String,
      why: json['why'] as String,
      dueDate: json['due_date'] as String,
      level: $enumDecode(
        _$NoteLevelEnumMap,
        json['level'],
        unknownValue: NoteLevel.unknown,
      ),
      route: json['route'] as String,
      adId: json['ad_id'] as String?,
      roundCode: json['round_code'] as String?,
    );

Map<String, dynamic> _$$PaidDueImplToJson(_$PaidDueImpl instance) =>
    <String, dynamic>{
      'kind': _$PaidDueKindEnumMap[instance.kind]!,
      'title': instance.title,
      'why': instance.why,
      'due_date': instance.dueDate,
      'level': _$NoteLevelEnumMap[instance.level]!,
      'route': instance.route,
      'ad_id': instance.adId,
      'round_code': instance.roundCode,
    };

const _$PaidDueKindEnumMap = {
  PaidDueKind.readD4: 'read_d4',
  PaidDueKind.readD7: 'read_d7',
  PaidDueKind.roundLaunch: 'round_launch',
  PaidDueKind.budgetStep: 'budget_step',
  PaidDueKind.retire: 'retire',
  PaidDueKind.stepGate: 'step_gate',
  PaidDueKind.unknown: '__unknown__',
};

_$QueueItemImpl _$$QueueItemImplFromJson(Map<String, dynamic> json) =>
    _$QueueItemImpl(
      adId: json['ad_id'] as String,
      version: VersionBrief.fromJson(json['version'] as Map<String, dynamic>),
      piece: PieceSummary.fromJson(json['piece'] as Map<String, dynamic>),
      queueRank: (json['queue_rank'] as num).toInt(),
      queueNote: json['queue_note'] as String?,
      readyForAds: json['ready_for_ads'] as bool,
      queuedBy: json['queued_by'] == null
          ? null
          : PersonRef.fromJson(json['queued_by'] as Map<String, dynamic>),
      queuedAt: json['queued_at'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$QueueItemImplToJson(_$QueueItemImpl instance) =>
    <String, dynamic>{
      'ad_id': instance.adId,
      'version': instance.version.toJson(),
      'piece': instance.piece.toJson(),
      'queue_rank': instance.queueRank,
      'queue_note': instance.queueNote,
      'ready_for_ads': instance.readyForAds,
      'queued_by': instance.queuedBy?.toJson(),
      'queued_at': instance.queuedAt,
      'actions': instance.actions,
    };

_$PaidQueueImpl _$$PaidQueueImplFromJson(Map<String, dynamic> json) =>
    _$PaidQueueImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => QueueItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$PaidQueueImplToJson(_$PaidQueueImpl instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

_$PaidOverviewImpl _$$PaidOverviewImplFromJson(Map<String, dynamic> json) =>
    _$PaidOverviewImpl(
      asOf: json['as_of'] as String,
      rounds: (json['rounds'] as List<dynamic>)
          .map((e) => RoundBrief.fromJson(e as Map<String, dynamic>))
          .toList(),
      due: (json['due'] as List<dynamic>)
          .map((e) => PaidDue.fromJson(e as Map<String, dynamic>))
          .toList(),
      queue: (json['queue'] as List<dynamic>)
          .map((e) => QueueItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      stopSigns: (json['stop_signs'] as List<dynamic>)
          .map((e) => Signal.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$PaidOverviewImplToJson(_$PaidOverviewImpl instance) =>
    <String, dynamic>{
      'as_of': instance.asOf,
      'rounds': instance.rounds.map((e) => e.toJson()).toList(),
      'due': instance.due.map((e) => e.toJson()).toList(),
      'queue': instance.queue.map((e) => e.toJson()).toList(),
      'stop_signs': instance.stopSigns.map((e) => e.toJson()).toList(),
    };

_$PostReadImpl _$$PostReadImplFromJson(Map<String, dynamic> json) =>
    _$PostReadImpl(
      postId: json['post_id'] as String,
      pieceId: json['piece_id'] as String,
      bucket: $enumDecode(
        _$ReadBucketEnumMap,
        json['bucket'],
        unknownValue: ReadBucket.unknown,
      ),
      opensOn: json['opens_on'] as String,
      due: json['due'] as bool,
      filed: json['filed'] as bool,
      reach: (json['reach'] as num?)?.toInt(),
      views: (json['views'] as num?)?.toInt(),
      shares: (json['shares'] as num?)?.toInt(),
      saves: (json['saves'] as num?)?.toInt(),
      likes: (json['likes'] as num?)?.toInt(),
      commentsCount: (json['comments_count'] as num?)?.toInt(),
      avgWatchS: (json['avg_watch_s'] as num?)?.toDouble(),
      totalWatchS: (json['total_watch_s'] as num?)?.toDouble(),
      skipRate: (json['skip_rate'] as num?)?.toDouble(),
      sharesPerReach: (json['shares_per_reach'] as num?)?.toDouble(),
      fbReach: (json['fb_reach'] as num?)?.toInt(),
      fbViews: (json['fb_views'] as num?)?.toInt(),
      hold3Pct: (json['hold3_pct'] as num?)?.toDouble(),
      sends: (json['sends'] as num?)?.toInt(),
      reelLenS: (json['reel_len_s'] as num?)?.toDouble(),
      source: $enumDecodeNullable(
        _$ReadSourceEnumMap,
        json['source'],
        unknownValue: ReadSource.unknown,
      ),
      enteredBy: json['entered_by'] as String?,
      pulledAt: json['pulled_at'] as String?,
      missing: (json['missing'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$PostReadImplToJson(_$PostReadImpl instance) =>
    <String, dynamic>{
      'post_id': instance.postId,
      'piece_id': instance.pieceId,
      'bucket': _$ReadBucketEnumMap[instance.bucket]!,
      'opens_on': instance.opensOn,
      'due': instance.due,
      'filed': instance.filed,
      'reach': instance.reach,
      'views': instance.views,
      'shares': instance.shares,
      'saves': instance.saves,
      'likes': instance.likes,
      'comments_count': instance.commentsCount,
      'avg_watch_s': instance.avgWatchS,
      'total_watch_s': instance.totalWatchS,
      'skip_rate': instance.skipRate,
      'shares_per_reach': instance.sharesPerReach,
      'fb_reach': instance.fbReach,
      'fb_views': instance.fbViews,
      'hold3_pct': instance.hold3Pct,
      'sends': instance.sends,
      'reel_len_s': instance.reelLenS,
      'source': _$ReadSourceEnumMap[instance.source],
      'entered_by': instance.enteredBy,
      'pulled_at': instance.pulledAt,
      'missing': instance.missing,
    };

const _$ReadBucketEnumMap = {
  ReadBucket.v24h: '24h',
  ReadBucket.v72h: '72h',
  ReadBucket.v3d: '3d',
  ReadBucket.v7d: '7d',
  ReadBucket.manual: 'manual',
  ReadBucket.unknown: '__unknown__',
};

const _$ReadSourceEnumMap = {
  ReadSource.api: 'api',
  ReadSource.hand: 'hand',
  ReadSource.legacy: 'legacy',
  ReadSource.unknown: '__unknown__',
};

_$ScorecardNumberImpl _$$ScorecardNumberImplFromJson(
  Map<String, dynamic> json,
) => _$ScorecardNumberImpl(
  key: json['key'] as String,
  label: json['label'] as String,
  value: (json['value'] as num?)?.toDouble(),
  unit: json['unit'] as String,
  line: (json['line'] as num?)?.toDouble(),
  ok: json['ok'] as bool?,
  source: $enumDecode(
    _$ScoreSourceEnumMap,
    json['source'],
    unknownValue: ScoreSource.unknown,
  ),
);

Map<String, dynamic> _$$ScorecardNumberImplToJson(
  _$ScorecardNumberImpl instance,
) => <String, dynamic>{
  'key': instance.key,
  'label': instance.label,
  'value': instance.value,
  'unit': instance.unit,
  'line': instance.line,
  'ok': instance.ok,
  'source': _$ScoreSourceEnumMap[instance.source]!,
};

const _$ScoreSourceEnumMap = {
  ScoreSource.system: 'system',
  ScoreSource.person: 'person',
  ScoreSource.missing: 'missing',
  ScoreSource.unknown: '__unknown__',
};

_$ScorecardGateImpl _$$ScorecardGateImplFromJson(Map<String, dynamic> json) =>
    _$ScorecardGateImpl(
      key: json['key'] as String,
      label: json['label'] as String,
      ok: json['ok'] as bool,
      detail: json['detail'] as String?,
    );

Map<String, dynamic> _$$ScorecardGateImplToJson(_$ScorecardGateImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'ok': instance.ok,
      'detail': instance.detail,
    };

_$ScorecardLineImpl _$$ScorecardLineImplFromJson(Map<String, dynamic> json) =>
    _$ScorecardLineImpl(
      label: json['label'] as String,
      value: json['value'] as String?,
      source: $enumDecode(
        _$ScoreSourceEnumMap,
        json['source'],
        unknownValue: ScoreSource.unknown,
      ),
      by: json['by'] == null
          ? null
          : PersonRef.fromJson(json['by'] as Map<String, dynamic>),
      at: json['at'] as String?,
    );

Map<String, dynamic> _$$ScorecardLineImplToJson(_$ScorecardLineImpl instance) =>
    <String, dynamic>{
      'label': instance.label,
      'value': instance.value,
      'source': _$ScoreSourceEnumMap[instance.source]!,
      'by': instance.by?.toJson(),
      'at': instance.at,
    };

_$WeekScorecardImpl _$$WeekScorecardImplFromJson(Map<String, dynamic> json) =>
    _$WeekScorecardImpl(
      id: json['id'] as String,
      weekStart: json['week_start'] as String,
      weekEnd: json['week_end'] as String,
      status: $enumDecode(
        _$ScorecardStatusEnumMap,
        json['status'],
        unknownValue: ScorecardStatus.unknown,
      ),
      numbers: (json['numbers'] as List<dynamic>)
          .map((e) => ScorecardNumber.fromJson(e as Map<String, dynamic>))
          .toList(),
      gates: (json['gates'] as List<dynamic>)
          .map((e) => ScorecardGate.fromJson(e as Map<String, dynamic>))
          .toList(),
      gatesHeldWeeks: (json['gates_held_weeks'] as num).toInt(),
      lines: (json['lines'] as List<dynamic>)
          .map((e) => ScorecardLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviewNotes: json['review_notes'] as String?,
      actionsAgreed: json['actions_agreed'] as String?,
      reviewedBy: json['reviewed_by'] == null
          ? null
          : PersonRef.fromJson(json['reviewed_by'] as Map<String, dynamic>),
      reviewedAt: json['reviewed_at'] as String?,
      modified: json['modified'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$WeekScorecardImplToJson(_$WeekScorecardImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'week_start': instance.weekStart,
      'week_end': instance.weekEnd,
      'status': _$ScorecardStatusEnumMap[instance.status]!,
      'numbers': instance.numbers.map((e) => e.toJson()).toList(),
      'gates': instance.gates.map((e) => e.toJson()).toList(),
      'gates_held_weeks': instance.gatesHeldWeeks,
      'lines': instance.lines.map((e) => e.toJson()).toList(),
      'review_notes': instance.reviewNotes,
      'actions_agreed': instance.actionsAgreed,
      'reviewed_by': instance.reviewedBy?.toJson(),
      'reviewed_at': instance.reviewedAt,
      'modified': instance.modified,
      'actions': instance.actions,
    };

const _$ScorecardStatusEnumMap = {
  ScorecardStatus.filling: 'Filling',
  ScorecardStatus.ready: 'Ready',
  ScorecardStatus.reviewed: 'Reviewed',
  ScorecardStatus.unknown: '__unknown__',
};

_$PieceResultImpl _$$PieceResultImplFromJson(Map<String, dynamic> json) =>
    _$PieceResultImpl(
      piece: PieceSummary.fromJson(json['piece'] as Map<String, dynamic>),
      posts: (json['posts'] as List<dynamic>)
          .map((e) => PostSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      reads: (json['reads'] as List<dynamic>)
          .map((e) => PostRead.fromJson(e as Map<String, dynamic>))
          .toList(),
      ads: (json['ads'] as List<dynamic>)
          .map((e) => AdBrief.fromJson(e as Map<String, dynamic>))
          .toList(),
      bestViews: (json['best_views'] as num?)?.toInt(),
      bestHold3: (json['best_hold3'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$PieceResultImplToJson(_$PieceResultImpl instance) =>
    <String, dynamic>{
      'piece': instance.piece.toJson(),
      'posts': instance.posts.map((e) => e.toJson()).toList(),
      'reads': instance.reads.map((e) => e.toJson()).toList(),
      'ads': instance.ads.map((e) => e.toJson()).toList(),
      'best_views': instance.bestViews,
      'best_hold3': instance.bestHold3,
    };

_$ResultGroupImpl _$$ResultGroupImplFromJson(Map<String, dynamic> json) =>
    _$ResultGroupImpl(
      key: json['key'] as String,
      label: json['label'] as String,
      pieces: (json['pieces'] as num).toInt(),
      posts: (json['posts'] as num).toInt(),
      reads: (json['reads'] as num).toInt(),
      avgViews: (json['avg_views'] as num?)?.toDouble(),
      avgHold3: (json['avg_hold3'] as num?)?.toDouble(),
      ads: (json['ads'] as num).toInt(),
      spend: (json['spend'] as num).toInt(),
      purchases: (json['purchases'] as num).toInt(),
    );

Map<String, dynamic> _$$ResultGroupImplToJson(_$ResultGroupImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'pieces': instance.pieces,
      'posts': instance.posts,
      'reads': instance.reads,
      'avg_views': instance.avgViews,
      'avg_hold3': instance.avgHold3,
      'ads': instance.ads,
      'spend': instance.spend,
      'purchases': instance.purchases,
    };

_$ResultSummaryImpl _$$ResultSummaryImplFromJson(Map<String, dynamic> json) =>
    _$ResultSummaryImpl(
      from: json['from'] as String,
      to: json['to'] as String,
      groupBy: json['group_by'] as String,
      groups: (json['groups'] as List<dynamic>)
          .map((e) => ResultGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ResultSummaryImplToJson(_$ResultSummaryImpl instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'group_by': instance.groupBy,
      'groups': instance.groups.map((e) => e.toJson()).toList(),
    };

_$ReportBriefImpl _$$ReportBriefImplFromJson(Map<String, dynamic> json) =>
    _$ReportBriefImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      kind: $enumDecode(
        _$ReportKindEnumMap,
        json['kind'],
        unknownValue: ReportKind.unknown,
      ),
      reportDate: json['report_date'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$$ReportBriefImplToJson(_$ReportBriefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'kind': _$ReportKindEnumMap[instance.kind]!,
      'report_date': instance.reportDate,
      'url': instance.url,
    };

const _$ReportKindEnumMap = {
  ReportKind.adsRead: 'Ads read',
  ReportKind.plan: 'Plan',
  ReportKind.study: 'Study',
  ReportKind.retro: 'Retro',
  ReportKind.competitorDaily: 'Competitor daily',
  ReportKind.referenceIntake: 'Reference intake',
  ReportKind.weeklyWorkingNow: 'Weekly working-now',
  ReportKind.sundayReview: 'Sunday review',
  ReportKind.other: 'Other',
  ReportKind.unknown: '__unknown__',
};

_$DecisionBriefImpl _$$DecisionBriefImplFromJson(Map<String, dynamic> json) =>
    _$DecisionBriefImpl(
      id: json['id'] as String,
      question: json['question'] as String,
      status: $enumDecode(
        _$DecisionStatusEnumMap,
        json['status'],
        unknownValue: DecisionStatus.unknown,
      ),
      waitingSince: json['waiting_since'] as String,
    );

Map<String, dynamic> _$$DecisionBriefImplToJson(_$DecisionBriefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'question': instance.question,
      'status': _$DecisionStatusEnumMap[instance.status]!,
      'waiting_since': instance.waitingSince,
    };

const _$DecisionStatusEnumMap = {
  DecisionStatus.open: 'Open',
  DecisionStatus.answered: 'Answered',
  DecisionStatus.superseded: 'Superseded',
  DecisionStatus.withdrawn: 'Withdrawn',
  DecisionStatus.unknown: '__unknown__',
};

_$StudioReportImpl _$$StudioReportImplFromJson(Map<String, dynamic> json) =>
    _$StudioReportImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      kind: $enumDecode(
        _$ReportKindEnumMap,
        json['kind'],
        unknownValue: ReportKind.unknown,
      ),
      reportDate: json['report_date'] as String,
      url: json['url'] as String,
      summary: json['summary'] as String?,
      createdBy: json['created_by'] as String,
      decisionsOpen: (json['decisions_open'] as num).toInt(),
      decisions: (json['decisions'] as List<dynamic>)
          .map((e) => DecisionBrief.fromJson(e as Map<String, dynamic>))
          .toList(),
      data: json['data'],
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$StudioReportImplToJson(_$StudioReportImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'kind': _$ReportKindEnumMap[instance.kind]!,
      'report_date': instance.reportDate,
      'url': instance.url,
      'summary': instance.summary,
      'created_by': instance.createdBy,
      'decisions_open': instance.decisionsOpen,
      'decisions': instance.decisions.map((e) => e.toJson()).toList(),
      'data': instance.data,
      'actions': instance.actions,
    };

_$DecisionOptionImpl _$$DecisionOptionImplFromJson(Map<String, dynamic> json) =>
    _$DecisionOptionImpl(
      index: (json['index'] as num).toInt(),
      label: json['label'] as String,
      pros: json['pros'] as String?,
      cons: json['cons'] as String?,
      mainRisk: json['main_risk'] as String?,
      whenRight: json['when_right'] as String?,
      recommended: json['recommended'] as bool,
      raisedByView: $enumDecodeNullable(
        _$ViewByEnumMap,
        json['raised_by_view'],
        unknownValue: ViewBy.unknown,
      ),
    );

Map<String, dynamic> _$$DecisionOptionImplToJson(
  _$DecisionOptionImpl instance,
) => <String, dynamic>{
  'index': instance.index,
  'label': instance.label,
  'pros': instance.pros,
  'cons': instance.cons,
  'main_risk': instance.mainRisk,
  'when_right': instance.whenRight,
  'recommended': instance.recommended,
  'raised_by_view': _$ViewByEnumMap[instance.raisedByView],
};

const _$ViewByEnumMap = {
  ViewBy.claude: 'claude',
  ViewBy.neon: 'neon',
  ViewBy.both: 'both',
  ViewBy.unknown: '__unknown__',
};

_$StudioDecisionImpl _$$StudioDecisionImplFromJson(Map<String, dynamic> json) =>
    _$StudioDecisionImpl(
      id: json['id'] as String,
      question: json['question'] as String,
      context: json['context'] as String?,
      status: $enumDecode(
        _$DecisionStatusEnumMap,
        json['status'],
        unknownValue: DecisionStatus.unknown,
      ),
      answerKind:
          $enumDecodeNullable(
            _$DecisionKindEnumMap,
            json['answer_kind'],
            unknownValue: DecisionKind.unknown,
          ) ??
          DecisionKind.option,
      options: (json['options'] as List<dynamic>)
          .map((e) => DecisionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendedIndex: (json['recommended_index'] as num?)?.toInt(),
      raisedBy: json['raised_by'] as String,
      report: json['report'] == null
          ? null
          : ReportBrief.fromJson(json['report'] as Map<String, dynamic>),
      pickedIndex: (json['picked_index'] as num?)?.toInt(),
      pickNote: json['pick_note'] as String?,
      answerText: json['answer_text'] as String?,
      answeredBy: json['answered_by'] == null
          ? null
          : PersonRef.fromJson(json['answered_by'] as Map<String, dynamic>),
      answeredAt: json['answered_at'] as String?,
      changed: json['changed'] == null
          ? null
          : DocRef.fromJson(json['changed'] as Map<String, dynamic>),
      waitingSince: json['waiting_since'] as String,
      modified: json['modified'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$StudioDecisionImplToJson(
  _$StudioDecisionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'question': instance.question,
  'context': instance.context,
  'status': _$DecisionStatusEnumMap[instance.status]!,
  'answer_kind': _$DecisionKindEnumMap[instance.answerKind]!,
  'options': instance.options.map((e) => e.toJson()).toList(),
  'recommended_index': instance.recommendedIndex,
  'raised_by': instance.raisedBy,
  'report': instance.report?.toJson(),
  'picked_index': instance.pickedIndex,
  'pick_note': instance.pickNote,
  'answer_text': instance.answerText,
  'answered_by': instance.answeredBy?.toJson(),
  'answered_at': instance.answeredAt,
  'changed': instance.changed?.toJson(),
  'waiting_since': instance.waitingSince,
  'modified': instance.modified,
  'actions': instance.actions,
};

const _$DecisionKindEnumMap = {
  DecisionKind.option: 'option',
  DecisionKind.text: 'text',
  DecisionKind.unknown: '__unknown__',
};

_$SignalImpl _$$SignalImplFromJson(Map<String, dynamic> json) => _$SignalImpl(
  id: json['id'] as String,
  signalDate: json['signal_date'] as String,
  section: $enumDecode(
    _$SignalSectionEnumMap,
    json['section'],
    unknownValue: SignalSection.unknown,
  ),
  src: json['src'] as String,
  key: json['key'] as String,
  level: $enumDecode(
    _$SignalLevelEnumMap,
    json['level'],
    unknownValue: SignalLevel.unknown,
  ),
  text: json['text'] as String,
  ownerName: json['owner_name'] as String?,
  ids: (json['ids'] as List<dynamic>).map((e) => e as String).toList(),
  resolved: json['resolved'] as bool,
  route: json['route'] as String?,
  actions: (json['actions'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$$SignalImplToJson(_$SignalImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'signal_date': instance.signalDate,
      'section': _$SignalSectionEnumMap[instance.section]!,
      'src': instance.src,
      'key': instance.key,
      'level': _$SignalLevelEnumMap[instance.level]!,
      'text': instance.text,
      'owner_name': instance.ownerName,
      'ids': instance.ids,
      'resolved': instance.resolved,
      'route': instance.route,
      'actions': instance.actions,
    };

const _$SignalSectionEnumMap = {
  SignalSection.paid: 'paid',
  SignalSection.signals: 'signals',
  SignalSection.ai: 'ai',
  SignalSection.budget: 'budget',
  SignalSection.unknown: '__unknown__',
};

const _$SignalLevelEnumMap = {
  SignalLevel.action: 'action',
  SignalLevel.warn: 'warn',
  SignalLevel.stop: 'stop',
  SignalLevel.red: 'red',
  SignalLevel.bad: 'bad',
  SignalLevel.info: 'info',
  SignalLevel.ok: 'ok',
  SignalLevel.unknown: '__unknown__',
};

_$NotificationItemImpl _$$NotificationItemImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationItemImpl(
  id: json['id'] as String,
  event: json['event'] as String,
  title: json['title'] as String,
  body: json['body'] as String?,
  route: json['route'] as String,
  doctype: json['doctype'] as String?,
  docname: json['docname'] as String?,
  read: json['read'] as bool,
  created: json['created'] as String,
);

Map<String, dynamic> _$$NotificationItemImplToJson(
  _$NotificationItemImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'event': instance.event,
  'title': instance.title,
  'body': instance.body,
  'route': instance.route,
  'doctype': instance.doctype,
  'docname': instance.docname,
  'read': instance.read,
  'created': instance.created,
};

_$UnreadCountImpl _$$UnreadCountImplFromJson(Map<String, dynamic> json) =>
    _$UnreadCountImpl(unread: (json['unread'] as num).toInt());

Map<String, dynamic> _$$UnreadCountImplToJson(_$UnreadCountImpl instance) =>
    <String, dynamic>{'unread': instance.unread};

_$EventInfoImpl _$$EventInfoImplFromJson(Map<String, dynamic> json) =>
    _$EventInfoImpl(
      event: json['event'] as String,
      label: json['label'] as String,
      audience: json['audience'] as String,
    );

Map<String, dynamic> _$$EventInfoImplToJson(_$EventInfoImpl instance) =>
    <String, dynamic>{
      'event': instance.event,
      'label': instance.label,
      'audience': instance.audience,
    };

_$NotificationPrefsImpl _$$NotificationPrefsImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationPrefsImpl(
  quietFrom: json['quiet_from'] as String?,
  quietTo: json['quiet_to'] as String?,
  digestEnabled: json['digest_enabled'] as bool,
  digestTime: json['digest_time'] as String?,
  lang: $enumDecodeNullable(
    _$StudioLangEnumMap,
    json['lang'],
    unknownValue: StudioLang.unknown,
  ),
  events: (json['events'] as List<dynamic>)
      .map((e) => EventInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$NotificationPrefsImplToJson(
  _$NotificationPrefsImpl instance,
) => <String, dynamic>{
  'quiet_from': instance.quietFrom,
  'quiet_to': instance.quietTo,
  'digest_enabled': instance.digestEnabled,
  'digest_time': instance.digestTime,
  'lang': _$StudioLangEnumMap[instance.lang],
  'events': instance.events.map((e) => e.toJson()).toList(),
};

_$TodayLineImpl _$$TodayLineImplFromJson(Map<String, dynamic> json) =>
    _$TodayLineImpl(
      id: json['id'] as String,
      kind: $enumDecode(
        _$LineKindEnumMap,
        json['kind'],
        unknownValue: LineKind.unknown,
      ),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      level: $enumDecode(
        _$NoteLevelEnumMap,
        json['level'],
        unknownValue: NoteLevel.unknown,
      ),
      due: json['due'] as String?,
      route: json['route'] as String,
      thumb: json['thumb'] == null
          ? null
          : StudioMedia.fromJson(json['thumb'] as Map<String, dynamic>),
      ref: json['ref'] == null
          ? null
          : DocRef.fromJson(json['ref'] as Map<String, dynamic>),
      badge: json['badge'] as String?,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$TodayLineImplToJson(_$TodayLineImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$LineKindEnumMap[instance.kind]!,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'level': _$NoteLevelEnumMap[instance.level]!,
      'due': instance.due,
      'route': instance.route,
      'thumb': instance.thumb?.toJson(),
      'ref': instance.ref?.toJson(),
      'badge': instance.badge,
      'actions': instance.actions,
    };

const _$LineKindEnumMap = {
  LineKind.piece: 'piece',
  LineKind.version: 'version',
  LineKind.post: 'post',
  LineKind.task: 'task',
  LineKind.shoot: 'shoot',
  LineKind.decision: 'decision',
  LineKind.idea: 'idea',
  LineKind.read: 'read',
  LineKind.ad: 'ad',
  LineKind.signal: 'signal',
  LineKind.actual: 'actual',
  LineKind.summary: 'summary',
  LineKind.unknown: '__unknown__',
};

_$TodayBlockImpl _$$TodayBlockImplFromJson(Map<String, dynamic> json) =>
    _$TodayBlockImpl(
      key: $enumDecode(
        _$BlockKeyEnumMap,
        json['key'],
        unknownValue: BlockKey.unknown,
      ),
      title: json['title'] as String,
      count: (json['count'] as num).toInt(),
      level: $enumDecode(
        _$NoteLevelEnumMap,
        json['level'],
        unknownValue: NoteLevel.unknown,
      ),
      moreRoute: json['more_route'] as String?,
      lines: (json['lines'] as List<dynamic>)
          .map((e) => TodayLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$TodayBlockImplToJson(_$TodayBlockImpl instance) =>
    <String, dynamic>{
      'key': _$BlockKeyEnumMap[instance.key]!,
      'title': instance.title,
      'count': instance.count,
      'level': _$NoteLevelEnumMap[instance.level]!,
      'more_route': instance.moreRoute,
      'lines': instance.lines.map((e) => e.toJson()).toList(),
    };

const _$BlockKeyEnumMap = {
  BlockKey.sentBack: 'sent_back',
  BlockKey.toApprove: 'to_approve',
  BlockKey.decisions: 'decisions',
  BlockKey.ideas: 'ideas',
  BlockKey.dueToday: 'due_today',
  BlockKey.readyToPost: 'ready_to_post',
  BlockKey.stories: 'stories',
  BlockKey.readsMissing: 'reads_missing',
  BlockKey.adsDue: 'ads_due',
  BlockKey.didntGoOut: 'didnt_go_out',
  BlockKey.unplanned: 'unplanned',
  BlockKey.unconfirmed: 'unconfirmed',
  BlockKey.blocked: 'blocked',
  BlockKey.shootTomorrow: 'shoot_tomorrow',
  BlockKey.advice: 'advice',
  BlockKey.warnings: 'warnings',
  BlockKey.unknown: '__unknown__',
};

_$TodayViewImpl _$$TodayViewImplFromJson(Map<String, dynamic> json) =>
    _$TodayViewImpl(
      date: json['date'] as String,
      role: $enumDecode(
        _$PersonRoleEnumMap,
        json['role'],
        unknownValue: PersonRole.unknown,
      ),
      generatedAt: json['generated_at'] as String,
      counts: InboxCounts.fromJson(json['counts'] as Map<String, dynamic>),
      blocks: (json['blocks'] as List<dynamic>)
          .map((e) => TodayBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$TodayViewImplToJson(_$TodayViewImpl instance) =>
    <String, dynamic>{
      'date': instance.date,
      'role': _$PersonRoleEnumMap[instance.role]!,
      'generated_at': instance.generatedAt,
      'counts': instance.counts.toJson(),
      'blocks': instance.blocks.map((e) => e.toJson()).toList(),
    };

_$RuleValueImpl _$$RuleValueImplFromJson(Map<String, dynamic> json) =>
    _$RuleValueImpl(
      validFrom: json['valid_from'] as String,
      value: (json['value'] as num).toDouble(),
      note: json['note'] as String?,
      archived: json['archived'] as bool,
    );

Map<String, dynamic> _$$RuleValueImplToJson(_$RuleValueImpl instance) =>
    <String, dynamic>{
      'valid_from': instance.validFrom,
      'value': instance.value,
      'note': instance.note,
      'archived': instance.archived,
    };

_$StudioRuleImpl _$$StudioRuleImplFromJson(Map<String, dynamic> json) =>
    _$StudioRuleImpl(
      key: json['key'] as String,
      unit: json['unit'] as String?,
      meaning: json['meaning'] as String,
      defaultValue: (json['default_value'] as num).toDouble(),
      value: (json['value'] as num).toDouble(),
      valueSince: json['value_since'] as String?,
      source: json['source'] as String?,
      values: (json['values'] as List<dynamic>)
          .map((e) => RuleValue.fromJson(e as Map<String, dynamic>))
          .toList(),
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$StudioRuleImplToJson(_$StudioRuleImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'unit': instance.unit,
      'meaning': instance.meaning,
      'default_value': instance.defaultValue,
      'value': instance.value,
      'value_since': instance.valueSince,
      'source': instance.source,
      'values': instance.values.map((e) => e.toJson()).toList(),
      'actions': instance.actions,
    };

_$PricesImpl _$$PricesImplFromJson(Map<String, dynamic> json) => _$PricesImpl(
  medium: (json['medium'] as num?)?.toInt(),
  large: (json['large'] as num?)?.toInt(),
);

Map<String, dynamic> _$$PricesImplToJson(_$PricesImpl instance) =>
    <String, dynamic>{'medium': instance.medium, 'large': instance.large};

_$StudioFlavourImpl _$$StudioFlavourImplFromJson(Map<String, dynamic> json) =>
    _$StudioFlavourImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      status: $enumDecode(
        _$FlavourStatusEnumMap,
        json['status'],
        unknownValue: FlavourStatus.unknown,
      ),
      availableFrom: json['available_from'] as String?,
      availableTo: json['available_to'] as String?,
      itemCode: json['item_code'] as String?,
      note: json['note'] as String?,
      keywords: (json['keywords'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      prices: json['prices'] == null
          ? null
          : Prices.fromJson(json['prices'] as Map<String, dynamic>),
      sortOrder: (json['sort_order'] as num).toInt(),
      modified: json['modified'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$StudioFlavourImplToJson(_$StudioFlavourImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': _$FlavourStatusEnumMap[instance.status]!,
      'available_from': instance.availableFrom,
      'available_to': instance.availableTo,
      'item_code': instance.itemCode,
      'note': instance.note,
      'keywords': instance.keywords,
      'prices': instance.prices?.toJson(),
      'sort_order': instance.sortOrder,
      'modified': instance.modified,
      'actions': instance.actions,
    };

const _$FlavourStatusEnumMap = {
  FlavourStatus.live: 'live',
  FlavourStatus.paused: 'paused',
  FlavourStatus.seasonal: 'seasonal',
  FlavourStatus.coming: 'coming',
  FlavourStatus.unknown: '__unknown__',
};

_$FlavourSetResultImpl _$$FlavourSetResultImplFromJson(
  Map<String, dynamic> json,
) => _$FlavourSetResultImpl(
  flavour: StudioFlavour.fromJson(json['flavour'] as Map<String, dynamic>),
  warnings: (json['warnings'] as List<dynamic>)
      .map((e) => CheckRow.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$FlavourSetResultImplToJson(
  _$FlavourSetResultImpl instance,
) => <String, dynamic>{
  'flavour': instance.flavour.toJson(),
  'warnings': instance.warnings.map((e) => e.toJson()).toList(),
};

_$StudioClaimImpl _$$StudioClaimImplFromJson(Map<String, dynamic> json) =>
    _$StudioClaimImpl(
      id: json['id'] as String,
      textEn: json['text_en'] as String,
      textAr: json['text_ar'] as String?,
      status: $enumDecode(
        _$ClaimStatusEnumMap,
        json['status'],
        unknownValue: ClaimStatus.unknown,
      ),
      registryRef: json['registry_ref'] as String?,
      syncedAt: json['synced_at'] as String?,
    );

Map<String, dynamic> _$$StudioClaimImplToJson(_$StudioClaimImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text_en': instance.textEn,
      'text_ar': instance.textAr,
      'status': _$ClaimStatusEnumMap[instance.status]!,
      'registry_ref': instance.registryRef,
      'synced_at': instance.syncedAt,
    };

const _$ClaimStatusEnumMap = {
  ClaimStatus.aPPROVED: 'APPROVED',
  ClaimStatus.hOLD: 'HOLD',
  ClaimStatus.rETIRED: 'RETIRED',
  ClaimStatus.unknown: '__unknown__',
};

_$StudioMomentImpl _$$StudioMomentImplFromJson(Map<String, dynamic> json) =>
    _$StudioMomentImpl(
      id: json['id'] as String,
      kind: $enumDecode(
        _$MomentKindEnumMap,
        json['kind'],
        unknownValue: MomentKind.unknown,
      ),
      title: json['title'] as String,
      date: json['date'] as String?,
      endDate: json['end_date'] as String?,
      effectiveDate: json['effective_date'] as String?,
      parent: json['parent'] == null
          ? null
          : MomentRef.fromJson(json['parent'] as Map<String, dynamic>),
      offsetDays: (json['offset_days'] as num?)?.toInt(),
      flavour: json['flavour'] == null
          ? null
          : FlavourRef.fromJson(json['flavour'] as Map<String, dynamic>),
      assignee: json['assignee'] == null
          ? null
          : PersonRef.fromJson(json['assignee'] as Map<String, dynamic>),
      note: json['note'] as String?,
      revealTime: json['reveal_time'] as String?,
      launchStage: $enumDecodeNullable(
        _$LaunchStageEnumMap,
        json['launch_stage'],
        unknownValue: LaunchStage.unknown,
      ),
      label: $enumDecodeNullable(
        _$JarLabelEnumMap,
        json['label'],
        unknownValue: JarLabel.unknown,
      ),
      nameRule: json['name_rule'] as bool?,
      approvedLines: (json['approved_lines'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      modified: json['modified'] as String,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$StudioMomentImplToJson(_$StudioMomentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$MomentKindEnumMap[instance.kind]!,
      'title': instance.title,
      'date': instance.date,
      'end_date': instance.endDate,
      'effective_date': instance.effectiveDate,
      'parent': instance.parent?.toJson(),
      'offset_days': instance.offsetDays,
      'flavour': instance.flavour?.toJson(),
      'assignee': instance.assignee?.toJson(),
      'note': instance.note,
      'reveal_time': instance.revealTime,
      'launch_stage': _$LaunchStageEnumMap[instance.launchStage],
      'label': _$JarLabelEnumMap[instance.label],
      'name_rule': instance.nameRule,
      'approved_lines': instance.approvedLines,
      'modified': instance.modified,
      'actions': instance.actions,
    };

const _$LaunchStageEnumMap = {
  LaunchStage.teasing: 'teasing',
  LaunchStage.live: 'live',
  LaunchStage.paused: 'paused',
  LaunchStage.done: 'done',
  LaunchStage.unknown: '__unknown__',
};

const _$JarLabelEnumMap = {
  JarLabel.old: 'old',
  JarLabel.newValue: 'new',
  JarLabel.unknown: '__unknown__',
};

_$MomentSetResultImpl _$$MomentSetResultImplFromJson(
  Map<String, dynamic> json,
) => _$MomentSetResultImpl(
  moment: StudioMoment.fromJson(json['moment'] as Map<String, dynamic>),
  warnings: (json['warnings'] as List<dynamic>)
      .map((e) => CheckRow.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$MomentSetResultImplToJson(
  _$MomentSetResultImpl instance,
) => <String, dynamic>{
  'moment': instance.moment.toJson(),
  'warnings': instance.warnings.map((e) => e.toJson()).toList(),
};

_$StudioPersonImpl _$$StudioPersonImplFromJson(Map<String, dynamic> json) =>
    _$StudioPersonImpl(
      key: json['key'] as String,
      fullName: json['full_name'] as String,
      studioRole: $enumDecode(
        _$PersonRoleEnumMap,
        json['studio_role'],
        unknownValue: PersonRole.unknown,
      ),
      user: json['user'] as String?,
      hasLogin: json['has_login'] as bool,
      mustRate: json['must_rate'] as bool,
      enabled: json['enabled'] as bool,
      sortOrder: (json['sort_order'] as num).toInt(),
      quietFrom: json['quiet_from'] as String?,
      quietTo: json['quiet_to'] as String?,
      digestEnabled: json['digest_enabled'] as bool,
      digestTime: json['digest_time'] as String?,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$StudioPersonImplToJson(_$StudioPersonImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'full_name': instance.fullName,
      'studio_role': _$PersonRoleEnumMap[instance.studioRole]!,
      'user': instance.user,
      'has_login': instance.hasLogin,
      'must_rate': instance.mustRate,
      'enabled': instance.enabled,
      'sort_order': instance.sortOrder,
      'quiet_from': instance.quietFrom,
      'quiet_to': instance.quietTo,
      'digest_enabled': instance.digestEnabled,
      'digest_time': instance.digestTime,
      'actions': instance.actions,
    };

_$StudioOptionsImpl _$$StudioOptionsImplFromJson(Map<String, dynamic> json) =>
    _$StudioOptionsImpl(
      lists: (json['lists'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    );

Map<String, dynamic> _$$StudioOptionsImplToJson(_$StudioOptionsImpl instance) =>
    <String, dynamic>{'lists': instance.lists};

_$IdeasBulkImpl _$$IdeasBulkImplFromJson(Map<String, dynamic> json) =>
    _$IdeasBulkImpl(
      created: (json['created'] as List<dynamic>)
          .map((e) => StudioIdea.fromJson(e as Map<String, dynamic>))
          .toList(),
      skipped: (json['skipped'] as List<dynamic>)
          .map((e) => SkipItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$IdeasBulkImplToJson(_$IdeasBulkImpl instance) =>
    <String, dynamic>{
      'created': instance.created.map((e) => e.toJson()).toList(),
      'skipped': instance.skipped.map((e) => e.toJson()).toList(),
    };

_$UpsertSummaryImpl _$$UpsertSummaryImplFromJson(Map<String, dynamic> json) =>
    _$UpsertSummaryImpl(
      created: (json['created'] as num).toInt(),
      updated: (json['updated'] as num).toInt(),
      skipped: (json['skipped'] as List<dynamic>)
          .map((e) => SkipItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      ids: (json['ids'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$UpsertSummaryImplToJson(_$UpsertSummaryImpl instance) =>
    <String, dynamic>{
      'created': instance.created,
      'updated': instance.updated,
      'skipped': instance.skipped.map((e) => e.toJson()).toList(),
      'ids': instance.ids,
    };

_$SignalsWrittenImpl _$$SignalsWrittenImplFromJson(Map<String, dynamic> json) =>
    _$SignalsWrittenImpl(
      written: (json['written'] as num).toInt(),
      replaced: (json['replaced'] as num).toInt(),
      resolved: (json['resolved'] as num).toInt(),
    );

Map<String, dynamic> _$$SignalsWrittenImplToJson(
  _$SignalsWrittenImpl instance,
) => <String, dynamic>{
  'written': instance.written,
  'replaced': instance.replaced,
  'resolved': instance.resolved,
};

_$DecisionAskImpl _$$DecisionAskImplFromJson(Map<String, dynamic> json) =>
    _$DecisionAskImpl(
      decision: StudioDecision.fromJson(
        json['decision'] as Map<String, dynamic>,
      ),
      created: json['created'] as bool,
    );

Map<String, dynamic> _$$DecisionAskImplToJson(_$DecisionAskImpl instance) =>
    <String, dynamic>{
      'decision': instance.decision.toJson(),
      'created': instance.created,
    };

_$ClaimsSyncedImpl _$$ClaimsSyncedImplFromJson(Map<String, dynamic> json) =>
    _$ClaimsSyncedImpl(
      created: (json['created'] as num).toInt(),
      updated: (json['updated'] as num).toInt(),
      deleted: (json['deleted'] as num).toInt(),
    );

Map<String, dynamic> _$$ClaimsSyncedImplToJson(_$ClaimsSyncedImpl instance) =>
    <String, dynamic>{
      'created': instance.created,
      'updated': instance.updated,
      'deleted': instance.deleted,
    };

_$ErrorBodyImpl _$$ErrorBodyImplFromJson(Map<String, dynamic> json) =>
    _$ErrorBodyImpl(
      code: $enumDecode(
        _$ErrorCodeEnumMap,
        json['code'],
        unknownValue: ErrorCode.unknown,
      ),
      message: json['message'] as String,
      field: json['field'] as String?,
      problems: (json['problems'] as List<dynamic>?)
          ?.map((e) => StudioProblem.fromJson(e as Map<String, dynamic>))
          .toList(),
      current: json['current'],
    );

Map<String, dynamic> _$$ErrorBodyImplToJson(_$ErrorBodyImpl instance) =>
    <String, dynamic>{
      'code': _$ErrorCodeEnumMap[instance.code]!,
      'message': instance.message,
      'field': instance.field,
      'problems': instance.problems?.map((e) => e.toJson()).toList(),
      'current': instance.current,
    };

const _$ErrorCodeEnumMap = {
  ErrorCode.uNAUTHENTICATED: 'UNAUTHENTICATED',
  ErrorCode.nOTPERMITTED: 'NOT_PERMITTED',
  ErrorCode.nOTFOUND: 'NOT_FOUND',
  ErrorCode.vALIDATION: 'VALIDATION',
  ErrorCode.gATEFAILED: 'GATE_FAILED',
  ErrorCode.sTALE: 'STALE',
  ErrorCode.aLREADYDONE: 'ALREADY_DONE',
  ErrorCode.sHADOWMODE: 'SHADOW_MODE',
  ErrorCode.rATELIMITED: 'RATE_LIMITED',
  ErrorCode.sERVERERROR: 'SERVER_ERROR',
  ErrorCode.unknown: '__unknown__',
};

_$ErrorEnvelopeImpl _$$ErrorEnvelopeImplFromJson(Map<String, dynamic> json) =>
    _$ErrorEnvelopeImpl(
      error: ErrorBody.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ErrorEnvelopeImplToJson(_$ErrorEnvelopeImpl instance) =>
    <String, dynamic>{'error': instance.error.toJson()};

_$ErrorExampleImpl _$$ErrorExampleImplFromJson(Map<String, dynamic> json) =>
    _$ErrorExampleImpl(
      httpStatus: (json['http_status'] as num).toInt(),
      frappeException: json['frappe_exception'] as String,
      body: ErrorEnvelope.fromJson(json['body'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ErrorExampleImplToJson(_$ErrorExampleImpl instance) =>
    <String, dynamic>{
      'http_status': instance.httpStatus,
      'frappe_exception': instance.frappeException,
      'body': instance.body.toJson(),
    };

_$PushPayloadImpl _$$PushPayloadImplFromJson(Map<String, dynamic> json) =>
    _$PushPayloadImpl(
      type: json['type'] as String,
      route: json['route'] as String,
      notificationId: json['notification_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      doctype: json['doctype'] as String,
      docname: json['docname'] as String,
    );

Map<String, dynamic> _$$PushPayloadImplToJson(_$PushPayloadImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'route': instance.route,
      'notification_id': instance.notificationId,
      'title': instance.title,
      'body': instance.body,
      'doctype': instance.doctype,
      'docname': instance.docname,
    };

_$PushExampleImpl _$$PushExampleImplFromJson(Map<String, dynamic> json) =>
    _$PushExampleImpl(
      event: json['event'] as String,
      audience: json['audience'] as String,
      payload: PushPayload.fromJson(json['payload'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PushExampleImplToJson(_$PushExampleImpl instance) =>
    <String, dynamic>{
      'event': instance.event,
      'audience': instance.audience,
      'payload': instance.payload.toJson(),
    };

_$ApproveCardPageImpl _$$ApproveCardPageImplFromJson(
  Map<String, dynamic> json,
) => _$ApproveCardPageImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => ApproveCard.fromJson(e as Map<String, dynamic>))
      .toList(),
  next: json['next'] as String?,
);

Map<String, dynamic> _$$ApproveCardPageImplToJson(
  _$ApproveCardPageImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
};

_$HistoryItemPageImpl _$$HistoryItemPageImplFromJson(
  Map<String, dynamic> json,
) => _$HistoryItemPageImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  next: json['next'] as String?,
);

Map<String, dynamic> _$$HistoryItemPageImplToJson(
  _$HistoryItemPageImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
};

_$NotificationItemPageImpl _$$NotificationItemPageImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationItemPageImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  next: json['next'] as String?,
);

Map<String, dynamic> _$$NotificationItemPageImplToJson(
  _$NotificationItemPageImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
};

_$PieceResultPageImpl _$$PieceResultPageImplFromJson(
  Map<String, dynamic> json,
) => _$PieceResultPageImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => PieceResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  next: json['next'] as String?,
);

Map<String, dynamic> _$$PieceResultPageImplToJson(
  _$PieceResultPageImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
};

_$PieceSummaryPageImpl _$$PieceSummaryPageImplFromJson(
  Map<String, dynamic> json,
) => _$PieceSummaryPageImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => PieceSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  next: json['next'] as String?,
);

Map<String, dynamic> _$$PieceSummaryPageImplToJson(
  _$PieceSummaryPageImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
};

_$RateCardPageImpl _$$RateCardPageImplFromJson(Map<String, dynamic> json) =>
    _$RateCardPageImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => RateCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      next: json['next'] as String?,
    );

Map<String, dynamic> _$$RateCardPageImplToJson(_$RateCardPageImpl instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'next': instance.next,
    };

_$ReadyPostPageImpl _$$ReadyPostPageImplFromJson(Map<String, dynamic> json) =>
    _$ReadyPostPageImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => ReadyPost.fromJson(e as Map<String, dynamic>))
          .toList(),
      next: json['next'] as String?,
    );

Map<String, dynamic> _$$ReadyPostPageImplToJson(_$ReadyPostPageImpl instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'next': instance.next,
    };

_$ShootSummarySyncImpl _$$ShootSummarySyncImplFromJson(
  Map<String, dynamic> json,
) => _$ShootSummarySyncImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => ShootSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  next: json['next'] as String?,
  deleted: (json['deleted'] as List<dynamic>).map((e) => e as String).toList(),
  serverTime: json['server_time'] as String,
);

Map<String, dynamic> _$$ShootSummarySyncImplToJson(
  _$ShootSummarySyncImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
  'deleted': instance.deleted,
  'server_time': instance.serverTime,
};

_$StudioAssetPageImpl _$$StudioAssetPageImplFromJson(
  Map<String, dynamic> json,
) => _$StudioAssetPageImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => StudioAsset.fromJson(e as Map<String, dynamic>))
      .toList(),
  next: json['next'] as String?,
);

Map<String, dynamic> _$$StudioAssetPageImplToJson(
  _$StudioAssetPageImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
};

_$StudioClaimPageImpl _$$StudioClaimPageImplFromJson(
  Map<String, dynamic> json,
) => _$StudioClaimPageImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => StudioClaim.fromJson(e as Map<String, dynamic>))
      .toList(),
  next: json['next'] as String?,
);

Map<String, dynamic> _$$StudioClaimPageImplToJson(
  _$StudioClaimPageImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
};

_$StudioCommentPageImpl _$$StudioCommentPageImplFromJson(
  Map<String, dynamic> json,
) => _$StudioCommentPageImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => StudioComment.fromJson(e as Map<String, dynamic>))
      .toList(),
  next: json['next'] as String?,
);

Map<String, dynamic> _$$StudioCommentPageImplToJson(
  _$StudioCommentPageImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
};

_$StudioCompetitorPageImpl _$$StudioCompetitorPageImplFromJson(
  Map<String, dynamic> json,
) => _$StudioCompetitorPageImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => StudioCompetitor.fromJson(e as Map<String, dynamic>))
      .toList(),
  next: json['next'] as String?,
);

Map<String, dynamic> _$$StudioCompetitorPageImplToJson(
  _$StudioCompetitorPageImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
};

_$StudioDecisionPageImpl _$$StudioDecisionPageImplFromJson(
  Map<String, dynamic> json,
) => _$StudioDecisionPageImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => StudioDecision.fromJson(e as Map<String, dynamic>))
      .toList(),
  next: json['next'] as String?,
);

Map<String, dynamic> _$$StudioDecisionPageImplToJson(
  _$StudioDecisionPageImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
};

_$StudioIdeaPageImpl _$$StudioIdeaPageImplFromJson(Map<String, dynamic> json) =>
    _$StudioIdeaPageImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => StudioIdea.fromJson(e as Map<String, dynamic>))
          .toList(),
      next: json['next'] as String?,
    );

Map<String, dynamic> _$$StudioIdeaPageImplToJson(
  _$StudioIdeaPageImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
};

_$StudioReferencePageImpl _$$StudioReferencePageImplFromJson(
  Map<String, dynamic> json,
) => _$StudioReferencePageImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => StudioReference.fromJson(e as Map<String, dynamic>))
      .toList(),
  next: json['next'] as String?,
);

Map<String, dynamic> _$$StudioReferencePageImplToJson(
  _$StudioReferencePageImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
};

_$StudioReportPageImpl _$$StudioReportPageImplFromJson(
  Map<String, dynamic> json,
) => _$StudioReportPageImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => StudioReport.fromJson(e as Map<String, dynamic>))
      .toList(),
  next: json['next'] as String?,
);

Map<String, dynamic> _$$StudioReportPageImplToJson(
  _$StudioReportPageImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
};

_$StudioShootSyncImpl _$$StudioShootSyncImplFromJson(
  Map<String, dynamic> json,
) => _$StudioShootSyncImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => StudioShoot.fromJson(e as Map<String, dynamic>))
      .toList(),
  next: json['next'] as String?,
  deleted: (json['deleted'] as List<dynamic>).map((e) => e as String).toList(),
  serverTime: json['server_time'] as String,
);

Map<String, dynamic> _$$StudioShootSyncImplToJson(
  _$StudioShootSyncImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
  'deleted': instance.deleted,
  'server_time': instance.serverTime,
};

_$StudioTaskPageImpl _$$StudioTaskPageImplFromJson(Map<String, dynamic> json) =>
    _$StudioTaskPageImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => StudioTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      next: json['next'] as String?,
    );

Map<String, dynamic> _$$StudioTaskPageImplToJson(
  _$StudioTaskPageImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next': instance.next,
};
