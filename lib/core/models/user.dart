class User {
  const User({
    required this.id,
    required this.nickname,
    this.email,
    this.profileImageUrl,
    this.createdAt,
  });

  final int id;
  final String nickname;

  /// 내 정보(`/api/users/me`, 가입·로그인 응답)에만 들어 있습니다.
  final String? email;
  final String? profileImageUrl;
  final DateTime? createdAt;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['id'] as num).toInt(),
        nickname: json['nickname'] as String? ?? '',
        email: json['email'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}

/// 가입·로그인 응답.
class AuthResult {
  const AuthResult({required this.accessToken, required this.user});

  final String accessToken;
  final User user;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json['accessToken'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
}
