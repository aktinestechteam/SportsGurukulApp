import '../../domain/entities/athlete.dart';
import '../../domain/repositories/athlete_repository.dart';

class AthleteRequest {
  const AthleteRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.dateOfBirth,
    required this.gender,
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

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'mobileNumber': mobileNumber,
    'dateOfBirth': _formatDate(dateOfBirth),
    'gender': gender.value,
    'branchId': branchId,
    'primarySportId': primarySportId,
    'secondarySportId': secondarySportId,
    'address': address,
    'emergencyContact': emergencyContact,
    'coachIds': coachIds,
  };

  factory AthleteRequest.fromInput(AthleteRequestInput input) => AthleteRequest(
    firstName: input.firstName,
    lastName: input.lastName,
    email: input.email,
    mobileNumber: input.mobileNumber,
    dateOfBirth: input.dateOfBirth,
    gender: input.gender,
    branchId: input.branchId,
    primarySportId: input.primarySportId,
    secondarySportId: input.secondarySportId,
    address: input.address,
    emergencyContact: input.emergencyContact,
    coachIds: input.coachIds,
  );

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
