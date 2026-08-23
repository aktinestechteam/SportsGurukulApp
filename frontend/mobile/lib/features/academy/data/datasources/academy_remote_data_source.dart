import '../../../../core/network/api_client.dart';
import '../../domain/entities/academy.dart';
import '../models/academy_requests.dart';

class AcademyRemoteDataSource {
  AcademyRemoteDataSource({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<Academy> createAcademy(AcademyRequest request) async {
    final data = await _api.post('/academies', body: request.toJson());
    return Academy.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<List<Academy>> getAcademies() async {
    final data = await _api.get('/academies');
    if (data is! List) {
      return const [];
    }
    return data
        .map((e) => Academy.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Academy> getAcademy(String academyId) async {
    final data = await _api.get('/academies/$academyId');
    return Academy.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<Academy> updateAcademy(String academyId, AcademyRequest request) async {
    final data = await _api.put('/academies/$academyId', body: request.toJson());
    return Academy.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> deleteAcademy(String academyId) async {
    await _api.delete('/academies/$academyId');
  }
}
