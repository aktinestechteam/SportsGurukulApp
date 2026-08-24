enum DayOfWeek {
  sunday(0, 'Sunday'),
  monday(1, 'Monday'),
  tuesday(2, 'Tuesday'),
  wednesday(3, 'Wednesday'),
  thursday(4, 'Thursday'),
  friday(5, 'Friday'),
  saturday(6, 'Saturday');

  const DayOfWeek(this.value, this.label);

  final int value;
  final String label;

  static DayOfWeek fromValue(int? value) {
    return DayOfWeek.values.firstWhere(
      (d) => d.value == value,
      orElse: () => DayOfWeek.monday,
    );
  }
}

class BatchScheduleSlot {
  const BatchScheduleSlot({
    required this.slotId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.location,
  });

  final String slotId;
  final DayOfWeek dayOfWeek;
  final String startTime;
  final String endTime;
  final String? location;

  factory BatchScheduleSlot.fromJson(Map<String, dynamic> json) {
    return BatchScheduleSlot(
      slotId: json['slotId'] as String? ?? '',
      dayOfWeek: DayOfWeek.fromValue(json['dayOfWeek'] as int?),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'slotId': slotId,
    'dayOfWeek': dayOfWeek.value,
    'startTime': startTime,
    'endTime': endTime,
    'location': location,
  };
}

class BatchCoachInfo {
  const BatchCoachInfo({
    required this.coachId,
    this.firstName = '',
    this.lastName = '',
    this.specialization,
    this.assignedAt = '',
  });

  final String coachId;
  final String firstName;
  final String lastName;
  final String? specialization;
  final String assignedAt;

  String get fullName => '$firstName $lastName';

  factory BatchCoachInfo.fromJson(Map<String, dynamic> json) {
    return BatchCoachInfo(
      coachId: json['coachId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      specialization: json['specialization'] as String?,
      assignedAt: json['assignedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'coachId': coachId,
    'firstName': firstName,
    'lastName': lastName,
    'specialization': specialization,
    'assignedAt': assignedAt,
  };
}

class BatchAthleteInfo {
  const BatchAthleteInfo({
    required this.athleteId,
    this.firstName = '',
    this.lastName = '',
    this.primarySport,
    this.assignedAt = '',
  });

  final String athleteId;
  final String firstName;
  final String lastName;
  final String? primarySport;
  final String assignedAt;

  String get fullName => '$firstName $lastName';

  factory BatchAthleteInfo.fromJson(Map<String, dynamic> json) {
    return BatchAthleteInfo(
      athleteId: json['athleteId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      primarySport: json['primarySport'] as String?,
      assignedAt: json['assignedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'athleteId': athleteId,
    'firstName': firstName,
    'lastName': lastName,
    'primarySport': primarySport,
    'assignedAt': assignedAt,
  };
}

class Batch {
  const Batch({
    required this.batchId,
    required this.academyId,
    this.name = '',
    this.description,
    this.sportId,
    this.sportName,
    this.startDate,
    this.endDate,
    this.createdAt = '',
    this.updatedAt = '',
    this.slots = const [],
    this.coaches = const [],
    this.athletes = const [],
  });

  final String batchId;
  final String academyId;
  final String name;
  final String? description;
  final String? sportId;
  final String? sportName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String createdAt;
  final String updatedAt;
  final List<BatchScheduleSlot> slots;
  final List<BatchCoachInfo> coaches;
  final List<BatchAthleteInfo> athletes;

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      batchId: json['batchId'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      sportId: json['sportId'] as String?,
      sportName: json['sportName'] as String?,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'] as String) : null,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      slots: (json['slots'] as List? ?? const [])
          .map((e) => BatchScheduleSlot.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      coaches: (json['coaches'] as List? ?? const [])
          .map((e) => BatchCoachInfo.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      athletes: (json['athletes'] as List? ?? const [])
          .map((e) => BatchAthleteInfo.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'batchId': batchId,
    'academyId': academyId,
    'name': name,
    'description': description,
    'sportId': sportId,
    'sportName': sportName,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'slots': slots.map((e) => e.toJson()).toList(),
    'coaches': coaches.map((e) => e.toJson()).toList(),
    'athletes': athletes.map((e) => e.toJson()).toList(),
  };
}
