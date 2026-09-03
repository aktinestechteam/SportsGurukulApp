import '../../domain/repositories/coach_repository.dart';

class CoachRequest {
  const CoachRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    this.branchId,
    this.sports = const [],
    this.athleteAssignments = const [],
  });

  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String? branchId;
  final List<CoachSportInput> sports;
  final List<CoachAthleteAssignment> athleteAssignments;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'mobileNumber': mobileNumber,
    'branchId': branchId,
    'sports': sports.map(_sportJson).toList(),
    'athleteAssignments': athleteAssignments
        .where((a) => a.athleteIds.isNotEmpty)
        .map((a) => {'sportId': a.sportId, 'athleteIds': a.athleteIds})
        .toList(),
  };

  static Map<String, dynamic> _sportJson(CoachSportInput s) => {
    'sportId': s.sportId,
    'specialization': s.specialization,
  };
}
