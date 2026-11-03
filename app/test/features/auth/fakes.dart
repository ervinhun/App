import 'package:app/core/api/api_client.dart';
import 'package:app/core/auth/token_storage.dart';
import 'package:app/features/auth/data/auth_api.dart';
import 'package:app/features/auth/data/google_auth.dart';
import 'package:app/features/auth/domain/auth_user.dart';

const anna = AuthUser(
  id: '00000000-0000-0000-0000-000000000001',
  email: 'anna@example.com',
  displayName: 'Anna',
  locale: 'en',
);

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String accessToken) async => token = accessToken;

  @override
  Future<void> clear() async => token = null;
}

class FakeAuthApi implements AuthApi {
  /// What `me()` returns for a stored token; an [ApiException] is thrown instead.
  Object meResult = anna;

  /// Thrown by every sign-in call when set.
  ApiException? signInError;

  final externalCalls = <({String provider, String idToken, String? name})>[];

  AuthSession _session() {
    if (signInError != null) throw signInError!;
    return const AuthSession(accessToken: 'backend-jwt', user: anna);
  }

  @override
  Future<AuthUser> me() async =>
      meResult is AuthUser ? meResult as AuthUser : throw meResult;

  @override
  Future<AuthSession> login(String email, String password) async => _session();

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  }) async => _session();

  @override
  Future<AuthSession> external({
    required String provider,
    required String idToken,
    String? displayName,
  }) async {
    externalCalls.add((
      provider: provider,
      idToken: idToken,
      name: displayName,
    ));
    return _session();
  }
}

class FakeGoogleAuth implements GoogleAuth {
  /// null simulates the user closing Google's account picker.
  GoogleCredential? credential = const GoogleCredential(
    idToken: 'google-id-token',
    displayName: 'Anna G',
  );
  bool signedOut = false;

  @override
  Future<GoogleCredential?> signIn() async => credential;

  @override
  Future<void> signOut() async => signedOut = true;
}
