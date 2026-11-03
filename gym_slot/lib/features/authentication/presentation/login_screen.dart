import 'package:flutter/material.dart';
import 'package:gym_slot/core/theme/app_colors.dart';
import 'package:gym_slot/core/theme/app_spacing.dart';
import 'package:gym_slot/models/user.dart';
import 'package:gym_slot/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Layar login GymSlot. (Lihat desain.md 8.2.)
/// Latar hitam penuh, logo putih dengan aksen merah, satu tombol utama merah.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _signIn() async {
    if (_loading) return;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
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
              // Logo dan tagline.
              const Text(
                'GYMSLOT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontSize: 40,
                  height: 44 / 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Booking slot gym.\nTanpa antre. Tanpa ribet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray500,
                    ),
              ),
              const Spacer(),
              // Tombol utama masuk dengan Google.
              ElevatedButton.icon(
                onPressed: _loading ? null : _signIn,
                icon: const Icon(Icons.g_mobiledata, color: AppColors.white),
                label: Text(
                  _loading ? 'Memproses...' : 'Masuk dengan Google',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Dengan masuk, kamu setuju dengan Syarat & Privasi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
