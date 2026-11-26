import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/src/studio/core/config/studio_config.dart';
import 'package:jarz_pos/src/studio/core/l10n/studio_locale.dart';
import 'package:jarz_pos/src/studio/core/network/studio_api.dart';
import 'package:jarz_pos/src/studio/core/offline/kv_store.dart';
import 'package:jarz_pos/src/studio/data/fake/fake_studio_api.dart';
import 'package:jarz_pos/src/studio/features/session/data/biometric_service.dart';
import 'package:jarz_pos/src/studio/features/session/data/session_repository.dart';
import 'package:jarz_pos/src/studio/features/session/state/studio_session_notifier.dart';
import 'package:jarz_pos/src/studio/features/settings/presentation/settings_hub_screen.dart';
import 'package:jarz_pos/src/studio/studio_app.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';

import '../helpers.dart';
import '../more/more_test_utils.dart';

/// In-memory stand-in for the device service: records every call.
class FakeBiometric implements StudioBiometricService {
  FakeBiometric({
    this.supported = true,
    this.usable = true,
    this.enabled = false,
    this.offered = false,
    this.unlockResult,
    this.enrolOk = true,
  });

  @override
  bool supported;
  bool usable;
  bool enabled;
  bool offered;
  bool enrolOk;
  BiometricCredentials? unlockResult;

  final calls = <String>[];
  BiometricCredentials? enrolled;

  @override
  Future<bool> canUse() async => supported && usable;
  @override
  Future<bool> isEnabled() async => supported && enabled;
  @override
  Future<bool> wasOffered() async => offered;
  @override
  Future<void> markOffered() async {
    calls.add('markOffered');
    offered = true;
  }

  @override
  Future<bool> enable(String username, String password) async {
    calls.add('enable');
    if (!enrolOk) return false;
    enrolled = BiometricCredentials(username, password);
    enabled = true;
    unlockResult = enrolled;
    return true;
  }

  @override
  Future<BiometricCredentials?> unlock() async {
    calls.add('unlock');
    return unlockResult;
  }

  @override
  Future<void> refresh(String username, String password) async {
    calls.add('refresh');
  }

  @override
  Future<void> wipe() async {
    calls.add('wipe');
    enabled = false;
    unlockResult = null;
  }
}

/// Session repository without a server: `login` answers [loginOk].
class FakeRepo extends StudioSessionRepository {
  FakeRepo(StudioApi api, {this.loginOk = true})
    : super(api, () => throw UnimplementedError());

  bool loginOk;
  final logins = <String>[];

  @override
  Future<bool> login(String username, String password) async {
    logins.add(username);
    return loginOk;
  }

  @override
  Future<void> logout() async {}
}

const _creds = BiometricCredentials('ali@jarz.test', 'test-pass-only');

