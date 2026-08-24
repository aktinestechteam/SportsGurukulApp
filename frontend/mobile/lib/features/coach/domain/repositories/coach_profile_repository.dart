import '../../domain/entities/coach_profile.dart';

abstract class CoachProfileRepository {
  Future<CoachProfile> getMe();
}
