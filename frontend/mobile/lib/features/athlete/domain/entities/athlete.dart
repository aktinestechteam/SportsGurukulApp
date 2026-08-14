enum AthleteStatus {
  invited(1, 'Invited'),
  active(2, 'Active');

  const AthleteStatus(this.value, this.label);

  final int value;
  final String label;

  static AthleteStatus fromValue(int? value) {
    return AthleteStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => AthleteStatus.invited,
    );
  }
}

enum AthleteGender {
  male(1, 'Male'),
  female(2, 'Female'),
  other(3, 'Other');

  const AthleteGender(this.value, this.label);

  final int value;
  final String label;

  static AthleteGender fromValue(int? value) {
    return AthleteGender.values.firstWhere(
      (g) => g.value == value,
      orElse: () => AthleteGender.male,
    );
  }
}

class AthleteSport {
  const AthleteSport({required this.sportId, this.name = ''});

  final String sportId;
  final String name;

  factory AthleteSport.fromJson(Map<String, dynamic> json) {
    return AthleteSport(
      sportId: json['sportId'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'sportId': sportId, 'name': name};
}

class Athlete {
  const Athlete({
    required this.athleteId,
    this.userId = '',
    this.publicUserId = '',
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    this.dateOfBirth,
    this.gender = AthleteGender.male,
    this.ageGroup,
    this.address,
    this.emergencyContact,
    this.academyId = '',
    this.academyName = '',
    this.branchId,
    this.branchName,
    this.status = AthleteStatus.invited,
    this.primarySport,
    this.secondarySport,
    this.createdAt = '',
  });

  final String athleteId;
  final String userId;
  final String publicUserId;
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final DateTime? dateOfBirth;
  final AthleteGender gender;
  final String? ageGroup;
  final String? address;
  final String? emergencyContact;
  final String academyId;
  final String academyName;
  final String? branchId;
  final String? branchName;
  final AthleteStatus status;
  final AthleteSport? primarySport;
  final AthleteSport? secondarySport;
  final String createdAt;

  String get fullName => '$firstName $lastName';

  factory Athlete.fromJson(Map<String, dynamic> json) {
    return Athlete(
      athleteId: json['athleteId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      publicUserId: json['publicUserId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      dateOfBirth: DateTime.tryParse(json['dateOfBirth'] as String? ?? ''),
      gender: AthleteGender.fromValue(json['gender'] as int?),
      ageGroup: json['ageGroup'] as String?,
      address: json['address'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      academyId: json['academyId'] as String? ?? '',
      academyName: json['academyName'] as String? ?? '',
      branchId: json['branchId'] as String?,
      branchName: json['branchName'] as String?,
      status: AthleteStatus.fromValue(json['status'] as int?),
      primarySport: json['primarySport'] is Map
          ? AthleteSport.fromJson(
              (json['primarySport'] as Map).cast<String, dynamic>(),
            )
          : null,
      secondarySport: json['secondarySport'] is Map
          ? AthleteSport.fromJson(
              (json['secondarySport'] as Map).cast<String, dynamic>(),
            )
          : null,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'athleteId': athleteId,
    'userId': userId,
    'publicUserId': publicUserId,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'mobileNumber': mobileNumber,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'gender': gender.value,
    'ageGroup': ageGroup,
    'address': address,
    'emergencyContact': emergencyContact,
    'academyId': academyId,
    'academyName': academyName,
    'branchId': branchId,
    'branchName': branchName,
    'status': status.value,
    'primarySport': primarySport?.toJson(),
    'secondarySport': secondarySport?.toJson(),
    'createdAt': createdAt,
  };
}
