import 'package:google_sign_in/google_sign_in.dart';

/// Pembungkus Google Sign-In untuk PoC Phase 0.
///
/// KONFIGURASI: butuh client id yang cocok untuk platform (Android/iOS/Web).
/// Dependency `google_sign_in` ditambahkan di pubspec.yaml.
/// Belum diverifikasi build karena Flutter belum diinstal di host.
class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Meminta login Google dan mengembalikan ID token.
  /// Mengembalikan null jika pengguna membatalkan.
  Future<String?> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null; // dibatalkan
    final auth = await account.authentication;
    return auth.idToken;
  }

  /// Keluar dari Google (untuk logout lokal).
  Future<void> signOut() => _googleSignIn.signOut();
}