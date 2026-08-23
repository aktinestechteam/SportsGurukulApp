import '../../../../core/network/api_client.dart';
import '../../domain/entities/athlete.dart';
import '../models/athlete_requests.dart';

class AthleteRemoteDataSource {
  AthleteRemoteDataSource({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<Athlete>> getAthletes(String academyId) async {
    final data = await _api.get('/academies/$academyId/athletes');
    if (data is! List) return const [];
    return data
        .map((e) => Athlete.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Athlete> createAthlete(String academyId, AthleteRequest request) async {
    final data = await _api.post('/academies/$academyId/athletes',
        body: request.toJson());
    return Athlete.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<Athlete> updateAthlete(
    String academyId,
    String athleteId,
    AthleteRequest request,
  ) async {
    final data = await _api.put(
      '/academies/$academyId/athletes/$athleteId',
      body: request.toJson(),
    );
    return Athlete.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> deleteAthlete(String academyId, String athleteId) async {
    await _api.delete('/academies/$academyId/athletes/$athleteId');
  }
}
