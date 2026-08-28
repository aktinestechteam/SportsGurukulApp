import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/time_format.dart';

class AthleteSportInfo {
  const AthleteSportInfo({
    this.sportId = '',
    this.name = '',
  });

  final String sportId;
  final String name;

  factory AthleteSportInfo.fromJson(Map<String, dynamic> json) {
    return AthleteSportInfo(
      sportId: json['sportId'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class AthleteAcademyInfo {
  const AthleteAcademyInfo({
    required this.academyId,
    this.name = '',
  });

  final String academyId;
  final String name;

  factory AthleteAcademyInfo.fromJson(Map<String, dynamic> json) {
    return AthleteAcademyInfo(
      academyId: json['academyId'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class AthleteBatchInfo {
  const AthleteBatchInfo({
    required this.batchId,
    this.name = '',
    this.academyId = '',
    this.academyName = '',
    this.sportName,
    this.slots = const [],
    this.coaches = const [],
    this.startDate,
    this.endDate,
  });

  final String batchId;
  final String name;
  final String academyId;
  final String academyName;
  final String? sportName;
  final List<AthleteBatchSlot> slots;
  final List<AthleteCoachInfo> coaches;
  final DateTime? startDate;
  final DateTime? endDate;

  factory AthleteBatchInfo.fromJson(Map<String, dynamic> json) {
    return AthleteBatchInfo(
      batchId: json['batchId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      academyName: json['academyName'] as String? ?? '',
      sportName: json['sportName'] as String?,
      slots: (json['slots'] as List? ?? const [])
          .map((e) => AthleteBatchSlot.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      coaches: (json['coaches'] as List? ?? const [])
          .map((e) => AthleteCoachInfo.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      startDate: AppDates.parseIsoDate(json['startDate'] as String?),
      endDate: AppDates.parseIsoDate(json['endDate'] as String?),
    );
  }
}

class AthleteBatchSlot {
  const AthleteBatchSlot({
    required this.startTime,
    required this.endTime,
    this.location,
  });

  final String startTime;
  final String endTime;
  final String? location;

  String get display {
    final loc = location;
    return '${TimeFormat.clock(startTime)} – ${TimeFormat.clock(endTime)}'
        '${loc != null ? ' · $loc' : ''}';
  }

  factory AthleteBatchSlot.fromJson(Map<String, dynamic> json) {
    return AthleteBatchSlot(
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      location: json['location'] as String?,
    );
  }
}

class AthleteCoachInfo {
  const AthleteCoachInfo({required this.coachId, this.firstName = '', this.lastName = ''});

  final String coachId;
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName'.trim();

  factory AthleteCoachInfo.fromJson(Map<String, dynamic> json) {
    return AthleteCoachInfo(
      coachId: json['coachId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
    );
  }
}

class AthleteProfile {
  const AthleteProfile({
    this.athleteId = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.sports = const [],
    this.academies = const [],
    this.batches = const [],
  });

  final String athleteId;
  final String firstName;
  final String lastName;
  final String email;
  final List<AthleteSportInfo> sports;
  final List<AthleteAcademyInfo> academies;
  final List<AthleteBatchInfo> batches;

  String get fullName => '$firstName $lastName'.trim();

  factory AthleteProfile.fromJson(Map<String, dynamic> json) {
    return AthleteProfile(
      athleteId: json['athleteId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      sports: (json['sports'] as List? ?? const [])
          .map((e) => AthleteSportInfo.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      academies: (json['academies'] as List? ?? const [])
          .map((e) => AthleteAcademyInfo.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      batches: (json['batches'] as List? ?? const [])
          .map((e) => AthleteBatchInfo.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}