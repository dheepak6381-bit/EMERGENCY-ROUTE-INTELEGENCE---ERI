import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_palette.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgScaffold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentBlue,
        secondary: AppColors.accentCyan,
        surface: AppColors.bgPanel,
        error: AppColors.statusRed,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.bgScaffold,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.inter(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDefault,
        thickness: 1,
        space: 0,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 18,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDefault),
        ),
        textStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 12,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textTertiary,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}
