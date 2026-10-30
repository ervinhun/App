/// The signed-in user, as returned by the backend's `UserDto`.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.locale,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String,
    locale: json['locale'] as String,
  );

  final String id;
  final String email;
  final String displayName;
  final String locale;
}

/// The backend's `AuthResponse`: our own access token plus the user it belongs to.
class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken'] as String,
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
  );

  final String accessToken;
  final AuthUser user;
}
