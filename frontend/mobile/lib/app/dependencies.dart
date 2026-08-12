import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../features/authentication/data/datasources/auth_remote_data_source.dart';
import '../features/authentication/data/repositories/auth_repository_impl.dart';
import '../features/authentication/domain/repositories/auth_repository.dart';
import '../features/authentication/domain/usecases/change_password.dart';
import '../features/authentication/domain/usecases/check_session.dart';
import '../features/authentication/domain/usecases/forgot_password.dart';
import '../features/authentication/domain/usecases/get_current_user.dart';
import '../features/authentication/domain/usecases/refresh_session.dart';
import '../features/authentication/domain/usecases/reset_password.dart';
import '../features/authentication/domain/usecases/sign_in.dart';
import '../features/authentication/domain/usecases/sign_out.dart';
import '../features/authentication/domain/usecases/sign_up.dart';
import '../features/authentication/presentation/providers/auth_provider.dart';

class Dependencies {
  Dependencies._();

  static late final TokenStorage tokenStorage;
  static late final ApiClient apiClient;
  static late final AuthProvider authProvider;

  static void initialize() {
    tokenStorage = TokenStorage(storage: const FlutterSecureStorage());

    apiClient = ApiClient(tokenStorage: tokenStorage);

    final dataSource = AuthRemoteDataSource(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );
    final AuthRepository repository = AuthRepositoryImpl(
      dataSource: dataSource,
      tokenStorage: tokenStorage,
    );

    authProvider = AuthProvider(
      signIn: SignIn(repository),
      signUp: SignUp(repository),
      signOut: SignOut(repository),
      refreshSession: RefreshSession(repository),
      getCurrentUser: GetCurrentUser(repository),
      checkSession: CheckSession(repository),
      forgotPassword: ForgotPassword(repository),
      resetPassword: ResetPassword(repository),
      changePassword: ChangePassword(repository),
    );

    apiClient.onAuthExpired = authProvider.handleSessionExpired;
  }
}
