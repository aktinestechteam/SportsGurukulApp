import 'package:sports_gurukul/features/athlete/domain/entities/athlete.dart';
import 'package:sports_gurukul/features/athlete/domain/repositories/athlete_repository.dart';
import 'package:sports_gurukul/features/athlete/domain/usecases/create_athlete.dart';
import 'package:sports_gurukul/features/athlete/domain/usecases/delete_athlete.dart';
import 'package:sports_gurukul/features/athlete/domain/usecases/get_athletes.dart';
import 'package:sports_gurukul/features/athlete/domain/usecases/update_athlete.dart';
import 'package:sports_gurukul/features/athlete/presentation/providers/athlete_provider.dart';

class FakeAthleteRepository implements AthleteRepository {
  FakeAthleteRepository({this.athletes = const []});

  List<Athlete> athletes;

  int createAthleteCalls = 0;
  int updateAthleteCalls = 0;
  int deleteAthleteCalls = 0;

  @override
  Future<List<Athlete>> getAthletes(String academyId) async => athletes;

  @override
  Future<Athlete> createAthlete(
    String academyId,
    AthleteRequestInput input,
  ) async {
    createAthleteCalls++;
    final athlete = Athlete(
      athleteId: 'a${athletes.length + 1}',
      publicUserId: 'SG-ATH-${100000 + athletes.length + 1}',
      firstName: input.firstName,
      lastName: input.lastName,
      email: input.email,
      mobileNumber: input.mobileNumber,
      dateOfBirth: input.dateOfBirth,
      gender: input.gender,
      ageGroup: 'U12',
      academyId: academyId,
      academyName: 'Sports Gurukul Academy',
      branchId: input.branchId,
      branchName: 'Main Campus',
      status: AthleteStatus.invited,
      primarySport: AthleteSport(sportId: input.primarySportId, name: 'Cricket'),
      secondarySport: input.secondarySportId == null
          ? null
          : AthleteSport(
              sportId: input.secondarySportId!,
              name: 'Football',
            ),
      createdAt: DateTime.now().toIso8601String(),
    );
    athletes = [athlete, ...athletes];
    return athlete;
  }

  @override
  Future<Athlete> updateAthlete(
    String academyId,
    String athleteId,
    AthleteRequestInput input,
  ) async {
    updateAthleteCalls++;
    final existing = athletes.firstWhere((a) => a.athleteId == athleteId);
    final updated = Athlete(
      athleteId: athleteId,
      publicUserId: existing.publicUserId,
      firstName: input.firstName,
      lastName: input.lastName,
      email: input.email,
      mobileNumber: input.mobileNumber,
      dateOfBirth: input.dateOfBirth,
      gender: input.gender,
      ageGroup: existing.ageGroup,
      address: input.address,
      emergencyContact: input.emergencyContact,
      academyId: existing.academyId,
      academyName: existing.academyName,
      branchId: input.branchId,
      branchName: existing.branchName,
      status: existing.status,
      primarySport: AthleteSport(
        sportId: input.primarySportId,
        name: 'Cricket',
      ),
      secondarySport: input.secondarySportId == null
          ? null
          : AthleteSport(
              sportId: input.secondarySportId!,
              name: 'Football',
            ),
      createdAt: existing.createdAt,
    );
    athletes = [
      for (final a in athletes)
        if (a.athleteId == athleteId) updated else a,
    ];
    return updated;
  }

  @override
  Future<void> deleteAthlete(String academyId, String athleteId) async {
    deleteAthleteCalls++;
    athletes = athletes.where((a) => a.athleteId != athleteId).toList();
  }
}

AthleteProvider buildAthleteProvider({List<Athlete> athletes = const []}) {
  final repo = FakeAthleteRepository(athletes: athletes);
  return AthleteProvider(
    createAthlete: CreateAthlete(repo),
    getAthletes: GetAthletes(repo),
    updateAthlete: UpdateAthlete(repo),
    deleteAthlete: DeleteAthlete(repo),
  );
}
