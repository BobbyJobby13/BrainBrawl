import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';

ThemeData getBlackWhiteTheme() {
  final ThemeData base = ThemeData.dark();
  final TextTheme textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme)
      .apply(
        bodyColor: Palette.textPrimary,
        displayColor: Palette.textPrimary,
      );

  return base.copyWith(
    primaryColor: Palette.background,
    primaryColorLight: Colors.white,
    scaffoldBackgroundColor: Palette.background,
    colorScheme: ColorScheme.dark(
      primary: Palette.pink,
      onPrimary: Colors.white,
      secondary: Palette.violet,
      onSecondary: Colors.white,
      surface: Palette.surface,
      onSurface: Palette.textPrimary,
      background: Palette.background,
      onBackground: Palette.textPrimary,
      error: Palette.danger,
      onError: Colors.white,
    ),
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.background,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: Palette.textPrimary),
      titleTextStyle: TextStyle(
        color: Palette.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Palette.surfaceRaised,
      contentTextStyle: GoogleFonts.spaceGrotesk(color: Palette.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Palette.pink,
    ),
  );
}
