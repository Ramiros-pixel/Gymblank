class Facility {
  final String facilityId;
  final String? gymId;
  final String facilityName;
  final String? description;
  final int capacity;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  Facility({
    required this.facilityId,
    this.gymId,
    required this.facilityName,
    this.description,
    this.capacity = 1,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      facilityId: json['facility_id'] as String,
      gymId: json['gym_id'] as String?,
      facilityName: json['facility_name'] as String? ?? '',
      description: json['description'] as String?,
      capacity: (json['capacity'] as num?)?.toInt() ?? 1,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facility_id': facilityId,
      'gym_id': gymId,
      'facility_name': facilityName,
      'description': description,
      'capacity': capacity,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
