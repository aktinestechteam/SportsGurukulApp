import '../entities/batch.dart';
import '../repositories/batch_repository.dart';

class UpdateBatch {
  const UpdateBatch(this._repository);

  final BatchRepository _repository;

  Future<Batch> call(
    String academyId,
    String batchId,
    BatchRequestInput input,
  ) =>
      _repository.updateBatch(academyId, batchId, input);
}
