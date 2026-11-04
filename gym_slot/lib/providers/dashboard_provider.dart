import 'package:flutter/material.dart';
import 'package:gym_slot/core/network/api_client.dart';

/// Statistik kartu dashboard (PRD 15).
class DashboardStats {
  final int totalMembers;
  final int activeMembers;
  final int bookingsToday;
  final int upcomingBookings;
  final int attendanceToday;
  final int cancelledBookings;
  final String generatedAt;

  DashboardStats({
    required this.totalMembers,
    required this.activeMembers,
    required this.bookingsToday,
    required this.upcomingBookings,
    required this.attendanceToday,
    required this.cancelledBookings,
    required this.generatedAt,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalMembers: (json['total_members'] as num?)?.toInt() ?? 0,
      activeMembers: (json['active_members'] as num?)?.toInt() ?? 0,
      bookingsToday: (json['bookings_today'] as num?)?.toInt() ?? 0,
      upcomingBookings: (json['upcoming_bookings'] as num?)?.toInt() ?? 0,
      attendanceToday: (json['attendance_today'] as num?)?.toInt() ?? 0,
      cancelledBookings: (json['cancelled_bookings'] as num?)?.toInt() ?? 0,
      generatedAt: json['generated_at'] as String? ?? '',
    );
  }
}

/// Satu titik data tren (tanggal → jumlah).
class TrendPoint {
  final String date;
  final int count;

  TrendPoint({required this.date, required this.count});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Data grafik dashboard (PRD 8.1).
class DashboardCharts {
  final String range;
  final String startDate;
  final String endDate;
  final List<TrendPoint> bookingTrend;
  final List<TrendPoint> attendanceTrend;
  final Map<String, int> bookingStatus;
  final List<Map<String, dynamic>> popularFacilities;
  final List<Map<String, dynamic>> busyHours;
  final String generatedAt;

  DashboardCharts({
    required this.range,
    required this.startDate,
    required this.endDate,
    required this.bookingTrend,
    required this.attendanceTrend,
    required this.bookingStatus,
    required this.popularFacilities,
    required this.busyHours,
    required this.generatedAt,
  });

  factory DashboardCharts.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['booking_status'] as Map<dynamic, dynamic>? ?? {};
    return DashboardCharts(
      range: json['range'] as String? ?? '7d',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      bookingTrend: (json['booking_trend'] as List<dynamic>? ?? [])
          .map((e) => TrendPoint.fromJson(e))
          .toList(),
      attendanceTrend: (json['attendance_trend'] as List<dynamic>? ?? [])
          .map((e) => TrendPoint.fromJson(e))
          .toList(),
      bookingStatus:
          statusRaw.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
      popularFacilities:
          (json['popular_facilities'] as List<dynamic>? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
      busyHours: (json['busy_hours'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      generatedAt: json['generated_at'] as String? ?? '',
    );
  }
}

/// Provider dashboard statistik & grafik (Phase 5).
class DashboardProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  DashboardProvider(this._apiClient);

  DashboardStats? _stats;
  DashboardCharts? _charts;
  bool _isLoading = false;
  bool _hasError = false;
  String _range = '7d';

  DashboardStats? get stats => _stats;
  DashboardCharts? get charts => _charts;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get range => _range;

  /// Waktu pembaruan terakhir (dari stats, fallback charts).
  String get lastUpdated => _stats?.generatedAt ?? '';

  /// Muat statistik + grafik untuk gym.
  /// [range]: 'today' | '7d' | '30d' | 'custom'.
  Future<void> load({
    required String gymId,
    String range = '7d',
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _hasError = false;
    _range = range;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiClient.call('dashboard.stats', {'gym_id': gymId}),
        _apiClient.call('dashboard.charts', {
          'gym_id': gymId,
          'range': range,
          'start_date': ?startDate,
          'end_date': ?endDate,
        }),
      ]);

      final statsRes = results[0];
      final chartsRes = results[1];

      if (statsRes['success'] == true) {
        _stats = DashboardStats.fromJson(statsRes['data']['stats']);
      } else {
        _hasError = true;
      }

      if (chartsRes['success'] == true) {
        _charts = DashboardCharts.fromJson(chartsRes['data']['charts']);
      } else {
        _hasError = true;
      }
    } catch (e) {
      debugPrint('Dashboard load exception: $e');
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
