// The generated B2B price sheet, app side: the material flags, the preview
// and template payloads, the wire shape of the three price-sheet calls, and
// what the template editor actually saves.
//
// What these guard:
//   * a generated material is recognisable from either `generated` or
//     `source_type`, and an older server (neither key) reads as uploaded;
//   * Frappe's 0/1 Check values and string numbers parse, never throw;
//   * the save payload carries exactly the template's own keys (no
//     `available_*`, `price_lists`, `can_edit`, `name`) and travels as ONE
//     JSON string — Dio would otherwise form-encode the nested lists, which
//     Frappe flattens to the last value;
//   * page URLs come back absolute so `Image.network` can load them.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarz_pos/l10n/app_localizations.dart';
import 'package:jarz_pos/src/features/b2b/data/models/b2b_models.dart';
import 'package:jarz_pos/src/features/b2b/presentation/screens/b2b_account_screen.dart'
    show b2bMaterialRecipients;
import 'package:jarz_pos/src/features/materials/data/materials_repository.dart';
import 'package:jarz_pos/src/features/materials/data/models/price_sheet.dart';
import 'package:jarz_pos/src/features/materials/data/models/sales_material.dart';
import 'package:jarz_pos/src/features/materials/presentation/screens/price_sheet_template_screen.dart';
import 'package:jarz_pos/src/features/materials/presentation/widgets/send_materials_sheet.dart';

/// Records every request and answers each path with a canned body.
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

Map<String, dynamic> _templateJson({bool canEdit = true}) => {
  'name': 'MAT-00007',
  'title': 'Jarz B2B Price List',
  'title_ar': 'قائمة أسعار جارز',
  'enabled': 1,
  'is_default': 0,
  'sheet_heading': 'Price List',
  'sheet_price_list': null,
  'sheet_sizes': ['Medium', 'Large'],
  'sheet_show_deals': 1,
  'sheet_terms': ['الحد الأدنى للطلب: ١٢ جار', 'التسليم: التوصيل بواسطة جارز'],
  'sheet_footer': 'More Than Just a Jar',
  'rows': [
    {
      'flavour': 'Strawberry',
      'label': 'Strawberry cheesecake jar',
      'enabled': 1,
    },
    {'flavour': 'Blueberry', 'label': '', 'enabled': 0},
  ],
  'available_flavours': ['Strawberry', 'Blueberry', 'Mango', 'Molten'],
  'available_sizes': ['Large', 'Medium', 'Small'],
  'price_lists': ['B2B Selling', 'Standard Selling'],
  'can_edit': canEdit,
};

Map<String, dynamic> _previewJson() => {
  'pdf_url': '/files/jarz_price_sheets/abc123/price-list.pdf',
  'pages': [
    {
      'thumb': '/files/jarz_price_sheets/abc123/p1-thumb.webp',
      'screen': '/files/jarz_price_sheets/abc123/p1-screen.webp',
      'full': 'https://cdn.example.test/p1-full.webp',
      'w': 1240,
      'h': '1754',
    },
  ],
  'sheet': <String, dynamic>{
    'heading': 'Price List',
    'customer_name': 'Café Orbit',
    'price_list': 'B2B Selling',
    'currency': 'EGP',
    'as_of': '2026-11-21',
    'sizes': ['Medium', 'Large'],
    'rows': [
      {
        'flavour': 'Strawberry',
        'label': 'Strawberry cheesecake jar',
        'cells': [
          {'size': 'Medium', 'rate': 70, 'normal_rate': 77, 'is_deal': true},
          {'size': 'Large', 'rate': '92', 'normal_rate': null, 'is_deal': 0},
        ],
      },
    ],
    'deal_until': '2026-11-30',
    'terms': [
      {'label': 'الحد الأدنى للطلب', 'text': '١٢ جار'},
      {'label': null, 'text': 'سطر بدون عنوان'},
    ],
    'footer': 'More Than Just a Jar',
  },
};

