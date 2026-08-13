class AcademyBranch {
  const AcademyBranch({
    required this.id,
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

  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? contactEmail;
  final String? contactPhone;
  final bool isMain;

  factory AcademyBranch.fromJson(Map<String, dynamic> json) {
    return AcademyBranch(
      id: json['branchId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
      isMain: json['isMain'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'branchId': id,
    'name': name,
    'address': address,
    'city': city,
    'state': state,
    'country': country,
    'postalCode': postalCode,
    'contactEmail': contactEmail,
    'contactPhone': contactPhone,
    'isMain': isMain,
  };
}

class AcademySport {
  const AcademySport({required this.id, required this.name});

  final String id;
  final String name;

  factory AcademySport.fromJson(Map<String, dynamic> json) {
    return AcademySport(
      id: json['sportId'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'sportId': id, 'name': name};
}

class AcademyFacility {
  const AcademyFacility({
    required this.id,
    required this.name,
    this.type,
    this.capacity,
    this.description,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? type;
  final int? capacity;
  final String? description;
  final bool isActive;

  factory AcademyFacility.fromJson(Map<String, dynamic> json) {
    return AcademyFacility(
      id: json['facilityId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String?,
      capacity: json['capacity'] as int?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'facilityId': id,
    'name': name,
    'type': type,
    'capacity': capacity,
    'description': description,
    'isActive': isActive,
  };
}

class AcademyMembership {
  const AcademyMembership({
    required this.id,
    required this.name,
    this.description,
    required this.durationDays,
    required this.price,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? description;
  final int durationDays;
  final double price;
  final bool isActive;

  factory AcademyMembership.fromJson(Map<String, dynamic> json) {
    return AcademyMembership(
      id: json['membershipId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      durationDays: json['durationDays'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'membershipId': id,
    'name': name,
    'description': description,
    'durationDays': durationDays,
    'price': price,
    'isActive': isActive,
  };
}

class AcademyWorkingHour {
  const AcademyWorkingHour({
    required this.id,
    required this.dayOfWeek,
    this.openTime,
    this.closeTime,
    this.isClosed = false,
  });

  final String id;
  final int dayOfWeek;
  final String? openTime;
  final String? closeTime;
  final bool isClosed;

  factory AcademyWorkingHour.fromJson(Map<String, dynamic> json) {
    return AcademyWorkingHour(
      id: json['workingHourId'] as String? ?? '',
      dayOfWeek: json['dayOfWeek'] as int? ?? 0,
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      isClosed: json['isClosed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'workingHourId': id,
    'dayOfWeek': dayOfWeek,
    'openTime': openTime,
    'closeTime': closeTime,
    'isClosed': isClosed,
  };
}

class Academy {
  const Academy({
    required this.id,
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
    this.ownerUserId = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.branches = const [],
    this.sports = const [],
    this.facilities = const [],
    this.memberships = const [],
    this.workingHours = const [],
  });

  final String id;
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
  final String ownerUserId;
  final String createdAt;
  final String updatedAt;
  final List<AcademyBranch> branches;
  final List<AcademySport> sports;
  final List<AcademyFacility> facilities;
  final List<AcademyMembership> memberships;
  final List<AcademyWorkingHour> workingHours;

  String get location {
    final parts = [city, state, country].where((e) => e != null && e.isNotEmpty);
    return parts.isEmpty ? '' : parts.join(', ');
  }

  factory Academy.fromJson(Map<String, dynamic> json) {
    return Academy(
      id: json['academyId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      profile: json['profile'] as String?,
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      logoUrl: json['logoUrl'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      ownerUserId: json['ownerUserId'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      branches: (json['branches'] as List? ?? const [])
          .map((e) => AcademyBranch.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      sports: (json['sports'] as List? ?? const [])
          .map((e) => AcademySport.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      facilities: (json['facilities'] as List? ?? const [])
          .map((e) => AcademyFacility.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      memberships: (json['memberships'] as List? ?? const [])
          .map((e) => AcademyMembership.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      workingHours: (json['workingHours'] as List? ?? const [])
          .map((e) => AcademyWorkingHour.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'academyId': id,
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
    'ownerUserId': ownerUserId,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'branches': branches.map((e) => e.toJson()).toList(),
    'sports': sports.map((e) => e.toJson()).toList(),
    'facilities': facilities.map((e) => e.toJson()).toList(),
    'memberships': memberships.map((e) => e.toJson()).toList(),
    'workingHours': workingHours.map((e) => e.toJson()).toList(),
  };
}
