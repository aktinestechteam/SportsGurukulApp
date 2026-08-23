import '../entities/academy.dart';
import '../repositories/academy_repository.dart';

class UpdateAcademy {
  const UpdateAcademy(this._repository);

  final AcademyRepository _repository;

  Future<Academy> call(String academyId, AcademyRequestInput input) =>
      _repository.update(academyId, input);
}
