import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final textTheme = TextTheme(
      headlineLarge: AppTypography.headingLarge(color: AppColors.bone),
      headlineMedium: AppTypography.headingMedium(color: AppColors.bone),
      headlineSmall: AppTypography.headingSmall(color: AppColors.bone),
      bodyLarge: AppTypography.bodyLarge(color: AppColors.bone),
      bodyMedium: AppTypography.bodyMedium(color: AppColors.bone),
      bodySmall: AppTypography.bodySmall(color: AppColors.ash),
      labelLarge: AppTypography.labelGothic(color: AppColors.brass, fontSize: 13),
      labelMedium: AppTypography.labelGothic(color: AppColors.ash, fontSize: 11),
      labelSmall: AppTypography.labelGothic(color: AppColors.ashDark, fontSize: 9),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.obsidian,
      canvasColor: AppColors.crypt,
      cardColor: AppColors.crypt,
      dividerColor: AppColors.ironLine,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brass,
        onPrimary: AppColors.obsidian,
        secondary: AppColors.verdigris,
        onSecondary: AppColors.bone,
        error: AppColors.oxbloodLit,
        onError: AppColors.bone,
        surface: AppColors.crypt,
        onSurface: AppColors.bone,
        onSurfaceVariant: AppColors.ash,
        outline: AppColors.ironLine,
        outlineVariant: AppColors.ironLineSubtle,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.obsidian,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headingLarge(color: AppColors.bone),
        iconTheme: const IconThemeData(color: AppColors.bone, size: 20),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.obsidian,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.crypt,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: const BorderSide(color: AppColors.ironLine, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.crypt,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          side: BorderSide(color: AppColors.ironLine, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.crypt,
        elevation: 0,
        titleTextStyle: AppTypography.headingMedium(color: AppColors.bone),
        contentTextStyle: AppTypography.bodyMedium(color: AppColors.bone),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.ironLine, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slab,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: AppTypography.bodyMedium(color: AppColors.ashDark),
        labelStyle: AppTypography.labelGothic(color: AppColors.ash),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: AppColors.ironLine, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: AppColors.brass, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: AppColors.oxbloodLit, width: 1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brass,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          textStyle: AppTypography.labelGothic(color: AppColors.brass),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brass,
          foregroundColor: AppColors.obsidian,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
          textStyle: AppTypography.labelGothic(
            color: AppColors.obsidian,
            fontSize: 13,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.slab,
        contentTextStyle: AppTypography.bodyMedium(color: AppColors.bone),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: const BorderSide(color: AppColors.ironLine, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData light() {
    final textTheme = TextTheme(
      headlineLarge: AppTypography.headingLarge(color: AppColors.vellumInk),
      headlineMedium: AppTypography.headingMedium(color: AppColors.vellumInk),
      headlineSmall: AppTypography.headingSmall(color: AppColors.vellumInk),
      bodyLarge: AppTypography.bodyLarge(color: AppColors.vellumInk),
      bodyMedium: AppTypography.bodyMedium(color: AppColors.vellumInk),
      bodySmall: AppTypography.bodySmall(color: AppColors.vellumAsh),
      labelLarge: AppTypography.labelGothic(color: AppColors.brass, fontSize: 13),
      labelMedium: AppTypography.labelGothic(color: AppColors.vellumAsh, fontSize: 11),
      labelSmall: AppTypography.labelGothic(color: AppColors.vellumAshDark, fontSize: 9),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.vellumParchment,
      canvasColor: AppColors.vellumCrypt,
      cardColor: AppColors.vellumCrypt,
      dividerColor: AppColors.vellumIronLine,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brass,
        onPrimary: AppColors.vellumInk,
        secondary: AppColors.verdigris,
        onSecondary: AppColors.vellumParchment,
        error: AppColors.oxblood,
        onError: AppColors.vellumParchment,
        surface: AppColors.vellumCrypt,
        onSurface: AppColors.vellumInk,
        onSurfaceVariant: AppColors.vellumAsh,
        outline: AppColors.vellumIronLine,
        outlineVariant: Color(0xFFD4CBBB),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.vellumParchment,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headingLarge(color: AppColors.vellumInk),
        iconTheme: const IconThemeData(color: AppColors.vellumInk, size: 20),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.vellumParchment,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.vellumCrypt,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: const BorderSide(color: AppColors.vellumIronLine, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.vellumCrypt,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          side: BorderSide(color: AppColors.vellumIronLine, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.vellumCrypt,
        elevation: 0,
        titleTextStyle: AppTypography.headingMedium(color: AppColors.vellumInk),
        contentTextStyle: AppTypography.bodyMedium(color: AppColors.vellumInk),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.vellumIronLine, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.vellumSlab,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: AppTypography.bodyMedium(color: AppColors.vellumAshDark),
        labelStyle: AppTypography.labelGothic(color: AppColors.vellumAsh),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: AppColors.vellumIronLine, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: AppColors.brass, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: AppColors.oxblood, width: 1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brass,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          textStyle: AppTypography.labelGothic(color: AppColors.brass),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brass,
          foregroundColor: AppColors.obsidian,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          textStyle: AppTypography.labelGothic(color: AppColors.obsidian, fontSize: 13),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.vellumCrypt,
        contentTextStyle: AppTypography.bodyMedium(color: AppColors.vellumInk),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: const BorderSide(color: AppColors.vellumIronLine, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
