import '../../domain/entities/coach_profile.dart';
import '../../domain/repositories/coach_profile_repository.dart';
import '../datasources/coach_profile_remote_data_source.dart';

class CoachProfileRepositoryImpl implements CoachProfileRepository {
  CoachProfileRepositoryImpl({required this.dataSource});

  final CoachProfileRemoteDataSource dataSource;

  @override
  Future<CoachProfile> getMe() => dataSource.getMe();
}
