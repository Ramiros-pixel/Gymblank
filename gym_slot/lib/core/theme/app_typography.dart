import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Skala teks GymSlot. (Lihat desain.md bagian 4.)
/// display/title memakai Barlow Condensed, body/label memakai Inter.
/// Font di-bundle sebagai asset (lihat pubspec.yaml).
class AppTypography {
  static const String _barlow = 'BarlowCondensed';
  static const String _inter = 'Inter';

  /// Membangun TextTheme dari fonts.
  static TextTheme buildTextTheme() {
    const base = TextTheme(
      // Angka statistik besar.
      displayLarge: TextStyle(
        fontFamily: _barlow,
        fontSize: 40,
        height: 44 / 40,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      // Judul layar (huruf kapital di widget).
      headlineLarge: TextStyle(
        fontFamily: _barlow,
        fontSize: 28,
        height: 32 / 28,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      // Judul section.
      headlineMedium: TextStyle(
        fontFamily: _barlow,
        fontSize: 22,
        height: 26 / 22,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
      // Isi utama.
      bodyLarge: TextStyle(
        fontFamily: _inter,
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.normal,
        color: AppColors.black,
      ),
      // Isi sekunder.
      bodyMedium: TextStyle(
        fontFamily: _inter,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.normal,
        color: AppColors.gray700,
      ),
      // Tombol, tab.
      labelLarge: TextStyle(
        fontFamily: _inter,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
      // Chip, caption, last_updated.
      labelSmall: TextStyle(
        fontFamily: _inter,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: AppColors.gray500,
      ),
    );

    return base.apply(
      displayColor: AppColors.black,
      bodyColor: AppColors.black,
    );
  }
}