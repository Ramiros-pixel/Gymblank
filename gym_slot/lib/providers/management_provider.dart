import 'package:flutter/material.dart';
import 'package:gym_slot/core/network/api_client.dart';
import 'package:gym_slot/models/facility.dart';
import 'package:gym_slot/models/member.dart';
import 'package:gym_slot/models/schedule.dart';

/// Provider gabungan untuk manajemen anggota, fasilitas, dan jadwal (Phase 3).
class ManagementProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  ManagementProvider(this._apiClient);

  // ---------- Members ----------

  List<Member> _members = [];
  List<Member> get members => _members;

  /// Muat daftar anggota gym.
  Future<void> loadMembers(String gymId) async {
    try {
      final response = await _apiClient.call('members.list', {'gym_id': gymId});
      if (response['success'] == true) {
        final list = response['data']['members'] as List<dynamic>? ?? [];
        _members = list.map((e) => Member.fromJson(e)).toList();
      } else {
        debugPrint('loadMembers error: ${response['error']}');
      }
    } catch (e) {
      debugPrint('loadMembers exception: $e');
    }
    notifyListeners();
  }

  /// Tambah anggota baru.
  Future<Member?> createMember({
    required String gymId,
    required String userId,
    required String fullName,
    String? email,
    String? phone,
  }) async {
    try {
      final response = await _apiClient.call('members.create', {
        'gym_id': gymId,
        'user_id': userId,
        'full_name': fullName,
        'email': email,
        'phone': phone,
      });
      if (response['success'] == true) {
        final member = Member.fromJson(response['data']['member']);
        _members.add(member);
        notifyListeners();
        return member;
      } else {
        debugPrint('createMember error: ${response['error']}');
      }
    } catch (e) {
      debugPrint('createMember exception: $e');
    }
    return null;
  }

  /// Perbarui data anggota.
  Future<Member?> updateMember({
    required String memberId,
    String? fullName,
    String? email,
    String? phone,
    String? membershipStatus,
  }) async {
    try {
      final response = await _apiClient.call('members.update', {
        'member_id': memberId,
        'full_name': ?fullName,
        'email': ?email,
        'phone': ?phone,
        'membership_status': ?membershipStatus,
      });
      if (response['success'] == true) {
        final member = Member.fromJson(response['data']['member']);
        final idx = _members.indexWhere((m) => m.memberId == memberId);
        if (idx >= 0) _members[idx] = member;
        notifyListeners();
        return member;
      } else {
        debugPrint('updateMember error: ${response['error']}');
      }
    } catch (e) {
      debugPrint('updateMember exception: $e');
    }
    return null;
  }

  /// Nonaktifkan anggota.
  Future<void> deactivateMember(String memberId) async {
    try {
      final response = await _apiClient.call('members.deactivate', {
        'member_id': memberId,
      });
      if (response['success'] == true) {
        final idx = _members.indexWhere((m) => m.memberId == memberId);
        if (idx >= 0) {
          _members[idx] = Member.fromJson(response['data']['member']);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('deactivateMember exception: $e');
    }
  }

  // ---------- Facilities ----------

  List<Facility> _facilities = [];
  List<Facility> get facilities => _facilities;

  /// Muat daftar fasilitas gym.
  Future<void> loadFacilities(String gymId) async {
    try {
      final response =
          await _apiClient.call('facilities.list', {'gym_id': gymId});
      if (response['success'] == true) {
        final list = response['data']['facilities'] as List<dynamic>? ?? [];
        _facilities = list.map((e) => Facility.fromJson(e)).toList();
      } else {
        debugPrint('loadFacilities error: ${response['error']}');
      }
    } catch (e) {
      debugPrint('loadFacilities exception: $e');
    }
    notifyListeners();
  }

  /// Tambah fasilitas baru.
  Future<Facility?> createFacility({
    required String gymId,
    required String facilityName,
    String? description,
    int capacity = 1,
  }) async {
    try {
      final response = await _apiClient.call('facilities.create', {
        'gym_id': gymId,
        'facility_name': facilityName,
        'description': description,
        'capacity': capacity,
      });
      if (response['success'] == true) {
        final facility = Facility.fromJson(response['data']['facility']);
        _facilities.add(facility);
        notifyListeners();
        return facility;
      } else {
        debugPrint('createFacility error: ${response['error']}');
      }
    } catch (e) {
      debugPrint('createFacility exception: $e');
    }
    return null;
  }

  /// Perbarui fasilitas.
  Future<Facility?> updateFacility({
    required String facilityId,
    String? facilityName,
    String? description,
    int? capacity,
    String? status,
  }) async {
    try {
      final response = await _apiClient.call('facilities.update', {
        'facility_id': facilityId,
        'facility_name': ?facilityName,
        'description': ?description,
        'capacity': ?capacity,
        'status': ?status,
      });
      if (response['success'] == true) {
        final facility = Facility.fromJson(response['data']['facility']);
        final idx = _facilities.indexWhere((f) => f.facilityId == facilityId);
        if (idx >= 0) _facilities[idx] = facility;
        notifyListeners();
        return facility;
      } else {
        debugPrint('updateFacility error: ${response['error']}');
      }
    } catch (e) {
      debugPrint('updateFacility exception: $e');
    }
    return null;
  }

  /// Nonaktifkan fasilitas.
  Future<void> deactivateFacility(String facilityId) async {
    try {
      final response = await _apiClient.call('facilities.deactivate', {
        'facility_id': facilityId,
      });
      if (response['success'] == true) {
        final idx = _facilities.indexWhere((f) => f.facilityId == facilityId);
        if (idx >= 0) {
          _facilities[idx] = Facility.fromJson(response['data']['facility']);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('deactivateFacility exception: $e');
    }
  }

  // ---------- Schedules ----------

  List<Schedule> _schedules = [];
  List<Schedule> get schedules => _schedules;

  /// Muat daftar jadwal gym.
  Future<void> loadSchedules(String gymId) async {
    try {
      final response =
          await _apiClient.call('schedules.list', {'gym_id': gymId});
      if (response['success'] == true) {
        final list = response['data']['schedules'] as List<dynamic>? ?? [];
        _schedules = list.map((e) => Schedule.fromJson(e)).toList();
      } else {
        debugPrint('loadSchedules error: ${response['error']}');
      }
    } catch (e) {
      debugPrint('loadSchedules exception: $e');
    }
    notifyListeners();
  }

  /// Buat jadwal baru.
  Future<Schedule?> createSchedule({
    required String gymId,
    required String facilityId,
    required String scheduleDate,
    required String startTime,
    required String endTime,
    int capacity = 1,
  }) async {
    try {
      final response = await _apiClient.call('schedules.create', {
        'gym_id': gymId,
        'facility_id': facilityId,
        'schedule_date': scheduleDate,
        'start_time': startTime,
        'end_time': endTime,
        'capacity': capacity,
      });
      if (response['success'] == true) {
        final schedule = Schedule.fromJson(response['data']['schedule']);
        _schedules.add(schedule);
        notifyListeners();
        return schedule;
      } else {
        debugPrint('createSchedule error: ${response['error']}');
      }
    } catch (e) {
      debugPrint('createSchedule exception: $e');
    }
    return null;
  }

  /// Perbarui jadwal.
  Future<Schedule?> updateSchedule({
    required String scheduleId,
    String? scheduleDate,
    String? startTime,
    String? endTime,
    int? capacity,
    String? status,
  }) async {
    try {
      final response = await _apiClient.call('schedules.update', {
        'schedule_id': scheduleId,
        'schedule_date': ?scheduleDate,
        'start_time': ?startTime,
        'end_time': ?endTime,
        'capacity': ?capacity,
        'status': ?status,
      });
      if (response['success'] == true) {
        final schedule = Schedule.fromJson(response['data']['schedule']);
        final idx = _schedules.indexWhere((s) => s.scheduleId == scheduleId);
        if (idx >= 0) _schedules[idx] = schedule;
        notifyListeners();
        return schedule;
      } else {
        debugPrint('updateSchedule error: ${response['error']}');
      }
    } catch (e) {
      debugPrint('updateSchedule exception: $e');
    }
    return null;
  }

  /// Nonaktifkan jadwal.
  Future<void> deactivateSchedule(String scheduleId) async {
    try {
      final response = await _apiClient.call('schedules.deactivate', {
        'schedule_id': scheduleId,
      });
      if (response['success'] == true) {
        final idx = _schedules.indexWhere((s) => s.scheduleId == scheduleId);
        if (idx >= 0) {
          _schedules[idx] = Schedule.fromJson(response['data']['schedule']);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('deactivateSchedule exception: $e');
    }
  }
}
