enum CoachStatus {
  invited(1, 'Invited'),
  active(2, 'Active');

  const CoachStatus(this.value, this.label);

  final int value;
  final String label;

  static CoachStatus fromValue(int? value) {
    return CoachStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => CoachStatus.invited,
    );
  }
}

class CoachSport {
  const CoachSport({
    required this.sportId,
    this.name = '',
    this.specialization,
  });

  final String sportId;
  final String name;
  final String? specialization;

  factory CoachSport.fromJson(Map<String, dynamic> json) {
    return CoachSport(
      sportId: json['sportId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      specialization: json['specialization'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'sportId': sportId,
    'name': name,
    'specialization': specialization,
  };
}

class Coach {
  const Coach({
    required this.coachId,
    this.userId = '',
    this.publicUserId = '',
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    this.academyId = '',
    this.academyName = '',
    this.branchId,
    this.branchName,
    this.status = CoachStatus.invited,
    this.sports = const [],
    this.createdAt = '',
  });

  final String coachId;
  final String userId;
  final String publicUserId;
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String academyId;
  final String academyName;
  final String? branchId;
  final String? branchName;
  final CoachStatus status;
  final List<CoachSport> sports;
  final String createdAt;

  String get fullName => '$firstName $lastName';

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      coachId: json['coachId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      publicUserId: json['publicUserId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      academyName: json['academyName'] as String? ?? '',
      branchId: json['branchId'] as String?,
      branchName: json['branchName'] as String?,
      status: CoachStatus.fromValue(json['status'] as int?),
      sports: (json['sports'] as List? ?? const [])
          .map((e) => CoachSport.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'coachId': coachId,
    'userId': userId,
    'publicUserId': publicUserId,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'mobileNumber': mobileNumber,
    'academyId': academyId,
    'academyName': academyName,
    'branchId': branchId,
    'branchName': branchName,
    'status': status.value,
    'sports': sports.map((e) => e.toJson()).toList(),
    'createdAt': createdAt,
  };
}
