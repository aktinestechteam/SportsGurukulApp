import '../entities/athlete.dart';

abstract class AthleteRepository {
  Future<List<Athlete>> getAthletes(String academyId);
  Future<Athlete> createAthlete(String academyId, AthleteRequestInput input);
  Future<Athlete> updateAthlete(
    String academyId,
    String athleteId,
    AthleteRequestInput input,
  );
  Future<void> deleteAthlete(String academyId, String athleteId);
}

class AthleteRequestInput {
  const AthleteRequestInput({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.dateOfBirth,
    this.gender = AthleteGender.male,
    this.branchId,
    required this.primarySportId,
    this.secondarySportId,
    this.address,
    this.emergencyContact,
    this.coachIds = const [],
  });

  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final DateTime dateOfBirth;
  final AthleteGender gender;
  final String? branchId;
  final String primarySportId;
  final String? secondarySportId;
  final String? address;
  final String? emergencyContact;
  final List<String> coachIds;
}
