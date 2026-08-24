import '../entities/coach_profile.dart';
import '../repositories/coach_profile_repository.dart';

class GetCoachProfile {
  const GetCoachProfile(this._repository);

  final CoachProfileRepository _repository;

  Future<CoachProfile> call() => _repository.getMe();
}
