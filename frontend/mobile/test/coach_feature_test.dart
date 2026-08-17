import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:sports_gurukul/core/theme/app_theme.dart';
import 'package:sports_gurukul/core/theme/theme_controller.dart';
import 'package:sports_gurukul/core/widgets/app_button.dart';
import 'package:sports_gurukul/features/academy/domain/entities/academy.dart';
import 'package:sports_gurukul/features/academy/presentation/providers/academy_provider.dart';
import 'package:sports_gurukul/features/athlete/presentation/providers/athlete_provider.dart';
import 'package:sports_gurukul/features/coach/domain/entities/coach.dart';
import 'package:sports_gurukul/features/coach/presentation/pages/add_coach_page.dart';
import 'package:sports_gurukul/features/coach/presentation/pages/coaches_list_page.dart';
import 'package:sports_gurukul/features/coach/presentation/providers/coach_provider.dart';

import 'helpers/fake_academy_repository.dart';
import 'helpers/fake_athlete_repository.dart';
import 'helpers/fake_coach_repository.dart';

Academy _sampleAcademy() => const Academy(
  id: 'a1',
  name: 'Sports Gurukul Academy',
  branches: [
    AcademyBranch(id: 'b1', name: 'Main Campus'),
  ],
  sports: [
    AcademySport(id: 's1', name: 'Cricket'),
    AcademySport(id: 's2', name: 'Football'),
  ],
);

List<Coach> _sampleCoaches() => const [
  Coach(
    coachId: 'c1',
    publicUserId: 'SG-COACH-000001',
    firstName: 'Virat',
    lastName: 'Kohli',
    email: 'virat@example.com',
    mobileNumber: '+919810011001',
    academyId: 'a1',
    academyName: 'Sports Gurukul Academy',
    branchId: 'b1',
    branchName: 'Main Campus',
    status: CoachStatus.invited,
    sports: [
      CoachSport(sportId: 's1', name: 'Cricket', specialization: 'Batting'),
    ],
  ),
];

Widget _app(CoachProvider coach, {AcademyProvider? academy}) {
  final router = GoRouter(
    initialLocation: '/academies/a1/coaches',
    routes: [
      GoRoute(
        path: '/academies/:academyId/coaches',
        builder: (context, state) => CoachesListPage(
          academyId: state.pathParameters['academyId'] ?? '',
          academy: (state.extra as Academy?) ?? _sampleAcademy(),
        ),
      ),
      GoRoute(
        path: '/academies/:academyId/coaches/add',
        builder: (context, state) => AddCoachPage(
          academyId: state.pathParameters['academyId'] ?? '',
          academy: (state.extra as Academy?) ?? _sampleAcademy(),
        ),
      ),
      GoRoute(
        path: '/academies/:academyId/coaches/:coachId/edit',
        builder: (context, state) {
          final extra = state.extra as ({Academy? academy, Coach? coach});
          return AddCoachPage(
            academyId: state.pathParameters['academyId'] ?? '',
            academy: extra.academy ?? _sampleAcademy(),
            coach: extra.coach,
          );
        },
      ),
    ],
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CoachProvider>.value(value: coach),
      ChangeNotifierProvider<AcademyProvider>.value(
        value: academy ?? buildAcademyProvider(),
      ),
      ChangeNotifierProvider<AthleteProvider>.value(
        value: buildAthleteProvider(),
      ),
      ChangeNotifierProvider(create: (_) => ThemeController()),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('coach list shows coaches and their details', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final coach = buildCoachProvider(coaches: _sampleCoaches());

    await tester.pumpWidget(_app(coach, academy: buildAcademyProvider()));
    await tester.pump();
    await tester.pump();

    expect(find.text('Virat Kohli'), findsOneWidget);
    expect(find.text('SG-COACH-000001'), findsOneWidget);
    expect(find.text('virat@example.com'), findsOneWidget);
    expect(find.text('+919810011001'), findsOneWidget);
    expect(find.text('Main Campus'), findsOneWidget);
    expect(find.text('Cricket · Batting'), findsOneWidget);
    expect(find.text('Invited'), findsOneWidget);
    expect(find.text('Add Coach'), findsWidgets);
  });

  testWidgets('adding a coach navigates and appears in the list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final coach = buildCoachProvider(coaches: _sampleCoaches());

    await tester.pumpWidget(
      _app(coach, academy: buildAcademyProvider()),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.widgetWithText(AppButton, 'Add Coach').first);
    await tester.pumpAndSettle();

    expect(find.byType(AddCoachPage), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Rohit');
    await tester.enterText(fields.at(1), 'Sharma');
    await tester.enterText(fields.at(2), 'rohit@example.com');
    await tester.enterText(fields.at(3), '+919810022002');

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Cricket'));
    await tester.pump();

    await tester.ensureVisible(find.widgetWithText(AppButton, 'Add Coach').last);
    await tester.tap(find.widgetWithText(AppButton, 'Add Coach').last);
    await tester.pumpAndSettle();

    expect(find.text('Rohit Sharma'), findsOneWidget);
    expect(find.text('rohit@example.com'), findsOneWidget);
  });

  testWidgets('editing a coach prefills and saves the changes', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final coach = buildCoachProvider(coaches: _sampleCoaches());

    await tester.pumpWidget(_app(coach, academy: buildAcademyProvider()));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('Edit Coach'));
    await tester.pumpAndSettle();

    expect(find.byType(AddCoachPage), findsOneWidget);
    expect(find.text('Edit Coach'), findsWidgets);

    final fields = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      'Virat',
    );

    await tester.enterText(fields.at(0), 'Virender');
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Football'));
    await tester.pump();

    await tester.ensureVisible(find.widgetWithText(AppButton, 'Save Changes'));
    await tester.tap(find.widgetWithText(AppButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.byType(AddCoachPage), findsNothing);
    expect(find.text('Virender Kohli'), findsOneWidget);
    expect(find.text('Virat Kohli'), findsNothing);
  });

  testWidgets('deleting a coach confirms and removes it from the list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final coach = buildCoachProvider(coaches: _sampleCoaches());

    await tester.pumpWidget(_app(coach, academy: buildAcademyProvider()));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('Remove Coach'));
    await tester.pumpAndSettle();

    expect(find.text('Remove Coach'), findsWidgets);
    expect(
      find.text(
        'Remove "Virat Kohli" from this academy? This cannot be undone.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(AppButton, 'Remove'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Virat Kohli'), findsNothing);
    expect(find.text('Coach removed successfully.'), findsOneWidget);
  });
}
