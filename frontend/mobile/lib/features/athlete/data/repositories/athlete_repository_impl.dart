import '../../domain/entities/athlete.dart';
import '../../domain/repositories/athlete_repository.dart';
import '../datasources/athlete_remote_data_source.dart';
import '../models/athlete_requests.dart';

class AthleteRepositoryImpl implements AthleteRepository {
  AthleteRepositoryImpl({required this.dataSource});

  final AthleteRemoteDataSource dataSource;

  @override
  Future<List<Athlete>> getAthletes(String academyId) =>
      dataSource.getAthletes(academyId);

  @override
  Future<Athlete> createAthlete(
    String academyId,
    AthleteRequestInput input,
  ) =>
      dataSource.createAthlete(
        academyId,
        AthleteRequest.fromInput(input),
      );

  @override
  Future<Athlete> updateAthlete(
    String academyId,
    String athleteId,
    AthleteRequestInput input,
  ) =>
      dataSource.updateAthlete(
        academyId,
        athleteId,
        AthleteRequest.fromInput(input),
      );

  @override
  Future<void> deleteAthlete(String academyId, String athleteId) =>
      dataSource.deleteAthlete(academyId, athleteId);
}
