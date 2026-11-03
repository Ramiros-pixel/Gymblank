class User {
  final String userId;
  final String googleSub;
  final String email;
  final String fullName;
  final String? photoUrl;
  final String accountStatus;
  final String createdAt;
  final String updatedAt;

  User({
    required this.userId,
    required this.googleSub,
    required this.email,
    required this.fullName,
    this.photoUrl,
    required this.accountStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as String,
      googleSub: json['google_sub'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      photoUrl: json['photo_url'] as String?,
      accountStatus: json['account_status'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'google_sub': googleSub,
      'email': email,
      'full_name': fullName,
      'photo_url': photoUrl,
      'account_status': accountStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