void main() {
  group('SalesMaterial generated flags', () {
    test('should read a generated sheet from the new keys', () {
      final material = SalesMaterial.fromJson({
        'name': 'MAT-00007',
        'source_type': 'Generated Price List',
        'generated': true,
        'ready': true,
        'download_url': null,
        'page_count': 1,
      });
      expect(material.generated, isTrue);
      expect(material.sourceType, 'Generated Price List');
      expect(material.isGenerated, isTrue);
      expect(material.downloadUrl, '');
    });

    test('should treat source_type alone as generated', () {
      final material = SalesMaterial.fromJson({
        'name': 'MAT-1',
        'source_type': 'Generated Price List',
      });
      expect(material.isGenerated, isTrue);
    });

    test('should read an older server payload as an uploaded file', () {
      final material = SalesMaterial.fromJson({'name': 'MAT-1'});
      expect(material.sourceType, 'Uploaded File');
      expect(material.generated, isFalse);
      expect(material.isGenerated, isFalse);
    });

    test('should parse can_edit_sheets on the library, default false', () {
      expect(
        MaterialLibrary.fromJson({'can_edit_sheets': true}).canEditSheets,
        isTrue,
      );
      expect(MaterialLibrary.fromJson({}).canEditSheets, isFalse);
    });
  });

  group('PriceSheetPreview.fromJson', () {
    test('should parse pages, cells, deals and terms leniently', () {
      final preview = PriceSheetPreview.fromJson(_previewJson());
      expect(preview.pages.single.h, 1754);
      final sheet = preview.sheet;
      expect(sheet.customerName, 'Café Orbit');
      expect(sheet.dealUntilDate, DateTime(2026, 11, 30));
      expect(sheet.hasDeals, isTrue);
      final cells = sheet.rows.single.cells;
      expect(cells.first.isDeal, isTrue);
      expect(cells.first.normalRate, 77);
      expect(cells.last.rate, 92);
      expect(cells.last.isDeal, isFalse);
      expect(sheet.terms.last.label, isNull);
    });

    test('should leave customer and deal line empty for a Lead preview', () {
      final json = _previewJson();
      (json['sheet'] as Map)['customer_name'] = null;
      (json['sheet'] as Map)['deal_until'] = null;
      final sheet = PriceSheetPreview.fromJson(json).sheet;
      expect(sheet.customerName, isNull);
      expect(sheet.dealUntilDate, isNull);
    });

    test('should resolve relative URLs and keep absolute ones', () {
      final preview = PriceSheetPreview.fromJson(
        _previewJson(),
      ).resolvedAgainst('https://erp.example.test/');
      final page = preview.pages.single;
      expect(
        page.screen,
        'https://erp.example.test/files/jarz_price_sheets/abc123/p1-screen.webp',
      );
      expect(page.full, 'https://cdn.example.test/p1-full.webp');
      expect(
        preview.pdfUrl,
        'https://erp.example.test/files/jarz_price_sheets/abc123/price-list.pdf',
      );
    });
  });

  group('PriceSheetTemplate', () {
    test('should parse 0/1 flags and the choice lists', () {
      final template = PriceSheetTemplate.fromJson(_templateJson());
      expect(template.enabled, isTrue);
      expect(template.isDefault, isFalse);
      expect(template.sheetShowDeals, isTrue);
      expect(template.sheetPriceList, isNull);
      expect(template.rows.last.enabled, isFalse);
      expect(template.canEdit, isTrue);
      expect(template.addableFlavours, ['Mango', 'Molten']);
    });

    test('should accept sizes as a comma string', () {
      final json = _templateJson()..['sheet_sizes'] = 'Medium, Large';
      expect(PriceSheetTemplate.fromJson(json).sheetSizes, ['Medium', 'Large']);
    });

    test('should round-trip into a save payload of only the template keys', () {
      final template = PriceSheetTemplate.fromJson(_templateJson());
      final payload = template.toSavePayload();
      expect(payload.keys.toSet(), {
        'title',
        'title_ar',
        'enabled',
        'is_default',
        'sheet_heading',
        'sheet_price_list',
        'sheet_sizes',
        'sheet_show_deals',
        'sheet_terms',
        'sheet_footer',
        'rows',
      });
      expect(payload['sheet_price_list'], isNull);
      expect(payload['sheet_sizes'], ['Medium', 'Large']);
      expect(payload['rows'], [
        {
          'flavour': 'Strawberry',
          'label': 'Strawberry cheesecake jar',
          'enabled': true,
        },
        {'flavour': 'Blueberry', 'label': '', 'enabled': false},
      ]);

      // And back: the payload re-parses into the same editable template.
      final again = PriceSheetTemplate.fromJson({
        ...jsonDecode(jsonEncode(payload)) as Map<String, dynamic>,
        'name': template.name,
        'available_flavours': template.availableFlavours,
        'available_sizes': template.availableSizes,
        'price_lists': template.priceLists,
        'can_edit': template.canEdit,
      });
      expect(again, template);
    });

    test('should send a blank price list as null and drop blank terms', () {
      final template = PriceSheetTemplate.fromJson(
        _templateJson(),
      ).copyWith(sheetPriceList: '  ', sheetTerms: ['a: b', '   ', '']);
      final payload = template.toSavePayload();
      expect(payload['sheet_price_list'], isNull);
      expect(payload['sheet_terms'], ['a: b']);
    });
  });

  group('MaterialsRepository price sheet calls', () {
    test(
      'should preview with the reference and return absolute pages',
      () async {
        final adapter = _RecordingAdapter(_previewJson());
        final preview = await _repository(adapter).previewPriceSheet(
          material: 'MAT-00007',
          referenceDoctype: 'Customer',
          referenceName: 'Cafe Orbit',
        );
        expect(adapter.last.path, contains('price_sheet.preview_price_sheet'));
        expect(adapter.last.method, 'POST');
        expect(adapter.last.data, {
          'material': 'MAT-00007',
          'reference_doctype': 'Customer',
          'reference_name': 'Cafe Orbit',
        });
        expect(
          preview.pages.single.screen,
          startsWith('https://erp.example.test/'),
        );
      },
    );

    test(
      'should preview without a reference for the template editor',
      () async {
        final adapter = _RecordingAdapter(_previewJson());
        await _repository(adapter).previewPriceSheet(material: 'MAT-00007');
        expect(adapter.last.data, {'material': 'MAT-00007'});
      },
    );

    test('should fetch a template by material', () async {
      final adapter = _RecordingAdapter(_templateJson());
      final template = await _repository(
        adapter,
      ).getPriceSheetTemplate('MAT-00007');
      expect(
        adapter.last.path,
        contains('price_sheet.get_price_sheet_template'),
      );
      expect(adapter.last.data, {'material': 'MAT-00007'});
      expect(template.rows, hasLength(2));
    });

    test('should POST the template as one JSON string', () async {
      final adapter = _RecordingAdapter(_templateJson());
      final template = PriceSheetTemplate.fromJson(_templateJson());
      await _repository(
        adapter,
      ).savePriceSheetTemplate(material: 'MAT-00007', template: template);
      final request = adapter.last;
      expect(request.path, contains('price_sheet.save_price_sheet_template'));
      expect(request.method, 'POST');
      final data = request.data as Map;
      expect(data['material'], 'MAT-00007');
      expect(data['data'], isA<String>());
      expect(jsonDecode(data['data'] as String), template.toSavePayload());
    });
  });

  group('b2bMaterialRecipients', () {
    test('should list each distinct phone once under the account name', () {
      const account = B2bAccount(
        doctype: 'Customer',
        name: 'CUST-0001',
        title: 'Café Orbit',
        contact: B2bContact(mobileNo: '01111034268', phone: '01111034268'),
      );
      final recipients = b2bMaterialRecipients(account);
      expect(recipients, hasLength(1));
      expect(recipients.single.name, 'Café Orbit');
      expect(recipients.single.phone, '01111034268');
    });

    test('should be empty when the account has no phone', () {
      const account = B2bAccount(
        doctype: 'Customer',
        name: 'CUST-0001',
        title: 'X',
      );
      expect(b2bMaterialRecipients(account), isEmpty);
    });
  });

  group('PriceSheetTemplateScreen', () {
    late _FakeRepository repository;

    setUp(() => repository = _FakeRepository());

    Future<void> pumpEditor(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 4200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
    }

    testWidgets('should save exactly what was edited', (tester) async {
      await pumpEditor(tester);

      await tester.enterText(
        find.byKey(const ValueKey('price-sheet-heading')),
        'Wholesale prices',
      );
      // Ordered multi-select: Small joins as the third column.
      await tester.tap(find.byKey(const ValueKey('price-sheet-size-Small')));
      await tester.pump();
      // Re-enable Blueberry and move it above Strawberry.
      final blueberry = find.byKey(const ValueKey('price-sheet-row-Blueberry'));
      await tester.tap(
        find.descendant(of: blueberry, matching: find.byType(Switch)),
      );
      await tester.pump();
      await tester.tap(
        find.descendant(of: blueberry, matching: find.byTooltip('Move up')),
      );
      await tester.pump();
      // A new term line.
      await tester.tap(find.byKey(const ValueKey('price-sheet-add-term')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('price-sheet-term-2')),
        'الدفع: نقدي عند الاستلام',
      );
      await tester.tap(find.byKey(const ValueKey('price-sheet-default')));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('price-sheet-save')));
      await tester.pumpAndSettle();

      expect(repository.saved, hasLength(1));
      final payload = repository.saved.single.toSavePayload();
      expect(payload['sheet_heading'], 'Wholesale prices');
      expect(payload['sheet_sizes'], ['Medium', 'Large', 'Small']);
      expect(payload['sheet_price_list'], isNull);
      expect(payload['is_default'], isTrue);
      expect(payload['sheet_show_deals'], isTrue);
      expect(payload['rows'], [
        {'flavour': 'Blueberry', 'label': '', 'enabled': true},
        {
          'flavour': 'Strawberry',
          'label': 'Strawberry cheesecake jar',
          'enabled': true,
        },
      ]);
      expect(payload['sheet_terms'], [
        'الحد الأدنى للطلب: ١٢ جار',
        'التسليم: التوصيل بواسطة جارز',
        'الدفع: نقدي عند الاستلام',
      ]);
      expect(find.text('Template saved'), findsOneWidget);
    });

    testWidgets('should refuse to save with no size picked', (tester) async {
      await pumpEditor(tester);

      await tester.tap(find.byKey(const ValueKey('price-sheet-size-Medium')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('price-sheet-size-Large')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('price-sheet-save')));
      await tester.pumpAndSettle();

      expect(repository.saved, isEmpty);
      expect(find.text('Pick at least one size.'), findsOneWidget);
    });

    testWidgets('should be read-only without manager pricing access', (
      tester,
    ) async {
      repository = _FakeRepository(canEdit: false);
      await pumpEditor(tester);

      expect(find.byKey(const ValueKey('price-sheet-save')), findsNothing);
      expect(
        find.text('Only a pricing manager can change this template.'),
        findsOneWidget,
      );
      final heading = tester.widget<TextField>(
        find.byKey(const ValueKey('price-sheet-heading')),
      );
      expect(heading.enabled, isFalse);
    });
  });

  _sendSheetTests();
}

