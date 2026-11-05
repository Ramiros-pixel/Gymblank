import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Chip status booking sesuai desain.md 3.4.
/// Status dibedakan lewat bentuk chip + ikon + label (bukan warna saja).
enum StatusChipStyle {
  // Booking.
  pending,
  confirmed,
  completed,
  cancelled,
  rejected,
  // Umum (anggota, fasilitas, jadwal).
  active,
  inactive,
  maintenance,
}

/// Chip status terpusat: outline abu (pending), isi hitam (confirmed),
/// isi gray-200 (completed), outline merah (cancelled), isi red-tint (rejected).
class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipStyle style;

  const StatusChip({super.key, required this.label, required this.style});

  /// Pemetaan status string backend → style.
  static StatusChipStyle styleFor(String? status) {
    switch (status) {
      case 'Pending':
        return StatusChipStyle.pending;
      case 'Confirmed':
        return StatusChipStyle.confirmed;
      case 'Completed':
        return StatusChipStyle.completed;
      case 'Cancelled':
        return StatusChipStyle.cancelled;
      case 'Rejected':
        return StatusChipStyle.rejected;
      case 'Active':
        return StatusChipStyle.active;
      case 'Inactive':
        return StatusChipStyle.inactive;
      case 'Maintenance':
        return StatusChipStyle.maintenance;
      default:
        return StatusChipStyle.inactive;
    }
  }

  IconData get _icon {
    switch (style) {
      case StatusChipStyle.pending:
        return Icons.schedule;
      case StatusChipStyle.confirmed:
      case StatusChipStyle.active:
        return Icons.check;
      case StatusChipStyle.completed:
        return Icons.done_all;
      case StatusChipStyle.cancelled:
        return Icons.close;
      case StatusChipStyle.rejected:
        return Icons.block;
      case StatusChipStyle.inactive:
        return Icons.remove_circle_outline;
      case StatusChipStyle.maintenance:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(AppSpacing.radiusChip));

    switch (style) {
      case StatusChipStyle.pending:
        return _chip(
          iconColor: AppColors.gray700,
          textColor: AppColors.gray700,
          bg: AppColors.white,
          border: Border.all(color: AppColors.gray200),
          radius: radius,
        );
      case StatusChipStyle.confirmed:
      case StatusChipStyle.active:
        return _chip(
          iconColor: AppColors.white,
          textColor: AppColors.white,
          bg: AppColors.black,
          radius: radius,
        );
      case StatusChipStyle.completed:
        return _chip(
          iconColor: AppColors.gray700,
          textColor: AppColors.gray700,
          bg: AppColors.gray200,
          radius: radius,
        );
      case StatusChipStyle.cancelled:
        return _chip(
          iconColor: AppColors.red,
          textColor: AppColors.red,
          bg: AppColors.white,
          border: Border.all(color: AppColors.red),
          radius: radius,
        );
      case StatusChipStyle.rejected:
      case StatusChipStyle.maintenance:
        return _chip(
          iconColor: AppColors.red,
          textColor: AppColors.red,
          bg: AppColors.redTint,
          radius: radius,
        );
      case StatusChipStyle.inactive:
        return _chip(
          iconColor: AppColors.gray700,
          textColor: AppColors.gray700,
          bg: AppColors.gray50,
          radius: radius,
        );
    }
  }

  Widget _chip({
    required Color iconColor,
    required Color textColor,
    required Color bg,
    Border? border,
    required BorderRadius radius,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: radius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
