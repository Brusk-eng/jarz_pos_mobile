// Finds links, emails and phone numbers in chat text and opens them.
//
// Hand-written regexes (no package): customers paste wa.me / Instagram /
// maps links and write their number in Arabic-Indic digits between Arabic
// words. Detection is pure ([findChatLinks]); the tap actions are in
// [openChatLink].

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum ChatLinkKind { url, email, phone }

/// One detected link: `text.substring(start, end)` is [text] as displayed.
class ChatLinkMatch {
  const ChatLinkMatch({
    required this.start,
    required this.end,
    required this.kind,
    required this.text,
  });

  final int start;
  final int end;
  final ChatLinkKind kind;
  final String text;

  @override
  String toString() => 'ChatLinkMatch($kind, "$text", $start-$end)';
}

const _d = r'[0-9\u0660-\u0669\u06F0-\u06F9]';

final _urlRegex = RegExp(
  r'(?<![\w@./-])(?:'
  r'https?://[^\s<>"\u0600-\u06FF]+'
  r'|(?:www\.|m\.)[a-z0-9-]+\.[^\s<>"\u0600-\u06FF]+'
  r'|(?:wa\.me|api\.whatsapp\.com|instagram\.com|facebook\.com|fb\.me|fb\.com'
  r'|maps\.app\.goo\.gl|goo\.gl/maps|t\.me|tiktok\.com|youtube\.com|youtu\.be'
  r'|x\.com|twitter\.com)(?:/[^\s<>"\u0600-\u06FF]*)?'
  r')',
  caseSensitive: false,
);

final _emailRegex = RegExp(
  r'(?<![\w.%+-])[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}',
);

// Egyptian mobile: 01[0125] + 8 digits, or with 20 / +20 / 0020 in front.
// Each digit also has its Arabic-Indic / Persian form.
const _z = r'[0٠۰]';
const _one = r'[1١۱]';
const _two = r'[2٢۲]';
const _carrier = r'[0125٠١٢٥۰۱۲۵]';
final _egyptPhoneRegex = RegExp(
  '(?<!$_d|[\\w+#/.])(?:(?:\\+|00|٠٠)?$_two$_z[ \\-]?|$_z)$_one$_carrier'
  '(?:[ \\-]?$_d){8}(?!$_d)',
);

// Any other international number: needs a + or 00 prefix, 8-15 digits.
final _intlPhoneRegex = RegExp(
  '(?<!$_d|[\\w+#/.])(?:\\+|00)$_d(?:[ \\-]?$_d){6,14}(?!$_d)',
);

const _trailing = '.,;:!?\'"\u060C\u061B\u061F\u2026*';

String _stripTrailing(String raw) {
  var s = raw;
  while (s.isNotEmpty) {
    final last = s[s.length - 1];
    if (_trailing.contains(last)) {
      s = s.substring(0, s.length - 1);
    } else if (last == ')' || last == ']' || last == '}') {
      final open = last == ')' ? '(' : (last == ']' ? '[' : '{');
      final opens = open.allMatches(s).length;
      final closes = last.allMatches(s).length;
      if (closes > opens) {
        s = s.substring(0, s.length - 1);
      } else {
        break;
      }
    } else {
      break;
    }
  }
  return s;
}

/// ASCII digits for any Arabic-Indic / Persian digit in [value].
String chatNormalizeDigits(String value) {
  final out = StringBuffer();
  for (final r in value.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      out.writeCharCode(0x30 + r - 0x0660);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      out.writeCharCode(0x30 + r - 0x06F0);
    } else {
      out.writeCharCode(r);
    }
  }
  return out.toString();
}

/// The international digits (no +) of a displayed phone number, or null when
/// it is not a usable phone: `01012345678` -> `201012345678`.
String? chatPhoneInternationalDigits(String raw) {
  final trimmed = chatNormalizeDigits(raw).trim();
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (trimmed.startsWith('+')) {
    return digits.length >= 8 && digits.length <= 15 ? digits : null;
  }
  if (digits.startsWith('00')) {
    final rest = digits.substring(2);
    return rest.length >= 8 && rest.length <= 15 ? rest : null;
  }
  if (RegExp(r'^01[0125]\d{8}$').hasMatch(digits)) {
    return '20${digits.substring(1)}';
  }
  if (RegExp(r'^201[0125]\d{8}$').hasMatch(digits)) return digits;
  return null;
}

