import '../entities/coach.dart';

abstract class CoachRepository {
  Future<List<Coach>> getCoaches(String academyId);
  Future<Coach> createCoach(String academyId, CoachRequestInput input);
  Future<Coach> updateCoach(
    String academyId,
    String coachId,
    CoachRequestInput input,
  );
  Future<void> deleteCoach(String academyId, String coachId);
}

class CoachSportInput {
  const CoachSportInput({required this.sportId, this.specialization});

  final String sportId;
  final String? specialization;
}

class CoachRequestInput {
  const CoachRequestInput({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    this.branchId,
    this.sports = const [],
    this.athleteIds = const [],
  });

  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String? branchId;
  final List<CoachSportInput> sports;
  final List<String> athleteIds;
}
