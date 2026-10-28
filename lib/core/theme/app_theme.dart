import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Nila's OTT dark "cinema" palette: near-black plum surfaces with the
/// brand pink as the single accent and gold reserved for Premium.
abstract final class AppColors {
  static const background = Color(0xFF0E090D);
  static const surface = Color(0xFF181116);
  static const surfaceHigh = Color(0xFF231920);
  static const surfaceHighest = Color(0xFF2E2229);
  static const hairline = Color(0x1AFFFFFF);

  static const pink = Color(0xFFE5156B);
  static const pinkBright = Color(0xFFFF4F93);
  static const pinkDeep = Color(0xFFB80E54);
  static const pinkTint = Color(0x26E5156B);

  static const text = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFC9BCC4);
  static const textTertiary = Color(0xFF8E7F88);

  static const gold = Color(0xFFF6C34A);
  static const goldDeep = Color(0xFF5C3A00);
  static const success = Color(0xFF34C77B);
  static const danger = Color(0xFFFF5A5F);

  static const goldGradient = LinearGradient(colors: [Color(0xFFFFE08A), gold]);

  static const pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF3D87), pinkDeep],
  );

  /// Fades artwork into the page background.
  static const scrimBottom = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x000E090D), Color(0x990E090D), background],
    stops: [0.45, 0.78, 1],
  );

  /// Keeps the status bar and floating buttons legible over artwork.
  static const scrimTop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xB3000000), Color(0x00000000)],
  );
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  /// Horizontal page gutter.
  static const gutter = 16.0;

  static const radiusSm = 6.0;
  static const radius = 10.0;
  static const radiusLg = 14.0;
  static const radiusXl = 20.0;
}

/// Type scale tuned to iOS/Android native sizes.
abstract final class AppText {
  static const largeTitle = TextStyle(fontSize: 30, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppColors.text);
  static const title1 = TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: AppColors.text);
  static const title2 = TextStyle(fontSize: 20, height: 1.25, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: AppColors.text);
  static const headline = TextStyle(fontSize: 17, height: 1.3, fontWeight: FontWeight.w700, color: AppColors.text);
  static const body = TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const bodyStrong = TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w600, color: AppColors.text);
  static const subhead = TextStyle(fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static const caption = TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w500, color: AppColors.textTertiary);
  static const label = TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: AppColors.textSecondary);
}

const appOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarBrightness: Brightness.dark,
  statusBarIconBrightness: Brightness.light,
  systemNavigationBarColor: AppColors.background,
  systemNavigationBarIconBrightness: Brightness.light,
);

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.pink,
    onPrimary: Colors.white,
    secondary: AppColors.gold,
    onSecondary: AppColors.goldDeep,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surfaceHigh,
    surfaceContainerHighest: AppColors.surfaceHighest,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.hairline,
    outlineVariant: AppColors.hairline,
    error: AppColors.danger,
  );
  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: scheme);
  final text = base.textTheme.apply(bodyColor: AppColors.text, displayColor: AppColors.text);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    splashFactory: InkSparkle.splashFactory,
    textTheme: text.copyWith(
      headlineMedium: AppText.title1,
      headlineSmall: AppText.title2,
      titleLarge: AppText.title2,
      titleMedium: AppText.headline,
      titleSmall: AppText.bodyStrong,
      bodyLarge: AppText.body.copyWith(fontSize: 16),
      bodyMedium: AppText.body,
      bodySmall: AppText.caption,
      labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
    }),
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: appOverlayStyle,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      foregroundColor: AppColors.text,
      centerTitle: true,
      titleTextStyle: AppText.headline,
    ),
    iconTheme: const IconThemeData(color: AppColors.text),
    dividerTheme: const DividerThemeData(color: AppColors.hairline, thickness: 0.5, space: 0.5),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w400),
      labelStyle: const TextStyle(color: AppColors.textTertiary),
      floatingLabelStyle: const TextStyle(color: AppColors.pinkBright, fontWeight: FontWeight.w600),
      prefixIconColor: AppColors.textTertiary,
      suffixIconColor: AppColors.textTertiary,
      errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(color: AppColors.pink, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.pink,
      selectionColor: AppColors.pinkTint,
      selectionHandleColor: AppColors.pink,
    ),
    cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: AppColors.pink, brightness: Brightness.dark),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.pinkBright,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppColors.surfaceHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl))),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppText.headline,
      contentTextStyle: AppText.body,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.textSecondary,
      textColor: AppColors.text,
      titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text),
      subtitleTextStyle: AppText.caption,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHighest,
      contentTextStyle: TextStyle(color: AppColors.text, fontSize: 14.5),
      actionTextColor: AppColors.pinkBright,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.pink, linearTrackColor: Color(0x33FFFFFF)),
  );
}
