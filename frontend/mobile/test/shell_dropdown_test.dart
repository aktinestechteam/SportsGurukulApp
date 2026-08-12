import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:sports_gurukul/core/theme/app_theme.dart';
import 'package:sports_gurukul/core/theme/theme_controller.dart';
import 'package:sports_gurukul/features/authentication/domain/entities/auth_session.dart';
import 'package:sports_gurukul/features/authentication/domain/entities/user.dart';
import 'package:sports_gurukul/features/authentication/domain/repositories/auth_repository.dart';
import 'package:sports_gurukul/features/authentication/domain/usecases/change_password.dart';
import 'package:sports_gurukul/features/authentication/domain/usecases/check_session.dart';
import 'package:sports_gurukul/features/authentication/domain/usecases/forgot_password.dart';
import 'package:sports_gurukul/features/authentication/domain/usecases/get_current_user.dart';
import 'package:sports_gurukul/features/authentication/domain/usecases/refresh_session.dart';
import 'package:sports_gurukul/features/authentication/domain/usecases/reset_password.dart';
import 'package:sports_gurukul/features/authentication/domain/usecases/sign_in.dart';
import 'package:sports_gurukul/features/authentication/domain/usecases/sign_out.dart';
import 'package:sports_gurukul/features/authentication/domain/usecases/sign_up.dart';
import 'package:sports_gurukul/features/authentication/presentation/pages/home_page.dart';
import 'package:sports_gurukul/features/authentication/presentation/pages/profile_page.dart';
import 'package:sports_gurukul/features/authentication/presentation/pages/settings_page.dart';
import 'package:sports_gurukul/features/authentication/presentation/providers/auth_provider.dart';

class _FakeRepo implements AuthRepository {
  _FakeRepo(this.user);

  final User user;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => AuthSession(accessToken: 'a', refreshToken: 'r', user: user);

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
    required String confirmPassword,
    required bool acceptTerms,
  }) async {}

  @override
  Future<AuthSession> refresh() async =>
      AuthSession(accessToken: 'a', refreshToken: 'r', user: user);

  @override
  Future<void> logout() async {}

  @override
  Future<User> getCurrentUser() async => user;

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {}

  @override
  Future<bool> hasStoredSession() async => true;
}

AuthProvider _buildAuthenticated() {
  final user = User(
    id: 'u1',
    firstName: 'Aarav',
    lastName: 'Sharma',
    email: 'aarav@example.com',
    mobileNumber: '9876543210',
    roles: const ['AppUser'],
    defaultRole: 'AppUser',
    accountStatus: 'Active',
  );
  final repo = _FakeRepo(user);
  return AuthProvider(
    signIn: SignIn(repo),
    signUp: SignUp(repo),
    signOut: SignOut(repo),
    refreshSession: RefreshSession(repo),
    getCurrentUser: GetCurrentUser(repo),
    checkSession: CheckSession(repo),
    forgotPassword: ForgotPassword(repo),
    resetPassword: ResetPassword(repo),
    changePassword: ChangePassword(repo),
  );
}

Widget _app(AuthProvider auth) {
  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: auth,
    redirect: (context, state) {
      final status = auth.status;
      final location = state.matchedLocation;

      final booting =
          status == AuthStatus.initial || status == AuthStatus.checkingSession;
      if (booting) {
        return location == '/' ? null : '/';
      }

      final authenticated = status == AuthStatus.authenticated;
      final publicOnly =
          location == '/sign-in' ||
          location == '/sign-up' ||
          location == '/forgot-password' ||
          location == '/reset-password';

      if (authenticated) {
        if (publicOnly || location == '/') {
          return '/home';
        }
        return null;
      }

      if (publicOnly) {
        return null;
      }

      return '/sign-in';
    },
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const HomePage()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
      GoRoute(path: '/change-password', builder: (_, _) => const Placeholder()),
    ],
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider(create: (_) => ThemeController()),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

void main() {
  for (final (description, label, page) in [
    ('profile', 'Profile', ProfilePage),
    ('settings', 'Settings', SettingsPage),
  ]) {
    testWidgets('opens $description from the avatar dropdown', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final auth = _buildAuthenticated();
      await auth.initialize();

      await tester.pumpWidget(_app(auth));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byTooltip('Account menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();

      expect(find.byType(page), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });
  }
}
