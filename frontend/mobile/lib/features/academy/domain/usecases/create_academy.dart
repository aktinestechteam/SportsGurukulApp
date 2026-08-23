import '../entities/academy.dart';
import '../repositories/academy_repository.dart';

class CreateAcademy {
  const CreateAcademy(this._repository);

  final AcademyRepository _repository;

  Future<Academy> call(AcademyRequestInput input) => _repository.create(input);
}
