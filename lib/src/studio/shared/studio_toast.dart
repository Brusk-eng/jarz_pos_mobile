import 'package:flutter/material.dart';

/// THE one `ScaffoldMessenger` of the Studio app (`MaterialApp.scaffoldMessengerKey`).
///
/// Every toast goes through [showStudioToast] / [showStudioSnackBar], so it does
/// not matter whether the screen that asked for it is still on screen: a toast
/// shown as a screen closes is not lost and never throws on a dead context.
final GlobalKey<ScaffoldMessengerState> studioMessengerKey =
    GlobalKey<ScaffoldMessengerState>(debugLabel: 'studio-messenger');

/// Shows [bar] on the root messenger, replacing the one on screen.
void showStudioSnackBar(SnackBar bar) {
  studioMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(bar);
}

/// Shows [text] as a toast; [duration] longer for an error, [action] for a link.
void showStudioToast(
  String text, {
  Duration? duration,
  SnackBarAction? action,
}) => showStudioSnackBar(
  SnackBar(
    content: Text(text),
    action: action,
    duration: duration ?? const Duration(milliseconds: 4000),
  ),
);

/// How long an error toast stays.
const studioErrorToastDuration = Duration(seconds: 6);
