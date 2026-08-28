import '../../../../core/utils/app_dates.dart';
import '../../domain/repositories/batch_repository.dart';

class BatchRequest {
  const BatchRequest({
    required this.name,
    this.description,
    this.sportId,
    this.startDate,
    this.endDate,
    this.slots = const [],
    this.coachIds = const [],
    this.athleteIds = const [],
  });

  final String name;
  final String? description;
  final String? sportId;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<BatchSlotInput> slots;
  final List<String> coachIds;
  final List<String> athleteIds;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'sportId': sportId,
    'startDate': startDate != null ? AppDates.toIsoDate(startDate!) : null,
    'endDate': endDate != null ? AppDates.toIsoDate(endDate!) : null,
    'slots': slots.map(_slotJson).toList(),
    'coachIds': coachIds,
    'athleteIds': athleteIds,
  };

  static Map<String, dynamic> _slotJson(BatchSlotInput s) => {
    'startTime': s.startTime,
    'endTime': s.endTime,
    'location': s.location,
  };
}
