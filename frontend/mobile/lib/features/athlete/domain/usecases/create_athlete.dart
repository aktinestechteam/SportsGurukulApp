import '../entities/athlete.dart';
import '../repositories/athlete_repository.dart';

class CreateAthlete {
  const CreateAthlete(this._repository);

  final AthleteRepository _repository;

  Future<Athlete> call(String academyId, AthleteRequestInput input) =>
      _repository.createAthlete(academyId, input);
}
