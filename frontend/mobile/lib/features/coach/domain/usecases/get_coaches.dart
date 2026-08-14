import '../entities/coach.dart';
import '../repositories/coach_repository.dart';

class GetCoaches {
  const GetCoaches(this._repository);

  final CoachRepository _repository;

  Future<List<Coach>> call(String academyId) => _repository.getCoaches(academyId);
}
