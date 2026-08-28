import '../entities/athlete_profile.dart';
import '../repositories/athlete_profile_repository.dart';

class GetAthleteProfile {
  const GetAthleteProfile(this._repository);

  final AthleteProfileRepository _repository;

  Future<AthleteProfile> call() => _repository.getMe();
}