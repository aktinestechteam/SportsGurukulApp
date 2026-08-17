import '../entities/athlete.dart';
import '../repositories/athlete_repository.dart';

class GetAthletes {
  const GetAthletes(this._repository);

  final AthleteRepository _repository;

  Future<List<Athlete>> call(String academyId) =>
      _repository.getAthletes(academyId);
}
