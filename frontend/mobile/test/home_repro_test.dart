import 'dart:ui';

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
import 'package:sports_gurukul/features/authentication/presentation/providers/auth_provider.dart';
import 'package:sports_gurukul/features/academy/presentation/providers/academy_provider.dart';

import 'helpers/fake_academy_repository.dart';

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
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const HomePage()),
      GoRoute(path: '/change-password', builder: (_, _) => const Placeholder()),
    ],
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<AcademyProvider>.value(
        value: buildAcademyProvider(),
      ),
      ChangeNotifierProvider(create: (_) => ThemeController()),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

Future<void> _hover(WidgetTester tester, Offset point) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: point);
  await gesture.moveTo(point);
  await tester.pump();
  await gesture.removePointer();
}

void main() {
  testWidgets('home desktop hit-test', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = _buildAuthenticated();
    await auth.initialize();

    await tester.pumpWidget(_app(auth));
    await tester.pump();
    await tester.pump();

    for (final point in [
      const Offset(300, 100),
      const Offset(400, 300),
      const Offset(500, 400),
      const Offset(1200, 700),
      const Offset(100, 350),
      const Offset(100, 600),
      const Offset(1100, 100),
    ]) {
      await _hover(tester, point);
    }
  });

  testWidgets('home compact hit-test', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = _buildAuthenticated();
    await auth.initialize();

    await tester.pumpWidget(_app(auth));
    await tester.pump();
    await tester.pump();

    for (final point in [
      const Offset(200, 100),
      const Offset(200, 400),
      const Offset(200, 700),
      const Offset(200, 750),
      const Offset(50, 400),
    ]) {
      await _hover(tester, point);
    }
  });
}
