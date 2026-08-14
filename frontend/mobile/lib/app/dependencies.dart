import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../features/academy/data/datasources/academy_remote_data_source.dart';
import '../features/academy/data/repositories/academy_repository_impl.dart';
import '../features/academy/domain/repositories/academy_repository.dart';
import '../features/academy/domain/usecases/create_academy.dart';
import '../features/academy/domain/usecases/delete_academy.dart';
import '../features/academy/domain/usecases/get_academies.dart';
import '../features/academy/domain/usecases/get_academy.dart';
import '../features/academy/domain/usecases/update_academy.dart';
import '../features/academy/presentation/providers/academy_provider.dart';
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
import '../features/coach/data/datasources/coach_remote_data_source.dart';
import '../features/coach/data/repositories/coach_repository_impl.dart';
import '../features/coach/domain/repositories/coach_repository.dart';
import '../features/coach/domain/usecases/create_coach.dart';
import '../features/coach/domain/usecases/delete_coach.dart';
import '../features/coach/domain/usecases/get_coaches.dart';
import '../features/coach/domain/usecases/update_coach.dart';
import '../features/coach/presentation/providers/coach_provider.dart';

class Dependencies {
  Dependencies._();

  static late final TokenStorage tokenStorage;
  static late final ApiClient apiClient;
  static late final AuthProvider authProvider;
  static late final AcademyProvider academyProvider;
  static late final CoachProvider coachProvider;

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

    final academyDataSource = AcademyRemoteDataSource(apiClient: apiClient);
    final AcademyRepository academyRepository = AcademyRepositoryImpl(
      dataSource: academyDataSource,
    );

    academyProvider = AcademyProvider(
      createAcademy: CreateAcademy(academyRepository),
      getAcademies: GetAcademies(academyRepository),
      getAcademy: GetAcademy(academyRepository),
      updateAcademy: UpdateAcademy(academyRepository),
      deleteAcademy: DeleteAcademy(academyRepository),
    );

    final coachDataSource = CoachRemoteDataSource(apiClient: apiClient);
    final CoachRepository coachRepository = CoachRepositoryImpl(
      dataSource: coachDataSource,
    );

    coachProvider = CoachProvider(
      createCoach: CreateCoach(coachRepository),
      getCoaches: GetCoaches(coachRepository),
      updateCoach: UpdateCoach(coachRepository),
      deleteCoach: DeleteCoach(coachRepository),
    );

    apiClient.onAuthExpired = authProvider.handleSessionExpired;
  }
}
