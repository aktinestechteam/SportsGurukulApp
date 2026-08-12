import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../models/auth_requests.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _api = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/login',
      body: LoginRequest(email: email, password: password).toJson(),
    );
    return AuthSession.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
    required String confirmPassword,
    required bool acceptTerms,
  }) async {
    await _api.post(
      '/auth/register',
      body: RegisterRequest(
        firstName: firstName,
        lastName: lastName,
        email: email,
        mobileNumber: mobileNumber,
        password: password,
        confirmPassword: confirmPassword,
        acceptTerms: acceptTerms,
      ).toJson(),
    );
  }

  Future<AuthSession> refresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw ApiException(statusCode: 401, message: 'No session found.');
    }
    final data = await _api.post(
      '/auth/refresh',
      body: RefreshTokenRequest(refreshToken).toJson(),
    );
    return AuthSession.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return;
    }
    try {
      await _api.post(
        '/auth/logout',
        body: RefreshTokenRequest(refreshToken).toJson(),
      );
    } catch (_) {
      // Logout must be safe to repeat even if the server call fails.
    }
  }

  Future<User> getCurrentUser() async {
    final data = await _api.get('/auth/me');
    return User.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> forgotPassword(String email) async {
    await _api.post(
      '/auth/forgot-password',
      body: ForgotPasswordRequest(email).toJson(),
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _api.post(
      '/auth/reset-password',
      body: ResetPasswordRequest(
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ).toJson(),
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _api.post(
      '/auth/change-password',
      body: ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ).toJson(),
    );
  }
}
