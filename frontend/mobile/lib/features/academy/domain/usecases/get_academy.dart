import '../entities/academy.dart';
import '../repositories/academy_repository.dart';

class GetAcademy {
  const GetAcademy(this._repository);

  final AcademyRepository _repository;

  Future<Academy> call(String academyId) => _repository.getAcademy(academyId);
}
