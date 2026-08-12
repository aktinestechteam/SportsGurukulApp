import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.dataSource, required this.tokenStorage});

  final AuthRemoteDataSource dataSource;
  final TokenStorage tokenStorage;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await dataSource.login(email: email, password: password);
    await tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
    required String confirmPassword,
    required bool acceptTerms,
  }) {
    return dataSource.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      mobileNumber: mobileNumber,
      password: password,
      confirmPassword: confirmPassword,
      acceptTerms: acceptTerms,
    );
  }

  @override
  Future<AuthSession> refresh() async {
    final session = await dataSource.refresh();
    await tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  @override
  Future<void> logout() async {
    await dataSource.logout();
    await tokenStorage.clear();
  }

  @override
  Future<User> getCurrentUser() => dataSource.getCurrentUser();

  @override
  Future<void> forgotPassword(String email) => dataSource.forgotPassword(email);

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) => dataSource.resetPassword(
    token: token,
    newPassword: newPassword,
    confirmPassword: confirmPassword,
  );

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) => dataSource.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
    confirmPassword: confirmPassword,
  );

  @override
  Future<bool> hasStoredSession() => tokenStorage.hasTokens();
}
