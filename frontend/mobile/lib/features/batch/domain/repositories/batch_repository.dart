import '../entities/batch.dart';

abstract class BatchRepository {
  Future<List<Batch>> getBatches(String academyId);
  Future<Batch> getBatch(String academyId, String batchId);
  Future<Batch> createBatch(String academyId, BatchRequestInput input);
  Future<Batch> updateBatch(
    String academyId,
    String batchId,
    BatchRequestInput input,
  );
  Future<void> deleteBatch(String academyId, String batchId);
}

class BatchSlotInput {
  const BatchSlotInput({
    required this.startTime,
    required this.endTime,
    this.location,
  });

  final String startTime;
  final String endTime;
  final String? location;
}

class BatchRequestInput {
  const BatchRequestInput({
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
}
