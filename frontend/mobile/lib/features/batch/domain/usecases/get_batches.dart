import '../entities/batch.dart';
import '../repositories/batch_repository.dart';

class GetBatches {
  const GetBatches(this._repository);

  final BatchRepository _repository;

  Future<List<Batch>> call(String academyId) =>
      _repository.getBatches(academyId);
}
