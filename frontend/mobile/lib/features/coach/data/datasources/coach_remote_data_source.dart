import '../../../../core/network/api_client.dart';
import '../../domain/entities/coach.dart';
import '../models/coach_requests.dart';

class CoachRemoteDataSource {
  CoachRemoteDataSource({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<Coach>> getCoaches(String academyId) async {
    final data = await _api.get('/academies/$academyId/coaches');
    if (data is! List) return const [];
    return data
        .map((e) => Coach.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Coach> createCoach(String academyId, CoachRequest request) async {
    final data = await _api.post('/academies/$academyId/coaches',
        body: request.toJson());
    return Coach.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<Coach> updateCoach(
    String academyId,
    String coachId,
    CoachRequest request,
  ) async {
    final data = await _api.put(
      '/academies/$academyId/coaches/$coachId',
      body: request.toJson(),
    );
    return Coach.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> deleteCoach(String academyId, String coachId) async {
    await _api.delete('/academies/$academyId/coaches/$coachId');
  }
}
