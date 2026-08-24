import '../../../../core/network/api_client.dart';
import '../../domain/entities/batch.dart';
import '../models/batch_requests.dart';

class BatchRemoteDataSource {
  BatchRemoteDataSource({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<Batch>> getBatches(String academyId) async {
    final data = await _api.get('/academies/$academyId/batches');
    if (data is! List) return const [];
    return data
        .map((e) => Batch.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Batch> getBatch(String academyId, String batchId) async {
    final data = await _api.get('/academies/$academyId/batches/$batchId');
    return Batch.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<Batch> createBatch(String academyId, BatchRequest request) async {
    final data = await _api.post(
      '/academies/$academyId/batches',
      body: request.toJson(),
    );
    return Batch.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<Batch> updateBatch(
    String academyId,
    String batchId,
    BatchRequest request,
  ) async {
    final data = await _api.put(
      '/academies/$academyId/batches/$batchId',
      body: request.toJson(),
    );
    return Batch.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> deleteBatch(String academyId, String batchId) async {
    await _api.delete('/academies/$academyId/batches/$batchId');
  }
}
