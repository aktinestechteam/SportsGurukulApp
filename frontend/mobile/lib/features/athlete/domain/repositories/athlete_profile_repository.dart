import '../entities/athlete_profile.dart';

abstract class AthleteProfileRepository {
  Future<AthleteProfile> getMe();
}