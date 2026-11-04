class Attendance {
  final String attendanceId;
  final String memberId;
  final String? bookingId;
  final String? checkInAt;
  final String? attendanceMethod;
  final String? deviceId;
  final String? createdBy;
  final String? createdAt;

  Attendance({
    required this.attendanceId,
    required this.memberId,
    this.bookingId,
    this.checkInAt,
    this.attendanceMethod,
    this.deviceId,
    this.createdBy,
    this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      attendanceId: json['attendance_id'] as String,
      memberId: json['member_id'] as String? ?? '',
      bookingId: json['booking_id'] as String?,
      checkInAt: json['check_in_at'] as String?,
      attendanceMethod: json['attendance_method'] as String?,
      deviceId: json['device_id'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
