import 'package:sports_gurukul/features/academy/domain/entities/academy.dart';
import 'package:sports_gurukul/features/academy/domain/repositories/academy_repository.dart';
import 'package:sports_gurukul/features/academy/domain/usecases/create_academy.dart';
import 'package:sports_gurukul/features/academy/domain/usecases/delete_academy.dart';
import 'package:sports_gurukul/features/academy/domain/usecases/get_academies.dart';
import 'package:sports_gurukul/features/academy/domain/usecases/get_academy.dart';
import 'package:sports_gurukul/features/academy/domain/usecases/update_academy.dart';
import 'package:sports_gurukul/features/academy/presentation/providers/academy_provider.dart';
import 'package:sports_gurukul/features/athlete/domain/entities/athlete.dart';
import 'package:sports_gurukul/features/athlete/domain/repositories/athlete_repository.dart';
import 'package:sports_gurukul/features/batch/domain/entities/batch.dart';
import 'package:sports_gurukul/features/batch/domain/repositories/batch_repository.dart';
import 'package:sports_gurukul/features/coach/domain/entities/coach.dart';
import 'package:sports_gurukul/features/coach/domain/repositories/coach_repository.dart';

class _FakeBatchRepository implements BatchRepository {
  @override
  Future<List<Batch>> getBatches(String academyId) async => const [];

  @override
  Future<Batch> getBatch(String academyId, String batchId) =>
      throw UnimplementedError();

  @override
  Future<Batch> createBatch(String academyId, BatchRequestInput input) =>
      throw UnimplementedError();

  @override
  Future<Batch> updateBatch(
    String academyId,
    String batchId,
    BatchRequestInput input,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> deleteBatch(String academyId, String batchId) async {}
}

class _FakeCoachRepository implements CoachRepository {
  @override
  Future<List<Coach>> getCoaches(String academyId) async => const [];

  @override
  Future<Coach> createCoach(String academyId, CoachRequestInput input) =>
      throw UnimplementedError();

  @override
  Future<Coach> updateCoach(
    String academyId,
    String coachId,
    CoachRequestInput input,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> deleteCoach(String academyId, String coachId) async {}
}

class _FakeAthleteRepository implements AthleteRepository {
  @override
  Future<List<Athlete>> getAthletes(String academyId) async => const [];

  @override
  Future<Athlete> createAthlete(
    String academyId,
    AthleteRequestInput input,
  ) =>
      throw UnimplementedError();

  @override
  Future<Athlete> updateAthlete(
    String academyId,
    String athleteId,
    AthleteRequestInput input,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAthlete(String academyId, String athleteId) async {}
}

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
    batchRepository: _FakeBatchRepository(),
    coachRepository: _FakeCoachRepository(),
    athleteRepository: _FakeAthleteRepository(),
  );
}
