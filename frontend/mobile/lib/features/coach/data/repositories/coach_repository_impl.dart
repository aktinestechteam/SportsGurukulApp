import '../../domain/entities/coach.dart';
import '../../domain/repositories/coach_repository.dart';
import '../datasources/coach_remote_data_source.dart';
import '../models/coach_requests.dart';

class CoachRepositoryImpl implements CoachRepository {
  CoachRepositoryImpl({required this.dataSource});

  final CoachRemoteDataSource dataSource;

  @override
  Future<List<Coach>> getCoaches(String academyId) =>
      dataSource.getCoaches(academyId);

  @override
  Future<Coach> createCoach(String academyId, CoachRequestInput input) =>
      dataSource.createCoach(academyId, _mapRequest(input));

  @override
  Future<Coach> updateCoach(
    String academyId,
    String coachId,
    CoachRequestInput input,
  ) =>
      dataSource.updateCoach(academyId, coachId, _mapRequest(input));

  @override
  Future<void> deleteCoach(String academyId, String coachId) =>
      dataSource.deleteCoach(academyId, coachId);

  CoachRequest _mapRequest(CoachRequestInput input) => CoachRequest(
    firstName: input.firstName,
    lastName: input.lastName,
    email: input.email,
    mobileNumber: input.mobileNumber,
    branchId: input.branchId,
    sports: input.sports,
  );
}
