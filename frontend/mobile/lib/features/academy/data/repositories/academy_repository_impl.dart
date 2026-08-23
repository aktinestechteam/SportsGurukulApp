import '../../domain/entities/academy.dart';
import '../../domain/repositories/academy_repository.dart';
import '../datasources/academy_remote_data_source.dart';
import '../models/academy_requests.dart';

class AcademyRepositoryImpl implements AcademyRepository {
  AcademyRepositoryImpl({required this.dataSource});

  final AcademyRemoteDataSource dataSource;

  @override
  Future<Academy> create(AcademyRequestInput input) {
    return dataSource.createAcademy(_mapRequest(input));
  }

  @override
  Future<List<Academy>> getAcademies() => dataSource.getAcademies();

  @override
  Future<Academy> getAcademy(String academyId) => dataSource.getAcademy(academyId);

  @override
  Future<Academy> update(String academyId, AcademyRequestInput input) {
    return dataSource.updateAcademy(academyId, _mapRequest(input));
  }

  @override
  Future<void> delete(String academyId) => dataSource.deleteAcademy(academyId);

  AcademyRequest _mapRequest(AcademyRequestInput input) {
    return AcademyRequest(
      name: input.name,
      profile: input.profile,
      contactEmail: input.contactEmail,
      contactPhone: input.contactPhone,
      address: input.address,
      city: input.city,
      state: input.state,
      country: input.country,
      postalCode: input.postalCode,
      logoUrl: input.logoUrl,
      isPublic: input.isPublic,
      branches: input.branches,
      sports: input.sports,
      facilities: input.facilities,
      memberships: input.memberships,
      workingHours: input.workingHours,
    );
  }
}
