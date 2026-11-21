// Flavour availability: parsing of get/set payloads, grouping by size, the
// screen's rows, and the segmented control sending the right value
// (optimistic, then replaced by the server's row; reverted on error).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/chat_inbox/data/chat_flavour_repository.dart';
import 'package:jarz_pos/src/features/chat_inbox/data/models/chat_flavour_models.dart';
import 'package:jarz_pos/src/features/chat_inbox/presentation/screens/chat_flavour_availability_screen.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

Map<String, dynamic> _item(
  String code, {
  String name = 'Lotus',
  String nameAr = 'لوتس',
  String size = 'Medium',
  String sizeAr = 'وسط',
  Object? stock = 12,
  String auto = 'available',
  String override = 'auto',
  String? effective,
}) => {
  'item_code': code,
  'name': name,
  'name_ar': nameAr,
  'size': size,
  'size_ar': sizeAr,
  'stock': stock,
  'auto': auto,
  'override': override,
  'effective': effective ?? (override == 'auto' ? auto : override),
};

Widget _app(MockDio dio, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      chatFlavourRepositoryProvider.overrideWithValue(
        ChatFlavourRepository(dio),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ChatFlavourAvailabilityScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPlatformChannels();

  group('models', () {
    test('parses a page, tolerating null stock and odd values', () {
      final page = ChatFlavourAvailabilityPage.fromJson({
        'items': [
          _item('JAR-L-LOTUS', size: 'Large', sizeAr: 'كبير', stock: '4.0'),
          _item(
            'JAR-M-MANGO',
            name: 'Mango',
            stock: null,
            auto: 'paused',
            override: 'available',
          ),
          {'item_code': ''},
          'junk',
          {
            'item_code': 'JAR-M-X',
            'size': 'Medium',
            'auto': 'PAUSED',
            'override': 'bogus',
          },
        ],
        'min_stock': '3',
      });
      expect(page.minStock, 3);
      expect(page.items.map((r) => r.itemCode), [
        'JAR-L-LOTUS',
        'JAR-M-MANGO',
        'JAR-M-X',
      ]);
      final lotus = page.items[0];
      expect(lotus.stock, 4.0);
      expect(lotus.isManual, isFalse);
      final mango = page.items[1];
      expect(mango.stock, isNull);
      expect(mango.auto, 'paused');
      expect(mango.override, 'available');
      expect(mango.effective, 'available');
      expect(mango.isManual, isTrue);
      final x = page.items[2];
      expect(x.override, 'auto');
      expect(x.effective, 'paused', reason: 'derived from auto when missing');

      expect(page.bySize.map((g) => g.key), ['Medium', 'Large']);
      expect(page.bySize.first.value.map((r) => r.itemCode), [
        'JAR-M-MANGO',
        'JAR-M-X',
      ]);
    });

    test('withOverride derives effective from auto', () {
      final row = ChatFlavourAvailability.fromJson(_item('A', auto: 'paused'));
      expect(row.effective, 'paused');
      expect(row.withOverride('available').effective, 'available');
      expect(row.withOverride('auto').effective, 'paused');
    });
  });

  testWidgets('shows rows grouped by size with stock, status and note', (
    tester,
  ) async {
    final dio = MockDio()
      ..setResponse(ChatFlavourRepository.getPath, {
        'message': {
          'items': [
            _item('JAR-L-LOTUS', size: 'Large', sizeAr: 'كبير'),
            _item(
              'JAR-M-MANGO',
              name: 'Mango',
              stock: null,
              auto: 'paused',
              override: 'available',
            ),
          ],
          'min_stock': 3,
        },
      });
    await tester.pumpWidget(_app(dio));
    await tester.pumpAndSettle();

    expect(find.text('Flavour availability'), findsOneWidget);
    expect(find.textContaining('under 3 jars'), findsOneWidget);
    // Medium is listed before Large.
    final medium = tester.getTopLeft(find.text('Medium'));
    final large = tester.getTopLeft(find.text('Large'));
    expect(medium.dy, lessThan(large.dy));
    expect(find.text('Mango'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('flavour-stock-JAR-M-MANGO')))
          .data,
      '—',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('flavour-stock-JAR-L-LOTUS')))
          .data,
      '12 jars',
    );
    expect(
      find.byKey(const ValueKey('flavour-manual-JAR-M-MANGO')),
      findsOneWidget,
    );
    expect(find.text('Set by hand — stock says: Paused'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('flavour-manual-JAR-L-LOTUS')),
      findsNothing,
    );
  });

  testWidgets('Arabic locale shows Arabic names and labels', (tester) async {
    final dio = MockDio()
      ..setResponse(ChatFlavourRepository.getPath, {
        'message': {
          'items': [_item('JAR-M-LOTUS')],
          'min_stock': 3,
        },
      });
    await tester.pumpWidget(_app(dio, locale: const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text('النكهات المتاحة'), findsOneWidget);
    expect(find.text('لوتس'), findsOneWidget);
    expect(find.text('وسط'), findsOneWidget);
    expect(find.text('تلقائي'), findsOneWidget);
  });

  testWidgets('tapping Paused posts availability=paused and shows the '
      "server's row", (tester) async {
    final dio = MockDio()
      ..setResponse(ChatFlavourRepository.getPath, {
        'message': {
          'items': [_item('JAR-M-LOTUS')],
          'min_stock': 3,
        },
      })
      ..setResponse(ChatFlavourRepository.setPath, {
        'message': {
          'item': _item('JAR-M-LOTUS', stock: 11, override: 'paused'),
        },
      });
    await tester.pumpWidget(_app(dio));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('flavour-choice-JAR-M-LOTUS-paused')),
    );
    await tester.pumpAndSettle();

    final posts = dio.requestLog
        .where((r) => r['path'] == ChatFlavourRepository.setPath)
        .toList();
    expect(posts, hasLength(1));
    expect(posts.single['method'], 'POST');
    expect(posts.single['data'], {
      'item_code': 'JAR-M-LOTUS',
      'availability': 'paused',
    });
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('flavour-stock-JAR-M-LOTUS')))
          .data,
      '11 jars',
    );
    expect(find.text('Set by hand — stock says: Available'), findsOneWidget);
    final chip = find.byKey(const ValueKey('flavour-status-JAR-M-LOTUS'));
    expect(
      find.descendant(of: chip, matching: find.text('Paused')),
      findsOneWidget,
    );
  });

  testWidgets('a failed save reverts the row and shows a SnackBar', (
    tester,
  ) async {
    final dio = MockDio()
      ..setResponse(ChatFlavourRepository.getPath, {
        'message': {
          'items': [_item('JAR-M-LOTUS')],
          'min_stock': 3,
        },
      })
      ..setError(
        ChatFlavourRepository.setPath,
        DioException(
          requestOptions: RequestOptions(path: ChatFlavourRepository.setPath),
          response: Response(
            requestOptions: RequestOptions(path: ChatFlavourRepository.setPath),
            statusCode: 417,
            data: {
              'exc_type': 'ValidationError',
              '_server_messages':
                  '["{\\"message\\": \\"Not a chat flavour\\"}"]',
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );
    await tester.pumpWidget(_app(dio));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('flavour-choice-JAR-M-LOTUS-available')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.byKey(const ValueKey('flavour-manual-JAR-M-LOTUS')),
      findsNothing,
      reason: 'reverted to Auto',
    );
  });
}
