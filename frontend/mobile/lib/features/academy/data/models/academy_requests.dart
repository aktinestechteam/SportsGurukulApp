import '../../domain/repositories/academy_repository.dart';

/// JSON payload sent to the academy API. Uses the domain input value types.
class AcademyRequest {
  const AcademyRequest({
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

  Map<String, dynamic> toJson() => {
    'name': name,
    'profile': profile,
    'contactEmail': contactEmail,
    'contactPhone': contactPhone,
    'address': address,
    'city': city,
    'state': state,
    'country': country,
    'postalCode': postalCode,
    'logoUrl': logoUrl,
    'isPublic': isPublic,
    'branches': branches.map(_branchJson).toList(),
    'sports': sports.map(_sportJson).toList(),
    'facilities': facilities.map(_facilityJson).toList(),
    'memberships': memberships.map(_membershipJson).toList(),
    'workingHours': workingHours.map(_workingHourJson).toList(),
  };

  static Map<String, dynamic> _branchJson(AcademyBranchInput b) => {
    'name': b.name,
    'address': b.address,
    'city': b.city,
    'state': b.state,
    'country': b.country,
    'postalCode': b.postalCode,
    'contactEmail': b.contactEmail,
    'contactPhone': b.contactPhone,
    'isMain': b.isMain,
  };

  static Map<String, dynamic> _sportJson(AcademySportInput s) => {
    'name': s.name,
  };

  static Map<String, dynamic> _facilityJson(AcademyFacilityInput f) => {
    'name': f.name,
    'type': f.type,
    'capacity': f.capacity,
    'description': f.description,
  };

  static Map<String, dynamic> _membershipJson(AcademyMembershipInput m) => {
    'name': m.name,
    'description': m.description,
    'durationDays': m.durationDays,
    'price': m.price,
  };

  static Map<String, dynamic> _workingHourJson(AcademyWorkingHourInput w) => {
    'dayOfWeek': w.dayOfWeek,
    'openTime': w.openTime,
    'closeTime': w.closeTime,
    'isClosed': w.isClosed,
  };
}
