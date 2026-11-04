class Booking {
  final String bookingId;
  final String memberId;
  final String scheduleId;
  final String? bookingStatus;
  final String? bookingTime;
  final String? cancelledAt;
  final String? createdAt;
  final String? updatedAt;

  Booking({
    required this.bookingId,
    required this.memberId,
    required this.scheduleId,
    this.bookingStatus,
    this.bookingTime,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'] as String,
      memberId: json['member_id'] as String? ?? '',
      scheduleId: json['schedule_id'] as String? ?? '',
      bookingStatus: json['booking_status'] as String?,
      bookingTime: json['booking_time'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  bool get isActive =>
      bookingStatus == 'Pending' || bookingStatus == 'Confirmed';
}
