# Jarz Studio (Flutter app inside the POS repo)

A second app entrypoint, `lib/main_studio.dart`, for the marketing team. All Studio code lives in `lib/src/studio/`.
The POS app (`lib/main.dart`) does not know it exists.

## Run

```
flutter run -d chrome -t lib/main_studio.dart --dart-define=STUDIO_FAKE=1
flutter run -d chrome -t lib/main_studio.dart --dart-define=STUDIO_FAKE=1 --dart-define=STUDIO_FAKE_ROLE=creator
```

`STUDIO_FAKE` accepts `1` or `true`. `STUDIO_FAKE_ROLE` is `founder` (default), `lead`, `creator`, `story` or `none` (signed in, no Studio role).
Without `STUDIO_FAKE` the app loads the POS env file, starts Sentry the POS way, and logs in against the Frappe site.

## Layout

```
core/    config, l10n, network, roles, router, theme
shared/  ViewEditScaffold, StudioAsyncView, optimistic(), StageChip, VerdictBadge, HowThisWorksSheet
features/<feature>/{data,presentation,state}
```

## Import rule

Studio code may import only the Studio, packages, and these POS paths:
`lib/src/core/{network,session,env,constants,localization,monitoring,offline}/` and
`lib/src/features/auth/data/auth_repository.dart`. POS code never imports `lib/src/studio/` or `main_studio.dart`.
Check it: `dart run tool/check_studio_imports.dart` (exit 1 on a violation).

## Offline replay opt-out

The POS Dio (`dioProvider`) parks a failed POST in the offline queue when its path contains `create`, and replays it
later. A replayed Studio write would double-create. `dio_provider.dart` has no per-request flag to opt out and must not
be edited, so the Studio builds its own Dio (`studioDioProvider`): the same base options as the POS Dio, the same
`SessionInterceptor` (cookies, site header, build headers, 401 and dead-session signals), but handed a
`NoReplayOfflineQueue` whose `addTransaction` does nothing. Nothing from a Studio call ever reaches the POS queue.
Studio calls fail visibly; the UI offers retry. Web needs no extra handling: browsers own the cookie.

## Data layer

```
data/models/    studio_enums.dart, studio_models.dart (+ .freezed/.g): GENERATED, one class per contract shape
data/api/       studio_api_<group>.dart: GENERATED, one typed method per endpoint (mixins), studio_api_base.dart
data/fake/      fake_studio_api.dart (hand written), studio_fixtures.g.dart (GENERATED fixtures as one const map)
data/           studio_error.dart (sealed StudioError), paging.dart (PagedNotifier, EntityNotifier), optimistic_write.dart
features/<f>/data/<f>_repository.dart   thin repository + Riverpod providers per feature
core/push/studio_push_router.dart       push payload -> router location (pure)
```

Contract: `systems/studio-rebuild/API_CONTRACT.md` (v1.2) and its `contract/` folder.
Naming: shapes that clash with Flutter/Dio/Dart get a prefix or suffix (`Round` is `PaidRound`, `Media` is `StudioMedia`,
`Options` is `StudioOptions`, `Route` is `ProdRoute`...; the map is `SHAPE_RENAME` / `ENUM_RENAME` in the generator).
Dates and times stay `String` (ISO, offset kept) so a model round-trips to the same JSON. Every enum has `unknown`;
`.wire` gives the exact string, `Enum.parse(s)` the reverse. `Page<T>` / `Sync<T>` become `<Item>Page` / `<Item>Sync`
(all `implements PageLike<Item>`).

### Re-generate (contract version bump)

```
tool/studio_gen.sh "<path to systems/studio-rebuild/contract>"
```

It runs `python tool/studio_gen_contract.py <contract_dir>` (models, enums, API mixins, `studio_fixtures.g.dart`, and the
test tables under `test/studio/data/generated/`), formats, runs `build_runner` for `lib/src/studio/**` only, and restores
any POS generated file build_runner deleted. Then run `flutter test test/studio`. Endpoint parameters are read from the
markdown tables of `API_CONTRACT.md` (one level above the contract folder), result shapes from `check_fixtures.py`. The
"Who may call" letters of the same file become `data/fake/studio_endpoint_roles.g.dart`, which the fake reads to filter
`actions` by role. A field the contract says defaults when absent (`Decision.answer_kind` reads as `option`) is set in the
generator, never in the generated file.

### Real or fake (compile time)

`studioApiProvider` picks `DioStudioApi` or `FakeStudioApi` with the const `StudioConfig.fake`
(`--dart-define=STUDIO_FAKE=1`). In a normal build the fake and its fixtures are tree-shaken out (checked on the web
build). Tests override `studioApiProvider` with `FakeStudioApi(role: ..., delay: Duration.zero)`.

