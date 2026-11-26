class AuthUser {
  const AuthUser({
    required this.userId,
    required this.name,
    required this.email,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['user_id'] as int,
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
    );
  }

  final int userId;
  final String name;
  final String email;
}
