import '../../domain/entities/athlete_profile.dart';
import '../../domain/repositories/athlete_profile_repository.dart';
import '../datasources/athlete_profile_remote_data_source.dart';

class AthleteProfileRepositoryImpl implements AthleteProfileRepository {
  AthleteProfileRepositoryImpl({required this.dataSource});

  final AthleteProfileRemoteDataSource dataSource;

  @override
  Future<AthleteProfile> getMe() => dataSource.getMe();
}