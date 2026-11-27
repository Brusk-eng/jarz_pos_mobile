import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the brand fonts and the SDK icon font so a screenshot shows real
/// glyphs (the same loader the golden tests use).
Future<void> loadShotFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  await load('Inter', [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
  await load('DMSerifDisplay', ['assets/fonts/DMSerifDisplay-Regular.ttf']);
  await load('Tajawal', [
    'assets/fonts/Tajawal-Regular.ttf',
    'assets/fonts/Tajawal-Bold.ttf',
  ]);
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final f = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (f.existsSync()) {
      final bytes = f.readAsBytesSync();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  }
}

/// Makes `Image.network` answer with a soft brand-coloured picture (one per
/// URL), so a screenshot shows thumbnails where the fixtures have links.
Future<HttpOverrides> fakePictureOverrides(WidgetTester tester) async {
  final pics = <Uint8List>[];
  await tester.runAsync(() => _makePics(pics));
  return _PicOverrides(pics);
}

Future<void> _makePics(List<Uint8List> pics) async {
  const palette = [
    (Color(0xFFEF6B7A), Color(0xFFF1CBE1)),
    (Color(0xFF434057), Color(0xFFEF6B7A)),
    (Color(0xFFC4A265), Color(0xFFF5EDE0)),
    (Color(0xFF6E6B80), Color(0xFFF1CBE1)),
    (Color(0xFFD94F63), Color(0xFFFDF5FA)),
    (Color(0xFF8B5E83), Color(0xFFF1CBE1)),
  ];
  for (final (a, b) in palette) {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    const size = Size(240, 300);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          [a, b],
        ),
    );
    // A simple jar silhouette so it reads as a product picture.
    final jar = Paint()..color = const Color(0x55FFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(70, 110, 100, 130),
        const Radius.circular(18),
      ),
      jar,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(80, 90, 80, 24),
        const Radius.circular(6),
      ),
      jar,
    );
    final img = await rec.endRecording().toImage(240, 300);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    pics.add(data!.buffer.asUint8List());
  }
}

class _PicOverrides extends HttpOverrides {
  _PicOverrides(this.pics);
  final List<Uint8List> pics;
  @override
  HttpClient createHttpClient(SecurityContext? context) => _Client(pics);
}

class _Client implements HttpClient {
  _Client(this.pics);
  final List<Uint8List> pics;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _Request(pics[url.toString().hashCode.abs() % pics.length]);
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _Request implements HttpClientRequest {
  _Request(this.bytes);
  final Uint8List bytes;
  @override
  final HttpHeaders headers = _Headers();
  @override
  Future<HttpClientResponse> close() async => _Response(bytes);
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _Headers implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.bytes);
  final Uint8List bytes;
  @override
  int get statusCode => 200;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.fromIterable([bytes]).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

/// A view of [w] x [h] logical pixels at devicePixelRatio 1.
void useSize(WidgetTester tester, double w, double h) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(w, h);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
