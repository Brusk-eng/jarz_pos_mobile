/// The server wraps text that runs the other way than its sentence in the
/// Unicode isolates U+2068 and U+2069 (contract v1.3). They show as nothing,
/// but they must never travel with text the person copies.
final _isolates = RegExp(r'[\u2066-\u2069]');

/// [text] without any bidi isolate mark (U+2066 to U+2069). Use it on
/// everything that goes to the clipboard.
String withoutBidiIsolates(String text) => text.replaceAll(_isolates, '');
