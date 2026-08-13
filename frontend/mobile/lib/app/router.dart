import 'package:go_router/go_router.dart';

import '../features/academy/presentation/pages/academy_list_page.dart';
import '../features/academy/presentation/pages/academy_setup_page.dart';
import '../features/authentication/presentation/pages/change_password_page.dart';
import '../features/authentication/presentation/pages/forgot_password_page.dart';
import '../features/authentication/presentation/pages/home_page.dart';
import '../features/authentication/presentation/pages/profile_page.dart';
import '../features/authentication/presentation/pages/reset_password_page.dart';
import '../features/authentication/presentation/pages/settings_page.dart';
import '../features/authentication/presentation/pages/sign_in_page.dart';
import '../features/authentication/presentation/pages/sign_up_page.dart';
import '../features/authentication/presentation/pages/splash_page.dart';
import '../features/authentication/presentation/providers/auth_provider.dart';
import 'dependencies.dart';

class AppRouter {
  AppRouter._();

  static GoRouter create() {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: Dependencies.authProvider,
      redirect: (context, state) {
        final auth = Dependencies.authProvider;
        final status = auth.status;
        final location = state.matchedLocation;

        final booting =
            status == AuthStatus.initial ||
            status == AuthStatus.checkingSession;
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
        GoRoute(path: '/', builder: (context, state) => const SplashPage()),
        GoRoute(
          path: '/sign-in',
          builder: (context, state) => const SignInPage(),
        ),
        GoRoute(
          path: '/sign-up',
          builder: (context, state) => const SignUpPage(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordPage(),
        ),
        GoRoute(
          path: '/change-password',
          builder: (context, state) => const ChangePasswordPage(),
        ),
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/academies',
          builder: (context, state) => const AcademyListPage(),
        ),
        GoRoute(
          path: '/academies/register',
          builder: (context, state) => const AcademySetupPage(),
        ),
        GoRoute(
          path: '/academies/:academyId/edit',
          builder: (context, state) => AcademySetupPage(
            academyId: state.pathParameters['academyId'],
          ),
        ),
      ],
    );
  }
}
