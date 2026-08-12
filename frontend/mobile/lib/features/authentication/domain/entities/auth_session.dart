import '../entities/user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;
  final User user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresAt: DateTime.tryParse(
        json['accessTokenExpiresAt'] as String? ?? '',
      ),
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? const {}),
    );
  }
}
