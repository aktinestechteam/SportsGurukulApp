class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.roles,
    required this.defaultRole,
    required this.accountStatus,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final List<String> roles;
  final String defaultRole;
  final String accountStatus;

  String get fullName => '$firstName $lastName'.trim();

  String get displayRole {
    final role = defaultRole.isNotEmpty
        ? defaultRole
        : (roles.isNotEmpty ? roles.first : '');
    return switch (role) {
      'SystemAdmin' => 'System Admin',
      'AcademyAdmin' => 'Academy Admin',
      'AcademyCoach' => 'Academy Coach',
      'AcademyAthlete' => 'Academy Athlete',
      'Coach' => 'Coach',
      'Athlete' => 'Athlete',
      'AppUser' => 'App User',
      _ => role.isEmpty ? 'User' : role,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId'] as String? ?? json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      roles: (json['roles'] as List?)?.cast<String>() ?? const [],
      defaultRole: json['defaultRole'] as String? ?? '',
      accountStatus: json['accountStatus'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'mobileNumber': mobileNumber,
    'roles': roles,
    'defaultRole': defaultRole,
    'accountStatus': accountStatus,
  };
}
