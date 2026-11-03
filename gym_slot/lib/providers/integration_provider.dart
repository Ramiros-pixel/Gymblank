import 'package:flutter/material.dart';
import 'package:gym_slot/core/network/api_client.dart';

/// Provider untuk manajemen integrasi Google Drive/Sheets.
class IntegrationProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  bool _isConnecting = false;
  bool _isCreatingSpreadsheet = false;
  Map<String, dynamic>? _connectionStatus;
  String? _authorizationUrl;
  String? _error;

  bool get isConnecting => _isConnecting;
  bool get isCreatingSpreadsheet => _isCreatingSpreadsheet;
  Map<String, dynamic>? get connectionStatus => _connectionStatus;
  String? get authorizationUrl => _authorizationUrl;
  String? get error => _error;
  bool get isConnected => _connectionStatus?['connected'] == true;

  IntegrationProvider(this._apiClient);

  /// Mulai alur OAuth: buat URL autorisasi untuk Owner.
  Future<void> startConnect({required String ownerUserId}) async {
    _isConnecting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.call(
        'integrations.connect',
        {'owner_user_id': ownerUserId},
      );

      if (response['success'] == true) {
        _authorizationUrl = response['data']['authorizationUrl'];
      } else {
        _error = response['error']?['message'] ?? 'Gagal memulai koneksi';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  /// Tangani callback OAuth dari Google.
  Future<void> handleCallback({required String code, required String state}) async {
    _isConnecting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.call(
        'integrations.callback',
        {'code': code, 'state': state},
      );

      if (response['success'] == true) {
        await _refreshStatus();
      } else {
        _error = response['error']?['message'] ?? 'Gagal menyelesaikan koneksi';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  /// Muat status koneksi Google Drive.
  Future<void> loadStatus() async {
    try {
      final response = await _apiClient.call('integrations.status', {});
      if (response['success'] == true) {
        _connectionStatus = response['data'];
      }
    } catch (e) {
      debugPrint('Load integration status error: $e');
    }
    notifyListeners();
  }

  /// Buat spreadsheet gym di Drive Owner.
  Future<Map<String, dynamic>?> createSpreadsheet({
    required String gymId,
    required String ownerUserId,
  }) async {
    _isCreatingSpreadsheet = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.call(
        'integrations.create-spreadsheet',
        {'gym_id': gymId, 'owner_user_id': ownerUserId},
      );

      if (response['success'] == true) {
        await _refreshStatus();
        return response['data'];
      } else {
        _error = response['error']?['message'] ?? 'Gagal membuat spreadsheet';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isCreatingSpreadsheet = false;
      notifyListeners();
    }
    return null;
  }

  /// Putuskan koneksi Google Drive.
  Future<void> disconnect() async {
    _isConnecting = true;
    notifyListeners();

    try {
      await _apiClient.call('integrations.disconnect', {});
      _connectionStatus = {'connected': false, 'status': 'Disconnected'};
    } catch (e) {
      _error = e.toString();
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final response = await _apiClient.call('integrations.status', {});
      if (response['success'] == true) {
        _connectionStatus = response['data'];
      }
    } catch (e) {
      debugPrint('Refresh status error: $e');
    }
  }
}
