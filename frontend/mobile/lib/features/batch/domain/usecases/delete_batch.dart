import '../repositories/batch_repository.dart';

class DeleteBatch {
  const DeleteBatch(this._repository);

  final BatchRepository _repository;

  Future<void> call(String academyId, String batchId) =>
      _repository.deleteBatch(academyId, batchId);
}
