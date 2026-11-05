import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Kartu standar GymSlot (desain.md 6.2):
/// putih, border gray-200, radius 16, padding 16 — tanpa bayangan tebal.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.gray200),
      ),
      child: child,
    );

    if (onTap == null) return body;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppSpacing.radiusCard), child: body);
  }
}

/// Kartu hero hitam: teks putih, satu aksen merah (garis tipis 4px di kiri).
class HeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const HeroCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusCard)),
      ),
      child: child,
    );
  }
}

/// Kartu statistik: angka display (Barlow Condensed 40), label kecil,
/// ikon kecil di kanan atas (desain.md 6.2).
class StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: AppColors.gray500),
            ],
          ),
          const Spacer(),
          Text(
            '$value',
            style: const TextStyle(
              fontFamily: 'BarlowCondensed',
              fontSize: 34,
              height: 38 / 34,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner status gym (desain.md 3.4): Pending abu, Suspended hitam,
/// Disconnected merah solid, SetupFailed red-tint.
class GymBanner extends StatelessWidget {
  final String status;
  final VoidCallback? onRetry;

  const GymBanner({super.key, required this.status, this.onRetry});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'Active':
        return const SizedBox.shrink();
      case 'Pending':
        return _banner(
          bg: AppColors.gray50,
          textColor: AppColors.gray700,
          icon: Icons.schedule,
          message: 'Gym sedang disiapkan',
        );
      case 'Suspended':
        return _banner(
          bg: AppColors.black,
          textColor: AppColors.white,
          icon: Icons.block,
          message: 'Gym ditangguhkan. Hubungi pengelola platform.',
        );
      case 'Disconnected':
        return _banner(
          bg: AppColors.red,
          textColor: AppColors.white,
          icon: Icons.cloud_off,
          message: 'Koneksi Google terputus. Hubungkan kembali.',
          actionLabel: onRetry != null ? 'Hubungkan kembali' : null,
          onAction: onRetry,
        );
      case 'SetupFailed':
        return _banner(
          bg: AppColors.redTint,
          textColor: AppColors.red,
          icon: Icons.error_outline,
          message: 'Penyiapan gagal. Coba lagi.',
          actionLabel: onRetry != null ? 'Coba lagi' : null,
          onAction: onRetry,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _banner({
    required Color bg,
    required Color textColor,
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: textColor),
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}
