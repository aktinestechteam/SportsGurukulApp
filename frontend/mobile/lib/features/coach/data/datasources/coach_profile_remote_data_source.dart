import '../../../../core/network/api_client.dart';
import '../../domain/entities/coach_profile.dart';

class CoachProfileRemoteDataSource {
  CoachProfileRemoteDataSource({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<CoachProfile> getMe() async {
    final data = await _api.get('/coaches/me');
    return CoachProfile.fromJson((data as Map).cast<String, dynamic>());
  }
}
