class Gym {
  final String gymId;
  final String gymName;
  final String? address;
  final String? phone;
  final String? contactEmail;
  final String? timezone;
  final String? spreadsheetId;
  final String ownerUserId;
  final String? gymStatus;
  final String createdAt;
  final String updatedAt;
  final String? role;
  final String? membershipStatus;

  Gym({
    required this.gymId,
    required this.gymName,
    this.address,
    this.phone,
    this.contactEmail,
    this.timezone,
    this.spreadsheetId,
    required this.ownerUserId,
    this.gymStatus,
    required this.createdAt,
    required this.updatedAt,
    this.role,
    this.membershipStatus,
  });

  factory Gym.fromJson(Map<String, dynamic> json) {
    return Gym(
      gymId: json['gym_id'] as String,
      gymName: json['gym_name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      timezone: json['timezone'] as String?,
      spreadsheetId: json['spreadsheet_id'] as String?,
      ownerUserId: json['owner_user_id'] as String,
      gymStatus: json['gym_status'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      role: json['role'] as String?,
      membershipStatus: json['membership_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gym_id': gymId,
      'gym_name': gymName,
      'address': address,
      'phone': phone,
      'contact_email': contactEmail,
      'timezone': timezone,
      'spreadsheet_id': spreadsheetId,
      'owner_user_id': ownerUserId,
      'gym_status': gymStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'role': role,
      'membership_status': membershipStatus,
    };
  }
}
