import '../entities/coach.dart';
import '../repositories/coach_repository.dart';

class UpdateCoach {
  const UpdateCoach(this._repository);

  final CoachRepository _repository;

  Future<Coach> call(
    String academyId,
    String coachId,
    CoachRequestInput input,
  ) =>
      _repository.updateCoach(academyId, coachId, input);
}
