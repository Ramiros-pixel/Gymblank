class Schedule {
  final String scheduleId;
  final String facilityId;
  final String? gymId;
  final String scheduleDate;
  final String startTime;
  final String endTime;
  final int capacity;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  Schedule({
    required this.scheduleId,
    required this.facilityId,
    this.gymId,
    required this.scheduleDate,
    required this.startTime,
    required this.endTime,
    this.capacity = 1,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      scheduleId: json['schedule_id'] as String,
      facilityId: json['facility_id'] as String,
      gymId: json['gym_id'] as String?,
      scheduleDate: json['schedule_date'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 1,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schedule_id': scheduleId,
      'facility_id': facilityId,
      'gym_id': gymId,
      'schedule_date': scheduleDate,
      'start_time': startTime,
      'end_time': endTime,
      'capacity': capacity,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