void main() {
  group('session notifier', () {
    late FakeStudioApi api;
    late FakeBiometric bio;
    late FakeRepo repo;

    ProviderContainer make() {
      final c = ProviderContainer(
        overrides: [
          studioApiProvider.overrideWithValue(api),
          studioBiometricProvider.overrideWithValue(bio),
          studioSessionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    setUp(() {
      api = FakeStudioApi(delay: Duration.zero);
      bio = FakeBiometric();
      repo = FakeRepo(api);
    });

    test(
      'after a password login the offer is raised once, with the login',
      () async {
        api.failNext('session.me', 'UNAUTHENTICATED');
        final c = make();
        expect(await c.read(studioSessionProvider.future), isNull);
        expect(
          await c.read(studioSessionProvider.notifier).login('a', 'b'),
          isTrue,
        );
        final offer = c.read(studioBiometricOfferProvider);
        expect(offer?.username, 'a');
        expect(offer?.password, 'b');
      },
    );

    test('no offer when it was asked before', () async {
      bio.offered = true;
      api.failNext('session.me', 'UNAUTHENTICATED');
      final c = make();
      await c.read(studioSessionProvider.future);
      await c.read(studioSessionProvider.notifier).login('a', 'b');
      expect(c.read(studioBiometricOfferProvider), isNull);
    });

    test('no offer when the phone has no biometric enrolled', () async {
      bio.usable = false;
      api.failNext('session.me', 'UNAUTHENTICATED');
      final c = make();
      await c.read(studioSessionProvider.future);
      await c.read(studioSessionProvider.notifier).login('a', 'b');
      expect(c.read(studioBiometricOfferProvider), isNull);
    });

    test('no offer and no prompt on web (not supported)', () async {
      bio.supported = false;
      api.failNext('session.me', 'UNAUTHENTICATED');
      final c = make();
      await c.read(studioSessionProvider.future);
      await c.read(studioSessionProvider.notifier).login('a', 'b');
      expect(c.read(studioBiometricOfferProvider), isNull);
      expect(bio.calls, isEmpty);
    });

    test('when on, a password login keeps the stored login in step', () async {
      bio.enabled = true;
      api.failNext('session.me', 'UNAUTHENTICATED');
      final c = make();
      // The dead session at boot offers the fingerprint; cancel it.
      await c.read(studioSessionProvider.future);
      bio.calls.clear();
      await c.read(studioSessionProvider.notifier).login('a', 'new');
      expect(bio.calls, ['refresh']);
    });

    test(
      'dead session at boot: fingerprint success signs in silently',
      () async {
        bio.enabled = true;
        bio.unlockResult = _creds;
        api.failNext('session.me', 'UNAUTHENTICATED');
        final c = make();
        final me = await c.read(studioSessionProvider.future);
        expect(me, isNotNull);
        expect(repo.logins, [_creds.username]);
        expect(bio.calls, ['unlock']);
      },
    );

    test(
      'dead session: cancel leaves the password form, nothing wiped',
      () async {
        bio.enabled = true;
        bio.unlockResult = null;
        api.failNext('session.me', 'UNAUTHENTICATED');
        final c = make();
        expect(await c.read(studioSessionProvider.future), isNull);
        expect(repo.logins, isEmpty);
        expect(bio.calls, ['unlock']);
        expect(bio.enabled, isTrue);
      },
    );

    test('dead session: a refused stored password wipes it', () async {
      bio.enabled = true;
      bio.unlockResult = _creds;
      repo.loginOk = false;
      api.failNext('session.me', 'UNAUTHENTICATED');
      final c = make();
      expect(await c.read(studioSessionProvider.future), isNull);
      expect(bio.calls, ['unlock', 'wipe']);
      expect(bio.enabled, isFalse);
    });

    test('dead session while off: straight to the login, no prompt', () async {
      api.failNext('session.me', 'UNAUTHENTICATED');
      final c = make();
      expect(await c.read(studioSessionProvider.future), isNull);
      expect(bio.calls, isEmpty);
    });

    test('the login-screen button signs in, and reports a cancel', () async {
      bio.enabled = true;
      api.failNext('session.me', 'UNAUTHENTICATED');
      final c = make();
      await c.read(studioSessionProvider.future); // cancelled at boot
      final n = c.read(studioSessionProvider.notifier);
      expect(await n.biometricSignIn(), isFalse);
      bio.unlockResult = _creds;
      expect(await n.biometricSignIn(), isTrue);
      expect(c.read(studioSessionProvider).valueOrNull, isNotNull);
    });

    test(
      'a session that dies in use asks for the fingerprint only when on',
      () async {
        final c = make();
        await c.read(studioSessionProvider.future);
        await c.read(studioSessionProvider.notifier).onSessionExpired();
        expect(bio.calls, isEmpty);

        bio.enabled = true;
        bio.unlockResult = _creds;
        api.failNext('session.me', 'UNAUTHENTICATED');
        await c.read(studioSessionProvider.notifier).onSessionExpired();
        expect(bio.calls, ['unlock']);
        expect(c.read(studioSessionProvider).valueOrNull, isNotNull);
      },
    );

    test('sign out wipes the stored login', () async {
      bio.enabled = true;
      final c = make();
      await c.read(studioSessionProvider.future);
      await c.read(studioSessionProvider.notifier).signOut();
      expect(bio.calls, contains('wipe'));
      expect(bio.enabled, isFalse);
      expect(c.read(studioBiometricOfferProvider), isNull);
    });
  });

  group('screens', () {
    Future<(ProviderContainer, FakeBiometric, FakeStudioApi)> pump(
      WidgetTester tester, {
      FakeBiometric? bio,
      bool signedOut = true,
      String locale = 'en',
    }) async {
      usePhone(tester);
      final b = bio ?? FakeBiometric();
      final api = FakeStudioApi(delay: Duration.zero);
      if (signedOut) api.failNext('session.me', 'UNAUTHENTICATED');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studioFakeProvider.overrideWithValue(true),
            studioApiProvider.overrideWithValue(api),
            studioKvStoreProvider.overrideWithValue(MemoryKvStore()),
            studioFakeRoleProvider.overrideWithValue('founder'),
            studioBiometricProvider.overrideWithValue(b),
            studioLocaleProvider.overrideWith((ref) => Locale(locale)),
          ],
          child: const StudioApp(),
        ),
      );
      await tester.pumpAndSettle();
      final c = ProviderScope.containerOf(
        tester.element(find.byType(StudioApp)),
      );
      return (c, b, api);
    }

    Future<void> logIn(WidgetTester tester) async {
      await tester.enterText(find.byKey(const ValueKey('login-user')), 'ali');
      await tester.enterText(find.byKey(const ValueKey('login-password')), 'x');
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pumpAndSettle();
    }

    testWidgets('the offer appears once after login; yes turns it on', (
      tester,
    ) async {
      final (_, bio, _) = await pump(tester);
      await logIn(tester);
      expect(find.byKey(const ValueKey('biometric-offer')), findsOneWidget);
      expect(
        find.text('Use fingerprint / face to sign in next time?'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('biometric-offer-yes')));
      await tester.pumpAndSettle();
      expect(bio.calls, ['markOffered', 'enable']);
      expect(bio.enrolled?.username, 'ali');
      expect(bio.offered, isTrue);
      expect(find.byKey(const ValueKey('biometric-offer')), findsNothing);
    });

    testWidgets('the offer in Arabic', (tester) async {
      await pump(tester, locale: 'ar');
      await logIn(tester);
      expect(find.text('تدخل بالبصمة أو الوش المرة الجاية؟'), findsOneWidget);
    });

    testWidgets('no thanks: nothing stored, not asked again', (tester) async {
      final (_, bio, _) = await pump(tester);
      await logIn(tester);
      await tester.tap(find.byKey(const ValueKey('biometric-offer-no')));
      await tester.pumpAndSettle();
      expect(bio.calls, ['markOffered']);
      expect(bio.enrolled, isNull);
      expect(bio.offered, isTrue);
    });

    testWidgets('web: no offer, no login button', (tester) async {
      final (_, bio, _) = await pump(
        tester,
        bio: FakeBiometric(supported: false),
      );
      expect(find.byKey(const ValueKey('login-biometric')), findsNothing);
      await logIn(tester);
      expect(find.byKey(const ValueKey('biometric-offer')), findsNothing);
      expect(bio.calls, isEmpty);
    });

    testWidgets('on: open the app, cancel, then the button signs in', (
      tester,
    ) async {
      final bio = FakeBiometric(enabled: true);
      final (c, _, _) = await pump(tester, bio: bio);
      // Cancelled at boot: the password form with the fingerprint button.
      expect(find.byKey(const ValueKey('login-user')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-biometric')), findsOneWidget);
      bio.unlockResult = _creds;
      await tester.tap(find.byKey(const ValueKey('login-biometric')));
      await tester.pumpAndSettle();
      expect(c.read(studioSessionProvider).valueOrNull, isNotNull);
      expect(find.byKey(const ValueKey('login-user')), findsNothing);
    });

    testWidgets('a cancelled button press keeps the password form', (
      tester,
    ) async {
      final (c, _, _) = await pump(tester, bio: FakeBiometric(enabled: true));
      await tester.tap(find.byKey(const ValueKey('login-biometric')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('login-user')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('login-biometric-failed')),
        findsOneWidget,
      );
      expect(c.read(studioSessionProvider).valueOrNull, isNull);
    });

    testWidgets('boot with a live session and fingerprint on: lands on Today', (
      tester,
    ) async {
      final (c, bio, _) = await pump(
        tester,
        bio: FakeBiometric(enabled: true),
        signedOut: false,
      );
      expect(currentLocation(c), '/today');
      expect(bio.calls, isEmpty);
    });

    testWidgets('dead session on a deep link: fingerprint lands there', (
      tester,
    ) async {
      final bio = FakeBiometric(enabled: true, unlockResult: _creds);
      final (c, _, _) = await pump(tester, bio: bio);
      // Booted straight into the app through the fingerprint (today).
      expect(currentLocation(c), '/today');
      expect(bio.calls, ['unlock']);
    });

    testWidgets('settings: the switch turns it off and wipes', (tester) async {
      usePhone(tester);
      final bio = FakeBiometric(enabled: true);
      await pumpMore(
        tester,
        const SettingsHubScreen(),
        size: const Size(360, 1800),
        overrides: [studioBiometricProvider.overrideWithValue(bio)],
      );
      final tile = find.byKey(const ValueKey('settings-biometric'));
      expect(tester.widget<SwitchListTile>(tile).value, isTrue);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(bio.calls, contains('wipe'));
      expect(bio.enabled, isFalse);
      expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    });

    testWidgets('settings: turning it on asks for the password once', (
      tester,
    ) async {
      usePhone(tester);
      final bio = FakeBiometric();
      await pumpMore(
        tester,
        const SettingsHubScreen(),
        size: const Size(360, 1800),
        overrides: [
          studioBiometricProvider.overrideWithValue(bio),
          studioSessionRepositoryProvider.overrideWith(
            (ref) => FakeRepo(ref.watch(studioApiProvider)),
          ),
        ],
      );
      final tile = find.byKey(const ValueKey('settings-biometric'));
      await tester.tap(tile);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('biometric-password')),
        'secret-test',
      );
      await tester.tap(find.byKey(const ValueKey('biometric-password-ok')));
      await tester.pumpAndSettle();
      expect(bio.calls, ['enable']);
      expect(bio.enrolled?.password, 'secret-test');
      expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    });

    testWidgets('settings: hidden on web, disabled with no enrolment', (
      tester,
    ) async {
      usePhone(tester);
      await pumpMore(
        tester,
        const SettingsHubScreen(),
        size: const Size(360, 1800),
        overrides: [
          studioBiometricProvider.overrideWithValue(
            FakeBiometric(supported: false),
          ),
        ],
      );
      expect(find.byKey(const ValueKey('settings-biometric')), findsNothing);

      await pumpMore(
        tester,
        const SettingsHubScreen(),
        size: const Size(360, 1800),
        overrides: [
          studioBiometricProvider.overrideWithValue(
            FakeBiometric(usable: false),
          ),
        ],
      );
      final tile = find.byKey(const ValueKey('settings-biometric'));
      expect(tester.widget<SwitchListTile>(tile).onChanged, isNull);
      expect(
        find.text('Set up a fingerprint or face in your phone settings first.'),
        findsOneWidget,
      );
    });
  });

  group('device service', () {
    late _FakeLocalAuth auth;
    late FlutterSecureStorage storage;
    late MethodChannel guard;
    late bool guardValid;
    late List<String> guardCalls;

    DeviceBiometricService make({bool supported = true}) =>
        DeviceBiometricService(
          auth: LocalAuthentication(),
          storage: storage,
          guard: guard,
          platformSupported: supported,
        );

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      storage = const FlutterSecureStorage();
      auth = _FakeLocalAuth();
      LocalAuthPlatform.instance = auth;
      guard = const MethodChannel('test/biometric_guard');
      guardValid = true;
      guardCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(guard, (call) async {
            guardCalls.add(call.method);
            return switch (call.method) {
              'arm' => true,
              'isValid' => guardValid,
              _ => null,
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(guard, null),
      );
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    Future<Map<String, String>> stored() => storage.readAll();

    test(
      'enable asks for the biometric first, then stores the login',
      () async {
        final s = make();
        expect(await s.enable('u', 'p'), isTrue);
        expect(auth.authCalls, 1);
        expect(auth.lastBiometricOnly, isTrue);
        expect(guardCalls, ['arm']);
        expect(await s.isEnabled(), isTrue);
        final c = await s.unlock();
        expect(c?.username, 'u');
        expect(c?.password, 'p');
        expect('$c', isNot(contains('p')));
      },
    );

    test('a cancelled prompt stores nothing', () async {
      auth.authResult = false;
      final s = make();
      expect(await s.enable('u', 'p'), isFalse);
      expect(await stored(), isEmpty);
    });

    test('unlock cancel keeps the login but returns nothing', () async {
      final s = make();
      await s.enable('u', 'p');
      auth.authResult = false;
      expect(await s.unlock(), isNull);
      expect(await s.isEnabled(), isTrue);
    });

    test(
      'new fingerprints enrolled: the stored login is wiped, no prompt',
      () async {
        final s = make();
        await s.enable('u', 'p');
        auth.authCalls = 0;
        guardValid = false;
        expect(await s.unlock(), isNull);
        expect(auth.authCalls, 0);
        expect(await s.isEnabled(), isFalse);
        expect((await stored()).containsKey('jarz_studio_bio_pass'), isFalse);
        expect(guardCalls.last, 'disarm');
      },
    );

    test('wipe removes login and guard key', () async {
      final s = make();
      await s.enable('u', 'p');
      await s.wipe();
      final left = await stored();
      expect(left.containsKey('jarz_studio_bio_user'), isFalse);
      expect(left.containsKey('jarz_studio_bio_pass'), isFalse);
      expect(await s.isEnabled(), isFalse);
      expect(guardCalls.last, 'disarm');
    });

    test('refresh rewrites only when on', () async {
      final s = make();
      await s.refresh('u', 'p');
      expect(await stored(), isEmpty);
      await s.enable('u', 'p');
      await s.refresh('u', 'p2');
      auth.authResult = true;
      expect((await s.unlock())?.password, 'p2');
    });

    test('a guard that cannot be armed refuses to turn on', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(guard, (call) async => false);
      final s = make();
      expect(await s.enable('u', 'p'), isFalse);
      expect(await stored(), isEmpty);
    });

    test('unsupported platform (web): nothing works, nothing stored', () async {
      final s = make(supported: false);
      expect(s.supported, isFalse);
      expect(await s.canUse(), isFalse);
      expect(await s.isEnabled(), isFalse);
      expect(await s.enable('u', 'p'), isFalse);
      expect(auth.authCalls, 0);
    });

    test('needs a strong biometric enrolled', () async {
      auth.types = [BiometricType.weak];
      expect(await make().canUse(), isFalse);
      auth.types = [BiometricType.strong];
      expect(await make().canUse(), isTrue);
    });
  });
}

class _FakeLocalAuth extends LocalAuthPlatform {
  bool authResult = true;
  int authCalls = 0;
  bool? lastBiometricOnly;
  List<BiometricType> types = [BiometricType.strong];

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    authCalls++;
    lastBiometricOnly = options.biometricOnly;
    return authResult;
  }

  @override
  Future<bool> deviceSupportsBiometrics() async => true;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async => types;

  @override
  Future<bool> stopAuthentication() async => true;
}
