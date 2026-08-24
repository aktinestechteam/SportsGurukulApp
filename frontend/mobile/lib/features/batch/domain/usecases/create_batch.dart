import '../entities/batch.dart';
import '../repositories/batch_repository.dart';

class CreateBatch {
  const CreateBatch(this._repository);

  final BatchRepository _repository;

  Future<Batch> call(String academyId, BatchRequestInput input) =>
      _repository.createBatch(academyId, input);
}
