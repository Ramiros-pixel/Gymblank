import 'package:flutter/material.dart';
import 'package:gym_slot/core/network/api_client.dart';
import 'package:gym_slot/models/gym.dart';

/// Provider untuk manajemen gym.
class GymProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  List<Gym> _gyms = [];
  bool _isLoading = false;

  List<Gym> get gyms => _gyms;
  bool get isLoading => _isLoading;

  GymProvider(this._apiClient);

  /// Muat daftar gym untuk user yang sedang login.
  Future<void> loadGyms() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Get session token from AuthProvider
      final response = await _apiClient.call('gyms.list', {});

      if (response['success'] == true) {
        final List<dynamic> gymsData = response['data']['gyms'] ?? [];
        _gyms = gymsData.map((g) => Gym.fromJson(g)).toList();
      }
    } catch (e) {
      debugPrint('Load gyms error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Buat gym baru.
  Future<Gym?> createGym({
    required String gymName,
    String? address,
    String? phone,
    String? contactEmail,
    String? timezone,
  }) async {
    try {
      final response = await _apiClient.call('gyms.create', {
        'gym_name': gymName,
        'address': address,
        'phone': phone,
        'contact_email': contactEmail,
        'timezone': timezone,
      });

      if (response['success'] == true) {
        final gym = Gym.fromJson(response['data']['gym']);
        _gyms.add(gym);
        notifyListeners();
        return gym;
      }
    } catch (e) {
      debugPrint('Create gym error: $e');
    }
    return null;
  }
}
