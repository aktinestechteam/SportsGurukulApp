import '../repositories/athlete_repository.dart';

class DeleteAthlete {
  const DeleteAthlete(this._repository);

  final AthleteRepository _repository;

  Future<void> call(String academyId, String athleteId) =>
      _repository.deleteAthlete(academyId, athleteId);
}
