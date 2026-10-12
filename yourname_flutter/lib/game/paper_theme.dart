import 'package:flutter/material.dart';

const ink = Color(0xFF171A20);
const mutedInk = Color(0xFF5C605F);
const paper = Color(0xFFFFF8ED);
const mist = Color(0xFFF0EADB);
const mint = Color(0xFFCDF0F6);
const sky = Color(0xFFDCECFF);
const butter = Color(0xFFFFDF45);
const forest = ink;
const chatBlue = Color(0xFF50C9EE);
const sunshine = Color(0xFFFFD629);
const coral = Color(0xFFFF937C);

ThemeData paperTheme() {
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(24));
  const border = OutlineInputBorder(
    borderSide: BorderSide.none,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    fontFamilyFallback: ['NotoSansTC'],
    scaffoldBackgroundColor: paper,
    colorScheme: const ColorScheme.light(
      primary: ink,
      onPrimary: Colors.white,
      secondary: chatBlue,
      onSecondary: ink,
      surface: paper,
      onSurface: ink,
      onSurfaceVariant: mutedInk,
      primaryContainer: sunshine,
      onPrimaryContainer: ink,
      secondaryContainer: mint,
      onSecondaryContainer: ink,
      outline: Color(0xFFD9D2C7),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 40,
        height: 1.12,
        fontWeight: FontWeight.w900,
        color: ink,
        letterSpacing: -1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 30,
        height: 1.18,
        fontWeight: FontWeight.w900,
        color: ink,
        letterSpacing: -.6,
      ),
      headlineSmall: TextStyle(
        fontSize: 25,
        height: 1.2,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 23,
        height: 1.3,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: ink),
      bodyMedium: TextStyle(fontSize: 15, height: 1.5, color: mutedInk),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: chatBlue,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontFamilyFallback: ['NotoSansTC'],
        fontWeight: FontWeight.w900,
        fontSize: 23,
        color: ink,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: mist,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: ink, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFAD291F)),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      hintStyle: TextStyle(color: mutedInk, fontSize: 15),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 56),
        backgroundColor: sunshine,
        foregroundColor: ink,
        disabledBackgroundColor: mist,
        disabledForegroundColor: mutedInk,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontFamilyFallback: ['NotoSansTC'],
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
        shape: shape,
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(48, 48),
        shape: shape,
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontFamilyFallback: ['NotoSansTC'],
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        backgroundColor: Colors.white,
        minimumSize: const Size(48, 52),
        side: const BorderSide(color: Color(0xFFD9D2C7)),
        shape: shape,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: sunshine,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ink,
      linearTrackColor: mist,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE3DCCF), space: 24),
  );
}
