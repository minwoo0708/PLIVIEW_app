/// 연동된 Spotify 계정 정보. 연동 안 했으면 User.spotify가 null입니다.
class SpotifyLink {
  const SpotifyLink({required this.userId, this.displayName});

  final String userId;
  final String? displayName;

  factory SpotifyLink.fromJson(Map<String, dynamic> json) =>
      SpotifyLink(userId: json['userId'] as String, displayName: json['displayName'] as String?);
}

class User {
  const User({
    required this.id,
    required this.nickname,
    this.email,
    this.profileImageUrl,
    this.spotify,
    this.createdAt,
  });

  final int id;
  final String nickname;

  /// 내 정보(`/api/users/me`, 가입·로그인 응답)에만 들어 있습니다.
  final String? email;
  final String? profileImageUrl;

  /// Spotify 연동 정보. 이 값으로 연동 전/후 화면을 나눕니다.
  final SpotifyLink? spotify;
  final DateTime? createdAt;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['id'] as num).toInt(),
        nickname: json['nickname'] as String? ?? '',
        email: json['email'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        spotify: json['spotify'] == null ? null : SpotifyLink.fromJson(json['spotify'] as Map<String, dynamic>),
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
