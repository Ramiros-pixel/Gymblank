import 'package:flutter/material.dart';
import 'package:gym_slot/core/network/api_client.dart';
import 'package:gym_slot/features/authentication/presentation/login_screen.dart';
import 'package:gym_slot/features/home/presentation/home_screen.dart';
import 'package:gym_slot/features/onboarding/presentation/register_gym_screen.dart';
import 'package:gym_slot/providers/auth_provider.dart';
import 'package:gym_slot/providers/booking_provider.dart';
import 'package:gym_slot/providers/dashboard_provider.dart';
import 'package:gym_slot/providers/gym_provider.dart';
import 'package:gym_slot/providers/integration_provider.dart';
import 'package:gym_slot/providers/management_provider.dart';
import 'package:provider/provider.dart';

/// Entri utama aplikasi GymSlot.
/// Mengatur MultiProvider dan AuthWrapper.
void main() {
  runApp(const GymSlotApp());
}

class GymSlotApp extends StatelessWidget {
  const GymSlotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => GymProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => IntegrationProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ManagementProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => BookingProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(apiClient)),
      ],
      child: MaterialApp(
        title: 'GymSlot',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB71C1C)),
        ),
        home: const AuthWrapper(),
        routes: {
          '/register-gym': (context) => const RegisterGymScreen(),
        },
      ),
    );
  }
}

/// AuthWrapper menampilkan LoginScreen jika belum login,
/// atau HomeScreen jika sudah login.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isAuthenticated) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

/// Instance API client global (konfigurasi dari --dart-define).
final String _apiUrl = String.fromEnvironment('GYMSLOT_API_URL', defaultValue: '');
final apiClient = ApiClient(_apiUrl.isEmpty ? 'https://example.com' : _apiUrl);
