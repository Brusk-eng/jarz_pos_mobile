// "See what the client gets": the send preview, app side.
//
// What these guard:
//   * the preview call has the same wire shape as create_material_share (the
//     material list as ONE JSON string, never repeated form keys) and carries
//     the rep's edited message untouched — `{link}` included;
//   * the payload parses leniently and file URLs come back absolute, while
//     the placeholder link stays exactly as the server wrote it;
//   * the button previews exactly what Send would send now (edited message,
//     ticked materials in library order, chosen recipient);
//   * Send from the preview runs the sheet's own send with those same inputs,
//     and Back to edit sends nothing.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/materials/data/materials_repository.dart';
import 'package:jarz_pos/src/features/materials/data/models/material_share_preview.dart';
import 'package:jarz_pos/src/features/materials/data/models/sales_material.dart';
import 'package:jarz_pos/src/features/materials/presentation/screens/client_preview_screen.dart';
import 'package:jarz_pos/src/features/materials/presentation/widgets/send_materials_sheet.dart';

const _placeholder = 'https://erp.example.test/m/xxxxxxxxxxxxxxxx';

Map<String, dynamic> _previewJson() => {
  'message': 'Hi Ahmed\n$_placeholder\nthanks',
  'link_placeholder_url': _placeholder,
  'greeting_name': 'Ahmed',
  'items': [
    {
      'title': 'Jarz B2B Price List',
      'type': 'Generated Price List',
      'download_url': '/files/jarz_price_sheets/abc/price-list.pdf',
      'pages': [
        {
          'thumb': '/files/p1-thumb.webp',
          'screen': '/files/p1-screen.webp',
          'full': 'https://cdn.example.test/p1-full.webp',
          'w': 1240,
          'h': '1754',
        },
      ],
    },
    {
      'title': 'Catalogue',
      'type': null,
      'download_url': '/files/catalogue.zip',
      'pages': [],
    },
  ],
  'material_names': ['MAT-00007', 'MAT-00001'],
};

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body);

  final Object body;
  final List<RequestOptions> requests = [];

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'message': body}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

MaterialsRepository _repository(_RecordingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://erp.example.test'));
  dio.httpClientAdapter = adapter;
  return MaterialsRepository(dio);
}

