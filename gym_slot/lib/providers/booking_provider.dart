import 'package:flutter/material.dart';
import 'package:gym_slot/core/network/api_client.dart';
import 'package:gym_slot/models/attendance.dart';
import 'package:gym_slot/models/booking.dart';

/// Provider booking, kehadiran, dan pengaturan gym (Phase 4).
class BookingProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  BookingProvider(this._apiClient);

  // ---------- Bookings ----------

  List<Booking> _bookings = [];
  List<Booking> get bookings => _bookings;

  String? _lastError;
  String? get lastError => _lastError;

  void _setError(Map<String, dynamic> response) {
    final err = response['error'];
    if (err is Map) {
      _lastError = err['message'] as String? ?? err['code'] as String?;
    } else {
      _lastError = null;
    }
  }

  /// Muat semua booking (staff).
  Future<void> loadBookings(String gymId) async {
    try {
      final response =
          await _apiClient.call('bookings.list', {'gym_id': gymId});
      if (response['success'] == true) {
        final list = response['data']['bookings'] as List<dynamic>? ?? [];
        _bookings = list.map((e) => Booking.fromJson(e)).toList();
        _lastError = null;
      } else {
        _setError(response);
      }
    } catch (e) {
      debugPrint('loadBookings exception: $e');
    }
    notifyListeners();
  }

  /// Muat booking milik member yang sedang login.
  Future<void> loadMyBookings(String gymId) async {
    try {
      final response = await _apiClient.call('bookings.my', {'gym_id': gymId});
      if (response['success'] == true) {
        final list = response['data']['bookings'] as List<dynamic>? ?? [];
        _bookings = list.map((e) => Booking.fromJson(e)).toList();
        _lastError = null;
      } else {
        _setError(response);
      }
    } catch (e) {
      debugPrint('loadMyBookings exception: $e');
    }
    notifyListeners();
  }

  /// Buat booking. Mengembalikan error message via lastError jika gagal
  /// (mis. CAPACITY_FULL, DUPLICATE_BOOKING).
  Future<Booking?> createBooking({
    required String gymId,
    required String memberId,
    required String scheduleId,
  }) async {
    _lastError = null;
    try {
      final response = await _apiClient.call('bookings.create', {
        'gym_id': gymId,
        'member_id': memberId,
        'schedule_id': scheduleId,
      });
      if (response['success'] == true) {
        final booking = Booking.fromJson(response['data']['booking']);
        _bookings.add(booking);
        notifyListeners();
        return booking;
      }
      _setError(response);
    } catch (e) {
      debugPrint('createBooking exception: $e');
      _lastError = e.toString();
    }
    notifyListeners();
    return null;
  }

  /// Batalkan booking.
  Future<bool> cancelBooking({
    required String gymId,
    required String bookingId,
  }) async {
    _lastError = null;
    try {
      final response = await _apiClient.call('bookings.cancel', {
        'gym_id': gymId,
        'booking_id': bookingId,
      });
      if (response['success'] == true) {
        final updated = Booking.fromJson(response['data']['booking']);
        final idx = _bookings.indexWhere((b) => b.bookingId == bookingId);
        if (idx >= 0) _bookings[idx] = updated;
        notifyListeners();
        return true;
      }
      _setError(response);
    } catch (e) {
      debugPrint('cancelBooking exception: $e');
      _lastError = e.toString();
    }
    notifyListeners();
    return false;
  }

  // ---------- Attendance ----------

  List<Attendance> _attendance = [];
  List<Attendance> get attendance => _attendance;

  /// Muat daftar kehadiran (staff).
  Future<void> loadAttendance(String gymId) async {
    try {
      final response =
          await _apiClient.call('attendance.list', {'gym_id': gymId});
      if (response['success'] == true) {
        final list = response['data']['attendance'] as List<dynamic>? ?? [];
        _attendance = list.map((e) => Attendance.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('loadAttendance exception: $e');
    }
    notifyListeners();
  }

  /// Check-in manual.
  Future<Attendance?> checkIn({
    required String gymId,
    required String memberId,
    String? bookingId,
    String method = 'manual',
  }) async {
    _lastError = null;
    try {
      final response = await _apiClient.call('attendance.checkin', {
        'gym_id': gymId,
        'member_id': memberId,
        if (bookingId != null && bookingId.isNotEmpty) 'booking_id': bookingId,
        'attendance_method': method,
      });
      if (response['success'] == true) {
        final att = Attendance.fromJson(response['data']['attendance']);
        _attendance.add(att);
        notifyListeners();
        return att;
      }
      _setError(response);
    } catch (e) {
      debugPrint('checkIn exception: $e');
      _lastError = e.toString();
    }
    notifyListeners();
    return null;
  }

  // ---------- Gym Settings ----------

  Map<String, String> _settings = {};
  Map<String, String> get settings => _settings;

  /// Muat pengaturan gym.
  Future<void> loadSettings(String gymId) async {
    try {
      final response =
          await _apiClient.call('settings.get', {'gym_id': gymId});
      if (response['success'] == true) {
        final raw = response['data']['settings'] as Map<dynamic, dynamic>? ?? {};
        _settings = raw.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (e) {
      debugPrint('loadSettings exception: $e');
    }
    notifyListeners();
  }

  /// Perbarui pengaturan gym (owner only di backend).
  Future<bool> updateSettings({
    required String gymId,
    required Map<String, String> updates,
  }) async {
    _lastError = null;
    try {
      final response = await _apiClient.call('settings.update', {
        'gym_id': gymId,
        'settings': updates,
      });
      if (response['success'] == true) {
        final raw = response['data']['settings'] as Map<dynamic, dynamic>? ?? {};
        _settings = raw.map((k, v) => MapEntry(k.toString(), v.toString()));
        notifyListeners();
        return true;
      }
      _setError(response);
    } catch (e) {
      debugPrint('updateSettings exception: $e');
      _lastError = e.toString();
    }
    notifyListeners();
    return false;
  }
}