### Using the API

`ref.read(studioApiProvider).versionsApprove(versionId: id)` and so on: one typed method per endpoint, named
`<group><Fn>`. Writes the contract marks idempotent take an optional `requestId`; leave it out and a UUID is made, pass the
same one on a retry. Lists and maps go out as JSON strings (like the POS materials repository). Failures throw a sealed
`StudioError` (`StudioShadowMode`, `StudioValidation(field)`, `StudioGateFailed(problems)`, `StudioStale(current)`,
`StudioAlreadyDone(current)`, `StudioNetworkError`...). `StudioUnauthenticated.deadSession` is true.

### Fake API

`FakeStudioApi({role, delay})` serves `studio_fixtures.g.dart`. `session.me` reads `me.<role>`; any other call reads
`<group>.<fn>.<role>` first (`today.get.creator`), then `<group>.<fn>`. Role `none` is a signed-in user without a Studio
role. Writes (approve, fix, clear review, rate, comment, tick, answer a decision, keep, drop, mark read) return the updated
object and change later reads, the to-approve feed and the inbox counts, in memory.

The fake answers as the server would for the signed-in role: every `actions` list is cut down to the endpoints that role
may call (`fakeObjectKind` tells which kind of object a map is), so a screen that shows a button the role cannot use shows
up in the role tests. `decisions.answer` takes the same arguments as the server (an option decision takes `option_index`
and an optional `note`, a decision answered in words takes `text` only, 1 to 2000 characters) and refuses a wrong
combination with `VALIDATION` and the `field`. `FakeStudioApi(textDecisions: true)` adds the two decisions answered in
words (`DEC-00012` open, `DEC-00011` answered) to the decisions list and the Inbox count; they are served by id either way.
The running fake app turns it on.

Force a failure in a test or while building a screen:

```dart
final api = FakeStudioApi(delay: Duration.zero)
  ..failNext('versions.approve', 'SHADOW_MODE')             // one call
  ..failNext('pieces', 'VALIDATION', message: 'x', field: 'to') // a whole group
  ..failAlways('inbox.counts', 'SERVER_ERROR');             // until api.clearFailures()
```

Codes: UNAUTHENTICATED NOT_PERMITTED NOT_FOUND VALIDATION GATE_FAILED STALE ALREADY_DONE SHADOW_MODE RATE_LIMITED
SERVER_ERROR. `api.calls` lists what was called. In a running fake app, override the provider in `main_studio` if you
need a failing API.

### Providers and notifiers

One `<feature>_repository.dart` per feature with `xRepositoryProvider` and the screen providers: `inboxCountsProvider`,
`toApproveProvider` (approve, fix), `toRateProvider`, `versionProvider(id)`; `decisionsProvider`, `ideasProvider`,
`todayProvider`, `tasksProvider`, `calendarRangeProvider((from, to))`, `readyToPostProvider`, `postProvider(id)`,
`pieceBoardProvider`, `piecesProvider`, `pieceProvider(id)`, `shootsProvider`, `shootProvider(id)`, `assetsProvider`,
`assetProvider(id)`, `referencesProvider`, `referenceProvider(id)`, `paidOverviewProvider`, `scorecardProvider(week)`,
`resultsByPieceProvider`, `reportsProvider`, `studioOptionsProvider`, `rulesProvider`, `flavoursProvider`,
`myNotificationPrefsProvider`, `notificationsProvider`, `unreadCountProvider`.
`PagedNotifier<T>` gives `loadMore()`, `refresh()`, `swap()` and `mutate()` (optimistic write with rollback; `STALE` swaps in
the fresh object and rethrows, `ALREADY_DONE` counts as success). `EntityNotifier<T>` is the same for one object by id.
Both use the context-free `runOptimistic()`; the widget helper `optimistic()` wraps it.

## Routes

Contract paths (section 1.9) are the app's paths. Above the shell: `/versions/:id`, `/inbox/approve/:id`, `/inbox/rate`
(review), `/shoots`, `/shoots/new`, `/shoots/:id`, `/shoots/:id/edit`, `/shoots/:id/on-set`, `/assets`, `/assets/new`,
`/assets/:id`, `/assets/:id/edit`, and the public `/prep/:token` (no login). In the shell: `/today`; `/inbox/{approve,
decisions,ideas}`, `/inbox/decisions/:id`, `/inbox/notifications[/settings]`; `/calendar`, `/calendar/post/:id`; `/pieces`,
`/pieces/:id`, `/pieces/:id/add-version`; `/more` with `/more/{references,paid,results,reports,settings}` and their
children. The contract's `/references`, `/paid`, `/results`, `/reports`, `/settings` redirect to `/more/...`
(`studioAppRoute`, also applied to every push payload). A signed-out deep link goes to `/login?from=...` and comes back.

