import 'package:flutter/material.dart';
import 'package:gym_slot/core/theme/app_colors.dart';
import 'package:gym_slot/core/theme/app_spacing.dart';
import 'package:gym_slot/models/user.dart';
import 'package:gym_slot/providers/auth_provider.dart';
import 'package:gym_slot/shared/widgets/app_states.dart';
import 'package:provider/provider.dart';

/// Layar login GymSlot (desain.md 8.2).
/// Latar hitam penuh, logo putih dengan aksen merah, satu tombol merah.
/// Loading: tombol berubah state loading. Gagal: snackbar.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _signIn() async {
    if (_loading) return; // anti double tap (desain.md 14.5)
    setState(() => _loading = true);

    try {
      // TODO: Implement actual Google Sign-In
      // For now, simulate login
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock login for development
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        authProvider.signInWithUser(
          User(
            userId: 'demo-user-123',
            googleSub: 'google-sub-123',
            email: 'demo@example.com',
            fullName: 'Demo User',
            accountStatus: 'Active',
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-01T00:00:00Z',
          ),
          'demo-token',
        );
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, 'Gagal masuk. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo: kotak merah dengan "G" putih + nama produk.
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusButton),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'G',
                    style: TextStyle(
                      fontFamily: 'BarlowCondensed',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Judul layar: Barlow Condensed kapital (desain.md 4).
              const Text(
                'GYMSLOT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontSize: 40,
                  height: 44 / 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Booking slot gym.\nTanpa antre. Tanpa ribet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.gray500,
                ),
              ),
              const Spacer(),
              // Tombol utama merah (desain.md 6.1 primary).
              SizedBox(
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _loading ? AppColors.redDark : AppColors.red,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.redDark,
                    disabledForegroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusButton),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white),
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.g_mobiledata, size: 26),
                            SizedBox(width: AppSpacing.xxs),
                            Text(
                              'Masuk dengan Google',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Dengan masuk, kamu setuju dengan Syarat & Privasi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
