import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

class MirrorTheme {
  MirrorTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: MirrorColors.bg,
    colorScheme: const ColorScheme.light(
      surface: MirrorColors.bg,
      onSurface: MirrorColors.text1,
      primary: MirrorColors.accent,
      onPrimary: MirrorColors.bg,
    ),
    fontFamily: GoogleFonts.outfit().fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: MirrorColors.bg,
      foregroundColor: MirrorColors.text1,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: MirrorColors.divider,
      thickness: 0.5,
      space: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MirrorColors.accent,
        foregroundColor: MirrorColors.bg,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MirrorRadius.lg),
        ),
        textStyle: MirrorText.button,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MirrorColors.bg2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MirrorRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MirrorRadius.md),
        borderSide: const BorderSide(color: MirrorColors.text1, width: 0.5),
      ),
      hintStyle: MirrorText.body.copyWith(color: MirrorColors.text3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}