## One place for each shared thing

- What a write makes stale: `data/write_refresh.dart` (`studioWriteRefreshes`, one map from `group.fn` to the providers to
  refresh). The API announces every successful call (`StudioApi.writes`); `StudioApp` watches
  `studioWriteRefreshProvider`. No screen invalidates another feature's provider after a write.
- The language and the lines the server words (contract v1.3): `core/l10n/studio_language_sync.dart` (device choice, send
  to `settings.set_my_notifications(lang)`, adopt on first sign-in). Text that goes to the clipboard passes
  `shared/bidi_text.dart` (`withoutBidiIsolates`).
- A raw person id from the server (`posted_by`, `waits_on`, `raised_by`): `shared/person_name.dart`.
- A problem or calendar check by `code`: `StudioLabels.problem` (the server message is the fallback).
- The first-login walkthrough per role: `features/walkthrough/` (key `walkthrough_<role>` in `session.help_seen`).

- Error text: `shared/studio_error_text.dart` (`studioErrorText`, `showStudioError`, `studioErrorMessage`). No screen words
  SHADOW_MODE, GATE_FAILED, STALE, NOT_PERMITTED or ALREADY_DONE its own way.
- `base_modified`: `EntityNotifier.baseModified` (from `modifiedOf`, which every notifier must implement). Pass it to every
  write the contract lets answer STALE. STALE and ALREADY_DONE take the server's copy and rethrow.
- Clearing a nullable parameter (`null clears` in the contract): pass `studioClear`; the generated method sends an explicit
  null. Leaving the parameter out sends nothing.
- Client-side role checks: `features/session/data/me_profile_x.dart`, and nowhere else.
- A picture and two lines: `shared/media_row.dart`. Uploads: `core/upload` (the tray sits under every screen in
  `StudioApp`, the queue resumes at app start).

## Words for what the server sends

`core/l10n/studio_labels.dart` (`StudioLabels`) is the one place that turns a server value into words in both languages: an
action name on a button, a Today block title and its empty line, a metric and its unit, and every enum that is shown to a
person (stage, post status, decision status, idea status, task kind, media kind, signal level, read window...). A screen
never prints a raw key or a wire value. `test/studio/labels_test.dart` walks every generated enum and fails for one that is
neither worded nor listed as not shown. New terms are added to `core/l10n/GLOSSARY.md` first.

## Localisation

Studio strings are separate from the POS ARB files and need no change to `l10n.yaml`. `core/l10n/studio_strings.dart`
holds an abstract `StudioStrings` with one class per language (`StudioStringsEn`, `StudioStringsAr`) and a small
`LocalizationsDelegate`. A key added to the abstract class that is missing in either language fails the build. Per-screen
copy (title, what it is for, first step, 3 to 5 help lines) is a `ScreenCopy` looked up by the `StudioScreen` enum.
Brand words (Jarz, Studio) and product words people say in English (flavor, size, dessert, order) stay in English inside Arabic.
The language switch is in the app bar (`studioLocaleProvider`); Arabic turns on RTL and swaps every font to Tajawal.

## Roles

`session.me` returns the Frappe roles. `StudioRole.primaryOf` picks founder, lead, creator, then story. The order of
Today's blocks and of the More list per role is in `core/roles/studio_role.dart`. A signed-in user with none of the four
roles gets the "You don't have Studio access" screen and cannot get past it by deep link.

## Screens worth knowing

- A Today line says what happens next (`todayDoneNotesProvider` keeps the notes for lines just acted on).
- Posts: the post screen holds the ready-to-post panel (save the files, copy the caption, mark posted with the link) and
  the 72-hour read; `/calendar/drift` is the drift screen, reached from Today and the calendar banner.
- Paid: `paid_rule_check.dart` explains why a state change is or is not allowed and asks for a second tap when a rule says wait.
- A decision is one card for both kinds: options with a note, or one question with an answer box (founder only; the other
  roles read the question and who answers it). The same card sits in the Inbox list and on `/inbox/decisions/:id`.
- Every edit screen waits for its object with a loading and an error state (`piece_edit_screen.dart` is the pattern); none
  reads an unloaded value.
- The server may change typed text (angle brackets are stored as `‹ ›`). No screen compares what it sent with what came
  back; the returned object simply replaces the optimistic one.

## Tests

`flutter test test/studio`. Goldens (`test/studio/goldens/`) are made on Windows with the bundled fonts; regenerate with
`--update-goldens` if they differ on another platform.
