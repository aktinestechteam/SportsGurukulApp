import '../../../../core/network/api_client.dart';
import '../../domain/entities/athlete_profile.dart';

class AthleteProfileRemoteDataSource {
  AthleteProfileRemoteDataSource({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<AthleteProfile> getMe() async {
    final data = await _api.get('/athletes/me');
    return AthleteProfile.fromJson((data as Map).cast<String, dynamic>());
  }
}