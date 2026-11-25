import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Studio's UI language. Kept apart from the POS locale notifier so the two
/// apps never share state. In memory only for now.
final studioLocaleProvider = StateProvider<Locale>((ref) => const Locale('en'));
