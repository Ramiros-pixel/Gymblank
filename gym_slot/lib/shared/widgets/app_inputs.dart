import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Pemetaan error.code backend → pesan manusiawi (desain.md bagian 10).
String messageForError(String? code, String? fallback) {
  switch (code) {
    case 'AUTH_INVALID':
      return 'Identitas tidak valid. Silakan masuk lagi.';
    case 'AUTH_EXPIRED':
      return 'Sesi berakhir. Silakan masuk lagi.';
    case 'PERMISSION_DENIED':
      return 'Kamu tidak punya izin untuk ini.';
    case 'GYM_NOT_FOUND':
      return 'Gym tidak ditemukan.';
    case 'TENANT_ACCESS_DENIED':
      return 'Kamu tidak punya akses ke gym ini.';
    case 'VALIDATION_ERROR':
      return 'Periksa kembali data yang diisi.';
    case 'DUPLICATE_BOOKING':
      return 'Kamu sudah booking slot ini.';
    case 'CAPACITY_FULL':
      return 'Slot ini sudah penuh.';
    case 'GOOGLE_DISCONNECTED':
      return 'Koneksi Google terputus.';
    case 'SHEET_NOT_FOUND':
      return 'Data gym tidak ditemukan. Hubungi pemilik gym.';
    case 'RATE_LIMITED':
      return 'Terlalu banyak permintaan. Tunggu sebentar.';
    case 'INTERNAL_ERROR':
      return 'Terjadi kesalahan. Coba lagi.';
    default:
      return fallback ?? 'Terjadi kesalahan. Coba lagi.';
  }
}

/// Mengambil {code, message} dari respons API standar GymSlot.
({String? code, String? message}) extractError(Map<String, dynamic> response) {
  final err = response['error'];
  if (err is Map) {
    return (
      code: err['code'] as String?,
      message: err['message'] as String?,
    );
  }
  return (code: null, message: null);
}

/// Field teks terpusat (desain.md 6.3):
/// label di atas field, tinggi 52, border gray-200, fokus hitam 2,
/// error border merah + pesan merah + ikon.
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        SizedBox(
          height: AppSpacing.buttonHeight,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 14, color: AppColors.black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.gray500),
              errorText: hasError ? errorText : null,
              suffixIcon: suffix,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusInput),
                borderSide: hasError
                    ? const BorderSide(color: AppColors.red)
                    : const BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusInput),
                borderSide: hasError
                    ? const BorderSide(color: AppColors.red)
                    : const BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusInput),
                borderSide: BorderSide(
                  color: hasError ? AppColors.red : AppColors.black,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Filter chip pill (desain.md 6.4): terpilih isi hitam teks putih,
/// tidak terpilih outline abu.
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.white,
          borderRadius:
              const BorderRadius.all(Radius.circular(AppSpacing.radiusChip)),
          border: Border.all(
            color: selected ? AppColors.black : AppColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.white : AppColors.gray700,
          ),
        ),
      ),
    );
  }
}

/// App bar hitam untuk halaman hero/dashboard (desain.md 6.5).
PreferredSizeWidget gymAppBar({
  required String title,
  List<Widget>? actions,
  Color background = AppColors.black,
  Color foreground = AppColors.white,
}) {
  return AppBar(
    title: Text(
      title.toUpperCase(),
      style: TextStyle(
        fontFamily: 'BarlowCondensed',
        fontSize: 22,
        height: 26 / 22,
        fontWeight: FontWeight.w600,
        color: foreground,
        letterSpacing: 0.5,
      ),
    ),
    backgroundColor: background,
    foregroundColor: foreground,
    elevation: 0,
    centerTitle: false,
    actions: actions,
  );
}

/// App bar putih untuk halaman biasa (desain.md 6.5).
PreferredSizeWidget plainAppBar({
  required String title,
  List<Widget>? actions,
  VoidCallback? onBack,
}) {
  return AppBar(
    title: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'BarlowCondensed',
        fontSize: 22,
        height: 26 / 22,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
        letterSpacing: 0.5,
      ),
    ),
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.black,
    elevation: 0,
    centerTitle: false,
    leading: onBack != null
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
            tooltip: 'Kembali',
          )
        : null,
    actions: actions,
  );
}
