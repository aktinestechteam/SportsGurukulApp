import '../repositories/coach_repository.dart';

class DeleteCoach {
  const DeleteCoach(this._repository);

  final CoachRepository _repository;

  Future<void> call(String academyId, String coachId) =>
      _repository.deleteCoach(academyId, coachId);
}
