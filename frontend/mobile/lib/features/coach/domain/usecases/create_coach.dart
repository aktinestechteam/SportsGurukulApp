import '../entities/coach.dart';
import '../repositories/coach_repository.dart';

class CreateCoach {
  const CreateCoach(this._repository);

  final CoachRepository _repository;

  Future<Coach> call(String academyId, CoachRequestInput input) =>
      _repository.createCoach(academyId, input);
}
