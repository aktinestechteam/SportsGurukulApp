import '../repositories/academy_repository.dart';

class DeleteAcademy {
  const DeleteAcademy(this._repository);

  final AcademyRepository _repository;

  Future<void> call(String academyId) => _repository.delete(academyId);
}
