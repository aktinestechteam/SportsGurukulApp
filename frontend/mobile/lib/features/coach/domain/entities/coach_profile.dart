import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/time_format.dart';

class CoachAcademyInfo {
  const CoachAcademyInfo({
    required this.academyId,
    this.name = '',
    this.sports = const [],
  });

  final String academyId;
  final String name;
  final List<CoachAcademySport> sports;

  factory CoachAcademyInfo.fromJson(Map<String, dynamic> json) {
    return CoachAcademyInfo(
      academyId: json['academyId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sports: (json['sports'] as List? ?? const [])
          .map((e) => CoachAcademySport.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class CoachAcademySport {
  const CoachAcademySport({this.name = '', this.specialization});

  final String name;
  final String? specialization;

  String get display {
    final s = specialization;
    if (s != null && s.trim().isNotEmpty) return '$name · $s';
    return name;
  }

  factory CoachAcademySport.fromJson(Map<String, dynamic> json) {
    return CoachAcademySport(
      name: json['name'] as String? ?? '',
      specialization: json['specialization'] as String?,
    );
  }
}

class CoachBatchInfo {
  const CoachBatchInfo({
    required this.batchId,
    this.name = '',
    this.academyId = '',
    this.academyName = '',
    this.sportName,
    this.allowCoachBatchEdit = false,
    this.slots = const [],
    this.athletesCount = 0,
    this.coaches = const [],
    this.athletes = const [],
    this.startDate,
    this.endDate,
  });

  final String batchId;
  final String name;
  final String academyId;
  final String academyName;
  final String? sportName;
  final bool allowCoachBatchEdit;
  final List<CoachBatchSlot> slots;
  final int athletesCount;
  final List<CoachBatchPeer> coaches;
  final List<CoachBatchAthleteInfo> athletes;
  final DateTime? startDate;
  final DateTime? endDate;

  factory CoachBatchInfo.fromJson(Map<String, dynamic> json) {
    return CoachBatchInfo(
      batchId: json['batchId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      academyName: json['academyName'] as String? ?? '',
      sportName: json['sportName'] as String?,
      allowCoachBatchEdit: json['allowCoachBatchEdit'] as bool? ?? false,
      slots: (json['slots'] as List? ?? const [])
          .map((e) => CoachBatchSlot.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      athletesCount: json['athletesCount'] as int? ?? 0,
      coaches: (json['coaches'] as List? ?? const [])
          .map((e) => CoachBatchPeer.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      athletes: (json['athletes'] as List? ?? const [])
          .map((e) => CoachBatchAthleteInfo.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      startDate: AppDates.parseIsoDate(json['startDate'] as String?),
      endDate: AppDates.parseIsoDate(json['endDate'] as String?),
    );
  }
}

class CoachBatchAthleteInfo {
  const CoachBatchAthleteInfo({
    required this.athleteId,
    this.firstName = '',
    this.lastName = '',
    this.sport,
  });

  final String athleteId;
  final String firstName;
  final String lastName;
  final String? sport;

  String get fullName => '$firstName $lastName'.trim();

  factory CoachBatchAthleteInfo.fromJson(Map<String, dynamic> json) {
    return CoachBatchAthleteInfo(
      athleteId: json['athleteId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      sport: json['sport'] as String?,
    );
  }
}

class CoachBatchSlot {
  const CoachBatchSlot({
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

  factory CoachBatchSlot.fromJson(Map<String, dynamic> json) {
    return CoachBatchSlot(
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      location: json['location'] as String?,
    );
  }
}

class CoachBatchPeer {
  const CoachBatchPeer({required this.coachId, this.firstName = '', this.lastName = ''});

  final String coachId;
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName'.trim();

  factory CoachBatchPeer.fromJson(Map<String, dynamic> json) {
    return CoachBatchPeer(
      coachId: json['coachId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
    );
  }
}

class CoachAthleteInfo {
  const CoachAthleteInfo({
    required this.athleteId,
    this.firstName = '',
    this.lastName = '',
    this.sport,
    this.batchName,
    this.email,
    this.mobileNumber,
  });

  final String athleteId;
  final String firstName;
  final String lastName;
  final String? sport;
  final String? batchName;
  final String? email;
  final String? mobileNumber;

  String get fullName => '$firstName $lastName'.trim();

  factory CoachAthleteInfo.fromJson(Map<String, dynamic> json) {
    return CoachAthleteInfo(
      athleteId: json['athleteId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      sport: json['sport'] as String?,
      batchName: json['batchName'] as String?,
      email: json['email'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
    );
  }
}

class CoachProfile {
  const CoachProfile({
    this.coachId = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.academies = const [],
    this.batches = const [],
    this.athletes = const [],
  });

  final String coachId;
  final String firstName;
  final String lastName;
  final String email;
  final List<CoachAcademyInfo> academies;
  final List<CoachBatchInfo> batches;
  final List<CoachAthleteInfo> athletes;

  String get fullName => '$firstName $lastName'.trim();

  factory CoachProfile.fromJson(Map<String, dynamic> json) {
    return CoachProfile(
      coachId: json['coachId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      academies: (json['academies'] as List? ?? const [])
          .map((e) => CoachAcademyInfo.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      batches: (json['batches'] as List? ?? const [])
          .map((e) => CoachBatchInfo.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      athletes: (json['athletes'] as List? ?? const [])
          .map((e) => CoachAthleteInfo.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
