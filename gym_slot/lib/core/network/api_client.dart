import 'dart:convert';

import 'package:http/http.dart' as http;

/// Konfigurasi API GymSlot. Dibaca dari --dart-define agar tidak hardcode.
/// Tidak ada secret di sini.
class ApiConfig {
  /// URL Web App Apps Script GymSlot.
  /// Set lewat: flutter run --dart-define=GYMSLOT_API_URL=https://script.google.com/...
  static const String apiUrl = String.fromEnvironment('GYMSLOT_API_URL');

  /// OAuth Client ID Google untuk login.
  /// Set lewat: flutter run --dart-define=GYMSLOT_GOOGLE_CLIENT_ID=...
  static const String googleClientId =
      String.fromEnvironment('GYMSLOT_GOOGLE_CLIENT_ID');

  static bool get isConfigured =>
      apiUrl.isNotEmpty && googleClientId.isNotEmpty;
}

/// Client HTTP ke backend GymSlot (Apps Script).
/// Semua request lewat sini. Token dibawa di body (bukan header),
/// sesuai keterbatasan Apps Script.
class ApiClient {
  final String baseUrl;

  ApiClient(this.baseUrl);

  /// Mengirim action ke backend dan mengembalikan respons JSON.
  Future<Map<String, dynamic>> call(
    String action,
    Map<String, dynamic> payload,
    {String? sessionToken, String? idToken}) async {
    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final body = <String, dynamic>{
      'action': action,
      'version': 'v1',
      'request_id': requestId,
      'payload': payload,
      'auth': <String, dynamic>{
        'session_token': sessionToken,
        'id_token': idToken,
      },
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
