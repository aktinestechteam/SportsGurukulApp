import '../entities/athlete.dart';
import '../repositories/athlete_repository.dart';

class UpdateAthlete {
  const UpdateAthlete(this._repository);

  final AthleteRepository _repository;

  Future<Athlete> call(
    String academyId,
    String athleteId,
    AthleteRequestInput input,
  ) =>
      _repository.updateAthlete(academyId, athleteId, input);
}
