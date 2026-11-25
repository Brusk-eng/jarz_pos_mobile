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

## Fake API

`StudioApi` is the one door for Studio calls (`call(method, params)`, `message` envelope unwrapped). With
`STUDIO_FAKE=1`, `studioApiProvider` returns `FakeStudioApi`, which reads bundled JSON; nothing touches the network or
the POS env, and login is skipped.

- Fixtures: `assets/studio/fixtures/` (declared in `pubspec.yaml`).
- A call to `jarz_social.api.studio.<key>` reads `<key>__<role>.json` if it exists, else `<key>.json`.
  `session.me` has a variant per role: `session.me__founder.json`, `__lead`, `__creator`, `__story`, `__none`.
- A fixture may be the full Frappe envelope (`{"message": ...}`) or bare JSON.
- A missing fixture throws `StudioApiException(404)`.
- Tests override `studioFixtureBundleProvider` with an in-memory bundle (no real asset IO under fake time).

To add an endpoint: add `features/<feature>/data/<x>_repository.dart` calling `ref.read(studioApiProvider).call(...)`,
then drop `<key>.json` in the fixtures folder.

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

## Tests

`flutter test test/studio`. Goldens (`test/studio/goldens/`) are made on Windows with the bundled fonts; regenerate with
`--update-goldens` if they differ on another platform.