/// `https://wa.me/<digits>` for a phone number, or null.
Uri? chatWhatsAppUri(String rawPhone) {
  final digits = chatPhoneInternationalDigits(rawPhone);
  return digits == null ? null : Uri.parse('https://wa.me/$digits');
}

/// [raw] as a launchable URL: `https://` is added when the scheme is missing.
Uri? chatUrlUri(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  return Uri.tryParse(
    RegExp(r'^https?://', caseSensitive: false).hasMatch(value)
        ? value
        : 'https://$value',
  );
}

/// Every link in [text], in order, never overlapping.
List<ChatLinkMatch> findChatLinks(String text) {
  if (text.isEmpty) return const [];
  final found = <ChatLinkMatch>[];

  void collect(RegExp re, ChatLinkKind kind, {bool trim = false}) {
    for (final m in re.allMatches(text)) {
      var value = m.group(0)!;
      if (trim) value = _stripTrailing(value);
      if (value.isEmpty) continue;
      if (kind == ChatLinkKind.phone &&
          chatPhoneInternationalDigits(value) == null) {
        continue;
      }
      if (kind == ChatLinkKind.url && !value.contains('.')) continue;
      found.add(ChatLinkMatch(
        start: m.start,
        end: m.start + value.length,
        kind: kind,
        text: value,
      ));
    }
  }

  // The regexes use lookbehind; a browser without it (Safari before 16.4) throws
  // when one is first used. A message then shows as plain text, never an error.
  try {
    collect(_emailRegex, ChatLinkKind.email, trim: true);
    collect(_urlRegex, ChatLinkKind.url, trim: true);
    collect(_egyptPhoneRegex, ChatLinkKind.phone);
    collect(_intlPhoneRegex, ChatLinkKind.phone);
  } catch (_) {
    return const [];
  }

  found.sort((a, b) {
    final c = a.start.compareTo(b.start);
    if (c != 0) return c;
    return (b.end - b.start).compareTo(a.end - a.start);
  });
  final result = <ChatLinkMatch>[];
  var cursor = 0;
  for (final m in found) {
    if (m.start < cursor) continue;
    result.add(m);
    cursor = m.end;
  }
  return result;
}

String _bi(BuildContext context, String en, String ar) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

Future<void> _copy(BuildContext context, String value) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final label = _bi(context, 'Copied', 'اتنسخ');
  await Clipboard.setData(ClipboardData(text: value));
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(label), duration: const Duration(seconds: 2)),
    );
}

Future<void> _launch(BuildContext context, Uri? uri, String copyValue) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final failed = _bi(context, "Couldn't open this link", 'مش قادر يفتح اللينك');
  final copyLabel = _bi(context, 'Copy', 'نسخ');
  var ok = false;
  if (uri != null) {
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
  }
  if (ok) return;
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(failed),
        action: SnackBarAction(
          label: copyLabel,
          onPressed: () => Clipboard.setData(ClipboardData(text: copyValue)),
        ),
      ),
    );
}

/// What a tap on [link] does: open a URL / email, or offer Call / WhatsApp /
/// Copy for a phone number.
Future<void> openChatLink(BuildContext context, ChatLinkMatch link) async {
  switch (link.kind) {
    case ChatLinkKind.url:
      return _launch(context, chatUrlUri(link.text), link.text);
    case ChatLinkKind.email:
      return _launch(context, Uri(scheme: 'mailto', path: link.text), link.text);
    case ChatLinkKind.phone:
      final digits = chatPhoneInternationalDigits(link.text);
      if (digits == null) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Column(
            key: const ValueKey('chat-phone-actions'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '+$digits',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
              ),
              ListTile(
                key: const ValueKey('chat-phone-call'),
                leading: const Icon(Icons.call_outlined),
                title: Text(_bi(sheetContext, 'Call', 'اتصال')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _launch(context, Uri.parse('tel:+$digits'), '+$digits');
                },
              ),
              ListTile(
                key: const ValueKey('chat-phone-whatsapp'),
                leading: const Icon(Icons.chat_outlined),
                title: const Text('WhatsApp'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _launch(context, chatWhatsAppUri(link.text), '+$digits');
                },
              ),
              ListTile(
                key: const ValueKey('chat-phone-copy'),
                leading: const Icon(Icons.copy_outlined),
                title: Text(_bi(sheetContext, 'Copy', 'نسخ')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _copy(context, '+$digits');
                },
              ),
            ],
          ),
        ),
      );
  }
}
