import 'package:flutter/material.dart';
import 'package:gym_slot/core/network/api_client.dart';
import 'package:gym_slot/features/authentication/presentation/login_screen.dart';
import 'package:gym_slot/features/home/presentation/home_screen.dart';
import 'package:gym_slot/providers/auth_provider.dart';
import 'package:gym_slot/providers/gym_provider.dart';
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
      ],
      child: MaterialApp(
        title: 'GymSlot',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB71C1C)),
        ),
        home: const AuthWrapper(),
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

// Instance API client global (konfigurasi dari --dart-define di main.dart asli,
// di sini menggunakan placeholder untuk kompilasi).
final apiClient = ApiClient('https://example.com');
