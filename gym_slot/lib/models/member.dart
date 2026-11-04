class Member {
  final String memberId;
  final String? userId;
  final String? gymId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? joinDate;
  final String? membershipStatus;
  final String? createdAt;
  final String? updatedAt;

  Member({
    required this.memberId,
    this.userId,
    this.gymId,
    required this.fullName,
    this.email,
    this.phone,
    this.joinDate,
    this.membershipStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      memberId: json['member_id'] as String,
      userId: json['user_id'] as String?,
      gymId: json['gym_id'] as String?,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      joinDate: json['join_date'] as String?,
      membershipStatus: json['membership_status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'user_id': userId,
      'gym_id': gymId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'join_date': joinDate,
      'membership_status': membershipStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
