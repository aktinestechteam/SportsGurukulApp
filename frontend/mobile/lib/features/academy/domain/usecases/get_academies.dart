import '../entities/academy.dart';
import '../repositories/academy_repository.dart';

class GetAcademies {
  const GetAcademies(this._repository);

  final AcademyRepository _repository;

  Future<List<Academy>> call() => _repository.getAcademies();
}
