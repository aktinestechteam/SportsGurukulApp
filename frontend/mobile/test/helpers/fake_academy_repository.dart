import 'package:sports_gurukul/features/academy/domain/entities/academy.dart';
import 'package:sports_gurukul/features/academy/domain/repositories/academy_repository.dart';
import 'package:sports_gurukul/features/academy/domain/usecases/create_academy.dart';
import 'package:sports_gurukul/features/academy/domain/usecases/delete_academy.dart';
import 'package:sports_gurukul/features/academy/domain/usecases/get_academies.dart';
import 'package:sports_gurukul/features/academy/domain/usecases/get_academy.dart';
import 'package:sports_gurukul/features/academy/domain/usecases/update_academy.dart';
import 'package:sports_gurukul/features/academy/presentation/providers/academy_provider.dart';

class FakeAcademyRepository implements AcademyRepository {
  FakeAcademyRepository({this.academies = const []});

  List<Academy> academies;

  @override
  Future<Academy> create(AcademyRequestInput input) =>
      throw UnimplementedError();

  @override
  Future<List<Academy>> getAcademies() async => academies;

  @override
  Future<Academy> getAcademy(String academyId) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String academyId) async {}

  @override
  Future<Academy> update(String academyId, AcademyRequestInput input) =>
      throw UnimplementedError();
}

AcademyProvider buildAcademyProvider({List<Academy> academies = const []}) {
  final repo = FakeAcademyRepository(academies: academies);
  return AcademyProvider(
    createAcademy: CreateAcademy(repo),
    getAcademies: GetAcademies(repo),
    getAcademy: GetAcademy(repo),
    updateAcademy: UpdateAcademy(repo),
    deleteAcademy: DeleteAcademy(repo),
  );
}