void main() {
  group('MaterialSharePreview.fromJson', () {
    test('should parse message, greeting, items and names', () {
      final preview = MaterialSharePreview.fromJson(_previewJson());
      expect(preview.message, contains(_placeholder));
      expect(preview.linkPlaceholderUrl, _placeholder);
      expect(preview.greetingName, 'Ahmed');
      expect(preview.items, hasLength(2));
      expect(preview.items.first.pages.single.h, 1754);
      expect(preview.items.first.isDownloadOnly, isFalse);
      expect(preview.items.last.type, '');
      expect(preview.items.last.isDownloadOnly, isTrue);
      expect(preview.materialNames, ['MAT-00007', 'MAT-00001']);
    });

    test('should read a blank or missing greeting as none', () {
      expect(
        MaterialSharePreview.fromJson({'greeting_name': '  '}).greetingName,
        isNull,
      );
      final empty = MaterialSharePreview.fromJson({});
      expect(empty.greetingName, isNull);
      expect(empty.items, isEmpty);
      expect(empty.message, '');
    });

    test('should resolve file URLs but leave the placeholder alone', () {
      final preview = MaterialSharePreview.fromJson(
        _previewJson(),
      ).resolvedAgainst('https://erp.example.test/');
      final page = preview.items.first.pages.single;
      expect(page.screen, 'https://erp.example.test/files/p1-screen.webp');
      expect(page.full, 'https://cdn.example.test/p1-full.webp');
      expect(
        preview.items.last.downloadUrl,
        'https://erp.example.test/files/catalogue.zip',
      );
      expect(preview.linkPlaceholderUrl, _placeholder);
    });
  });

  group('MaterialsRepository.previewMaterialShare', () {
    test('should POST the pack in create_material_share\'s shape', () async {
      final adapter = _RecordingAdapter(_previewJson());
      final preview = await _repository(adapter).previewMaterialShare(
        referenceDoctype: 'Customer',
        referenceName: 'Cafe Orbit',
        materials: const ['MAT-00007', 'MAT-00001'],
        contactName: ' Ahmed ',
        message: 'Hi Ahmed\n{link}\nthanks',
      );
      final request = adapter.last;
      expect(
        request.path,
        contains('jarz_pos.api.materials.preview_material_share'),
      );
      expect(request.method, 'POST');
      expect(request.data, {
        'reference_doctype': 'Customer',
        'reference_name': 'Cafe Orbit',
        'materials': '["MAT-00007","MAT-00001"]',
        'contact_name': 'Ahmed',
        'message': 'Hi Ahmed\n{link}\nthanks',
      });
      expect(
        preview.items.first.pages.single.screen,
        startsWith('https://erp.example.test/'),
      );
    });

    test('should omit blank optional fields and default to Lead', () async {
      final adapter = _RecordingAdapter(_previewJson());
      await _repository(adapter).previewMaterialShare(
        referenceName: 'CRM-LEAD-2026-00042',
        materials: const ['MAT-00001'],
        contactName: '  ',
        message: '   ',
      );
      expect(adapter.last.data, {
        'reference_doctype': 'Lead',
        'reference_name': 'CRM-LEAD-2026-00042',
        'materials': '["MAT-00001"]',
      });
    });
  });

  group('send sheet client preview', () {
    const library = MaterialLibrary(
      messageTemplate: 'Hi {name}\n{link}',
      namePlaceholder: '{name}',
      linkPlaceholder: '{link}',
      nameFallback: 'there',
      materials: [
        SalesMaterial(
          name: 'MAT-00007',
          title: 'Jarz B2B Price List',
          sourceType: 'Generated Price List',
          generated: true,
          ready: true,
          isDefault: true,
          pageCount: 1,
        ),
        SalesMaterial(name: 'MAT-00001', title: 'Catalogue', ready: true),
        SalesMaterial(name: 'MAT-00002', title: 'Menu', ready: true),
      ],
    );
    const recipients = [
      MaterialRecipient(name: 'Ahmed', phone: '01111034268'),
      MaterialRecipient(name: 'Mona', phone: '01000000000'),
    ];

    late _FakeRepository repository;
    setUp(() => repository = _FakeRepository(library));

    Future<void> openSheet(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(
          repository,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSendMaterialsSheet(
                  context,
                  referenceDoctype: 'Customer',
                  referenceName: 'Cafe Orbit',
                  recipients: recipients,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    /// Ticks Menu then Catalogue (tap order reversed from library order),
    /// picks Mona and rewrites the message.
    Future<void> editSheet(WidgetTester tester) async {
      await tester.tap(find.text('Menu'));
      await tester.pump();
      await tester.tap(find.text('Catalogue'));
      await tester.pump();
      await tester.tap(find.text('Mona'));
      await tester.pump();
      await tester.enterText(
        find.byType(TextField),
        'Edited for Mona\n{link}\nbye',
      );
      await tester.pump();
    }

    testWidgets('should preview the edited message and ticked materials', (
      tester,
    ) async {
      await openSheet(tester);
      await editSheet(tester);

      await tester.tap(find.byKey(const ValueKey('materials-client-preview')));
      await tester.pumpAndSettle();

      expect(find.byType(ClientPreviewScreen), findsOneWidget);
      final call = repository.previews.single;
      expect(call.doctype, 'Customer');
      expect(call.name, 'Cafe Orbit');
      expect(call.materials, ['MAT-00007', 'MAT-00001', 'MAT-00002']);
      expect(call.contactName, 'Mona');
      expect(call.message, 'Edited for Mona\n{link}\nbye');

      // The replica: message bubble, link caption, greeting, both items.
      expect(
        find.byKey(const ValueKey('client-preview-message')),
        findsOneWidget,
      );
      expect(find.text('Link is created when you press send'), findsOneWidget);
      expect(find.text('Hello Ahmed'), findsOneWidget);
      expect(find.text('Jarz B2B Price List'), findsWidgets);
      expect(
        find.textContaining('The client gets a download button'),
        findsOneWidget,
      );
      expect(repository.shares, isEmpty);
    });

    testWidgets('should run the sheet\'s send from the preview', (
      tester,
    ) async {
      await openSheet(tester);
      await editSheet(tester);

      await tester.tap(find.byKey(const ValueKey('materials-client-preview')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('client-preview-send')));
      await tester.pumpAndSettle();

      final share = repository.shares.single;
      expect(share.doctype, 'Customer');
      expect(share.name, 'Cafe Orbit');
      expect(share.materials, ['MAT-00007', 'MAT-00001', 'MAT-00002']);
      expect(share.contactName, 'Mona');
      expect(share.contactPhone, '01000000000');
      expect(share.message, 'Edited for Mona\n{link}\nbye');
      // Both the preview and the sheet are gone.
      expect(find.byType(ClientPreviewScreen), findsNothing);
      expect(find.byKey(const ValueKey('materials-send')), findsNothing);
    });

    testWidgets('should send nothing on Back to edit', (tester) async {
      await openSheet(tester);

      await tester.tap(find.byKey(const ValueKey('materials-client-preview')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('client-preview-back')));
      await tester.pumpAndSettle();

      expect(repository.shares, isEmpty);
      expect(find.byType(ClientPreviewScreen), findsNothing);
      expect(find.byKey(const ValueKey('materials-send')), findsOneWidget);
    });

    testWidgets('should disable the button with nothing ticked', (
      tester,
    ) async {
      await openSheet(tester);
      await tester.tap(find.text('Jarz B2B Price List'));
      await tester.pump();

      final button = tester.widget<ButtonStyleButton>(
        find.byKey(const ValueKey('materials-client-preview')),
      );
      expect(button.onPressed, isNull);
    });
  });
}

typedef _Call = ({
  String doctype,
  String name,
  List<String> materials,
  String? contactName,
  String? contactPhone,
  String? message,
});

class _FakeRepository extends MaterialsRepository {
  _FakeRepository(this.library) : super(Dio());

  final MaterialLibrary library;
  final List<_Call> previews = [];
  final List<_Call> shares = [];

  @override
  Future<MaterialLibrary> getLibrary() async => library;

  @override
  Future<MaterialSharePreview> previewMaterialShare({
    required String referenceName,
    required List<String> materials,
    String referenceDoctype = 'Lead',
    String? contactName,
    String? message,
  }) async {
    previews.add((
      doctype: referenceDoctype,
      name: referenceName,
      materials: materials,
      contactName: contactName,
      contactPhone: null,
      message: message,
    ));
    // Empty image URLs: the page widget renders, nothing hits the network.
    final json = _previewJson();
    for (final item in json['items'] as List) {
      for (final page in (item as Map)['pages'] as List) {
        (page as Map)
          ..['thumb'] = ''
          ..['screen'] = ''
          ..['full'] = '';
      }
    }
    return MaterialSharePreview.fromJson(json);
  }

  @override
  Future<MaterialShare> createShare({
    required String referenceName,
    required List<String> materials,
    String referenceDoctype = 'Lead',
    String? contactName,
    String? contactPhone,
    String? message,
  }) async {
    shares.add((
      doctype: referenceDoctype,
      name: referenceName,
      materials: materials,
      contactName: contactName,
      contactPhone: contactPhone,
      message: message,
    ));
    return const MaterialShare(token: 'abc', url: 'https://x.test/m/abc');
  }

  @override
  Future<List<MaterialShareSummary>> getShares({
    required String referenceName,
    String referenceDoctype = 'Lead',
    int limit = 20,
  }) async => const [];
}

Widget _app(MaterialsRepository repository, Widget home) {
  return ProviderScope(
    overrides: [materialsRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}
