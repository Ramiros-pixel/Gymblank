import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// State layar terpusat (desain.md bagian 10):
/// EmptyState, ErrorState, SkeletonBox.

/// Empty state: ikon sederhana, judul singkat, satu kalimat, satu tombol aksi.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.gray500),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.gray500),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  side: const BorderSide(color: AppColors.black, width: 1.5),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusButton),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state: ikon peringatan, pesan manusiawi, tombol Coba lagi.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 48, color: AppColors.red),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.gray700),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba lagi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  side: const BorderSide(color: AppColors.black, width: 1.5),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusButton),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton abu muda yang mengikuti bentuk konten (bukan spinner layar penuh).
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius radius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: radius,
      ),
    );
  }
}

/// Snackbar berhasil singkat: hitam, ikon centang (desain.md 6.7).
void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppColors.black,
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

/// Snackbar error ringan: latar red-tint dengan ikon peringatan (6.7).
void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppColors.redTint,
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    ),
  );
}
