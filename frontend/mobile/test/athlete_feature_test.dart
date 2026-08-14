import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:sports_gurukul/core/theme/app_theme.dart';
import 'package:sports_gurukul/core/theme/theme_controller.dart';
import 'package:sports_gurukul/core/widgets/app_button.dart';
import 'package:sports_gurukul/features/academy/domain/entities/academy.dart';
import 'package:sports_gurukul/features/academy/presentation/providers/academy_provider.dart';
import 'package:sports_gurukul/features/athlete/domain/entities/athlete.dart';
import 'package:sports_gurukul/features/athlete/presentation/pages/add_athlete_page.dart';
import 'package:sports_gurukul/features/athlete/presentation/pages/athletes_list_page.dart';
import 'package:sports_gurukul/features/athlete/presentation/providers/athlete_provider.dart';

import 'helpers/fake_academy_repository.dart';
import 'helpers/fake_athlete_repository.dart';

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

List<Athlete> _sampleAthletes() => [
  Athlete(
    athleteId: 'a1',
    publicUserId: 'SG-ATH-000001',
    firstName: 'Rohit',
    lastName: 'Sharma',
    email: 'rohit@example.com',
    mobileNumber: '+919810011001',
    dateOfBirth: DateTime(2012, 5, 1),
    gender: AthleteGender.male,
    ageGroup: 'U14',
    academyId: 'a1',
    academyName: 'Sports Gurukul Academy',
    branchId: 'b1',
    branchName: 'Main Campus',
    status: AthleteStatus.invited,
    primarySport: AthleteSport(sportId: 's1', name: 'Cricket'),
    secondarySport: AthleteSport(sportId: 's2', name: 'Football'),
  ),
];

Widget _app(AthleteProvider athlete, {AcademyProvider? academy}) {
  final router = GoRouter(
    initialLocation: '/academies/a1/athletes',
    routes: [
      GoRoute(
        path: '/academies/:academyId/athletes',
        builder: (context, state) => AthletesListPage(
          academyId: state.pathParameters['academyId'] ?? '',
          academy: (state.extra as Academy?) ?? _sampleAcademy(),
        ),
      ),
      GoRoute(
        path: '/academies/:academyId/athletes/add',
        builder: (context, state) => AddAthletePage(
          academyId: state.pathParameters['academyId'] ?? '',
          academy: (state.extra as Academy?) ?? _sampleAcademy(),
        ),
      ),
      GoRoute(
        path: '/academies/:academyId/athletes/:athleteId/edit',
        builder: (context, state) {
          final extra = state.extra as ({Academy? academy, Athlete? athlete});
          return AddAthletePage(
            academyId: state.pathParameters['academyId'] ?? '',
            academy: extra.academy ?? _sampleAcademy(),
            athlete: extra.athlete,
          );
        },
      ),
    ],
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AthleteProvider>.value(value: athlete),
      ChangeNotifierProvider<AcademyProvider>.value(
        value: academy ?? buildAcademyProvider(),
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
  testWidgets('athlete list shows athletes and their details', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final athlete = buildAthleteProvider(athletes: _sampleAthletes());

    await tester.pumpWidget(_app(athlete, academy: buildAcademyProvider()));
    await tester.pump();
    await tester.pump();

    expect(find.text('Rohit Sharma'), findsOneWidget);
    expect(find.text('SG-ATH-000001'), findsOneWidget);
    expect(find.text('rohit@example.com'), findsOneWidget);
    expect(find.text('+919810011001'), findsOneWidget);
    expect(find.text('Main Campus'), findsOneWidget);
    expect(find.text('Cricket · Primary'), findsOneWidget);
    expect(find.text('Football · Secondary'), findsOneWidget);
    expect(find.text('U14'), findsOneWidget);
    expect(find.text('Invited'), findsOneWidget);
    expect(find.text('Add Athlete'), findsWidgets);
  });

  testWidgets('adding an athlete navigates and appears in the list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final athlete = buildAthleteProvider(athletes: _sampleAthletes());

    await tester.pumpWidget(_app(athlete, academy: buildAcademyProvider()));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.widgetWithText(AppButton, 'Add Athlete').first);
    await tester.pumpAndSettle();

    expect(find.byType(AddAthletePage), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Virat');
    await tester.enterText(fields.at(1), 'Kohli');
    await tester.enterText(fields.at(2), 'virat@example.com');
    await tester.enterText(fields.at(3), '+919810022002');

    await tester.ensureVisible(find.byIcon(Icons.cake_outlined));
    await tester.tap(find.byIcon(Icons.cake_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(AppButton, 'Add Athlete').last,
    );
    await tester.tap(find.widgetWithText(AppButton, 'Add Athlete').last);
    await tester.pumpAndSettle();

    expect(find.byType(AddAthletePage), findsNothing);
    expect(find.text('Virat Kohli'), findsOneWidget);
    expect(find.text('virat@example.com'), findsOneWidget);
  });

  testWidgets('editing an athlete prefills and saves the changes', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final athlete = buildAthleteProvider(athletes: _sampleAthletes());

    await tester.pumpWidget(_app(athlete, academy: buildAcademyProvider()));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('Edit Athlete'));
    await tester.pumpAndSettle();

    expect(find.byType(AddAthletePage), findsOneWidget);
    expect(find.text('Edit Athlete'), findsWidgets);

    final fields = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      'Rohit',
    );

    await tester.enterText(fields.at(0), 'Rahul');

    await tester.ensureVisible(find.widgetWithText(AppButton, 'Save Changes'));
    await tester.tap(find.widgetWithText(AppButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(find.byType(AddAthletePage), findsNothing);
    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('Rohit Sharma'), findsNothing);
  });

  testWidgets('deleting an athlete confirms and removes it from the list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final athlete = buildAthleteProvider(athletes: _sampleAthletes());

    await tester.pumpWidget(_app(athlete, academy: buildAcademyProvider()));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('Remove Athlete'));
    await tester.pumpAndSettle();

    expect(find.text('Remove Athlete'), findsWidgets);
    expect(
      find.text(
        'Remove "Rohit Sharma" from this academy? This cannot be undone.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(AppButton, 'Remove'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Rohit Sharma'), findsNothing);
    expect(find.text('Athlete removed successfully.'), findsOneWidget);
  });
}
