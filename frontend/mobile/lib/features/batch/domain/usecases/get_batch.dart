import '../entities/batch.dart';
import '../repositories/batch_repository.dart';

class GetBatch {
  const GetBatch(this._repository);

  final BatchRepository _repository;

  Future<Batch> call(String academyId, String batchId) =>
      _repository.getBatch(academyId, batchId);
}
