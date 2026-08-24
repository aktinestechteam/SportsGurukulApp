import 'package:go_router/go_router.dart';

import '../features/academy/domain/entities/academy.dart';
import '../features/academy/presentation/pages/academy_list_page.dart';
import '../features/academy/presentation/pages/academy_setup_page.dart';
import '../features/athlete/domain/entities/athlete.dart';
import '../features/athlete/presentation/pages/add_athlete_page.dart';
import '../features/athlete/presentation/pages/athlete_dashboard_page.dart';
import '../features/athlete/presentation/pages/athletes_list_page.dart';
import '../features/batch/domain/entities/batch.dart';
import '../features/batch/presentation/pages/add_batch_page.dart';
import '../features/batch/presentation/pages/batches_list_page.dart';
import '../features/coach/domain/entities/coach.dart';
import '../features/coach/presentation/pages/add_coach_page.dart';
import '../features/coach/presentation/pages/coach_dashboard_page.dart';
import '../features/coach/presentation/pages/coaches_list_page.dart';
import '../features/authentication/presentation/pages/change_password_page.dart';
import '../features/authentication/presentation/pages/forgot_password_page.dart';
import '../features/authentication/presentation/pages/home_page.dart';
import '../features/authentication/presentation/pages/profile_page.dart';
import '../features/authentication/presentation/pages/reset_password_page.dart';
import '../features/authentication/presentation/pages/settings_page.dart';
import '../features/authentication/presentation/pages/sign_in_page.dart';
import '../features/authentication/presentation/pages/sign_up_page.dart';
import '../features/authentication/presentation/pages/splash_page.dart';
import '../features/authentication/domain/entities/user.dart';
import '../features/authentication/presentation/providers/auth_provider.dart';
import 'dependencies.dart';

class AppRouter {
  AppRouter._();

  static String _roleHome(User? user) {
    if (user == null) return '/home';
    final roles = user.roles.map((r) => r.toLowerCase()).toSet();
    if (roles.contains('academycoach') || roles.contains('coach')) {
      return '/coach/dashboard';
    }
    if (roles.contains('academyathlete') || roles.contains('athlete')) {
      return '/athlete/dashboard';
    }
    return '/home';
  }

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
            return _roleHome(auth.user);
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
        GoRoute(
          path: '/coach/dashboard',
          builder: (context, state) => const CoachDashboardPage(),
        ),
        GoRoute(
          path: '/athlete/dashboard',
          builder: (context, state) => const AthleteDashboardPage(),
        ),
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
        GoRoute(
          path: '/academies/:academyId/coaches',
          builder: (context, state) => CoachesListPage(
            academyId: state.pathParameters['academyId'] ?? '',
            academy: state.extra as Academy?,
          ),
        ),
        GoRoute(
          path: '/academies/:academyId/coaches/add',
          builder: (context, state) => AddCoachPage(
            academyId: state.pathParameters['academyId'] ?? '',
            academy: state.extra as Academy?,
          ),
        ),
        GoRoute(
          path: '/academies/:academyId/coaches/:coachId/edit',
          builder: (context, state) {
            final extra =
                state.extra as ({Academy? academy, Coach? coach});
            return AddCoachPage(
              academyId: state.pathParameters['academyId'] ?? '',
              academy: extra.academy,
              coach: extra.coach,
            );
          },
        ),
        GoRoute(
          path: '/academies/:academyId/athletes',
          builder: (context, state) => AthletesListPage(
            academyId: state.pathParameters['academyId'] ?? '',
            academy: state.extra as Academy?,
          ),
        ),
        GoRoute(
          path: '/academies/:academyId/athletes/add',
          builder: (context, state) => AddAthletePage(
            academyId: state.pathParameters['academyId'] ?? '',
            academy: state.extra as Academy?,
          ),
        ),
        GoRoute(
          path: '/academies/:academyId/athletes/:athleteId/edit',
          builder: (context, state) {
            final extra =
                state.extra as ({Academy? academy, Athlete? athlete});
            return AddAthletePage(
              academyId: state.pathParameters['academyId'] ?? '',
              academy: extra.academy,
              athlete: extra.athlete,
            );
          },
        ),
        GoRoute(
          path: '/academies/:academyId/batches',
          builder: (context, state) => BatchesListPage(
            academyId: state.pathParameters['academyId'] ?? '',
            academy: state.extra as Academy?,
          ),
        ),
        GoRoute(
          path: '/academies/:academyId/batches/add',
          builder: (context, state) => AddBatchPage(
            academyId: state.pathParameters['academyId'] ?? '',
            academy: state.extra as Academy?,
          ),
        ),
        GoRoute(
          path: '/academies/:academyId/batches/:batchId/edit',
          builder: (context, state) {
            final extra =
                state.extra as ({Academy? academy, Batch? batch});
            return AddBatchPage(
              academyId: state.pathParameters['academyId'] ?? '',
              academy: extra.academy,
              batch: extra.batch,
            );
          },
        ),
      ],
    );
  }
}