void _sendSheetTests() {
  group('send sheet with a generated sheet', () {
    MaterialLibrary library({required bool canEdit}) => MaterialLibrary(
      canEditSheets: canEdit,
      materials: const [
        SalesMaterial(
          name: 'MAT-00007',
          title: 'Jarz B2B Price List',
          sourceType: 'Generated Price List',
          generated: true,
          ready: true,
          pageCount: 1,
        ),
        SalesMaterial(name: 'MAT-00001', title: 'Catalogue', ready: true),
      ],
    );

    Future<void> openSheet(WidgetTester tester, MaterialLibrary value) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(
          _FakeRepository(library: value),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSendMaterialsSheet(
                  context,
                  referenceDoctype: 'Customer',
                  referenceName: 'Cafe Orbit',
                  recipients: const [],
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

    testWidgets('should mark it auto-priced and offer a preview', (
      tester,
    ) async {
      await openSheet(tester, library(canEdit: false));
      expect(
        find.byKey(const ValueKey('materials-auto-prices-MAT-00007')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('materials-preview-MAT-00007')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('materials-auto-prices-MAT-00001')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('materials-edit-template-MAT-00007')),
        findsNothing,
      );
      // A customer with no phone gets the customer wording, not the lead one.
      expect(find.textContaining('No phone on this customer'), findsOneWidget);
    });

    testWidgets('should offer Edit template only with can_edit_sheets', (
      tester,
    ) async {
      await openSheet(tester, library(canEdit: true));
      expect(
        find.byKey(const ValueKey('materials-edit-template-MAT-00007')),
        findsOneWidget,
      );
    });
  });
}

class _FakeRepository extends MaterialsRepository {
  _FakeRepository({this.canEdit = true, this.library = const MaterialLibrary()})
    : super(Dio());

  final MaterialLibrary library;

  final bool canEdit;
  final List<PriceSheetTemplate> saved = [];

  @override
  Future<PriceSheetTemplate> getPriceSheetTemplate(String material) async =>
      PriceSheetTemplate.fromJson(_templateJson(canEdit: canEdit));

  @override
  Future<PriceSheetTemplate> savePriceSheetTemplate({
    required String material,
    required PriceSheetTemplate template,
  }) async {
    saved.add(template);
    return template;
  }

  @override
  Future<MaterialLibrary> getLibrary() async => library;
}

Widget _app(MaterialsRepository repository, {Widget? home}) {
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
      home: home ?? const PriceSheetTemplateScreen(material: 'MAT-00007'),
    ),
  );
}
