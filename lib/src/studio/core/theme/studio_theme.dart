import 'package:flutter/material.dart';

import 'studio_tokens.dart';

/// Text styles that are not part of Material's [TextTheme] slots.
class StudioTextStyles {
  StudioTextStyles._();

  /// Section label above a block of cards.
  static const sectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: StudioColors.plumMuted,
  );

  static const caption = TextStyle(fontSize: 12, color: StudioColors.plumMuted);
}

/// Builds the Studio theme (light only). Arabic swaps every family to Tajawal:
/// DM Serif Display has no Arabic glyphs.
ThemeData buildStudioTheme({Locale locale = const Locale('en')}) {
  final isArabic = locale.languageCode == 'ar';
  final bodyFamily = isArabic ? StudioFonts.arabic : StudioFonts.body;
  final headingFamily = isArabic ? StudioFonts.arabic : StudioFonts.display;

  final scheme =
      ColorScheme.fromSeed(
        seedColor: StudioColors.berryPink,
        brightness: Brightness.light,
      ).copyWith(
        primary: StudioColors.berryPink,
        onPrimary: Colors.white,
        primaryContainer: StudioColors.softBlush,
        onPrimaryContainer: StudioColors.deepPlum,
        secondary: StudioColors.deepPlum,
        onSecondary: Colors.white,
        tertiary: StudioColors.jarzGold,
        surface: StudioColors.warmWhite,
        onSurface: StudioColors.deepPlum,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: StudioColors.blushPale,
        surfaceContainer: StudioColors.blushPale,
        surfaceContainerHighest: StudioColors.softBlush,
        outline: StudioColors.border,
        outlineVariant: StudioColors.border,
        error: StudioColors.danger,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: StudioColors.warmWhite,
    fontFamily: bodyFamily,
  );

  TextStyle heading(double size) => TextStyle(
    fontFamily: headingFamily,
    fontSize: size,
    height: 1.2,
    color: StudioColors.deepPlum,
    fontWeight: isArabic ? FontWeight.w700 : FontWeight.w400,
  );
  TextStyle body(double size, {FontWeight? weight}) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: size,
    height: 1.4,
    color: StudioColors.deepPlum,
    fontWeight: weight,
  );

  final textTheme = base.textTheme.copyWith(
    displaySmall: heading(32),
    headlineMedium: heading(26),
    headlineSmall: heading(22),
    titleLarge: heading(20),
    titleMedium: body(16, weight: FontWeight.w700),
    titleSmall: body(14, weight: FontWeight.w700),
    bodyLarge: body(16),
    bodyMedium: body(14),
    bodySmall: body(12).copyWith(color: StudioColors.plumMuted),
    labelLarge: body(14, weight: FontWeight.w700),
    labelMedium: body(12, weight: FontWeight.w700),
    labelSmall: body(11, weight: FontWeight.w700),
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: StudioColors.warmWhite,
      foregroundColor: StudioColors.deepPlum,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: heading(20),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioRadii.md),
        side: const BorderSide(color: StudioColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: StudioColors.border,
      space: 1,
      thickness: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: StudioColors.softBlush,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(body(12, weight: FontWeight.w700)),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: StudioColors.softBlush,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: StudioColors.deepPlum,
      unselectedLabelColor: StudioColors.plumMuted,
      indicatorColor: StudioColors.berryPink,
      labelStyle: body(14, weight: FontWeight.w700),
      unselectedLabelStyle: body(14),
      dividerColor: StudioColors.border,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: StudioColors.berryPink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioRadii.md),
        ),
        minimumSize: const Size(48, 48),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StudioRadii.md),
        borderSide: const BorderSide(color: StudioColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StudioRadii.md),
        borderSide: const BorderSide(color: StudioColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StudioRadii.md),
        borderSide: const BorderSide(color: StudioColors.berryPink, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: StudioColors.deepPlum,
      contentTextStyle: body(14).copyWith(color: Colors.white),
    ),
  );
}
