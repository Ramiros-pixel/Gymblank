import 'package:flutter/material.dart';
import 'package:gym_slot/core/network/api_client.dart';
import 'package:gym_slot/models/user.dart';

/// Provider untuk manajemen auth state.
/// Menyimpan session token dan user data.
class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  String? _sessionToken;
  User? _user;
  bool _isLoading = false;

  String? get sessionToken => _sessionToken;
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _sessionToken != null;

  AuthProvider(this._apiClient);

  /// Login dengan Google ID token.
  Future<bool> signInWithGoogle(String idToken) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.call(
        'auth.google',
        {},
        idToken: idToken,
      );

      if (response['success'] == true) {
        _sessionToken = response['data']['session_token'];
        _user = User.fromJson(response['data']['user']);
        _saveSession(_sessionToken!);
        return true;
      } else {
        _handleError(response);
        return false;
      }
    } catch (e) {
      debugPrint('SignIn error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login manual untuk development/testing.
  void signInWithUser(User user, String token) {
    _user = user;
    _sessionToken = token;
    notifyListeners();
  }

  /// Logout dan hapus session.
  Future<void> logout() async {
    if (_sessionToken != null) {
      try {
        await _apiClient.call(
          'auth.logout',
          {},
          sessionToken: _sessionToken,
        );
      } catch (e) {
        debugPrint('Logout error: $e');
      }
    }
    _sessionToken = null;
    _user = null;
    _clearSession();
    notifyListeners();
  }

  /// Ambil profil user saat ini.
  Future<User?> me() async {
    if (_sessionToken == null) return null;

    try {
      final response = await _apiClient.call(
        'auth.me',
        {},
        sessionToken: _sessionToken,
      );

      if (response['success'] == true) {
        _user = User.fromJson(response['data']['user']);
        return _user;
      }
    } catch (e) {
      debugPrint('Me error: $e');
      // Session mungkin expired
      await logout();
    }
    return null;
  }

  void _saveSession(String token) {
    // TODO: Implement persistent storage (SharedPreferences)
    debugPrint('Session saved: $token');
  }

  void _clearSession() {
    // TODO: Clear persistent storage
    debugPrint('Session cleared');
  }

  void _handleError(Map<String, dynamic> response) {
    final error = response['error'];
    if (error != null) {
      debugPrint('API Error: ${error['code']} - ${error['message']}');
    }
  }
}
