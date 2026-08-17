import '../entities/academy.dart';

abstract class AcademyRepository {
  Future<Academy> create(AcademyRequestInput input);

  Future<List<Academy>> getAcademies();

  Future<Academy> getAcademy(String academyId);

  Future<Academy> update(String academyId, AcademyRequestInput input);

  Future<void> delete(String academyId);
}

class AcademyRequestInput {
  const AcademyRequestInput({
    required this.name,
    this.profile,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.logoUrl,
    this.isPublic = false,
    this.branches = const [],
    this.sports = const [],
    this.facilities = const [],
    this.memberships = const [],
    this.workingHours = const [],
  });

  final String name;
  final String? profile;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? logoUrl;
  final bool isPublic;
  final List<AcademyBranchInput> branches;
  final List<AcademySportInput> sports;
  final List<AcademyFacilityInput> facilities;
  final List<AcademyMembershipInput> memberships;
  final List<AcademyWorkingHourInput> workingHours;
}

class AcademyBranchInput {
  const AcademyBranchInput({
    required this.name,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.contactEmail,
    this.contactPhone,
    this.isMain = false,
  });

  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? contactEmail;
  final String? contactPhone;
  final bool isMain;
}

class AcademySportInput {
  const AcademySportInput({required this.name});

  final String name;
}

class AcademyFacilityInput {
  const AcademyFacilityInput({
    required this.name,
    this.type,
    this.capacity,
    this.description,
  });

  final String name;
  final String? type;
  final int? capacity;
  final String? description;
}

class AcademyMembershipInput {
  const AcademyMembershipInput({
    required this.name,
    this.description,
    this.durationDays = 30,
    this.price = 0,
  });

  final String name;
  final String? description;
  final int durationDays;
  final double price;
}

class AcademyWorkingHourInput {
  const AcademyWorkingHourInput({
    required this.dayOfWeek,
    this.openTime,
    this.closeTime,
    this.isClosed = false,
  });

  final int dayOfWeek;
  final String? openTime;
  final String? closeTime;
  final bool isClosed;
}
