import '../../domain/entities/batch.dart';
import '../../domain/repositories/batch_repository.dart';
import '../datasources/batch_remote_data_source.dart';
import '../models/batch_requests.dart';

class BatchRepositoryImpl implements BatchRepository {
  BatchRepositoryImpl({required this.dataSource});

  final BatchRemoteDataSource dataSource;

  @override
  Future<List<Batch>> getBatches(String academyId) =>
      dataSource.getBatches(academyId);

  @override
  Future<Batch> getBatch(String academyId, String batchId) =>
      dataSource.getBatch(academyId, batchId);

  @override
  Future<Batch> createBatch(String academyId, BatchRequestInput input) =>
      dataSource.createBatch(academyId, _mapRequest(input));

  @override
  Future<Batch> updateBatch(
    String academyId,
    String batchId,
    BatchRequestInput input,
  ) =>
      dataSource.updateBatch(academyId, batchId, _mapRequest(input));

  @override
  Future<void> deleteBatch(String academyId, String batchId) =>
      dataSource.deleteBatch(academyId, batchId);

  BatchRequest _mapRequest(BatchRequestInput input) => BatchRequest(
    name: input.name,
    description: input.description,
    sportId: input.sportId,
    startDate: input.startDate,
    endDate: input.endDate,
    slots: input.slots,
    coachIds: input.coachIds,
    athleteIds: input.athleteIds,
  );
}
