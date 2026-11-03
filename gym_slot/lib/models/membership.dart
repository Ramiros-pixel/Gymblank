class Membership {
  final String membershipId;
  final String userId;
  final String gymId;
  final String role;
  final String status;
  final String joinedAt;

  Membership({
    required this.membershipId,
    required this.userId,
    required this.gymId,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      membershipId: json['membership_id'] as String,
      userId: json['user_id'] as String,
      gymId: json['gym_id'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      joinedAt: json['joined_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'membership_id': membershipId,
      'user_id': userId,
      'gym_id': gymId,
      'role': role,
      'status': status,
      'joined_at': joinedAt,
    };
  }
}
