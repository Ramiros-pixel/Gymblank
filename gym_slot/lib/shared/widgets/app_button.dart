import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Varian tombol GymSlot (desain.md 6.1).
enum AppButtonVariant { primary, secondary, outline, text, danger }

/// Tombol terpusat dengan state loading & anti double-tap.
/// - primary: isi merah, teks putih (satu aksi utama per layar)
/// - secondary: isi hitam, teks putih
/// - outline: border hitam 1.5, teks hitam
/// - text: teks hitam bergaris bawah halus
/// - danger: outline merah, teks merah
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
  });

  bool get _disabled => onPressed == null || loading;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(context);

    Widget child;
    if (loading) {
      child = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
        ),
      );
    } else {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label),
        ],
      );
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: _disabled ? null : onPressed,
          style: style,
          child: child,
        );
      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: _disabled ? null : onPressed,
          style: style,
          child: child,
        );
      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: _disabled ? null : onPressed,
          style: style,
          child: child,
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: _disabled ? null : onPressed,
          style: style,
          child: child,
        );
      case AppButtonVariant.danger:
        return OutlinedButton(
          onPressed: _disabled ? null : onPressed,
          style: style,
          child: child,
        );
    }
  }

  ButtonStyle _styleFor(BuildContext context) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusButton)),
    );
    const minSize = Size.fromHeight(AppSpacing.buttonHeight);

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray200,
          disabledForegroundColor: AppColors.gray500,
          minimumSize: minSize,
          shape: shape,
        );
      case AppButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray200,
          disabledForegroundColor: AppColors.gray500,
          minimumSize: minSize,
          shape: shape,
        );
      case AppButtonVariant.outline:
        return OutlinedButton.styleFrom(
          foregroundColor: AppColors.black,
          disabledForegroundColor: AppColors.gray500,
          side: const BorderSide(
              color: AppColors.black, width: 1.5),
          minimumSize: minSize,
          shape: shape,
        );
      case AppButtonVariant.text:
        return TextButton.styleFrom(
          foregroundColor: AppColors.black,
          minimumSize: minSize,
          shape: shape,
        );
      case AppButtonVariant.danger:
        return OutlinedButton.styleFrom(
          foregroundColor: AppColors.red,
          disabledForegroundColor: AppColors.gray500,
          side: const BorderSide(color: AppColors.red, width: 1.5),
          minimumSize: minSize,
          shape: shape,
        );
    }
  }
}
